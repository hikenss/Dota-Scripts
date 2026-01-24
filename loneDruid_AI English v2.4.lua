-- ============================================================================
-- Dota 2 Lone Druid Bear AI Script (Optimized & Smart CS)
-- Automated AI for controlling Spirit Bear with advanced combat and utility
-- ============================================================================

local agent_script = {}
agent_script.ui = {}

-- ============================================================================
-- STATE DEFINITIONS
-- ============================================================================
local STATES = {
    FOLLOWING = "FOLLOWING",
    PATROLLING = "PATROLLING",
    FIGHTING = "FIGHTING",
    SEARCHING = "SEARCHING",
    FARMING = "FARMING",
    LANE_HARASS = "LANE_HARASS",
    MANUAL_OVERRIDE = "MANUAL",
    INTERRUPTING = "INTERRUPTING"
}

-- ============================================================================
-- GLOBAL VARIABLES
-- ============================================================================
local my_hero, local_player, font, agent_manager = nil, nil, nil, {}

local FOUNTAIN_LOCATIONS = {
    [Enum.TeamNum.TEAM_RADIANT] = Vector(-7019, -6534, 384),
    [Enum.TeamNum.TEAM_DIRE] = Vector(6846, 6251, 384)
}

local enemy_tracker = {
    last_known_positions = {},
    last_update_time = 0
}

local patrol_pattern = {
    last_hero_position = nil,
    last_update_time = 0,
    update_interval = 0.1
}

local force_patrol = {
    last_key_state = false
}

local follow_hero_attack = {
    enabled = false,
    target = nil,
    lock_until = 0
}

local courier_target_preference = 1

-- ============================================================================
-- UTILITY: ATTACK DETECTION
-- ============================================================================
local function IsTargetingUnit(attacker, target)
    if not attacker or not target or not Entity.IsAlive(attacker) then return false end
    if not NPC.IsAttacking(attacker) then return false end
    
    local attacker_pos = Entity.GetAbsOrigin(attacker)
    local target_pos = Entity.GetAbsOrigin(target)
    
    -- Check Range
    local range = NPC.GetAttackRange(attacker) + 150
    if attacker_pos:Distance(target_pos) > range then return false end
    
    -- Check Facing Angle (Dot Product)
    local forward = Entity.GetAbsRotation(attacker):GetForward()
    local to_target = (target_pos - attacker_pos):Normalized()
    
    return forward:Dot(to_target) > 0.75 
end

-- ============================================================================
-- DELIVERY MANAGER MODULE
-- ============================================================================
local DeliveryManager = {
    isActive = false,
    target = nil,
    state = "IDLE",
    stateStartTime = 0,
    lastInventoryCount = 0
}

function DeliveryManager:StartDelivery(deliveryTarget)
    local courier = Couriers.GetLocal()
    if not courier or not Entity.IsAlive(courier) then return end
    
    self.isActive = true
    self.target = deliveryTarget
    self.state = "INIT"
    self.stateStartTime = GlobalVars.GetCurTime()
    
    local hasStashItems = false
    if my_hero then
        for i = 9, 14 do
            local stashItem = NPC.GetItemByIndex(my_hero, i, false)
            if stashItem then
                hasStashItems = true
                break
            end
        end
    end
    
    if hasStashItems then
        self:Action_CollectStash(courier)
    else
        self:Action_DeliverItems(courier)
    end
end

function DeliveryManager:Action_CollectStash(courier)
    self.state = "COLLECTING_STASH"
    self.stateStartTime = GlobalVars.GetCurTime()
    
    local takeStashAbility = NPC.GetAbility(courier, "courier_take_stash_items")
    if takeStashAbility and Ability.IsReady(takeStashAbility) then
        Ability.CastNoTarget(takeStashAbility)
    end
end

function DeliveryManager:Action_DeliverItems(courier)
    self.state = "DELIVERING"
    self.stateStartTime = GlobalVars.GetCurTime()
    
    local itemsToDeliver = {}
    for i = 0, 8 do
        local item = NPC.GetItemByIndex(courier, i, false)
        if item then
            local itemName = Ability.GetName(item)
            if itemName ~= "courier_shield" and 
               itemName ~= "courier_burst" and 
               itemName ~= "courier_go_to_secret_shop" then
                table.insert(itemsToDeliver, item)
            end
        end
    end
    
    if #itemsToDeliver == 0 then
        self:StopDelivery()
        return
    end
    
    local firstItem = true
    for _, item in ipairs(itemsToDeliver) do
        Player.PrepareUnitOrders(
            Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_GIVE_ITEM,
            self.target,
            nil,
            item,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            courier,
            not firstItem,
            true
        )
        firstItem = false
    end
    
    local local_team = Entity.GetTeamNum(courier)
    local fountain_pos = FOUNTAIN_LOCATIONS[local_team]
    if fountain_pos then
        Player.PrepareUnitOrders(
            Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            fountain_pos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            courier,
            true,
            true
        )
    end
end

function DeliveryManager:StopDelivery()
    self.isActive = false
    self.state = "IDLE"
    self.target = nil
end

function DeliveryManager:OnUpdate()
    if not self.isActive then return end
    
    local courier = Couriers.GetLocal()
    if not courier or not Entity.IsAlive(courier) then
        self:StopDelivery()
        return
    end
    
    if self.target and not Entity.IsAlive(self.target) then
        self:StopDelivery()
        return
    end
    
    local currentTime = GlobalVars.GetCurTime()
    
    if self.state == "COLLECTING_STASH" then
        local hasItems = false
        for i = 0, 8 do
            if NPC.GetItemByIndex(courier, i, false) then
                hasItems = true
                break
            end
        end
        
        if hasItems then
             self:Action_DeliverItems(courier)
             return
        end
        
        if currentTime > self.stateStartTime + 5.0 then
            self:Action_DeliverItems(courier)
            return
        end
        
    elseif self.state == "DELIVERING" then
        local hasItems = false
        for i = 0, 8 do
            local item = NPC.GetItemByIndex(courier, i, false)
            if item then
                local name = Ability.GetName(item)
                if name ~= "courier_shield" and name ~= "courier_burst" then
                    hasItems = true
                    break
                end
            end
        end
        
        if not hasItems then
            self:StopDelivery()
        end
        
        if currentTime > self.stateStartTime + 60.0 then
            self:StopDelivery()
        end
    end
end

function DeliveryManager:OnGameEnd()
    self:StopDelivery()
end

-- ============================================================================
-- COURIER PANEL MODULE
-- ============================================================================
local CourierPanelModule = {
    ui = {},
    panel_size = Vec2(160, 55),
    font = nil,
    dragging = false,
    drag_offset = Vec2(0, 0)
}

function CourierPanelModule:Init(courier_group)
    self.font = Render.LoadFont("Arial", 14, Enum.FontCreate.FONTFLAG_OUTLINE)
    self.ui.pos_x = courier_group:Slider("Panel Position X", 0, Render.ScreenSize().x, Render.ScreenSize().x * 0.85, "%.0f")
    self.ui.pos_y = courier_group:Slider("Panel Position Y", 0, Render.ScreenSize().y, Render.ScreenSize().y * 0.85, "%.0f")
end

function CourierPanelModule:OnDraw()
    local local_hero_on_draw = Heroes.GetLocal()
    if not local_hero_on_draw then return end
    
    local is_lone_druid = (NPC.GetUnitName(local_hero_on_draw) == "npc_dota_hero_lone_druid")
    if not agent_script.ui.enable_courier_utility:Get() or not is_lone_druid then
        return
    end
    
    local panel_pos = Vec2(self.ui.pos_x:Get(), self.ui.pos_y:Get())
    local panel_end_pos = panel_pos + self.panel_size
    local rounding = 6.0
    
    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
        local mousePos = Input.GetCursorPos()
        if not self.dragging then
             if Input.IsCursorInRect(panel_pos.x, panel_pos.y, self.panel_size.x, self.panel_size.y) then
                 self.dragging = true
                 self.drag_offset = panel_pos - mousePos
             end
        else
             local newPos = mousePos + self.drag_offset
             self.ui.pos_x:Set(newPos.x)
             self.ui.pos_y:Set(newPos.y)
             panel_pos = newPos
             panel_end_pos = panel_pos + self.panel_size
        end
    else
        self.dragging = false
    end
    
    Render.FilledRect(panel_pos, panel_end_pos, Color(30, 35, 40, 240), rounding)
    Render.OutlineGradient(panel_pos, panel_end_pos, Color(0, 0, 0, 200), Color(0, 0, 0, 200), Color(0, 0, 0, 200), Color(0, 0, 0, 200), rounding, Enum.DrawFlags.None, 1.0)
    Render.Text(self.font, 14, "Courier Delivery:", panel_pos + Vec2(10, 5), Color(200, 200, 200, 255))
    
    local switch_rect_start = panel_pos + Vec2(10, 25)
    local switch_width = self.panel_size.x - 20
    local switch_height = 22
    local switch_rect_end = switch_rect_start + Vec2(switch_width, switch_height)
    
    local is_hero_pref = (courier_target_preference == 1)
    
    Render.FilledRect(switch_rect_start, switch_rect_end, Color(20, 20, 20, 255), 4.0)
    
    local active_start = is_hero_pref and switch_rect_start or (switch_rect_start + Vec2(switch_width/2, 0))
    local active_end = is_hero_pref and (switch_rect_start + Vec2(switch_width/2, switch_height)) or switch_rect_end
    
    Render.FilledRect(active_start, active_end, Color(60, 100, 160, 255), 4.0)
    Render.OutlineGradient(active_start, active_end, Color(100, 150, 220, 255), Color(100, 150, 220, 255), Color(100, 150, 220, 255), Color(100, 150, 220, 255), 4.0, Enum.DrawFlags.None, 1.0)
    
    local hero_text_size = Render.TextSize(self.font, 14, "HERO")
    local bear_text_size = Render.TextSize(self.font, 14, "BEAR")
    
    Render.Text(self.font, 14, "HERO", switch_rect_start + Vec2((switch_width/2 - hero_text_size.x)/2, 4), is_hero_pref and Color(255,255,255,255) or Color(100,100,100,255))
    Render.Text(self.font, 14, "BEAR", switch_rect_start + Vec2(switch_width/2 + (switch_width/2 - bear_text_size.x)/2, 4), not is_hero_pref and Color(255,255,255,255) or Color(100,100,100,255))
    
    if Input.IsCursorInRect(switch_rect_start.x, switch_rect_start.y, switch_width, switch_height) and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
        courier_target_preference = (courier_target_preference == 1) and 2 or 1
    end
