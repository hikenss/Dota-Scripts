-- ============================================================================
-- Dota 2 Visage Familiar AI Script
-- Controls Familiars with follow, harass, and fight logic.
-- ============================================================================

local agent_script = {}
agent_script.ui = {}

local STATES = {
    FOLLOWING = "FOLLOWING",
    PATROLLING = "PATROLLING",
    FIGHTING = "FIGHTING",
    RETREATING = "RETREATING"
}

local my_hero, local_player, font = nil, nil, nil
local agent_manager = {}
local last_log_time = 0
local log_file = nil

local function LogToFile(message)
    if not log_file then
        log_file = io.open("visage_ai_log.txt", "a")
        if not log_file then
            log_file = io.open("c:\\UB\\scripts\\visage_ai_log.txt", "a")
        end
    end
    if log_file then
        log_file:write(os.date("%H:%M:%S") .. " " .. message .. "\n")
        log_file:flush()
    end
end

LogToFile("Visage_AI loaded")

local function IsVisageHero(hero)
    return hero and NPC.GetUnitName(hero) == "npc_dota_hero_visage"
end

local function IsValidEnemy(unit)
    return unit and Entity.IsAlive(unit) and not Entity.IsSameTeam(unit, my_hero) and NPC.IsVisible(unit) and not NPC.IsIllusion(unit)
end

local function IsTargetingUnit(attacker, target)
    if not attacker or not target or not Entity.IsAlive(attacker) then return false end
    if not NPC.IsAttacking(attacker) then return false end

    local attacker_pos = Entity.GetAbsOrigin(attacker)
    local target_pos = Entity.GetAbsOrigin(target)
    local range = NPC.GetAttackRange(attacker) + 150
    if attacker_pos:Distance(target_pos) > range then return false end

    local forward = Entity.GetAbsRotation(attacker):GetForward()
    local to_target = (target_pos - attacker_pos):Normalized()

    return forward:Dot(to_target) > 0.75
end

local function GetFamiliars()
    local hero = Heroes.GetLocal()
    if not hero then return {} end

    local player_id = Hero.GetPlayerID(hero)
    local result = {}

    for _, npc in ipairs(NPCs.GetAll()) do
        if Entity.IsAlive(npc) and Entity.IsControllableByPlayer(npc, player_id) then
            if NPC.GetUnitName(npc) == "npc_dota_visage_familiar" then
                table.insert(result, npc)
            end
        end
    end

    return result
end

local function FindHeroAttackTarget()
    if not agent_script.ui.follow_hero_attack:Get() then return nil end
    local hero_target = NPC.GetAttackTarget(my_hero)
    if IsValidEnemy(hero_target) then
        return hero_target
    end
    return nil
end

local function FindThreatTarget(agent)
    local familiar_pos = Entity.GetAbsOrigin(agent.unit)
    local search_radius = agent_script.ui.harass_range:Get()
    local enemies = NPCs.InRadius(familiar_pos, search_radius, Entity.GetTeamNum(my_hero), Enum.TeamType.TEAM_ENEMY)

    local best_target, best_dist = nil, math.huge
    for _, enemy in ipairs(enemies) do
        if IsValidEnemy(enemy) then
            if IsTargetingUnit(enemy, my_hero) or IsTargetingUnit(enemy, agent.unit) then
                local dist = familiar_pos:Distance(Entity.GetAbsOrigin(enemy))
                if dist < best_dist then
                    best_dist = dist
                    best_target = enemy
                end
            end
        end
    end

    return best_target
end

local function FindBestTarget(agent)
    local familiar_pos = Entity.GetAbsOrigin(agent.unit)
    local search_radius = agent_script.ui.harass_range:Get()
    local enemies = NPCs.InRadius(familiar_pos, search_radius, Entity.GetTeamNum(my_hero), Enum.TeamType.TEAM_ENEMY)

    local best_target, best_dist = nil, math.huge
    for _, enemy in ipairs(enemies) do
        if IsValidEnemy(enemy) then
            local dist = familiar_pos:Distance(Entity.GetAbsOrigin(enemy))
            if NPC.IsHero(enemy) then
                if dist < best_dist then
                    best_dist = dist
                    best_target = enemy
                end
            elseif agent_script.ui.attack_creeps:Get() and NPC.IsCreep(enemy) then
                if dist < best_dist then
                    best_dist = dist
                    best_target = enemy
                end
            end
        end
    end

    return best_target
end

