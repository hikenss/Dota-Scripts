local CourierUltimate = {}

-- ============================================================================
-- Courier Ultimate - Timer, Inventory, Auto-Protect, River Routes, Alert
-- Features extraidas de courier_river_route_mvp e integradas no script
-- ============================================================================

-- River route safe waypoints (extracted from courier_river_route_mvp.md)
local RIVER_ROUTE_CHAINS = {
    bot_safe = {
        name = "bot_safe",
        team = "radiant",
        points = {
            Vector(-4270.756, -7550.622, 262),
            Vector(-1573.83, -7836.8164, 136.00049),
            Vector(-637.0481, -8264.06, 136.00049),
            Vector(2713.4849, -7671.9453, 8.000488),
            Vector(4598.5317, -7626.057, 8.000488),
        }
    },
    top_safe = {
        name = "top_safe",
        team = "dire",
        points = {
            Vector(3826.729, 7283.053, 262.94336),
            Vector(2115.2205, 7141.1875, 136.00049),
            Vector(214.29291, 7428.9077, 136.00049),
            Vector(-1262.4188, 7963.4795, 134),
            Vector(-3598.7456, 8248.121, 8.000488),
            Vector(-4742.2163, 7557.3184, 8.000488),
        }
    }
}

-- Courier ability helpers (extracted from river route source)
local function tryCourierAbility(courier, abilityName)
    if not courier then return false end
    local ability = NPC.GetAbilityByName(courier, abilityName)
    if not ability then return false end
    -- Check if ability is activated and ready
    local ok1, activated = pcall(Ability.IsActivated, ability)
    if not ok1 or not activated then return false end
    local ok2, ready = pcall(Ability.IsCastable, ability, 0, true)
    if not ok2 or not ready then return false end
    local ok3 = pcall(Ability.CastNoTarget, ability)
    return ok3 == true
end

local function tryCourierBurst(courier, reasonTag)
    return tryCourierAbility(courier, "courier_burst")
end

local function tryCourierShield(courier, reasonTag)
    return tryCourierAbility(courier, "courier_shield")
end

local tab = Menu.Create("Scripts", "Utility", "Courier Ultimate")
tab:Icon("\u{f21e}")

local timerGroup = tab:Create("Main"):Create("Timer")
local invGroup = tab:Create("Main"):Create("Inventory")
local saverGroup = tab:Create("Main"):Create("Auto Saver")
local alertGroup = tab:Create("Main"):Create("Alert")

local ui_timer = {}
ui_timer.enabled = timerGroup:Switch("Show Timer", true, "\u{f017}", true)
ui_timer.test = timerGroup:Button("Test 60s", function()
    local time = getTime()
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
ui_saver.dangerRange = saverGroup:Slider("Danger Range", 800, 2000, 1400, true)
ui_saver.criticalHP = saverGroup:Slider("Critical HP %", 20, 80, 50, true)
ui_saver.hideInShop = saverGroup:Switch("Hide in Secret Shop", true, "", true)
ui_saver.smartEscape = saverGroup:Switch("Smart Escape", true, "", true)
ui_saver.dynamicEscape = saverGroup:Switch("Dynamic Escape", true, "", true)
ui_saver.safeRouteCheck = saverGroup:Switch("Safe Route Check", true, "", true)
ui_saver.workFromMin = saverGroup:Slider("Escape from minute", 0, 99, 0, true)
ui_saver.workUntilMin = saverGroup:Slider("Escape until minute", 0, 99, 99, true)
ui_saver.overrideDuration = saverGroup:Slider("Manual Override (s)", 3, 15, 8, true)
ui_saver.showAlerts = saverGroup:Switch("Show Alerts", false, "", true)
ui_saver.autoReturn = saverGroup:Switch("Auto Return to Base", true, "", true)

local ui_alert = {}
ui_alert.enabled = alertGroup:Switch("Alert on Spotted", true, "\u{1f514}", true)
ui_alert.sound = alertGroup:Switch("Play Sound", true, "", true)
ui_alert.chat = alertGroup:Switch("Chat Message", true, "", true)
ui_alert.ping = alertGroup:Switch("Ping Map", true, "", true)

local font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)

