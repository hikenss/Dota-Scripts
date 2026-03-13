-- ============================================
-- TUSK COMBO SCRIPT - OTIMIZADO
-- Combo: Kick -> Snowball -> Walrus Punch
-- ============================================

local my_script = {}

-- ============================================
-- MENU CONFIGURATION
-- ============================================
local first_tab = Menu.Create("Heroes", "Hero List", "Tusk")
local group = first_tab:Create("Main Settings"):Create("Walrus Kick Combo")

local ui = {}
ui.global_switch = group:Switch("Ativar Combo", false)
ui.hotkey = group:Bind("Tecla para Combo", Enum.ButtonCode.KEY_NONE, "⌨")
ui.min_distance = group:Slider("Distância mínima do inimigo ao aliado para chutar", 100, 800, 800)
ui.max_distance = group:Slider("Distância máxima do inimigo ao aliado para chutar", 1400, 6000, 5000)
ui.kick_to_techies_bombs = group:Switch("Chutar para Techies bomb", false, "panorama/images/spellicons/techies_land_mines_png.vtex_c")
ui.kick_to_chronosphere = group:Switch("Chutar para Crono esfera Void", false, "panorama/images/spellicons/faceless_void_chronosphere_png.vtex_c")
ui.ally_selector = nil

-- Linken breaker items
local linken_breaker_items_raw = {
    "item_force_staff",
    "item_heavens_halberd",
    "item_orchid",
    "item_bloodthorn",
    "item_cyclone"
}

local linken_breaker_items_localized = {}
for _, item_name in ipairs(linken_breaker_items_raw) do
    table.insert(linken_breaker_items_localized, GameLocalizer.FindItem(item_name))
end

ui.linken_breakers = group:MultiCombo("Quebrar Linken com estes itens", 
    linken_breaker_items_localized, 
    linken_breaker_items_localized)
ui.linken_breakers:ToolTip("Selecione os itens que o script usará para quebrar Linken's Sphere.")

-- ============================================
-- STATE VARIABLES
-- ============================================
local hero = nil
local local_player = nil
local script_state = "IDLE"
local combo_target_enemy = nil
local combo_target_ally = nil
local combo_target_position = nil
local blink_target_pos = nil
local last_move_order_time = 0
local kick_attempt_time = 0
local snowball_cast_time = 0

local BLINK_DAGGER_ITEMS = {
    "item_overwhelming_blink",
    "item_arcane_blink",
    "item_swift_blink",
    "item_blink"
}

local KICK_TRAVEL_DISTANCE = 1200
local CHRONOSPHERE_RADIUS = 425
local TECHIES_BOMB_EFFECT_RADIUS = 300

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function reset_state()
    script_state = "IDLE"
    combo_target_enemy = nil
    combo_target_ally = nil
    combo_target_position = nil
    blink_target_pos = nil
    kick_attempt_time = 0
    snowball_cast_time = 0
end

local function has_chronosphere_freeze_modifier(target)
    return NPC.HasModifier(target, "modifier_faceless_void_chronosphere_freeze")
        or NPC.HasModifier(target, "modifier_faceless_chronosphere_freeze")
end

local function is_in_kick_landing_window(enemy_pos, target_pos, target_area_radius)
    local distance = (enemy_pos - target_pos):Length2D()
    return math.abs(distance - KICK_TRAVEL_DISTANCE) <= target_area_radius
end

local function find_techies_bomb_target_position(enemy)
    if not ui.kick_to_techies_bombs or not ui.kick_to_techies_bombs:Get() then
        return nil
    end

    local my_team = Entity.GetTeamNum(hero)
    local enemy_pos = Entity.GetAbsOrigin(enemy)
    local best_bomb_pos = nil
    local best_distance_delta = math.huge

    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) and Entity.GetTeamNum(npc) == my_team then
            local npc_name = NPC.GetUnitName(npc)
            if npc_name
                and string.find(npc_name, "techies")
                and (string.find(npc_name, "mine") or string.find(npc_name, "bomb") or string.find(npc_name, "trap")) then

                local npc_pos = Entity.GetAbsOrigin(npc)
                local distance = (enemy_pos - npc_pos):Length2D()
                local distance_delta = math.abs(distance - KICK_TRAVEL_DISTANCE)

                if is_in_kick_landing_window(enemy_pos, npc_pos, TECHIES_BOMB_EFFECT_RADIUS)
                    and distance_delta < best_distance_delta then
                    best_distance_delta = distance_delta
                    best_bomb_pos = npc_pos
                end
            end
        end
    end

    return best_bomb_pos
