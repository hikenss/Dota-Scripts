local marci_dlc = {}

local menu = Menu.Create("Heroes", "Hero List", "Marci", "Marci Helper")
local main_group = menu:Create("Main")

local ui = {}
ui.enabled = main_group:Switch("Ativar Script", true, "\u{f0e7}")
ui.force_staff = main_group:Switch("Interceptar Force Staff", true, "panorama/images/items/force_staff_png.vtex_c")
ui.phoenix_dive = main_group:Switch("Phoenix Icarus Dive", true, "panorama/images/spellicons/phoenix_icarus_dive_png.vtex_c")
ui.techies_blast = main_group:Switch("Techies Blast Off", true, "panorama/images/spellicons/techies_suicide_png.vtex_c")
ui.slark_pounce = main_group:Switch("Slark Pounce", true, "panorama/images/spellicons/slark_pounce_png.vtex_c")
ui.zeus_jump = main_group:Switch("Zeus Heavenly Jump", true, "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c")
ui.timber_chain = main_group:Switch("Timber Chain", true, "panorama/images/spellicons/shredder_timber_chain_png.vtex_c")
ui.earthshaker_totem = main_group:Switch("ES Enchant Totem (Aghs)", true, "panorama/images/spellicons/earthshaker_enchant_totem_png.vtex_c")
ui.spirit_breaker_charge = main_group:Switch("SB Charge of Darkness", true, "panorama/images/spellicons/spirit_breaker_charge_of_darkness_png.vtex_c")
ui.dispose_range = main_group:Slider("Alcance Máximo de Dispose", 150, 400, 300, function(value) return tostring(value) end)
ui.reaction_time = main_group:Slider("Tempo de Reação (ms)", 0, 300, 50, function(value) return tostring(value) .. "ms" end)
ui.auto_face_target = main_group:Switch("Virar Auto para Alvo", true, "\u{f01e}")
ui.debug_enabled = main_group:Switch("Modo Debug", false, "\u{f188}")
ui.show_notifications = main_group:Switch("Mostrar Notificações", true, "\u{f0f3}")

local INTERCEPT_CONFIGS = {
    ["modifier_item_forcestaff_active"] = {
        name = "Force Staff",
        ui_key = "force_staff",
        predict_distance = 600,
        cast_delay = 0,
        priority = 2
    },
    ["modifier_phoenix_icarus_dive"] = {
        name = "Phoenix Dive",
        ui_key = "phoenix_dive",
        predict_distance = 400,
        cast_delay = 0,
        priority = 3
    },
    ["modifier_techies_suicide_leap"] = {
        name = "Techies Blast Off",
        ui_key = "techies_blast",
        predict_distance = 600,
        cast_delay = 0,
        priority = 3,
        intercept_trajectory = true
    },
    ["modifier_slark_pounce"] = {
        name = "Slark Pounce",
        ui_key = "slark_pounce",
        predict_distance = 700,
        cast_delay = 0,
        priority = 3
    },
    ["modifier_zuus_heavenly_jump"] = {
        name = "Zeus Heavenly Jump",
        ui_key = "zeus_jump",
        predict_distance = 800,
        cast_delay = 0.4,
        priority = 3
    },
    ["modifier_shredder_timber_chain"] = {
        name = "Timber Chain",
        ui_key = "timber_chain",
        predict_distance = 800,
        cast_delay = 0,
        priority = 3,
        intercept_trajectory = true
    },
    ["modifier_spirit_breaker_charge_of_darkness"] = {
        name = "SB Charge",
        ui_key = "spirit_breaker_charge",
        predict_distance = 1000,
        cast_delay = 0,
        priority = 3,
        intercept_trajectory = true
    }
}

local my_hero = nil
local dispose_ability = nil
local last_dispose_time = 0
local active_targets = {}

local function get_local_hero()
    return Heroes.GetLocal()
end

local function initialize_marci()
    my_hero = get_local_hero()
    if not my_hero or NPC.GetUnitName(my_hero) ~= "npc_dota_hero_marci" then
        return false
    end
    dispose_ability = NPC.GetAbility(my_hero, "marci_grapple")
    if not dispose_ability then
        return false
    end
    return true
end

local function check_earthshaker_aghs_totem(entity)
    if not entity or NPC.GetUnitName(entity) ~= "npc_dota_hero_earthshaker" then
        return false
    end
    local aghs_item = NPC.GetItem(entity, "item_ultimate_scepter")
    if not aghs_item then
        if not NPC.HasModifier(entity, "modifier_item_ultimate_scepter_consumed") then
            return false
        end
    end
    return true
end

local function quick_predict_position(target, config)
    if not target or not Entity.IsAlive(target) then
        return nil
    end
    local current_pos = Entity.GetAbsOrigin(target)
    if not NPC.IsRunning(target) then
        return current_pos
    end
    local rotation = Entity.GetAbsRotation(target)
    local forward = rotation:GetForward():Normalized()
    if string.find(config.name, "Phoenix") then
        return current_pos + (forward * 400)
    end
    if string.find(config.name, "Zeus") then
        return current_pos + (forward * config.predict_distance * 0.5)
    end
    return current_pos + (forward * config.predict_distance * 0.3)
end

local function can_use_dispose()
    if not dispose_ability or not my_hero then
        return false
    end
    if not Ability.IsCastable(dispose_ability, NPC.GetMana(my_hero)) then
        return false
    end
    local current_time = GameRules.GetGameTime()
    local reaction_delay = ui.reaction_time:Get() / 1000.0
    if current_time - last_dispose_time < reaction_delay then
        return false
    end
    return true