end

function CourierPanelModule:OnGameEnd()
end

-- ============================================================================
-- ORDER INTERCEPTOR MODULE
-- ============================================================================
local OrderInterceptorModule = {}

function OrderInterceptorModule:CheckForCourierTransferOrder(data)
    if not my_hero or NPC.GetUnitName(my_hero) ~= "npc_dota_hero_lone_druid" then return true end
    if not agent_script.ui.enable_courier_utility:Get() or not data.ability then return true end
    
    local ability_name = Ability.GetName(data.ability)
    if ability_name ~= "courier_take_stash_and_transfer_items" and 
       ability_name ~= "courier_transfer_items" and
       ability_name ~= "courier_take_stash_items" then
        return true
    end
    
    local target_unit = my_hero
    if courier_target_preference == 2 then
        local bear = NPC.GetAbility(my_hero, "lone_druid_spirit_bear") and 
                     CustomEntities.GetSpiritBear(NPC.GetAbility(my_hero, "lone_druid_spirit_bear")) or nil
        if bear and Entity.IsAlive(bear) then
            target_unit = bear
        end
    end
    
    DeliveryManager:StartDelivery(target_unit)
    return false
end

-- ============================================================================
-- ASSIST MODULE
-- ============================================================================
local AssistModule = {}

function AssistModule.OnPlayerOrder(data)
    if not agent_script.ui.enable:Get() or not my_hero then
        return
    end
    
    for _, agent in pairs(agent_manager) do
        if agent.state == STATES.FIGHTING or agent.state == STATES.INTERRUPTING then
            return
        end
    end
    
    local farm_target = nil
    
    if data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET and 
       data.target and NPC.IsCreep(data.target) and not NPC.IsLaneCreep(data.target) then
        farm_target = data.target
    elseif data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE then
        local hero_pos = Entity.GetAbsOrigin(my_hero)
        local potential_creeps = NPCs.InRadius(
            hero_pos, 1200,
            Entity.GetTeamNum(my_hero),
            Enum.TeamType.TEAM_ENEMY
        )
        
        local closest_creep = nil
        local min_dist = 99999
        for _, creep in ipairs(potential_creeps) do
            if NPC.IsCreep(creep) and not NPC.IsLaneCreep(creep) and Entity.IsAlive(creep) then
                local dist = hero_pos:Distance(Entity.GetAbsOrigin(creep))
                if dist < min_dist then
                    min_dist = dist
                    closest_creep = creep
                end
            end
        end
        farm_target = closest_creep
    end
    
    if farm_target then
        for _, agent in pairs(agent_manager) do
            if agent and agent.unit and Entity.IsAlive(agent.unit) then
                agent.state = STATES.FARMING
                agent.target = farm_target
                agent.thought = "Helping to farm"
                agent.manual_override_until = 0
            end
        end
    end
end

-- ============================================================================
-- ENEMY TRACKING UTILITIES
-- ============================================================================

function UpdateEnemyPositions()
    local current_time = GlobalVars.GetCurTime()
    
    if current_time - enemy_tracker.last_update_time < 0.5 then
        return
    end
    
    enemy_tracker.last_update_time = current_time
    
    if not my_hero then return end
    
    for _, hero in pairs(Heroes.GetAll()) do
        if not Entity.IsSameTeam(hero, my_hero) and 
           Entity.IsAlive(hero) and 
           NPC.IsVisible(hero) and 
           not NPC.IsIllusion(hero) then
            local hero_index = Entity.GetIndex(hero)
            enemy_tracker.last_known_positions[hero_index] = {
                position = Entity.GetAbsOrigin(hero),
                time = current_time
            }
        end
    end
end

function GetDirectionToNearestEnemy(from_position)
    if not my_hero or not from_position then
        return nil
    end
    
    local nearest_enemy_pos = nil
    local min_distance = 99999
    local current_time = GlobalVars.GetCurTime()
    
    for hero_index, data in pairs(enemy_tracker.last_known_positions) do
        if current_time - data.time < 10.0 then
            local distance = from_position:Distance(data.position)
            if distance < min_distance then
                min_distance = distance
                nearest_enemy_pos = data.position
            end
        end
    end
    
    if nearest_enemy_pos then
        local direction = (nearest_enemy_pos - from_position):Normalized()
        return direction
    end
    
    return nil
end

-- ============================================================================
-- MENU INITIALIZATION
-- ============================================================================
do
    local main_tab = Menu.Create("Heroes", "Hero List", "Lone Druid")
    if main_tab then
        local main_group = main_tab:Create("Main Settings")
        
        local settings_group = main_group:Create("Bear AI")
        agent_script.ui.enable = settings_group:Switch(
            "Enable AI for Bear", true,
            "panorama/images/heroes/icons/npc_dota_hero_lone_druid_png.vtex_c"
        )
        agent_script.ui.enable:ToolTip("Fully enables or disables the script logic for the bear.")
        
        agent_script.ui.debug_draw = settings_group:Switch("Display Debug", true, "\u{f05a}")
        agent_script.ui.debug_draw:ToolTip("Shows the state, target, and thoughts of the bear in the game.")
        
        agent_script.ui.enable_by_timer = settings_group:Switch("Enable by Timer", false, "\u{f017}")
        agent_script.ui.enable_by_timer:ToolTip("If enabled, the bear AI (except delivery assistant) activates only after the specified minute.")
        
        agent_script.ui.activation_minute = settings_group:Slider("Activation Minute", 1, 15, 5, "%d min")
        agent_script.ui.activation_minute:ToolTip("Sets the game time minute after which the AI will start working.")
        
        agent_script.ui.game_phase = settings_group:Slider("Game Phase", 1, 3, 1, "%.0f")
        agent_script.ui.game_phase:ToolTip("Adjusts bear behavior for game phase:\n1 = Laning (Harass/CS, 1100 range, tower safe)\n2 = Mid Game (Aggressive, 1500 range, patrol, no tower avoid)\n3 = Aghs Late Game (Very aggressive, 2500 range, patrol, no tower avoid)")
        
        agent_script.ui.follow_distance = settings_group:Slider("Follow Distance", 200, 500, 300, "%d")
        agent_script.ui.follow_distance:ToolTip("The distance at which the bear will follow the hero in the idle state")

        agent_script.ui.harass_leash_range = settings_group:Slider("Harass Leash Range", 500, 2000, 1100, "%d")
        agent_script.ui.harass_leash_range:ToolTip("Maximum distance from Lone Druid before the bear returns during harassment mode.")
        
        agent_script.ui.patrol_distance = settings_group:Slider("Patrol Distance", 200, 1100, 400, "%d")
        agent_script.ui.patrol_distance:ToolTip("Distance ahead of hero the bear will patrol (only active in Mid/Late game phases)")
        
        agent_script.ui.fetch_min_range = settings_group:Slider("Fetch Min Range", 100, 2000, 800, "%d")
        agent_script.ui.fetch_min_range:ToolTip("Bear will only use Fetch if the distance to Lone Druid is greater than this value.")
        
        agent_script.ui.lane_harass_mode = settings_group:Switch("Lane Harass Mode", false, "\u{f05b}")
        agent_script.ui.lane_harass_mode:ToolTip("Automatically manages laning: Last hits, Denies, and Harasses enemy heroes safely.")
        
        agent_script.ui.max_creep_aggro = settings_group:Slider("Max Creep Aggro", 2, 6, 3, "%d")
        agent_script.ui.max_creep_aggro:ToolTip("Bear will retreat if attacked by more than this many creeps.")

        agent_script.ui.hero_attack_tolerance = settings_group:Slider("Hero Attack Tolerance", 0, 5, 0, "%d hits")
        agent_script.ui.hero_attack_tolerance:ToolTip("How many attacks from an enemy hero the bear will tolerate before retreating in Harass Mode.")

        agent_script.ui.cs_retreat_time = settings_group:Slider("CS Retreat Duration", 0.5, 3.0, 1.0, "%.1fs")
        agent_script.ui.cs_retreat_time:ToolTip("How long the bear retreats towards fountain after taking hero damage while CSing.")

        agent_script.ui.defend_radius = settings_group:Slider("Defend Druid Radius", 100, 800, 300, "%d")
        agent_script.ui.defend_radius:ToolTip("If an enemy hero is this close to Lone Druid, the bear will ignore retreat logic/tower safety to attack them.")

        agent_script.ui.auto_skill_on_entangle = settings_group:Switch(
            "Auto-Skill on Entangle", true,
            "panorama/images/spellicons/lone_druid_spirit_bear_entangle_png.vtex_c"
        )
        agent_script.ui.auto_skill_on_entangle:ToolTip("Automatically level up Spirit Bear ability if possible and enemy is entangled")
        
        agent_script.ui.follow_hero_attack = settings_group:Switch("Follow Hero Attack Target", true, "\u{f05b}")
        agent_script.ui.follow_hero_attack:ToolTip("When enabled, bear will immediately attack the same target as Lone Druid")
        
        local keybind_group = main_group:Create("Keybinds")
        agent_script.ui.force_patrol_key = keybind_group:Bind("Force Aggressive Patrol", Enum.ButtonCode.KEY_NONE)
        agent_script.ui.force_patrol_key:ToolTip("When pressed, immediately forces bear into aggressive patrol mode, overriding current state.\nPress again to return to normal AI behavior.")
        
        local attack_items_group = main_group:Create("Attack Items")
        agent_script.ui.item_multiselect = attack_items_group:MultiSelect("Bear uses:", {
            {"item_diffusa", "panorama/images/items/diffusal_blade_png.vtex_c", true},
            {"item_disperser", "panorama/images/items/disperser_png.vtex_c", true},
            {"item_orchid", "panorama/images/items/orchid_png.vtex_c", true},
            {"item_bloodthorn", "panorama/images/items/bloodthorn_png.vtex_c", true},
            {"item_harpoon", "panorama/images/items/harpoon_png.vtex_c", true},
            {"item_abyssal_blade", "panorama/images/items/abyssal_blade_png.vtex_c", true},
            {"item_mask_of_madness", "panorama/images/items/mask_of_madness_png.vtex_c", true},
            {"item_black_king_bar", "panorama/images/items/black_king_bar_png.vtex_c", true}
        }, true)
        agent_script.ui.item_multiselect:ToolTip("Select items that the bear will use in combat.")
        
        local save_group = main_group:Create("Save Abilities")
        agent_script.ui.enable_roar = save_group:Switch(
            "Use Savage Roar (defense)", true,
            "panorama/images/spellicons/lone_druid_savage_roar_png.vtex_c"
        )
        agent_script.ui.enable_roar:ToolTip("Allows the bear to use Savage Roar to save the druid if shard is purchased.")
        
        agent_script.ui.enable_disperser_save = save_group:Switch(
            "Use Disperser (defense)", true,
            "panorama/images/items/disperser_png.vtex_c"
        )
        agent_script.ui.enable_disperser_save:ToolTip("Allows the bear to use Disperser on the druid to remove negative effects.")
        
        local interrupt_group = main_group:Create("Interrupts")
        agent_script.ui.auto_interrupt_casts = interrupt_group:Switch("Interrupt Casts", true, "\u{f73c}")
        agent_script.ui.auto_interrupt_casts:ToolTip("Enables automatic interruption of enemy abilities (Enigma ult, CM ult).")
        
        agent_script.ui.interrupt_tools_multiselect = interrupt_group:MultiSelect("What to interrupt with:", {
            {"orchid_bloodthorn", "panorama/images/items/orchid_png.vtex_c", true},
            {"savage_roar", "panorama/images/spellicons/lone_druid_savage_roar_png.vtex_c", true}
        }, true)
        agent_script.ui.interrupt_tools_multiselect:ToolTip("Select which abilities and items will be used to interrupt casts.")
        
        local courier_group = main_group:Create("Courier Utility")
        agent_script.ui.enable_courier_utility = courier_group:Switch("Enable Delivery Assistant", true, "\u{f0d1}")
        agent_script.ui.enable_courier_utility:ToolTip("Intercepts courier delivery orders and offers choice of target (hero or bear). Automatically collects items from stash.")
        
        CourierPanelModule:Init(courier_group)
        
        agent_script.ui.enable_courier_utility:SetCallback(function()
            local enabled = agent_script.ui.enable_courier_utility:Get()
            CourierPanelModule.ui.pos_x:Disabled(not enabled)
            CourierPanelModule.ui.pos_y:Disabled(not enabled)
        end, true)
    end