-- State initialization (required for timer, inventory, alerts, saver)
CourierUltimate.State = {
    deadCouriers = {},
    trackedCouriers = {},
    seenCouriers = {},
    alerts = {},
    itemIcons = {},
    heroIcons = {},
    alpha = 0,
    escaping = false,
    manualOverride = false,
    manualOverrideTime = 0,
    lastUpdateTime = 0,
    lastEscapeTime = 0,
    stuckCounter = 0,
    lastPosition = nil,
    alertTime = 0,
    goingToSecretShop = false,
    secretShopTarget = nil,
    secretShopAttemptTime = 0,
    escapeTarget = nil,
    alternateRoute = false,
    alternateRouteTime = 0,
    returningToBase = false,
}

local function log(msg) end

local FOUNTAIN = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7019, -6534, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(6846, 6251, 384)
}

local SECRET_SHOPS = {
    Vector(-4553, 1046, 256),
    Vector(4486, -1542, 256)
}

local function getTime()
    if GlobalVars and GlobalVars.GetCurTime then
        return GlobalVars.GetCurTime()
    end
    return GameRules.GetGameTime()
end

local SAFE_CORNERS = {
    [Enum.TeamNum.TEAM_RADIANT] = {
        Vector(-6800, -6800, 256),
        Vector(-7200, 6400, 256),
        Vector(-4800, -6600, 256)
    },
    [Enum.TeamNum.TEAM_DIRE] = {
        Vector(6800, 6800, 256),
        Vector(7200, -6400, 256),
        Vector(4800, 6600, 256)
    }
}

local function toReadableHeroName(hero)
    if not hero or not NPC.GetUnitName then return nil end
    local raw = NPC.GetUnitName(hero)
    if not raw then return nil end
    local clean = raw:gsub("npc_dota_hero_", ""):gsub("_", " ")
    if clean == "" then return nil end
    return clean:sub(1, 1):upper() .. clean:sub(2)
end

local function getCourierOwnerHero(courier)
    if not courier then return nil end
    if Entity.GetOwner then
        local owner = Entity.GetOwner(courier)
        if owner and (not Entity.IsHero or Entity.IsHero(owner)) then
            return owner
        end
    end
    local team = Entity.GetTeamNum(courier)
    local pos = Entity.GetAbsOrigin(courier)
    local closest, closestDist = nil, nil
    for i = 1, Heroes.Count() do
        local hero = Heroes.Get(i)
        if hero and Entity.GetTeamNum(hero) == team then
            local dist = (Entity.GetAbsOrigin(hero) - pos):Length()
            if not closestDist or dist < closestDist then
                closest, closestDist = hero, dist
            end
        end
    end
    return closest
end

local function formatCourierLabel(team, ownerHero)
    local ownerName = toReadableHeroName(ownerHero)
    if ownerName then
        return ownerName
    end
    return "Courier"
end

local function rememberAlert(id, courier, team, now)
    local owner = getCourierOwnerHero(courier)
    local label = formatCourierLabel(team, owner)
    local pos = Entity.GetAbsOrigin(courier)
    CourierUltimate.State.alerts[id] = {
        npc = courier,
        pos = pos,
        team = team,
        label = label,
        color = team == Enum.TeamNum.TEAM_RADIANT and Color(120, 255, 120, 230) or Color(255, 120, 120, 230),
        expire = now + 4
    }
    
    return label
end

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
    local dangerRange = ui_saver.dangerRange:Get()
    local enemyCount = 0
    
    -- Check enemy heroes
    for i = 1, Heroes.Count() do
        local enemy = Heroes.Get(i)
        if enemy and Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= team and not NPC.IsIllusion(enemy) then
            local epos = Entity.GetAbsOrigin(enemy)
            local dist = (epos - pos):Length()
            
            if dist < dangerRange * 2 then
                if dist < minDist then
                    minDist = dist
                    closest = enemy
                end
                
                if dist < dangerRange * 1.5 then
                    enemyCount = enemyCount + 1
                end
                
                local range = NPC.GetAttackRange(enemy) + 200
                
                if dist < range then 
                    threat = 100
                elseif dist < range + 400 then 
                    threat = math.max(threat, 85)
                elseif dist < dangerRange * 0.6 then 
                    threat = math.max(threat, 60)
                elseif dist < dangerRange then 
                    threat = math.max(threat, 35)
                elseif dist < dangerRange * 1.2 then 
                    threat = math.max(threat, 20)
                end
            end
        end
    end
    
    -- Check enemy towers (from river route source)
    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) and Entity.GetTeamNum(npc) ~= team then
            local name = NPC.GetUnitName(npc) or ""
            if name:find("tower") then
                local tpos = Entity.GetAbsOrigin(npc)
                local tdist = (tpos - pos):Length()
                if tdist < 950 then
                    threat = math.max(threat, 90)
                    if tdist < minDist then
                        minDist = tdist
                        closest = npc
                    end
                end
            end
        end
    end
    
    return threat, closest, minDist, enemyCount
