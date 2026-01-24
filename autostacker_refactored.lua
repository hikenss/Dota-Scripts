--[[
    AutoStacker - Refactored Version
    Automatic neutral camp stacker for Dota 2
    
    Main features:
    - Automatic camp stacking at designated times
    - Attack and pull point configuration for each camp
    - Visualization of points and movement trajectories
    - Settings saved for each camp
    - Interactive GUI management
]]

-- ============================================================================
-- CONSTANTS AND CONFIGURATION
-- ============================================================================

local CONFIG = {
    PRESET_KEY = "autostacker_presets",
    DEFAULT_ATTACK_SECOND = 53,
    DEFAULT_WAIT_UNTIL_SECOND = 15,
    DEFAULT_ATTACK_TIME = 0.6,
    DEFAULT_OFFSET_DISTANCE = 250,
    SPAM_PREVENTION_DELAY = 0.6,
    OVERLAY_WIDTH = 260,
    OVERLAY_BASE_HEIGHT = 96,
    BUTTON_WIDTH = 24,
    BUTTON_HEIGHT = 18,
}

-- Default wait/pull spots per camp (from Auto Stacker By GLTM.md)
local CAMP_POINTS = {
    [1]={wait={x=-742, y=4325, z=134}, pull={x=-682, y=3881, z=236}},
    [2]={wait={x=2943, y=-796, z=256}, pull={x=2817, y=-53, z=256}},
    [3]={wait={x=4082, y=-5526, z=128}, pull={x=4181, y=-6368, z=128}},
    [4]={wait={x=8255, y=-734, z=256}, pull={x=8204, y=-1369, z=256}},
    [5]={wait={x=-4806, y=4534, z=128}, pull={x=-4884, y=5071, z=128}},
    [6]={wait={x=4284, y=-4110, z=128}, pull={x=3622, y=-4505, z=128}},
    [7]={wait={x=-2121, y=-3921, z=128}, pull={x=-1564, y=-4531, z=128}},
    [8]={wait={x=262, y=-4751, z=136}, pull={x=333, y=-4101, z=254}},
    [9]={wait={x=-4509, y=361, z=256}, pull={x=-5031, y=1121, z=128}},
    [10]={wait={x=4072, y=-421, z=256}, pull={x=4276, y=-1359, z=128}},
    [11]={wait={x=-1274, y=-4908, z=128}, pull={x=-812, y=-5282, z=128}},
    [12]={wait={x=1515, y=8209, z=128}, pull={x=792, y=8152, z=128}},
    [13]={wait={x=455, y=3965, z=134}, pull={x=-78, y=3932, z=136}},
    [14]={wait={x=-4144, y=322, z=256}, pull={x=-5031, y=1121, z=128}},
    [15]={wait={x=316, y=-8138, z=134}, pull={x=954, y=-8538, z=136}},
    [16]={wait={x=-2529, y=-7737, z=134}, pull={x=-2690, y=-7154, z=134}},
    [17]={wait={x=-479, y=7639, z=134}, pull={x=-551, y=6961, z=128}},
    [18]={wait={x=-4743, y=7534, z=0}, pull={x=-4832, y=7136, z=0}},
    [19]={wait={x=1348, y=3263, z=128}, pull={x=1683, y=3710, z=128}},
    [20]={wait={x=7969, y=1047, z=256}, pull={x=7681, y=695, z=256}},
    [21]={wait={x=-7735, y=-183, z=256}, pull={x=-7436, y=685, z=256}},
    [22]={wait={x=-3962, y=7564, z=0}, pull={x=-4521, y=7474, z=8}},
    [23]={wait={x=-2589, y=4502, z=256}, pull={x=-2651, y=5138, z=256}},
    [24]={wait={x=3522, y=-8186, z=8}, pull={x=4028, y=-7376, z=0}},
    [25]={wait={x=1501, y=-4208, z=256}, pull={x=1094, y=-5103, z=136}},
    [26]={wait={x=-4338, y=4903, z=128}, pull={x=-5198, y=4877, z=128}},
    [27]={wait={x=-7757, y=-1219, z=256}, pull={x=-7693, y=-727, z=256}},
    [28]={wait={x=4781, y=-7812, z=8}, pull={x=4510, y=-7260, z=82}},
}

local COLORS = {
    ATTACK_POINT = {0, 200, 255, 220},
    ATTACK_POINT_OUTLINE = {0, 120, 255, 255},
    PULL_POINT = {255, 200, 0, 220},
    PULL_POINT_OUTLINE = {255, 140, 0, 255},
    CAMP_BOX = {0, 255, 0, 220},
    CAMP_BOX_FILL = {0, 255, 0, 50},
    TRAJECTORY = {255, 255, 255, 140},
    UNIT_LINE = {0, 220, 255, 200},
    OVERLAY_BG = {15, 15, 18}, -- Darker and modern
    OVERLAY_BORDER = {60, 60, 70}, -- Thin border
    OVERLAY_HEADER = {25, 25, 35}, -- Header
    BUTTON_BG = {45, 45, 55, 230}, -- Softer buttons
    TEXT = {220, 220, 230, 255}, -- Softer white
    TEXT_SECONDARY = {180, 180, 190, 200}, -- Secondary text
    STATUS_SUCCESS = {50, 200, 50}, -- Green for ready
    STATUS_WARNING = {255, 180, 50}, -- Orange for warning
}

-- ============================================================================
-- GLOBAL VARIABLES
-- ============================================================================

local state = {
    enabled = true,
    initialized = false,
    selectedCamp = nil,
    attackPoint = nil,
    pullPoint = nil,
    dragging = false,
    dragTarget = nil,
    dragCamp = nil,
    dragPresetKey = nil,
    lastSave = 0,
    lastNoUnitsLog = 0,
    recordKeyPressed = false,
    disableKeyPressed = false,
}

local units = {
    tracked = {},
    states = {},
    lastDesiredPos = {},
    spamPrevention = {},
    campAssignments = {},
    attackTimes = {},
    lastAttackMinute = {},
}

local presets = {}

-- ============================================================================
-- MENU AND INTERFACE
-- ============================================================================

local mainMenu = Menu.Create("Scripts", "User Scripts")
local mainTab = mainMenu:Create("AutoStacker")
local mainSection = mainTab:Create("Main")

-- ============================================================================
-- BLOCK: CONTROL (LEFT)
-- ============================================================================
local controlBlock = mainSection:Create("Control")

local menuItems = {
    enableCamp = controlBlock:Bind("Setup & Enable camp", Enum.ButtonCode.KEY_1),
    disableCamp = controlBlock:Bind("Disable camp", Enum.ButtonCode.KEY_2),
    resetPoints = controlBlock:Bind("Reset points", Enum.ButtonCode.KEY_DELETE),
}

-- Add callbacks to update instructions when hotkeys change
menuItems.enableCamp:SetCallback(function()
    if Utils and Utils.updateInstructionLabels then
        Utils.updateInstructionLabels()
    end
end)

menuItems.disableCamp:SetCallback(function()
    if Utils and Utils.updateInstructionLabels then
        Utils.updateInstructionLabels()
    end
end)

menuItems.resetPoints:SetCallback(function()
    if Utils and Utils.updateInstructionLabels then
        Utils.updateInstructionLabels()
    end
end)

local resetAllButton = controlBlock:Button("Reset All Settings", function()
    print("[AutoStacker] Resetting all settings...")
    -- Clear all presets
    presets = {}
    state.attackPoint = nil
    state.pullPoint = nil
    state.selectedCamp = nil
    units.campAssignments = {}
    print("[AutoStacker] All settings have been reset!")
end, false, 1.0)

local reloadButton = controlBlock:Button("Reload Presets", function()
    print("[AutoStacker] Reloading presets...")
    if PresetManager and PresetManager.loadFromConfig then
        pcall(PresetManager.loadFromConfig)
    end
    print("[AutoStacker] Presets reloaded!")
end, false, 1.0)

local scanCreepsButton = controlBlock:Button("Scan All Creeps", function()
    print("[AutoStacker] Scanning all creeps...")
    Utils.scanAndAssignAllCreeps()
end, false, 1.0)



-- ============================================================================
-- BLOCK: VISUALIZATION (RIGHT)
-- ============================================================================
local visualBlock = mainSection:Create("Visuals")

local visualSettings = {
    showCampBox = visualBlock:Switch("Show camp box", true),
    overlayFontSize = visualBlock:Slider("Overlay font size", 10, 24, 12),
    overlayOpacity = visualBlock:Slider("Overlay opacity", 0, 255, 120),
}

local conditionalVisuals = {
    conditionalVisuals = visualBlock:Switch("Show visuals only when key held", false),
    visualsHotkey = visualBlock:Bind("Visuals hotkey", Enum.ButtonCode.KEY_LALT),
}

-- ============================================================================
-- BLOCK: STACKING SETTINGS (LEFT, SECOND ROW)
-- ============================================================================
local stackingBlock = mainSection:Create("Stacking")

local campSettings = {
    attackSecond = stackingBlock:Slider("Attack second", 0, 59, CONFIG.DEFAULT_ATTACK_SECOND),
    waitUntilSecond = stackingBlock:Slider("Wait until sec", 0, 59, CONFIG.DEFAULT_WAIT_UNTIL_SECOND),
    attackTime = stackingBlock:Slider("Attack time", 0, 2, CONFIG.DEFAULT_ATTACK_TIME),
}

-- ============================================================================
-- БЛОК: ИНФОРМАЦИЯ И СТАТИСТИКА (ПРАВЫЙ, ВТОРОЙ РЯД)
-- ============================================================================
local infoBlock = mainSection:Create("Info & Stats")
-- Инструкции (будут обновляться динамически с актуальными хоткеями)
local instructionLabels = {
    step1 = infoBlock:Label("1. Select your creeps"),
    step2 = infoBlock:Label("2. Press [1] near camp to setup & enable it"),
    step3 = infoBlock:Label("3. Press [2] near camp to disable it"),
    step4 = infoBlock:Label("4. Drag points with Ctrl+Click to adjust"),
}

-- Add labels to display statistics (will be updated dynamically)
local statsLabels = {
    trackedUnits = infoBlock:Label("Tracked units: 0"),
    activeCamps = infoBlock:Label("Active camps: 0"),
    savedPresets = infoBlock:Label("Saved presets: 0"),
}

local debugSettings = {
    verboseLogging = infoBlock:Switch("Verbose logging", false),
    showDebugInfo = infoBlock:Switch("Show debug overlay", false),
    showPointsDebug = infoBlock:Switch("Show points debug", false),
}

-- Initialize menu element visibility
conditionalVisuals.visualsHotkey:Visible(conditionalVisuals.conditionalVisuals:Get())

-- Initialize instructions with actual hotkeys (will be updated after Utils is created)
local needUpdateInstructions = true

-- ============================================================================
-- UTILITIES
-- ============================================================================

local Utils = {}

function Utils.getGameTime()
    local gameTime = GameRules.GetGameTime() - GameRules.GetGameStartTime()
    return gameTime < 0 and 0 or gameTime
end

function Utils.getKeyName(buttonCode)
    -- Simple function to get readable key name
    local keyNames = {
        [Enum.ButtonCode.KEY_1] = "1",
        [Enum.ButtonCode.KEY_2] = "2",
        [Enum.ButtonCode.KEY_3] = "3",
        [Enum.ButtonCode.KEY_4] = "4",
        [Enum.ButtonCode.KEY_5] = "5",
        [Enum.ButtonCode.KEY_INSERT] = "Insert",
        [Enum.ButtonCode.KEY_DELETE] = "Delete",
        [Enum.ButtonCode.KEY_F7] = "F7",
        [Enum.ButtonCode.KEY_F8] = "F8",
        [Enum.ButtonCode.KEY_LALT] = "Left Alt",
        [Enum.ButtonCode.KEY_RALT] = "Right Alt",
        [Enum.ButtonCode.KEY_LCONTROL] = "Left Ctrl",
        [Enum.ButtonCode.KEY_RCONTROL] = "Right Ctrl",
        -- Add more popular keys if needed
    }
    return keyNames[buttonCode] or "Unknown Key"
end

function Utils.updateInstructionLabels()
    local enableKey = Utils.getKeyName(menuItems.enableCamp:Get())
    local disableKey = Utils.getKeyName(menuItems.disableCamp:Get())
    
    instructionLabels.step2:ForceLocalization("2. Press " .. enableKey .. " near camp to setup & enable it")
    instructionLabels.step3:ForceLocalization("3. Press " .. disableKey .. " near camp to disable it")
end

function Utils.getCampCenter(camp)
    if not camp then return nil end
    local box = Camp.GetCampBox(camp)
    if not box or not box.min or not box.max then return nil end
    
    local centerX = (box.min:GetX() + box.max:GetX()) / 2
    local centerY = (box.min:GetY() + box.max:GetY()) / 2
    local centerZ = (box.min:GetZ() + box.max:GetZ()) / 2
    
    return Vector(centerX, centerY, centerZ)
end

function Utils.findNearestCamp(position)
    local camps = Camps.GetAll()
    if not camps or #camps == 0 then return nil end
    
    local nearestCamp = nil
    local minDistance = math.huge
    
    for i = 1, #camps do
        local camp = camps[i]
        local center = Utils.getCampCenter(camp)
        if center then
            local distance = (center - position):Length2D()
            if distance < minDistance then
                minDistance = distance
                nearestCamp = camp
            end
        end
    end
    
    return nearestCamp
end

function Utils.generateCampKey(camp)
    if not camp then return nil end
    local box = Camp.GetCampBox(camp)
    if not box or not box.min or not box.max then return nil end
    
    local minX = math.floor(box.min:GetX())
    local minY = math.floor(box.min:GetY())
    local maxX = math.floor(box.max:GetX())
    local maxY = math.floor(box.max:GetY())
    
    return string.format("%d_%d_%d_%d", minX, minY, maxX, maxY)
end

