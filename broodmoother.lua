--[[
        ~ broodmother helper - uczone.gitbook.io/api-v2.0/
       ~~ jaydenannemayspecial4wind
]]


local leonellibrudo = {}

local function GetConfigPath()
    return "brood_panel.ini"
end

local function LoadPanelPosition()
    local configPath = GetConfigPath()
    local file = io.open(configPath, "r")
    local x, y = 100, 100

    if file then
        for line in file:lines() do
            local xMatch = line:match("pos_x=(%d+)")
            local yMatch = line:match("pos_y=(%d+)")
            if xMatch then x = tonumber(xMatch) end
            if yMatch then y = tonumber(yMatch) end
        end
        file:close()
    end

    return x, y
end

local function SavePanelPosition(x, y)
    local configPath = GetConfigPath()
    local file = io.open(configPath, "w")
    if file then
        file:write(string.format("pos_x=%d\n", x))
        file:write(string.format("pos_y=%d\n", y))
        file:close()
    end
end

local BuiltInWebPoints = {
    radiant = {
        Vector(-201.0,-77.7,116.6), Vector(-1650.3,-1035.8,128.0), Vector(1139.7,926.0,128.0), Vector(-1441.3,-3310.8,128.0),
        Vector(-1073.8,-4963.5,128.0), Vector(937.3,-4405.5,244.2), Vector(3016.3,-5293.7,153.8), Vector(4838.3,-4607.0,128.0),
        Vector(6350.6,-5282.3,128.0), Vector(3007.3,-3204.2,14.0), Vector(4760.9,-6695.1,128.0), Vector(6952.3,-7236.4,256.0),
        Vector(3804.3,-8109.5,8.0), Vector(1358.6,-6705.8,8.0), Vector(-572.4,-7852.3,136.0), Vector(-2781.3,-7820.2,136.0),
        Vector(432.3,-2011.2,128.0), Vector(-3359.8,-2404.2,128.0), Vector(-4038.6,-128.5,256.0), Vector(-6294.8,-81.0,128.0),
        Vector(-7853.7,-720.1,256.0), Vector(-5477.0,1837.9,128.0), Vector(-7644.1,1684.1,256.0), Vector(-7946.9,3872.9,128.0),
        Vector(-7209.8,5891.9,128.0), Vector(-7249.5,7903.7,256.0), Vector(-5578.5,4211.5,128.0), Vector(-5522.4,6315.3,128.0),
        Vector(-3559.2,4280.8,140.4), Vector(-1561.8,4555.9,136.0), Vector(-3146.4,6256.3,128.0), Vector(-4126.5,8058.1,17.9),
        Vector(-1280.8,7674.4,256.0), Vector(782.5,7706.2,134.0), Vector(2627.1,7279.6,134.0), Vector(1627.7,5371.9,128.0),
        Vector(-1262.3,2169.0,256.0), Vector(287.8,3399.1,136.0), Vector(2294.0,2973.3,128.0), Vector(3097.4,1399.3,128.0),
        Vector(4161.7,-441.1,256.0), Vector(1980.0,-1044.2,256.0), Vector(5165.5,1637.2,128.0), Vector(7498.3,1572.4,256.0),
        Vector(7553.4,-640.2,194.5), Vector(5925.3,-1202.9,128.0), Vector(6223.9,-3209.6,128.0), Vector(-333.4,-6524.6,128.0),
        Vector(-2538.9,698.8,0.0), Vector(-3304.7,2564.7,74.9), Vector(-7291.8,2830.6,52.2)
    },
    dire = {
        Vector(577.4,220.4,128.0), Vector(-876.4,-695.2,128.0), Vector(623.2,-1765.3,128.0), Vector(-2676.0,389.6,128.0),
        Vector(-1115.8,1490.1,128.0), Vector(-4499.0,589.8,256.0), Vector(-6297.6,1723.0,128.0), Vector(-4719.2,2781.3,0.0),
        Vector(-1705.4,-2356.7,128.0), Vector(-3187.1,-1237.9,256.0), Vector(-1578.5,-4574.9,128.0), Vector(615.3,-4684.3,136.0),
        Vector(144.2,-3264.8,256.0), Vector(2740.0,-4209.9,256.0), Vector(4773.7,-4620.6,128.0), Vector(3174.1,-6286.9,128.0),
        Vector(5171.5,-6917.3,128.0), Vector(6710.5,-5165.4,128.0), Vector(7340.3,-7211.4,256.0), Vector(3485.5,-8188.2,8.0),
        Vector(1301.2,-7854.0,134.0), Vector(-883.8,-7865.6,136.0), Vector(-2983.0,-7481.6,131.9), Vector(-2115.3,-6160.5,128.0),
        Vector(-3850.4,-4844.2,256.0), Vector(-4180.6,-2536.2,128.0), Vector(-6439.4,-2212.2,128.0), Vector(-7913.8,-946.2,256.0),
        Vector(-7952.4,1369.9,256.0), Vector(-4801.4,-1009.6,256.0), Vector(2687.5,-98.2,240.9), Vector(4333.0,-652.1,256.0),
        Vector(6481.7,-433.7,128.0), Vector(7971.8,757.7,256.0), Vector(7933.0,-2114.0,256.0), Vector(5397.7,-2473.7,128.0),
        Vector(1011.2,2511.2,128.0), Vector(126.7,4245.9,136.0), Vector(-1915.0,4310.5,256.0), Vector(-1035.0,2883.5,256.0),
        Vector(-4098.5,4298.6,128.0), Vector(-6145.8,3511.2,128.0), Vector(-7861.2,4548.8,128.0), Vector(-7044.3,6549.5,256.0),
        Vector(-5528.9,5512.7,128.0), Vector(-5069.2,7786.7,8.0), Vector(-2878.3,7706.6,8.0), Vector(-2966.6,5917.6,128.0),
        Vector(-216.3,5558.3,128.0), Vector(1369.2,7798.8,142.5), Vector(1703.4,5670.7,128.0), Vector(4132.2,1559.8,128.0),
        Vector(6327.4,1596.6,128.0), Vector(2893.6,3347.3,128.0), Vector(2185.7,1661.9,128.0), Vector(2418.7,-3067.0,0.0),
        Vector(4123.6,-2100.7,0.0), Vector(-2959.7,2653.2,0.0)
    },
    -- ne nado (fallback)
    neutral = {}
}

-- general check
local function IsBroodmother()
    local myHero = Heroes.GetLocal()
    return myHero and NPC.GetUnitName(myHero) == "npc_dota_hero_broodmother"
end

local Config = {
    UI = {
        TabName = "Heroes",
        ScriptName = "Hero List",
        ScriptID = "Broodmother",
        Icons = {
            Main = "\u{f188}",
            Soul = "\u{f06e}",
            Gather = "\u{f0c0}",
            Juggle = "\u{f110}",
            Blood = "\u{f219}"
        },
        Groups = {
            Main = "Principal",
            AutoCast = "Auto Cast",
            SpiderControl = "Controle de Aranhas",
            Items = "Itens",
            WebHelper = "Ajuda de Teias",
            AutoStack = "Auto Stack"
        }
    },
    Colors = {
        Text = {
            Primary = Color(255, 255, 255),
            Shadow = Color(0, 0, 0)
        },
        Panel = {
            Background = Color(20, 20, 25, 220),
            Header = Color(139, 69, 19, 200),
            Shadow = Color(0, 0, 0, 100)
        }
    },
    Fonts = {
        Main = Render.LoadFont("SF Pro Text", Enum.FontCreate.FONTFLAG_ANTIALIAS)
    },
    Juggle = {
        DefaultRadius = 885,
        DefaultCount = 5
    }
}