end

local function find_chronosphere_target_position(enemy)
    if not ui.kick_to_chronosphere or not ui.kick_to_chronosphere:Get() then
        return nil
    end

    local enemy_pos = Entity.GetAbsOrigin(enemy)
    local frozen_count = 0
    local frozen_sum = Vector(0, 0, 0)

    for _, npc in ipairs(NPCs.GetAll()) do
        if npc and Entity.IsAlive(npc) and has_chronosphere_freeze_modifier(npc) then
            frozen_sum = frozen_sum + Entity.GetAbsOrigin(npc)
            frozen_count = frozen_count + 1
        end
    end

    if frozen_count == 0 then
        return nil
    end

    local chrono_center = frozen_sum / frozen_count
    local ally_void_nearby = false
    local my_team = Entity.GetTeamNum(hero)

    for _, ally in ipairs(Heroes.GetAll()) do
        if ally
            and Entity.IsAlive(ally)
            and not NPC.IsIllusion(ally)
            and Entity.GetTeamNum(ally) == my_team
            and NPC.GetUnitName(ally) == "npc_dota_hero_faceless_void" then

            if (Entity.GetAbsOrigin(ally) - chrono_center):Length2D() <= 900 then
                ally_void_nearby = true
                break
            end
        end
    end

    if not ally_void_nearby then
        return nil
    end

    if is_in_kick_landing_window(enemy_pos, chrono_center, CHRONOSPHERE_RADIUS) then
        return chrono_center
    end

    return nil
end

local function is_target_valid(target)
    return target 
        and Entity.IsAlive(target)
        and not NPC.IsWaitingToSpawn(target)
        and not Entity.IsDormant(target)
        and NPC.IsVisible(target)
        and not NPC.IsKillable(target) == false
end

local function get_available_blink()
    if not hero then 
        return nil 
    end
    
    for _, item_name in ipairs(BLINK_DAGGER_ITEMS) do
        local blink_item = NPC.GetItem(hero, item_name, false)
        if blink_item and Ability.IsReady(blink_item) then
            return blink_item
        end
    end
    
    return nil
end

local function populate_ally_selector()
    if not hero or ui.ally_selector then 
        return 
    end
    
    local allies_for_menu = {}
    local my_team = Entity.GetTeamNum(hero)
    
    for _, ally in ipairs(Heroes.GetAll()) do
        if ally ~= hero 
            and Entity.GetTeamNum(ally) == my_team 
            and not NPC.IsIllusion(ally) then
            table.insert(allies_for_menu, {
                Entity.GetUnitName(ally),
                "panorama/images/heroes/icons/" .. Entity.GetUnitName(ally) .. "_png.vtex_c",
                true
            })
        end
    end
    
    if #allies_for_menu > 0 then
        ui.ally_selector = group:MultiSelect("Chutar em direção a estes aliados", allies_for_menu, false)
        ui.ally_selector:DragAllowed(true)
        ui.ally_selector:ToolTip("Ative os aliados para os quais deve chutar. Prioridade da esquerda para direita (pode arrastar).")
    end
end

local function get_enemy_near_cursor()
    local slider = Menu.Find("Heroes", "", "Settings", "General", "Target Selection", "Search Range")
    local search_radius = slider and slider:Get() or 600
    local cursor_pos = Input.GetWorldCursorPos()
    local my_team = Entity.GetTeamNum(hero)
    
    local nearest_enemy = nil
    local min_dist_to_cursor = search_radius + 1
    
    for _, enemy_hero in ipairs(Heroes.GetAll()) do
        if Entity.GetTeamNum(enemy_hero) ~= my_team 
            and is_target_valid(enemy_hero)
            and not NPC.IsIllusion(enemy_hero) then
            
            local enemy_pos = Entity.GetAbsOrigin(enemy_hero)
            local dist = enemy_pos:Distance(cursor_pos)
            
            if dist <= search_radius and dist < min_dist_to_cursor then
                min_dist_to_cursor = dist
                nearest_enemy = enemy_hero
            end
        end
    end
    
    return nearest_enemy
end