function Utils.serializeTable(tbl)
    local function serialize(value)
        if type(value) == "table" then
            local parts = {"{"}
            local first = true
            for k, v in pairs(value) do
                if not first then table.insert(parts, ",") end
                first = false
                local key = type(k) == "number" and ("[" .. k .. "]=") or string.format("[%q]=", tostring(k))
                table.insert(parts, key .. serialize(v))
            end
            table.insert(parts, "}")
            return table.concat(parts)
        elseif type(value) == "string" then
            return string.format("%q", value)
        else
            return tostring(value)
        end
    end
    return "return " .. serialize(tbl)
end

function Utils.isCampActive(camp)
    -- Camp is considered active if:
    -- 1. It has an assigned alive unit, OR
    -- 2. It has autostart enabled (waiting for units)
    
    local key = Utils.generateCampKey(camp)
    
    -- Check assigned units
    for unit, assignedCamp in pairs(units.campAssignments) do
        if assignedCamp == camp and Entity.IsAlive(unit) then
            if debugSettings.verboseLogging:Get() then
                print(string.format("[AutoStacker] Camp %s is active (has alive unit)", key or "unknown"))
            end
            return true
        end
    end
    
    -- Check autostart
    if PresetManager and PresetManager.getCampAutoStart then
        local autoStart = PresetManager.getCampAutoStart(camp)
        if autoStart then
            return true
        end
    end
    return false
end

function Utils.toggleCampActive(camp)
    -- If camp is active, deactivate it
    if Utils.isCampActive(camp) then
        -- Remove assignments for this camp
        for unit, assignedCamp in pairs(units.campAssignments) do
            if assignedCamp == camp then
                units.campAssignments[unit] = nil
            end
        end
    else
        -- If camp is inactive, try to find a free unit and assign it immediately
        local freeUnit = Utils.findFreeUnit()
        if freeUnit then
            UnitManager.assignUnitToCamp(freeUnit, camp)
        end
    end
end

-- Checks if player can control the unit
function Utils.isPlayerControlled(unit)
    if not unit or not Entity.IsAlive(unit) then return false end
    
    local player = Players.GetLocal()
    if not player then return false end
    
    -- Exclude heroes - they should not participate in stacking
    if NPC.IsHero(unit) then return false end
    
    -- Check basic conditions
    if not NPC.IsCreep(unit) then return false end
    
    -- MAIN CHECK: can player control this unit
    local playerId = Entity.GetIndex(player)
    if Entity.IsControllableByPlayer(unit, playerId) then return true end
    
    -- Check special cases for controlled creeps
    if NPC.HasModifier(unit, "modifier_dominated") then return true end
    if NPC.HasModifier(unit, "modifier_chen_holy_persuasion") then return true end
    if NPC.HasModifier(unit, "modifier_enchantress_enchant") then return true end
    
    -- Check Nature's Prophet treants by unit name
    local unitName = NPC.GetUnitName(unit)
    if unitName then
        if string.find(unitName, "furion_treant") then return true end
        if string.find(unitName, "npc_dota_furion_treant") then return true end
        if string.find(unitName, "treant") and string.find(unitName, "furion") then return true end
    end
    
    -- Check owner
    local owner = Entity.GetOwner(unit)
    if owner and owner == player then return true end
    
    -- Check team (for regular creeps)
    if Entity.GetTeamNum(unit) ~= Entity.GetTeamNum(player) then return false end
    
    -- Exclude neutral creeps (but dominated ones already passed check above)
    if NPC.IsNeutral(unit) then return false end
    
    return false
end

