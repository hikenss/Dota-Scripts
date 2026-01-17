local CourierUltimate = {}

CourierUltimate.State = {
    deadCouriers = {},
    heroIcons = {},
    itemIcons = {},
    alpha = 0,
    escaping = false,
    lastHP = 0,
    escapeTarget = nil,
    lastEscapeTime = 0,
    trackedCouriers = {}
}

local tab = Menu.Create("Scripts", "Utility", "Courier Ultimate")
tab:Icon("\u{f21e}")

local timerGroup = tab:Create("Main"):Create("Timer")
local invGroup = tab:Create("Main"):Create("Inventory")
local saverGroup = tab:Create("Main"):Create("Auto Saver")

local ui_timer = {}
ui_timer.enabled = timerGroup:Switch("Show Timer", true, "\u{f017}", true)
ui_timer.test = timerGroup:Button("Test 60s", function()
    local time = GameRules.GetGameTime()
    CourierUltimate.State.deadCouriers[3] = {
        deathTime = time,
        respawnTime = time + 60,
        ownerHero = Heroes.GetLocal()
    }
end)

local ui_inv = {}
ui_inv.enabled = invGroup:Switch("Show Inventory", true, "\u{f0b1}", true)
ui_inv.layout = invGroup:Combo("Layout", {"Horizontal", "3x3"}, 0, true)
ui_inv.altOnly = invGroup:Switch("ALT Only", false, "", true)

local ui_saver = {}
ui_saver.enabled = saverGroup:Switch("Auto Protect", true, "\u{1f6e1}", true)
ui_saver.dangerRange = saverGroup:Slider("Danger Range", 800, 2000, 1200, true)
ui_saver.criticalHP = saverGroup:Slider("Critical HP %", 20, 80, 40, true)
ui_saver.hideInShop = saverGroup:Switch("Hide in Secret Shop", true, "", true)
ui_saver.smartEscape = saverGroup:Switch("Smart Escape", true, "", true)
ui_saver.showAlerts = saverGroup:Switch("Show Alerts", false, "", true)

local font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)

local FOUNTAIN = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7019, -6534, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(6846, 6251, 384)
}

local SECRET_SHOPS = {
    Vector(-4553, 1046, 256),
    Vector(4486, -1542, 256)
}

local function getCourierRespawnTime()
    local t = GameRules.GetDOTATime()
    if t < 180 then return 50
    elseif t < 600 then return 90
    elseif t < 1200 then return 120
    elseif t < 1800 then return 140
    else return 160 end
end

local function loadItemIcon(itemName)
    if not itemName or itemName == "" then return nil end
    local base = itemName:sub(1, 5) == "item_" and itemName:sub(6) or itemName
    if base:sub(1, 6) == "recipe" then base = "recipe" end
    if not CourierUltimate.State.itemIcons[base] then
        CourierUltimate.State.itemIcons[base] = Render.LoadImage("panorama/images/items/" .. base .. "_png.vtex_c")
    end
    return CourierUltimate.State.itemIcons[base]
end

local function getCourierItems(courier)
    local items = {}
    if not courier then return items end
    for slot = 0, 10 do
        local item = NPC.GetItemByIndex(courier, slot)
        if item and Ability.GetName(item) ~= "" then
            table.insert(items, item)
        end
    end
    return items
end

local function isInSecretShop(pos)
    for _, shop in ipairs(SECRET_SHOPS) do
        if (pos - shop):Length() < 400 then return true, shop end
    end
    return false
end

local function countEnemyHeroes(pos, radius, team)
    local count = 0
    for i = 1, Heroes.Count() do
        local hero = Heroes.Get(i)
        if hero and Entity.IsAlive(hero) and Entity.GetTeamNum(hero) ~= team then
            if not NPC.IsIllusion(hero) and (Entity.GetAbsOrigin(hero) - pos):Length() < radius then
                count = count + 1
            end
        end
    end
    return count
end