local function get_best_target()
    local enemy = get_enemy_near_cursor()
    if not enemy then 
        return nil, nil 
    end

    -- Prioridade especial: Chronosphere e Techies bomb,
    -- apenas quando o alvo está no range efetivo de chute (~1200 ± área)
    local chronosphere_pos = find_chronosphere_target_position(enemy)
    if chronosphere_pos then
        return enemy, chronosphere_pos, nil
    end

    local techies_bomb_pos = find_techies_bomb_target_position(enemy)
    if techies_bomb_pos then
        return enemy, techies_bomb_pos, nil
    end

    if not ui.ally_selector then
        return enemy, nil, nil
    end
    
    local alive_allies_map = {}
    for _, ally_hero in ipairs(Heroes.GetAll()) do
        if ally_hero ~= hero 
            and Entity.GetTeamNum(ally_hero) == Entity.GetTeamNum(hero)
            and is_target_valid(ally_hero)
            and not NPC.IsIllusion(ally_hero) then
            alive_allies_map[Entity.GetUnitName(ally_hero)] = ally_hero
        end
    end
    
    local priority_list = ui.ally_selector:List()
    for _, ally_name in ipairs(priority_list) do
        if ui.ally_selector:Get(ally_name) then
            local target_ally = alive_allies_map[ally_name]
            if target_ally then
                local distance = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(target_ally)):Length2D()
                if distance >= ui.min_distance:Get() and distance <= ui.max_distance:Get() then
                    return enemy, Entity.GetAbsOrigin(target_ally), target_ally
                end
            end
        end
    end

    return enemy, nil, nil
end

local function find_linken_breaker_item()
    if not ui.linken_breakers then 
        return nil 
    end
    
    local enabled_localized_names = ui.linken_breakers:ListEnabled()
    if not enabled_localized_names or #enabled_localized_names == 0 then 
        return nil 
    end
    
    for i, raw_name in ipairs(linken_breaker_items_raw) do
        local localized_name = linken_breaker_items_localized[i]
        for _, enabled_name in ipairs(enabled_localized_names) do
            if localized_name == enabled_name then
                local item = NPC.GetItem(hero, raw_name, false)
                if item and Ability.IsReady(item) then
                    return item
                end
            end
        end
    end
    
    return nil
end

-- ============================================
-- MAIN UPDATE FUNCTION
-- ============================================