-- Universal function to find controlled units in radius from position
function Utils.findControlledUnitsInRadius(position, radius)
    local controlledUnits = {}
    
    -- NEW METHOD: Use NPCs.GetAll() to get ALL NPCs in the game
    pcall(function()
        local allNPCs = NPCs.GetAll()
        
        if debugSettings.verboseLogging:Get() then
            print(string.format("[AutoStacker] NPCs.GetAll(): found %d NPC", allNPCs and #allNPCs or 0))
        end
        
        if allNPCs then
            local inRadiusCount = 0
            local controlledCount = 0
            
            for i = 1, #allNPCs do
                local unit = allNPCs[i]
                
                -- Check distance to position
                pcall(function()
                    local unitPos = Entity.GetAbsOrigin(unit)
                    if unitPos then
                        local distance = (unitPos - position):Length2D()
                        if distance <= radius then
                            inRadiusCount = inRadiusCount + 1
                            
                            if Utils.isPlayerControlled(unit) then
                                controlledCount = controlledCount + 1
                                
                                -- Check if already added
                                local alreadyAdded = false
                                for j = 1, #controlledUnits do
                                    if controlledUnits[j] == unit then
                                        alreadyAdded = true
                                        break
                                    end
                                end
                                if not alreadyAdded then
                                    table.insert(controlledUnits, unit)
                                    
                                    if debugSettings.verboseLogging:Get() then
                                        local unitName = "Unknown"
                                        pcall(function()
                                            unitName = NPC.GetUnitName(unit) or "No Name"
                                        end)
                                        print(string.format("[AutoStacker] Found controlled NPC: %s (distance: %.0f)", unitName, distance))
                                    end
                                end
                            end
                        end
                    end
                end)
            end
            
            if debugSettings.verboseLogging:Get() then
                print(string.format("[AutoStacker] В radius %d: %d NPC, controlled: %d", radius, inRadiusCount, controlledCount))
            end
        end
    end)
    
    return controlledUnits
end

function Utils.findFreeUnit()
    local player = Players.GetLocal()
    if not player then return nil end
    
    local controlledUnits = {}
    
    -- Method 1: Add selected units (priority)
    pcall(function()
        local selectedUnits = Player.GetSelectedUnits(player) or {}
        for i = 1, #selectedUnits do
            local unit = selectedUnits[i]
            if Utils.isPlayerControlled(unit) then
                table.insert(controlledUnits, unit)
            end
        end
    end)
    
    -- Method 2: Add already tracked units
    pcall(function()
        for i = 1, #units.tracked do
            local unit = units.tracked[i]
            if Utils.isPlayerControlled(unit) then
                local alreadyAdded = false
                for j = 1, #controlledUnits do
                    if controlledUnits[j] == unit then
                        alreadyAdded = true
                        break
                    end
                end
                if not alreadyAdded then
                    table.insert(controlledUnits, unit)
                end
            end
        end
    end)
    
    -- Method 3: Universal search near player
    local playerPos = Entity.GetAbsOrigin(player)
    local nearPlayerUnits = Utils.findControlledUnitsInRadius(playerPos, 2000)
    for i = 1, #nearPlayerUnits do
        local unit = nearPlayerUnits[i]
        local alreadyAdded = false
        for j = 1, #controlledUnits do
            if controlledUnits[j] == unit then
                alreadyAdded = true
                break
            end
        end
        if not alreadyAdded then
            table.insert(controlledUnits, unit)
        end
    end
    
    -- Method 4: Universal search near camps
    pcall(function()
        local camps = Camps.GetAll()
        if camps then
            for i = 1, #camps do
                local camp = camps[i]
                local campCenter = Utils.getCampCenter(camp)
                if campCenter then
                    local nearCampUnits = Utils.findControlledUnitsInRadius(campCenter, 2000)
                    for j = 1, #nearCampUnits do
                        local unit = nearCampUnits[j]
                        local alreadyAdded = false
                        for k = 1, #controlledUnits do
                            if controlledUnits[k] == unit then
                                alreadyAdded = true
                                break
                            end
                        end
                        if not alreadyAdded then
                            table.insert(controlledUnits, unit)
                        end
                    end
                end
            end
        end
    end)
    
    if debugSettings.verboseLogging:Get() then
        print(string.format("[AutoStacker] found controlled creeps: %d", #controlledUnits))
        
        -- Show found creeps
        for i = 1, #controlledUnits do
            local unit = controlledUnits[i]
            local unitName = "Unknown"
            pcall(function()
                unitName = NPC.GetUnitName(unit) or "No Name"
            end)
            print(string.format("[AutoStacker] Контролируемый creep %d: %s", i, unitName))
        end
        if #controlledUnits == 0 then
            print("[AutoStacker] No controlled creeps! Make sure you have:")
            print("  - Dominated creeps (Helm of Dominator)")
            print("  - Summoned creeps (Nature's Prophet, Chen, Enchantress)")
            print("  - Selected creeps")
            
            -- Additional debugging: show found CREEPS
            print("[AutoStacker] === CREEP SEARCH DEBUG ===")
            local player = Players.GetLocal()
            if player then
                local allUnits = Entity.GetUnitsInRadius(player, 2000, Enum.TeamType.TEAM_FRIEND, true, true)
                if allUnits then
                    print(string.format("[AutoStacker] Total allied units в radius: %d", #allUnits))
                    
                    local creepCount = 0
                    for i = 1, #allUnits do
                        local unit = allUnits[i]
                        local unitName = "Unknown"
                        local unitClass = "Unknown"
                        local isCreep = false
                        local isNeutral = false
                        local owner = nil
                        local isPlayerControlled = false
                        
                        local isHero = false
                        local hasDominated = false
                        local hasChentrol = false
                        local hasEnchant = false
                        pcall(function()
                            unitName = NPC.GetUnitName(unit) or "No Name"
                            unitClass = Entity.GetClassName(unit) or "No Class"
                            isCreep = NPC.IsCreep(unit)
                            isHero = NPC.IsHero(unit)
                            isNeutral = NPC.IsNeutral(unit)
                            owner = Entity.GetOwner(unit)
                            isPlayerControlled = Utils.isPlayerControlled(unit)
                            hasDominated = NPC.HasModifier(unit, "modifier_dominated")
                            hasChentrol = NPC.HasModifier(unit, "modifier_chen_holy_persuasion")
                            hasEnchant = NPC.HasModifier(unit, "modifier_enchantress_enchant")
                        end)
                        
                        -- Show creeps и heroes для debugging
                        if isCreep or isHero then
                            creepCount = creepCount + 1
                            local unitType = isHero and "Hero" or "Creep"
                            local isTreant = unitName and string.find(unitName, "furion_treant") or false
                            print(string.format("[AutoStacker] %s %d: %s (%s)", unitType, creepCount, unitName, unitClass))
                            print(string.format("  - Hero:%s, Neutral:%s, Owner:%s, PlayerControlled:%s", 
                                tostring(isHero), tostring(isNeutral), tostring(owner == player), tostring(isPlayerControlled)))
                            print(string.format("  - Dominated:%s, Chen:%s, Enchant:%s, Treant:%s", 
                                tostring(hasDominated), tostring(hasChentrol), tostring(hasEnchant), tostring(isTreant)))
                            
                            if creepCount >= 15 then break end -- Show maximum 15 units
                        end
                    end
                    
                    if creepCount == 0 then
                        print("[AutoStacker] No creeps found among allied units!")
                    end
                end
            end
            print("[AutoStacker] === END DEBUG ===")
        end
    end
    
    -- Search among all found creeps for a free one (not assigned to camp)
    for i = 1, #controlledUnits do
        local unit = controlledUnits[i]
        if not units.campAssignments[unit] then
            if debugSettings.verboseLogging:Get() then
                print(string.format("[AutoStacker] Found free creep: %s", tostring(unit)))
            end
            return unit
        end
    end
    
    if debugSettings.verboseLogging:Get() then
        print("[AutoStacker] No free creeps found")
    end
    
    return nil
end

function Utils.scanAndAssignAllCreeps()
    local assignedCount = 0
    local camps = Camps.GetAll() or {}
    
    print(string.format("[AutoStacker] found camps: %d", #camps))
    
    for i = 1, #camps do
        local camp = camps[i]
        local key = Utils.generateCampKey(camp)
        
        if key and presets[key] then
            local autoStart = PresetManager and PresetManager.getCampAutoStart and PresetManager.getCampAutoStart(camp)
            local hasAttackPoint = presets[key].attackPoint
            local hasPullPoint = presets[key].pullPoint
            local isConfigured = hasAttackPoint and hasPullPoint
            
            -- If autostart enabled and camp configured
            if autoStart and isConfigured then
                -- Check if there's already an assigned alive creep
                local hasLiveUnit = false
                for unit, assignedCamp in pairs(units.campAssignments) do
                    if assignedCamp == camp and Entity.IsAlive(unit) then
                        hasLiveUnit = true
                        break
                    end
                end
                
                -- Если нет живого creepа, пытаемся назначить нового
                if not hasLiveUnit then
                    local freeUnit = Utils.findFreeUnit()
                    if freeUnit then
                        UnitManager.assignUnitToCamp(freeUnit, camp)
                        assignedCount = assignedCount + 1
                        print(string.format("[AutoStacker] Assigned creep %s на camp %d", tostring(freeUnit), i))
                    end
                end
            end
        end
    end
    
    print(string.format("[AutoStacker] Scanning complete. Creeps assigned: %d", assignedCount))
    
    if assignedCount == 0 then
        print("[AutoStacker] Possible reasons:")
        print("  - No creeps in search radius")
        print("  - All creeps already assigned")
        print("  - No camps with autostart enabled")
        print("  - Creeps not controlled by player")
    end
end

-- ============================================================================
-- PRESET SYSTEM
-- ============================================================================

PresetManager = {}

function PresetManager.getCampSettings(camp)
    local attackSec = campSettings.attackSecond:Get()
    local waitTo = campSettings.waitUntilSecond:Get()
    local attackTime = campSettings.attackTime:Get()
    
    local key = Utils.generateCampKey(camp)
    if key and presets[key] and presets[key].settings then
        local settings = presets[key].settings
        if settings.attackSecond ~= nil then attackSec = settings.attackSecond end
        if settings.waitUntilSecond ~= nil then waitTo = settings.waitUntilSecond end
        if settings.attackTime ~= nil then attackTime = settings.attackTime end
    end
    
    return attackSec, waitTo, attackTime
end

function PresetManager.saveCampSettings(camp, attackSec, waitTo, attackTime, locked, autoStart)
    if not camp then return end
    local key = Utils.generateCampKey(camp)
    if not key then return end
    
    if not presets[key] then presets[key] = {} end
    if not presets[key].settings then presets[key].settings = {} end
    
    presets[key].settings.attackSecond = attackSec
    presets[key].settings.waitUntilSecond = waitTo
    presets[key].settings.attackTime = attackTime
    if locked ~= nil then presets[key].settings.locked = locked end
    if autoStart ~= nil then presets[key].settings.autoStart = autoStart end
    
    PresetManager.saveToConfig()
end

function PresetManager.getCampLocked(camp)
    local key = Utils.generateCampKey(camp)
    if key and presets[key] and presets[key].settings then
        return presets[key].settings.locked or false
    end
    return false
end

function PresetManager.getCampAutoStart(camp)
    local key = Utils.generateCampKey(camp)
    if key and presets[key] and presets[key].settings then
        return presets[key].settings.autoStart or false
    end
    return false
end

function PresetManager.setCampLocked(camp, locked)
    local key = Utils.generateCampKey(camp)
    if not key then return end
    
    if not presets[key] then presets[key] = {} end
    if not presets[key].settings then presets[key].settings = {} end
    
    presets[key].settings.locked = locked
    PresetManager.saveToConfig()
    
    if debugSettings.verboseLogging:Get() then
        print("[AutoStacker] Camp " .. key .. " " .. (locked and "locked" or "unlocked"))
    end
end

function PresetManager.setCampAutoStart(camp, autoStart)
    local key = Utils.generateCampKey(camp)
    if not key then return end
    
    if not presets[key] then presets[key] = {} end
    if not presets[key].settings then presets[key].settings = {} end
    
    presets[key].settings.autoStart = autoStart
    PresetManager.saveToConfig()
    
    print("[AutoStacker] Camp " .. key .. " auto-assign creeps " .. (autoStart and "enabled" or "disabled"))
    
    -- NEW LOGIC: Checkbox no longer affects already assigned creeps
    -- It only controls auto-search for new creeps when current ones die
    -- Assigned creeps continue stacking regardless of checkbox
end

function PresetManager.saveToConfig()
    local keysList = {}
    for key, preset in pairs(presets) do
        table.insert(keysList, key)
        
        if preset.attackPoint then
            local pos = preset.attackPoint
            Config.WriteString(CONFIG.PRESET_KEY, key .. ".attack", 
                string.format("%f,%f,%f", pos.x, pos.y, pos.z))
        end
        
        if preset.pullPoint then
            local pos = preset.pullPoint
            Config.WriteString(CONFIG.PRESET_KEY, key .. ".pull", 
                string.format("%f,%f,%f", pos.x, pos.y, pos.z))
        end
        
        if preset.settings then
            local s = preset.settings
            Config.WriteInt(CONFIG.PRESET_KEY, key .. ".attackSec", s.attackSecond or 0)
            Config.WriteInt(CONFIG.PRESET_KEY, key .. ".waitTo", s.waitUntilSecond or 0)
            Config.WriteFloat(CONFIG.PRESET_KEY, key .. ".attackTime", s.attackTime or 0)
            Config.WriteInt(CONFIG.PRESET_KEY, key .. ".locked", (s.locked and 1) or 0)
            Config.WriteInt(CONFIG.PRESET_KEY, key .. ".autoStart", (s.autoStart and 1) or 0)
        end
    end
    
    if #keysList > 0 then
        Config.WriteString(CONFIG.PRESET_KEY, "_keys", table.concat(keysList, ","))
    end
end

function PresetManager.loadFromConfig()
    local loaded = {}
    local keysStr = Config.ReadString(CONFIG.PRESET_KEY, "_keys", "")
    
    if keysStr ~= "" then
        for key in string.gmatch(keysStr, "[^,]+") do
            loaded[key] = true
        end
    else
        -- Fallback: load all existing camps
        local camps = Camps.GetAll() or {}
        for i = 1, #camps do
            local camp = camps[i]
            local key = Utils.generateCampKey(camp)
            if key then loaded[key] = true end
        end
    end
    
    for key, _ in pairs(loaded) do
        local function readVector(suffix)
            local str = Config.ReadString(CONFIG.PRESET_KEY, key .. suffix, "")
            if str == "" then return nil end
            local x, y, z = str:match("([^,]+),([^,]+),([^,]+)")
            if not x then return nil end
            return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
        end
        
        local attackPoint = readVector(".attack")
        local pullPoint = readVector(".pull")
        local attackSec = Config.ReadInt(CONFIG.PRESET_KEY, key .. ".attackSec", -1)
        local waitTo = Config.ReadInt(CONFIG.PRESET_KEY, key .. ".waitTo", -1)
        local attackTime = Config.ReadFloat(CONFIG.PRESET_KEY, key .. ".attackTime", -1)
        local locked = Config.ReadInt(CONFIG.PRESET_KEY, key .. ".locked", 0) == 1
        local autoStart = Config.ReadInt(CONFIG.PRESET_KEY, key .. ".autoStart", 0) == 1
        
        if attackPoint or pullPoint or attackSec >= 0 or waitTo >= 0 or attackTime >= 0 then
            presets[key] = {
                attackPoint = attackPoint,
                pullPoint = pullPoint,
                settings = {
                    attackSecond = attackSec >= 0 and attackSec or nil,
                    waitUntilSecond = waitTo >= 0 and waitTo or nil,
                    attackTime = attackTime >= 0 and attackTime or nil,
                    locked = locked,
                    autoStart = autoStart
                }
            }
        end
    end
end

function PresetManager.applyPreset(camp)
    if not camp then return end
    local key = Utils.generateCampKey(camp)
    if not key then return end
    
    local preset = presets[key]
    if preset then
        if preset.attackPoint then
            state.attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
        end
        if preset.pullPoint then
            state.pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
        end
        if preset.settings then
            local s = preset.settings
            if s.attackSecond then campSettings.attackSecond:Set(s.attackSecond) end
            if s.waitUntilSecond then campSettings.waitUntilSecond:Set(s.waitUntilSecond) end
            if s.attackTime then campSettings.attackTime:Set(s.attackTime) end
        end
        print("[AutoStacker] Preset applied for camp " .. key)
    else
        state.attackPoint = nil
        state.pullPoint = nil
        print("[AutoStacker] No preset for camp " .. key .. ", points cleared")
    end
end

function PresetManager.clearPreset(camp)
    if not camp then return end
    local key = Utils.generateCampKey(camp)
    if not key then return end
    
    presets[key] = nil
    Config.WriteString(CONFIG.PRESET_KEY, key .. ".attack", "")
    Config.WriteString(CONFIG.PRESET_KEY, key .. ".pull", "")
    Config.WriteInt(CONFIG.PRESET_KEY, key .. ".attackSec", -1)
    Config.WriteInt(CONFIG.PRESET_KEY, key .. ".waitTo", -1)
    Config.WriteFloat(CONFIG.PRESET_KEY, key .. ".attackTime", -1)
    Config.WriteInt(CONFIG.PRESET_KEY, key .. ".locked", 0)
    Config.WriteInt(CONFIG.PRESET_KEY, key .. ".autoStart", 0)
end

function PresetManager.saveCurrentPoints()
    if not state.selectedCamp or not state.attackPoint or not state.pullPoint then
        return
    end
    
    local key = Utils.generateCampKey(state.selectedCamp)
    if not key then return end
    
    local existing = presets[key]
    local attackSec, waitTo, attackTime = PresetManager.getCampSettings(state.selectedCamp)
    local locked = PresetManager.getCampLocked(state.selectedCamp)
    local autoStart = PresetManager.getCampAutoStart(state.selectedCamp)
    
    local current = {
        attackPoint = {
            x = state.attackPoint:GetX(),
            y = state.attackPoint:GetY(),
            z = state.attackPoint:GetZ()
        },
        pullPoint = {
            x = state.pullPoint:GetX(),
            y = state.pullPoint:GetY(),
            z = state.pullPoint:GetZ()
        },
        settings = {
            attackSecond = attackSec,
            waitUntilSecond = waitTo,
            attackTime = attackTime,
            locked = locked,
            autoStart = autoStart
        }
    }
    
    -- Check if settings have changed
    local function samePoint(a, b)
        return a and b and a.x == b.x and a.y == b.y and a.z == b.z
    end
    
    local same = existing and 
        samePoint(existing.attackPoint, current.attackPoint) and
        samePoint(existing.pullPoint, current.pullPoint) and
        existing.settings and
        existing.settings.attackSecond == current.settings.attackSecond and
        existing.settings.waitUntilSecond == current.settings.waitUntilSecond and
        existing.settings.attackTime == current.settings.attackTime and
        existing.settings.locked == current.settings.locked and
        existing.settings.autoStart == current.settings.autoStart
    
    if not same then
        presets[key] = current
        PresetManager.saveToConfig()
        print("[AutoStacker] Preset autosaved for camp " .. key)
    end
end

-- ============================================================================
-- UNIT MANAGEMENT
-- ============================================================================

local UnitManager = {}

function UnitManager.initializeSelectedUnits()
    local player = Players.GetLocal()
    local selectedUnits = Player.GetSelectedUnits(player) or {}
    
    if #selectedUnits == 0 then
        print("[AutoStacker] No selected units.")
        return false
    end
    
    units.tracked = {}
    for i = 1, #selectedUnits do
        local unit = selectedUnits[i]
        if Entity.IsAlive(unit) and not Entity.IsHero(unit) then
            table.insert(units.tracked, unit)
        end
    end
    
    if #units.tracked == 0 then
        print("[AutoStacker] Select a non-hero to stack.")
        return false
    end
    
    units.states = {}
    return true
end

function UnitManager.assignUnitToCamp(unit, camp)
    if not unit or not camp then return end
    
    units.campAssignments[unit] = camp
    units.states[unit] = {}
    
    local exists = false
    for i = 1, #units.tracked do
        if units.tracked[i] == unit then
            exists = true
            break
        end
    end
    
    if not exists then
        table.insert(units.tracked, unit)
    end
    
    -- NEW LOGIC: Assigned creep immediately starts stacking (regardless of checkbox)
    -- Checkbox now only controls auto-search for new creeps when they die
    
    print(string.format("[AutoStacker] Bound unit %s to camp and started stacking", tostring(unit)))
end

function UnitManager.getActiveUnits()
    local activeUnits = {}
    for i = 1, #units.tracked do
        local unit = units.tracked[i]
        -- NEW LOGIC: All assigned alive units are considered active
        -- Checkbox no longer controls activity of assigned units
        if Entity.IsAlive(unit) and units.campAssignments[unit] then
            table.insert(activeUnits, unit)
        end
    end
    return activeUnits
end

function UnitManager.cleanupDeadUnits()
    -- Clean dead units from tracked list
    local aliveUnits = {}
    local removedUnits = {}
    
    for i = 1, #units.tracked do
        local unit = units.tracked[i]
        local isAlive = false
        pcall(function()
            if unit and Entity.IsAlive(unit) then
                isAlive = true
            end
        end)
        
        if isAlive then
            table.insert(aliveUnits, unit)
        else
            table.insert(removedUnits, unit)
            -- Clean dead unit's data
            local camp = units.campAssignments[unit]
            units.campAssignments[unit] = nil
            units.states[unit] = nil
            units.lastDesiredPos[unit] = nil
            units.spamPrevention[unit] = nil
            units.attackTimes[unit] = nil
            units.lastAttackMinute[unit] = nil
            
            if camp then
                print(string.format("[AutoStacker] Unit %s died", tostring(unit)))
                
                -- NEW LOGIC: Check auto-assign checkbox
                local autoAssign = PresetManager.getCampAutoStart(camp)
                if autoAssign then
                    -- Try to find a new free creep
                    local freeUnit = Utils.findFreeUnit()
                    if freeUnit then
                        UnitManager.assignUnitToCamp(freeUnit, camp)
                        print(string.format("[AutoStacker] Automatically assigned new creep %s to camp", tostring(freeUnit)))
                    else
                        print("[AutoStacker] No free creep found for auto-assign")
                    end
                end
            end
        end
    end
    
    units.tracked = aliveUnits
    
    -- Additional cleanup of invalid assignments
    local validAssignments = {}
    for unit, camp in pairs(units.campAssignments) do
        local isValid = false
        pcall(function()
            if unit and camp and Entity.IsAlive(unit) then
                isValid = true
            end
        end)
        
        if isValid then
            validAssignments[unit] = camp
        end
    end
    units.campAssignments = validAssignments
    
    return #removedUnits > 0
end

function UnitManager.executeUnitLogic()
    -- First clean up dead units
    UnitManager.cleanupDeadUnits()
    
    local activeUnits = UnitManager.getActiveUnits()
    if #activeUnits == 0 then
        local now = GameRules.GetGameTime()
        if (now - state.lastNoUnitsLog) > 1.0 then
            print("[AutoStacker] No bound units.")
            state.lastNoUnitsLog = now
        end
        return
    end
    
    local gameTime = Utils.getGameTime()
    local currentMinute = math.floor(gameTime / 60)
    local currentSecond = math.floor(gameTime % 60)
    
    -- Initialize states for current minute
    for i = 1, #activeUnits do
        local unit = activeUnits[i]
        if not units.states[unit] then
            units.states[unit] = {}
        end
        if not units.states[unit][currentMinute] then
            -- Check if there was a previous minute
            local prevMinute = currentMinute - 1
            local prevState = units.states[unit][prevMinute]
            
            units.states[unit][currentMinute] = {
                waitDone = false,
                attackDone = false,
                pullDone = false
            }
            
            -- If creep was already at wait position in previous minute,
            -- and we're at the beginning of new minute (seconds 0-5), don't reset waitDone
            if prevState and prevState.waitDone and currentSecond <= 5 then
                units.states[unit][currentMinute].waitDone = true
            end
        end
    end
    
    -- Execute logic for each unit
    for i = 1, #activeUnits do
        local unit = activeUnits[i]
        UnitManager.processUnit(unit, currentMinute, currentSecond)
    end
end

function UnitManager.processUnit(unit, currentMinute, currentSecond)
    local camp = units.campAssignments[unit]
    if not camp then return end
    
    local key = Utils.generateCampKey(camp)
    local preset = key and presets[key]
    if not preset or not preset.attackPoint or not preset.pullPoint then
        return
    end
    
    -- НОВАЯ ЛОГИКА: Убираем проверку автостарта
    -- Assignedные creepы всегда выполняют стакинг независимо от галочки
    -- Галочка контролирует только автопоиск новых creeps при смерти
    
    local attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
    local pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
    local attackSec, waitTo, attackTime = PresetManager.getCampSettings(camp)
    
    local unitState = units.states[unit][currentMinute]
    local player = Players.GetLocal()
    local currentTime = GameRules.GetGameTime()
    
    -- Stacking logic
    if currentSecond < attackSec then
        -- Wait phase
        if not unitState.waitDone then
            -- Check if creep is not too close to attack point
            local unitPos = Entity.GetAbsOrigin(unit)
            local distance = (attackPoint - unitPos):Length2D()
            
            -- Send command only if creep is far from point (more than 100 units)
            if distance > 100 then
                unitState.waitDone = true
                print(string.format("[Stacker] Unit %s в %d:%02d -> WAIT (%.0f, %.0f, %.0f)", 
                    unit, currentMinute, currentSecond, attackPoint:GetX(), attackPoint:GetY(), attackPoint:GetZ()))
                
                Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
                    nil, attackPoint, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, 
                    unit, false, false, false, false)
            else
                -- Creep already close to point, just mark as done
                unitState.waitDone = true
            end
        end
    elseif currentSecond == attackSec and not unitState.attackDone then
        -- Attack phase
        unitState.attackDone = true
        
        -- Find nearest neutral
        local nearbyUnits = Entity.GetUnitsInRadius(unit, 1200, Enum.TeamType.TEAM_ENEMY, true, true)
        local target = nil
        local minDistance = math.huge
        local unitPos = Entity.GetAbsOrigin(unit)
        
        if nearbyUnits and #nearbyUnits > 0 then
            for j = 1, #nearbyUnits do
                local enemy = nearbyUnits[j]
                if NPC.IsNeutral(enemy) and Entity.IsAlive(enemy) then
                    local distance = (Entity.GetAbsOrigin(enemy) - unitPos):Length2D()
                    if distance < minDistance then
                        minDistance = distance
                        target = enemy
                    end
                end
            end
        end
        
        if target then
            print(string.format("[Stacker] Unit %s в %d:%02d -> ATTACK TARGET %s", 
                unit, currentMinute, currentSecond, NPC.GetUnitName(target)))
            Player.AttackTarget(player, unit, target, false, false, true)
        else
            local campCenter = Utils.getCampCenter(camp)
            if campCenter then
                print(string.format("[Stacker] Unit %s в %d:%02d -> ATTACK (%.0f, %.0f, %.0f)", 
                    unit, currentMinute, currentSecond, campCenter:GetX(), campCenter:GetY(), campCenter:GetZ()))
                Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE, 
                    nil, campCenter, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, 
                    unit, false, false, false, false)
            end
        end
        
        units.attackTimes[unit] = currentTime + attackTime
        units.lastAttackMinute[unit] = currentMinute
    end
    
    -- Pull phase
    if unitState.attackDone and not unitState.pullDone and units.attackTimes[unit] and 
       currentTime >= units.attackTimes[unit] then
        unitState.pullDone = true
        print(string.format("[Stacker] Unit %s в %d:%02d -> PULL (%.0f, %.0f, %.0f)", 
            unit, currentMinute, currentSecond, pullPoint:GetX(), pullPoint:GetY(), pullPoint:GetZ()))
        
        Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
            nil, pullPoint, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, 
            unit, false, false, false, false)
    end
    
    -- Additional positioning logic
    UnitManager.updateUnitPosition(unit, attackPoint, pullPoint, currentMinute, currentSecond, 
        attackSec, waitTo, attackTime)
end

function UnitManager.updateUnitPosition(unit, attackPoint, pullPoint, currentMinute, currentSecond, 
                                       attackSec, waitTo, attackTime)
    -- NEW LOGIC: Remove autostart check
    -- Assigned creeps should always be tracked and positioned correctly
    
    local desired = nil
    local currentTime = GameRules.GetGameTime()
    local lastAttackMinute = units.lastAttackMinute[unit]
    local inNextMinute = (lastAttackMinute ~= nil) and (currentMinute > lastAttackMinute)
    
    local unitState = units.states[unit][currentMinute]
    local prevMinute = (lastAttackMinute ~= nil) and (currentMinute - 1) or nil
    local prevState = prevMinute and units.states[unit][prevMinute] or nil
    
    -- Determine desired position
    if inNextMinute and prevState and not prevState.pullDone then
        desired = pullPoint
    elseif inNextMinute and currentSecond < waitTo then
        desired = pullPoint
    elseif currentSecond < attackSec or not unitState.attackDone then
        desired = attackPoint
    else
        if not unitState.pullDone then
            if units.attackTimes[unit] and currentTime < units.attackTimes[unit] then
                desired = nil -- Wait for attack to finish
            else
                desired = pullPoint
            end
        else
            if inNextMinute and currentSecond >= waitTo then
                desired = attackPoint
            else
                desired = pullPoint
            end
        end
    end
    
    -- Send movement command with spam protection
    if desired then
        local unitPos = Entity.GetAbsOrigin(unit)
        local distance = (desired - unitPos):Length2D()
        local lastPos = units.lastDesiredPos[unit]
        local targetChanged = (not lastPos) or ((desired - lastPos):Length2D() > 10)
        local lastSpam = units.spamPrevention[unit] or 0
        local shouldOrder = false
        
        if targetChanged then
            shouldOrder = true
        elseif distance > 60 and (currentTime - lastSpam) >= CONFIG.SPAM_PREVENTION_DELAY then
            shouldOrder = true
        end
        
        if shouldOrder then
            units.lastDesiredPos[unit] = desired
            units.spamPrevention[unit] = currentTime
            local player = Players.GetLocal()
            
            if debugSettings.verboseLogging:Get() then
                print(string.format("[AutoStacker] Sending command movement Unitу %s к (%.0f, %.0f)", 
                    tostring(unit), desired:GetX(), desired:GetY()))
            end
            
            Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
                nil, desired, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, 
                unit, false, false, false, false)
        end
    end
end

-- ============================================================================
-- СИСТЕМА РЕНДЕРИНГА
-- ============================================================================

local RenderSystem = {}



function RenderSystem.getCampStatus(camp, isConfigured)
    if not isConfigured then
        return {255, 180, 50, 255}, "⚠ Setup Required"
    end
    
    -- Проверяем, есть ли живой Assignedный creep
    local assignedUnit = nil
    local isUnitAlive = false
    
    for unit, assignedCamp in pairs(units.campAssignments) do
        if assignedCamp == camp then
            assignedUnit = unit
            isUnitAlive = Entity.IsAlive(unit)
            break
        end
    end
    
    local autoAssign = PresetManager.getCampAutoStart(camp)
    
    if not assignedUnit then
        if autoAssign then
            return {100, 150, 255, 255}, "🔍 Searching for creep"
        else
            return {120, 120, 130, 255}, "⏸ Ready to assign creep"
        end
    elseif not isUnitAlive then
        if autoAssign then
            return {255, 120, 120, 255}, "💀 Creep died, searching new"
        else
            return {180, 80, 80, 255}, "💀 Creep died"
        end
    else
        -- НОВАЯ ЛОГИКА: creep жив и Assigned = всегда активно стакает
        -- Галочка больше не влияет на статус Assignedного creepа
        local gameTime = Utils.getGameTime()
        local currentMinute = math.floor(gameTime / 60)
        local currentSecond = math.floor(gameTime % 60)
        local attackSec = PresetManager.getCampSettings(camp)
        
        -- Определяем фазу стакинга
        if currentSecond >= (attackSec - 5) and currentSecond <= (attackSec + 5) then
            return {255, 200, 50, 255}, "⚔ Stacking now!"
        elseif currentSecond < attackSec then
            return {50, 255, 150, 255}, "⏳ Waiting to stack"
        else
            return {150, 255, 50, 255}, "🏃 Returning to position"
        end
    end
end

function RenderSystem.shouldShowVisuals()
    if not state.enabled then return false end
    
    -- Проверяем условное отображение визуалов
    if conditionalVisuals.conditionalVisuals:Get() then
        return conditionalVisuals.visualsHotkey:IsDown()
    end
    
    return true
end

function RenderSystem.drawCampBoxes()
    if not RenderSystem.shouldShowVisuals() or not visualSettings.showCampBox:Get() then return end
    
    for unit, camp in pairs(units.campAssignments) do
        if camp then
            local box = Camp.GetCampBox(camp)
            if box and box.min and box.max then
                -- Используем среднюю высоту между min и max - это уровень земли
                local z = (box.min:GetZ() + box.max:GetZ()) / 2
                local corners = {
                    Vector(box.min:GetX(), box.min:GetY(), z),
                    Vector(box.max:GetX(), box.min:GetY(), z),
                    Vector(box.max:GetX(), box.max:GetY(), z),
                    Vector(box.min:GetX(), box.max:GetY(), z)
                }
                
                local screenCorners = {}
                local allVisible = true
                
                for i = 1, 4 do
                    local x, y, visible = Renderer.WorldToScreen(corners[i])
                    if visible then
                        screenCorners[i] = {x = x, y = y}
                    else
                        allVisible = false
                        break
                    end
                end
                
                if allVisible then
                    Renderer.SetDrawColor(table.unpack(COLORS.CAMP_BOX))
                    for i = 1, 4 do
                        local next_i = (i % 4) + 1
                        Renderer.DrawLine(screenCorners[i].x, screenCorners[i].y, 
                                        screenCorners[next_i].x, screenCorners[next_i].y)
                    end
                    
                    local centerX = (screenCorners[1].x + screenCorners[3].x) / 2
                    local centerY = (screenCorners[1].y + screenCorners[3].y) / 2
                    Renderer.SetDrawColor(table.unpack(COLORS.CAMP_BOX_FILL))
                    Renderer.DrawFilledRect(centerX - 4, centerY - 4, 8, 8)
                end
            end
        end
    end
end

function RenderSystem.drawPoints()
    if not RenderSystem.shouldShowVisuals() then return end
    
    local pulse = math.floor((math.sin(GameRules.GetGameTime() * 4) * 0.5 + 0.5) * 4) + 6
    local font = Renderer.LoadFont("Tahoma", 12, 700)
    
    -- Отладочная информация
    if debugSettings.showPointsDebug:Get() then
        local debugY = 500
        Renderer.SetDrawColor(0, 0, 0, 180)
        Renderer.DrawFilledRect(10, debugY, 400, 100)
        
        Renderer.SetDrawColor(255, 255, 255, 255)
        Renderer.DrawText(font, 15, debugY + 5, "Points Debug:")
        Renderer.DrawText(font, 15, debugY + 25, string.format("Selected camp: %s", tostring(state.selectedCamp)))
        Renderer.DrawText(font, 15, debugY + 45, string.format("Attack point: %s", tostring(state.attackPoint)))
        Renderer.DrawText(font, 15, debugY + 65, string.format("Pull point: %s", tostring(state.pullPoint)))
        
        local assignedCount = 0
        for unit, camp in pairs(units.campAssignments) do
            pcall(function()
                if unit and Entity.IsAlive(unit) then 
                    assignedCount = assignedCount + 1 
                end
            end)
        end
        Renderer.DrawText(font, 15, debugY + 85, string.format("Assigned units: %d", assignedCount))
    end
    
    -- Собираем все campы для отображения (избегаем дублирования)
    local campsToRender = {}
    
    -- Добавляем выбранный camp (если есть)
    if state.selectedCamp and state.attackPoint and state.pullPoint then
        local key = Utils.generateCampKey(state.selectedCamp)
        if key then
            campsToRender[key] = {
                camp = state.selectedCamp,
                attackPoint = state.attackPoint,
                pullPoint = state.pullPoint,
                isSelected = true,
                hasAssignedUnit = false
            }
        end
    end
    
    -- Добавляем campы с Assignedными Unitами (не дублируем выбранный)
    for unit, camp in pairs(units.campAssignments) do
        local isAlive = false
        pcall(function()
            if unit and camp and Entity.IsAlive(unit) then
                isAlive = true
            end
        end)
        
        if isAlive then
            local key = camp and Utils.generateCampKey(camp)
            local preset = key and presets[key]
            
            if preset and preset.attackPoint and preset.pullPoint then
                if campsToRender[key] then
                    -- camp уже есть (выбранный), просто отмечаем что у него есть Assignedный Unit
                    campsToRender[key].hasAssignedUnit = true
                else
                    -- Добавляем новый camp
                    campsToRender[key] = {
                        camp = camp,
                        attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z),
                        pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z),
                        isSelected = false,
                        hasAssignedUnit = true
                    }
                end
            end
        end
    end
    
    -- Добавляем campы с активным основным оверлеем (где нажали ENABLE)
    local camps = Camps.GetAll()
    if camps then
        for i = 1, #camps do
            local camp = camps[i]
            local key = Utils.generateCampKey(camp)
            local preset = key and presets[key]
            local hasAutoStart = PresetManager and PresetManager.getCampAutoStart and PresetManager.getCampAutoStart(camp)
            
            -- Если у campа есть preset, точки и включен autoStart - Show точки
            if preset and preset.attackPoint and preset.pullPoint and hasAutoStart and not campsToRender[key] then
                campsToRender[key] = {
                    camp = camp,
                    attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z),
                    pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z),
                    isSelected = false,
                    hasAssignedUnit = false
                }
            end
        end
    end
    

    
    -- Рисуем точки для всех собранных camps
    for key, campData in pairs(campsToRender) do
        local attackPoint = campData.attackPoint
        local pullPoint = campData.pullPoint
        local isSelected = campData.isSelected
        local hasAssignedUnit = campData.hasAssignedUnit
        
        -- Точка атаки
        local x, y, visible = Renderer.WorldToScreen(attackPoint)
        if visible then
            -- Подсветка при перетаскивании
            local isBeingDragged = state.dragging and 
                ((state.dragTarget == "selected_attack" and isSelected) or 
                 (state.dragTarget == "preset_attack" and state.dragPresetKey == key))
            
            local pointSize = pulse
            local pointColor = COLORS.ATTACK_POINT
            local label = "ATTACK"
            
            if isBeingDragged then
                pointSize = pulse + 3
                pointColor = {255, 255, 100, 255}
                label = "ATTACK (Dragging)"
            elseif isSelected then
                pointSize = pulse + 2
                pointColor = {255, 255, 0, 255} -- Желтый для выбранного
                label = hasAssignedUnit and "ATTACK (Selected + Active)" or "ATTACK (Selected)"
            elseif hasAssignedUnit then
                label = "ATTACK"
            end
            
            Renderer.SetDrawColor(table.unpack(pointColor))
            Renderer.DrawFilledCircle(x, y, pointSize)
            Renderer.SetDrawColor(table.unpack(COLORS.ATTACK_POINT_OUTLINE))
            Renderer.DrawOutlineCircle(x, y, pointSize + 2, 32)
            
            Renderer.SetDrawColor(255, 255, 255, 255)
            Renderer.DrawText(font, x + 10, y - 6, label)
        end
        
        -- Точка отхода
        local x2, y2, visible2 = Renderer.WorldToScreen(pullPoint)
        if visible2 then
            -- Подсветка при перетаскивании
            local isBeingDragged = state.dragging and 
                ((state.dragTarget == "selected_pull" and isSelected) or 
                 (state.dragTarget == "preset_pull" and state.dragPresetKey == key))
            
            local pointSize = pulse
            local pointColor = COLORS.PULL_POINT
            local label = "PULL"
            
            if isBeingDragged then
                pointSize = pulse + 3
                pointColor = {255, 255, 100, 255}
                label = "PULL (Dragging)"
            elseif isSelected then
                pointSize = pulse + 2
                pointColor = {255, 255, 0, 255} -- Желтый для выбранного
                label = hasAssignedUnit and "PULL (Selected + Active)" or "PULL (Selected)"
            elseif hasAssignedUnit then
                label = "PULL"
            end
            
            Renderer.SetDrawColor(table.unpack(pointColor))
            Renderer.DrawFilledCircle(x2, y2, pointSize)
            Renderer.SetDrawColor(table.unpack(COLORS.PULL_POINT_OUTLINE))
            Renderer.DrawOutlineCircle(x2, y2, pointSize + 2, 32)
            
            Renderer.SetDrawColor(255, 255, 255, 255)
            Renderer.DrawText(font, x2 + 10, y2 - 6, label)
        end
        
        -- Рисуем линию от точки ATTACK к центру campа
        if visible then
            local campCenter = Utils.getCampCenter(campData.camp)
            if campCenter then
                local cx, cy, centerVisible = Renderer.WorldToScreen(campCenter)
                if centerVisible then
                    -- Рисуем линию от точки атаки к центру campа
                    Renderer.SetDrawColor(255, 100, 100, 180) -- Красноватая линия
                    Renderer.DrawLine(x, y, cx, cy)
                    
                    -- Рисуем стрелку на конце линии (в центре campа)
                    local dx = cx - x
                    local dy = cy - y
                    local len = math.sqrt(dx * dx + dy * dy)
                    if len > 0 then
                        local ux = dx / len
                        local uy = dy / len
                        local px = -uy
                        local py = ux
                        local arrowSize = 8
                        local arrowWidth = 4
                        
                        local a1x = cx - ux * arrowSize + px * arrowWidth
                        local a1y = cy - uy * arrowSize + py * arrowWidth
                        local a2x = cx - ux * arrowSize - px * arrowWidth
                        local a2y = cy - uy * arrowSize - py * arrowWidth
                        
                        Renderer.DrawLine(cx, cy, a1x, a1y)
                        Renderer.DrawLine(cx, cy, a2x, a2y)
                    end
                end
            end
        end
    end