local function evaluateThreat(courier, pos, team)
    local threat = 0
    local closest = nil
    local minDist = 9999
    
    for i = 1, Heroes.Count() do
        local enemy = Heroes.Get(i)
        if enemy and Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= team and not NPC.IsIllusion(enemy) then
            local dist = (Entity.GetAbsOrigin(enemy) - pos):Length()
            if dist < minDist then
                minDist = dist
                closest = enemy
            end
            
            local range = NPC.GetAttackRange(enemy) + 300
            if dist < range then threat = 100
            elseif dist < range + 300 then threat = math.max(threat, 70)
            elseif dist < ui_saver.dangerRange:Get() then threat = math.max(threat, 40)
            end
        end
    end
    
    return threat, closest
end

local function findSafeEscape(pos, enemyPos, team)
    if ui_saver.hideInShop:Get() then
        for _, shop in ipairs(SECRET_SHOPS) do
            if (shop - pos):Length() < 1500 and countEnemyHeroes(shop, 600, team) == 0 then
                return shop
            end
        end
    end
    
    if ui_saver.smartEscape:Get() and enemyPos then
        local dir = (pos - enemyPos):Normalized()
        return pos + dir * 1200
    end
    
    return FOUNTAIN[team]
end

local function DrawTimer()
    if not ui_timer.enabled:Get() then return end
    
    local time = GameRules.GetGameTime()
    local hasTimers = false
    
    for team, data in pairs(CourierUltimate.State.deadCouriers) do
        if data.respawnTime - time <= 0 then
            CourierUltimate.State.deadCouriers[team] = nil
        else
            hasTimers = true
        end
    end
    
    if not hasTimers then return end
    
    local x, y = 50, 50
    local h = 10
    
    for team, data in pairs(CourierUltimate.State.deadCouriers) do
        local left = data.respawnTime - time
        if left > 0 then
            h = h + 20
        end
    end
    
    Render.FilledRect(Vec2(x, y), Vec2(x + 110, y + h), Color(15, 15, 20, 200), 4)
    
    local yOff = 6
    for team, data in pairs(CourierUltimate.State.deadCouriers) do
        local left = data.respawnTime - time
        if left > 0 then
            local text = string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60))
            local color = team == 2 and Color(120, 255, 120) or Color(255, 120, 120)
            
            if data.ownerHero then
                local heroName = NPC.GetUnitName(data.ownerHero)
                if heroName then
                    if not CourierUltimate.State.heroIcons[heroName] then
                        CourierUltimate.State.heroIcons[heroName] = Render.LoadImage("panorama/images/heroes/icons/" .. heroName .. "_png.vtex_c")
                    end
                    if CourierUltimate.State.heroIcons[heroName] then
                        Render.Image(CourierUltimate.State.heroIcons[heroName], Vec2(x + 4, y + yOff - 2), Vec2(16, 16))
                    end
                end
            end
            
            Render.Text(font, 12, text, Vec2(x + 24, y + yOff), color)
            yOff = yOff + 20
        end
    end
end