local function InitializeUI()
    local tab = Menu.Create(Config.UI.TabName, Config.UI.ScriptName, Config.UI.ScriptID)

    local mainSettings = tab:Create("Main Settings")
    local mainGroup = mainSettings:Create(Config.UI.Groups.Main)
    local spiderGroup = mainSettings:Create(Config.UI.Groups.SpiderControl)
    local itemsGroup = mainSettings:Create(Config.UI.Groups.Items)
    local webGroup = mainSettings:Create(Config.UI.Groups.WebHelper)
    local stackGroup = mainSettings:Create(Config.UI.Groups.AutoStack)

    return {
        Enabled = mainGroup:Switch("Ativar Script", true, Config.UI.Icons.Main),
        ShowPanel = mainGroup:Switch("Mostrar Painel", true),

        GatherKey = spiderGroup:Bind("Reunir Aranhas", Enum.ButtonCode.KEY_NONE, Config.UI.Icons.Gather),
        -- juggling spiders bro salam alaikum 2022 mindset
        JuggleKey = spiderGroup:Bind("Espalhar Aranhas para Visão", Enum.ButtonCode.KEY_NONE, Config.UI.Icons.Juggle),
        AlwaysSpread = spiderGroup:Switch("Sempre Espalhar Aranhas", false, Config.UI.Icons.Juggle),
        JuggleRadius = spiderGroup:Slider("Raio de Espalhamento", 100, 2000, Config.Juggle.DefaultRadius, "%d"),
        JuggleCount = spiderGroup:Slider("Número de Aranhas a Espalhar", 1, 10, Config.Juggle.DefaultCount, "%d"),
        GatherDelay = spiderGroup:Slider("Atraso Entre Comandos (ms)", 50, 300, 50, "%d"),

        AutoSoulRing = itemsGroup:Switch("Soul Ring Automático na Ultimate", true, Config.UI.Icons.Soul),
        SmartBloodthorn = itemsGroup:Switch("Espinho Sangrento Inteligente", true, Config.UI.Icons.Blood),
        BloodthornDelay = itemsGroup:Slider("Atraso do Espinho Sangrento (ms)", 0, 100, 20, "%d"),


        WebHelperEnabled = webGroup:Switch("Mostrar Pontos de Teia", true),
        ShowWebPointsOnlyAlt = webGroup:Switch("Mostrar Apenas com ALT Pressionado", false),
        WebClickToCast = webGroup:Switch("Clicar na Célula Lança Teia", true),
        ShowCursorCoords = webGroup:Switch("Mostrar Coordenadas do Cursor", false),

        AutoStackEnabled = stackGroup:Switch("Empilhamento Automático de Camps", false),
        AutoStackToggleKey = stackGroup:Bind("Alternar Empilhamento Automático", Enum.ButtonCode.KEY_NONE, Config.UI.Icons.Juggle),
        AutoStackSecond = stackGroup:Slider("Segundo de Início", 0, 59, 45, "%d"),
        AutoStackAttackSecond = stackGroup:Slider("Segundo de Ataque", 0, 59, 54, "%d"),
        AutoStackWaitDistance = stackGroup:Slider("Distância de Espera", 200, 1000, 350, "%d"),
        AutoStackRetreatDistance = stackGroup:Slider("Distância de Recuo", 300, 1500, 1330, "%d"),
        AutoStackCount = stackGroup:Slider("Quantas Aranhas Enviar", 1, 6, 4, "%d"),
        AutoStackSides = stackGroup:MultiCombo("Quais Camps Empilhar", {"Aliados", "Inimigos"}, {"Aliados", "Inimigos"}),

    }
end

local UI = InitializeUI()

local panelX, panelY = LoadPanelPosition()

local State = {
    spiders = {},
    lastSoulRingTime = 0,
    lastUltTime = 0,
    juggling = false,
    juggleAngle = 0,
    lastJuggleTime = 0,
    lastGatherTime = 0,
    lastGatherPos = nil,
    lastGatherSpiderCount = 0,
    spiderlingCount = 0,
    spideriteCount = 0,
    juggleTime = 0,
    pendHS = 0,
    panelPos = {x = panelX, y = panelY},
    isDragging = false,
    dragOffset = {x = 0, y = 0},
    -- Dota occasionally crashed here; keep simple throttling
    -- throttling utility
    btNextCheck = 0,
    btCheckInterval = 0.12,
    panelAnimation = {
        cellsAlpha = 0,
        titleAlpha = 255,
        headerAlpha = 255,
        cellsTargetAlpha = 0,
        titleTargetAlpha = 255,
        headerTargetAlpha = 255,
        lastSpiderCount = 0,
        headerInCellsPosition = true
    },
    killCandidateName = nil,
    webPoints = BuiltInWebPoints,
    webAltAlpha = 0,
    webAltLastActive = false,
    webMouseWasDown = false,
    stackAssignments = {},
    stackRetreats = {},
    stackOrderBypass = {},
    stackLocked = {},
    spreadSpiderIndices = {},
    lastSpreadTime = 0
}

local function GetAllSpiders()
    local myHero = Heroes.GetLocal()
    if not myHero then return {} end

    local playerId = Hero.GetPlayerID(myHero)
    local allNPCs = NPCs.GetAll()
    local result = {}
    local spiderlingCount = 0

    for _, npc in ipairs(allNPCs) do
        if Entity.IsAlive(npc) and Entity.IsControllableByPlayer(npc, playerId) then
            local unitName = NPC.GetUnitName(npc)
            if unitName == "npc_dota_broodmother_spiderling" then
                table.insert(result, npc)
                spiderlingCount = spiderlingCount + 1
            end
        end
    end

    State.spiderlingCount = spiderlingCount
    State.spideriteCount = 0

    return result
end


-- sort spiders by remaining lifetime
local function GetSpiderRemainingLife(spider)
    if not spider then return 0 end
    local mods = NPC.GetModifiers(spider)
    if not mods or #mods == 0 then return 0 end
    local now = GameRules.GetGameTime()
    local best = 0
    for _, m in ipairs(mods) do
        local die = Modifier.GetDieTime(m)
        if die and die > 0 then
            local rem = die - now
            if rem > best then best = rem end
        end
    end
    return best
end

local CachedCampPositions = nil
local function GetCampPositions()
    if CachedCampPositions then return CachedCampPositions end
    CachedCampPositions = {}
    local camps = Camps.GetAll()
    if camps then
        for _, camp in ipairs(camps) do
            local pos = Entity.GetAbsOrigin and Entity.GetAbsOrigin(camp) or nil
            if pos then table.insert(CachedCampPositions, pos) end
        end
    end
    return CachedCampPositions
end

local function GetNearestCampPos(fromPos)
    local camps = GetCampPositions()
    if not camps or #camps == 0 or not fromPos then return nil end
    local bestPos, bestD2 = nil, math.huge
    for _, cp in ipairs(camps) do
        local dx, dy = cp.x - fromPos.x, cp.y - fromPos.y
        local d2 = dx*dx + dy*dy
        if d2 < bestD2 then bestD2, bestPos = d2, cp end
    end
    return bestPos
end

local CachedCampData = nil
local function GetCampData()
    if CachedCampData then return CachedCampData end
    CachedCampData = {}
    local camps = Camps.GetAll()
    if camps then
        for _, camp in ipairs(camps) do
            local pos = Entity.GetAbsOrigin and Entity.GetAbsOrigin(camp) or nil
            if pos then table.insert(CachedCampData, {pos = pos}) end
        end
    end
    return CachedCampData
end

-- retreat offset relative to team side
local function GetCampPullOffset(myHero, campPos)
    local team = myHero and Entity.GetTeamNum(myHero) or nil

    local dir = Vector(0,0,0)
    if team == Enum.TeamNum.TEAM_RADIANT then
        dir = Vector(-1, -1, 0)
    elseif team == Enum.TeamNum.TEAM_DIRE then
        dir = Vector(1, 1, 0)
    else
        dir = Vector(-1, -1, 0)
    end
    local len = math.sqrt(dir.x*dir.x + dir.y*dir.y)
    if len > 0 then dir = Vector(dir.x/len, dir.y/len, 0) end
    local offset = 350
    return Vector(campPos.x + dir.x * offset, campPos.y + dir.y * offset, campPos.z)
end