end

-- ============================================================================
-- THREAT TRACKING
-- ============================================================================
local threat_list = {}

-- ============================================================================
-- AGENT CLASS
-- ============================================================================
local Agent = {}
Agent.__index = Agent

function Agent.new(unit)
    return setmetatable({
        unit = unit,
        handle = Entity.GetIndex(unit),
        state = STATES.FOLLOWING,
        target = nil,
        target_score = 0,
        thought = "Initialization...",
        next_action_time = 0,
        manual_override_until = 0,
        hero_target_locked = false,
        last_seen_pos = nil,
        search_end_time = 0,
        damage_history = {},
        retreat_until = 0,
        retreat_type = "NONE",
        last_attack_time = 0,
        last_tower_retreat = 0,
        recent_hero_hits = 0,
        last_hero_hit_time = 0,
        -- New fields for Organic Hovering
        hover_target_pos = nil,
        hover_expiry_time = 0,
        -- New field for Patrol Throttling
        last_patrol_target = nil
    }, Agent)
end

function Agent:UseAbilityOrItem(name, target, is_item)
    local ability = is_item and NPC.GetItem(self.unit, name) or NPC.GetAbility(self.unit, name)
    if not (ability and Ability.IsReady(ability)) then
        return false
    end
    
    if target then
        Ability.CastTarget(ability, target)
    else
        Ability.CastNoTarget(ability)
    end
    
    return true
end

function Agent:Attack(target)
    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
        target,
        nil,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        self.unit
    )
end

function Agent:MoveTo(position)
    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
        nil,
        position,
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        self.unit
    )
end

function Agent:HoldPosition()
    Player.PrepareUnitOrders(
        local_player,
        Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION,
        nil,
        Entity.GetAbsOrigin(self.unit),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        self.unit
    )
end

-- ============================================================================
-- ACTION HANDLERS
-- ============================================================================
local Actions = {}

function Actions.ExecuteSAVING_LOGIC(agent)
    if not my_hero or not (NPC.IsSilenced(my_hero) or NPC.HasState(my_hero, Enum.ModifierState.MODIFIER_STATE_ROOTED)) then
        return false
    end
    
    if agent_script.ui.enable_disperser_save:Get() and 
       agent:UseAbilityOrItem("item_disperser", my_hero, true) then
        agent.thought = "Removing debuffs from druid"
        return true
    end
    
    if agent_script.ui.enable_roar:Get() and 
       NPC.HasShard(my_hero) and 
       agent:UseAbilityOrItem("lone_druid_savage_roar_bear", nil, false) then
        agent.thought = "Saving druid"
        return true
    end
    
    return false
end

function Actions.ExecuteFOLLOWING(agent)
    if ShouldUseAggressivePatrol() then
        agent.state = STATES.PATROLLING
        return Actions.ExecutePATROLLING(agent)
    end
    
    if my_hero and Entity.IsAlive(my_hero) then
        local follow_dist = agent_script.ui.follow_distance:Get()
        local bear_pos = Entity.GetAbsOrigin(agent.unit)
        local hero_pos = Entity.GetAbsOrigin(my_hero)
        
        if bear_pos:Distance(hero_pos) > follow_dist then
            -- Avoid micro-stuttering: only move if significantly far
            if bear_pos:Distance(hero_pos) > follow_dist + 50 then
                agent:MoveTo(hero_pos)
                agent.thought = "Following."
            end
        else
            agent:HoldPosition()
            agent.thought = "Waiting."
        end
        return true
    end
    return false
end

function Actions.ExecutePATROLLING(agent)
    if not ShouldUseAggressivePatrol() then
        agent.state = STATES.FOLLOWING
        return Actions.ExecuteFOLLOWING(agent)
    end
    
    if my_hero and Entity.IsAlive(my_hero) then
        local hero_pos = Entity.GetAbsOrigin(my_hero)
        local bear_pos = Entity.GetAbsOrigin(agent.unit)
        local patrol_distance = agent_script.ui.patrol_distance:Get()
        
        local hero_forward = Entity.GetAbsRotation(my_hero):GetForward():Normalized()
        local move_dir = hero_forward
        
        -- Default to Front Patrol
        agent.thought = "Patrol (Front)"
        
        -- 1. Scan for enemies within 2500 Range
        local enemies = Heroes.GetAll()
        local nearest_enemy_pos = nil
        local nearest_dist = 99999
        local enemy_in_range = false
        
        for _, enemy in pairs(enemies) do
            if not Entity.IsSameTeam(enemy, my_hero) and Entity.IsAlive(enemy) and NPC.IsVisible(enemy) and not NPC.IsIllusion(enemy) then
                local enemy_pos = Entity.GetAbsOrigin(enemy)
                local dist = hero_pos:Distance(enemy_pos)
                
                -- Only consider angling if within 2500 range
                if dist <= 2500 then
                    enemy_in_range = true
                    if dist < nearest_dist then
                        nearest_dist = dist
                        nearest_enemy_pos = enemy_pos
                    end
                end
            end
        end
        
        -- 2. Determine Patrol Vector (Angled vs Front vs Rear)
        local final_patrol_dist = patrol_distance
        
        if enemy_in_range and nearest_enemy_pos then
             local to_enemy = (nearest_enemy_pos - hero_pos):Normalized()
             local dot = to_enemy:Dot(hero_forward)
             
             -- Rear Guard Logic (Enemy behind and close)
             if dot < -0.3 and nearest_dist < 900 then
                 move_dir = to_enemy -- Move towards enemy (behind hero)
                 agent.thought = "Guarding Rear"
                 final_patrol_dist = 250 -- Keep rear guard closer
             else
                 -- Angled Logic
                 if dot > -0.2 then
                    move_dir = (hero_forward + to_enemy):Normalized()
                    agent.thought = "Patrol (Angled)"
                 else
                    -- Enemy is flanking wide or behind but far, stay front
                    agent.thought = "Patrol (Front)"
                 end
             end
        end
        
        local target_pos = hero_pos + (move_dir * final_patrol_dist)
        
        -- 3. Input Throttling / Click Reduction
        -- Only issue a new move command if the target position has changed significantly
        -- or if the bear is lagging too far behind.
        
        local dist_change = 0
        if agent.last_patrol_target then
            dist_change = target_pos:Distance(agent.last_patrol_target)
        else
            dist_change = 9999 -- Force update if no previous target
        end
        
        local dist_bear_to_ideal = bear_pos:Distance(target_pos)
        
        -- Thresholds:
        -- Update if the ideal position moved > 150 units (Hero moved/turned significantly)
        -- OR if the bear is > 200 units further than it should be (Catch up)
        if dist_change > 150 or dist_bear_to_ideal > (final_patrol_dist + 200) then
            agent:MoveTo(target_pos)
            agent.last_patrol_target = target_pos
        end
        
        return true
    end
    return false
