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
ui.max_distance = group:Slider("Distância máxima do inimigo ao aliado para chutar", 1400, 2200, 2000)
ui.use_walrus_punch = group:Switch("Usar Walrus Punch após Snowball", true)
ui.ally_selector = nil

-- Linken breaker items
local linken_breaker_items_raw = {
    "item_urn_of_shadows",
    "item_spirit_vessel",
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

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function reset_state()
    script_state = "IDLE"
    combo_target_enemy = nil
    combo_target_ally = nil
    blink_target_pos = nil
    kick_attempt_time = 0
    snowball_cast_time = 0
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
    if not ui.ally_selector then 
        return nil, nil 
    end
    
    local enemy = get_enemy_near_cursor()
    if not enemy then 
        return nil, nil 
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
                    return enemy, target_ally
                end
            end
        end
    end
    
    return enemy, nil
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
        local enemy, ally = get_best_target()
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
        
        -- Check if we need to move or if ally is not valid
        if not ally or (blink and Entity.GetAbsOrigin(hero):Distance(enemy_pos) > blink_range) then
            local current_time = GlobalVars.GetCurTime()
            if (current_time - last_move_order_time) > 0.25 then
                NPC.MoveTo(hero, Input.GetWorldCursorPos())
                last_move_order_time = current_time
            end
            return
        end
        
        -- Lock targets
        combo_target_enemy = enemy
        combo_target_ally = ally
        
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
            local ally_pos = Entity.GetAbsOrigin(ally)
            blink_target_pos = enemy_pos - (ally_pos - enemy_pos):Normalized() * (NPC.GetHullRadius(enemy) + 50)
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
        if not is_target_valid(combo_target_enemy) or not is_target_valid(combo_target_ally) then
            reset_state()
            return
        end
        
        -- Check if kick landed
        if NPC.HasModifier(combo_target_enemy, "modifier_tusk_walrus_kick_air_time") then
            script_state = "SNOWBALLING"
            return
        end
        
        local kick = NPC.GetAbility(hero, "tusk_walrus_kick")
        local current_time = GlobalVars.GetCurTime()
        
        if kick and Ability.IsReady(kick) then
            if (current_time - kick_attempt_time) > 0.01 then
                Player.PrepareUnitOrders(local_player, 
                    Enum.UnitOrder.DOTA_UNIT_ORDER_VECTOR_TARGET_POSITION,
                    nil, 
                    Entity.GetAbsOrigin(combo_target_ally), 
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
                kick_attempt_time = current_time
            end
        elseif (current_time - kick_attempt_time) > 0.1 then
            -- Fallback to snowball if kick failed
            local snowball = NPC.GetAbility(hero, "tusk_snowball")
            if snowball and Ability.IsReady(snowball) and Entity.GetAbsOrigin(hero):Distance(Entity.GetAbsOrigin(combo_target_enemy)) <= 1400 then
                script_state = "SNOWBALLING"
            end
        end
        
    elseif script_state == "SNOWBALLING" then
        if not is_target_valid(combo_target_enemy) then
            reset_state()
            return
        end
        
        -- Check if already in snowball
        if NPC.HasModifier(hero, "modifier_tusk_snowball_movement") then
            script_state = "WAITING_SNOWBALL_END"
            snowball_cast_time = GlobalVars.GetCurTime()
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
        
    elseif script_state == "WAITING_SNOWBALL_END" then
        -- Wait for snowball to finish
        if not NPC.HasModifier(hero, "modifier_tusk_snowball_movement") then
            -- Snowball finished, use Walrus Punch if enabled
            if ui.use_walrus_punch and ui.use_walrus_punch:Get() and is_target_valid(combo_target_enemy) then
                script_state = "USING_WALRUS_PUNCH"
            else
                reset_state()
            end
        end
        
    elseif script_state == "USING_WALRUS_PUNCH" then
        if not is_target_valid(combo_target_enemy) then
            reset_state()
            return
        end
        
        local walrus_punch = NPC.GetAbility(hero, "tusk_walrus_punch")
        if walrus_punch and Ability.IsReady(walrus_punch) then
            local punch_range = Ability.GetCastRange(walrus_punch) + NPC.GetCastRangeBonus(hero)
            local distance = Entity.GetAbsOrigin(hero):Distance(Entity.GetAbsOrigin(combo_target_enemy))
            
            if distance <= punch_range then
                Ability.CastTarget(walrus_punch, combo_target_enemy)
            end
        end
        
        reset_state()
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
