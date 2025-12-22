-- Teamfight Win Predictor + Power Spike Detector for Umbrella
-- Calcula chance de ganhar a luta perto do seu heroi e mostra spikes de poder (level 6/12/18, BKB, Aghs, Shard)
---@diagnostic disable: undefined-global, lowercase-global
local script = {}

-- UI
local ui = {}
local menuBuilt = false

-- State
local state = {
    myHero = nil,
    lastEval = 0,
    winChance = 50,
    fightLabel = "NEUTRO",
    fightColor = {200, 200, 120},
    allyCount = 0,
    enemyCount = 0,
    recentSpikes = {ally = 0, enemy = 0},
    spikeSuggestion = "Equilibrado",
    tracked = {},
    timeline = {},
}

local fonts = {
    header = nil,
    body = nil
}

local function loadFont(size)
    if Render and Render.LoadFont then
        return Render.LoadFont("Arial", size, Enum.FontCreate.FONTFLAG_OUTLINE)
    elseif Renderer and Renderer.LoadFont then
        return Renderer.LoadFont("Arial", size, Enum.FontCreate.FONTFLAG_OUTLINE)
    end
    return nil
end

local function drawFilledRect(p1, p2, col, radius)
    if Render and Render.FilledRect then
        Render.FilledRect(p1, p2, col, radius or 0)
    elseif Renderer and Renderer.FilledRect then
        Renderer.FilledRect(p1, p2, col, radius or 0)
    end
end

local function drawText(font, size, text, pos, col)
    if Render and Render.Text then
        Render.Text(font, size, text, pos, col)
    elseif Renderer and Renderer.Text then
        Renderer.Text(font, size, text, pos, col)
    elseif Renderer and Renderer.DrawText then
        -- fallback for APIs que pedem RGBA separados
        Renderer.DrawText(pos.x, pos.y, text, col.r or 255, col.g or 255, col.b or 255, col.a or 255, size, false)
    end
end

-- Constrói o menu imediatamente (alguns loaders não chamam OnUpdate fora do jogo)
local function buildMenu()
    if menuBuilt then return end
    -- Coloca em "Scripts > User Scripts > Teamfight Predictor" (mesmo lugar de AutoStacker)
    local tab = Menu.Create("Scripts", "User Scripts", "Teamfight Predictor")
    tab:Icon("\u{f0e3}") -- balance-scale
    -- Segue o padrão de duas camadas igual outros scripts (ex: Courier/AutoStacker)
    local section = tab:Create("Config")
    local group = section:Create("Main")

    ui.enabled = group:Switch("Ativar Predictor", true, "\u{f011}")
    ui.radius = group:Slider("Raio de avaliacao", 600, 2000, 1200, "%d")
    ui.tickRate = group:Slider("Intervalo de recalc (ms)", 100, 1500, 300, "%d")
    ui.timelineWindow = group:Slider("Janela de spikes (s)", 30, 240, 90, "%d")
    ui.showTimeline = group:Switch("Mostrar timeline", true)

    menuBuilt = true
end

buildMenu()

local function now()
    return GameRules.GetGameTime() or GlobalVars.GetCurTime() or 0
end

local function clamp(val, minv, maxv)
    if val < minv then return minv end
    if val > maxv then return maxv end
    return val
end

local function getMyHero()
    state.myHero = state.myHero or Heroes.GetLocal()
    return state.myHero
end

local function hasItemReady(hero, name)
    local item = NPC.GetItem(hero, name, true)
    if not item then return false end
    if Ability.IsReady then
        return Ability.IsReady(item)
    end
    -- fallback: treat as present
    return true
end

local blinkList = {
    "item_blink",
    "item_overwhelming_blink",
    "item_swift_blink",
    "item_arcane_blink",
}

local function hasAnyBlink(hero)
    for _, name in ipairs(blinkList) do
        if hasItemReady(hero, name) then
            return true
        end
    end
    return false
end

local function hasAghs(hero)
    if NPC.HasModifier and (NPC.HasModifier(hero, "modifier_item_ultimate_scepter") or NPC.HasModifier(hero, "modifier_item_ultimate_scepter_consumed")) then
        return true
    end
    return hasItemReady(hero, "item_ultimate_scepter")
end

local function hasShard(hero)
    if NPC.HasModifier and NPC.HasModifier(hero, "modifier_item_aghanims_shard") then
        return true
    end
    return hasItemReady(hero, "item_aghanims_shard")
end

local function isUltReady(hero)
    -- Heuristica: tenta slots mais altos primeiro
    local candidateSlots = {5, 4, 3}
    for _, idx in ipairs(candidateSlots) do
        local ab = NPC.GetAbilityByIndex(hero, idx)
        if ab and Ability.GetLevel(ab) and Ability.GetLevel(ab) > 0 then
            if Ability.IsReady and Ability.IsReady(ab) then
                return true
            end
            if Ability.GetCooldown and Ability.GetCooldown(ab) <= 0 then
                return true
            end
        end
    end
    return false
end