end

function Actions.ExecuteINTERRUPTING(agent)
    local target = agent.target
    if not target or not Entity.IsAlive(target) then
        agent.state = STATES.FOLLOWING
        return false
    end
    
    local enemy_activity = NPC.GetActivity(target)
    local casting_ability = NPC.GetChannellingAbility(target) or NPC.GetAbilityByActivity(target, enemy_activity)
    local is_casting_or_channeling = (enemy_activity >= Enum.GameActivity.ACT_DOTA_CAST_ABILITY_1 and 
                                     enemy_activity <= Enum.GameActivity.ACT_DOTA_CAST_ABILITY_7) or 
                                     NPC.IsChannellingAbility(target)
    
    if not is_casting_or_channeling then
        agent.state = STATES.FOLLOWING
        return false
    end
    
    agent.thought = "Interrupting " .. (casting_ability and Ability.GetName(casting_ability) or "cast") .. "!"
    
    local used_interrupt = false
    
    if not used_interrupt and agent_script.ui.interrupt_tools_multiselect:Get("orchid_bloodthorn") then
        if agent:UseAbilityOrItem("item_bloodthorn", target, true) then
            used_interrupt = true
        elseif agent:UseAbilityOrItem("item_orchid", target, true) then
            used_interrupt = true
        end
    end
    
    if not used_interrupt and 
       agent_script.ui.interrupt_tools_multiselect:Get("savage_roar") and 
       NPC.HasShard(my_hero) then
        local bear_roar = NPC.GetAbility(agent.unit, "lone_druid_savage_roar_bear")
        local hero_roar = NPC.GetAbility(my_hero, "lone_druid_savage_roar")
        
        if (bear_roar and Ability.IsReady(bear_roar)) or 
           (hero_roar and Ability.IsReady(hero_roar)) then
            local distance = Entity.GetAbsOrigin(agent.unit):Distance(Entity.GetAbsOrigin(target))
            if distance > 325 then
                agent:MoveTo(Entity.GetAbsOrigin(target))
                agent.thought = "Closing in for roar"
                return true
            else
                if agent:UseAbilityOrItem("lone_druid_savage_roar_bear", nil, false) then
                    used_interrupt = true
                elseif hero_roar and Ability.IsReady(hero_roar) then
                    Ability.CastNoTarget(hero_roar)
                    used_interrupt = true
                end
            end
        end
    end
    
    if used_interrupt then
        agent.state = STATES.FOLLOWING
        return true
    end
    
    return false
end

function Actions.ExecuteSEARCHING(agent)
    local current_time = GlobalVars.GetCurTime()
    
    if current_time > agent.search_end_time then
        if ShouldUseAggressivePatrol() then
            agent.state = STATES.PATROLLING
        else
            agent.state = STATES.FOLLOWING
        end
        agent.target = nil
        agent.hero_target_locked = false 
        agent.thought = "Search timed out (Lock Cleared)"
        return false
    end

    if my_hero and Entity.IsAlive(my_hero) then
        local dist_to_hero = Entity.GetAbsOrigin(agent.unit):Distance(Entity.GetAbsOrigin(my_hero))
        if dist_to_hero > 1100 then
             agent.state = STATES.FOLLOWING
             agent.thought = "Search aborted (Too far)"
             return false
        end
    end

    if agent.last_seen_pos then
         local dist_to_target = Entity.GetAbsOrigin(agent.unit):Distance(agent.last_seen_pos)
         if dist_to_target > 50 then
             agent:MoveTo(agent.last_seen_pos)
             agent.thought = string.format("Searching... (%.1fs)", agent.search_end_time - current_time)
         else
             agent:HoldPosition()
             agent.thought = "Searching... (Scanning)"
         end
    end
    
    return true
end

-- ============================================================================
-- SMART CS CALCULATOR (HELPER)
-- ============================================================================
local function GetHitDetails(bear, target)
    local bear_pos = Entity.GetAbsOrigin(bear)
    local target_pos = Entity.GetAbsOrigin(target)
    
    -- Bear stats
    local min_dmg = NPC.GetMinDamage(bear)
    local bonus_dmg = NPC.GetBonusDamage(bear)
    local bear_dmg = min_dmg + bonus_dmg
    
    local movespeed = NPC.GetMoveSpeed(bear)
    local distance = bear_pos:Distance(target_pos)
    local attack_range = NPC.GetAttackRange(bear) + NPC.GetHullRadius(bear) + NPC.GetHullRadius(target)
    
    -- Time Calculation
    local time_to_reach = 0
    if distance > attack_range then
        time_to_reach = (distance - attack_range) / movespeed
    end
    
    -- Turn Rate estimation (simplified) + Attack Point (Spirit Bear ~0.43s)
    -- Reduced buffer slightly for snappier reaction
    local attack_point = 0.43
    local total_delay = time_to_reach + attack_point
    
    -- Estimate Creep HP at time of impact
    local current_hp = Entity.GetHealth(target)
    local incoming_dps = 0
    
    -- Very basic heuristic: how many things are attacking it?
    local enemies_of_target = NPCs.InRadius(target_pos, 800, Entity.GetTeamNum(target), Enum.TeamType.TEAM_ENEMY)
    for _, e in ipairs(enemies_of_target) do
        if IsTargetingUnit(e, target) then
            if NPC.IsTower(e) then incoming_dps = incoming_dps + 100
            elseif NPC.IsLaneCreep(e) then incoming_dps = incoming_dps + 21
            elseif NPC.IsHero(e) then incoming_dps = incoming_dps + 60 end
        end
    end
    
    local predicted_hp = current_hp - (incoming_dps * total_delay)
    
    return predicted_hp, bear_dmg, total_delay, current_hp
end

