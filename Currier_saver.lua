-- Courier Saver Avançado - Proteção Inteligente do Courier com IA

local tab = Menu.Create("Miscellaneous", "In Game", "Courier")
local mainUI = tab:Create("Main"):Create("Courier")

-- UI
local enableSaver = mainUI:Switch("Ativar Proteção Automática", true, "🛡️")
local smartEscape = mainUI:Switch("Fuga Inteligente", true)
local useTreePaths = mainUI:Switch("Usar Caminhos nas Árvores", true)
local dangerRadius = mainUI:Slider("Raio de Detecção", 800, 2000, 1400)
local criticalHP = mainUI:Slider("HP Crítico (%)", 20, 80, 50)
local hideInShop = mainUI:Switch("Esconder em Loja Secreta", true)
local maxHideTime = mainUI:Slider("Tempo Máx. Escondido (s)", 3, 15, 8)
local autoReturn = mainUI:Switch("Retornar Após Entregar", true)
local showAlerts = mainUI:Switch("Mostrar Alertas", true)
local manualOverride = mainUI:Switch("Permitir Controle Manual", true)
local antiStuck = mainUI:Switch("Anti-Travamento", true)
local stayHidden = mainUI:Switch("Manter-se Escondido Quando Parado", true)
local preventReturn = mainUI:Switch("Prevenir Volta (40% do Caminho)", true)

-- Constantes
local FOUNTAIN_POSITIONS = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7019, -6534, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(6846, 6251, 384)
}

local SECRET_SHOPS = {
    Vector(-4553, 1046, 256),  -- Radiant secret shop
    Vector(4486, -1542, 256)   -- Dire secret shop
}

-- Estado
local courierState = {
    escaping = false,
    hidingInShop = false,
    hideStartTime = 0,
    lastDamageTime = 0,
    destination = nil,
    escapeStartTime = 0,
    lastAlertTime = 0,
    underAttack = false,
    lastHP = 0,
    lastPosition = nil,
    stuckCounter = 0,
    lastOrderTime = 0,
    manualControl = false,
    lastManualTime = 0,
    pathCheckpoints = {},
    currentCheckpoint = 1,
    lastItemCount = 0,
    justDelivered = false,
    deliveryTime = 0,
    manuallyInShop = false,
    lastUnstuckTime = 0,
    recentlyThreatened = false,
    lastThreatCheck = 0,
    isBeingSeen = false,
    hidingFromVision = false,
    lastVisionCheck = 0,
    deliveryStartPos = nil,
    deliveryTargetPos = nil,
    deliveryProgress = 0
}

-- Funções auxiliares
local lastAlertMessage = ""
local function printAlert(message, color)
    if not showAlerts:Get() then return end
    local now = GlobalVars.GetCurTime()
    
    -- Evitar mensagem repetida ou spam
    if message == lastAlertMessage and now - courierState.lastAlertTime < 3 then 
        return 
    end
    
    courierState.lastAlertTime = now
    lastAlertMessage = message
    Chat.Print("ConsoleChat", string.format("<font color='%s'>[Courier Saver]</font> %s", color, message))
end

local function isInSecretShop(pos)
    for _, shopPos in ipairs(SECRET_SHOPS) do
        if (pos - shopPos):Length() < 400 then
            return true, shopPos
        end
    end
    return false, nil
end

local function findNearestTree(pos)
    local trees = Trees.InRadius(pos, 800, true)
    if #trees > 0 then
        local nearestTree = trees[1]
        local minDist = (Entity.GetAbsOrigin(nearestTree) - pos):Length()
        for _, tree in ipairs(trees) do
            local dist = (Entity.GetAbsOrigin(tree) - pos):Length()
            if dist < minDist then
                minDist = dist
                nearestTree = tree
            end
        end
        return Entity.GetAbsOrigin(nearestTree)
    end
    return nil
end

local function isNearTower(pos, team)
    local towers = NPCs.InRadius(pos, 900, team, Enum.TeamType.TEAM_ENEMY)
    for _, tower in ipairs(towers) do
        if NPC.IsTower(tower) and Entity.IsAlive(tower) then
            return true
        end
    end
    return false
end