end

function RenderSystem.drawUnitTrajectories()
    if not RenderSystem.shouldShowVisuals() then return end
    
    for unit, camp in pairs(units.campAssignments) do
        local key = camp and Utils.generateCampKey(camp)
        local preset = key and presets[key]
        
        if preset and preset.attackPoint and preset.pullPoint then
            local attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
            local pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
            
            -- Рисуем траекторию между точками
            local x1, y1, visible1 = Renderer.WorldToScreen(attackPoint)
            local x2, y2, visible2 = Renderer.WorldToScreen(pullPoint)
            
            if visible1 and visible2 then
                Renderer.SetDrawColor(table.unpack(COLORS.TRAJECTORY))
                Renderer.DrawLine(x1, y1, x2, y2)
                
                -- Рисуем стрелку
                local dx, dy = x2 - x1, y2 - y1
                local length = math.sqrt(dx * dx + dy * dy)
                if length > 0 then
                    local ux, uy = dx / length, dy / length
                    local px, py = -uy, ux
                    local arrowSize = 12
                    local arrowWidth = 6
                    
                    local a1x = x2 - ux * arrowSize + px * arrowWidth
                    local a1y = y2 - uy * arrowSize + py * arrowWidth
                    local a2x = x2 - ux * arrowSize - px * arrowWidth
                    local a2y = y2 - uy * arrowSize - py * arrowWidth
                    
                    Renderer.DrawLine(x2, y2, a1x, a1y)
                    Renderer.DrawLine(x2, y2, a2x, a2y)
                end
            end
            
            -- Рисуем линию от Unitа к цели
            RenderSystem.drawUnitTargetLine(unit, attackPoint, pullPoint)
        end
    end
    
    -- Также рисуем траекторию для выбранного campа, даже если у него нет Assignedных units
    if state.selectedCamp and state.attackPoint and state.pullPoint then
        local x1, y1, visible1 = Renderer.WorldToScreen(state.attackPoint)
        local x2, y2, visible2 = Renderer.WorldToScreen(state.pullPoint)
        
        if visible1 and visible2 then
            Renderer.SetDrawColor(table.unpack(COLORS.TRAJECTORY))
            Renderer.DrawLine(x1, y1, x2, y2)
            
            -- Рисуем стрелку
            local dx, dy = x2 - x1, y2 - y1
            local length = math.sqrt(dx * dx + dy * dy)
            if length > 0 then
                local ux, uy = dx / length, dy / length
                local px, py = -uy, ux
                local arrowSize = 12
                local arrowWidth = 6
                
                local a1x = x2 - ux * arrowSize + px * arrowWidth
                local a1y = y2 - uy * arrowSize + py * arrowWidth
                local a2x = x2 - ux * arrowSize - px * arrowWidth
                local a2y = y2 - uy * arrowSize - py * arrowWidth
                
                Renderer.DrawLine(x2, y2, a1x, a1y)
                Renderer.DrawLine(x2, y2, a2x, a2y)
            end
        end
    end
    
    -- Рисуем траектории для всех активных camps (с autoStart), даже без Assignedных units
    local camps = Camps.GetAll()
    if camps then
        for i = 1, #camps do
            local camp = camps[i]
            local key = Utils.generateCampKey(camp)
            local preset = key and presets[key]
            local hasAutoStart = PresetManager and PresetManager.getCampAutoStart and PresetManager.getCampAutoStart(camp)
            
            -- Проверяем что это не выбранный camp (для него траектория уже нарисована выше)
            local isSelected = (state.selectedCamp == camp)
            
            -- Проверяем что у campа нет Assignedного Unitа (для таких траектория уже нарисована выше)
            local hasAssignedUnit = false
            for unit, assignedCamp in pairs(units.campAssignments) do
                if assignedCamp == camp and Entity.IsAlive(unit) then
                    hasAssignedUnit = true
                    break
                end
            end
            
            -- Рисуем траекторию только если camp активен, но не выбран и не имеет Assignedного Unitа
            if preset and preset.attackPoint and preset.pullPoint and hasAutoStart and not isSelected and not hasAssignedUnit then
                local attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
                local pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
                
                local x1, y1, visible1 = Renderer.WorldToScreen(attackPoint)
                local x2, y2, visible2 = Renderer.WorldToScreen(pullPoint)
                
                if visible1 and visible2 then
                    Renderer.SetDrawColor(table.unpack(COLORS.TRAJECTORY))
                    Renderer.DrawLine(x1, y1, x2, y2)
                    
                    -- Рисуем стрелку
                    local dx, dy = x2 - x1, y2 - y1
                    local length = math.sqrt(dx * dx + dy * dy)
                    if length > 0 then
                        local ux, uy = dx / length, dy / length
                        local px, py = -uy, ux
                        local arrowSize = 12
                        local arrowWidth = 6
                        
                        local a1x = x2 - ux * arrowSize + px * arrowWidth
                        local a1y = y2 - uy * arrowSize + py * arrowWidth
                        local a2x = x2 - ux * arrowSize - px * arrowWidth
                        local a2y = y2 - uy * arrowSize - py * arrowWidth
                        
                        Renderer.DrawLine(x2, y2, a1x, a1y)
                        Renderer.DrawLine(x2, y2, a2x, a2y)
                    end
                end
            end
        end
    end