end

local function findSafeEscape(pos, enemyPos, team, threat)
    -- Critical danger: go straight to fountain
    if threat >= 90 then
        return FOUNTAIN[team]
    end
    
    -- Try river route if available (safest path, avoids neutral camps)
    if ui_saver.smartEscape:Get() and threat < 85 then
        local teamKey = (team == Enum.TeamNum.TEAM_RADIANT) and "radiant" or "dire"
        for _, route in pairs(RIVER_ROUTE_CHAINS) do
            if route.team == teamKey and route.points then
                -- Find nearest waypoint in the route
                local nearestIdx = nil
                local nearestDist = 99999
                for i, wp in ipairs(route.points) do
                    local d = (wp - pos):Length()
                    if d < nearestDist then
                        nearestDist = d
                        nearestIdx = i
                    end
                end
                -- Route is usable if a waypoint is within 3000 units
                if nearestIdx and nearestDist < 3000 then
                    -- Check the nearest waypoint is safe
                    local target = route.points[nearestIdx]
                    if countEnemyHeroes(target, 1100, team) == 0 then
                        -- Pick the waypoint that's farthest FROM the enemy
                        if enemyPos then
                            local bestWp = target
                            local bestEnemyDist = (target - enemyPos):Length()
                            -- Check adjacent waypoints for better escape
                            for offset = -1, 1, 2 do
                                local adj = nearestIdx + offset
                                if adj >= 1 and adj <= #route.points then
                                    local adjWp = route.points[adj]
                                    local adjEDist = (adjWp - enemyPos):Length()
                                    if adjEDist > bestEnemyDist and countEnemyHeroes(adjWp, 1100, team) == 0 then
                                        bestWp = adjWp
                                        bestEnemyDist = adjEDist
                                    end
                                end
                            end
                            return bestWp
                        else
                            return target
                        end
                    end
                end
            end
        end
    end
    
    -- Try secret shop
    if ui_saver.hideInShop:Get() and threat < 70 then
        for _, shop in ipairs(SECRET_SHOPS) do
            local shopDist = (shop - pos):Length()
            if shopDist < 1500 and countEnemyHeroes(shop, 600, team) == 0 then
                if enemyPos then
                    local currentEnemyDist = (pos - enemyPos):Length()
                    local shopEnemyDist = (shop - enemyPos):Length()
                    if shopEnemyDist > currentEnemyDist then
                        return shop
                    end
                else
                    return shop
                end
            end
        end
    end
    
    -- Try safe corners (improved: also check tower safety)
    if SAFE_CORNERS[team] then
        local safestCorner = nil
        local maxScore = 0
        for _, corner in ipairs(SAFE_CORNERS[team]) do
            local enemyCount = countEnemyHeroes(corner, 1100, team)
            if enemyCount == 0 then
                local enemyDist = enemyPos and (corner - enemyPos):Length() or 9999
                local fromPos = (corner - pos):Length()
                -- Score: prefer far from enemy, not too far from us
                local score = enemyDist - (fromPos * 0.3)
                if score > maxScore and fromPos < 4000 then
                    maxScore = score
                    safestCorner = corner
                end
            end
        end
        if safestCorner and maxScore > 800 then
            return safestCorner
        end
    end
    
    -- Dynamic escape: move away from enemy (perpendicular to avoid running into more trouble)
    if ui_saver.dynamicEscape:Get() and enemyPos then
        local dir = (pos - enemyPos):Normalized()
        local escapeDistance = math.min(1800, ui_saver.dangerRange:Get())
        -- Try perpendicular directions too to avoid mid-lane deaths
        local candidates = {
            pos + dir * escapeDistance,
            pos + Vector(dir.y, -dir.x, 0):Normalized() * escapeDistance,
            pos + Vector(-dir.y, dir.x, 0):Normalized() * escapeDistance,
        }
        local bestCandidate = candidates[1]
        local bestSafety = 0
        for _, cand in ipairs(candidates) do
            local safety = (cand - enemyPos):Length()
            local nearEnemy = countEnemyHeroes(cand, 1000, team)
            if nearEnemy == 0 and safety > bestSafety then
                bestSafety = safety
                bestCandidate = cand
            end
        end
        return bestCandidate
    end
    
    return FOUNTAIN[team]
