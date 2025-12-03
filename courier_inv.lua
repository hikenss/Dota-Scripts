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
        ShowTimer = mainGroup:Switch("Mostrar timer de respawn", true, "\u{f017}")
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
    
    local screenSize = Render.ScreenSize()
    local startX = screenSize.x - 200
    local startY = 100
    local currentTime = GameRules.GetGameTime()
    
    local yOffset = 0
    for team, data in pairs(State.deadCouriers) do
        local timeLeft = data.respawnTime - currentTime
        if timeLeft > 0 then
            local y = startY + yOffset
            
            -- Fundo
            Render.FilledRect(Vec2(startX, y), Vec2(startX + 180, y + 40), Color(20, 20, 25, 200), 8)
            
            -- Ícone do courier
            local courierIcon = Render.LoadImage("panorama/images/heroes/icons/npc_dota_hero_courier_png.vtex_c")
            if courierIcon then
                Render.Image(courierIcon, Vec2(startX + 5, y + 5), Vec2(30, 30), Color(255, 255, 255, 255), 4)
            end
            
            -- Texto do timer
            local timerText = string.format("%d:%02d", math.floor(timeLeft / 60), math.floor(timeLeft % 60))
            Render.Text(Config.Fonts.Main, 20, timerText, Vec2(startX + 45, y + 10), Color(255, 100, 100, 255))
            
            -- Texto do time
            local teamText = team == 2 and "Radiante" or "Dire"
            Render.Text(Config.Fonts.Main, 12, teamText, Vec2(startX + 130, y + 15), Color(200, 200, 200, 255))
            
            yOffset = yOffset + 50
        else
            -- Remove timer expirado
            State.deadCouriers[team] = nil
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

M.OnUpdate = function()
    if not UI.Enabled or not UI.Enabled:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    local all = NPCs.GetAll()
    if not all then return end
    
    -- Rastreia couriers inimigos
    for _, npc in ipairs(all) do
        if npc then
            local unitName = NPC.GetUnitName(npc)
            if unitName and (unitName == "npc_dota_courier" or unitName == "npc_dota_courier_flying" or string.find(unitName, "courier", 1, true)) then
                local team = Entity.GetTeamNum(npc)
                if team and team ~= myTeam then
                    local npcIndex = Entity.GetIndex(npc)
                    
                    -- Courier estava vivo
                    if Entity.IsAlive(npc) then
                        State.trackedCouriers[npcIndex] = true
                        -- Remove do timer se estava morto
                        if State.deadCouriers[team] then
                            State.deadCouriers[team] = nil
                        end
                    else
                        -- Courier morreu
                        if State.trackedCouriers[npcIndex] and not State.deadCouriers[team] then
                            local currentTime = GameRules.GetGameTime()
                            local respawnTime = getCourierRespawnTime()
                            State.deadCouriers[team] = {
                                respawnTime = currentTime + respawnTime,
                                team = team
                            }
                        end
                    end
                end
            end
        end
    end
end

M.OnDraw = function()
    if not UI.Enabled or not UI.Enabled:Get() then return end
    local altDown = Input.IsKeyDown(Enum.ButtonCode.KEY_LALT)
    local showNow = (not UI.AltOnly or not UI.AltOnly:Get()) or altDown
    State.alpha = clamp(State.alpha, showNow and 255 or 0, 10)
    
    -- Desenha timer de respawn
    DrawCourierTimer()
    
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

return M