my_script.OnUpdate = function()
    -- Check if in game
    if not Engine.IsInGame() then
        if hero then
            reset_state()
            if ui.ally_selector then
                ui.ally_selector = nil
            end
            hero = nil
        end
        return
    end
    
    -- Check if script is enabled
    if not ui or not ui.global_switch or not ui.global_switch:Get() then
        if script_state ~= "IDLE" then
            reset_state()
        end
        return
    end
    
    -- Get hero
    hero = Heroes.GetLocal()
    local_player = Players.GetLocal()
    
    if not hero or not local_player or Entity.GetUnitName(hero) ~= "npc_dota_hero_tusk" then
        if script_state ~= "IDLE" then
            reset_state()
        end
        return
    end
    
    populate_ally_selector()
    
    -- Check if hotkey is pressed
    local assigned_key = ui.hotkey:Get()
    if assigned_key == Enum.ButtonCode.KEY_NONE or not Input.IsKeyDown(assigned_key) then
        if script_state ~= "IDLE" then
            reset_state()
        end
        return
    end
    
    -- ============================================
    -- STATE MACHINE
    -- ============================================
    
    if script_state == "IDLE" then
        local enemy, target_pos, target_ally_ent = get_best_target()
        local kick = NPC.GetAbility(hero, "tusk_walrus_kick")
        local snowball = NPC.GetAbility(hero, "tusk_snowball")
        local blink = get_available_blink()
        
        if not enemy or not (kick and snowball and NPC.HasScepter(hero)) then
            return
        end
        
        -- Check Linken's Sphere
        if NPC.IsLinkensProtected(enemy) and not find_linken_breaker_item() then
            local current_time = GlobalVars.GetCurTime()
            if (current_time - last_move_order_time) > 0.25 then
                NPC.MoveTo(hero, Input.GetWorldCursorPos())
                last_move_order_time = current_time
            end
            return
        end
        
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local blink_range = blink and (Ability.GetCastRange(blink) + NPC.GetCastRangeBonus(hero)) or 0
        
        -- Check if we need to move or if target position is not valid
        if not target_pos or (blink and Entity.GetAbsOrigin(hero):Distance(enemy_pos) > blink_range) then
            local current_time = GlobalVars.GetCurTime()
            if (current_time - last_move_order_time) > 0.25 then
                NPC.MoveTo(hero, Input.GetWorldCursorPos())
                last_move_order_time = current_time
            end
            return
        end
        
        -- Lock targets
        combo_target_enemy = enemy
        combo_target_position = target_pos
        combo_target_ally = target_ally_ent
        
        local kick_range = Ability.GetCastRange(kick) + NPC.GetCastRangeBonus(hero)
        local distance_to_enemy = Entity.GetAbsOrigin(hero):Distance(enemy_pos)
        
        -- Start combo
        if distance_to_enemy <= kick_range and Ability.IsReady(kick) and Ability.IsReady(snowball) then
            if NPC.IsLinkensProtected(combo_target_enemy) then
                local breaker_item = find_linken_breaker_item()
                if breaker_item then
                    Ability.CastTarget(breaker_item, combo_target_enemy)
                    script_state = "BREAKING_LINKEN"
                end
            else
                script_state = "KICKING"
                kick_attempt_time = GlobalVars.GetCurTime()
            end
        elseif blink and distance_to_enemy <= blink_range and Ability.IsReady(kick) and Ability.IsReady(snowball) then
            blink_target_pos = enemy_pos - (combo_target_position - enemy_pos):Normalized() * (NPC.GetHullRadius(enemy) + 50)
            Ability.CastPosition(blink, blink_target_pos)
            script_state = "BLINKING"
            kick_attempt_time = GlobalVars.GetCurTime()
        end
        
    elseif script_state == "BLINKING" then
        if not is_target_valid(combo_target_enemy) then
            reset_state()
            return
        end
        
        local kick = NPC.GetAbility(hero, "tusk_walrus_kick")
        if not kick then
            reset_state()
            return
        end
        
        local total_kick_range = Ability.GetCastRange(kick) + NPC.GetCastRangeBonus(hero)
        if Entity.GetAbsOrigin(hero):Distance(Entity.GetAbsOrigin(combo_target_enemy)) <= total_kick_range then
            if NPC.IsLinkensProtected(combo_target_enemy) then
                local breaker_item = find_linken_breaker_item()
                if breaker_item then
                    Ability.CastTarget(breaker_item, combo_target_enemy)
                    script_state = "BREAKING_LINKEN"
                else
                    reset_state()
                end
            else
                script_state = "KICKING"
                kick_attempt_time = GlobalVars.GetCurTime()
            end
        end
        
    elseif script_state == "BREAKING_LINKEN" then
        if not is_target_valid(combo_target_enemy) then
            reset_state()
            return
        end
        
        if not NPC.IsLinkensProtected(combo_target_enemy) then
            script_state = "KICKING"
            kick_attempt_time = GlobalVars.GetCurTime()
        end
        
    elseif script_state == "KICKING" then
        if not is_target_valid(combo_target_enemy) or not combo_target_position then
            reset_state()
            return
        end
        
        local kick = NPC.GetAbility(hero, "tusk_walrus_kick")
        local current_time = GlobalVars.GetCurTime()
        
        if kick and Ability.IsReady(kick) then
            if (current_time - kick_attempt_time) > 0.01 then
                -- Refresh target position from live ally position for accuracy
                if combo_target_ally and Entity.IsAlive(combo_target_ally) and not Entity.IsDormant(combo_target_ally) then
                    combo_target_position = Entity.GetAbsOrigin(combo_target_ally)
                end
                Player.PrepareUnitOrders(local_player, 
                    Enum.UnitOrder.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
                    nil, 
                    combo_target_position, 
                    kick, 
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, 
                    hero)
                Player.PrepareUnitOrders(local_player, 
                    Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
                    combo_target_enemy, 
                    Vector(0, 0, 0), 
                    kick, 
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, 
                    hero)
                
                -- Immediately go to snowball without waiting
                script_state = "SNOWBALLING"
            end
        elseif (current_time - kick_attempt_time) > 0.3 then
            -- Timeout - reset if kick failed
            reset_state()
        end
        
    elseif script_state == "SNOWBALLING" then
        if not is_target_valid(combo_target_enemy) then
            reset_state()
            return
        end
        
        -- Check if already in snowball
        if NPC.HasModifier(hero, "modifier_tusk_snowball_movement") then
            reset_state()
            return
        end
        
        local snowball = NPC.GetAbility(hero, "tusk_snowball")
        if snowball and Ability.IsReady(snowball) then
            Ability.CastTarget(snowball, combo_target_enemy)
            
            local snowball_launch = NPC.GetAbility(hero, "tusk_launch_snowball")
            if snowball_launch and Ability.IsReady(snowball_launch) then
                Ability.CastNoTarget(snowball_launch)
            end
        else
            reset_state()
        end
    end
end

-- ============================================
-- GAME END HANDLER
-- ============================================

my_script.OnGameEnd = function()
    reset_state()
    if ui.ally_selector then
        ui.ally_selector = nil
    end
    hero = nil
end

return my_script
