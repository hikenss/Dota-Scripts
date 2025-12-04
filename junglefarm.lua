-- ============================================================================
-- Auto Farmer for Jungle Camps
-- Automatically sends selected units to farm jungle camps in sequence
-- ============================================================================

-- UI Setup
local menu = Menu.Create("Scripts", "User Scripts", "AutoFarmer")
local options = menu:Create("Options"):Create("Main")
local toggleKey = options:Bind("Активировать Авто-фармер леса", Enum.ButtonCode.KEY_0, "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c")
local unitsPerCamp = options:Slider("Юнитов на 1 кемп", 1, 5, 1)
local campsInQueue = options:Slider("Кемпов в очередь", 1, 10, 3)

-- State Variables
local botEnabled = false
local lastKeyState = false
local commandsQueued = false
local visitedCamps = {}

-- ============================================================================
-- Get Center Position of a Camp
-- ============================================================================
local function GetCampCenter(camp)
    if not camp then 
        return nil
    end
    
    local box = Camp.GetCampBox(camp)
    if not box or not box.min or not box.max then 
        return nil
    end
    
    local centerX = (box.min:GetX() + box.max:GetX()) / 2
    local centerY = (box.min:GetY() + box.max:GetY()) / 2
    local centerZ = (box.min:GetZ() + box.max:GetZ()) / 2
    
    return Vector(centerX, centerY, centerZ)
end

-- ============================================================================
-- Get All Camps with Centers
-- ============================================================================
local function GetAllCampsWithCenters()
    local allCamps = Camps.GetAll()
    if not allCamps or #allCamps == 0 then 
        return {}
    end
    
    local campsData = {}
    for index, camp in ipairs(allCamps) do
        local center = GetCampCenter(camp)
        if center then
            table.insert(campsData, {
                camp = camp,
                center = center,
                index = index
            })
        end
    end
    
    return campsData
end

-- ============================================================================
-- Find Nearest Camps to Position
-- ============================================================================
local function FindNearestCamps(position, count, excludedIndices)
    local allCamps = GetAllCampsWithCenters()
    if #allCamps == 0 then 
        return {}
    end
    
    -- Sort by distance
    table.sort(allCamps, function(a, b)
        local distA = (a.center - position):Length2D()
        local distB = (b.center - position):Length2D()
        return distA < distB
    end)
    
    -- Select nearest camps that aren't excluded
    local selected = {}
    for _, campData in ipairs(allCamps) do
        if #selected >= count then 
            break
        end
        
        local isExcluded = false
        if excludedIndices then
            for _, excludedIndex in ipairs(excludedIndices) do
                if campData.index == excludedIndex then
                    isExcluded = true
                    break
                end
            end
        end
        
        if not isExcluded then
            table.insert(selected, campData)
        end
    end
    
    return selected
end

-- ============================================================================
-- Queue Camp Orders for Unit Group
-- ============================================================================
local function QueueCampOrders(units, startPosition, maxCamps, excludedCamps)
    local player = Players.GetLocal()
    local campSequence = {}
    local numCamps = math.min(campsInQueue:Get(), maxCamps or 3)
    local currentPos = startPosition
    
    -- Find sequence of nearest camps
    for i = 1, numCamps do
        local nearest = FindNearestCamps(currentPos, 1, excludedCamps)
        if #nearest == 0 then 
            break
        end
        
        local campData = nearest[1]
        table.insert(excludedCamps, campData.index)
        table.insert(campSequence, {
            campIndex = campData.index,
            campCenter = campData.center
        })
        currentPos = campData.center
        
        print(string.format("[AutoFarmer] Засечен кемп #%d (%.0f, %.0f)", 
            campData.index, 
            campData.center:GetX(), 
            campData.center:GetY()))
    end
    
    -- Reverse order for queue (last camp first in queue)
    local reversed = {}
    for i = #campSequence, 1, -1 do
        table.insert(reversed, campSequence[i])
    end
    
    -- Issue attack-move orders
    for _, camp in ipairs(reversed) do
        Player.PrepareUnitOrders(
            player,
            Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
            nil,
            camp.campCenter,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS,
            units,
            true,  -- queue
            false,
            false,
            true,
            nil,
            true
        )
        
        print(string.format("[AutoFarmer] Группа юнитов отправлена на кемп #%d (%.0f, %.0f)", 
            camp.campIndex, 
            camp.campCenter:GetX(), 
            camp.campCenter:GetY()))
    end
    
    -- Return camp indices that were queued
    local queuedIndices = {}
    for _, camp in ipairs(campSequence) do
        table.insert(queuedIndices, camp.campIndex)
    end
    
    return queuedIndices
end

-- ============================================================================
-- Execute Farming Orders
-- ============================================================================
local function ExecuteFarmingOrders()
    local player = Players.GetLocal()
    local selectedUnits = Player.GetSelectedUnits(player) or {}
    
    if #selectedUnits == 0 then
        print("[AutoFarmer] Нет выбранных юнитов.")
        return false
    end
    
    visitedCamps = {}
    local unitsPerGroup = unitsPerCamp:Get()
    local groups = {}
    
    -- Split selected units into groups
    for i = 1, #selectedUnits, unitsPerGroup do
        local group = {}
        for j = i, math.min(i + unitsPerGroup - 1, #selectedUnits) do
            table.insert(group, selectedUnits[j])
        end
        table.insert(groups, group)
    end
    
    -- Queue orders for each group
    for _, group in ipairs(groups) do
        local startPos = Entity.GetAbsOrigin(group[1])
        local queuedCamps = QueueCampOrders(group, startPos, campsInQueue:Get(), visitedCamps)
        
        for _, campIndex in ipairs(queuedCamps) do
            table.insert(visitedCamps, campIndex)
        end
    end
    
    commandsQueued = true
    print("[AutoFarmer] Команды поставлены в очередь, скрипт деактивирован.")
    return true
end

-- ============================================================================
-- Main Update Loop
-- ============================================================================
function OnUpdate()
    local player = Players.GetLocal()
    local keyPressed = toggleKey:IsPressed()
    
    -- Toggle bot on key press
    if keyPressed and not lastKeyState then
        botEnabled = not botEnabled
        print("[AutoFarmer] Bot toggled:", botEnabled)
        
        if botEnabled then
            commandsQueued = false
        end
    end
    
    lastKeyState = keyPressed
    
    if not botEnabled then 
        return
    end
    
    if commandsQueued then
        botEnabled = false
        return
    end
    
    if ExecuteFarmingOrders() then
        botEnabled = false
    else
        print("[AutoFarmer] Не удалось поставить команды в очередь, выключаем бот.")
        botEnabled = false
    end
end

return {
    OnUpdate = OnUpdate
}