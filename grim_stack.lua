local grim_stacker = {}

local tab = Menu.Create("Heroes", "Hero List", "Grimstroke")
local group = tab:Create("Main Settings"):Create("Stacker")
local ui = {}
ui.global_switch = group:Switch("Ativado", false, "\u{f00c}")
ui.stack_bind = group:Bind("Tecla de Stack", Enum.ButtonCode.KEY_NONE)

ui.global_switch:SetCallback(function ()
    ui.stack_bind:Disabled(not ui.global_switch:Get())
end, true)

local hero = nil
local key_pressed = false
local is_moving_to_stack = false
local stack_distance_threshold = 10
local stack_search_radius = 1600
local current_stack_type = nil

local stack_cast_times = {
    [0] = 52,
    [1] = 51.5,
    [2] = 51,
    [3] = 50.5,
    [4] = 50
}

local stack_positions = {
    dire_start = Vector(4273.5400390625, -1311.2102050781, 128.0),
    dire_target_pos = Vector(3794.5102539062, -1008.2581176758, 256.0),
    dire_cast_pos = Vector(3816.2280273438, -992.85162353516, 256.0),

    radiant_start = Vector(-5193.4775390625, 1034.6090087891, 128.0),
    radiant_target_pos = Vector(-4707.978515625, 491.81787109375, 256.0),
    radiant_cast_pos = Vector(-4680.1884765625, 570.15075683594, 255.99987792969)
}   

local function IsGrimstroke()
    local hero = Heroes.GetLocal()
    return hero and NPC.GetUnitName(hero) == "npc_dota_hero_grimstroke"
end

local function GetClosestStackPosition(hero_pos)
    local dire_distance = (hero_pos - stack_positions.dire_start):Length()
    local radiant_distance = (hero_pos - stack_positions.radiant_start):Length()
    
    if dire_distance < radiant_distance then
        return "dire", stack_positions.dire_start
    else
        return "radiant", stack_positions.radiant_start
    end
end

local function GetMaxStackInRadius(hero_pos)
    local creeps = NPCs.GetAll(Enum.UnitTypeFlags.TYPE_CREEP)
    local max_stack = 0
    
    for _, creep in pairs(creeps) do
        if NPC.IsNeutral(creep) then
            local creep_pos = Entity.GetAbsOrigin(creep)
            local distance = (hero_pos - creep_pos):Length()
            
            if distance <= stack_search_radius then
                local modifier = NPC.GetModifier(creep, "modifier_stacked_neutral")
                if modifier then
                    local stack_count = Modifier.GetStackCount(modifier)
                    if stack_count > max_stack then
                        max_stack = stack_count
                    end
                end
            end
        end
    end
    
    return max_stack
end

local function ShouldCastAbility(max_stack)
    local game_time = GameRules.GetGameTime()
    local start_time = GameRules.GetGameStartTime()
    local ingame_time = game_time - start_time
    
    local seconds_in_minute = math.floor(ingame_time % 60)
    
    local cast_time = stack_cast_times[max_stack] or 50
    
    return seconds_in_minute >= cast_time
end
    
local function CastAbility(hero, stack_type)
    local ability = NPC.GetAbility(hero, "grimstroke_dark_artistry")
    
    if not ability or not Ability.IsCastable(ability, NPC.GetMana(hero)) then return end

    local target_pos, cast_pos
    
    if stack_type == "dire" then
        target_pos = stack_positions.dire_target_pos
        cast_pos = stack_positions.dire_cast_pos
    else
        target_pos = stack_positions.radiant_target_pos
        cast_pos = stack_positions.radiant_cast_pos
    end

    Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
        nil,
        target_pos,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        hero,
        nil,
        nil, 
        true
    )
    Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        cast_pos,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        hero,
        nil,
        nil, 
        true
    )
end

local function StartStacking(hero)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local stack_type, stack_position = GetClosestStackPosition(hero_pos)
    
    current_stack_type = stack_type
    NPC.MoveTo(hero, stack_position)
    is_moving_to_stack = true
end

grim_stacker.OnUpdate = function ()
    if not IsGrimstroke() or not ui.global_switch:Get() then 
        return 
    end

    hero = Heroes.GetLocal()
    if not hero then 
        return 
    end

    if Hero.GetFacetID(hero) ~= 2 then 
        return 
    end

    local is_key_down = Input.IsKeyDown(ui.stack_bind:Get())
    
    if is_key_down and not key_pressed then
        StartStacking(hero)
        key_pressed = true
    elseif not is_key_down then
        key_pressed = false
        is_moving_to_stack = false
        current_stack_type = nil
    end
    
    if is_moving_to_stack and current_stack_type then
        local hero_pos = Entity.GetAbsOrigin(hero)
        local target_position = current_stack_type == "dire" and stack_positions.dire_start or stack_positions.radiant_start
        local distance = (hero_pos - target_position):Length()
        
        if distance <= stack_distance_threshold then
            local max_stack = GetMaxStackInRadius(hero_pos)
            
            if ShouldCastAbility(max_stack) then
                CastAbility(hero, current_stack_type)
                is_moving_to_stack = false
            end
        end
    end
end

grim_stacker.OnPrepareUnitOrders = function(data)
    if not IsGrimstroke() or not ui.global_switch:Get() then return end
    
    hero = Heroes.GetLocal()
    if not hero or Hero.GetFacetID(hero) ~= 2 then return end
    
    if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION and
       data.npc == hero and
       Input.IsKeyDown(ui.stack_bind:Get()) then
        
        local dire_dist = (data.position - stack_positions.dire_start):Length()
        local radiant_dist = (data.position - stack_positions.radiant_start):Length()
        
        if dire_dist < 10 or radiant_dist < 10 then
            if key_pressed then
                return false
            end
        end
    end
end

return grim_stacker