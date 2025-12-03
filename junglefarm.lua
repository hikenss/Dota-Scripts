local menuRoot = Menu.Create("Scripts", "User Scripts", "AutoFarmer")
local optionsRoot = menuRoot:Create("Options")
local optionsMain = optionsRoot:Create("Main")

local toggleKey = optionsMain:Bind(
    "Ativar Fazendeiro de Selva",
    Enum.ButtonCode.KEY_0,
    "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c"
)
local unitsPerCamp = optionsMain:Slider("Unidades por acampamento", 1, 5, 1)
local queuedCamps = optionsMain:Slider("Acampamentos na fila", 1, 10, 3)
local searchRadius = optionsMain:Slider("Raio máximo de busca", 1000, 20000, 12000, function(v)
    return string.format("%.0f", v)
end)
local avoidAllies = optionsMain:Switch("Evitar acampamentos com aliados próximos", true)
local allyRadius = optionsMain:Slider("Raio para detectar aliados", 300, 2000, 800, function(v)
    return string.format("%.0f", v)
end)
local autoHeal = optionsMain:Switch("Voltar para curar se estiver morrendo", true)
local healPercent = optionsMain:Slider("HP% para curar", 5, 80, 30, function(v)
    return string.format("%d%%", v)
end)
local enemyAlert = optionsMain:Switch("Fugir se houver inimigo por perto", true)
local enemyRadius = optionsMain:Slider("Raio para detectar inimigos", 600, 2000, 1200, function(v)
    return string.format("%.0f", v)
end)

local toggleState = false
local lastKeyState = false
local visitedCamps = {}
local activeGroups = {}
local retreatingUnits = {}
local groupDanger = {}

local fountainPositions = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7019, -6534, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(6846, 6251, 384)
}

local function getPlayerTeam()
    local player = Players.GetLocal()
    if not player then
        return nil
    end

    local slot = Player.GetPlayerSlot(player)
    return ((slot < 5) and Enum.TeamNum.TEAM_RADIANT) or Enum.TeamNum.TEAM_DIRE
end

local function getCampCenter(camp)
    if not camp then
        return nil
    end

    local campBox = Camp.GetCampBox(camp)
    if not campBox or not campBox.min or not campBox.max then
        return nil
    end

    local cx = (campBox.min:GetX() + campBox.max:GetX()) / 2
    local cy = (campBox.min:GetY() + campBox.max:GetY()) / 2
    local cz = (campBox.min:GetZ() + campBox.max:GetZ()) / 2

    return Vector(cx, cy, cz)
end