local function isBeingSeenByEnemies(courier, courierPos, courierTeam)
    -- Verificar se há heróis inimigos com visão no courier
    for i = 1, Heroes.Count() do
        local hero = Heroes.Get(i)
        if hero and Entity.IsAlive(hero) and not Entity.IsSameTeam(courier, hero) then
            if Entity.IsHero(hero) and not NPC.IsIllusion(hero) then
                local heroPos = Entity.GetAbsOrigin(hero)
                local distance = (courierPos - heroPos):Length()
                
                -- Considerar range de visão diurna/noturna
                local visionRange = 1800  -- Visão padrão diurna
                if GameRules.GetGameTime() then
                    local gameTime = GameRules.GetGameTime()
                    local dayNightCycle = math.fmod(gameTime, 600)
                    if dayNightCycle >= 300 then  -- Noite
                        visionRange = 800
                    end
                end
                
                -- Se inimigo tem visão do courier
                if distance <= visionRange then
                    -- Verificar se não há fog of war (courier visível para inimigo)
                    if NPC.IsVisible(hero) or distance < 600 then
                        return true, hero
                    end
                end
            end
        end
    end
    return false, nil
end

local function findNearestHidingSpot(courierPos, courierTeam)
    -- Prioridade 1: Loja secreta
    for _, shopPos in ipairs(SECRET_SHOPS) do
        local dist = (courierPos - shopPos):Length()
        if dist < 1500 then
            return shopPos, "loja"
        end
    end
    
    -- Prioridade 2: Árvores próximas (fog)
    local trees = Trees.InRadius(courierPos, 1000, true)
    if #trees > 0 then
        -- Encontrar cluster de árvores longe de inimigos
        local bestTreePos = nil
        local bestScore = -1
        
        for _, tree in ipairs(trees) do
            local treePos = Entity.GetAbsOrigin(tree)
            local enemiesNear = countNearbyEnemies(treePos, 800, courierTeam)
            local distToCourier = (treePos - courierPos):Length()
            
            -- Score: preferir árvores perto do courier e longe de inimigos
            local score = (1000 - distToCourier) - (enemiesNear * 500)
            if score > bestScore then
                bestScore = score
                bestTreePos = treePos
            end
        end
        
        if bestTreePos then
            return bestTreePos, "arvores"
        end
    end
    
    -- Prioridade 3: Torres aliadas
    local towers = NPCs.InRadius(courierPos, 2000, courierTeam, Enum.TeamType.TEAM_FRIEND)
    for _, tower in ipairs(towers) do
        if NPC.IsTower(tower) and Entity.IsAlive(tower) then
            local towerPos = Entity.GetAbsOrigin(tower)
            return towerPos + Vector(200, 200, 0), "torre"
        end
    end
    
    return nil, nil
end

local function countNearbyEnemies(pos, radius, team)
    local enemies = NPCs.InRadius(pos, radius, team, Enum.TeamType.TEAM_ENEMY)
    local count = 0
    for _, enemy in ipairs(enemies) do
        if Entity.IsHero(enemy) and not NPC.IsIllusion(enemy) and Entity.IsAlive(enemy) then
            count = count + 1
        end
    end
    return count
end

local function isPathSafe(startPos, endPos, courierTeam)
    -- Verificar se o caminho passa por torres inimigas
    local direction = (endPos - startPos):Normalized()
    local distance = (endPos - startPos):Length()
    local steps = math.floor(distance / 200)
    
    for i = 1, steps do
        local checkPos = startPos + direction * (i * 200)
        if isNearTower(checkPos, courierTeam) then
            return false
        end
        
        -- Verificar heróis inimigos no caminho
        local enemiesNear = countNearbyEnemies(checkPos, 500, courierTeam)
        if enemiesNear > 0 then
            return false
        end
    end
    
    return true
end

local function generateSafeWaypoints(courierPos, targetPos, courierTeam)
    local waypoints = {}
    local direction = (targetPos - courierPos):Normalized()
    local distance = (targetPos - courierPos):Length()
    local numWaypoints = math.min(math.floor(distance / 800), 5)
    
    for i = 1, numWaypoints do
        local progress = i / (numWaypoints + 1)
        local waypoint = courierPos + direction * (distance * progress)
        
        -- Ajustar waypoint para evitar perigos
        local enemies = NPCs.InRadius(waypoint, 600, courierTeam, Enum.TeamType.TEAM_ENEMY)
        if #enemies > 0 then
            -- Desviar perpendicular
            local perpendicular = Vector(-direction.y, direction.x, 0)
            waypoint = waypoint + perpendicular * 400
        end
        
        table.insert(waypoints, waypoint)
    end
    
    table.insert(waypoints, targetPos)
    return waypoints