local function BuildFamiliarOrder(familiars)
    table.sort(familiars, function(a, b)
        return Entity.GetIndex(a) < Entity.GetIndex(b)
    end)

    local order = {}
    for i, fam in ipairs(familiars) do
        order[Entity.GetIndex(fam)] = i
    end

    return order, #familiars
end

local function GetPatrolPoint(index, count, hero_pos)
    local radius = agent_script.ui.patrol_radius:Get()
    local speed = agent_script.ui.patrol_speed:Get()
    local time = GlobalVars.GetCurTime()
    local base = (2 * math.pi * (index - 1)) / math.max(1, count)
    local angle = base + (time * speed)

    return Vector(
        hero_pos.x + radius * math.cos(angle),
        hero_pos.y + radius * math.sin(angle),
        hero_pos.z
    )
end

local function FindInterruptTarget(agent)
    if not agent_script.ui.auto_stone_form:Get() or not agent_script.ui.stone_form_interrupt:Get() then return nil end
    local fam_pos = Entity.GetAbsOrigin(agent.unit)
    local range = agent_script.ui.stone_form_range:Get()

    for _, enemy in pairs(Heroes.GetAll()) do
        if IsValidEnemy(enemy) and NPC.IsChannellingAbility(enemy) then
            if fam_pos:Distance(Entity.GetAbsOrigin(enemy)) <= range then
                return enemy
            end
        end
    end

    return nil
end

local Agent = {}
Agent.__index = Agent

function Agent.new(unit)
    return setmetatable({
        unit = unit,
        handle = Entity.GetIndex(unit),
        state = STATES.FOLLOWING,
        target = nil,
        thought = "Init",
        next_action_time = 0
    }, Agent)
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

function Agent:CastStoneForm()
    local ability = NPC.GetAbility(self.unit, "visage_stone_form")
    if ability and Ability.IsReady(ability) then
        Ability.CastNoTarget(ability)
        return true
    end
    return false
end

-- ============================================================================
-- MENU INITIALIZATION
-- ============================================================================

