--[[
    Arc Warden Power Capture Helper
    UCZone API v2.0
    Author - Euphoria
    Visualizes optimal positions to capture both mid runes
    using the Power Capture facet (Magnetic Field pulls runes).
    Automatically casts Magnetic Field when clicking the required position.
]]

local script = {}

-- ═══════════════════════════════════════════════════════════════════════════
--  Constants
-- ═══════════════════════════════════════════════════════════════════════════

-- Mid rune positions (coordinates for Radiant and Dire sides)
local RUNE_POSITIONS = {
    top = Vector(-1818, 1233, 128),    -- Top mid rune
    bottom = Vector(1818, -1233, 128)  -- Bottom mid rune
}

-- Optimal positions to capture both runes
local CAPTURE_POSITIONS = {
    radiant = {
        Vector(-835.3, -717.5, 128),      -- Primary position for Radiant (mid)
        Vector(943.1, -2995.0, 256)       -- Secondary position for Radiant
    },
    dire = {
        Vector(273.96, 440.54, 128),      -- Primary position for Dire (mid)
        Vector(-1204.5, 2937.4, 256)      -- Secondary position for Dire
    }
}

local MAGNETIC_FIELD_RANGE = 900  -- Rune pull radius with facet
local CELL_SIZE = 26              -- Visualization cell size

-- ═══════════════════════════════════════════════════════════════════════════
--  Menu Initialization
-- ═══════════════════════════════════════════════════════════════════════════

local function InitializeUI()
    local utilityMenu = Menu.Find("Heroes", "Hero List", "Arc Warden", "Main Settings", "Utility")
    
    if not utilityMenu then
        -- Fallback: create separate menu
        local tab = Menu.Create("General", "Arc Warden Power Capture", "arc_power_capture")
        if tab and tab.Icon then
            tab:Icon("panorama/images/heroes/icons/npc_dota_hero_arc_warden_png.vtex_c")
        end
        utilityMenu = tab
    end

    local ui = {}
    
    ui.Enabled = utilityMenu:Switch("Power Capture Helper", false)
    ui.Enabled:Image("panorama/images/spellicons/arc_warden_magnetic_field_png.vtex_c")
    ui.Enabled:ToolTip("Shows optimal positions for capturing both mid runes.\nClicking a position automatically casts Magnetic Field.")
    
    ui.AutoCast = utilityMenu:Switch("Auto Cast on Click", true)
    ui.AutoCast:ToolTip("Automatically cast Magnetic Field when clicking a position")
    
    return ui
end

local UI = InitializeUI()

-- ═══════════════════════════════════════════════════════════════════════════
--  State Management
-- ═══════════════════════════════════════════════════════════════════════════

local State = {
    lastCastTime = 0,
    font = nil,
    mouseWasDown = false,
    visualAlpha = 255,
    abilityIcon = nil,
}

-- ═══════════════════════════════════════════════════════════════════════════
--  Helper Functions
-- ═══════════════════════════════════════════════════════════════════════════

local function GetAbilityIconHandle(abilityName)
    if not abilityName then return nil end
    if State.abilityIcon then return State.abilityIcon end
    local path = "panorama/images/spellicons/" .. abilityName .. "_png.vtex_c"
    local handle = Render.LoadImage(path)
    State.abilityIcon = handle
    return handle
end

local function AnimateAlpha(current, target, speed)
    if current < target then
        return math.min(current + speed, target)
    elseif current > target then
        return math.max(current - speed, target)
    end
    return current
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

local function DrawIconCell(x, y, alpha, imageHandle, scale, rounding)
    local size = CELL_SIZE
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

-- ═══════════════════════════════════════════════════════════════════════════
--  Helper Functions
-- ═══════════════════════════════════════════════════════════════════════════