end

local function findSafestEscapeRoute(courierPos, enemyPos, courierTeam)
    local bestRoute = nil
    local bestScore = -1
    local routeType = "fonte"
    
    -- Avaliar múltiplas rotas possíveis
    local possibleRoutes = {}
    
    -- Rota 1: Loja secreta
    if hideInShop:Get() then
        for _, shopPos in ipairs(SECRET_SHOPS) do
            local distToShop = (shopPos - courierPos):Length()
            if distToShop < 2000 then
                local enemiesNearShop = countNearbyEnemies(shopPos, 600, courierTeam)
                if enemiesNearShop == 0 and isPathSafe(courierPos, shopPos, courierTeam) then
                    table.insert(possibleRoutes, {pos = shopPos, score = 100 - distToShop/20, type = "loja secreta"})
                end
            end
        end
    end
    
    -- Rota 2: Através de árvores
    if useTreePaths:Get() then
        local treePos = findNearestTree(courierPos)
        if treePos then
            local dirToTree = (treePos - courierPos):Normalized()
            local escapePos = courierPos + dirToTree * 1000
            if not isNearTower(escapePos, courierTeam) then
                local enemiesNear = countNearbyEnemies(escapePos, 400, courierTeam)
                if enemiesNear == 0 then
                    table.insert(possibleRoutes, {pos = escapePos, score = 80, type = "árvores"})
                end
            end
        end
    end
    
    -- Rota 3: Direção oposta ao inimigo
    if smartEscape:Get() and enemyPos then
        local directionAway = (courierPos - enemyPos):Normalized()
        for angle = -45, 45, 45 do
            local rad = math.rad(angle)
            local rotatedDir = Vector(
                directionAway.x * math.cos(rad) - directionAway.y * math.sin(rad),
                directionAway.x * math.sin(rad) + directionAway.y * math.cos(rad),
                0
            )
            local escapePos = courierPos + rotatedDir * 1500
            
            if not isNearTower(escapePos, courierTeam) then
                local enemiesNear = countNearbyEnemies(escapePos, 500, courierTeam)
                local score = 60 - enemiesNear * 20 - math.abs(angle) / 2
                if score > 0 then
                    table.insert(possibleRoutes, {pos = escapePos, score = score, type = "fuga lateral"})
                end
            end
        end
    end
    
    -- Rota 4: Fonte (sempre disponível)
    local fountainPos = FOUNTAIN_POSITIONS[courierTeam]
    table.insert(possibleRoutes, {pos = fountainPos, score = 50, type = "fonte"})
    
    -- Escolher melhor rota
    for _, route in ipairs(possibleRoutes) do
        if route.score > bestScore then
            bestScore = route.score
            bestRoute = route.pos
            routeType = route.type
        end
    end
    
    return bestRoute or fountainPos, routeType
end

local function evaluateThreatLevel(courier, courierPos, courierTeam)
    local radius = dangerRadius:Get()
    local enemies = NPCs.InRadius(courierPos, radius, courierTeam, Enum.TeamType.TEAM_ENEMY)
    local maxThreat = 0
    local closestEnemy = nil
    local closestDist = math.huge
    
    for _, enemy in ipairs(enemies) do
        if Entity.IsHero(enemy) and not NPC.IsIllusion(enemy) and Entity.IsAlive(enemy) then
            local enemyPos = Entity.GetAbsOrigin(enemy)
            local dist = (courierPos - enemyPos):Length()
            
            if dist < closestDist then
                closestDist = dist
                closestEnemy = enemy
            end
            
            local attackRange = NPC.GetAttackRange(enemy) + NPC.GetHullRadius(enemy)
            if not NPC.IsRanged(enemy) then
                attackRange = attackRange + 350
            else
                attackRange = attackRange + 280
            end
            
            -- Calcular nível de ameaça (mais agressivo)
            local threat = 0
            if dist <= attackRange then
                threat = 100 -- Ameaça crítica
            elseif dist <= attackRange + 200 then
                threat = 85 -- Ameaça muito alta
            elseif dist <= attackRange + 400 then
                threat = 70 -- Ameaça alta
            elseif dist <= radius * 0.6 then
                threat = 50 -- Ameaça média
            else
                threat = 30 -- Ameaça baixa
            end
            
            -- Aumentar ameaça se inimigo tem blink ou está se movendo em direção ao courier
            if NPC.HasModifier(enemy, "modifier_item_blink") then
                threat = threat + 25
            end
            
            -- Se inimigo está se aproximando, aumentar ameaça
            if NPC.IsRunning(enemy) then
                local enemyForward = Entity.GetAbsRotation(enemy):GetForward():Normalized()
                local dirToCourier = (courierPos - enemyPos):Normalized()
                local dotProduct = enemyForward.x * dirToCourier.x + enemyForward.y * dirToCourier.y
                if dotProduct > 0.7 then -- Indo em direção ao courier
                    threat = threat + 20
                end
            end
            
            maxThreat = math.max(maxThreat, threat)
        end
    end
    
    -- Verificar torres inimigas
    if isNearTower(courierPos, courierTeam) then
        maxThreat = math.max(maxThreat, 90)
    end
    
    return maxThreat, closestEnemy