-- ============================================================================
-- LANE HARASSMENT LOGIC (OPTIMIZED & SMART CS)
-- ============================================================================
function Actions.ExecuteLANE_HARASS(agent)
    local bear = agent.unit
    local bear_pos = Entity.GetAbsOrigin(bear)
    local druid_pos = Entity.GetAbsOrigin(my_hero)
    local my_team = Entity.GetTeamNum(bear)
    local current_time = GlobalVars.GetCurTime()
    
    local TETHER_LIMIT = 1100
    local RETREAT_DURATION = agent_script.ui.cs_retreat_time:Get()
    local DEFEND_RADIUS = agent_script.ui.defend_radius:Get()
    local LEASH_RANGE = agent_script.ui.harass_leash_range:Get()
    local MAX_CREEP_AGGRO = agent_script.ui.max_creep_aggro:Get()
    
    -- 1. Check Recent Hero Damage
    local just_took_hero_damage = false
    for i = #agent.damage_history, 1, -1 do
        local event = agent.damage_history[i]
        if current_time - event.time > 2.0 then
            table.remove(agent.damage_history, i)
        else
            if event.is_hero and (current_time - event.time < 0.2) then
                just_took_hero_damage = true
            end
        end
    end

    -- 2. Check Aggro
    local is_being_attacked_by_hero = false
    local nearby_enemies = Heroes.InRadius(bear_pos, 1000, my_team, Enum.TeamType.TEAM_ENEMY)
    for _, hero in ipairs(nearby_enemies) do
        if IsTargetingUnit(hero, bear) then
            is_being_attacked_by_hero = true
            break
        end
    end
    
    local creep_aggro_count = 0
    local nearby_creeps = NPCs.InRadius(bear_pos, 800, my_team, Enum.TeamType.TEAM_ENEMY)
    for _, unit in ipairs(nearby_creeps) do
        if NPC.IsCreep(unit) and IsTargetingUnit(unit, bear) then
            creep_aggro_count = creep_aggro_count + 1
        end
    end

    -- 3. Find Target Hero (Moved UP to determine Defending State first)
    local target_hero = nil
    local min_dist = 99999
    local all_enemies = Heroes.InRadius(bear_pos, 2000, my_team, Enum.TeamType.TEAM_ENEMY)
    
    for _, hero in ipairs(all_enemies) do
        if Entity.IsAlive(hero) and not NPC.IsIllusion(hero) and NPC.IsVisible(hero) then
            local d = druid_pos:Distance(Entity.GetAbsOrigin(hero))
            if d < min_dist then
                min_dist = d
                target_hero = hero
            end
        end
    end

    -- 4. Check Defending Status
    local is_defending = false
    if target_hero then
        local d = Entity.GetAbsOrigin(target_hero):Distance(druid_pos)
        if d <= DEFEND_RADIUS then
            is_defending = true
        end
    end

    -- 5. Handle Active Retreat (Ignored if Defending)
    if not is_defending and current_time < agent.retreat_until then
        -- Safety: cancel retreat early if no one is hitting and no creeps are targeting the bear
        if creep_aggro_count == 0 and not is_being_attacked_by_hero then
            agent.retreat_until = 0
            agent.retreat_type = "NONE"
            agent:MoveTo(druid_pos)
            agent.thought = "Retreat canceled (no aggro)"
            return true
        end

        local fountain_pos = FOUNTAIN_LOCATIONS[my_team]
        if fountain_pos then
             agent:MoveTo(fountain_pos)
             agent.thought = string.format("Backing to Fountain! (%.1fs)", agent.retreat_until - current_time)
        else
             agent:MoveTo(druid_pos) 
        end
        return true
    else
        if agent.retreat_type ~= "NONE" then
             agent.recent_hero_hits = 0 
        end
        agent.retreat_type = "NONE"
    end

    -- 6. Trigger New Retreat (Ignored if Defending)
    if not is_defending then
        local hit_tolerance = agent_script.ui.hero_attack_tolerance:Get()
        if current_time - agent.last_hero_hit_time > 4.0 then
             agent.recent_hero_hits = 0
        end
        
        local hero_limit_exceeded = false
        if hit_tolerance == 0 then
             hero_limit_exceeded = is_being_attacked_by_hero or (agent.recent_hero_hits > 0)
        else
             hero_limit_exceeded = agent.recent_hero_hits > hit_tolerance
        end

        if creep_aggro_count >= MAX_CREEP_AGGRO then
            agent.retreat_until = current_time + RETREAT_DURATION
            agent.retreat_type = "MICRO_FOUNTAIN"
            agent.thought = "Harass: Too many creeps! Fountain!"
            return true
        end

        if hero_limit_exceeded then
            agent.retreat_until = current_time + RETREAT_DURATION
            agent.retreat_type = "MICRO_FOUNTAIN"
            agent.thought = "Harass: Hero Aggro! Resetting!"
            return true
        end
    end

    -- 7. Execute Defend Action
    if is_defending then
        agent:Attack(target_hero)
        agent.thought = "Harass: DEFENDING!"
        return true
    end

    -- 8. Tower Safety
    if ShouldAvoidTowers() then
        local bear_in_tower, _ = IsPositionInTowerRange(bear_pos, my_team)
        if bear_in_tower then
            agent:MoveTo(druid_pos)
            agent.thought = "Harass: Tower Safety"
            return true
        end
    end

    -- 9. Determine Mode (Harass vs CS)
    local hero_in_range = target_hero and (min_dist <= 1100)
    local target_under_tower = false
    if target_hero then
        local in_range, _ = IsPositionInTowerRange(Entity.GetAbsOrigin(target_hero), my_team)
        if in_range then target_under_tower = true end
    end

    local should_harass = hero_in_range
    if ShouldAvoidTowers() and target_under_tower then should_harass = false
    elseif target_under_tower then should_harass = false end

    if should_harass then
        -- === HARASS LOGIC ===
        local dist_to_enemy = bear_pos:Distance(Entity.GetAbsOrigin(target_hero))
        local attack_range = NPC.GetAttackRange(bear) + NPC.GetHullRadius(bear) + NPC.GetHullRadius(target_hero)

        local dist_from_druid = bear_pos:Distance(druid_pos)
        if dist_from_druid > LEASH_RANGE then
            agent:MoveTo(druid_pos)
            agent.thought = "Harass: Leashed"
            return true
        end

        if dist_to_enemy <= (attack_range + 50) then
            agent:Attack(target_hero)
            agent.thought = "Harass: ATTACKING!"
        else
            agent:MoveTo(Entity.GetAbsOrigin(target_hero))
            agent.thought = "Harass: Chasing..."
        end
        return true
    else
        -- === SMART CS LOGIC ===
        
        -- Leash Check for CS Mode
        local dist_from_druid = bear_pos:Distance(druid_pos)
        if dist_from_druid > LEASH_RANGE then
            agent:MoveTo(druid_pos)
            agent.thought = "CS: Leashed (Returning)"
            return true
        end

        local creeps = NPCs.InRadius(bear_pos, 1000, my_team, Enum.TeamType.TEAM_BOTH)
        local best_creep = nil
        local best_score = -1
        local action_type = "NONE" -- KILL, DENY, PREPARE
        
        for _, creep in ipairs(creeps) do
            if NPC.IsCreep(creep) and NPC.IsLaneCreep(creep) and Entity.IsAlive(creep) then
                local creep_pos = Entity.GetAbsOrigin(creep)
                local creep_in_tower, _ = IsPositionInTowerRange(creep_pos, my_team)
                
                local safe_to_cs = true
                if ShouldAvoidTowers() and creep_in_tower then safe_to_cs = false end
                
                if safe_to_cs then
                    local is_enemy = not Entity.IsSameTeam(bear, creep)
                    local max_hp = Entity.GetMaxHealth(creep)
                    
                    -- Smart Calculation
                    local predicted_hp, bear_dmg, time_to_impact, current_hp = GetHitDetails(bear, creep)
                    
                    -- Thresholds
                    local safety_hp_cap = bear_dmg * 1.5
                    local prepare_threshold = bear_dmg * 2.5 
                    
                    local score = 0
                    local this_action = "NONE"
                    
                    if is_enemy then
                        -- KILL LOGIC
                        if predicted_hp <= bear_dmg then
                            if current_hp <= safety_hp_cap then
                                score = 1000 + (1000 - predicted_hp)
                                this_action = "KILL"
                            else
                                score = 600 - current_hp
                                this_action = "PREPARE"
                            end
                        elseif current_hp <= prepare_threshold then
                            score = 500 - current_hp
                            this_action = "PREPARE"
                        end
                    else
                        -- DENY LOGIC
                        if current_hp < (max_hp * 0.5) then
                            if predicted_hp <= bear_dmg then
                                if current_hp <= safety_hp_cap then
                                    score = 800 + (1000 - predicted_hp)
                                    this_action = "DENY"
                                else
                                    score = 450 - current_hp
                                    this_action = "PREPARE"
                                end
                            elseif current_hp <= prepare_threshold then
                                score = 400 - current_hp
                                this_action = "PREPARE"
                            end
                        end
                    end
                    
                    if score > best_score then
                        best_score = score
                        best_creep = creep
                        action_type = this_action
                    end
                end
            end
        end

        if best_creep then
            if action_type == "KILL" or action_type == "DENY" then
                -- Commit to attack ONLY for killing blows
                agent:Attack(best_creep)
                agent.thought = "CS: " .. action_type .. " (Execute)"
                return true
            elseif action_type == "PREPARE" then
                -- Move closer but STRICTLY DO NOT ATTACK
                local creep_pos = Entity.GetAbsOrigin(best_creep)
                if bear_pos:Distance(creep_pos) > 150 then
                    agent:MoveTo(creep_pos)
                    agent.thought = "CS: Positioning (Wait)"
                else
                    agent:HoldPosition()
                    agent.thought = "CS: Waiting for HP drop..."
                end
                agent.hover_target_pos = nil
                return true
            end
        end
        
        -- === ORGANIC HOVER (No Jitter) ===
        local allied_creeps = NPCs.InRadius(bear_pos, 1000, my_team, Enum.TeamType.TEAM_FRIEND)
        local creep_centroid = Vector(0,0,0)
        local count = 0
        
        for _, c in ipairs(allied_creeps) do
            if NPC.IsLaneCreep(c) then
                creep_centroid = creep_centroid + Entity.GetAbsOrigin(c)
                count = count + 1
            end
        end
        
        if count > 0 then
            creep_centroid = creep_centroid / count
            
            -- Pull hover point towards Druid for safety
            local dir_to_druid = (druid_pos - creep_centroid):Normalized()
            local anchor_pos = creep_centroid + (dir_to_druid * 200)
            
            -- Check if we need a new hover target
            local needs_new_target = false
            if not agent.hover_target_pos then needs_new_target = true end
            if current_time > agent.hover_expiry_time then needs_new_target = true end
            if agent.hover_target_pos and bear_pos:Distance(agent.hover_target_pos) < 50 then needs_new_target = true end
            
            if needs_new_target then
                -- Pick a random point around the anchor (Organic Movement)
                local rx = math.random(-200, 200)
                local ry = math.random(-200, 200)
                local new_pos = anchor_pos + Vector(rx, ry, 0)
                
                agent.hover_target_pos = new_pos
                agent.hover_expiry_time = current_time + math.random(2.0, 4.0)
                
                agent:MoveTo(new_pos)
                agent.thought = "CS: Hovering (Wander)"
            end
            return true
        else
            -- No creeps nearby, return to druid
            if bear_pos:Distance(druid_pos) > 200 then
                agent:MoveTo(druid_pos)
                agent.thought = "CS: Returning (No Creeps)"
            end
        end
    end

    return true
end

