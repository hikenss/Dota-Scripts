--[[
    ~ courier inventory overlay
   ~~ jaydenannemay special4wind
]]

local M = {}

local Config = {
    UI = {
        TabName = "Geral",
        ScriptName = "Inventário do Courier",
        ScriptID = "courier_inv",
        Icons = {
            Main = "\u{f21e}"
        },
        Groups = {
            Main = "Principal"
        }
    },
    Fonts = {
        Main = Render.LoadFont("SF Pro Text", Enum.FontCreate.FONTFLAG_ANTIALIAS)
    }
}

local function InitializeUI()
    local tab = Menu.Create("Scripts", "Utility", "Courier Inventory")
    tab:Icon(Config.UI.Icons.Main)

    local settingsTab = tab:Create("Settings")
    local mainGroup = settingsTab:Create("Main")

    return {
        Enabled = mainGroup:Switch("Ativar", true, Config.UI.Icons.Main),
        Layout = mainGroup:Combo("Layout", { "Normal", "3x3" }, 0),
        AltOnly = mainGroup:Switch("Mostrar apenas com ALT", false),
        ShowTimer = mainGroup:Switch("Mostrar timer de respawn", true, "\u{f017}"),
        TestTimer = mainGroup:Button("Testar Timer (60s)", function()
            local currentTime = GameRules.GetGameTime()
            State.deadCouriers[3] = {
                deathTime = currentTime,
                respawnTime = currentTime + 60
            }
            Log.Write("[Courier] Timer de teste adicionado: 60s")
        end),
        DebugMode = mainGroup:Switch("Debug Mode", false, "\u{f188}")
    }
end

local UI = InitializeUI()

local PanelConfig = {
    CellSize = 25,
    CellWidth = 28,
    CellSpacing = 1,
    BorderRadius = 8,
    ShadowOffset = 2,
    BlurStrength = 8,
    CellRounding = 4
}

local PanelColors = {
    Background = Color(20, 20, 25, 200),
    Border = Color(60, 60, 70, 160),
    Shadow = Color(0, 0, 0, 100)
}

local function stlclr(key, fallback)
    local st = Menu and Menu.Style and Menu.Style()
    if st and st[key] then
        local c = st[key]
        return Color(c.r or 255, c.g or 255, c.b or 255, c.a or 255)
    end
    return fallback or Color(255,255,255,255)
end

local function outlinecol()
    return stlclr("indication_inactive", PanelColors.Border)
end

local TimerState = {
    x = 50,
    y = 50,
    dragging = false,
    dragOffset = {x = 0, y = 0},
    minimized = false
}

local State = {
    alpha = 0,
    deadCouriers = {},
    trackedCouriers = {}
}

local function clamp(a, b, c)
    if a < b then
        return math.min(a + c, b)
    elseif a > b then
        return math.max(a - c, b)
    end
    return a
end

local function nametoicon(itemName)
    if not itemName or itemName == "" then return nil end
    local base = itemName
    if string.sub(base, 1, 5) == "item_" then base = string.sub(base, 6) end
    if string.sub(base, 1, 6) == "recipe" then base = "recipe" end
    return base
end

local iconcache = {}
local function itemtoicon(itemName)
    if not itemName then return nil end
    local base = nametoicon(itemName)
    if not base then return nil end
    local key = base
    local handle = iconcache[key]
    if handle ~= nil then return handle end
    local path = "panorama/images/items/" .. base .. "_png.vtex_c"
    handle = Render.LoadImage(path)
    iconcache[key] = handle
    return handle
end

local function DrawIconCell(x, y, alpha, imageHandle)
    local w = PanelConfig.CellWidth or PanelConfig.CellSize
    local h = PanelConfig.CellSize
    if imageHandle then
        local r = PanelConfig.CellRounding or 4
        Render.Image(imageHandle, Vec2(x, y), Vec2(w, h), Color(255, 255, 255, math.floor(alpha)), r)
    end
    local b = outlinecol()
    local r = PanelConfig.CellRounding or 4
    local ba = b.a or 255
    local oa = math.floor(ba * (alpha / 255))
    Render.Rect(Vec2(x, y), Vec2(x + w, y + h), Color(b.r, b.g, b.b, oa), r, Enum.DrawFlags.None, 1)