end

local function isStuck(courierPos)
    if not antiStuck:Get() then return false end
    
    -- Não verificar travamento se estiver em controle manual ou na loja
    if courierState.manualControl or courierState.manuallyInShop then
        courierState.stuckCounter = 0
        courierState.lastPosition = courierPos
        return false
    end
    
    -- Só verificar travamento se estiver em fuga há pelo menos 2 segundos
    if not courierState.escaping or (GlobalVars.GetCurTime() - courierState.escapeStartTime) < 2 then
        courierState.stuckCounter = 0
        courierState.lastPosition = courierPos
        return false
    end
    
    if courierState.lastPosition then
        local moved = (courierPos - courierState.lastPosition):Length()
        if moved < 20 then
            courierState.stuckCounter = courierState.stuckCounter + 1
        else
            courierState.stuckCounter = 0
        end
    end
    
    courierState.lastPosition = courierPos
    return courierState.stuckCounter > 30
end

local function resetCourierState()
    courierState = {
        escaping = false,
        hidingInShop = false,
        hideStartTime = 0,
        lastDamageTime = 0,
        destination = nil,
        escapeStartTime = 0,
        lastAlertTime = 0,
        underAttack = false,
        lastHP = 0,
        lastPosition = nil,
        stuckCounter = 0,
        lastOrderTime = 0,
        manualControl = false,
        lastManualTime = 0,
        pathCheckpoints = {},
        currentCheckpoint = 1,
        lastItemCount = 0,
        justDelivered = false,
        deliveryTime = 0,
        manuallyInShop = false,
        lastUnstuckTime = 0,
        recentlyThreatened = false,
        lastThreatCheck = 0,
        isBeingSeen = false,
        hidingFromVision = false,
        lastVisionCheck = 0,
        deliveryStartPos = nil,
        deliveryTargetPos = nil,
        deliveryProgress = 0
    }
end