local function HasPowerCaptureAspect(hero)
    -- Check if Power Capture facet is present
    -- Facet adds a modifier, or can be checked via ability
    local modifiers = NPC.GetModifiers(hero)
    if modifiers then
        for _, modifier in ipairs(modifiers) do
            local modName = Modifier.GetName(modifier)
            -- Check facet modifier
            if modName and (modName:find("arc_warden_magnetic_field_aspect") or 
                           modName:find("modifier_arc_warden_magnetic_field_aspect") or
                           modName:find("modifier_arc_warden_aspect")) then
                return true
            end
        end
    end
    
    -- Alternative check: see if facet ability exists
    -- Power Capture adds rune pulling behavior
    -- Can be validated through facet-specific ability if available
    local aspectAbility = NPC.GetAbility(hero, "arc_warden_magnetic_field_aspect")
    if aspectAbility then
        return true
    end
    
    -- If we cannot determine exactly, assume facet is present
    -- (can be changed to return false for strict checking)
    return true
end

local function IsAbilityLevelValid(ability)
    -- Ensure ability is at least level 2
    if not ability then return false end
    local level = Ability.GetLevel(ability)
    return level >= 2
end

local function GetOptimalCapturePosition(hero)
    local heroTeam = Entity.GetTeamNum(hero)
    local positions = nil
    
    -- Radiant = 2, Dire = 3
    -- In "Demo" mode team can be detected incorrectly, so check hero position
    if heroTeam == Enum.TeamNum.TEAM_RADIANT or heroTeam == 2 then
        positions = CAPTURE_POSITIONS.radiant
    elseif heroTeam == Enum.TeamNum.TEAM_DIRE or heroTeam == 3 then
        positions = CAPTURE_POSITIONS.dire
    else
        -- Fallback: detect by hero position (X < 0 = Radiant side of map)
        local heroPos = Entity.GetAbsOrigin(hero)
        if heroPos.x < 0 then
            positions = CAPTURE_POSITIONS.radiant
        else
            positions = CAPTURE_POSITIONS.dire
        end
    end
    
    -- Return all positions for the team
    return positions
end

local function CanCaptureRunes(position)
    -- Check that both runes are within capture range
    local distTop = (position - RUNE_POSITIONS.top):Length()
    local distBottom = (position - RUNE_POSITIONS.bottom):Length()
    
    return distTop <= MAGNETIC_FIELD_RANGE and distBottom <= MAGNETIC_FIELD_RANGE
end

local function IsHeroNearCapturePosition(hero, capturePos, threshold)
    local heroPos = Entity.GetAbsOrigin(hero)
    local dist = (heroPos - capturePos):Length2D()
    return dist <= threshold
end

-- ═══════════════════════════════════════════════════════════════════════════
--  Drawing Functions
-- ═══════════════════════════════════════════════════════════════════════════