end

local function getitembyslot(unit, slot)
    if NPC.GetItemByIndex then
        local res = NPC.GetItemByIndex(unit, slot)
        if res then return res end
    end
end

local function getcouritems(courier)
    local items = {}
    if not courier then return items end

    for slot = 0, 10 do
        local it = getitembyslot(courier, slot)
        if it then
            local name = Ability.GetName(it)
            if name and name ~= "" then
                table.insert(items, it)
            end
        end
    end
    return items
end

local function isenemy(npc, myTeam)
    if not npc or not Entity.IsAlive(npc) then return false end
    local unitName = NPC.GetUnitName(npc)
    if not unitName then return false end
    if unitName ~= "npc_dota_courier" and unitName ~= "npc_dota_courier_flying" then
        if not string.find(unitName, "courier", 1, true) then return false end
    end
    local team = Entity.GetTeamNum(npc)
    return myTeam and team and team ~= myTeam
end

local function DrawCharges(x, y, alpha, item)
    if not item then return end
    local charges = nil
    if Ability.GetCurrentCharges then
        charges = Ability.GetCurrentCharges(item)
    end
    if charges and charges > 0 then
        local txt = tostring(charges)
        local size = Render.TextSize(Config.Fonts.Main, 11, txt)
        local cellW = PanelConfig.CellWidth or PanelConfig.CellSize
        local cellH = PanelConfig.CellSize
        local tx = x + cellW - size.x - 4
        local ty = y + cellH - size.y - 2
        Render.Text(Config.Fonts.Main, 11, txt, Vec2(tx + 1, ty + 1), Color(0, 0, 0, math.floor(alpha * 0.45)))
        Render.Text(Config.Fonts.Main, 11, txt, Vec2(tx, ty), Color(255, 255, 255, math.floor(alpha)))
    end
end

-- Calcula tempo de respawn do courier baseado no tempo de jogo
local function getCourierRespawnTime()
    local gameTime = GameRules.GetDOTATime()
    if gameTime < 180 then -- 0-3 min
        return 50
    elseif gameTime < 600 then -- 3-10 min
        return 90
    elseif gameTime < 1200 then -- 10-20 min
        return 120
    elseif gameTime < 1800 then -- 20-30 min
        return 140
    else -- 30+ min
        return 160
    end
end