function OnUpdate()
    if not enableSaver:Get() then return end
    
    local player = Players.GetLocal()
    local hero = Heroes.GetLocal()
    local courier = Couriers.GetLocal()
    
    if not player or not hero or not courier or not Entity.IsAlive(courier) then
        resetCourierState()
        return
    end
    
    local courierPos = Entity.GetAbsOrigin(courier)
    local courierTeam = Entity.GetTeamNum(courier)
    local courierHP = Entity.GetHealth(courier)
    local courierMaxHP = Entity.GetMaxHealth(courier)
    local courierHPPercent = (courierHP / courierMaxHP) * 100
    local currentTime = GlobalVars.GetCurTime()
    
    -- Verificar controle manual
    if manualOverride:Get() and courierState.manualControl then
        if currentTime - courierState.lastManualTime > 5 then
            courierState.manualControl = false
            printAlert("🤖 Controle automático reativado", "#4488ff")
        else
            return
        end
    end
    
    -- Detectar travamento (apenas durante fuga automática)
    if courierState.escaping and isStuck(courierPos) then
        courierState.stuckCounter = 0
        courierState.escaping = false
        courierState.pathCheckpoints = {}
        courierState.currentCheckpoint = 1
        courierState.lastUnstuckTime = currentTime
        printAlert("⚠️ Travamento detectado! Liberando controle", "#ff8800")
        return
    end
    
    -- Cooldown após destravar para evitar loop
    if currentTime - courierState.lastUnstuckTime < 5 then
        return
    end
    
    -- Detectar se está sendo atacado
    if courierState.lastHP > 0 and courierHP < courierState.lastHP then
        courierState.underAttack = true
        courierState.lastDamageTime = currentTime
        courierState.hidingInShop = false
        courierState.pathCheckpoints = {}
        printAlert("⚠️ Sob ataque! Fugindo!", "#ff4444")
    end
    courierState.lastHP = courierHP
    
    -- Resetar estado de ataque após 3 segundos sem dano
    if courierState.underAttack and currentTime - courierState.lastDamageTime > 3 then
        courierState.underAttack = false
    end
    
    -- Contar itens no courier
    local currentItemCount = 0
    for slot = 0, 10 do
        local item = NPC.GetItemByIndex and NPC.GetItemByIndex(courier, slot)
        if item and Ability.GetName(item) ~= "" then
            currentItemCount = currentItemCount + 1
        end
    end
    
    -- Detectar entrega de itens
    if courierState.lastItemCount > 0 and currentItemCount < courierState.lastItemCount then
        courierState.justDelivered = true
        courierState.deliveryTime = currentTime
        printAlert("📦 Itens entregues!", "#44ff44")
    end
    courierState.lastItemCount = currentItemCount
    
    -- Verificar se está escondido na loja secreta
    local inShop, shopPos = isInSecretShop(courierPos)
    if inShop then
        if not courierState.hidingInShop then
            courierState.hidingInShop = true
            courierState.hideStartTime = currentTime
            
            -- Se não estava em fuga, assume que foi colocado manualmente
            if not courierState.escaping then
                courierState.manuallyInShop = true
                printAlert("🏪 Na loja secreta (controle manual)", "#4488ff")
            else
                courierState.manuallyInShop = false
                printAlert("🏪 Escondido na loja secreta", "#44ff44")
            end
        end
        
        -- Se foi colocado manualmente, não interferir
        if courierState.manuallyInShop then
            return
        end
        
        -- Se está sendo atacado, sair imediatamente
        if courierState.underAttack then
            courierState.hidingInShop = false
            courierState.hideStartTime = 0
            courierState.manuallyInShop = false
            -- Continua para lógica de fuga abaixo
        else
            -- Verificar tempo máximo escondido (apenas se foi pelo script)
            local hideTime = currentTime - courierState.hideStartTime
            if hideTime > maxHideTime:Get() then
                local enemiesNear = countNearbyEnemies(courierPos, 800, courierTeam)
                if enemiesNear == 0 then
                    courierState.hidingInShop = false
                    courierState.hideStartTime = 0
                    courierState.manuallyInShop = false
                    printAlert("⏰ Tempo limite escondido, área segura", "#44ff44")
                end
            end
            
            -- Se está na loja e NÃO está sendo atacado, monitorar
            local enemiesNear = countNearbyEnemies(courierPos, 600, courierTeam)
            if enemiesNear > 0 then
                return
            end
        end
    else
        if courierState.hidingInShop then
            courierState.hidingInShop = false
            courierState.hideStartTime = 0
            courierState.manuallyInShop = false
        end
    end
    
    -- Se está se escondendo de visão, verificar se chegou ao destino
    if courierState.hidingFromVision then
        if courierState.destination then
            local distToHiding = (courierPos - courierState.destination):Length()
            
            -- Chegou ao esconderijo
            if distToHiding < 200 then
                courierState.hidingFromVision = false
                courierState.pathCheckpoints = {}
                courierState.currentCheckpoint = 1
                courierState.destination = nil
                printAlert("✅ Escondido com sucesso", "#44ff88")
                return
            end
            
            -- Timeout
            if currentTime - courierState.escapeStartTime > 8 then
                courierState.hidingFromVision = false
                courierState.pathCheckpoints = {}
                courierState.currentCheckpoint = 1
                return
            end
        end
    end
    
    -- Se está em fuga, verificar progresso com waypoints
    if courierState.escaping then
        if #courierState.pathCheckpoints > 0 then
            local currentWaypoint = courierState.pathCheckpoints[courierState.currentCheckpoint]
            if currentWaypoint then
                local distToWaypoint = (courierPos - currentWaypoint):Length()
                
                -- Chegou no waypoint atual
                if distToWaypoint < 200 then
                    courierState.currentCheckpoint = courierState.currentCheckpoint + 1
                    
                    -- Chegou no destino final
                    if courierState.currentCheckpoint > #courierState.pathCheckpoints then
                        courierState.escaping = false
                        courierState.destination = nil
                        courierState.pathCheckpoints = {}
                        courierState.currentCheckpoint = 1
                        printAlert("✅ Chegou em segurança", "#44ff44")
                        return
                    else
                        -- Ir para próximo waypoint
                        local nextWaypoint = courierState.pathCheckpoints[courierState.currentCheckpoint]
                        Player.PrepareUnitOrders(
                            player,
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            nil,
                            nextWaypoint,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            courier
                        )
                        courierState.lastOrderTime = currentTime
                    end
                end
            end
            
            -- Timeout ou re-avaliar ameaças
            if currentTime - courierState.escapeStartTime > 10 then
                courierState.escaping = false
                courierState.pathCheckpoints = {}
                courierState.currentCheckpoint = 1
                printAlert("⚠️ Timeout na fuga, liberando controle", "#ffaa44")
                return
            end
            
            -- Re-avaliar ameaças a cada 2 segundos
            if currentTime - courierState.lastOrderTime > 2 then
                local threatLevel = evaluateThreatLevel(courier, courierPos, courierTeam)
                if threatLevel < 40 then
                    courierState.escaping = false
                    courierState.pathCheckpoints = {}
                    courierState.currentCheckpoint = 1
                    
                    -- Se está vazio e longe da base, voltar
                    if autoReturn:Get() and currentItemCount == 0 then
                        local fountainPos = FOUNTAIN_POSITIONS[courierTeam]
                        local distToFountain = (courierPos - fountainPos):Length()
                        if distToFountain > 2000 then
                            Player.PrepareUnitOrders(
                                player,
                                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                                nil,
                                fountainPos,
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                courier
                            )
                            courierState.lastOrderTime = currentTime
                            printAlert("🏠 Área segura, retornando", "#44ff44")
                            return
                        end
                    end
                    
                    printAlert("✅ Área segura, liberando controle", "#44ff44")
                    return
                end
            end
        end
        return
    end
    
    -- Verificar estado do courier
    local courierStateEnum = Courier.GetCourierState(courier)
    if courierStateEnum == Enum.CourierState.COURIER_STATE_AT_BASE then
        courierState.justDelivered = false
        courierState.deliveryStartPos = nil
        courierState.deliveryTargetPos = nil
        courierState.deliveryProgress = 0
        return
    end
    
    -- Detectar início de entrega e calcular progresso
    if courierStateEnum == Enum.CourierState.COURIER_STATE_DELIVERING_ITEMS then
        -- Iniciar tracking de entrega
        if not courierState.deliveryStartPos then
            courierState.deliveryStartPos = courierPos
            -- Tentar encontrar o herói alvo (assumir que é o herói local)
            if hero then
                courierState.deliveryTargetPos = Entity.GetAbsOrigin(hero)
            end
        end
        
        -- Calcular progresso da entrega (se temos start e target)
        if courierState.deliveryStartPos and courierState.deliveryTargetPos then
            local totalDistance = (courierState.deliveryTargetPos - courierState.deliveryStartPos):Length()
            local traveledDistance = (courierPos - courierState.deliveryStartPos):Length()
            
            if totalDistance > 0 then
                courierState.deliveryProgress = (traveledDistance / totalDistance) * 100
            end
        end
    else
        -- Não está mais em entrega, resetar
        if courierState.deliveryStartPos then
            courierState.deliveryStartPos = nil
            courierState.deliveryTargetPos = nil
            courierState.deliveryProgress = 0
        end
    end
    
    -- Se acabou de entregar itens e está vazio, tentar voltar
    if autoReturn:Get() and courierState.justDelivered and currentItemCount == 0 then
        if currentTime - courierState.deliveryTime > 1 then
            local threatLevel = evaluateThreatLevel(courier, courierPos, courierTeam)
            
            -- Se área está segura, voltar para base
            if threatLevel < 40 then
                local fountainPos = FOUNTAIN_POSITIONS[courierTeam]
                local distToFountain = (courierPos - fountainPos):Length()
                
                -- Só retornar se estiver longe da base
                if distToFountain > 2000 then
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        nil,
                        fountainPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        courier
                    )
                    courierState.lastOrderTime = currentTime
                    printAlert("🏠 Retornando para base", "#4488ff")
                end
                courierState.justDelivered = false
            end
        end
    end
    
    -- Verificar se está sendo visto por inimigos (a cada 2 segundos)
    if stayHidden:Get() and currentTime - courierState.lastVisionCheck >= 2 then
        courierState.lastVisionCheck = currentTime
        local beingSeen, enemy = isBeingSeenByEnemies(courier, courierPos, courierTeam)
        
        -- Se está sendo visto e não está fazendo entrega ativa
        if beingSeen and courierStateEnum ~= Enum.CourierState.COURIER_STATE_DELIVERING_ITEMS then
            if not courierState.hidingFromVision then
                local hidingSpot, hideType = findNearestHidingSpot(courierPos, courierTeam)
                
                if hidingSpot then
                    local waypoints = generateSafeWaypoints(courierPos, hidingSpot, courierTeam)
                    
                    courierState.pathCheckpoints = waypoints
                    courierState.currentCheckpoint = 1
                    courierState.hidingFromVision = true
                    courierState.destination = hidingSpot
                    courierState.escapeStartTime = currentTime
                    courierState.lastOrderTime = currentTime
                    
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        nil,
                        waypoints[1],
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        courier
                    )
                    
                    printAlert(string.format("👁️ Sendo visto! Escondendo em %s", hideType), "#ff8844")
                    return
                end
            end
        else
            -- Não está mais sendo visto ou iniciou entrega
            if courierState.hidingFromVision then
                courierState.hidingFromVision = false
                courierState.pathCheckpoints = {}
                courierState.currentCheckpoint = 1
            end
        end
    end
    
    -- Avaliar nível de ameaça
    local threatLevel, closestEnemy = evaluateThreatLevel(courier, courierPos, courierTeam)
    
    -- HP crítico - voltar para base imediatamente
    if courierHPPercent <= criticalHP:Get() and threatLevel > 0 then
        local escapePos = FOUNTAIN_POSITIONS[courierTeam]
        local waypoints = generateSafeWaypoints(courierPos, escapePos, courierTeam)
        
        courierState.pathCheckpoints = waypoints
        courierState.currentCheckpoint = 1
        courierState.escaping = true
        courierState.destination = escapePos
        courierState.escapeStartTime = currentTime
        courierState.lastOrderTime = currentTime
        
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            waypoints[1],
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            courier
        )
        
        printAlert(string.format("🚨 HP CRÍTICO (%.0f%%)! Voltando para base!", courierHPPercent), "#ff0000")
        return
    end
    
    -- Ameaça crítica ou alta - FUGIR (apenas se não estiver em cooldown)
    if (threatLevel >= 70 or courierState.underAttack) and currentTime - courierState.lastUnstuckTime >= 5 then
        local enemyPos = closestEnemy and Entity.GetAbsOrigin(closestEnemy) or nil
        local escapePos, escapeType = findSafestEscapeRoute(courierPos, enemyPos, courierTeam)
        local waypoints = generateSafeWaypoints(courierPos, escapePos, courierTeam)
        
        courierState.pathCheckpoints = waypoints
        courierState.currentCheckpoint = 1
        courierState.escaping = true
        courierState.destination = escapePos
        courierState.escapeStartTime = currentTime
        courierState.lastOrderTime = currentTime
        courierState.recentlyThreatened = true  -- Marcar para monitoramento contínuo
        
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            waypoints[1],
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            courier
        )
        
        local threatText = threatLevel >= 100 and "CRÍTICO" or "ALTO"
        printAlert(string.format("⚠️ Perigo %s! Fugindo via %s", threatText, escapeType), "#ff8800")
        return
    end
    
    -- Monitoramento contínuo após ameaça (não deixar courier parar se inimigo ainda está perto)
    if not courierState.escaping and closestEnemy then
        local enemyPos = Entity.GetAbsOrigin(closestEnemy)
        local distToEnemy = (courierPos - enemyPos):Length()
        
        -- Se inimigo está próximo (mesmo com threatLevel baixo), continuar fugindo
        if distToEnemy < 1200 and currentTime - courierState.lastOrderTime > 1 then
            local escapePos, escapeType = findSafestEscapeRoute(courierPos, enemyPos, courierTeam)
            local waypoints = generateSafeWaypoints(courierPos, escapePos, courierTeam)
            
            courierState.pathCheckpoints = waypoints
            courierState.currentCheckpoint = 1
            courierState.escaping = true
            courierState.destination = escapePos
            courierState.escapeStartTime = currentTime
            courierState.lastOrderTime = currentTime
            
            Player.PrepareUnitOrders(
                player,
                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                nil,
                waypoints[1],
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                courier
            )
            
            printAlert("⚠️ Inimigo próximo! Continuando fuga", "#ffaa44")
            return
        end
    end
    
    -- Ameaça média - manter distância (tratar como fuga ativa)
    if threatLevel >= 50 and threatLevel < 70 and closestEnemy and currentTime - courierState.lastUnstuckTime >= 5 then
        local enemyPos = Entity.GetAbsOrigin(closestEnemy)
        local distToEnemy = (courierPos - enemyPos):Length()
        
        -- Se inimigo está muito perto, fugir ativamente
        if distToEnemy < 800 then
            local directionAway = (courierPos - enemyPos):Normalized()
            local keepDistancePos = courierPos + directionAway * 1000
            
            -- Iniciar fuga se não estiver fugindo ou se passou tempo suficiente
            if not courierState.escaping or currentTime - courierState.lastOrderTime > 0.5 then
                local escapePos, escapeType = findSafestEscapeRoute(courierPos, enemyPos, courierTeam)
                local waypoints = generateSafeWaypoints(courierPos, escapePos, courierTeam)
                
                courierState.pathCheckpoints = waypoints
                courierState.currentCheckpoint = 1
                courierState.escaping = true
                courierState.destination = escapePos
                courierState.escapeStartTime = currentTime
                courierState.lastOrderTime = currentTime
                
                Player.PrepareUnitOrders(
                    player,
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    waypoints[1],
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    courier
                )
                
                printAlert("⚠️ Inimigo se aproximando! Continuando fuga", "#ffaa44")
            end
        end
    end