-- filter camps by selected side
local function GetPreferredCampPos(myHero)
    local sides = UI.AutoStackSides:ListEnabled()
    local team = myHero and Entity.GetTeamNum(myHero) or nil
    local heroPos = myHero and Entity.GetAbsOrigin(myHero) or nil
    if not heroPos then return nil end

    local camps = GetCampData()
    if not camps or #camps == 0 then return nil end

    local onlyAllied = (#sides == 1 and sides[1] == "Aliados")
    local onlyEnemy  = (#sides == 1 and sides[1] == "Inimigos")

    local bestPos, bestD2 = nil, math.huge
    for _, c in ipairs(camps) do
        local cp = c.pos
        if cp then
            local dx, dy = cp.x - heroPos.x, cp.y - heroPos.y
            local d2 = dx*dx + dy*dy
            local score = d2
            local ok = true
            if onlyAllied then
                if team == Enum.TeamNum.TEAM_RADIANT then
                    ok = (cp.x + cp.y) < 0
                elseif team == Enum.TeamNum.TEAM_DIRE then
                    ok = (cp.x + cp.y) > 0
                end
            elseif onlyEnemy then
                if team == Enum.TeamNum.TEAM_RADIANT then
                    ok = (cp.x + cp.y) > 0
                elseif team == Enum.TeamNum.TEAM_DIRE then
                    ok = (cp.x + cp.y) < 0
                end
            end
            if ok and score < bestD2 then bestD2, bestPos = score, cp end
        end
    end
    return bestPos
end

local function GetPullDirection(waitPos, campPos)
    local dx, dy = campPos.x - waitPos.x, campPos.y - waitPos.y
    local len = math.sqrt(dx*dx + dy*dy)
    if len <= 0.0001 then return Vector(1, 0, 0) end
    return Vector(dx/len, dy/len, 0)
end

local function GetCampWaitPos(myHero, campPos)
    local team = myHero and Entity.GetTeamNum(myHero) or nil
    local dir = Vector(0,0,0)
    if team == Enum.TeamNum.TEAM_RADIANT then
        dir = Vector(-1, -1, 0)
    elseif team == Enum.TeamNum.TEAM_DIRE then
        dir = Vector(1, 1, 0)
    else
        dir = Vector(-1, -1, 0)
    end
    local len = math.sqrt(dir.x*dir.x + dir.y*dir.y)
    if len > 0 then dir = Vector(dir.x/len, dir.y/len, 0) end
    local offset = math.max(200, UI.AutoStackWaitDistance and UI.AutoStackWaitDistance:Get() or 450)
    return Vector(campPos.x + dir.x * offset, campPos.y + dir.y * offset, campPos.z)
end

local function GetCampRetreatPos(myHero, campPos, waitPos)
    local pullDir = GetPullDirection(waitPos, campPos)
    local side = Vector(pullDir.y, -pullDir.x, 0)
    local center = Vector(0,0,0)
    local basePos = Entity.GetAbsOrigin(myHero)
    local distPlus = (campPos.x + side.x - center.x)^2 + (campPos.y + side.y - center.y)^2
    local distMinus = (campPos.x - side.x - center.x)^2 + (campPos.y - side.y - center.y)^2
    if distMinus > distPlus then side = Vector(-side.x, -side.y, 0) end
    local len = math.sqrt(side.x*side.x + side.y*side.y)
    if len > 0 then side = Vector(side.x/len, side.y/len, 0) end
    local retreatDist = math.max(350, UI.AutoStackRetreatDistance and UI.AutoStackRetreatDistance:Get() or 900)
    return Vector(waitPos.x + side.x * retreatDist, waitPos.y + side.y * retreatDist, waitPos.z)
end

local function GetClockData()
    local realNow = GameRules.GetGameTime()
    local startTime = (GameRules.GetGameStartTime and GameRules.GetGameStartTime()) or 0
    local clockNow = realNow - startTime
    if clockNow < 0 then clockNow = 0 end
    local totalSec = math.floor(clockNow)
    local curMin = math.floor(totalSec / 60)
    local curSec = totalSec % 60
    return realNow, clockNow, totalSec, curMin, curSec, startTime
end

-- custom spider lock approach; selection can still move all spiders
-- so we additionally filter selection below.
local lastStackMinute = -1
-- pop/push
local function PushBypassFor(unit, identifier)
    if not unit then return end
    State.stackOrderBypass[unit] = identifier or true
end

local function PopBypassFor(unit, identifier)
    if not unit then return end
    if not identifier or State.stackOrderBypass[unit] == identifier then
        State.stackOrderBypass[unit] = nil
    end
end

local function IsBypassAllowed(unit, identifier)
    if not unit then return false end
    local v = State.stackOrderBypass[unit]
    return v == true or v == identifier
end

local function LockSpider(spider, untilTime)
    if not spider then return end
    local idx = Entity.GetIndex(spider)
    State.stackLocked[idx] = math.max(State.stackLocked[idx] or 0, untilTime or (GameRules.GetGameTime() + 5))
end

local function UnlockSpider(spider)
    if not spider then return end
    local idx = Entity.GetIndex(spider)
    State.stackLocked[idx] = nil
end

local function IsSpiderHLock(spider)
    if not spider then return false end
    local idx = Entity.GetIndex(spider)
    local t = State.stackLocked[idx]
    return t ~= nil and GameRules.GetGameTime() < t
end

local function IsSpiderInSpread(unit)
    if not unit then return false end
    local idx = Entity.GetIndex(unit)
    return State.spreadSpiderIndices[idx] == true
end

local function IsSpiderStackLocked(unit)
    if not unit then return false end
    -- SEMPRE verifica o lock de tempo primeiro (usado por stack E spread)
    if IsSpiderHLock(unit) then return true end
    for _, it in ipairs(State.stackAssignments) do
        if it.spider == unit then return true end
    end
    for _, it in ipairs(State.stackRetreats) do
        if it.spider == unit then return true end
    end
    return false
end

local function AutoStack()
    local realNow, clockNow, totalSec, curMin, curSec, startTime = GetClockData()
    local startSec = UI.AutoStackSecond:Get()
    local attackSec = UI.AutoStackAttackSecond:Get()

    if not UI.AutoStackEnabled:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myPlayer = Players.GetLocal()

    if curSec == startSec and lastStackMinute ~= curMin then
        local spiders = GetAllSpiders()
        if #spiders == 0 then lastStackMinute = curMin; return end
        table.sort(spiders, function(a,b) return GetSpiderRemainingLife(a) > GetSpiderRemainingLife(b) end)
        local sendCount = math.min(UI.AutoStackCount:Get(), #spiders)

        local heroPos = Entity.GetAbsOrigin(myHero)
        local camps = GetCampData()
        if not camps or #camps == 0 then lastStackMinute = curMin; return end
        local sides = UI.AutoStackSides:ListEnabled()
        local team = Entity.GetTeamNum(myHero)
        local onlyAllied = (#sides == 1 and sides[1] == "Aliados")
        local onlyEnemy  = (#sides == 1 and sides[1] == "Inimigos")
        local filtered = {}
        for _, c in ipairs(camps) do
            local cp = c.pos
            if cp then
                local ok = true
                if onlyAllied then
                    if team == Enum.TeamNum.TEAM_RADIANT then ok = (cp.x + cp.y) < 0 else ok = (cp.x + cp.y) > 0 end
                elseif onlyEnemy then
                    if team == Enum.TeamNum.TEAM_RADIANT then ok = (cp.x + cp.y) > 0 else ok = (cp.x + cp.y) < 0 end
                end
                if ok then
                    local dx, dy = cp.x - heroPos.x, cp.y - heroPos.y
                    local d2 = dx*dx + dy*dy
                    table.insert(filtered, {pos = cp, d2 = d2})
                end
            end
        end
        table.sort(filtered, function(a,b) return a.d2 < b.d2 end)
        if #filtered == 0 then lastStackMinute = curMin; return end

        State.stackAssignments = {}
        for i = 1, math.min(sendCount, #filtered) do
            local spider = spiders[i]
            local campCenter = filtered[i].pos
            if spider and campCenter then
                local waitPos = GetCampWaitPos(myHero, campCenter)
                PushBypassFor(spider, "auto_stack_wait")
                Player.PrepareUnitOrders(
                    myPlayer,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    waitPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    spider,
                    false,
                    false,
                    false,
                    false,
                    "auto_stack_wait"
                )
                -- not ideal, but works
                LockSpider(spider, GameRules.GetGameTime() + math.max(attackSec - curSec + 2, 5))
                table.insert(State.stackAssignments, {spider = spider, camp = campCenter, wait = waitPos})
            end
        end
        lastStackMinute = curMin
    end

    if curSec == attackSec and State.stackAssignments and #State.stackAssignments > 0 then
        for _, asg in ipairs(State.stackAssignments) do
            local spider = asg.spider
            local campCenter = asg.camp
            local waitPos = asg.wait
            if spider and Entity.IsAlive(spider) then
                PushBypassFor(spider, "auto_stack_attack")
                Player.PrepareUnitOrders(
                    myPlayer,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
                    nil,
                    campCenter,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    spider,
                    false,
                    false,
                    false,
                    false,
                    "auto_stack_attack"
                )

                local retreatPos = GetCampRetreatPos(myHero, campCenter, waitPos)
                LockSpider(spider, GameRules.GetGameTime() + 3.5)
                table.insert(State.stackRetreats, {spider = spider, wait = retreatPos, when = realNow + 1})
            end
        end

        State.stackAssignments = {}
    end

    if State.stackRetreats and #State.stackRetreats > 0 then
        for i = #State.stackRetreats, 1, -1 do
            local it = State.stackRetreats[i]
            if realNow >= (it.when or 0) then
                local spider = it.spider
                local waitPos = it.wait
                if spider and Entity.IsAlive(spider) and waitPos then
                    PushBypassFor(spider, "auto_stack_retreat")
                    Player.PrepareUnitOrders(
                        myPlayer,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        nil,
                        waitPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        spider,
                        false,
                        false,
                        false,
                        true,
                        "auto_stack_retreat"
                    )
                    LockSpider(spider, GameRules.GetGameTime() + 2.0)
                end
                table.remove(State.stackRetreats, i)
            end
        end
    end
end

local function AutoSoulRing()
    if not UI.AutoSoulRing:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local spawnSpiderlings = NPC.GetAbility(myHero, "broodmother_spawn_spiderlings")
    if not spawnSpiderlings then return end
    local soulRing = NPC.GetItem(myHero, "item_soul_ring")
    if not soulRing then return end
    local ultReady = Ability.IsCastable(spawnSpiderlings, NPC.GetMana(myHero))
    local soulRingActive = NPC.HasModifier(myHero, "modifier_item_soul_ring_buff")
    if ultReady and not soulRingActive and Ability.IsCastable(soulRing, 0) then
        if Ability.IsInAbilityPhase(spawnSpiderlings) then
            Ability.CastNoTarget(soulRing)
            State.lastSoulRingTime = GameRules.GetGameTime()
        end
    end
end

-- gather spiders into one point; original method kept for stability
-- TODO: improve movement convergence later.
local function GatherSpiders()
    if not UI.GatherKey:IsPressed() then return end

    local currentTime = GameRules.GetGameTime()
    local gatherDelay = UI.GatherDelay:Get() / 1000

    if currentTime - State.lastGatherTime < gatherDelay then return end

    local myHero = Heroes.GetLocal()
    if not myHero then return end

    local cursorPos = Input.GetWorldCursorPos()

    if not cursorPos then
        cursorPos = Entity.GetAbsOrigin(myHero)
    end

    local spiders = GetAllSpiders()

    State.juggling = false

    State.lastGatherSpiderCount = #spiders
    State.lastGatherTime = currentTime
    State.lastGatherPos = cursorPos

    if #spiders > 0 then
        local myPlayer = Players.GetLocal()

        Player.ClearSelectedUnits(myPlayer)

        for _, spider in ipairs(spiders) do
            if Entity.IsAlive(spider) and Entity.IsControllableByPlayer(spider, Hero.GetPlayerID(myHero)) then
                Player.AddSelectedUnit(myPlayer, spider)
            end
        end

        Player.PrepareUnitOrders(
            myPlayer,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            cursorPos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,
            nil,
            false,
            false,
            false,
            false,
            "brood_gather"
        )

        State.pendHS = currentTime + 0.1
    end
end

-- spider juggling
local function JuggleSpiders()
    local alwaysSpread = UI.AlwaysSpread:Get()
    local keyPressed = UI.JuggleKey:IsPressed()
    
    -- Ativa se pressionar a tecla OU se "Always Spread" estiver ligado
    if not keyPressed and not alwaysSpread then 
        -- Se desligou, limpa a lista de spread
        State.spreadSpiderIndices = {}
        return 
    end

    -- Se Always Spread estiver ativo, limita a frequência de atualização
    local now = GameRules.GetGameTime()
    if alwaysSpread then
        if now - State.lastSpreadTime < 1.5 then return end
        State.lastSpreadTime = now
    end

    local myHero = Heroes.GetLocal()
    if not myHero then return end

    local heroPos = Entity.GetAbsOrigin(myHero)
    local radius = UI.JuggleRadius:Get()
    local spiders = GetAllSpiders()
    local count = math.min(UI.JuggleCount:Get(), #spiders)

    if count > 0 then
        local myPlayer = Players.GetLocal()

        -- Limpa e reconstrói a lista de índices de spread
        State.spreadSpiderIndices = {}
        for i = 1, count do
            if spiders[i] and Entity.IsAlive(spiders[i]) then
                local idx = Entity.GetIndex(spiders[i])
                State.spreadSpiderIndices[idx] = true
                
                -- IMPORTANTE: Bloqueia a aranha com tempo MAIOR para cobrir até a próxima atualização
                local lockTime = now + 10.0
                LockSpider(spiders[i], lockTime)
            end
        end

        -- Envia comandos de movimento
        for i = 1, count do
            if spiders[i] then
                local angle = (i - 1) * (2 * math.pi / count)
                local x = heroPos.x + radius * math.cos(angle)
                local y = heroPos.y + radius * math.sin(angle)
                local targetPos = Vector(x, y, heroPos.z)

                -- Marca a aranha com bypass para comandos internos
                PushBypassFor(spiders[i], "brood_juggle")

                Player.PrepareUnitOrders(
                    myPlayer,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    targetPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    spiders[i],
                    false,
                    false,
                    false,
                    false,
                    "brood_juggle"
                )
            end
        end

        -- NÃO limpa seleção - deixa o usuário no controle
    end

    State.juggling = true
    State.juggleTime = GameRules.GetGameTime()
end


-- this method is technically correct, despite odd behavior
local GetEffectivePDMG
local GetEffectiveMDMG
local OneTickHitToTarget

local function SmartBloodthorn()
    if not UI.SmartBloodthorn:Get() then return end

    local myHero = Heroes.GetLocal()
    if not myHero then return end

    local bloodthorn = NPC.GetItem(myHero, "item_bloodthorn")
    if not bloodthorn or not Ability.IsCastable(bloodthorn, NPC.GetMana(myHero)) then 
        return 
    end

    -- throttling to avoid occasional crashes
    local now = GameRules.GetGameTime()
    if now < (State.btNextCheck or 0) then return end
    State.btNextCheck = now + (State.btCheckInterval or 0.12)

    local enemies = Entity.GetHeroesInRadius(myHero, 900, Enum.TeamType.TEAM_ENEMY, true)
    if #enemies == 0 then
        State.killCandidateName = nil
        return
    end

    local spiders = GetAllSpiders()

    if not spiders or #spiders == 0 then
        State.killCandidateName = nil
        return
    end

    if State.killCandidateName then
        local currentTarget = nil
        for _, enemy in ipairs(enemies) do
            if NPC.GetUnitName(enemy) == State.killCandidateName then
                currentTarget = enemy
                break
            end
        end

        if not currentTarget then
            State.killCandidateName = nil
        else
            local attackingCount = 0
            for _, spider in ipairs(spiders) do
                if NPC.IsAttacking(spider) and NPC.IsEntityInRange(spider, currentTarget, (NPC.GetAttackRange(spider) or 0) + 50) then
                    attackingCount = attackingCount + 1
                end
            end

            if attackingCount < 2 then
                State.killCandidateName = nil
            end
        end
    end

    local bestTarget = nil
    local bestScore = -1

    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) and NPC.IsVisible(enemy) then
            if NPC.IsLinkensProtected(enemy) or NPC.IsMirrorProtected(enemy) then goto continue end
            if NPC.HasState and NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then goto continue end

            local manta = NPC.GetItem(enemy, "item_manta")
            if not manta or Ability.GetCooldown(manta) ~= 0 then goto continue end

            local anyClose = false
            local closeCount = 0
            for i = 1, math.min(#spiders, 12) do
                local s = spiders[i]
                if s and Entity.IsAlive(s) then
                    local rng = (NPC.GetAttackRange(s) or 0) + 50
                    if NPC.IsEntityInRange(s, enemy, rng) then
                        anyClose = true
                        closeCount = closeCount + 1
                        if closeCount >= 2 then break end
                    end
                end
            end
            if not anyClose then goto continue end

            local hp = Entity.GetHealth(enemy)
            local physSum, hitters = OneTickHitToTarget(spiders, enemy)
            if hitters == 0 then goto continue end
            local extraMag = GetEffectiveMDMG(25 * hitters, enemy)
            local totalOneTick = physSum + extraMag
            if totalOneTick >= hp then
                local score = hp
                if score > bestScore then bestScore = score; bestTarget = enemy end
            end
        end
        ::continue::
    end

    if bestTarget then
        local targetName = NPC.GetUnitName(bestTarget)
        -- Log.Write("bt: " .. targetName .. " | lethal")
        Ability.CastTarget(bloodthorn, bestTarget)
        State.killCandidateName = targetName
        return
    end

    State.killCandidateName = nil
end

local PanelConfig = {
    Width = 200,
    Height = 50,
    HeaderHeight = 26,
    CellSize = 26,
    CellSpacing = 5,
    BorderRadius = 8,
    ShadowOffset = 2,
    BlurStrength = 15,
    BlurStrengthHeader = 10
}

local PanelColors = {
    Background = Color(20, 20, 25, 220),
    BackgroundHover = Color(25, 25, 30, 230),
    Border = Color(60, 60, 70, 180),
    BorderHover = Color(80, 120, 255, 200),
    Header = Color(10, 10, 10, 200),
    HeaderText = Color(255, 255, 255, 255),
    Shadow = Color(0, 0, 0, 100),
    StatusColors = {
        ["Collect"] = Color(120, 255, 120, 255),
        ["Split"] = Color(255, 120, 255, 255),
        ["Attack"] = Color(255, 80, 80, 255),
        ["Idle"] = Color(180, 180, 180, 255),
        ["HP"] = Color(120, 200, 255, 255)
    }
}

local function HandlePanelInput()
    local cursorX, cursorY = Input.GetCursorPos()

    local headerY = State.panelPos.y
    if State.panelAnimation.headerInCellsPosition then
        headerY = State.panelPos.y + PanelConfig.HeaderHeight + 5
    end

    local isInHeader = cursorX >= State.panelPos.x and cursorX <= State.panelPos.x + PanelConfig.Width and
                      cursorY >= headerY and cursorY <= headerY + PanelConfig.HeaderHeight

    if isInHeader and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) and not State.isDragging then
        State.isDragging = true
        State.dragOffset.x = cursorX - State.panelPos.x
        State.dragOffset.y = cursorY - State.panelPos.y
    end

    if State.isDragging then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
            State.panelPos.x = cursorX - State.dragOffset.x
            State.panelPos.y = cursorY - State.dragOffset.y

            local screenSize = Render.ScreenSize()
            State.panelPos.x = math.max(0, math.min(State.panelPos.x, screenSize.x - PanelConfig.Width))
            State.panelPos.y = math.max(0, math.min(State.panelPos.y, screenSize.y - PanelConfig.Height))
        else
            State.isDragging = false

            SavePanelPosition(State.panelPos.x, State.panelPos.y)
        end
    end
end

local function DrawBlurredBackground(x, y, width, height, radius, blurStrength, alpha)
    Render.Blur(
        Vec2(x, y),
        Vec2(x + width, y + height),
        blurStrength,
        alpha,
        radius,
        Enum.DrawFlags.None
    )
end

local function DrawCell(x, y, alpha, text, fontSize, textColor)
    local size = PanelConfig.CellSize
    DrawBlurredBackground(x, y, size, size, 6, 8, 0.97 * (alpha / 255))
    Render.Shadow(
        Vec2(x, y),
        Vec2(x + size, y + size),
        Color(0, 0, 0, math.floor(alpha)),
        24,
        6,
        Enum.DrawFlags.ShadowCutOutShapeBackground,
        Vec2(1, 1)
    )
    Render.FilledRect(
        Vec2(x, y),
        Vec2(x + size, y + size),
        Color(0, 0, 0, math.floor(140 * alpha / 255)),
        6
    )

    local textSize = Render.TextSize(Config.Fonts.Main, fontSize, text)
    local textX = x + (size - textSize.x) / 2
    local textY = y + (size - textSize.y) / 2

    Render.Text(Config.Fonts.Main, fontSize, text, Vec2(textX + 1, textY + 1), Color(0, 0, 0, math.floor(alpha * 0.4)))
    Render.Text(Config.Fonts.Main, fontSize, text, Vec2(textX, textY), Color(textColor.r, textColor.g, textColor.b, math.floor(alpha)))
end

local HeroIconCache = {}

local function GetHeroIconHandle(unitName)
    if not unitName then return nil end
    if HeroIconCache[unitName] then return HeroIconCache[unitName] end
    local path = "panorama/images/heroes/icons/" .. unitName .. "_png.vtex_c"
    local handle = Render.LoadImage(path)
    HeroIconCache[unitName] = handle
    return handle
end

local AbilityIconCache = {}
local function GetAbilityIconHandle(abilityName)
    if not abilityName then return nil end
    if AbilityIconCache[abilityName] then return AbilityIconCache[abilityName] end
    local path = "panorama/images/spellicons/" .. abilityName .. "_png.vtex_c"
    local handle = Render.LoadImage(path)
    AbilityIconCache[abilityName] = handle
    return handle
end

local function DrawIconCell(x, y, alpha, imageHandle, scale, rounding)
    local size = PanelConfig.CellSize
    DrawBlurredBackground(x, y, size, size, 6, 8, 0.97 * (alpha / 255))
    Render.Shadow(
        Vec2(x, y),
        Vec2(x + size, y + size),
        Color(0, 0, 0, math.floor(alpha)),
        24,
        6,
        Enum.DrawFlags.ShadowCutOutShapeBackground,
        Vec2(1, 1)
    )
    Render.FilledRect(
        Vec2(x, y),
        Vec2(x + size, y + size),
        Color(0, 0, 0, math.floor(140 * alpha / 255)),
        6
    )

    if imageHandle then
        local basePad = 2
        local iconScale = math.max(0.5, math.min(scale or 1.0, 1.0))
        local inner = (size - basePad * 2)
        local iconSize = math.floor(inner * iconScale)
        local offset = math.floor((inner - iconSize) / 2)
        local pos = Vec2(x + basePad + offset + 0.5, y + basePad + 1 + offset)
        local sz = Vec2(iconSize, iconSize)
        local r = rounding or 0
        r = math.max(0, math.min(r, math.floor(iconSize / 2)))
        Render.Image(imageHandle, pos, sz, Color(255, 255, 255, math.floor(alpha)), r)
    end
end

-- damage calculation
GetEffectivePDMG = function(attacker, target)
    if not attacker or not target then return 0 end
    local minD = NPC.GetTrueDamage(attacker) or 0
    local maxD = NPC.GetTrueMaximumDamage(attacker) or minD
    local avg = (minD + maxD) * 0.5
    local mult = NPC.GetArmorDamageMultiplier(target) or 1
    return avg * mult
end

GetEffectiveMDMG = function(amount, target)
    local mult = NPC.GetMagicalArmorDamageMultiplier(target) or 1
    return amount * mult
end

OneTickHitToTarget = function(spiders, target)
    local sum = 0
    local inRange = 0
    if not spiders or not target then return 0, 0 end
    if type(spiders) ~= "table" then return 0, 0 end

    for _, spider in ipairs(spiders) do
        if spider and Entity.IsAlive(spider) then
            local range = (NPC.GetAttackRange(spider) or 0) + 50
            if NPC.IsEntityInRange(spider, target, range) then
                sum = sum + GetEffectivePDMG(spider, target)
                inRange = inRange + 1
            end
        end
    end
    return sum, inRange
end

-- FIXME: ideally add a function to track spider hits and apply Bloodthorn tick-by-tick.

local function GetSpiderStatus(spiders)
    spiders = spiders or GetAllSpiders()
    local totalSpiders = #spiders

    if totalSpiders == 0 then
        return "0", "Aguardando"
    end

    local status = "Aguardando"
    if State.juggling and (GameRules.GetGameTime() - State.juggleTime < 3) then
        status = "Espalhar"
    elseif State.lastGatherPos and (GameRules.GetGameTime() - State.lastGatherTime < 2) then
        status = "Reunir"
    else
        local attackingCount = 0
        for _, spider in ipairs(spiders) do
            if NPC.IsAttacking(spider) then
                attackingCount = attackingCount + 1
            end
        end
        if attackingCount > totalSpiders * 0.3 then
            status = "Ataque"
        end
    end

    return tostring(totalSpiders), status
end

local AnimateAlpha

local function UpdatePanelAnimation()
    local spiders = GetAllSpiders()
    local currentSpiderCount = #spiders

    local nextInCells = (currentSpiderCount == 0)

    if currentSpiderCount ~= State.panelAnimation.lastSpiderCount then
        State.panelAnimation.lastSpiderCount = currentSpiderCount

        State.panelAnimation.cellsTargetAlpha = nextInCells and 0 or 255
    end

    if State.panelAnimation.headerInCellsPosition ~= nextInCells then

        if State.panelAnimation.headerAlpha > 0 then

            State.panelAnimation.headerTargetAlpha = 0

            if not nextInCells then
                State.panelAnimation.cellsTargetAlpha = 0
            end
        else

            State.panelAnimation.headerInCellsPosition = nextInCells
            State.panelAnimation.headerTargetAlpha = 255

            if not nextInCells then
                State.panelAnimation.cellsTargetAlpha = 255
            end
        end
    else

        State.panelAnimation.headerTargetAlpha = 255
    end

    local animationSpeed = 15

    State.panelAnimation.cellsAlpha  = AnimateAlpha(State.panelAnimation.cellsAlpha,  State.panelAnimation.cellsTargetAlpha,  animationSpeed)
    State.panelAnimation.headerAlpha = AnimateAlpha(State.panelAnimation.headerAlpha, State.panelAnimation.headerTargetAlpha, animationSpeed)

    State.panelAnimation.titleTargetAlpha = State.panelAnimation.headerTargetAlpha
    State.panelAnimation.titleAlpha = AnimateAlpha(State.panelAnimation.titleAlpha, State.panelAnimation.titleTargetAlpha, animationSpeed)
end

AnimateAlpha = function(current, target, speed)
    if current < target then
        return math.min(current + speed, target)
    elseif current > target then
        return math.max(current - speed, target)
    end
    return current
end

local function GetAverageSpiderHP(spiders)
    spiders = spiders or GetAllSpiders()
    if #spiders == 0 then return 0 end

    local totalHP = 0
    local totalMaxHP = 0

    for _, spider in ipairs(spiders) do
        totalHP = totalHP + Entity.GetHealth(spider)
        totalMaxHP = totalMaxHP + Entity.GetMaxHealth(spider)
    end

    if totalMaxHP == 0 then return 0 end
    return math.floor((totalHP / totalMaxHP) * 100)
end

local function DrawPanel()
    if not UI.ShowPanel:Get() then return end

    UpdatePanelAnimation()

    local isHovered = HandlePanelInput()

    local headerY = State.panelPos.y
    if State.panelAnimation.headerInCellsPosition then

        headerY = State.panelPos.y + PanelConfig.HeaderHeight + 5
    end

    DrawBlurredBackground(State.panelPos.x, headerY, PanelConfig.Width, PanelConfig.HeaderHeight, PanelConfig.BorderRadius, PanelConfig.BlurStrengthHeader, 0.91 * (State.panelAnimation.headerAlpha / 255))

    Render.Shadow(
        Vec2(State.panelPos.x, headerY),
        Vec2(State.panelPos.x + PanelConfig.Width, headerY + PanelConfig.HeaderHeight),
        Color(0, 0, 0, math.floor(State.panelAnimation.headerAlpha)),
        24,
        PanelConfig.BorderRadius,
        Enum.DrawFlags.ShadowCutOutShapeBackground,
        Vec2(1, 1)
    )

    Render.FilledRect(
        Vec2(State.panelPos.x, headerY),
        Vec2(State.panelPos.x + PanelConfig.Width, headerY + PanelConfig.HeaderHeight),
        Color(PanelColors.Header.r, PanelColors.Header.g, PanelColors.Header.b, math.floor(PanelColors.Header.a * State.panelAnimation.headerAlpha / 255)),
        PanelConfig.BorderRadius
    )

    local iconHandle = GetHeroIconHandle("npc_dota_hero_broodmother")
    local iconSizePx = 18
    local iconX = State.panelPos.x + 8
    local iconY = headerY + (PanelConfig.HeaderHeight - iconSizePx) / 2
    if iconHandle then
        Render.Image(iconHandle, Vec2(iconX, iconY), Vec2(iconSizePx, iconSizePx), Color(255, 255, 255, math.floor(State.panelAnimation.headerAlpha)), 0)
    else

        Render.Text(Config.Fonts.Main, 14, "🕷", Vec2(iconX, iconY - 1), Color(170, 170, 170, math.floor(State.panelAnimation.headerAlpha)))
    end

    local separatorX = iconX + iconSizePx + 8
    local separatorY = headerY + 4
    local separatorHeight = PanelConfig.HeaderHeight - 8

    Render.FilledRect(
        Vec2(separatorX, separatorY-4),
        Vec2(separatorX + 2, separatorY + separatorHeight + 4),
        Color(15, 15, 15, math.floor(70 * State.panelAnimation.headerAlpha / 255))
    )

    local title = "@spiders"
    local titleSize = Render.TextSize(Config.Fonts.Main, 12, title)
    local titleX = separatorX + 8
    local titleY = headerY + (PanelConfig.HeaderHeight - titleSize.y) / 2

    Render.Text(Config.Fonts.Main, 12, title, Vec2(titleX + 1, titleY + 1), Color(0, 0, 0, math.floor(State.panelAnimation.headerAlpha * 0.3)))
    Render.Text(Config.Fonts.Main, 12, title, Vec2(titleX, titleY), Color(170, 170, 170, math.floor(State.panelAnimation.headerAlpha)))

    local contentY = State.panelPos.y + PanelConfig.HeaderHeight + 5
    local cellStartX = State.panelPos.x + 8
    local cellY = contentY

    local spiders = GetAllSpiders()

    local spiderCount, spiderStatus = GetSpiderStatus(spiders)
    local avgHP = GetAverageSpiderHP(spiders)

    local myHero = Heroes.GetLocal()
    local webText, webColor = "-", Color(120, 200, 255, 255)
    local hungerText, hungerColor = "-", Color(255, 200, 120, 255)

    if myHero then
        local spinWeb = NPC.GetAbility(myHero, "broodmother_spin_web")
        if spinWeb then
            local charges = Ability.GetCurrentCharges(spinWeb)
            if charges and charges >= 0 then
                webText = tostring(charges)
                if charges == 0 then
                    webColor = Color(255, 120, 120, 255)
                end
            end
        end

        local hunger = NPC.GetAbility(myHero, "broodmother_insatiable_hunger")
        if hunger then
            if NPC.HasModifier(myHero, "modifier_broodmother_insatiable_hunger") then
                hungerText = "ON"
                hungerColor = Color(255, 200, 120, 255)
            elseif Ability.IsCastable(hunger, NPC.GetMana(myHero)) then
                hungerText = "RDY"
                hungerColor = Color(120, 255, 120, 255)
            else
                local cd = Ability.GetCooldown(hunger)
                hungerText = tostring(math.ceil(cd))
                hungerColor = Color(255, 120, 120, 255)
            end
        end
    end

    local attackingCount = 0
    for _, spider in ipairs(spiders) do
        if NPC.IsAttacking(spider) then
            attackingCount = attackingCount + 1
        end
    end
    local atkText = tostring(attackingCount)
    local atkColor = Color(180, 180, 180, 255)
    if attackingCount > 8 then
        atkColor = Color(120, 255, 120, 255)
    elseif attackingCount > 0 then
        atkColor = Color(255, 255, 120, 255)
    end

    local cells = {
        {
            text = spiderCount,
            font = 12,
            color = Color(255, 255, 255, 255)
        },
        {
            text = (function()
                if spiderStatus == "Reunir" then return "R" end
                if spiderStatus == "Espalhar" then return "E" end
                if spiderStatus == "Ataque" then return "A" end
                if spiderStatus == "Aguardando" then return "A" end
                return "?"
            end)(),
            font = 12,
            color = (function()
                return PanelColors.StatusColors[spiderStatus] or PanelColors.StatusColors["Aguardando"]
            end)()
        },
        {
            text = tostring(avgHP) .. "%",
            font = 9,
            color = (function()
                if avgHP < 25 then return Color(255, 120, 120, 255) end
                if avgHP < 50 then return Color(255, 255, 120, 255) end
                return PanelColors.StatusColors["HP"]
            end)()
        },

        {
            text = webText,
            font = 12,
            color = webColor
        },

        {
            text = hungerText,
            font = 11,
            color = hungerColor
        },

        {
            text = (function()
                if UI.AutoStackEnabled:Get() then
                    if #State.stackAssignments > 0 then return "ESP" end
                    if #State.stackRetreats > 0 then return "REC" end
                    return "ON"
                else
                    return "OFF"
                end
            end)(),
            font = 10,
            color = (function()
                if UI.AutoStackEnabled:Get() then
                    if #State.stackAssignments > 0 then return Color(120, 200, 255, 255) end
                    if #State.stackRetreats > 0 then return Color(255, 160, 100, 255) end
                    return Color(120, 255, 120, 255)
                else
                    return Color(200, 200, 200, 255)
                end
            end)()
        }
    }

    local cellX = cellStartX
    for i = 1, #cells do
        local c = cells[i]
        if i == #cells and c._iconUnit then
            local handle = GetHeroIconHandle(c._iconUnit)
            DrawIconCell(cellX, cellY, State.panelAnimation.cellsAlpha, handle)
        else
            DrawCell(cellX, cellY, State.panelAnimation.cellsAlpha, c.text, c.font, c.color)
        end
        cellX = cellX + PanelConfig.CellSize + PanelConfig.CellSpacing
    end
end

local function DrawWebPoints()
    if not UI.WebHelperEnabled:Get() then return end

    local altHeld = Input.IsKeyDown(Enum.ButtonCode.KEY_LALT) or Input.IsKeyDown(Enum.ButtonCode.KEY_RALT)
    local altActive = (not UI.ShowWebPointsOnlyAlt:Get()) or altHeld
    local targetAlpha = altActive and 255 or 0
    State.webAltAlpha = AnimateAlpha(State.webAltAlpha, targetAlpha, 25)
    if State.webAltAlpha <= 0 then return end

    local webIcon = GetAbilityIconHandle("broodmother_spin_web")
    local rounding = 6

    local myHero = Heroes.GetLocal()
    local team = myHero and Entity.GetTeamNum(myHero) or nil

    local cursorX, cursorY = Input.GetCursorPos()
    local mouseDown = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1)
    local justClicked = mouseDown and (not State.webMouseWasDown)
    local didCast = false

    local alphaScale = State.webAltAlpha / 255

    local function drawList(list)
        for _, wp in ipairs(list or {}) do
            local screenPos, visible = Render.WorldToScreen(wp)
            if visible then
                local size = PanelConfig.CellSize
                local x = screenPos.x - size / 2
                local y = screenPos.y - size / 2

                local isHovered = cursorX >= x and cursorX <= (x + size) and cursorY >= y and cursorY <= (y + size)
                local baseAlpha = isHovered and math.floor(230 * 0.6) or 230
                local alpha = math.floor(baseAlpha * alphaScale)

                if webIcon then
                    DrawIconCell(x, y, alpha, webIcon, 0.88, rounding)

                    local basePad = 2
                    local iconScale = 0.88
                    local inner = (size - basePad * 2)
                    local iconSize = math.floor(inner * iconScale)
                    local offset = math.floor((inner - iconSize) / 2)
                    local pos = Vec2(x + basePad + offset + 0.5, y + basePad + 1 + offset)
                    local endPos = Vec2(pos.x + iconSize, pos.y + iconSize)
                    local baseBorder = isHovered and 180 or 220
                    local borderAlpha = math.floor(baseBorder * alphaScale)
                    Render.Rect(pos, endPos, Color(170, 170, 170, borderAlpha), rounding, Enum.DrawFlags.None, 0.5)
                else
                    DrawCell(x, y, alpha, "", 14, Color(120, 200, 255, 255))
                end

                if (not didCast) and UI.WebClickToCast:Get() and justClicked and isHovered and myHero then
                    local spinWeb = NPC.GetAbility(myHero, "broodmother_spin_web")
                    if spinWeb and Ability.IsCastable(spinWeb, NPC.GetMana(myHero)) then
                        Ability.CastPosition(spinWeb, wp, false, false, false, "web_click")
                        didCast = true
                    end
                end
            end
        end
    end

    if team == Enum.TeamNum.TEAM_RADIANT then
        drawList(State.webPoints.radiant)
    elseif team == Enum.TeamNum.TEAM_DIRE then
        drawList(State.webPoints.dire)
    else
        drawList(State.webPoints.neutral)
    end

    State.webMouseWasDown = mouseDown
end

local function HandlependHS()
    if State.pendHS > 0 then
        local currentTime = GameRules.GetGameTime()
        if currentTime >= State.pendHS then
            local myPlayer = Players.GetLocal()
            local myHero = Heroes.GetLocal()

            if myPlayer and myHero then
                Player.ClearSelectedUnits(myPlayer)
                Player.AddSelectedUnit(myPlayer, myHero)
            end

            State.pendHS = 0
        end
    end
end

local lastFilterTime = 0
local lastFilteredCount = 0

local function OchsitkaPaykov()
    -- Usa a MESMA lógica do auto-stack: verifica se qualquer recurso que bloqueia está ativo
    if not UI.AutoStackEnabled:Get() and not UI.AlwaysSpread:Get() then return end
    
    local player = Players.GetLocal()
    if not player then return end
    local selectedUnits = Player.GetSelectedUnits(player) or {}
    if #selectedUnits == 0 then 
        lastFilteredCount = 0
        return 
    end

    -- Se a seleção não mudou desde a última filtragem, não faz nada
    local now = GameRules.GetGameTime()
    if #selectedUnits == lastFilteredCount and (now - lastFilterTime) < 0.5 then
        return
    end

    local allowed = {}
    local hasLocked = false
    
    for _, u in ipairs(selectedUnits) do
        -- Verifica DIRETAMENTE se é aranha e se está no spread
        local unitName = NPC.GetUnitName(u)
        local idx = Entity.GetIndex(u)
        local isSpreadSpider = (unitName == "npc_dota_broodmother_spiderling" and State.spreadSpiderIndices[idx] == true)
        
        -- OU verifica se está bloqueada por stack
        local isStackLocked = IsSpiderStackLocked(u)
        
        if isSpreadSpider or isStackLocked then
            hasLocked = true
        else
            table.insert(allowed, u)
        end
    end

    -- Só mexe na seleção se houver aranhas bloqueadas
    if hasLocked then
        lastFilterTime = now
        lastFilteredCount = #allowed
        
        Player.ClearSelectedUnits(player)
        for _, u in ipairs(allowed) do
            Player.AddSelectedUnit(player, u)
        end
    else
        lastFilteredCount = #selectedUnits
    end
end

leonellibrudo.OnUpdate = function()
    if not IsBroodmother() or not UI.Enabled:Get() then return end

    -- OchsitkaPaykov 666
    OchsitkaPaykov()

    HandlependHS()
    GatherSpiders()
    JuggleSpiders()
    SmartBloodthorn()
    if UI.AutoStackToggleKey and UI.AutoStackToggleKey:IsPressed() then
        UI.AutoStackEnabled:Set(not UI.AutoStackEnabled:Get())
    end
    AutoStack()
end

leonellibrudo.OnPrepareUnitOrders = function(data)
    if not IsBroodmother() or not UI.Enabled:Get() then 
        return true 
    end

    if UI.AutoStackEnabled:Get() then
        local player = Players.GetLocal()
        if player then
            local selectedUnits = Player.GetSelectedUnits(player) or {}
            local allowedUnits = {}
            local hasLocked = false

            for _, u in ipairs(selectedUnits) do
                if IsSpiderStackLocked(u) then
                    hasLocked = true
                else
                    table.insert(allowedUnits, u)
                end
            end

            if hasLocked then
                if #allowedUnits > 0 then
                    Player.PrepareUnitOrders(
                        player,
                        data.order,
                        data.target,
                        data.position,
                        data.ability,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        allowedUnits,
                        data.queue or false,
                        data.showEffects or false,
                        false,  -- callback
                        false,  -- execute_fast
                        "user_order_relay"
                    )
                end
                return false
            end
        end

        if data.npc and IsSpiderStackLocked(data.npc) then
            if data.identifier and IsBypassAllowed(data.npc, data.identifier) then
                PopBypassFor(data.npc, data.identifier)
                return true
            end
            return false
        end
    end

    if UI.AutoSoulRing:Get() then
        local myHero = Heroes.GetLocal()
        if myHero and data.npc == myHero then
            if data.ability and Ability.GetName(data.ability) == "broodmother_spawn_spiderlings" then
                local soulRing = NPC.GetItem(myHero, "item_soul_ring")
                if soulRing and Ability.IsCastable(soulRing, 0) then
                    local soulRingActive = NPC.HasModifier(myHero, "modifier_item_soul_ring_buff")
                    if not soulRingActive then
                        Ability.CastNoTarget(soulRing)
                        State.lastSoulRingTime = GameRules.GetGameTime()
                    end
                end
            end
        end
    end

    return true
end


leonellibrudo.OnDraw = function()
    if not IsBroodmother() or not UI.Enabled:Get() then return end

    -- debug
    if UI.ShowCursorCoords:Get() then
        local cursorX, cursorY = Input.GetCursorPos()
        local worldPos = Input.GetWorldCursorPos()
        local myHero = Heroes.GetLocal()
        if not worldPos and myHero then
            worldPos = Entity.GetAbsOrigin(myHero)
        end
        if worldPos then
            local txt = string.format("%.1f, %.1f, %.1f", worldPos.x, worldPos.y, worldPos.z)
            local tSize = Render.TextSize(Config.Fonts.Main, 12, txt)
            local pad = 6
            local boxPos1 = Vec2(cursorX + 14, cursorY + 18)
            local boxPos2 = Vec2(cursorX + 14 + tSize.x + pad*2, cursorY + 18 + tSize.y + pad)
            DrawBlurredBackground(boxPos1.x, boxPos1.y, boxPos2.x - boxPos1.x, boxPos2.y - boxPos1.y, 6, 6, 0.9)
            Render.FilledRect(boxPos1, boxPos2, Color(0, 0, 0, 160), 6)
            Render.Text(Config.Fonts.Main, 12, txt, Vec2(boxPos1.x + pad, boxPos1.y + 2), Color(255, 255, 255, 255))
        end
    end

    DrawPanel()
    DrawWebPoints()

    DrawAutoStackDebug()

    if State.lastGatherPos and (GameRules.GetGameTime() - State.lastGatherTime < 2) then
        local screenPos, isVisible = Render.WorldToScreen(State.lastGatherPos)
        if isVisible then
            local alpha = math.max(0, 255 - (GameRules.GetGameTime() - State.lastGatherTime) * 127)

            Render.Line(Vec2(screenPos.x - 5, screenPos.y), Vec2(screenPos.x + 5, screenPos.y), Color(100, 255, 100, alpha), 2)
            Render.Line(Vec2(screenPos.x, screenPos.y - 5), Vec2(screenPos.x, screenPos.y + 5), Color(100, 255, 100, alpha), 2)
        end
    end

    if State.juggling and (GameRules.GetGameTime() - State.juggleTime < 3) then
        local myHero = Heroes.GetLocal()
        if myHero then
            local heroPos = Entity.GetAbsOrigin(myHero)
            local radius = UI.JuggleRadius:Get()
            local alpha = math.max(0, 255 - (GameRules.GetGameTime() - State.juggleTime) * 85)

            local points = 32
            for i = 0, points do
                local angle = (i / points) * 2 * math.pi
                local x = heroPos.x + radius * math.cos(angle)
                local y = heroPos.y + radius * math.sin(angle)
                local worldPos = Vector(x, y, heroPos.z)
                local screenPos, isVisible = Render.WorldToScreen(worldPos)

                if isVisible and i > 0 then
                    local prevAngle = ((i - 1) / points) * 2 * math.pi
                    local prevX = heroPos.x + radius * math.cos(prevAngle)
                    local prevY = heroPos.y + radius * math.sin(prevAngle)
                    local prevWorldPos = Vector(prevX, prevY, heroPos.z)
                    local prevScreenPos, prevVisible = Render.WorldToScreen(prevWorldPos)

                    if prevVisible then
                        Render.Line(prevScreenPos, screenPos, Color(255, 120, 0, alpha), 2)
                    end
                end
            end

            local spiders = GetAllSpiders()
            local count = math.min(UI.JuggleCount:Get(), #spiders)

            for i = 1, count do
                local angle = (i - 1) * (2 * math.pi / count)
                local x = heroPos.x + radius * math.cos(angle)
                local y = heroPos.y + radius * math.sin(angle)
                local worldPos = Vector(x, y, heroPos.z)
                local screenPos, isVisible = Render.WorldToScreen(worldPos)

                if isVisible then
                    Render.FilledCircle(screenPos, 6, Color(255, 120, 0, alpha))
                    Render.Text(Config.Fonts.Main, 12, tostring(i), Vec2(screenPos.x - 4, screenPos.y - 6), Color(255, 255, 255, alpha))
                end
            end
        end
    else
        State.juggling = false
    end
end

leonellibrudo.OnGameEnd = function()
    State.juggling = false
    State.juggleAngle = 0
    State.lastJuggleTime = 0
end

function DrawAutoStackDebug()
    if not UI.AutoStackEnabled:Get() then return end

    if State.stackAssignments and #State.stackAssignments > 0 then
        for _, asg in ipairs(State.stackAssignments) do
            local spider = asg.spider
            local camp = asg.camp
            local wait = asg.wait
            if spider and camp and wait and Entity.IsAlive(spider) then
                local sp = Entity.GetAbsOrigin(spider)
                local sSp, sOk = Render.WorldToScreen(sp)
                local cSp, cOk = Render.WorldToScreen(camp)
                local wSp, wOk = Render.WorldToScreen(wait)
                if sOk and wOk then
                    Render.Line(sSp, wSp, Color(120, 200, 255, 180), 2)
                    Render.FilledCircle(wSp, 6, Color(120, 200, 255, 160))
                end
                if cOk then
                    Render.FilledCircle(cSp, 4, Color(255, 200, 120, 200))
                end
            end
        end
    end

    if State.stackRetreats and #State.stackRetreats > 0 then
        for _, it in ipairs(State.stackRetreats) do
            local spider = it.spider
            local wait = it.wait
            if spider and wait and Entity.IsAlive(spider) then
                local sp = Entity.GetAbsOrigin(spider)
                local sSp, sOk = Render.WorldToScreen(sp)
                local wSp, wOk = Render.WorldToScreen(wait)
                if sOk and wOk then
                    Render.Line(sSp, wSp, Color(255, 160, 100, 180), 2)
                    Render.FilledCircle(wSp, 5, Color(255, 160, 100, 160))
                    local txt = string.format("%.1fs", math.max(0, (it.when or 0) - GameRules.GetGameTime()))
                    Render.Text(Config.Fonts.Main, 11, txt, Vec2(wSp.x + 8, wSp.y - 8), Color(255, 200, 160, 220))
                end
            end
        end
    end
end

return leonellibrudo