end

local function findSafeReturnPath(pos, team)
    -- Find nearest safe corner to route through
    if SAFE_CORNERS[team] then
        local nearestCorner = nil
        local minDist = 9999
        for _, corner in ipairs(SAFE_CORNERS[team]) do
            if countEnemyHeroes(corner, 1000, team) == 0 then
                local dist = (corner - pos):Length()
                if dist < minDist then
                    minDist = dist
                    nearestCorner = corner
                end
            end
        end
        if nearestCorner and minDist < 3000 then
            return nearestCorner
        end
    end
    return FOUNTAIN[team]
end

local function DrawTimer()
    if not ui_timer.enabled:Get() then return end
    
    local time = GameRules.GetGameTime()
    local hasTimers = false
    
    -- Limpar timers expirados
    for id, data in pairs(CourierUltimate.State.deadCouriers) do
        if data.respawnTime - time <= 0 then
            CourierUltimate.State.deadCouriers[id] = nil
        else
            hasTimers = true
        end
    end
    
    if not hasTimers then return end
    
    local x, y = 50, 50
    local h = 10
    
    -- Calcular altura necessária
    for id, data in pairs(CourierUltimate.State.deadCouriers) do
        local left = data.respawnTime - time
        if left > 0 then
            h = h + 20
        end
    end
    
    Render.FilledRect(Vec2(x, y), Vec2(x + 110, y + h), Color(15, 15, 20, 200), 4)
    
    local yOff = 6
    for id, data in pairs(CourierUltimate.State.deadCouriers) do
        local left = data.respawnTime - time
        if left > 0 then
            local text = string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60))
            local color = data.team == 2 and Color(120, 255, 120) or Color(255, 120, 120)
            
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
    
    -- Collect all couriers from multiple sources
    local seen = {}
    local couriers = {}
    local function tryAdd(npc)
        if not npc then return end
        local idx = Entity.GetIndex(npc)
        if seen[idx] then return end
        seen[idx] = true
        local name = NPC.GetUnitName(npc)
        if name and (name == "npc_dota_courier" or name:find("courier")) then
            if Entity.GetTeamNum(npc) ~= myTeam and Entity.IsAlive(npc) then
                couriers[#couriers+1] = npc
            end
        end
    end
    for _, npc in ipairs(NPCs.GetAll()) do tryAdd(npc) end
    if Couriers and Couriers.GetAll then
        local ok, list = pcall(Couriers.GetAll)
        if ok and list then
            for _, c in ipairs(list) do tryAdd(c) end
        end
    end
    
    for _, npc in ipairs(couriers) do
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

local function UpdateSaver()
    if not ui_saver.enabled:Get() then return end
    
    local courier = Couriers.GetLocal()
    if not courier or not Entity.IsAlive(courier) then
        CourierUltimate.State.escaping = false
        CourierUltimate.State.manualOverride = false
        return
    end
    
    local pos = Entity.GetAbsOrigin(courier)
    local team = Entity.GetTeamNum(courier)
    local time = GameRules.GetGameTime()
    local player = Players.GetLocal()
    local dotaTime = GameRules.GetDOTATime and GameRules.GetDOTATime() or time
    local minute = math.max(0, math.floor((dotaTime or 0) / 60))
    
    if not player then return end

    local fromMin = ui_saver.workFromMin:Get()
    local untilMin = ui_saver.workUntilMin:Get()
    if fromMin > untilMin then fromMin = untilMin end
    if minute < fromMin or minute > untilMin then
        return
    end

    -- Throttle
    if time - CourierUltimate.State.lastUpdateTime < 0.5 then
        return
    end
    CourierUltimate.State.lastUpdateTime = time
    log("UpdateSaver called")
    
    -- NÃO FUGIR se estiver entregando itens
    local courierState = Courier.GetCourierState(courier)
    if courierState == Enum.CourierState.COURIER_STATE_DELIVERING_ITEMS then
        log("Delivering items, not escaping")
        return
    end
    
    -- Detectar travamento
    if CourierUltimate.State.lastPosition then
        local moved = (pos - CourierUltimate.State.lastPosition):Length()
        if CourierUltimate.State.escaping and moved < 15 then
            CourierUltimate.State.stuckCounter = CourierUltimate.State.stuckCounter + 1
        else
            CourierUltimate.State.stuckCounter = 0
        end
    end
    CourierUltimate.State.lastPosition = pos
    
    -- Check manual override
    if CourierUltimate.State.manualOverride and (time - CourierUltimate.State.manualOverrideTime) > ui_saver.overrideDuration:Get() then
        CourierUltimate.State.manualOverride = false
    end
    
    if CourierUltimate.State.manualOverride then return end
    
    -- Avaliar ameaça
    local threat, enemy, enemyDist, enemyCount = evaluateThreat(courier, pos, team)
    log(string.format("Threat: %d, Dist: %.0f, Stuck: %d", threat, enemyDist, CourierUltimate.State.stuckCounter))
    
    -- Se ameaça >= 50 (mais alto para não fugir sempre), fugir IMEDIATAMENTE
    if threat >= 50 then
        local enemyPos = enemy and Entity.GetAbsOrigin(enemy)
        local escapeTarget = findSafeEscape(pos, enemyPos, team, threat) or FOUNTAIN[team]

        if ui_saver.safeRouteCheck:Get() and countEnemyHeroes(escapeTarget, 900, team) > 0 then
            escapeTarget = FOUNTAIN[team]
        end
        
        -- Se travado OU se última rota alternativa foi recente, fugir para longe do inimigo
        if CourierUltimate.State.stuckCounter >= 3 or (CourierUltimate.State.alternateRoute and time - CourierUltimate.State.alternateRouteTime < 5) then
            if enemyPos then
                local dir = (pos - enemyPos):Normalized()
                escapeTarget = pos + dir * 2000
            end
            CourierUltimate.State.stuckCounter = 0
            CourierUltimate.State.alternateRoute = true
            CourierUltimate.State.alternateRouteTime = time
            log("Using alternate route")
        else
            CourierUltimate.State.alternateRoute = false
        end
        
        -- Use courier burst if available before escaping
        tryCourierBurst(courier, "escape")
        
        -- If critical danger, use shield
        if threat >= 80 then
            tryCourierShield(courier, "critical_escape")
        end
        
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            escapeTarget,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            courier,
            false,
            false
        )
        
        log(string.format("ESCAPING! Threat: %d", threat))
        CourierUltimate.State.escaping = true
        CourierUltimate.State.lastEscapeTime = time
        return
    end
    
    -- Seguro
    if CourierUltimate.State.escaping and threat < 15 then
        CourierUltimate.State.escaping = false
        CourierUltimate.State.stuckCounter = 0
        log("Safe now")
    end