function Actions.ExecuteFIGHTING(agent)
    local target = agent.target
    local max_range = GetMaxCombatRange()
    
    local range_check = true
    if agent.hero_target_locked then
        range_check = true
    else
        range_check = Entity.GetAbsOrigin(my_hero):Distance(Entity.GetAbsOrigin(target)) <= max_range
    end

    if not target or not Entity.IsAlive(target) or not range_check then
        agent.state = STATES.FOLLOWING
        agent.target = nil
        agent.hero_target_locked = false
        return false
    end

    local distance = Entity.GetAbsOrigin(agent.unit):Distance(Entity.GetAbsOrigin(target))
    local attack_range = NPC.GetAttackRange(agent.unit) + 
                         NPC.GetAttackRangeBonus(agent.unit) + 
                         NPC.GetHullRadius(agent.unit) + 
                         NPC.GetHullRadius(target)

    local is_stunned = NPC.IsStunned(target)
    local is_rooted = NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_ROOTED)
    local is_silenced = NPC.IsSilenced(target)
    local action_taken = false

    -- Fetch
    local dist_to_hero = Entity.GetAbsOrigin(agent.unit):Distance(Entity.GetAbsOrigin(my_hero))
    local fetch_min_range = agent_script.ui.fetch_min_range:Get()
    local fetch_ability = NPC.GetAbility(agent.unit, "lone_druid_spirit_bear_fetch")
    
    if not action_taken and 
       fetch_ability and Ability.GetLevel(fetch_ability) > 0 and
       NPC.GetMana(agent.unit) >= Ability.GetManaCost(fetch_ability) and
       dist_to_hero > fetch_min_range and
       agent:UseAbilityOrItem("lone_druid_spirit_bear_fetch", target, false) then
        agent.thought = "Casting Fetch"
        return true
    end
    
    -- BKB Logic
    if not action_taken and agent_script.ui.item_multiselect:Get("item_black_king_bar") then
        local nearby_enemies = Heroes.InRadius(Entity.GetAbsOrigin(agent.unit), 700, Entity.GetTeamNum(agent.unit), Enum.TeamType.TEAM_ENEMY)
        local enemy_count = 0
        for _, enemy in ipairs(nearby_enemies) do
            if Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
                enemy_count = enemy_count + 1
            end
        end

        if enemy_count >= 2 then
            if agent:UseAbilityOrItem("item_black_king_bar", nil, true) then
                agent.thought = "Using BKB (Crowd Control)"
                action_taken = true
            end
        end
    end

    -- Harpoon
    if not action_taken and distance > attack_range and 
       agent_script.ui.item_multiselect:Get("item_harpoon") and 
       agent:UseAbilityOrItem("item_harpoon", target, true) then
        agent.thought = "Closing in (Harpoon)"
        return true
    end

    -- Silence
    if not action_taken and not is_silenced and distance <= 900 then
        if agent_script.ui.item_multiselect:Get("item_bloodthorn") and 
           agent:UseAbilityOrItem("item_bloodthorn", target, true) then
            agent.thought = "Silence (Bloodthorn)"
            return true
        end
        if agent_script.ui.item_multiselect:Get("item_orchid") and 
           agent:UseAbilityOrItem("item_orchid", target, true) then
            agent.thought = "Silence (Orchid)"
            return true
        end
    end

    -- Slows
    if not action_taken and distance <= 600 then
        if agent_script.ui.item_multiselect:Get("item_diffusa") and 
           agent:UseAbilityOrItem("item_diffusal_blade", target, true) then
            agent.thought = "Slowing (diffusal)"
            return true
        end
        
        if agent_script.ui.item_multiselect:Get("item_disperser") and 
           agent:UseAbilityOrItem("item_disperser", target, true) then
            agent.thought = "Slowing (Disperser)"
            return true
        end
    end

    -- Stuns
    if not action_taken and distance <= 250 and
       agent_script.ui.item_multiselect:Get("item_abyssal_blade") and 
       agent:UseAbilityOrItem("item_abyssal_blade", target, true) then
        agent.thought = "Stunning (abyssal)"
        return true
    end

    -- Mask of Madness
    if not action_taken and distance <= attack_range + 100 and
       agent_script.ui.item_multiselect:Get("item_mask_of_madness") and 
       not NPC.HasModifier(agent.unit, "modifier_mask_of_madness_berserk") and 
       agent:UseAbilityOrItem("item_mask_of_madness", nil, true) then
        agent.thought = "Activating MoM"
        action_taken = true 
    end

    -- Auto-skill on entangle
    if agent_script.ui.auto_skill_on_entangle:Get() and 
       NPC.HasModifier(target, "modifier_lone_druid_spirit_bear_entangle_effect") then
        if Hero.GetAbilityPoints(my_hero) > 0 then
            local ability = NPC.GetAbility(my_hero, "lone_druid_spirit_bear")
            if ability and Ability.GetLevel(ability) < Ability.GetMaxLevel(ability) then
                Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY, nil, nil, ability, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, my_hero)
                return true
            end
        end
    end
    
    -- Tower avoidance (Ignored if locked)
    if ShouldAvoidTowers() and not agent.hero_target_locked then
        local bear_team = Entity.GetTeamNum(agent.unit)
        local target_pos = Entity.GetAbsOrigin(target)
        local in_tower_range, tower = IsPositionInTowerRange(target_pos, bear_team)
        
        if in_tower_range then
            local bear_pos = Entity.GetAbsOrigin(agent.unit)
            local bear_in_tower = IsPositionInTowerRange(bear_pos, bear_team)
            
            if bear_in_tower then
                local hero_pos = Entity.GetAbsOrigin(my_hero)
                agent:MoveTo(hero_pos)
                agent.thought = "Retreating from tower"
                return true
            end
            
            if distance <= attack_range then
                agent:Attack(target)
                agent.thought = "Attacking (safe from tower)"
                return true
            else
                local hero_pos = Entity.GetAbsOrigin(my_hero)
                agent:MoveTo(hero_pos)
                agent.thought = "Following (target under tower)"
                return true
            end
        end
    end
    
    if distance > attack_range then
        local game_phase = agent_script.ui.game_phase:Get()
        
        if agent.hero_target_locked or game_phase >= 2 then
            agent:Attack(target)
            agent.thought = "Attacking (Gap closing)"
        else
            agent:MoveTo(Entity.GetAbsOrigin(target))
            agent.thought = "Moving to target (safe)"
        end
        return true
    end
    
    agent:Attack(target)
    agent.thought = "Attacking target"
    
    return true
end

function Actions.ExecuteFARMING(agent)
    local target = agent.target
    local bear_pos = Entity.GetAbsOrigin(agent.unit)
    local creep_aggro_count = 0
    local my_team = Entity.GetTeamNum(agent.unit)
    
    -- Count attacking creeps to avoid heavy aggro
    local nearby_creeps = NPCs.InRadius(bear_pos, 800, my_team, Enum.TeamType.TEAM_ENEMY)
    for _, unit in ipairs(nearby_creeps) do
        if NPC.IsCreep(unit) and IsTargetingUnit(unit, agent.unit) then
            creep_aggro_count = creep_aggro_count + 1
        end
    end
    
    if not target or not Entity.IsAlive(target) then
        agent.state = STATES.FOLLOWING
        agent.thought = "Finished farming."
        agent.target = nil
        agent.target_score = 0
        return false
    end
    
    -- If too much creep aggro, retreat briefly then continue farming
    if creep_aggro_count >= 2 then
        local druid_pos = Entity.GetAbsOrigin(my_hero)
        agent:MoveTo(druid_pos)
        agent.thought = string.format("Farm: Deaggro (%d creeps)", creep_aggro_count)
        agent.retreat_until = GlobalVars.GetCurTime() + 0.5
        return true
    end
    
    -- Try to kill low hp creeps first for efficiency
    local target_hp_percent = (Entity.GetHealth(target) / Entity.GetMaxHealth(target)) * 100
    if target_hp_percent > 20 then
        -- Look for lower HP creeps nearby to last-hit
        local best_creep = target
        local best_hp_percent = target_hp_percent
        
        local nearby_enemy_creeps = NPCs.InRadius(bear_pos, 600, my_team, Enum.TeamType.TEAM_ENEMY)
        for _, creep in ipairs(nearby_enemy_creeps) do
            if NPC.IsCreep(creep) and Entity.IsAlive(creep) then
                local creep_hp_percent = (Entity.GetHealth(creep) / Entity.GetMaxHealth(creep)) * 100
                if creep_hp_percent < best_hp_percent and creep_hp_percent < 40 then
                    best_creep = creep
                    best_hp_percent = creep_hp_percent
                end
            end
        end
        
        if best_creep ~= target then
            agent.target = best_creep
            target = best_creep
        end
    end
    
    agent:Attack(target)
    agent.thought = "Farming creep"
    return true
end

-- ============================================================================
-- ACTION DISPATCHER
-- ============================================================================
local ACTION_DISPATCHER = {
    [STATES.FOLLOWING] = Actions.ExecuteFOLLOWING,
    [STATES.PATROLLING] = Actions.ExecutePATROLLING,
    [STATES.FIGHTING] = Actions.ExecuteFIGHTING,
    [STATES.FARMING] = Actions.ExecuteFARMING,
    [STATES.SEARCHING] = Actions.ExecuteSEARCHING,
    [STATES.LANE_HARASS] = Actions.ExecuteLANE_HARASS
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

function GetMaxCombatRange()
    local game_phase = agent_script.ui.game_phase:Get()
    if game_phase == 1 then return 1100
    elseif game_phase == 2 then return 1500
    else return 2500 end
end

function ShouldAvoidTowers()
    return agent_script.ui.game_phase:Get() == 1
end

function ShouldUseAggressivePatrol()
    return agent_script.ui.game_phase:Get() >= 2
end

function IsPositionInTowerRange(position, team)
    if not position or not team then return false end
    
    local towers = NPCs.InRadius(position, 1000, team, Enum.TeamType.TEAM_ENEMY)
    for _, tower in ipairs(towers) do
        if NPC.IsTower(tower) and Entity.IsAlive(tower) then
            local tower_pos = Entity.GetAbsOrigin(tower)
            local distance = position:Distance(tower_pos)
            if distance <= 800 then
                return true, tower
            end
        end
    end
    
    return false, nil
end

-- ============================================================================
-- TARGET SELECTION
-- ============================================================================

function CalculateTargetScore(agent, target)
    local score = 0
    local d = Entity.GetAbsOrigin(agent.unit):Distance(Entity.GetAbsOrigin(target))
    
    -- Creeps: prioritize by HP and distance
    if NPC.IsCreep(target) then
        local target_hp = Entity.GetHealth(target)
        local target_max_hp = Entity.GetMaxHealth(target)
        local hp_percent = (target_hp / target_max_hp) * 100
        
        -- Low HP creeps get high priority for last-hitting
        if hp_percent < 30 then
            score = score + 500
        elseif hp_percent < 50 then
            score = score + 300
        else
            score = score + 100
        end
        
        -- Closer creeps slightly preferred
        score = score - (d / 100) * 2
        return score
    end
    
    -- Hero priority
    local h = Entity.GetIndex(target)
    if threat_list[h] and GlobalVars.GetCurTime() < threat_list[h] then
        score = score + 200
    end
    
    if NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_STUNNED) or 
       NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_ROOTED) then
        score = score + 200
    end
    
    local target_hp = Entity.GetHealth(target)
    local target_max_hp = Entity.GetMaxHealth(target)
    local hp_missing = target_max_hp - target_hp
    local hp_percent = (target_hp / target_max_hp) * 100
    
    score = score + (hp_missing / 100) * 10
    
    if hp_percent < 30 and d < 600 then
        score = score + 300
    elseif hp_percent < 50 and d < 400 then
        score = score + 150
    end
    
    if NPC.HasAegis(target) then
        score = score - 1000
    end
    
    if d < 400 then
        score = score - (d / 100) * 5
    elseif d < 800 then
        score = score - (d / 100) * 15
    else
        score = score - (d / 100) * 25
    end
    
    if agent.target and agent.target == target and Entity.IsAlive(agent.target) then
        local current_target_hp_percent = (Entity.GetHealth(agent.target) / Entity.GetMaxHealth(agent.target)) * 100
        
        if d > 600 and current_target_hp_percent > 60 then
            score = score + 50
        else
            score = score + 150
        end
    end
    
    return score
