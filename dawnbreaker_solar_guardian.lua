local DawnbreakerScript = {}

-- Menu Setup

local settingsGroup = nil
local settings = {}
local allyCheckboxes = {}

local success, err = pcall(function()
    Log.Write("Dawnbreaker Helper: Initializing menu...")
    local heroTab = Menu.Create("Heroes", "Hero List", "Dawnbreaker")
    if not heroTab then
        Log.Write("Dawnbreaker Helper Error: Failed to create tab. Proceeding without menu.")
        return
    end
    heroTab:Icon("panorama/images/heroes/icons/npc_dota_hero_dawnbreaker_png.vtex_c")

    local scriptTab = heroTab:Create("Auto Solar Guardian")
    if not scriptTab then
        Log.Write("Dawnbreaker Helper Error: Failed to create script tab 'Auto Solar Guardian'.")
        return
    end

    settingsGroup = scriptTab:Create("Settings")
    if not settingsGroup then
        Log.Write("Dawnbreaker Helper Error: Failed to create 'Settings' group.")
        return
    end


    settings.masterEnable = settingsGroup:Switch("Ativar Script", true, "✓")
    settings.minAttackers = settingsGroup:Slider("Mín Atacantes", 2, 5, 3, "%d")
    settings.checkRadius = settingsGroup:Slider("Raio de Verificação", 400, 1200, 800, "%d")
    settings.hpThreshold = settingsGroup:Slider("Limiar de HP %", 10, 100, 40, "%d%%")

    settings.minAttackers:ToolTip("Número de inimigos próximos necessários para ultar.")
    settings.checkRadius:ToolTip("Raio em torno do aliado para contar inimigos.")
    settings.hpThreshold:ToolTip("Ultar quando a vida do aliado estiver abaixo desta porcentagem.")

    -- Callback to manage the enabled/disabled state of the controls.
    local function updateMenuState()
        if settings.masterEnable then
            local isEnabled = settings.masterEnable:Get()
            if settings.minAttackers then settings.minAttackers:Disabled(not isEnabled) end
            if settings.checkRadius then settings.checkRadius:Disabled(not isEnabled) end
            if settings.hpThreshold then settings.hpThreshold:Disabled(not isEnabled) end
            for _, cb in pairs(allyCheckboxes) do
                cb:Disabled(not isEnabled)
            end
        end
    end
    settings.masterEnable:SetCallback(updateMenuState, true)

    Log.Write("Dawnbreaker Helper: Menu and widgets created successfully.")
end)

if not success then
    Log.Write("Dawnbreaker Helper FATAL ERROR during menu setup: " .. tostring(err))
    return DawnbreakerScript -- Return an empty table to prevent the script from running with a broken menu.
end

-- Script Variables
local localHero = nil
local alliesPopulated = false
local allyList = {}


-- Helper Functions
local function getLocalHero()
    if not localHero then
        localHero = Heroes.GetLocal()
    end
    return localHero
end

local heroNames = {
    npc_dota_hero_antimage = "Anti-Mage",
    npc_dota_hero_axe = "Axe",
    npc_dota_hero_bane = "Bane",
    npc_dota_hero_bloodseeker = "Bloodseeker",
    npc_dota_hero_crystal_maiden = "Crystal Maiden",
    npc_dota_hero_dawnbreaker = "Dawnbreaker",
    -- Adicione outros heróis conforme necessário
}

local function getFriendlyName(name)
    if name == "npc_dota_hero_dawnbreaker" then return "Dawnbreaker" end
    if heroNames[name] then return heroNames[name] end
    local simple = name:gsub("npc_dota_hero_", "")
    simple = simple:gsub("_", " ")
    simple = simple:gsub("%a+", function(w) return w:sub(1,1):upper()..w:sub(2):lower() end)
    return simple
end

local function populateAllyCheckboxes(hero)
    if alliesPopulated then return end
    -- Remove antigos
    for _, cb in pairs(allyCheckboxes) do
        cb:Remove()
    end
    allyCheckboxes = {}
    allyList = {}
    local myTeam = Entity.GetTeamNum(hero)
    local allHeroes = Heroes.GetAll()
    for _, ally in pairs(allHeroes) do
        if ally and Entity.GetTeamNum(ally) == myTeam and ally ~= hero then
            local name = NPC.GetUnitName(ally)
            local friendlyName = getFriendlyName(name)
            table.insert(allyList, name)
            local cb = settingsGroup:Switch("Ally: "..friendlyName, false, "✓")
            cb:SetCallback(function()
                -- nada extra, só marca/desmarca
            end)
            allyCheckboxes[name] = cb
        end
    end
    alliesPopulated = true
end


-- Main Logic
DawnbreakerScript.OnUpdate = function()
    if not settings.masterEnable or not settings.masterEnable:Get() then
        return
    end

    if not Engine.IsInGame() then
        if alliesPopulated then
            alliesPopulated = false
            allyList = {}
        end
        localHero = nil
        return
    end

    local hero = getLocalHero()
    if not hero or NPC.GetUnitName(hero) ~= "npc_dota_hero_dawnbreaker" or not Entity.IsAlive(hero) then
        return
    end

    -- popula checkboxes com segurança
    local ok, perr = pcall(function()
        populateAllyCheckboxes(hero)
    end)
    if not ok then
        Log.Write("Dawnbreaker Helper: erro ao popular aliados: "..tostring(perr))
    end

    local solarGuardian = NPC.GetAbility(hero, "dawnbreaker_solar_guardian")
    if not solarGuardian or not Ability.IsReady(solarGuardian) then
        return
    end

    local minAttackers = settings.minAttackers:Get()
    local checkRadius = settings.checkRadius:Get()
    local hpThreshold = settings.hpThreshold and settings.hpThreshold:Get() or 40
    local allHeroes = Heroes.GetAll()
    for _, name in ipairs(allyList) do
        local cb = allyCheckboxes[name]
        if cb and cb:Get() then
            local allyHero = nil
            for _, h in pairs(allHeroes) do
                if h and NPC.GetUnitName(h) == name and Entity.IsAlive(h) then
                    allyHero = h
                    break
                end
            end
            if allyHero then
                local enemiesNear = Entity.GetHeroesInRadius(allyHero, checkRadius, Enum.TeamType.TEAM_ENEMY, true, true)
                local allyHP = Entity.GetHealth(allyHero)
                local allyMaxHP = Entity.GetMaxHealth(allyHero)
                local allyHPpct = allyMaxHP > 0 and math.floor((allyHP / allyMaxHP) * 100) or 100
                if allyHPpct <= hpThreshold and #enemiesNear >= minAttackers then
                    Ability.CastPosition(solarGuardian, Entity.GetAbsOrigin(allyHero))
                end
            end
        end
    end
end

DawnbreakerScript.OnFrame = function()
    localHero = nil
end

return DawnbreakerScript