end

function CourierUltimate.OnUpdate()
    UpdateSaver()

    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    -- Tracking de couriers inimigos (necessário para timer E alertas)
    local tracked = {}
    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) then
            local name = NPC.GetUnitName(npc)
            if name and (name == "npc_dota_courier" or name:find("courier")) then
                local team = Entity.GetTeamNum(npc)
                if team ~= myTeam then
                    local owner = getCourierOwnerHero(npc)
                    tracked[Entity.GetIndex(npc)] = {team = team, time = GameRules.GetGameTime(), owner = owner}
                end
            end
        end
    end
    -- Também verificar via Couriers.GetAll se disponível
    if Couriers and Couriers.GetAll then
        local ok, list = pcall(Couriers.GetAll)
        if ok and list then
            for _, npc in ipairs(list) do
                if npc and Entity.IsAlive(npc) then
                    local idx = Entity.GetIndex(npc)
                    if not tracked[idx] then
                        local team = Entity.GetTeamNum(npc)
                        if team ~= myTeam then
                            local owner = getCourierOwnerHero(npc)
                            tracked[idx] = {team = team, time = GameRules.GetGameTime(), owner = owner}
                        end
                    end
                end
            end
        end
    end
    
    local time = GameRules.GetGameTime()
    if ui_timer.enabled:Get() then
        for id, data in pairs(CourierUltimate.State.trackedCouriers) do
            if not tracked[id] and time - data.time < 2 then
                -- Só adicionar se não existe já um timer para este courier
                if not CourierUltimate.State.deadCouriers[id] then
                    local owner = data.owner
                    if not owner then
                        -- Fallback: attempt to resolve owner now if we failed while alive
                        for i = 1, Heroes.Count() do
                            local h = Heroes.Get(i)
                            if h and Entity.GetTeamNum(h) == data.team then
                                owner = h
                                break
                            end
                        end
                    end
                    
                    local respawn = getCourierRespawnTime()
                    CourierUltimate.State.deadCouriers[id] = {
                        deathTime = time,
                        respawnTime = time + respawn,
                        ownerHero = owner,
                        team = data.team
                    }
                end
            end
        end
    end
    
    CourierUltimate.State.trackedCouriers = tracked
    
    if ui_alert.enabled:Get() then
        local time = getTime()
        local currentCouriers = {}
        
        for _, npc in ipairs(NPCs.GetAll()) do
            if npc and Entity.IsAlive(npc) then
                local name = NPC.GetUnitName(npc)
                if name and (name == "npc_dota_courier" or name:find("courier")) then
                    local team = Entity.GetTeamNum(npc)
                    if team ~= myTeam then
                        local id = Entity.GetIndex(npc)
                        currentCouriers[id] = true
                        
                        if not CourierUltimate.State.seenCouriers[id] then
                            if time - CourierUltimate.State.alertTime > 3 then
                                CourierUltimate.State.alertTime = time
                                
                                local alertLabel = rememberAlert(id, npc, team, time)
                                
                                if ui_alert.sound:Get() then
                                    Engine.ExecuteCommand("playvol sounds/ui/chat_wheel_message.vsnd 1")
                                end
                                
                                if ui_alert.chat:Get() then
                                    Chat.Print("ConsoleChat", string.format("<font color='#ff0000'>[COURIER]</font> %s", alertLabel))
                                end
                                
                                if ui_alert.ping:Get() then
                                    local pos = Entity.GetAbsOrigin(npc)
                                    Player.PrepareUnitOrders(
                                        Players.GetLocal(),
                                        Enum.UnitOrder.DOTA_UNIT_ORDER_PING_ABILITY,
                                        npc,
                                        Vector(0, 0, 0),
                                        nil,
                                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                        nil
                                    )
                                end
                            end
                            CourierUltimate.State.seenCouriers[id] = time
                        else
                            local existing = CourierUltimate.State.alerts[id]
                            if existing then
                                existing.expire = time + 2
                                existing.npc = npc
                                existing.pos = Entity.GetAbsOrigin(npc)
                            end
                        end
                    end
                end
            end
        end
        
        for id, lastSeen in pairs(CourierUltimate.State.seenCouriers) do
            if not currentCouriers[id] and time - lastSeen > 5 then
                CourierUltimate.State.seenCouriers[id] = nil
                CourierUltimate.State.alerts[id] = nil
            end
        end
    end