end

function FindBestHeroTarget(agent)
    local potential_targets = {}
    local max_range = GetMaxCombatRange()
    local bear_pos = Entity.GetAbsOrigin(agent.unit)
    local my_team = Entity.GetTeamNum(agent.unit)
    
    -- Include heroes
    for _, hero in pairs(Heroes.GetAll()) do
        if not Entity.IsSameTeam(hero, my_hero) and 
           Entity.IsAlive(hero) and 
           NPC.IsVisible(hero) and 
           not NPC.IsIllusion(hero) and 
           Entity.GetAbsOrigin(my_hero):Distance(Entity.GetAbsOrigin(hero)) <= max_range then
            table.insert(potential_targets, hero)
        end
    end
    
    -- Include low-hp creeps for farming/finishing
    local nearby_creeps = NPCs.InRadius(bear_pos, 600, my_team, Enum.TeamType.TEAM_ENEMY)
    for _, creep in ipairs(nearby_creeps) do
        if NPC.IsCreep(creep) and Entity.IsAlive(creep) then
            local creep_hp_percent = (Entity.GetHealth(creep) / Entity.GetMaxHealth(creep)) * 100
            if creep_hp_percent < 35 then  -- Only low HP creeps
                table.insert(potential_targets, creep)
            end
        end
    end
    
    if #potential_targets > 0 then
        local best_target, best_score = nil, -999999
        for _, candidate in ipairs(potential_targets) do
            local current_score = CalculateTargetScore(agent, candidate)
            if current_score > best_score then
                best_score, best_target = current_score, candidate
            end
        end
        return best_target, best_score
    end
    
    return nil, 0
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================
function agent_script.OnUpdate()
    if agent_script.ui.force_patrol_key then
        local bind = agent_script.ui.force_patrol_key
        local isHeld = false
        
        if bind.IsDown and bind:IsDown() then isHeld = true end
        if bind.IsPressed and bind:IsPressed() then isHeld = true end
        if bind.Buttons then
            local k1, k2 = bind:Buttons()
            if k1 and k1 ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k1 ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k1) then 
                isHeld = true 
            end
            if k2 and k2 ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k2 ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k2) then 
                isHeld = true 
            end
        end
        if not isHeld and bind.Get then
            local k = bind:Get()
            if k and k ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k) then 
                isHeld = true 
            end
        end
        
        if isHeld and not force_patrol.last_key_state then
            for _, agent in pairs(agent_manager) do
                if agent and agent.unit and Entity.IsAlive(agent.unit) then
                    agent.manual_override_until = 0
                    agent.hero_target_locked = false
                    agent.target = nil
                    agent.state = STATES.PATROLLING
                    agent.thought = "AI Resumed (Lock Cleared)"
                end
            end
        end
        
        force_patrol.last_key_state = isHeld
    end
    
    UpdateEnemyPositions()
    DeliveryManager:OnUpdate()
    
    if not agent_script.ui.enable:Get() or not Engine.IsInGame() then return end
    
    if agent_script.ui.enable_by_timer:Get() then
        local game_time_seconds = GameRules.GetDOTATime(false, true)
        local activation_time_seconds = agent_script.ui.activation_minute:Get() * 60
        if game_time_seconds < activation_time_seconds then return end
    end
    
    my_hero = Heroes.GetLocal()
    local_player = Players.GetLocal()
    
    if not my_hero or not Entity.IsAlive(my_hero) or not local_player or 
       NPC.GetUnitName(my_hero) ~= "npc_dota_hero_lone_druid" then
        agent_manager = {}
        return
    end
    
    local bear_ability = NPC.GetAbility(my_hero, "lone_druid_spirit_bear")
    local bear = bear_ability and Ability.GetLevel(bear_ability) > 0 and 
                   CustomEntities.GetSpiritBear(bear_ability) or nil
    
    if bear and Entity.IsAlive(bear) then
        if not agent_manager[Entity.GetIndex(bear)] then
            agent_manager[Entity.GetIndex(bear)] = Agent.new(bear)
        end
    else
        agent_manager = {}
        return
    end
    
    local interrupt_target, casting_ability = nil, nil
    if agent_script.ui.auto_interrupt_casts:Get() then
        for _, enemy in pairs(Heroes.GetAll()) do
            if not Entity.IsSameTeam(enemy, my_hero) and Entity.IsAlive(enemy) and 
               NPC.IsVisible(enemy) and Entity.GetAbsOrigin(my_hero):Distance(Entity.GetAbsOrigin(enemy)) <= 1200 then
                if NPC.IsChannellingAbility(enemy) then
                    interrupt_target = enemy
                    casting_ability = NPC.GetChannellingAbility(enemy) or NPC.GetAbilityByActivity(enemy, enemy_activity)
                    break
                end
            end
        end
    end
    
    for handle, agent in pairs(agent_manager) do
        local current_time = GlobalVars.GetCurTime()
        local game_phase = agent_script.ui.game_phase:Get()
        
        if ShouldAvoidTowers() and not agent.hero_target_locked then
            local bear_pos = Entity.GetAbsOrigin(agent.unit)
            local bear_team = Entity.GetTeamNum(agent.unit)
            local in_tower_range, tower = IsPositionInTowerRange(bear_pos, bear_team)
            
            if in_tower_range then
                if my_hero and Entity.IsAlive(my_hero) then
                    agent:MoveTo(Entity.GetAbsOrigin(my_hero))
                    agent.thought = "RETREATING FROM TOWER!"
                    agent.state = STATES.FOLLOWING
                    agent.target = nil
                    agent.next_action_time = current_time + 0.1
                    goto continue_loop
                end
            end
        end
        
        if current_time < agent.next_action_time then goto continue_loop end
        
        if current_time < agent.manual_override_until then
            agent.state = STATES.MANUAL_OVERRIDE
            agent.thought = string.format("Manual control (%.1fs)", math.max(0, agent.manual_override_until - current_time))
            goto continue_loop
        elseif agent.state == STATES.MANUAL_OVERRIDE then
            agent.state = STATES.FOLLOWING
            agent.thought = "Switching to AI mode."
        end
        
        if interrupt_target then
            if agent.state ~= STATES.INTERRUPTING then
                agent.state = STATES.INTERRUPTING
                agent.target = interrupt_target
            end
            if not Actions.ExecuteINTERRUPTING(agent) then
                agent.state = STATES.FIGHTING
            else
                agent.next_action_time = current_time + 0.5
                goto continue_loop
            end
        elseif agent.state == STATES.INTERRUPTING then
            agent.state = STATES.FOLLOWING
        end
        
        if Actions.ExecuteSAVING_LOGIC(agent) then
            agent.next_action_time = current_time + 0.5
            goto continue_loop
        end
        
        if agent.state ~= STATES.INTERRUPTING and agent.state ~= STATES.MANUAL_OVERRIDE then
            if game_phase == 1 and not agent.hero_target_locked then
                agent.state = STATES.LANE_HARASS
            else
                local best_enemy_target, enemy_score = FindBestHeroTarget(agent)
                
                if agent.hero_target_locked and agent.target and Entity.IsAlive(agent.target) then
                     if NPC.IsVisible(agent.target) then
                        agent.state = STATES.FIGHTING
                     else
                        if agent.state ~= STATES.SEARCHING then
                            agent.state = STATES.SEARCHING
                            local bear_pos = Entity.GetAbsOrigin(agent.unit)
                            local enemy_pos = Entity.GetAbsOrigin(agent.target)
                            local chase_dir = (enemy_pos - bear_pos):Normalized()
                            local extrapolation_dist = 600
                            
                            agent.last_seen_pos = enemy_pos + (chase_dir * extrapolation_dist)
                            agent.search_end_time = GlobalVars.GetCurTime() + 4.0
                            agent.thought = "Target Locked (Fog) -> Chasing"
                        end
                     end
                elseif best_enemy_target then
                    agent.state = STATES.FIGHTING
                    agent.target = best_enemy_target
                    agent.target_score = enemy_score
                    agent.hero_target_locked = false
                elseif agent.state == STATES.FIGHTING then
                    local old_target = agent.target
                    
                    if old_target and Entity.IsAlive(old_target) and not NPC.IsVisible(old_target) then
                        agent.state = STATES.SEARCHING
                        local bear_pos = Entity.GetAbsOrigin(agent.unit)
                        local enemy_pos = Entity.GetAbsOrigin(old_target)
                        local chase_dir = (enemy_pos - bear_pos):Normalized()
                        local extrapolation_dist = 600
                        
                        agent.last_seen_pos = enemy_pos + (chase_dir * extrapolation_dist)
                        agent.search_end_time = GlobalVars.GetCurTime() + 2.0
                        agent.thought = "Target lost... Chasing!"
                        agent.target = nil
                    else
                        if game_phase == 1 then
                            agent.state = STATES.LANE_HARASS
                        elseif ShouldUseAggressivePatrol() then
                            agent.state = STATES.PATROLLING
                        else
                            agent.state = STATES.FOLLOWING
                        end
                        agent.target = nil
                        agent.hero_target_locked = false
                    end
                end
            end
        end
        
        if ACTION_DISPATCHER[agent.state] and ACTION_DISPATCHER[agent.state](agent) then
            -- Packet overload managed by logic logic changes, reverting delay for responsiveness
            local delay = 0.1 
            agent.next_action_time = current_time + delay
        end
        
        ::continue_loop::
    end