do
    local main_tab = Menu.Create("Heroes", "Hero List", "Visage")
    if main_tab then
        local main_group = main_tab:Create("Main Settings")
        local settings_group = main_group:Create("Familiar AI")

        agent_script.ui.enable = settings_group:Switch("Enable Familiar AI", true)
        agent_script.ui.debug_draw = settings_group:Switch("Display Debug", false)
        agent_script.ui.follow_distance = settings_group:Slider("Follow Distance", 200, 800, 350, "%d")
        agent_script.ui.harass_range = settings_group:Slider("Harass Range", 600, 2000, 1200, "%d")
        agent_script.ui.retreat_hp_pct = settings_group:Slider("Retreat HP Percent", 5, 60, 20, "%d")
        agent_script.ui.follow_hero_attack = settings_group:Switch("Follow Hero Attack Target", true)
        agent_script.ui.enable_patrol = settings_group:Switch("Enable Patrol", true)
        agent_script.ui.patrol_radius = settings_group:Slider("Patrol Radius", 200, 1000, 450, "%d")
        agent_script.ui.patrol_speed = settings_group:Slider("Patrol Speed", 0.2, 2.5, 1.0, "%.1f")
        agent_script.ui.attack_creeps = settings_group:Switch("Attack Creeps", false)
        agent_script.ui.debug_log = settings_group:Switch("Debug Log", false)

        local ability_group = main_group:Create("Abilities")
        agent_script.ui.auto_stone_form = ability_group:Switch("Auto Stone Form", true)
        agent_script.ui.stone_form_range = ability_group:Slider("Stone Form Range", 200, 700, 350, "%d")
        agent_script.ui.stone_form_interrupt = ability_group:Switch("Stone Form Interrupt", true)
    end
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================
function agent_script.OnUpdate()
    if not agent_script.ui.enable or not agent_script.ui.enable.Get then return end
    if not agent_script.ui.enable:Get() or not Engine.IsInGame() then return end

    my_hero = Heroes.GetLocal()
    local_player = Players.GetLocal()

    if not my_hero or not local_player or not Entity.IsAlive(my_hero) or not IsVisageHero(my_hero) then
        agent_manager = {}
        return
    end

    local familiars = GetFamiliars()
    local familiar_order, familiar_count = BuildFamiliarOrder(familiars)
    local seen = {}
    for _, fam in ipairs(familiars) do
        local idx = Entity.GetIndex(fam)
        seen[idx] = true
        if not agent_manager[idx] then
            agent_manager[idx] = Agent.new(fam)
        end
    end

    for idx, _ in pairs(agent_manager) do
        if not seen[idx] then
            agent_manager[idx] = nil
        end
    end

    local current_time = GlobalVars.GetCurTime()
    local hero_pos = Entity.GetAbsOrigin(my_hero)

    if agent_script.ui.debug_log:Get() and current_time - last_log_time > 1.0 then
        last_log_time = current_time
        LogToFile(string.format("tick hero=%s fam=%d", tostring(NPC.GetUnitName(my_hero)), #familiars))
    end

    for _, agent in pairs(agent_manager) do
        if not agent.unit or not Entity.IsAlive(agent.unit) then
            goto continue_loop
        end

        if current_time < agent.next_action_time then
            goto continue_loop
        end

        local fam_pos = Entity.GetAbsOrigin(agent.unit)
        local hp_pct = (Entity.GetHealth(agent.unit) / math.max(1, Entity.GetMaxHealth(agent.unit))) * 100
        local retreat_pct = agent_script.ui.retreat_hp_pct:Get()
        local distance_to_hero = fam_pos:Distance(hero_pos)

        local interrupt_target = FindInterruptTarget(agent)
        if interrupt_target then
            if agent:CastStoneForm() then
                agent.thought = "Stone Form (Interrupt)"
                agent.next_action_time = current_time + 0.2
                goto continue_loop
            end
        end

        if hp_pct <= retreat_pct or distance_to_hero > agent_script.ui.harass_range:Get() then
            agent.state = STATES.RETREATING
        end

        if agent.state == STATES.RETREATING then
            agent:MoveTo(hero_pos)
            agent.thought = "Retreating"

            if hp_pct >= retreat_pct + 10 and distance_to_hero <= agent_script.ui.follow_distance:Get() then
                agent.state = STATES.FOLLOWING
            end
        else
            local threat_target = FindThreatTarget(agent)
            local hero_target = FindHeroAttackTarget()
            local target = threat_target or hero_target or FindBestTarget(agent)
            if target then
                agent.state = STATES.FIGHTING
                agent.target = target
            else
                agent.state = agent_script.ui.enable_patrol:Get() and STATES.PATROLLING or STATES.FOLLOWING
                agent.target = nil
            end
        end

        if agent.state == STATES.FIGHTING and agent.target and IsValidEnemy(agent.target) then
            local target_pos = Entity.GetAbsOrigin(agent.target)
            if agent_script.ui.auto_stone_form:Get() and NPC.IsHero(agent.target) then
                if fam_pos:Distance(target_pos) <= agent_script.ui.stone_form_range:Get() then
                    if agent:CastStoneForm() then
                        agent.thought = "Stone Form"
                        agent.next_action_time = current_time + 0.2
                        goto continue_loop
                    end
                end
            end

            agent:Attack(agent.target)
            agent.thought = "Attacking"
        elseif agent.state == STATES.PATROLLING then
            local index = familiar_order[agent.handle] or 1
            local patrol_point = GetPatrolPoint(index, familiar_count, hero_pos)
            agent:MoveTo(patrol_point)
            agent.thought = "Patrolling"
        elseif agent.state == STATES.FOLLOWING then
            if distance_to_hero > agent_script.ui.follow_distance:Get() then
                agent:MoveTo(hero_pos)
                agent.thought = "Following"
            else
                agent:HoldPosition()
                agent.thought = "Holding"
            end
        end

        agent.next_action_time = current_time + 0.1

        ::continue_loop::
    end
end

-- ============================================================================
-- DRAW DEBUG INFORMATION
-- ============================================================================
function agent_script.OnDraw()
    if not agent_script.ui.enable:Get() or not agent_script.ui.debug_draw:Get() then return end

    if not font then
        font = Render.LoadFont("Arial", 12, Enum.FontCreate.FONTFLAG_OUTLINE)
    end

    for _, agent in pairs(agent_manager) do
        if agent.unit and Entity.IsAlive(agent.unit) then
            local offset = NPC.GetHealthBarOffset(agent.unit)
            if not offset or offset < 50 then offset = 150 end

            local p = Entity.GetAbsOrigin(agent.unit) + Vector(0, 0, offset + 20)
            local screen_pos, visible = Render.WorldToScreen(p)

            if visible then
                Render.Text(font, 12, agent.state .. " | " .. agent.thought, screen_pos, Color(200, 220, 255, 255))
            end
        end
    end
end

-- ============================================================================
-- GAME END CLEANUP
-- ============================================================================
function agent_script.OnGameEnd()
    my_hero, local_player, agent_manager = nil, nil, {}
end

return agent_script
