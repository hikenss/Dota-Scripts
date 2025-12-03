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
local searchRadius = optionsMain:Slider("Raio máximo de busca", 1000, 8000, 4500, function(v)
    return string.format("%.0f", v)
end)
local avoidAllies = optionsMain:Switch("Evitar acampamentos com aliados próximos", true)
local allyRadius = optionsMain:Slider("Raio para detectar aliados", 300, 2000, 800, function(v)
    return string.format("%.0f", v)
end)

local toggleState = false
local lastKeyState = false
local queuedOnce = false
local visitedCamps = {}

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

local function findNearestCamps(origin, count, blacklist)
    local campData = getAllCamps()
    if (#campData == 0) then
        return {}
    end

    local maxRadius = searchRadius:Get()

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
        if distance > maxRadius then
            break
        end

        local alreadyVisited = false
        if blacklist then
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

local function issueCommands()
    local player = Players.GetLocal()
    local selectedUnits = Player.GetSelectedUnits(player) or {}
    if (#selectedUnits == 0) then
        print("[AutoFarmer] Nenhuma unidade selecionada.")
        return false
    end

    visitedCamps = {}
    local groupSize = unitsPerCamp:Get()
    local groupedUnits = {}

    for i = 1, #selectedUnits, groupSize do
        local group = {}
        for j = i, math.min((i + groupSize) - 1, #selectedUnits) do
            table.insert(group, selectedUnits[j])
        end
        table.insert(groupedUnits, group)
    end

    for _, group in ipairs(groupedUnits) do
        local groupOrigin = Entity.GetAbsOrigin(group[1])
        local queued = queueGroupToCamps(group, groupOrigin, queuedCamps:Get(), visitedCamps)
        for _, idx in ipairs(queued) do
            table.insert(visitedCamps, idx)
        end
    end

    queuedOnce = true
    print("[AutoFarmer] Ordens adicionadas à fila; script desativado.")
    return true
end

function OnUpdate()
    local keyPressed = toggleKey:IsPressed()
    if keyPressed and not lastKeyState then
        toggleState = not toggleState
        print("[AutoFarmer] Bot alternado:", toggleState)
        if toggleState then
            queuedOnce = false
        end
    end

    lastKeyState = keyPressed

    if not toggleState then
        return
    end

    if queuedOnce then
        toggleState = false
        return
    end

    if issueCommands() then
        toggleState = false
    else
        print("[AutoFarmer] Não foi possível adicionar ordens; desativando bot.")
        toggleState = false
    end
end

return { OnUpdate = OnUpdate }