end

-- ============================================================================
-- DRAW DEBUG INFORMATION
-- ============================================================================
function agent_script.OnDraw()
    CourierPanelModule:OnDraw()
    
    if not agent_script.ui.enable:Get() or not agent_script.ui.debug_draw:Get() then return end
    
    if not font then
        font = Render.LoadFont("Arial", 12, Enum.FontCreate.FONTFLAG_OUTLINE)
    end
    
    for _, a in pairs(agent_manager) do
        if a.unit and Entity.IsAlive(a.unit) then
            local offset = NPC.GetHealthBarOffset(a.unit)
            if not offset or offset < 50 then offset = 150 end
            
            local p = Entity.GetAbsOrigin(a.unit) + Vector(0, 0, offset + 20)
            local s, v = Render.WorldToScreen(p)
            
            if v then
                local display_color = Color(180, 220, 255, 255)
                if a.state == STATES.MANUAL_OVERRIDE then display_color = Color(255, 165, 0, 255)
                elseif a.state == STATES.FIGHTING then display_color = Color(255, 50, 50, 255)
                elseif a.state == STATES.FARMING then display_color = Color(100, 255, 100, 255)
                elseif a.state == STATES.INTERRUPTING then display_color = Color(255, 100, 255, 255)
                elseif a.state == STATES.PATROLLING then display_color = Color(255, 200, 50, 255)
                elseif a.state == STATES.SEARCHING then display_color = Color(255, 255, 0, 255)
                elseif a.state == STATES.LANE_HARASS then display_color = Color(0, 255, 255, 255) end
                
                Render.Text(font, 12, string.format("State: [%s]", a.state), Vec2(s.x, s.y), display_color)
                Render.Text(font, 12, string.format("Thought: %s", a.thought), Vec2(s.x, s.y + 12), Color(255, 255, 255, 255))
                
                if a.target and Entity.IsAlive(a.target) and a.target ~= my_hero and a.state ~= STATES.MANUAL_OVERRIDE then
                    local ts, _ = Render.WorldToScreen(Entity.GetAbsOrigin(a.target))
                    if ts then
                        Render.Line(s, ts, Color(255, 0, 0, 150))
                        if a.state == STATES.FIGHTING or a.state == STATES.FARMING then
                            Render.Text(font, 12, string.format("Score: %.0f", a.target_score), Vec2(s.x, s.y + 24), Color(255, 255, 100, 255))
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================================
-- ORDER INTERCEPTION
-- ============================================================================
function agent_script.OnPrepareUnitOrders(data)
    local player = data.player or Players.GetLocal()
    if not player then return true end
    
    if DeliveryManager.isActive then
        local courier = Couriers.GetLocal()
        if courier then
            local isCourierOrder = false
            
            if data.npc and data.npc == courier then
                isCourierOrder = true
            else
                local selected_units = Player.GetSelectedUnits(player)
                for _, unit in ipairs(selected_units) do
                    if unit == courier then
                        isCourierOrder = true
                        break
                    end
                end
            end
            
            if isCourierOrder and data.order ~= Enum.UnitOrder.DOTA_UNIT_ORDER_GIVE_ITEM then
                DeliveryManager:StopDelivery()
            end
        end
    end
    
    if not OrderInterceptorModule:CheckForCourierTransferOrder(data) then return false end
    if not agent_script.ui.enable:Get() then return true end
    
    local local_hero = Heroes.GetLocal()
    local game_phase = agent_script.ui.game_phase:Get()
    
    local is_attack_order = (data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET)
    local is_attack_move_order = (data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE)
    local target_is_enemy_hero_or_tower = false
    
    if data.target then
        local is_enemy = not Entity.IsSameTeam(data.target, local_hero)
        if is_enemy and (Entity.IsHero(data.target) or NPC.IsTower(data.target)) then
            if game_phase == 1 then
                if is_attack_order then
                    target_is_enemy_hero_or_tower = true
                end
            else
                if is_attack_order or is_attack_move_order then
                    target_is_enemy_hero_or_tower = true
                end
            end
        end
    end

    local order_applies_to_bear = false
    local specific_bear_agent = nil

    if data.npc then
        if agent_manager[Entity.GetIndex(data.npc)] then
            order_applies_to_bear = true
            specific_bear_agent = agent_manager[Entity.GetIndex(data.npc)]
        elseif data.npc == local_hero then
            order_applies_to_bear = true
        end
    else
        local selected = Player.GetSelectedUnits(player)
        for _, unit in ipairs(selected) do
            if agent_manager[Entity.GetIndex(unit)] then
                order_applies_to_bear = true
                break
            end
        end
        for _, unit in ipairs(selected) do
            if unit == local_hero then
                order_applies_to_bear = true
                break
            end
        end
    end

    if order_applies_to_bear then
        if target_is_enemy_hero_or_tower then
            for _, agent in pairs(agent_manager) do
                local should_apply = (data.npc == local_hero) or (not data.npc) or (agent == specific_bear_agent)
                
                if not should_apply and not data.npc then
                     local selected = Player.GetSelectedUnits(player)
                     for _, u in ipairs(selected) do
                         if u == agent.unit then should_apply = true break end
                     end
                end

                if should_apply and agent.unit and Entity.IsAlive(agent.unit) then
                    agent.state = STATES.FIGHTING
                    agent.target = data.target
                    agent.target_score = 9999
                    agent.thought = "CMD: Locked on target!"
                    agent.manual_override_until = 0
                    agent.hero_target_locked = true
                end
            end
        else
            local is_attack_move_on_hero_unlock = (
                data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE and 
                data.target and 
                not target_is_enemy_hero_or_tower
            )

            local is_unlock_order = (
                data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION or
                data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET or
                (data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE and not data.target) or
                (data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET and not target_is_enemy_hero_or_tower) or
                data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_STOP or
                data.order == Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION or
                is_attack_move_on_hero_unlock
            )

            if is_unlock_order then
                for _, agent in pairs(agent_manager) do
                    local is_selected = false
                    local selected = Player.GetSelectedUnits(player)
                    for _, u in ipairs(selected) do
                        if u == agent.unit then is_selected = true break end
                    end
                    
                    local bear_is_target = (data.npc == agent.unit)
                    
                    if (is_selected or bear_is_target) then
                        agent.hero_target_locked = false
                        agent.manual_override_until = GlobalVars.GetCurTime() + 5
                        agent.state = STATES.MANUAL_OVERRIDE
                        agent.target = nil
                        agent.thought = "CMD: Manual Override"
                    end
                end
            end
        end
    end
    
    if data.orderIssuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY then return true end
    
    if not target_is_enemy_hero_or_tower then
        AssistModule.OnPlayerOrder(data)
    end
    
    return true
end

-- ============================================================================
-- ENTITY HURT EVENT
-- ============================================================================
function agent_script.OnEntityHurt(data)
    if not agent_script.ui.enable:Get() or not my_hero or not data or not data.target or not data.source then
        return
    end
    
    for _, agent in pairs(agent_manager) do
        if agent.unit == data.target then
            local is_hero_dmg = Entity.IsHero(data.source) and not NPC.IsIllusion(data.source)
            table.insert(agent.damage_history, { 
                time = GlobalVars.GetCurTime(), 
                damage = data.damage,
                is_hero = is_hero_dmg
            })
            
            if is_hero_dmg then
                agent.recent_hero_hits = agent.recent_hero_hits + 1
                agent.last_hero_hit_time = GlobalVars.GetCurTime()
            end
        end
        if agent.unit == data.source then
            agent.last_attack_time = GlobalVars.GetCurTime()
        end
    end
    
    if data.target ~= my_hero then return end
    
    if Entity.IsHero(data.source) and not Entity.IsSameTeam(data.source, my_hero) and not NPC.IsIllusion(data.source) then
        local h = Entity.GetIndex(data.source)
        threat_list[h] = GlobalVars.GetCurTime() + 3
        return
    end
    
    if NPC.IsCreep(data.source) and not NPC.IsLaneCreep(data.source) then
        for _, agent in pairs(agent_manager) do
            if agent.state == STATES.FOLLOWING then
                agent.state = STATES.FARMING
                agent.target = data.source
                agent.thought = "Protecting from creep"
                agent.manual_override_until = 0
                return
            end
        end
    end
end

-- ============================================================================
-- GAME END CLEANUP
-- ============================================================================
function agent_script.OnGameEnd()
    my_hero, local_player, agent_manager, threat_list = nil, nil, {}, {}
    enemy_tracker.last_known_positions = {}
    enemy_tracker.last_update_time = 0
    force_patrol.last_key_state = false
    follow_hero_attack.target = nil
    follow_hero_attack.lock_until = 0
    CourierPanelModule:OnGameEnd()
    DeliveryManager:OnGameEnd()
end

-- ============================================================================
-- MODULE EXPORT
-- ============================================================================
return agent_script