local function heroScore(hero, center, radius)
    local hp = math.max(NPC.GetHealth(hero) or 0, 1)
    local hpMax = math.max(NPC.GetMaxHealth(hero) or 1, 1)
    local mana = math.max(NPC.GetMana(hero) or 0, 0)
    local manaMax = math.max(NPC.GetMaxMana(hero) or 1, 1)

    local hpPct = clamp(hp / hpMax, 0, 1)
    local manaPct = clamp(mana / manaMax, 0, 1)

    local score = hpPct * 0.6 + manaPct * 0.2
    if isUltReady(hero) then score = score + 0.15 end
    if hasItemReady(hero, "item_black_king_bar") then score = score + 0.12 end
    if hasAghs(hero) then score = score + 0.06 end
    if hasShard(hero) then score = score + 0.04 end
    if hasAnyBlink(hero) then score = score + 0.03 end

    if center and radius then
        local pos = Entity.GetAbsOrigin(hero)
        if pos then
            local dist = (pos - center):Length2D()
            local posWeight = clamp(1 - (dist / (radius * 1.2)), 0.4, 1.15)
            score = score * posWeight
        end
    end

    return math.max(score, 0.05)
end

local function addTimelineEvent(teamLabel, heroName, text)
    local entry = {
        time = now(),
        team = teamLabel,
        hero = heroName,
        desc = text
    }
    table.insert(state.timeline, 1, entry)
    if #state.timeline > 16 then
        table.remove(state.timeline)
    end
end

local function formatTime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function trackSpikes(hero, teamLabel)
    local uid = Entity.GetIndex(hero)
    local tracked = state.tracked[uid] or {level = 0, bkb = false, aghs = false, shard = false}
    local level = NPC.GetCurrentLevel(hero) or 0
    local name = Engine.GetDisplayNameByUnitName(NPC.GetUnitName(hero)) or NPC.GetUnitName(hero)

    for _, lvl in ipairs({6, 12, 18}) do
        if level >= lvl and tracked.level < lvl then
            addTimelineEvent(teamLabel, name, "Level " .. lvl)
        end
    end

    local bkbNow = hasItemReady(hero, "item_black_king_bar")
    if bkbNow and not tracked.bkb then
        addTimelineEvent(teamLabel, name, "BKB pronta")
    end

    local aghsNow = hasAghs(hero)
    if aghsNow and not tracked.aghs then
        addTimelineEvent(teamLabel, name, "Aghanim pronta")
    end

    local shardNow = hasShard(hero)
    if shardNow and not tracked.shard then
        addTimelineEvent(teamLabel, name, "Shard pronta")
    end

    tracked.level = math.max(tracked.level, level)
    tracked.bkb = tracked.bkb or bkbNow
    tracked.aghs = tracked.aghs or aghsNow
    tracked.shard = tracked.shard or shardNow

    state.tracked[uid] = tracked
end

local function spikeBalance(window)
    local limit = now() - window
    local ally = 0
    local enemy = 0
    for _, ev in ipairs(state.timeline) do
        if ev.time >= limit then
            if ev.team == "Aliado" then ally = ally + 1 else enemy = enemy + 1 end
        else
            break
        end
    end
    state.recentSpikes = {ally = ally, enemy = enemy}
    if ally > enemy then
        state.spikeSuggestion = "Spikes a favor, pode lutar"
    elseif enemy > ally then
        state.spikeSuggestion = "Inimigos mais fortes, farm/espera"
    else
        state.spikeSuggestion = "Equilibrado"
    end
end