local function DrawInventory()
    if not ui_inv.enabled:Get() then return end
    
    local altDown = Input.IsKeyDown(Enum.ButtonCode.KEY_LALT)
    local show = not ui_inv.altOnly:Get() or altDown
    CourierUltimate.State.alpha = math.min(255, CourierUltimate.State.alpha + (show and 15 or -15))
    if CourierUltimate.State.alpha <= 0 then return end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) then
            local name = NPC.GetUnitName(npc)
            if name and (name == "npc_dota_courier" or name:find("courier")) then
                if Entity.GetTeamNum(npc) ~= myTeam then
                    local items = getCourierItems(npc)
                    if #items > 0 then
                        local pos = Entity.GetAbsOrigin(npc) + Vector(0, 0, 150)
                        local screen, vis = Render.WorldToScreen(pos)
                        if vis and screen then
                            local is3x3 = ui_inv.layout:Get() == 1
                            local cols = is3x3 and math.min(3, #items) or #items
                            local rows = is3x3 and math.ceil(#items / cols) or 1
                            local cw, ch = 26, 24
                            local w = cols * cw
                            local h = rows * ch
                            local x = screen.x - w / 2
                            local y = screen.y - h / 2
                            
                            for i, item in ipairs(items) do
                                local row = math.floor((i - 1) / cols)
                                local col = (i - 1) % cols
                                local cx = x + col * cw
                                local cy = y + row * ch
                                
                                local icon = loadItemIcon(Ability.GetName(item))
                                if icon then
                                    Render.Image(icon, Vec2(cx, cy), Vec2(cw - 2, ch - 2), Color(255, 255, 255, CourierUltimate.State.alpha), 3)
                                end
                                
                                local charges = Ability.GetCurrentCharges(item)
                                if charges and charges > 0 then
                                    local txt = tostring(charges)
                                    Render.Text(font, 10, txt, Vec2(cx + cw - 12, cy + ch - 12), Color(255, 255, 255, CourierUltimate.State.alpha))
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function UpdateSaver()
    if not ui_saver.enabled:Get() then return end
    
    local courier = Couriers.GetLocal()
    if not courier or not Entity.IsAlive(courier) then
        CourierUltimate.State.escaping = false
        return
    end
    
    local pos = Entity.GetAbsOrigin(courier)
    local team = Entity.GetTeamNum(courier)
    local hp = Entity.GetHealth(courier)
    local maxHP = Entity.GetMaxHealth(courier)
    local hpPct = (hp / maxHP) * 100
    local time = GameRules.GetGameTime()
    
    if CourierUltimate.State.lastHP > 0 and hp < CourierUltimate.State.lastHP then
        CourierUltimate.State.escaping = true
        CourierUltimate.State.lastEscapeTime = time
        if ui_saver.showAlerts:Get() then
            Chat.Print("ConsoleChat", "<font color='#ff4444'>[Courier]</font> Under attack!")
        end
    end
    CourierUltimate.State.lastHP = hp
    
    local threat, enemy = evaluateThreat(courier, pos, team)
    
    if (hpPct <= ui_saver.criticalHP:Get() and threat > 0) or threat >= 70 then
        if not CourierUltimate.State.escaping or time - CourierUltimate.State.lastEscapeTime > 2 then
            local enemyPos = enemy and Entity.GetAbsOrigin(enemy)
            local target = findSafeEscape(pos, enemyPos, team)
            
            Player.PrepareUnitOrders(
                Players.GetLocal(),
                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                nil,
                target,
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                courier
            )
            
            CourierUltimate.State.escaping = true
            CourierUltimate.State.escapeTarget = target
            CourierUltimate.State.lastEscapeTime = time
            
            if ui_saver.showAlerts:Get() then
                Chat.Print("ConsoleChat", "<font color='#ff8800'>[Courier]</font> Escaping!")
            end
        end
    elseif CourierUltimate.State.escaping and threat < 30 and time - CourierUltimate.State.lastEscapeTime > 3 then
        CourierUltimate.State.escaping = false
        CourierUltimate.State.escapeTarget = nil
    end
end

function CourierUltimate.OnUpdate()
    if not ui_timer.enabled:Get() then return end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    local tracked = {}
    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) then
            local name = NPC.GetUnitName(npc)
            if name and (name == "npc_dota_courier" or name:find("courier")) then
                local team = Entity.GetTeamNum(npc)
                if team ~= myTeam then
                    tracked[Entity.GetIndex(npc)] = {team = team, time = GameRules.GetGameTime()}
                end
            end
        end
    end
    
    local time = GameRules.GetGameTime()
    for id, data in pairs(CourierUltimate.State.trackedCouriers) do
        if not tracked[id] and time - data.time < 2 then
            local owner = nil
            for i = 1, Heroes.Count() do
                local h = Heroes.Get(i)
                if h and Entity.GetTeamNum(h) == data.team then
                    owner = h
                    break
                end
            end
            
            local respawn = getCourierRespawnTime()
            CourierUltimate.State.deadCouriers[data.team] = {
                deathTime = time,
                respawnTime = time + respawn,
                ownerHero = owner
            }
        end
    end
    
    CourierUltimate.State.trackedCouriers = tracked
end

function CourierUltimate.OnDraw()
    DrawTimer()
    DrawInventory()
    UpdateSaver()
end

function CourierUltimate.OnPrepareUnitOrders(order)
    local courier = Couriers.GetLocal()
    if courier and order.npc and Entity.GetIndex(order.npc) == Entity.GetIndex(courier) then
        if order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then
            CourierUltimate.State.escaping = false
            CourierUltimate.State.escapeTarget = nil
        end
    end
    return true
end

return CourierUltimate