end

function RenderSystem.drawUnitTargetLine(unit, attackPoint, pullPoint)
    local unitPos = Entity.GetAbsOrigin(unit)
    local ux, uy, unitVisible = Renderer.WorldToScreen(unitPos)
    if not unitVisible then return end
    
    -- Определяем текущую цель Unitа
    local target = RenderSystem.determineUnitTarget(unit, attackPoint, pullPoint)
    if not target then return end
    
    local tx, ty, targetVisible = Renderer.WorldToScreen(target)
    if targetVisible then
        Renderer.SetDrawColor(table.unpack(COLORS.UNIT_LINE))
        Renderer.DrawLine(ux, uy, tx, ty)
        
        -- Рисуем стрелку к цели
        local dx, dy = tx - ux, ty - uy
        local length = math.sqrt(dx * dx + dy * dy)
        if length > 0 then
            local uxv, uyv = dx / length, dy / length
            local pxv, pyv = -uyv, uxv
            local arrowSize = 10
            local arrowWidth = 5
            
            local a1x = tx - uxv * arrowSize + pxv * arrowWidth
            local a1y = ty - uyv * arrowSize + pyv * arrowWidth
            local a2x = tx - uxv * arrowSize - pxv * arrowWidth
            local a2y = ty - uyv * arrowSize - pyv * arrowWidth
            
            Renderer.DrawLine(tx, ty, a1x, a1y)
            Renderer.DrawLine(tx, ty, a2x, a2y)
        end
    end
end

function RenderSystem.determineUnitTarget(unit, attackPoint, pullPoint)
    local gameTime = Utils.getGameTime()
    local currentMinute = math.floor(gameTime / 60)
    local currentSecond = math.floor(gameTime % 60)
    
    local unitState = units.states[unit] and units.states[unit][currentMinute]
    if not unitState then return nil end
    
    local camp = units.campAssignments[unit]
    local attackSec, waitTo, attackTime = PresetManager.getCampSettings(camp)
    
    local lastAttackMinute = units.lastAttackMinute[unit]
    local inNextMinute = (lastAttackMinute ~= nil) and (currentMinute > lastAttackMinute)
    
    if inNextMinute and currentSecond < waitTo then
        return pullPoint
    elseif currentSecond < attackSec or not unitState.attackDone then
        return attackPoint
    else
        if not unitState.pullDone then
            if not units.attackTimes[unit] or GameRules.GetGameTime() >= units.attackTimes[unit] then
                return pullPoint
            end
        else
            if inNextMinute and currentSecond >= waitTo then
                return attackPoint
            else
                return pullPoint
            end
        end
    end
    
    return nil
end

function RenderSystem.drawOverlays()
    if not RenderSystem.shouldShowVisuals() then return end
    
    local overlayFont = Renderer.LoadFont("Tahoma", visualSettings.overlayFontSize:Get(), 700)
    local drawnCamps = {}
    
    -- Получаем все campы
    local allCamps = Camps.GetAll() or {}
    
    for i = 1, #allCamps do
        local camp = allCamps[i]
        local campCenter = Utils.getCampCenter(camp)
        if campCenter and not drawnCamps[camp] then
            local cx, cy, visible = Renderer.WorldToScreen(campCenter)
            if visible then
                local isActive = Utils.isCampActive(camp)
                
                if isActive then
                    -- Полный оверлей для активных camps
                    RenderSystem.drawFullCampOverlay(cx, cy, camp, overlayFont)
                else
                    -- Мини-оверлей для неактивных camps
                    RenderSystem.drawMiniCampOverlay(cx, cy, camp, overlayFont)
                end
                drawnCamps[camp] = true
            end
        end
    end
end

function RenderSystem.drawMiniCampOverlay(cx, cy, camp, font)
    local key = Utils.generateCampKey(camp)
    local preset = key and presets[key]
    
    -- Размеры мини-оверлея
    local miniWidth = 120
    local miniHeight = 40
    local overlayX = math.floor(cx - miniWidth / 2)
    local overlayY = math.floor(cy - miniHeight / 2)
    
    -- Фон мини-оверлея
    local bgOpacity = visualSettings.overlayOpacity:Get()
    Renderer.SetDrawColor(15, 15, 18, bgOpacity)
    Renderer.DrawFilledRect(overlayX, overlayY, miniWidth, miniHeight)
    
    -- Рамка
    Renderer.SetDrawColor(60, 60, 70, bgOpacity + 50)
    Renderer.DrawOutlineRect(overlayX, overlayY, miniWidth, miniHeight)
    
    -- Проверяем есть ли настройки для campа
    local hasSettings = preset and preset.attackPoint and preset.pullPoint
    
    if hasSettings then
        -- Кнопка Enable
        local buttonX = overlayX + 10
        local buttonY = overlayY + 10
        local buttonWidth = miniWidth - 20
        local buttonHeight = 20
        
        -- Фон кнопки
        Renderer.SetDrawColor(50, 150, 50, 200)
        Renderer.DrawFilledRect(buttonX, buttonY, buttonWidth, buttonHeight)
        
        -- Рамка кнопки
        Renderer.SetDrawColor(70, 200, 70, 255)
        Renderer.DrawOutlineRect(buttonX, buttonY, buttonWidth, buttonHeight)
        
        -- Текст кнопки
        Renderer.SetDrawColor(255, 255, 255, 255)
        local textX = buttonX + buttonWidth / 2 - 20
        local textY = buttonY + 3
        Renderer.DrawText(font, textX, textY, "ENABLE")
        
        -- Обработка клика
        if Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
            if Input.IsCursorInRect(buttonX, buttonY, buttonWidth, buttonHeight) then
                -- Активируем camp
                PresetManager.applyPreset(camp)
                PresetManager.setCampAutoStart(camp, true)
                
                -- Пытаемся назначить свободного creepа
                local freeUnit = Utils.findFreeUnit()
                if freeUnit then
                    UnitManager.assignUnitToCamp(freeUnit, camp)
                    print("[AutoStacker] camp активирован через мини-оверлей с Unitом")
                else
                    print("[AutoStacker] camp активирован через мини-оверлей (ожидает units)")
                end
            end
        end
    else
        -- Сообщение что camp не настроен
        Renderer.SetDrawColor(200, 200, 200, 255)
        local textX = overlayX + 10
        local textY = overlayY + 12
        Renderer.DrawText(font, textX, textY, "Not configured")
    end