local function evaluate()
    if not ui.enabled or not ui.enabled:Get() then return end
    local hero = getMyHero()
    if not hero or not Entity.IsAlive(hero) then return end

    local team = Entity.GetTeamNum(hero)
    local center = Entity.GetAbsOrigin(hero)
    local radius = ui.radius:Get()

    local allyScore, enemyScore = 0, 0
    local allyCount, enemyCount = 0, 0

    -- Primeiro tenta API nativa de raio (mais confiável no Demo)
    -- Usa UnitsInRadius (funciona melhor no Demo)
    local allies = Entity.GetUnitsInRadius(hero, radius, Enum.TeamType.TEAM_FRIEND) or {}
    local enemies = Entity.GetUnitsInRadius(hero, radius, Enum.TeamType.TEAM_ENEMY) or {}

    local function processList(list, isAlly)
        for _, h in ipairs(list) do
            if h and Entity.IsAlive(h) and not NPC.IsIllusion(h) then
                if isAlly then
                    allyScore = allyScore + heroScore(h, center, radius)
                    allyCount = allyCount + 1
                else
                    enemyScore = enemyScore + heroScore(h, center, radius)
                    enemyCount = enemyCount + 1
                end
            end
        end
    end

    processList(allies, true)
    processList(enemies, false)

    -- Fallback manual: se nada foi contado, percorre NPCs/GetAll
    if allyCount == 0 and enemyCount == 0 then
        for _, h in ipairs(NPCs.GetAll() or {}) do
            if h and Entity.IsAlive(h) and (Entity.IsHero(h) or NPC.IsHero(h)) and not NPC.IsIllusion(h) then
                local pos = Entity.GetAbsOrigin(h)
                if pos then
                    local dist = (pos - center):Length2D()
                    if dist <= radius then
                        if Entity.IsSameTeam(hero, h) then
                            allyScore = allyScore + heroScore(h, center, radius)
                            allyCount = allyCount + 1
                        else
                            enemyScore = enemyScore + heroScore(h, center, radius)
                            enemyCount = enemyCount + 1
                        end
                    end
                end
            end
        end
    end

    -- Rastreamento de spikes usa todos heróis visíveis no jogo (fora do raio também)
    local allHeroes = Heroes.GetAll() or NPCs.GetAll() or {}
    for _, h in ipairs(allHeroes) do
        if h and Entity.IsAlive(h) and not NPC.IsIllusion(h) and (Entity.IsHero(h) or NPC.IsHero(h)) then
            local teamLabel = (Entity.GetTeamNum(h) == team) and "Aliado" or "Inimigo"
            trackSpikes(h, teamLabel)
        end
    end

    state.allyCount = allyCount
    state.enemyCount = enemyCount

    local total = allyScore + enemyScore
    if total < 0.01 then
        state.winChance = 50
    else
        state.winChance = clamp((allyScore / total) * 100, 1, 99)
    end

    if state.winChance >= 60 then
        state.fightLabel = "LUTAR"
        state.fightColor = {90, 200, 90}
    elseif state.winChance <= 40 then
        state.fightLabel = "RECUAR"
        state.fightColor = {220, 90, 80}
    else
        state.fightLabel = "NEUTRO"
        state.fightColor = {220, 200, 90}
    end

    spikeBalance(ui.timelineWindow:Get())
end

local function drawPanel()
    if not ui.enabled or not ui.enabled:Get() then return end
    local hero = getMyHero()
    if not hero or not Entity.IsAlive(hero) then return end
    fonts.header = fonts.header or loadFont(16)
    fonts.body = fonts.body or loadFont(13)

    local x, y = 40, 260
    local lines = {
        "Teamfight Win Predictor",
        string.format("Chance: %.0f%% [%s]", state.winChance, state.fightLabel),
        string.format("Aliados/Inimigos no raio: %d / %d", state.allyCount, state.enemyCount),
        string.format("Spikes (ultimo %ds): %d / %d", ui.timelineWindow:Get(), state.recentSpikes.ally, state.recentSpikes.enemy),
        "Sugestao: " .. state.spikeSuggestion
    }

    local height = 22 + (#lines * 18)
    local width = 320

    drawFilledRect(Vec2(x, y), Vec2(x + width, y + height), Color(20, 20, 26, 190), 6)
    drawText(fonts.header, 15, lines[1], Vec2(x + 12, y + 8), Color(160, 200, 255, 255))

    for i = 2, #lines do
        local col = Color(230, 230, 220, 255)
        if i == 2 then
            col = Color(state.fightColor[1], state.fightColor[2], state.fightColor[3], 255)
        end
        drawText(fonts.body, 13, lines[i], Vec2(x + 12, y + 6 + 16 * (i - 1)), col)
    end

    if ui.showTimeline and ui.showTimeline:Get() and #state.timeline > 0 then
        local tY = y + height + 6
        local maxRows = 6
        local rows = math.min(#state.timeline, maxRows)
        local tHeight = 20 + rows * 16
        drawFilledRect(Vec2(x, tY), Vec2(x + width, tY + tHeight), Color(18, 18, 22, 180), 6)
        drawText(fonts.header, 14, "Power Spike Timeline", Vec2(x + 12, tY + 6), Color(200, 200, 255, 255))
        for i = 1, rows do
            local ev = state.timeline[i]
            local ts = formatTime(ev.time)
            local prefix = ev.team == "Aliado" and "[A]" or "[E]"
            local line = string.format("%s %s - %s (%s)", prefix, ev.hero or "?", ev.desc, ts)
            local lineCol = ev.team == "Aliado" and Color(120, 200, 120, 240) or Color(220, 150, 90, 240)
            drawText(fonts.body, 12, line, Vec2(x + 12, tY + 6 + 16 * i), lineCol)
        end
    end
end

function script.OnUpdate()
    buildMenu()
    local enabled = ui.enabled and ui.enabled:Get() or false
    if not enabled then return end
    if not Engine.IsInGame() then return end

    local tickMs = ui.tickRate:Get()
    if now() < state.lastEval + (tickMs / 1000.0) then return end
    state.lastEval = now()

    evaluate()
end

function script.OnDraw()
    buildMenu()
    local enabled = ui.enabled and ui.enabled:Get() or false
    if not enabled then return end
    if not Engine.IsInGame() then return end
    drawPanel()
end

function script.OnGameEnd()
    state.myHero = nil
    state.timeline = {}
    state.tracked = {}
    state.lastEval = 0
end

return script