end

local function execute_dispose_on_target(target, config, custom_pos)
    if not can_use_dispose() then
        return false
    end
    local my_pos = Entity.GetAbsOrigin(my_hero)
    local target_pos = custom_pos or quick_predict_position(target, config) or Entity.GetAbsOrigin(target)
    local distance = (target_pos - my_pos):Length2D()
    local max_range = ui.dispose_range:Get()
    if ui.debug_enabled:Get() then
        print(string.format("Dispose attempt: %s, distance: %d, max: %d", config.name, math.floor(distance), max_range))
    end
    if distance > max_range then
        if ui.debug_enabled:Get() then
            print("Target too far for Dispose")
        end
        return false
    end
    if ui.auto_face_target:Get() then
        Player.PrepareUnitOrders(
            Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            target_pos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            my_hero
        )
    end
    Ability.CastTarget(dispose_ability, target)
    last_dispose_time = GameRules.GetGameTime()
    if ui.show_notifications:Get() then
        print(string.format("Dispose used on %s (%s) - %dm", NPC.GetUnitName(target), config.name, math.floor(distance)))
    end
    return true
end

local function is_target_in_dispose_range(target)
    if not target or not Entity.IsAlive(target) or not my_hero then
        return false
    end
    local my_pos = Entity.GetAbsOrigin(my_hero)
    local target_pos = Entity.GetAbsOrigin(target)
    local distance = (target_pos - my_pos):Length2D()
    return distance <= ui.dispose_range:Get()
end

function marci_dlc.OnModifierCreate(entity, modifier)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    local mod_name = Modifier.GetName(modifier)
    local config = INTERCEPT_CONFIGS[mod_name]
    if not config or not ui[config.ui_key]:Get() then
        return
    end
    if ui.debug_enabled:Get() then
        print("Modifier detected: " .. mod_name .. " on " .. NPC.GetUnitName(entity))
    end
    if config.name == "Force Staff" then
        local ability = Modifier.GetAbility(modifier)
        if ability then
            local owner = Ability.GetOwner(ability)
            if not owner or Entity.IsSameTeam(owner, my_hero) then
                return
            end
        end
    end
    if not entity or not Entity.IsAlive(entity) or Entity.IsSameTeam(entity, my_hero) then
        return
    end
    if config.name == "Techies Blast Off" and NPC.GetUnitName(entity) == "npc_dota_hero_techies" then
        local entity_id = Entity.GetIndex(entity)
        active_targets[entity_id] = {
            entity = entity,
            config = config,
            start_time = GameRules.GetGameTime(),
            modifier = modifier
        }
        if ui.debug_enabled:Get() then
            print("Techies added to active tracking: " .. entity_id)
        end
        return
    end
    execute_dispose_on_target(entity, config)
end

function marci_dlc.OnModifierDestroy(entity, modifier)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    local mod_name = Modifier.GetName(modifier)
    if mod_name == "modifier_techies_suicide_leap" then
        local entity_id = Entity.GetIndex(entity)
        if active_targets[entity_id] then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Techies removed from tracking: " .. entity_id)
            end
        end
    end
end

function marci_dlc.OnPrepareUnitOrders(order)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    if not ui.earthshaker_totem:Get() then
        return
    end
    if order.ability and Ability.GetName(order.ability) == "earthshaker_enchant_totem" then
        local caster = order.npc
        if not caster or not Entity.IsAlive(caster) or Entity.IsSameTeam(caster, my_hero) then
            return
        end
        if not check_earthshaker_aghs_totem(caster) then
            if ui.debug_enabled:Get() then
                print("Earthshaker without Aghanim's Scepter - skipping")
            end
            return
        end
        if ui.debug_enabled:Get() then
            print("Earthshaker Enchant Totem with Aghs detected!")
        end
        local es_pos = Entity.GetAbsOrigin(caster)
        local my_pos = Entity.GetAbsOrigin(my_hero)
        local distance = (es_pos - my_pos):Length2D()
        if distance <= 900 then
            execute_dispose_on_target(caster, {
                name = "Earthshaker Aghs Totem",
                predict_distance = 200,
                priority = 3
            })
        end
    end
end

function marci_dlc.OnUpdate()
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    local current_time = GameRules.GetGameTime()
    for entity_id, target_data in pairs(active_targets) do
        local entity = target_data.entity
        if not entity or not Entity.IsAlive(entity) then
            active_targets[entity_id] = nil
            goto continue
        end
        if not NPC.HasModifier(entity, "modifier_techies_suicide_leap") then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Techies modifier disappeared, removing from tracking")
            end
            goto continue
        end
        if is_target_in_dispose_range(entity) then
            if ui.debug_enabled:Get() then
                print("Techies in Dispose range! Executing intercept")
            end
            if execute_dispose_on_target(entity, target_data.config) then
                active_targets[entity_id] = nil
            end
        else
            if ui.debug_enabled:Get() then
                local my_pos = Entity.GetAbsOrigin(my_hero)
                local target_pos = Entity.GetAbsOrigin(entity)
                local distance = (target_pos - my_pos):Length2D()
                print(string.format("Techies tracked: distance %d, need %d", math.floor(distance), ui.dispose_range:Get()))
            end
        end
        if current_time - target_data.start_time > 10.0 then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Removing outdated target from tracking")
            end
        end
        ::continue::
    end
end

return marci_dlc