local function DrawCourierTimer()
    if not UI.ShowTimer or not UI.ShowTimer:Get() then return end
    
    -- Sempre mostra o painel se houver timers OU para debug
    local hasTimers = false
    local currentTime = GameRules.GetGameTime()
    
    -- Limpa timers expirados primeiro
    for team, data in pairs(State.deadCouriers) do
        local timeLeft = data.respawnTime - currentTime
        if timeLeft <= 0 then
            State.deadCouriers[team] = nil
        else
            hasTimers = true
        end
    end
    
    -- Para debug: sempre mostra o painel
    if not hasTimers then
        -- Mostra painel vazio para debug
        hasTimers = true
    end
    
    if not hasTimers then return end
    
    local mouse = Input.GetCursorPos()
    local mouseDown = Input.IsKeyDown(Enum.ButtonCode.MOUSE_LEFT)
    
    -- Dimensões do painel
    local panelW = TimerState.minimized and 80 or 120
    local panelH = TimerState.minimized and 20 or 30
    
    -- Verifica se mouse está sobre o painel
    local mouseOver = mouse.x >= TimerState.x and mouse.x <= TimerState.x + panelW and
                      mouse.y >= TimerState.y and mouse.y <= TimerState.y + panelH
    
    -- Lógica de drag
    if mouseOver and mouseDown and not TimerState.dragging then
        TimerState.dragging = true
        TimerState.dragOffset.x = mouse.x - TimerState.x
        TimerState.dragOffset.y = mouse.y - TimerState.y
    elseif TimerState.dragging and mouseDown then
        TimerState.x = mouse.x - TimerState.dragOffset.x
        TimerState.y = mouse.y - TimerState.dragOffset.y
    elseif not mouseDown then
        TimerState.dragging = false
    end
    
    -- Fundo do painel
    local bgColor = mouseOver and Color(40, 40, 50, 200) or Color(20, 20, 30, 150)
    Render.FilledRect(Vec2(TimerState.x, TimerState.y), Vec2(TimerState.x + panelW, TimerState.y + panelH), bgColor, 4)
    
    -- Botão minimizar
    local btnX = TimerState.x + panelW - 15
    local btnY = TimerState.y + 2
    local btnOver = mouse.x >= btnX and mouse.x <= btnX + 12 and mouse.y >= btnY and mouse.y <= btnY + 12
    if btnOver then
        Render.FilledRect(Vec2(btnX, btnY), Vec2(btnX + 12, btnY + 12), Color(60, 60, 70, 150), 2)
        if Input.IsKeyPressed(Enum.ButtonCode.MOUSE_LEFT) then
            TimerState.minimized = not TimerState.minimized
        end
    end
    local btnText = TimerState.minimized and "+" or "-"
    Render.Text(Config.Fonts.Main, 10, btnText, Vec2(btnX + 3, btnY + 1), Color(200, 200, 200, 255))
    
    if TimerState.minimized then
        -- Versão minimizada - só mostra "C"
        Render.Text(Config.Fonts.Main, 12, "C", Vec2(TimerState.x + 3, TimerState.y + 4), Color(255, 150, 150, 255))
    else
        -- Versão completa
        local hasActiveTimers = false
        local yOffset = 0
        for team, data in pairs(State.deadCouriers) do
            local timeLeft = data.respawnTime - currentTime
            if timeLeft > 0 then
                hasActiveTimers = true
                local timerText = string.format("%d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
                local teamColor = team == 2 and Color(100, 255, 100, 255) or Color(255, 100, 100, 255)
                Render.Text(Config.Fonts.Main, 11, timerText, Vec2(TimerState.x + 3, TimerState.y + 5 + yOffset), teamColor)
                yOffset = yOffset + 12
            end
        end
        
        -- Se não há timers ativos, mostra "No timers"
        if not hasActiveTimers then
            Render.Text(Config.Fonts.Main, 10, "No timers", Vec2(TimerState.x + 3, TimerState.y + 8), Color(150, 150, 150, 255))
        end
    end
end

local function DrawCourierPanel(courier, alpha)
    if not courier or not Entity.IsAlive(courier) then return end
    
    local pos = Entity.GetAbsOrigin(courier)
    if not pos then return end
    
    -- Ajusta a posição para ficar acima do courier
    local offsetPos = pos + Vector(0, 0, 150)
    local screenPos, visible = Render.WorldToScreen(offsetPos)
    if not visible or not screenPos then return end

    local items = getcouritems(courier)
    if #items == 0 then return end

    local totalCells = #items
    local cellW = PanelConfig.CellWidth or PanelConfig.CellSize
    local cellH = PanelConfig.CellSize
    local spacing = PanelConfig.CellSpacing
    local isGrid = UI.Layout:Get() == 1
    local showCount = isGrid and math.min(totalCells, 9) or totalCells
    local columns = isGrid and math.min(3, showCount) or showCount
    local rows = isGrid and math.ceil(showCount / columns) or 1

    local width = columns * cellW + (columns - 1) * spacing
    local height = rows * cellH + (rows - 1) * spacing

    local x = math.floor(screenPos.x - width / 2)
    local y = math.floor(screenPos.y - height / 2)
    for i = 1, showCount do
        local row = math.floor((i - 1) / columns)
        local col = (i - 1) % columns
        local cx = x + col * (cellW + spacing)
        local cy = y + row * (cellH + spacing)

        local it = items[i]
        local name = it and Ability.GetName(it) or nil
        local icon = name and itemtoicon(name) or nil
        DrawIconCell(cx, cy, alpha, icon)
        DrawCharges(cx, cy, alpha, it)
    end
end

M.OnEntityKilled = function(ent)
    if not UI.Enabled or not UI.Enabled:Get() then return end
    if not UI.ShowTimer or not UI.ShowTimer:Get() then return end
    
    if UI.DebugMode and UI.DebugMode:Get() then
        Log.Write("[Courier Debug] Entity killed: " .. tostring(ent))
    end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    if ent then
        local unitName = NPC.GetUnitName(ent)
        if UI.DebugMode and UI.DebugMode:Get() then
            Log.Write("[Courier Debug] Unit name: " .. tostring(unitName))
        end
        
        if unitName and (unitName == "npc_dota_courier" or unitName == "npc_dota_courier_flying" or string.find(unitName, "courier", 1, true)) then
            local team = Entity.GetTeamNum(ent)
            if UI.DebugMode and UI.DebugMode:Get() then
                Log.Write("[Courier Debug] Courier team: " .. tostring(team) .. " My team: " .. tostring(myTeam))
            end
            
            if team and team ~= myTeam then
                local currentTime = GameRules.GetGameTime()
                local respawnTime = getCourierRespawnTime()
                State.deadCouriers[team] = {
                    deathTime = currentTime,
                    respawnTime = currentTime + respawnTime
                }
                Log.Write("[Courier] Enemy courier killed! Team: " .. team .. " Respawn in: " .. respawnTime .. "s")
            end
        end
    end
end

M.OnUpdate = function()
    if not UI.Enabled or not UI.Enabled:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    local all = NPCs.GetAll()
    if not all then return end
    
    -- Rastreia couriers inimigos vivos para limpar timers
    for _, npc in ipairs(all) do
        if npc and Entity.IsAlive(npc) then
            local unitName = NPC.GetUnitName(npc)
            if unitName and (unitName == "npc_dota_courier" or unitName == "npc_dota_courier_flying" or string.find(unitName, "courier", 1, true)) then
                local team = Entity.GetTeamNum(npc)
                if team and team ~= myTeam then
                    State.trackedCouriers[Entity.GetIndex(npc)] = true
                end
            end
        end
    end
end

M.OnDraw = function()
    if not UI.Enabled or not UI.Enabled:Get() then return end
    
    -- Timer de courier
    if UI.ShowTimer and UI.ShowTimer:Get() then
        local currentTime = GameRules.GetGameTime()
        local hasTimers = false
        
        -- Limpa timers expirados
        for team, data in pairs(State.deadCouriers) do
            if data.respawnTime - currentTime <= 0 then
                State.deadCouriers[team] = nil
            else
                hasTimers = true
            end
        end
        
        -- Só mostra se houver timers ativos
        if hasTimers then
            local x, y = 50, 50
            Render.FilledRect(Vec2(x, y), Vec2(x + 120, y + 40), Color(0, 0, 0, 200), 4)
            Render.Text(Config.Fonts.Main, 12, "COURIER TIMER", Vec2(x + 5, y + 5), Color(255, 255, 255, 255))
            
            local yOffset = 20
            for team, data in pairs(State.deadCouriers) do
                local timeLeft = data.respawnTime - currentTime
                if timeLeft > 0 then
                    local timerText = string.format("%d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
                    local teamColor = team == 2 and Color(100, 255, 100, 255) or Color(255, 100, 100, 255)
                    Render.Text(Config.Fonts.Main, 11, timerText, Vec2(x + 5, y + yOffset), teamColor)
                    yOffset = yOffset + 15
                end
            end
        end
    end
    
    local altDown = Input.IsKeyDown(Enum.ButtonCode.KEY_LALT)
    local showNow = (not UI.AltOnly or not UI.AltOnly:Get()) or altDown
    State.alpha = clamp(State.alpha, showNow and 255 or 0, 10)
    
    if State.alpha <= 0 then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)

    local all = NPCs.GetAll()
    if not all or #all == 0 then return end

    for _, npc in ipairs(all) do
        if isenemy(npc, myTeam) then
            DrawCourierPanel(npc, State.alpha)
        end
    end
end

-- Registra as funções no framework
Callbacks.Add("OnEntityKilled", M.OnEntityKilled)
Callbacks.Add("OnUpdate", M.OnUpdate)
Callbacks.Add("OnDraw", M.OnDraw)

return M