end

function RenderSystem.drawFullCampOverlay(cx, cy, camp, font)
    local key = Utils.generateCampKey(camp)
    local preset = key and presets[key]
    
    -- Определяем статус campа
    local hasAttackPoint = preset and preset.attackPoint
    local hasPullPoint = preset and preset.pullPoint
    local isConfigured = hasAttackPoint and hasPullPoint
    
    -- Современные размеры и отступы
    local padding = 12
    local cornerRadius = 8
    local lineHeight = visualSettings.overlayFontSize:Get() + 6
    local headerHeight = 28
    local statusHeight = 24
    
    -- Вычисляем размеры динамически
    local overlayWidth = 280
    local baseHeight = headerHeight + statusHeight + padding
    
    -- Добавляем высоту для инструкций
    local instructionsHeight = 0
    if not isConfigured then
        local instructionCount = 0
        if not hasAttackPoint then instructionCount = instructionCount + 1 end
        if not hasPullPoint then instructionCount = instructionCount + 1 end
        if instructionCount > 0 then
            instructionsHeight = instructionCount * lineHeight + 20 -- +20 для отступов и рамки
        end
    end
    
    -- Добавляем высоту для настроек (увеличиваем для новых элементов)
    local settingsHeight = isConfigured and 120 or 0
    
    local contentHeight = baseHeight + instructionsHeight + settingsHeight
    
    local overlayX = math.floor(cx - overlayWidth / 2)
    local overlayY = math.floor(cy - 140)
    
    -- Полупрозрачный фон с современным дизайном
    local bgOpacity = math.floor(visualSettings.overlayOpacity:Get() * 0.85) -- Делаем более прозрачным
    
    -- Основной фон с закругленными углами (имитация)
    Renderer.SetDrawColor(15, 15, 18, bgOpacity)
    Renderer.DrawFilledRect(overlayX, overlayY, overlayWidth, contentHeight)
    
    -- Тонкая рамка
    Renderer.SetDrawColor(60, 60, 70, bgOpacity + 40)
    Renderer.DrawOutlineRect(overlayX, overlayY, overlayWidth, contentHeight)
    
    -- Заголовок с градиентом (имитация)
    Renderer.SetDrawColor(25, 25, 35, bgOpacity + 20)
    Renderer.DrawFilledRect(overlayX + 1, overlayY + 1, overlayWidth - 2, headerHeight)
    
    -- Текст заголовка
    Renderer.SetDrawColor(220, 220, 230, 255)
    Renderer.DrawText(font, overlayX + padding, overlayY + 8, "Camp Stacking Setup")
    
    local currentY = overlayY + headerHeight + 8
    
    -- Статус индикатор (динамический)
    local statusColor, statusText = RenderSystem.getCampStatus(camp, isConfigured)
    
    -- Статус бар
    Renderer.SetDrawColor(statusColor[1], statusColor[2], statusColor[3], bgOpacity + 30)
    Renderer.DrawFilledRect(overlayX + padding, currentY, overlayWidth - padding * 2, statusHeight)
    
    -- Текст статуса (делаем более читаемым)
    local statusTextColor = isConfigured and {255, 255, 255, 255} or statusColor -- Белый для готового, оранжевый для не готового
    Renderer.SetDrawColor(table.unpack(statusTextColor))
    Renderer.DrawText(font, overlayX + padding + 8, currentY + 6, statusText)
    
    currentY = currentY + statusHeight + 8
    
    -- Инструкции (только если не настроено)
    if not isConfigured then
        local instructionsHeight = 0
        local instructions = {}
        
        if not hasAttackPoint then
            table.insert(instructions, "1. Select creep & press [1] near camp")
        end
        
        if not hasPullPoint then
            table.insert(instructions, "2. Drag points with Ctrl+Click to adjust")
        end
        
        if hasAttackPoint and hasPullPoint then
            table.insert(instructions, "3. Enable auto-assign for automation")
        end
        
        if #instructions > 0 then
            instructionsHeight = #instructions * lineHeight + 12
            
            -- Фон для инструкций
            Renderer.SetDrawColor(20, 20, 25, bgOpacity + 20)
            Renderer.DrawFilledRect(overlayX + padding, currentY - 4, overlayWidth - padding * 2, instructionsHeight)
            
            -- Рамка для инструкций
            Renderer.SetDrawColor(50, 50, 60, bgOpacity + 30)
            Renderer.DrawOutlineRect(overlayX + padding, currentY - 4, overlayWidth - padding * 2, instructionsHeight)
            
            -- Текст инструкций
            Renderer.SetDrawColor(200, 200, 210, 255)
            for i, instruction in ipairs(instructions) do
                Renderer.DrawText(font, overlayX + padding + 8, currentY + (i - 1) * lineHeight + 4, instruction)
            end
            
            currentY = currentY + instructionsHeight + 8
        end
    end
    
    -- Рисуем настройки campа (если нужно)
    if isConfigured then
        RenderSystem.drawCampSettings(overlayX, currentY, camp, font)
        currentY = currentY + 120 -- Высота блока настроек
    end
    
    -- Кнопка Disable для активных camps
    if Utils.isCampActive(camp) then
        local buttonWidth = 80
        local buttonHeight = 25
        local buttonX = overlayX + (overlayWidth - buttonWidth) / 2
        local buttonY = currentY + 5
        
        -- Фон кнопки
        Renderer.SetDrawColor(150, 50, 50, 200)
        Renderer.DrawFilledRect(buttonX, buttonY, buttonWidth, buttonHeight)
        
        -- Рамка кнопки
        Renderer.SetDrawColor(200, 70, 70, 255)
        Renderer.DrawOutlineRect(buttonX, buttonY, buttonWidth, buttonHeight)
        
        -- Текст кнопки
        Renderer.SetDrawColor(255, 255, 255, 255)
        local textX = buttonX + buttonWidth / 2 - 25
        local textY = buttonY + 5
        Renderer.DrawText(font, textX, textY, "DISABLE")
        
        -- Обработка клика
        if Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
            if Input.IsCursorInRect(buttonX, buttonY, buttonWidth, buttonHeight) then
                -- Деактивируем camp
                for unit, assignedCamp in pairs(units.campAssignments) do
                    if assignedCamp == camp then
                        units.campAssignments[unit] = nil
                    end
                end
                
                PresetManager.setCampAutoStart(camp, false)
                print("[AutoStacker] camp деактивирован через полный оверлей")
            end
        end
    end
    
    -- Рисуем отладочную информацию если включена
    if debugSettings.showDebugInfo:Get() then
        RenderSystem.drawDebugInfo(overlayX, overlayY + contentHeight + 10, camp, font)
    end
end

function RenderSystem.drawDebugInfo(x, y, camp, font)
    local debugHeight = 120  -- Увеличиваем высоту для больше информации
    local debugWidth = CONFIG.OVERLAY_WIDTH
    
    -- Фон для отладочной информации
    Renderer.SetDrawColor(40, 40, 45, 200)
    Renderer.DrawFilledRect(x, y, debugWidth, debugHeight)
    
    -- Заголовок
    Renderer.SetDrawColor(table.unpack(COLORS.TEXT))
    Renderer.DrawText(font, x + 10, y + 5, "Debug Info:")
    
    -- Информация о campе
    local key = Utils.generateCampKey(camp)
    Renderer.DrawText(font, x + 10, y + 20, "Camp Key: " .. (key or "N/A"))
    
    -- Детальная информация о привязанных Unitах
    local unitCount = 0
    local currentY = y + 35
    
    for unit, assignedCamp in pairs(units.campAssignments) do
        if assignedCamp == camp then
            unitCount = unitCount + 1
            local isAlive = Entity.IsAlive(unit)
            local unitName = "Unknown"
            local unitClass = "Unknown"
            
            -- Получаем информацию о Unitе
            pcall(function()
                unitName = NPC.GetUnitName(unit) or "No Name"
                unitClass = Entity.GetClassName(unit) or "No Class"
            end)
            
            -- Цвет в зависимости от состояния
            if isAlive then
                Renderer.SetDrawColor(100, 255, 100, 255) -- Зеленый для живых
            else
                Renderer.SetDrawColor(255, 100, 100, 255) -- Красный для мертвых
            end
            
            Renderer.DrawText(font, x + 10, currentY, string.format("Unit %d: %s", unitCount, unitName))
            currentY = currentY + 15
            Renderer.DrawText(font, x + 10, currentY, string.format("Class: %s (%s)", unitClass, isAlive and "ALIVE" or "DEAD"))
            currentY = currentY + 15
        end
    end
    
    if unitCount == 0 then
        Renderer.SetDrawColor(255, 180, 50, 255) -- Оранжевый
        Renderer.DrawText(font, x + 10, y + 35, "No units assigned")
    end
end