local function DrawCaptureVisualization()
    if not UI.Enabled:Get() or not Engine.IsInGame() then
        return
    end
    
    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsAlive(hero) then return end
    
    -- Ensure hero is Arc Warden
    if NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then return end
    
    -- Get Magnetic Field ability
    local ability = NPC.GetAbility(hero, "arc_warden_magnetic_field")
    if not ability then return end
    
    -- Ensure ability is at least level 2
    if not IsAbilityLevelValid(ability) then return end
    
    -- Check for Power Capture facet
    if not HasPowerCaptureAspect(hero) then return end
    
    -- Alpha animation
    local targetAlpha = 255
    State.visualAlpha = AnimateAlpha(State.visualAlpha, targetAlpha, 15)
    if State.visualAlpha <= 0 then return end
    
    local alphaScale = State.visualAlpha / 255
    local color = Color(0, 255, 255, 200)  -- Cyan color for visualization
    local abilityIcon = GetAbilityIconHandle("arc_warden_magnetic_field")
    local rounding = 6
    
    -- Get all capture positions
    local capturePositions = GetOptimalCapturePosition(hero)
    
    -- Get cursor position to check hover and click
    local cursorX, cursorY = Input.GetCursorPos()
    local mouseDown = Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1)
    local justClicked = mouseDown and (not State.mouseWasDown)
    
    -- Draw all capture positions
    for i = 1, #capturePositions do
        local capturePos = capturePositions[i]
        local canCapture = CanCaptureRunes(capturePos)
        
        local screenPos, visible = Render.WorldToScreen(capturePos)
        if visible then
            local size = CELL_SIZE
            local x = screenPos.x - size / 2
            local y = screenPos.y - size / 2
            
            local isHovered = cursorX >= x and cursorX <= (x + size) and cursorY >= y and cursorY <= (y + size)
            local baseAlpha = isHovered and math.floor(230 * 0.8) or 230
            local alpha = math.floor(baseAlpha * alphaScale)
            
            if abilityIcon then
                DrawIconCell(x, y, alpha, abilityIcon, 0.88, rounding)
                
                -- Draw border
                local basePad = 2
                local iconScale = 0.88
                local inner = (size - basePad * 2)
                local iconSize = math.floor(inner * iconScale)
                local offset = math.floor((inner - iconSize) / 2)
                local pos = Vec2(x + basePad + offset + 0.5, y + basePad + 1 + offset)
                local endPos = Vec2(pos.x + iconSize, pos.y + iconSize)
                local borderColor = canCapture and Color(0, 255, 0, math.floor(200 * alphaScale)) or Color(255, 0, 0, math.floor(200 * alphaScale))
                Render.Rect(pos, endPos, borderColor, rounding, Enum.DrawFlags.None, 2)
            end
            
            -- Click handling
            if justClicked and isHovered then
                if UI.AutoCast:Get() then
                    if hero then
                        if Ability.IsCastable(ability, NPC.GetMana(hero)) then
                            local now = GameRules.GetGameTime()
                            if now - State.lastCastTime >= 1.0 then
                                local myPlayer = Players.GetLocal()
                                if myPlayer then
                                    Player.PrepareUnitOrders(
                                        myPlayer,
                                        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
                                        nil,
                                        capturePos,
                                        ability,
                                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                        hero,
                                        false, false, false, false,
                                        "arc_power_capture"
                                    )
                                    State.lastCastTime = now
                                end
                            end
                        end
                    end
                end
            end
        end
        
    end
    
    State.mouseWasDown = mouseDown
end

-- ═══════════════════════════════════════════════════════════════════════════
--  Main Logic
-- ═══════════════════════════════════════════════════════════════════════════

script.OnDraw = function()
    DrawCaptureVisualization()
end

script.OnUpdate = function()
    if not UI.Enabled:Get() or not Engine.IsInGame() then
        return
    end
    
    if not UI.AutoCast:Get() then return end
    
    local hero = Heroes.GetLocal()
    if not hero or not Entity.IsAlive(hero) then return end
    
    -- Ensure hero is Arc Warden
    if NPC.GetUnitName(hero) ~= "npc_dota_hero_arc_warden" then return end
    
    -- Get Magnetic Field ability
    local ability = NPC.GetAbility(hero, "arc_warden_magnetic_field")
    if not ability then return end
    
    -- Ensure ability is at least level 2
    if not IsAbilityLevelValid(ability) then return end
    
    -- Check for Power Capture facet
    if not HasPowerCaptureAspect(hero) then return end
    
    -- Check whether ability can be cast
    if not Ability.IsCastable(ability, NPC.GetMana(hero)) then return end
    
    -- Cooldown protection
    local now = GameRules.GetGameTime()
    if now - State.lastCastTime < 1.0 then return end
    
    -- Get all optimal positions
    local capturePositions = GetOptimalCapturePosition(hero)
    
    -- Check each position
    for i = 1, #capturePositions do
        local capturePos = capturePositions[i]
        
        -- Check hero is near capture position (within 200 units)
        if IsHeroNearCapturePosition(hero, capturePos, 200) then
            -- Check we can capture both runes
            if CanCaptureRunes(capturePos) then
                -- Cast Magnetic Field
                Ability.CastNoTarget(ability, false, false, false, "arc_power_capture")
                State.lastCastTime = now
                break
            end
        end
    end
end

script.OnGameEnd = function()
    State.lastCastTime = 0
    State.font = nil
    State.abilityIcon = nil
end

return script