end

function OnPrepareUnitOrders(order)
    if not manualOverride:Get() then return true end
    
    local courier = Couriers.GetLocal()
    
    if not courier or not order.npc or not Entity.IsEntity(order.npc) then
        return true
    end
    
    -- PREVENIR VOLTA DO COURIER SE JÁ PERCORREU 40% DO CAMINHO
    if preventReturn:Get() and Entity.GetIndex(order.npc) == Entity.GetIndex(courier) then
        local courierStateEnum = Courier.GetCourierState(courier)
        
        -- Se courier está em entrega e já percorreu 40% do caminho
        if courierStateEnum == Enum.CourierState.COURIER_STATE_DELIVERING_ITEMS then
            if courierState.deliveryProgress >= 40 then
                -- Verificar se é ordem de retorno (voltar pra base)
                if order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then
                    local targetPos = order.position
                    if targetPos then
                        local courierTeam = Entity.GetTeamNum(courier)
                        local fountainPos = FOUNTAIN_POSITIONS[courierTeam]
                        local distToFountain = (targetPos - fountainPos):Length()
                        
                        -- Se está tentando voltar para fountain, BLOQUEAR
                        if distToFountain < 500 then
                            printAlert(string.format("🚫 Volta bloqueada! Progresso: %.0f%%", courierState.deliveryProgress), "#ff8844")
                            return false  -- BLOQUEIA a ordem
                        end
                    end
                end
            end
        end
    end
    
    -- Se jogador deu ordem manual ao courier, cancelar fuga automática
    if Entity.GetIndex(order.npc) == Entity.GetIndex(courier) then
        if order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION or 
           order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET then
            
            -- Só processar se não estava em controle manual
            local wasManual = courierState.manualControl
            
            -- Verificar se está movendo para loja secreta
            local targetPos = order.position
            if targetPos then
                for _, shopPos in ipairs(SECRET_SHOPS) do
                    if (targetPos - shopPos):Length() < 400 then
                        courierState.manuallyInShop = true
                    end
                end
            end
            
            courierState.escaping = false
            courierState.destination = nil
            courierState.pathCheckpoints = {}
            courierState.currentCheckpoint = 1
            courierState.manualControl = true
            courierState.lastManualTime = GlobalVars.GetCurTime()
            courierState.stuckCounter = 0
            
            -- Só resetar hidingInShop se não estiver indo para loja
            if not courierState.manuallyInShop then
                courierState.hidingInShop = false
            end
            
            -- Só mostrar alerta se não estava em controle manual
            if not wasManual then
                printAlert("✋ Controle manual ativado", "#4488ff")
            end
        end
    end
    
    return true
end

function OnGameEnd()
    resetCourierState()
end

return {
    OnUpdate = OnUpdate,
    OnPrepareUnitOrders = OnPrepareUnitOrders,
    OnGameEnd = OnGameEnd
}
