---@diagnostic disable: undefined-global, param-type-mismatch, inject-field

local ZeusHJ = {}

-- MENU
local menu = Menu.Create("Heroes", "Hero List", "Zeus", "Heavenly Jump Helper", "Main")
local ui = {}

ui.enable        = menu:Switch("Enable Script", true)
ui.enable:Icon("\u{f00c}")

ui.key           = menu:Bind("Heavenly Jump Button", Enum.ButtonCode.KEY_E)
ui.key:Icon("\u{f0c9}")

ui.only_zeus     = menu:Switch("Only for Zeus", true)
ui.only_zeus:Icon("\u{f1ce}")

local info_group = Menu.Create("Heroes", "Hero List", "Zeus", "Heavenly Jump Helper", "Information")
info_group:Label("Больше скриптов - discord.gg/glitch-realm")

-- Constants 
local ABILITY_NAME = "zuus_heavenly_jump"
local MAX_ANGLE = 15  -- Degrees
local MAX_WAIT_MS = 300  -- Milliseconds

-- Internal variables
local pending_cast = false
local turn_start_time = 0
local target_position = nil

local function GetHeavenlyJump(hero)
    if not hero then return nil end
    return NPC.GetAbility(hero, ABILITY_NAME)
end

-- Check angle between hero direction and target
local function IsHeroFacingTarget(hero, targetPos, maxAngle)
    local heroPos = Entity.GetAbsOrigin(hero)
    local heroAngles = Entity.GetAbsRotation(hero)
    local heroYaw = heroAngles:GetYaw() -- Hero rotation angle in degrees
    
    -- Vector to target
    local toTarget = targetPos - heroPos
    local targetYaw = math.deg(math.atan2(toTarget:GetY(), toTarget:GetX()))
    
    -- Angle difference
    local angleDiff = math.abs(heroYaw - targetYaw)
    
    -- Normalize angle (0-360)
    if angleDiff > 180 then
        angleDiff = 360 - angleDiff
    end
    
    return angleDiff <= maxAngle
end

-- Command "Move to direction"
local function MoveToDirection(hero, targetPos)
    local myPlayer = Players.GetLocal()
    if not myPlayer then return end
    
    Player.PrepareUnitOrders(
        myPlayer,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_DIRECTION,
        nil,              -- target
        targetPos,        -- position
        nil,              -- ability
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        hero,             -- npc
        false,            -- queue
        false             -- show effects
    )
end

function ZeusHJ.OnUpdate()
    if not ui.enable or not ui.enable:Get() then return end

    local myHero = Heroes.GetLocal()
    if not myHero or not Entity.IsAlive(myHero) then
        pending_cast = false
        return
    end

    if ui.only_zeus:Get() and NPC.GetUnitName(myHero) ~= "npc_dota_hero_zuus" then
        pending_cast = false
        return
    end

    local now = GameRules.GetGameTime() * 1000

    -- STEP 2: Wait for turn and cast
    if pending_cast then
        local elapsed = now - turn_start_time
        local hj = GetHeavenlyJump(myHero)
        
        if not hj or not Ability.IsCastable(hj, NPC.GetMana(myHero)) then
            print("[ZeusHJ] Ability lost or not castable")
            pending_cast = false
            return
        end
        
        -- Check rotation angle
        if IsHeroFacingTarget(myHero, target_position, MAX_ANGLE) then
            Ability.CastNoTarget(hj)
            print("[ZeusHJ] Casted after " .. math.floor(elapsed) .. " ms (angle OK)")
            pending_cast = false
            target_position = nil
            return
        end
        
        -- Timeout - force cast
        if elapsed >= MAX_WAIT_MS then
            Ability.CastNoTarget(hj)
            print("[ZeusHJ] Force casted after timeout (" .. math.floor(elapsed) .. " ms)")
            pending_cast = false
            target_position = nil
        end
        
        return
    end

    -- STEP 1: Button press
    if Input.IsKeyDownOnce(ui.key:Get()) then
        local hj = GetHeavenlyJump(myHero)
        if not hj then
            print("[ZeusHJ] Ability not found: " .. ABILITY_NAME)
            return
        end

        if not Ability.IsCastable(hj, NPC.GetMana(myHero)) then
            print("[ZeusHJ] Ability not castable (CD/mana)")
            return
        end

        local cursorPos = Input.GetWorldCursorPos()
        if not cursorPos then
            print("[ZeusHJ] No cursor position")
            return
        end

        target_position = cursorPos 
        -- Using "Move to direction"
        MoveToDirection(myHero, cursorPos)

        pending_cast = true
        turn_start_time = now
        
        print("[ZeusHJ] Turn initiated (MOVE_TO_DIRECTION)")
    end
end

-- Visuals
function ZeusHJ.OnDraw()
    if not ui.enable or not ui.enable:Get() then return end
    if not pending_cast or not target_position then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end

    local heroPos = Entity.GetAbsOrigin(myHero)
    local a, visA = heroPos:ToScreen()
    local b, visB = target_position:ToScreen()

    if visA and visB then
        local isFacing = IsHeroFacingTarget(myHero, target_position, MAX_ANGLE)
        local color = isFacing and Color(0, 255, 0, 255)
        
        Render.Line(a, b, color, 2)
        Render.Circle(b, 10, color)
        
        -- Angle indicator
        local elapsed = GameRules.GetGameTime() * 1000 - turn_start_time
        local text = string.format("Turning... %dms", math.floor(elapsed))
        if isFacing then
            text = "READY!"
        end
    end
end

return ZeusHJ