end

local function DrawAlerts()
    if not ui_alert.enabled:Get() then return end
    local now = GameRules.GetGameTime()
    
    -- Clean up alerts for couriers in fog first
    for id, alert in pairs(CourierUltimate.State.alerts) do
        if alert.npc and Entity.IsAlive(alert.npc) then
            local isVisible = false
            if Entity.IsVisibleToPlayer then
                isVisible = Entity.IsVisibleToPlayer(alert.npc, Players.GetLocal())
            end
            if not isVisible then
                CourierUltimate.State.alerts[id] = nil
            end
        end
    end
    
    -- Now draw remaining visible alerts
    for id, alert in pairs(CourierUltimate.State.alerts) do
        if now > alert.expire then
            CourierUltimate.State.alerts[id] = nil
        elseif alert.npc and Entity.IsAlive(alert.npc) then
            local isVisible = false
            if Entity.IsVisibleToPlayer then
                isVisible = Entity.IsVisibleToPlayer(alert.npc, Players.GetLocal())
            end
            
            if isVisible then
                local pos = Entity.GetAbsOrigin(alert.npc)
                local screen, vis = Render.WorldToScreen(pos + Vector(0, 0, 120))
                if vis and screen then
                    local label = alert.label or "Enemy courier"
                    local ok_ts, size = pcall(Render.TextSize, font, 13, label)
                    if not ok_ts or not size then size = Vec2(#label * 7, 14) end
                    local padding = 6
                    local bx = screen.x - size.x / 2 - padding
                    local by = screen.y - size.y - 18
                    Render.FilledRect(Vec2(bx, by), Vec2(bx + size.x + padding * 2, by + size.y + 8), Color(15, 15, 20, 200), 4)
                    Render.Text(font, 13, label, Vec2(screen.x - size.x / 2, by + 2), alert.color or Color(255, 220, 120, 230))
                    Render.Circle(screen, 10, alert.color or Color(255, 220, 120, 230))
                end
            end
        end
    end
end

local function DrawMinimapPings()
    -- Removed - using dota_ping_location command instead
end

function CourierUltimate.OnDraw()

    DrawTimer()
    DrawInventory()
    DrawAlerts()
end

function CourierUltimate.OnPrepareUnitOrders(order)

    local courier = Couriers.GetLocal()
    if courier and order.npc and Entity.GetIndex(order.npc) == Entity.GetIndex(courier) then
        local time = GameRules.GetGameTime()
        
        if order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then
            local pos = Entity.GetAbsOrigin(courier)
            
            -- Check if player is sending courier to secret shop
            local isSecretShop = false
            for _, shop in ipairs(SECRET_SHOPS) do
                if order.position and (order.position - shop):Length() < 500 then
                    CourierUltimate.State.goingToSecretShop = true
                    CourierUltimate.State.secretShopTarget = shop
                    CourierUltimate.State.secretShopAttemptTime = time
                    CourierUltimate.State.escaping = false
                    CourierUltimate.State.returningToBase = false
                    CourierUltimate.State.manualOverride = true
                    CourierUltimate.State.manualOverrideTime = time
                    isSecretShop = true
                    break
                end
            end
            
            -- Check if it's a manual order (not from auto-protect system)
            -- Only activate override if it's NOT from PASSED_UNIT_ONLY or CURRENT_UNIT_ONLY (script orders)
            if not isSecretShop and order.issuer and 
               order.issuer ~= Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY and
               order.issuer ~= Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_CURRENT_UNIT_ONLY then
                -- Player gave manual order - activate override
                CourierUltimate.State.manualOverride = true
                CourierUltimate.State.manualOverrideTime = time
                CourierUltimate.State.escaping = false
                CourierUltimate.State.escapeTarget = nil
                CourierUltimate.State.returningToBase = false
                
                if ui_saver.showAlerts:Get() then
                    Chat.Print("ConsoleChat", string.format("<font color='#ffff00'>[Courier]</font> Manual control (%ds)", ui_saver.overrideDuration:Get()))
                end
            end
        elseif order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_GIVE_ITEM or 
               order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_TRANSFER_ITEM then
            -- Player is managing items - activate override
            CourierUltimate.State.manualOverride = true
            CourierUltimate.State.manualOverrideTime = time
        end
    end
    return true
end

function CourierUltimate.OnGameEnd()
    CourierUltimate.State.deadCouriers = {}
    CourierUltimate.State.trackedCouriers = {}
    CourierUltimate.State.seenCouriers = {}
    CourierUltimate.State.alerts = {}
    CourierUltimate.State.escaping = false
    CourierUltimate.State.manualOverride = false
    CourierUltimate.State.lastPosition = nil
    CourierUltimate.State.stuckCounter = 0
    CourierUltimate.State.goingToSecretShop = false
    CourierUltimate.State.returningToBase = false
    CourierUltimate.State.alternateRoute = false
    CourierUltimate.State.escapeTarget = nil
end

return CourierUltimate