local function getAllCamps()
    local camps = Camps.GetAll()
    if not camps or (#camps == 0) then
        return {}
    end

    local data = {}
    for index, camp in ipairs(camps) do
        local center = getCampCenter(camp)
        if center then
            table.insert(data, { camp = camp, center = center, index = index })
        end
    end

    return data
end

local function isAllyNearby(position)
    if not avoidAllies:Get() then
        return false
    end

    local player = Players.GetLocal()
    if not player then
        return false
    end

    local slot = Player.GetPlayerSlot(player)
    local team = ((slot < 5) and Enum.TeamNum.TEAM_RADIANT) or Enum.TeamNum.TEAM_DIRE
    local allies = Heroes.InRadius(position, allyRadius:Get(), team, Enum.TeamType.TEAM_FRIEND) or {}

    for _, ally in ipairs(allies) do
        if Entity.IsAlive(ally) and ally ~= Heroes.GetLocal() then
            return true
        end
    end

    return false
end

local function findNearestCamps(origin, count, blacklist, maxRadius, allowReuse)
    local campData = getAllCamps()
    if (#campData == 0) then
        return {}
    end

    local radius = maxRadius or searchRadius:Get()

    table.sort(campData, function(a, b)
        local distA = (a.center - origin):Length2D()
        local distB = (b.center - origin):Length2D()
        return distA < distB
    end)

    local selected = {}
    for _, campInfo in ipairs(campData) do
        if (#selected >= count) then
            break
        end

        local distance = (campInfo.center - origin):Length2D()
        if radius and distance > radius then
            break
        end

        local alreadyVisited = false
        if blacklist and (not allowReuse) then
            for _, idx in ipairs(blacklist) do
                if campInfo.index == idx then
                    alreadyVisited = true
                    break
                end
            end
        end

        if not alreadyVisited then
            if isAllyNearby(campInfo.center) then
                print(string.format(
                    "[AutoFarmer] Ignorando acampamento #%d: aliado próximo.",
                    campInfo.index
                ))
            else
                table.insert(selected, campInfo)
            end
        end
    end

    return selected
end

local function queueGroupToCamps(units, startPos, maxCamps, blacklist)
    local player = Players.GetLocal()
    local selection = {}
    local remaining = math.min(queuedCamps:Get(), maxCamps or 3)
    local currentOrigin = startPos

    for _ = 1, remaining do
        local nearest = findNearestCamps(currentOrigin, 1, blacklist)
        if (#nearest == 0) then
            break
        end

        local camp = nearest[1]
        table.insert(blacklist, camp.index)
        table.insert(selection, { campIndex = camp.index, campCenter = camp.center })
        currentOrigin = camp.center

        print(string.format(
            "[AutoFarmer] Acampamento detectado #%d (%.0f, %.0f)",
            camp.index,
            camp.center:GetX(),
            camp.center:GetY()
        ))
    end

    local orderList = {}
    for i = #selection, 1, -1 do
        table.insert(orderList, selection[i])
    end

    for _, campOrder in ipairs(orderList) do
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
            nil,
            campOrder.campCenter,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,
            units,
            true,
            false,
            false,
            true,
            nil,
            true
        )

        print(string.format(
            "[AutoFarmer] Grupo enviado para o acampamento #%d (%.0f, %.0f)",
            campOrder.campIndex,
            campOrder.campCenter:GetX(),
            campOrder.campCenter:GetY()
        ))
    end

    local indexes = {}
    for _, campOrder in ipairs(selection) do
        table.insert(indexes, campOrder.campIndex)
    end

    return indexes
end

local function sendUnitsToFountain(units)
    local team = getPlayerTeam()
    local fountain = team and fountainPositions[team]
    if not fountain then
        return
    end

    local player = Players.GetLocal()
    if not player then
        return
    end
    for _, unit in ipairs(units) do
        if Entity.IsAlive(unit) then
            Player.HoldPosition(player, unit)
            NPC.MoveTo(unit, fountain)
        end
    end
end

local function checkRetreatState(unit)
    if not Entity.IsAlive(unit) then
        retreatingUnits[Entity.GetIndex(unit)] = nil
        return false
    end

    local currentHP = Entity.GetHealth(unit)
    local maxHP = Entity.GetMaxHealth(unit)
    if not maxHP or maxHP == 0 then
        return false
    end

    local hpPct = currentHP / maxHP
    local retreatThreshold = healPercent:Get() / 100
    local returnThreshold = math.min(0.95, retreatThreshold + 0.1)
    local idx = Entity.GetIndex(unit)

    if autoHeal:Get() and hpPct < retreatThreshold then
        retreatingUnits[idx] = true
        return true
    end

    if retreatingUnits[idx] then
        if hpPct >= returnThreshold then
            retreatingUnits[idx] = nil
            return false
        end
        return true
    end

    return false
end

local function enemyNearby(unit)
    if not enemyAlert:Get() then
        return false
    end

    local team = getPlayerTeam()
    if not team then
        return false
    end

    local origin = Entity.GetAbsOrigin(unit)
    local enemies = Heroes.InRadius(origin, enemyRadius:Get(), team, Enum.TeamType.TEAM_ENEMY) or {}
    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) then
            return true
        end
    end

    return false
end

local function groupIsBusy(units)
    for _, unit in ipairs(units) do
        if Entity.IsAlive(unit) then
            if NPC.IsAttacking(unit) or NPC.IsAttackingNPC(unit) or NPC.IsAttackingPlayer(unit) then
                return true
            end
            if NPC.IsRunning(unit) or Entity.IsMoving(unit) then
                return true
            end
            if NPC.IsChannelingAbility(unit) then
                return true
            end
        end
    end

    return false
end

local function campHasNeutrals(campCenter)
    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) and Entity.GetTeamNum(npc) == Enum.TeamNum.TEAM_NEUTRAL then
            local distance = (Entity.GetAbsOrigin(npc) - campCenter):Length2D()
            if distance <= 800 then
                return true
            end
        end
    end

    return false
end

local function assignCamp(group)
    local firstUnit = group.units[1]
    if not firstUnit or not Entity.IsAlive(firstUnit) then
        return false
    end

    local origin = Entity.GetAbsOrigin(firstUnit)
    local campList = findNearestCamps(origin, 1, group.blacklist)

    if (#campList == 0) then
        campList = findNearestCamps(origin, 1, {}, nil, true)
    end

    if (#campList == 0) then
        campList = findNearestCamps(Vector(0, 0, 0), 1, {}, nil, true)
    end

    if (#campList == 0) then
        return false
    end

    local camp = campList[1]
    table.insert(group.blacklist, camp.index)

    while (#group.blacklist > 16) do
        table.remove(group.blacklist, 1)
    end

    group.currentCamp = camp
    group.lastCampOrderTime = GameRules.GetGameTime()
    Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
        nil,
        camp.center,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,
        group.units,
        true,
        false,
        false,
        true,
        nil,
        true
    )

    print(string.format(
        "[AutoFarmer] Grupo enviando para o acampamento #%d (%.0f, %.0f)",
        camp.index,
        camp.center:GetX(),
        camp.center:GetY()
    ))

    return true
end

local function updateGroup(group)
    local aliveUnits = {}
    for _, unit in ipairs(group.units) do
        if Entity.IsAlive(unit) then
            table.insert(aliveUnits, unit)
        end
    end

    group.units = aliveUnits
    if (#group.units == 0) then
        return
    end

    if enemyAlert:Get() then
        for _, unit in ipairs(group.units) do
            if enemyNearby(unit) then
                groupDanger[group] = GameRules.GetGameTime() + 4
                sendUnitsToFountain(group.units)
                print("[AutoFarmer] Grupo recuando: inimigo detectado.")
                return
            end
        end
    end

    if groupDanger[group] and GameRules.GetGameTime() < groupDanger[group] then
        sendUnitsToFountain(group.units)
        return
    end

    groupDanger[group] = nil

    local anyRetreating = false
    for _, unit in ipairs(group.units) do
        if checkRetreatState(unit) then
            anyRetreating = true
            sendUnitsToFountain({ unit })
        end
    end

    if anyRetreating then
        return
    end

    if group.currentCamp then
        local distance = (Entity.GetAbsOrigin(group.units[1]) - group.currentCamp.center):Length2D()
        local busy = groupIsBusy(group.units)

        if (distance < 500 and not campHasNeutrals(group.currentCamp.center)) or (not busy and distance < 200) then
            group.currentCamp = nil
        elseif busy then
            return
        end
    end

    if group.currentCamp and group.lastCampOrderTime then
        local elapsed = GameRules.GetGameTime() - group.lastCampOrderTime
        if elapsed > 10 then
            group.currentCamp = nil
        end
    end

    if not group.currentCamp then
        assignCamp(group)
    end
end

local function startFarming()
    local player = Players.GetLocal()
    local selectedUnits = Player.GetSelectedUnits(player) or {}
    if (#selectedUnits == 0) then
        print("[AutoFarmer] Nenhuma unidade selecionada.")
        return false
    end

    visitedCamps = {}
    activeGroups = {}
    local groupSize = unitsPerCamp:Get()

    for i = 1, #selectedUnits, groupSize do
        local group = { units = {}, blacklist = {} }
        for j = i, math.min((i + groupSize) - 1, #selectedUnits) do
            table.insert(group.units, selectedUnits[j])
        end

        table.insert(activeGroups, group)
        assignCamp(group)
    end

    return true
end

function OnUpdate()
    local keyPressed = toggleKey:IsPressed()
    if keyPressed and not lastKeyState then
        toggleState = not toggleState
        print("[AutoFarmer] Bot alternado:", toggleState)

        if toggleState then
            startFarming()
        else
            activeGroups = {}
            retreatingUnits = {}
            groupDanger = {}
        end
    end

    lastKeyState = keyPressed

    if not toggleState then
        return
    end

    for _, group in ipairs(activeGroups) do
        updateGroup(group)
    end
end

return { OnUpdate = OnUpdate }