function RenderSystem.drawCampSettings(x, y, camp, font)
    local attackSec, waitTo, attackTime = PresetManager.getCampSettings(camp)
    local isLocked = PresetManager.getCampLocked(camp)
    local autoStart = PresetManager.getCampAutoStart(camp)
    
    -- Фон для блока настроек (увеличиваем высоту для новых элементов)
    local settingsHeight = 120
    local settingsWidth = 280 - 24 -- overlayWidth - padding * 2
    
    Renderer.SetDrawColor(20, 20, 25, 160)
    Renderer.DrawFilledRect(x + 12, y, settingsWidth, settingsHeight)
    
    -- Рамка для блока настроек
    Renderer.SetDrawColor(50, 50, 60, 200)
    Renderer.DrawOutlineRect(x + 12, y, settingsWidth, settingsHeight)
    
    -- Компактный заголовок настроек
    Renderer.SetDrawColor(180, 180, 190, 255)
    Renderer.DrawText(font, x + 20, y + 6, "Timing Settings:")
    
    -- Замочек в правом верхнем углу
    local lockX, lockY = x + settingsWidth - 50, y + 4
    local lockSize = 20
    local lockHover = Input.IsCursorInRect(lockX, lockY, lockSize, lockSize)
    
    -- Фон замочка
    local lockBgColor = lockHover and {80, 80, 90, 220} or {60, 60, 70, 180}
    if isLocked then lockBgColor = lockHover and {120, 80, 80, 220} or {100, 60, 60, 180} end
    
    Renderer.SetDrawColor(table.unpack(lockBgColor))
    Renderer.DrawFilledRect(lockX, lockY, lockSize, lockSize)
    
    -- Рамка замочка
    local lockBorderColor = isLocked and {200, 100, 100, 255} or {120, 120, 130, 255}
    Renderer.SetDrawColor(table.unpack(lockBorderColor))
    Renderer.DrawOutlineRect(lockX, lockY, lockSize, lockSize)
    
    -- Символ замочка
    local lockTextColor = isLocked and {255, 150, 150, 255} or {200, 200, 210, 255}
    Renderer.SetDrawColor(table.unpack(lockTextColor))
    local lockSymbol = isLocked and "🔒" or "🔓"
    Renderer.DrawText(font, lockX + 3, lockY + 3, lockSymbol)
    
    -- Галочка автозапуска (увеличиваем размер чекбокса)
    local autoX, autoY = x + 20, y + 26
    local autoSize = 18
    local autoHover = Input.IsCursorInRect(autoX, autoY, autoSize + 120, autoSize)
    
    -- Чекбокс
    local checkBgColor = autoHover and {80, 80, 90, 220} or {60, 60, 70, 180}
    if autoStart then checkBgColor = autoHover and {80, 120, 80, 220} or {60, 100, 60, 180} end
    
    Renderer.SetDrawColor(table.unpack(checkBgColor))
    Renderer.DrawFilledRect(autoX, autoY, autoSize, autoSize)
    
    -- Рамка чекбокса
    local checkBorderColor = autoStart and {100, 200, 100, 255} or {120, 120, 130, 255}
    Renderer.SetDrawColor(table.unpack(checkBorderColor))
    Renderer.DrawOutlineRect(autoX, autoY, autoSize, autoSize)
    
    -- Галочка (увеличенная и более заметная)
    if autoStart then
        -- Добавляем тень для лучшей видимости
        Renderer.SetDrawColor(0, 0, 0, 120)
        Renderer.DrawText(font, autoX + 3, autoY + 2, "✓")
        -- Основная галочка - белый цвет для лучшей видимости
        Renderer.SetDrawColor(255, 255, 255, 255)
        Renderer.DrawText(font, autoX + 2, autoY + 1, "✓")
    end
    
    -- Текст автозапуска
    local autoTextColor = autoStart and {150, 255, 150, 255} or {180, 180, 190, 255}
    Renderer.SetDrawColor(table.unpack(autoTextColor))
    Renderer.DrawText(font, autoX + autoSize + 6, autoY + 2, "Auto-assign free creeps")
    
    local settingsY = y + 48
    local lineHeight = 20
    local padding = 12
    
    local function drawCompactSetting(yPos, label, value, format)
        -- Лейбл (затемняем если заблокировано)
        local labelColor = isLocked and {120, 120, 130, 255} or {180, 180, 190, 255}
        Renderer.SetDrawColor(table.unpack(labelColor))
        Renderer.DrawText(font, x + padding + 8, yPos, label)
        
        -- Значение (затемняем если заблокировано)
        local valueColor = isLocked and {150, 150, 160, 255} or {220, 220, 230, 255}
        Renderer.SetDrawColor(table.unpack(valueColor))
        local valueText = string.format(format, value)
        Renderer.DrawText(font, x + 140, yPos, valueText)
        
        -- Компактные кнопки
        local buttonSize = 18
        local minusX, minusY = x + 200, yPos - 3
        local plusX, plusY = x + 222, yPos - 3
        
        -- Проверяем ховер для интерактивности (только если не заблокировано)
        local minusHover = not isLocked and Input.IsCursorInRect(minusX, minusY, buttonSize, buttonSize)
        local plusHover = not isLocked and Input.IsCursorInRect(plusX, plusY, buttonSize, buttonSize)
        
        -- Фон кнопок с ховер эффектом (затемняем если заблокировано)
        local minusBgColor, plusBgColor
        if isLocked then
            minusBgColor = {30, 30, 35, 120}
            plusBgColor = {30, 30, 35, 120}
        else
            minusBgColor = minusHover and {65, 65, 75, 220} or {45, 45, 55, 180}
            plusBgColor = plusHover and {65, 65, 75, 220} or {45, 45, 55, 180}
        end
        
        Renderer.SetDrawColor(table.unpack(minusBgColor))
        Renderer.DrawFilledRect(minusX, minusY, buttonSize, buttonSize)
        
        Renderer.SetDrawColor(table.unpack(plusBgColor))
        Renderer.DrawFilledRect(plusX, plusY, buttonSize, buttonSize)
        
        -- Рамки кнопок с ховер эффектом (затемняем если заблокировано)
        local borderColor
        if isLocked then
            borderColor = {60, 60, 70, 150}
        else
            borderColor = minusHover and {140, 140, 150, 255} or {100, 100, 110, 255}
        end
        
        Renderer.SetDrawColor(table.unpack(borderColor))
        Renderer.DrawOutlineRect(minusX, minusY, buttonSize, buttonSize)
        
        if isLocked then
            borderColor = {60, 60, 70, 150}
        else
            borderColor = plusHover and {140, 140, 150, 255} or {100, 100, 110, 255}
        end
        Renderer.SetDrawColor(table.unpack(borderColor))
        Renderer.DrawOutlineRect(plusX, plusY, buttonSize, buttonSize)
        
        -- Символы кнопок с ховер эффектом (затемняем если заблокировано)
        local textColor
        if isLocked then
            textColor = {100, 100, 110, 150}
        else
            textColor = minusHover and {255, 255, 255, 255} or {200, 200, 210, 255}
        end
        Renderer.SetDrawColor(table.unpack(textColor))
        Renderer.DrawText(font, minusX + 6, minusY + 3, "-")
        
        if isLocked then
            textColor = {100, 100, 110, 150}
        else
            textColor = plusHover and {255, 255, 255, 255} or {200, 200, 210, 255}
        end
        Renderer.SetDrawColor(table.unpack(textColor))
        Renderer.DrawText(font, plusX + 5, plusY + 3, "+")
        
        return minusX, minusY, plusX, plusY, buttonSize
    end
    
    local y1 = settingsY
    local m1x, m1y, p1x, p1y, buttonSize = drawCompactSetting(y1, "Attack sec", attackSec, "%d")
    
    local y2 = settingsY + lineHeight
    local m2x, m2y, p2x, p2y = drawCompactSetting(y2, "Wait until", waitTo, "%d")
    
    local y3 = settingsY + lineHeight * 2
    local m3x, m3y, p3x, p3y = drawCompactSetting(y3, "Attack time", attackTime, "%.1f")
    
    -- Обработка кликов по кнопкам
    if Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
        local function inRect(rx, ry, rw, rh)
            return Input.IsCursorInRect(rx, ry, rw, rh)
        end
        
        -- Проверяем клик по замочку
        if inRect(lockX, lockY, lockSize, lockSize) then
            PresetManager.setCampLocked(camp, not isLocked)
            return -- Выходим, чтобы не обрабатывать другие клики
        end
        
        -- Проверяем клик по автозапуску
        if inRect(autoX, autoY, autoSize + 120, autoSize) then
            PresetManager.setCampAutoStart(camp, not autoStart)
            return -- Выходим, чтобы не обрабатывать другие клики
        end
        
        -- Обработка кликов по настройкам только если не заблокировано
        if not isLocked then
            local changed = false
            
            if inRect(m1x, m1y, buttonSize, buttonSize) then
                attackSec = math.max(0, math.min(59, attackSec - 1))
                changed = true
            elseif inRect(p1x, p1y, buttonSize, buttonSize) then
                attackSec = math.max(0, math.min(59, attackSec + 1))
                changed = true
            elseif inRect(m2x, m2y, buttonSize, buttonSize) then
                waitTo = math.max(0, math.min(59, waitTo - 1))
                changed = true
            elseif inRect(p2x, p2y, buttonSize, buttonSize) then
                waitTo = math.max(0, math.min(59, waitTo + 1))
                changed = true
            elseif inRect(m3x, m3y, buttonSize, buttonSize) then
                attackTime = math.max(0, math.min(2, math.floor((attackTime - 0.1) * 10 + 0.5) / 10))
                changed = true
            elseif inRect(p3x, p3y, buttonSize, buttonSize) then
                attackTime = math.max(0, math.min(2, math.floor((attackTime + 0.1) * 10 + 0.5) / 10))
                changed = true
            end
            
            if changed then
                local locked = PresetManager.getCampLocked(camp)
                local autoStart = PresetManager.getCampAutoStart(camp)
                PresetManager.saveCampSettings(camp, attackSec, waitTo, attackTime, locked, autoStart)
                PresetManager.saveCurrentPoints()
            end
        end
    end
end

-- ============================================================================
-- СИСТЕМА ВВОДА
-- ============================================================================

local InputHandler = {}

function InputHandler.handleDragging()
    -- Перетаскивание работает только когда визуалы видны
    if not RenderSystem.shouldShowVisuals() then return end
    
    local function hitTest(point)
        if not point then return false end
        local x, y, visible = Renderer.WorldToScreen(point)
        if not visible then return false end
        return Input.IsCursorInRect(x - 15, y - 15, 30, 30) -- Увеличил зону клика
    end
    
    if not state.dragging then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_LCONTROL) and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
            -- Сначала проверяем точки выбранного campа (приоритет)
            if state.selectedCamp and state.attackPoint and hitTest(state.attackPoint) then
                state.dragging = true
                state.dragTarget = "selected_attack"
                state.dragCamp = state.selectedCamp
            elseif state.selectedCamp and state.pullPoint and hitTest(state.pullPoint) then
                state.dragging = true
                state.dragTarget = "selected_pull"
                state.dragCamp = state.selectedCamp
            else
                -- Проверяем точки всех camps с Assignedными Unitами
                for unit, camp in pairs(units.campAssignments) do
                    local isAlive = false
                    pcall(function()
                        if unit and Entity.IsAlive(unit) then
                            isAlive = true
                        end
                    end)
                    
                    if isAlive then
                        local key = camp and Utils.generateCampKey(camp)
                        local preset = key and presets[key]
                        
                        if preset and preset.attackPoint and preset.pullPoint then
                            local attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
                            local pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
                            
                            if hitTest(attackPoint) then
                                state.dragging = true
                                state.dragTarget = "preset_attack"
                                state.dragCamp = camp
                                state.dragPresetKey = key
                                break
                            elseif hitTest(pullPoint) then
                                state.dragging = true
                                state.dragTarget = "preset_pull"
                                state.dragCamp = camp
                                state.dragPresetKey = key
                                break
                            end
                        end
                    end
                end
                
                -- Если не нашли среди camps с Unitами, проверяем активные campы без units
                if not state.dragging then
                    local camps = Camps.GetAll()
                    if camps then
                        for i = 1, #camps do
                            local camp = camps[i]
                            local key = Utils.generateCampKey(camp)
                            local preset = key and presets[key]
                            local hasAutoStart = PresetManager and PresetManager.getCampAutoStart and PresetManager.getCampAutoStart(camp)
                            
                            -- Проверяем что это не выбранный camp (для него уже проверили выше)
                            local isSelected = (state.selectedCamp == camp)
                            
                            -- Проверяем что у campа нет Assignedного Unitа (для таких уже проверили выше)
                            local hasAssignedUnit = false
                            for unit, assignedCamp in pairs(units.campAssignments) do
                                if assignedCamp == camp and Entity.IsAlive(unit) then
                                    hasAssignedUnit = true
                                    break
                                end
                            end
                            
                            -- Проверяем точки только если camp активен, но не выбран и не имеет Assignedного Unitа
                            if preset and preset.attackPoint and preset.pullPoint and hasAutoStart and not isSelected and not hasAssignedUnit then
                                local attackPoint = Vector(preset.attackPoint.x, preset.attackPoint.y, preset.attackPoint.z)
                                local pullPoint = Vector(preset.pullPoint.x, preset.pullPoint.y, preset.pullPoint.z)
                                
                                if hitTest(attackPoint) then
                                    state.dragging = true
                                    state.dragTarget = "preset_attack"
                                    state.dragCamp = camp
                                    state.dragPresetKey = key
                                    break
                                elseif hitTest(pullPoint) then
                                    state.dragging = true
                                    state.dragTarget = "preset_pull"
                                    state.dragCamp = camp
                                    state.dragPresetKey = key
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        local worldPos = Input.GetWorldCursorPos()
        
        if state.dragTarget == "selected_attack" and state.attackPoint then
            -- Перетаскиваем точку выбранного campа
            state.attackPoint = Vector(worldPos:GetX(), worldPos:GetY(), state.attackPoint:GetZ())
        elseif state.dragTarget == "selected_pull" and state.pullPoint then
            state.pullPoint = Vector(worldPos:GetX(), worldPos:GetY(), state.pullPoint:GetZ())
        elseif state.dragTarget == "preset_attack" and state.dragPresetKey then
            -- Перетаскиваем точку из пресета
            local preset = presets[state.dragPresetKey]
            if preset and preset.attackPoint then
                preset.attackPoint.x = worldPos:GetX()
                preset.attackPoint.y = worldPos:GetY()
                -- Z остается тот же
            end
        elseif state.dragTarget == "preset_pull" and state.dragPresetKey then
            local preset = presets[state.dragPresetKey]
            if preset and preset.pullPoint then
                preset.pullPoint.x = worldPos:GetX()
                preset.pullPoint.y = worldPos:GetY()
                -- Z остается тот же
            end
        end
        
        if Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
            -- Сохраняем изменения
            if state.dragTarget == "selected_attack" or state.dragTarget == "selected_pull" then
                PresetManager.saveCurrentPoints()
            elseif state.dragPresetKey then
                PresetManager.saveToConfig()
                print(string.format("[AutoStacker] Точка перемещена для campа %s", state.dragPresetKey))
            end
            
            -- Сбрасываем состояние перетаскивания
            state.dragging = false
            state.dragTarget = nil
            state.dragCamp = nil
            state.dragPresetKey = nil
        end
    end
end

function InputHandler.handleKeyBinds()
    -- Сброс точек
    if menuItems.resetPoints:IsPressed() then
        local prevCamp = state.selectedCamp
        if prevCamp then
            PresetManager.clearPreset(prevCamp)
        end
        
        state.attackPoint = nil
        state.pullPoint = nil
        state.selectedCamp = nil
        units.campAssignments = {}
        
        print("[AutoStacker] Точки сброшены")
    end
    
    -- Настройка и активация campа (кнопка 1)
    local enablePressed = menuItems.enableCamp:IsPressed()
    if enablePressed and not state.recordKeyPressed then
        state.recordKeyPressed = true
        InputHandler.recordPoint() -- Функция записи точек + активации
    end
    
    if not enablePressed then
        state.recordKeyPressed = false
    end
    
    -- Деактивация campа (кнопка 2)
    local disablePressed = menuItems.disableCamp:IsPressed()
    if disablePressed and not state.disableKeyPressed then
        state.disableKeyPressed = true
        InputHandler.disableCamp()
    end
    
    if not disablePressed then
        state.disableKeyPressed = false
    end
end

function InputHandler.recordPoint()
    local worldPos = Input.GetWorldCursorPos()
    print("[AutoStacker] Setting up and activating camp near cursor")
    
    -- Находим ближайший camp
    local nearCamps = Camps.InRadius(worldPos, 800)
    local camp = nil
    
    if nearCamps and #nearCamps > 0 then
        local bestCamp = nil
        local minDistance = math.huge
        
        for i = 1, #nearCamps do
            local c = nearCamps[i]
            local center = Utils.getCampCenter(c)
            if center then
                local distance = (center - worldPos):Length2D()
                if distance < minDistance then
                    minDistance = distance
                    bestCamp = c
                end
            end
        end
        camp = bestCamp
    end
    
    if not camp then
        camp = Utils.findNearestCamp(worldPos)
    end
    
    if camp then
        state.selectedCamp = camp
        PresetManager.applyPreset(camp)
        
        -- Отладочная информация
        print(string.format("[AutoStacker] После применения пресета: attackPoint=%s, pullPoint=%s", 
            tostring(state.attackPoint), tostring(state.pullPoint)))
        
        -- Привязываем выбранного Unitа к campу
        local player = Players.GetLocal()
        local selectedUnits = Player.GetSelectedUnits(player) or {}
        local bestUnit = nil
        local minDistance = math.huge
        local campCenter = Utils.getCampCenter(camp)
        
        if campCenter then
            for i = 1, #selectedUnits do
                local unit = selectedUnits[i]
                if Entity.IsAlive(unit) and not Entity.IsHero(unit) then
                    local unitPos = Entity.GetAbsOrigin(unit)
                    local distance = (unitPos - campCenter):Length2D()
                    if distance < minDistance then
                        minDistance = distance
                        bestUnit = unit
                    end
                end
            end
            
            if bestUnit then
                UnitManager.assignUnitToCamp(bestUnit, camp)
            end
        end
        
        -- Use predefined spots when available; fallback to old offset
        local campId = nil
        if type(camp.GetID) == "function" then
            campId = camp:GetID()
        end

        if not campId and campCenter then
            -- Heuristic: match by proximity to known wait points
            for id, pts in pairs(CAMP_POINTS) do
                local dx = math.abs(campCenter:GetX() - pts.wait.x)
                local dy = math.abs(campCenter:GetY() - pts.wait.y)
                if dx < 500 and dy < 500 then
                    campId = id
                    break
                end
            end
        end

        if campId and CAMP_POINTS[campId] then
            local preset = CAMP_POINTS[campId]
            if not state.attackPoint then
                state.attackPoint = Vector(preset.wait.x, preset.wait.y, preset.wait.z)
            end
            if not state.pullPoint then
                state.pullPoint = Vector(preset.pull.x, preset.pull.y, preset.pull.z)
            end
        else
            -- Fallback: offset from camp center
            if not state.attackPoint then
                state.attackPoint = campCenter and (campCenter + Vector(CONFIG.DEFAULT_OFFSET_DISTANCE, 0, 0))
            end
            if not state.pullPoint then
                state.pullPoint = campCenter and (campCenter + Vector(-CONFIG.DEFAULT_OFFSET_DISTANCE, 0, 0))
            end
        end
        
        -- ВАЖНО: Включаем автозапуск при активации campа
        PresetManager.setCampAutoStart(camp, true)
        
        PresetManager.saveCurrentPoints()
    end
end

function InputHandler.disableCamp()
    local worldPos = Input.GetWorldCursorPos()
    
    -- Находим ближайший camp
    local nearCamps = Camps.InRadius(worldPos, 800)
    local camp = nil
    
    if nearCamps and #nearCamps > 0 then
        local bestCamp = nil
        local minDistance = math.huge
        
        for i = 1, #nearCamps do
            local c = nearCamps[i]
            local center = Utils.getCampCenter(c)
            if center then
                local distance = (center - worldPos):Length2D()
                if distance < minDistance then
                    minDistance = distance
                    bestCamp = c
                end
            end
        end
        camp = bestCamp
    end
    
    if not camp then
        camp = Utils.findNearestCamp(worldPos)
    end
    
    if camp then
        -- Деактивируем camp - убираем всех Assignedных units
        local removedUnits = 0
        for unit, assignedCamp in pairs(units.campAssignments) do
            if assignedCamp == camp then
                units.campAssignments[unit] = nil
                removedUnits = removedUnits + 1
            end
        end
        
        -- Отключаем автозапуск
        PresetManager.setCampAutoStart(camp, false)
        
        local key = Utils.generateCampKey(camp)
        print(string.format("[AutoStacker] camp %s деактивирован. Убрано units: %d", key or "unknown", removedUnits))
        
        -- Если это выбранный camp, очищаем выбор (отключаем визуалы)
        if state.selectedCamp == camp then
            state.selectedCamp = nil
            state.attackPoint = nil
            state.pullPoint = nil
            print("[AutoStacker] Визуалы отключены")
        end
    else
        print("[AutoStacker] camp не найден рядом с курсором")
    end
end

-- ============================================================================
-- СИСТЕМА СТАТИСТИКИ
-- ============================================================================

local StatsManager = {}

function StatsManager.updateStats()
    -- Обновляем статистику каждые 2 секунды
    local now = GameRules.GetGameTime()
    if not StatsManager.lastUpdate or (now - StatsManager.lastUpdate) > 2.0 then
        StatsManager.lastUpdate = now
        
        -- Подсчитываем активные Unitы
        local activeUnits = UnitManager.getActiveUnits()
        statsLabels.trackedUnits:ForceLocalization("Tracked units: " .. #activeUnits)
        
        -- Подсчитываем активные campы
        local activeCamps = {}
        for unit, camp in pairs(units.campAssignments) do
            pcall(function()
                if unit and Entity.IsAlive(unit) then
                    activeCamps[camp] = true
                end
            end)
        end
        local campCount = 0
        for _ in pairs(activeCamps) do campCount = campCount + 1 end
        statsLabels.activeCamps:ForceLocalization("Active camps: " .. campCount)
        
        -- Подсчитываем сохраненные пресеты
        local presetCount = 0
        for _ in pairs(presets) do presetCount = presetCount + 1 end
        statsLabels.savedPresets:ForceLocalization("Saved presets: " .. presetCount)
    end
end

-- ============================================================================
-- СИСТЕМА АВТОЗАПУСКА
-- ============================================================================

local AutoStartManager = {}
AutoStartManager.lastAutoStartCheck = 0

function AutoStartManager.initializeAutoStartCamps()
    print("[AutoStacker] Инициализация автостарт camps...")
    local camps = Camps.GetAll() or {}
    local activatedCount = 0
    
    for i = 1, #camps do
        local camp = camps[i]
        local key = Utils.generateCampKey(camp)
        
        if key and presets[key] then
            local autoStart = PresetManager.getCampAutoStart(camp)
            local hasAttackPoint = presets[key].attackPoint
            local hasPullPoint = presets[key].pullPoint
            local isConfigured = hasAttackPoint and hasPullPoint
            
            -- Если автозапуск включен и camp настроен
            if autoStart and isConfigured then
                print("[AutoStacker] Активируем автостарт camp: " .. key)
                AutoStartManager.tryAssignFreeUnitToCamp(camp)
                activatedCount = activatedCount + 1
            end
        end
    end
    
    if activatedCount > 0 then
        print("[AutoStacker] Активировано " .. activatedCount .. " автостарт camps")
    else
        print("[AutoStacker] Нет camps с автостартом для активации")
    end
end

function AutoStartManager.checkAutoStartCamps()
    local camps = Camps.GetAll() or {}
    
    for i = 1, #camps do
        local camp = camps[i]
        local key = Utils.generateCampKey(camp)
        
        if key and presets[key] then
            local autoStart = PresetManager.getCampAutoStart(camp)
            local hasAttackPoint = presets[key].attackPoint
            local hasPullPoint = presets[key].pullPoint
            local isConfigured = hasAttackPoint and hasPullPoint
            
            -- Если автозапуск включен и camp настроен
            if autoStart and isConfigured then
                AutoStartManager.tryAssignFreeUnitToCamp(camp)
            end
        end
    end
end

function AutoStartManager.tryAssignFreeUnitToCamp(camp)
    -- Проверяем, есть ли уже Assignedный Unit для этого campа
    local hasAssignedUnit = false
    for unit, assignedCamp in pairs(units.campAssignments) do
        if assignedCamp == camp and Entity.IsAlive(unit) then
            hasAssignedUnit = true
            break
        end
    end
    
    -- Если уже есть Assignedный Unit, ничего не делаем
    if hasAssignedUnit then return end
    
    -- Ищем свободного creepа
    local freeUnit = Utils.findFreeUnit()
    if freeUnit then
        -- Назначаем creepа на camp
        units.campAssignments[freeUnit] = camp
        
        -- Добавляем в отслеживаемые Unitы если нужно
        local isTracked = false
        for i = 1, #units.tracked do
            if units.tracked[i] == freeUnit then
                isTracked = true
                break
            end
        end
        
        if not isTracked then
            table.insert(units.tracked, freeUnit)
        end
        
        print(string.format("[AutoStacker] Автостарт: Assigned Unit %s на camp %s", 
            tostring(freeUnit), Utils.generateCampKey(camp) or "unknown"))
    else
        if debugSettings.verboseLogging:Get() then
            print("[AutoStacker] Автостарт: нет свободных units для campа " .. 
                (Utils.generateCampKey(camp) or "unknown"))
        end
    end
end



function AutoStartManager.periodicAutoStartCheck()
    local currentTime = Utils.getGameTime()
    
    -- Проверяем каждые 2 секунды
    if currentTime - AutoStartManager.lastAutoStartCheck > 2.0 then
        AutoStartManager.lastAutoStartCheck = currentTime
        AutoStartManager.checkAutoStartCamps()
        
        -- Дополнительно проверяем, не появились ли новые свободные creepы
        AutoStartManager.checkForNewUnits()
    end
end

function AutoStartManager.checkForNewUnits()
    -- Проверяем все campы с автостартом, у которых нет Assignedных units
    local camps = Camps.GetAll() or {}
    
    for i = 1, #camps do
        local camp = camps[i]
        local key = Utils.generateCampKey(camp)
        
        if key and presets[key] then
            local autoStart = PresetManager.getCampAutoStart(camp)
            local hasAttackPoint = presets[key].attackPoint
            local hasPullPoint = presets[key].pullPoint
            local isConfigured = hasAttackPoint and hasPullPoint
            
            if autoStart and isConfigured then
                -- Проверяем, есть ли живой Assignedный Unit
                local hasLiveUnit = false
                for unit, assignedCamp in pairs(units.campAssignments) do
                    if assignedCamp == camp and Entity.IsAlive(unit) then
                        hasLiveUnit = true
                        break
                    end
                end
                
                -- Если нет живого Unitа, пытаемся назначить нового
                if not hasLiveUnit then
                    AutoStartManager.tryAssignFreeUnitToCamp(camp)
                end
            end
        end
    end
end

-- ============================================================================
-- ОСНОВНЫЕ ФУНКЦИИ ОБРАТНОГО ВЫЗОВА
-- ============================================================================

function OnUpdate()
    if not state.initialized then
        state.initialized = true
        pcall(PresetManager.loadFromConfig)
        UnitManager.initializeSelectedUnits()
        -- После инициализации активируем campы с автостартом
        AutoStartManager.initializeAutoStartCamps()
    end
    
    if not state.enabled then return end
    
    InputHandler.handleKeyBinds()
    UnitManager.executeUnitLogic()
    StatsManager.updateStats()
    
    -- Периодически проверяем автозапуск (каждые 2 секунды)
    AutoStartManager.periodicAutoStartCheck()
end

function OnDraw()
    if not state.enabled then return end
    
    -- Управление видимостью hotkey в зависимости от состояния conditional visuals
    conditionalVisuals.visualsHotkey:Visible(conditionalVisuals.conditionalVisuals:Get())
    
    -- Обновляем инструкции с актуальными хоткеями (только один раз при первом запуске)
    if needUpdateInstructions then
        Utils.updateInstructionLabels()
        needUpdateInstructions = false
    end
    
    InputHandler.handleDragging()
    RenderSystem.drawCampBoxes()
    RenderSystem.drawPoints()
    RenderSystem.drawUnitTrajectories()
    RenderSystem.drawOverlays()
end

function OnPrepareUnitOrders(params)
    if not state.enabled then return end
    
    local p = params or {}
    local orderType = p.order or p.orderType or p.type
    
    -- Отладка: Show ВСЕ command для отслеживаемых units
    if debugSettings.verboseLogging:Get() and orderType then
        local commandUnits = p.units or p.entities or p.selectedEntities or {}
        if p.unit or p.npc or p.entity then
            table.insert(commandUnits, p.unit or p.npc or p.entity)
        end
        
        for i = 1, #commandUnits do
            local unit = commandUnits[i]
            for j = 1, #units.tracked do
                if units.tracked[j] == unit then
                    local orderName = "UNKNOWN"
                    if orderType == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION then orderName = "MOVE"
                    elseif orderType == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE then orderName = "ATTACK_MOVE"
                    elseif orderType == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET then orderName = "ATTACK_TARGET"
                    elseif orderType == Enum.UnitOrder.DOTA_UNIT_ORDER_STOP then orderName = "STOP"
                    elseif orderType == Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION then orderName = "HOLD"
                    end
                    
                    local pos = p.position or p.pos or Vector(0,0,0)
                    print(string.format("[AutoStacker] КОМАНДА: %s для Unitа %s к (%.0f, %.0f)", 
                        orderName, tostring(unit), pos:GetX(), pos:GetY()))
                    break
                end
            end
        end
    end
    
    if not orderType then return end
    if orderType ~= Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE and 
       orderType ~= Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET then
        return
    end
    
    -- Получаем список units из command
    local commandUnits = p.units or p.entities or p.selectedEntities or {}
    if p.unit or p.npc or p.entity then
        table.insert(commandUnits, p.unit or p.npc or p.entity)
    end
    
    if #commandUnits == 0 then return end
    
    -- Проверяем, есть ли среди них отслеживаемые Unitы
    local trackedUnit = nil
    for i = 1, #commandUnits do
        local unit = commandUnits[i]
        for j = 1, #units.tracked do
            if units.tracked[j] == unit then
                trackedUnit = unit
                break
            end
        end
        if trackedUnit then break end
    end
    
    if not trackedUnit then return end
    
    -- Проверяем, разрешена ли атака в данный момент
    local currentTime = GameRules.GetGameTime()
    local gameTime = Utils.getGameTime()
    local currentMinute = math.floor(gameTime / 60)
    local currentSecond = math.floor(gameTime % 60)
    
    local allow = false
    
    -- Разрешаем атаку во время активного периода атаки
    if units.attackTimes[trackedUnit] and currentTime < units.attackTimes[trackedUnit] then
        allow = true
    end
    
    -- Разрешаем атаку в момент стакинга
    local unitState = units.states[trackedUnit] and units.states[trackedUnit][currentMinute]
    local camp = units.campAssignments[trackedUnit]
    if unitState and camp and not unitState.attackDone then
        local attackSec = PresetManager.getCampSettings(camp)
        if currentSecond == attackSec then
            allow = true
        end
    end
    
    -- Блокируем команду, если атака не разрешена
    if not allow then
        return true
    end
end

-- ============================================================================
-- ЭКСПОРТ МОДУЛЯ
-- ============================================================================

return {
    OnUpdate = OnUpdate,
    OnDraw = OnDraw,
    OnPrepareUnitOrders = OnPrepareUnitOrders
}
