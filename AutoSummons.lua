local AutoSummons = {}

local BOAR_NAME = "npc_dota_beastmaster_boar"
local FORGE_SPIRIT_NAME = "npc_dota_invoker_forged_spirit"
local SUMMON_NAMES = { [BOAR_NAME] = true, [FORGE_SPIRIT_NAME] = true }
local SAFETY_MARGIN = 200
local SAFE_DIST_MARGIN = 25
local AUTO_DISABLE_AT_SECONDS = 8 * 60

local CONVAR_SUMMONED_AUTOATTACK = "dota_summoned_units_auto_attack_mode_2"
local SUMMONED_AUTOATTACK_STANDARD = 0
local SUMMONED_AUTOATTACK_FALLBACK = 2

local ORDER_ATTACK_TARGET = Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET
local ORDER_MOVE = Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION
local ORDER_HOLD = Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION
local ORDER_STOP = Enum.UnitOrder.DOTA_UNIT_ORDER_STOP

local ORDER_COOLDOWN = 0.5
local PROJECTILE_ATTACK_EXPIRE = 2.0

local HERO_MENU_NAMES = {
    ["npc_dota_hero_beastmaster"] = "Beastmaster",
    ["npc_dota_hero_invoker"] = "Invoker"
}

local g_main = Menu.Create("Scripts", "Other", "Auto Summons", "Main", "Main")
g_main:Parent():Parent():Icon("\u{f06e}")
local s_enable = g_main:Switch("Boar kiting (enemy attack range)", false)
local s_only_when_attacking = g_main:Switch("Only when enemy is attacking", true)
local s_enemy_target_check = g_main:Switch("Retreat only if enemy targets this summon", true)
local s_melee_fallback = g_main:Switch("Melee fallback (closest summon when no projectile)", false)
local s_hitrun = g_main:Switch("Hit-and-run on attack/combo (attack once then retreat)", true)
local s_order_cooldown = g_main:Slider("Order cooldown (x0.1 sec)", 2, 15, 5, "%d")

local last_issued = {}
local last_order_time = {}
local summon_attack_order = {}
local summon_was_attacking = {}
local hero_combo_widget = nil
local summoned_autoattack_convar_ref = nil
local projectile_attacks = {}
local prev_enabled = false
local saved_summoned_autoattack_value = nil

local function get_enemy_attack_range(npc)
    if not npc or not Entity.IsNPC(npc) then return 0 end
    local base = NPC.GetAttackRange(npc) or 0
    local bonus = NPC.GetAttackRangeBonus(npc) or 0
    return base + bonus
end

local function get_summons()
    local my_hero = Heroes.GetLocal()
    if not my_hero then return {} end
    local my_team = Entity.GetTeamNum(my_hero)
    local player_id = Hero.GetPlayerID(my_hero)
    local list = NPCs.GetAll()
    if not list then return {} end
    local out = {}
    for _, npc in pairs(list) do
        if npc and Entity.IsNPC(npc) and SUMMON_NAMES[NPC.GetUnitName(npc)] then
            local owner = NPC.GetOwnerNPC(npc)
            local is_ours = (owner == my_hero) or (Entity.GetTeamNum(npc) == my_team and NPC.IsControllableByPlayer(npc, player_id))
            if is_ours then
                out[#out + 1] = npc
            end
        end
    end
    return out
end

local function get_nearby_enemies(pos, radius, my_team)
    return NPCs.InRadius(pos, radius, my_team, Enum.TeamType.TEAM_ENEMY, false, true) or {}
end

local function is_our_summon(npc)
    if not npc or not Entity.IsNPC(npc) or not SUMMON_NAMES[NPC.GetUnitName(npc)] then return false end
    local my_hero = Heroes.GetLocal()
    if not my_hero then return false end
    local owner = NPC.GetOwnerNPC(npc)
    if owner == my_hero then return true end
    return Entity.GetTeamNum(npc) == Entity.GetTeamNum(my_hero) and NPC.IsControllableByPlayer(npc, Hero.GetPlayerID(my_hero))
end

local function retreat_position(boar_pos, enemy_pos, enemy_range, margin)
    local dx = boar_pos.x - enemy_pos.x
    local dy = boar_pos.y - enemy_pos.y
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then
        return boar_pos.x, boar_pos.y
    end
    local target_dist = enemy_range + margin
    local nx = dx / len
    local ny = dy / len
    local tx = enemy_pos.x + nx * target_dist
    local ty = enemy_pos.y + ny * target_dist
    return tx, ty
end

local function record_projectile_attack(source_npc, target_npc, expire_at)
    if not source_npc or not target_npc or not Entity.IsNPC(source_npc) or not Entity.IsNPC(target_npc) then return end
    local ti = Entity.GetIndex(target_npc)
    local si = Entity.GetIndex(source_npc)
    if not projectile_attacks[ti] then projectile_attacks[ti] = {} end
    projectile_attacks[ti][si] = expire_at
end

local function is_enemy_attacking_summon_by_projectile(enemy, unit, now)
    local ti = Entity.GetIndex(unit)
    local si = Entity.GetIndex(enemy)
    if not projectile_attacks[ti] then return false end
    local exp = projectile_attacks[ti][si]
    if not exp or exp < now then return false end
    return true
end

local function cleanup_expired_projectile_attacks(now)
    for ti, enemies in pairs(projectile_attacks) do
        for si, exp in pairs(enemies) do
            if exp < now then enemies[si] = nil end
        end
        local empty = true
        for _ in pairs(enemies) do empty = false break end
        if empty then projectile_attacks[ti] = nil end
    end
end

local function enemy_attacking_our_summon(enemy, unit, now, summons_set)
    if is_enemy_attacking_summon_by_projectile(enemy, unit, now) then return true end
    if not s_melee_fallback:Get() then return false end
    if not NPC.IsAttacking(enemy) then return false end
    if NPC.IsRanged(enemy) then return false end
    local enemy_pos = Entity.GetAbsOrigin(enemy)
    local unit_dist = Entity.GetAbsOrigin(unit):Distance2D(enemy_pos)
    for s, _ in pairs(summons_set) do
        if s and s ~= unit and Entity.GetAbsOrigin(s):Distance2D(enemy_pos) < unit_dist then
            return false
        end
    end
    return true
end

local function is_combo_key_down()
    if not hero_combo_widget then return false end
    local ok, key = pcall(function() return hero_combo_widget:Get() end)
    if not ok or not key or key == Enum.ButtonCode.KEY_NONE then return false end
    return Input.IsKeyDown(key)
end

function AutoSummons.OnProjectile(proj)
    if not proj or not proj.isAttack then return end
    local source = proj.source
    local target = proj.target
    if not source or not target or not Entity.IsNPC(source) or not Entity.IsNPC(target) then return end
    if not is_our_summon(target) then return end
    local my_hero = Heroes.GetLocal()
    if not my_hero then return end
    if Entity.GetTeamNum(source) == Entity.GetTeamNum(my_hero) then return end
    if not NPC.IsHero(source) then return end
    local now = os.clock()
    record_projectile_attack(source, target, now + PROJECTILE_ATTACK_EXPIRE)
end

function AutoSummons.OnPrepareUnitOrders(order)
    if not order or not order.npc then return true end
    local my_hero = Heroes.GetLocal()
    if not my_hero then return true end
    local my_team = Entity.GetTeamNum(my_hero)
    local units = type(order.npc) == "table" and order.npc or { order.npc }
    for _, npc in pairs(units) do
        if not npc or not Entity.IsNPC(npc) then goto next_unit end
        if not is_our_summon(npc) then goto next_unit end
        local key = Entity.GetIndex(npc)
        local ord = order.order
        if ord == ORDER_ATTACK_TARGET and order.target and Entity.IsNPC(order.target) and NPC.IsHero(order.target) and Entity.GetTeamNum(order.target) ~= my_team then
            summon_attack_order[key] = true
        elseif ord == ORDER_MOVE or ord == ORDER_HOLD or ord == ORDER_STOP then
            summon_attack_order[key] = nil
        end
        ::next_unit::
    end
    return true
end

function AutoSummons.OnUpdate()
    local game_start = GameRules.GetGameStartTime()
    if game_start > 0 then
        local ingame = GameRules.GetGameTime() - game_start
        if ingame >= AUTO_DISABLE_AT_SECONDS and s_enable:Get() then
            s_enable:Set(false)
        end
    end
    local enabled = s_enable:Get()
    if summoned_autoattack_convar_ref == nil then
        local ok, ref = pcall(ConVar.Find, CONVAR_SUMMONED_AUTOATTACK)
        if ok and ref ~= nil then summoned_autoattack_convar_ref = ref end
    end
    if summoned_autoattack_convar_ref ~= nil then
        if enabled and not prev_enabled then
            pcall(function()
                local v = ConVar.GetInt(summoned_autoattack_convar_ref)
                if v ~= nil then saved_summoned_autoattack_value = v end
                ConVar.SetInt(summoned_autoattack_convar_ref, SUMMONED_AUTOATTACK_STANDARD)
            end)
        elseif not enabled and prev_enabled then
            pcall(function()
                local restore = saved_summoned_autoattack_value
                if restore == nil then restore = SUMMONED_AUTOATTACK_FALLBACK end
                ConVar.SetInt(summoned_autoattack_convar_ref, restore)
                saved_summoned_autoattack_value = nil
            end)
        end
    end
    prev_enabled = enabled
    if not enabled then return end
    local my_hero = Heroes.GetLocal()
    if not my_hero then return end
    local my_team = Entity.GetTeamNum(my_hero)
    local summons = get_summons()
    if #summons == 0 then return end
    if not hero_combo_widget then
        local hero_name = NPC.GetUnitName(my_hero)
        local menu_name = HERO_MENU_NAMES[hero_name]
        if menu_name then
            hero_combo_widget = Menu.Find("Heroes", "Hero List", menu_name, "Main Settings", "Hero Settings", "Combo Key")
        end
    end
    local now = os.clock()
    cleanup_expired_projectile_attacks(now)
    local summons_set = {}
    for _, s in pairs(summons) do summons_set[s] = true end
    for _, unit in pairs(summons) do
        if not NPC.IsKillable(unit) then goto continue end
        local key = Entity.GetIndex(unit)
        local attacking_now = NPC.IsAttacking(unit)
        if s_hitrun:Get() then
            if attacking_now then
                summon_was_attacking[key] = true
            elseif summon_was_attacking[key] then
                summon_was_attacking[key] = nil
                summon_attack_order[key] = nil
            end
        else
            summon_was_attacking[key] = nil
        end
        local unit_pos = Entity.GetAbsOrigin(unit)
        local enemies = get_nearby_enemies(unit_pos, 1200, my_team)
        local best_enemy = nil
        local best_range = 0
        local need_retreat = false
        for _, enemy in pairs(enemies) do
            if not NPC.IsHero(enemy) then goto next_enemy end
            if not NPC.IsKillable(enemy) then goto next_enemy end
            local attack_range = get_enemy_attack_range(enemy)
            if attack_range <= 0 then goto next_enemy end
            local enemy_pos = Entity.GetAbsOrigin(enemy)
            local dist = unit_pos:Distance2D(enemy_pos)
            local threshold = attack_range + SAFETY_MARGIN + SAFE_DIST_MARGIN
            if dist < threshold then
                local enemy_attacking = not s_only_when_attacking:Get() or NPC.IsAttacking(enemy)
                if enemy_attacking then
                    if s_enemy_target_check:Get() then
                        if enemy_attacking_our_summon(enemy, unit, now, summons_set) then
                            need_retreat = true
                            if attack_range > best_range then
                                best_range = attack_range
                                best_enemy = enemy
                            end
                        end
                    else
                        need_retreat = true
                        if attack_range > best_range then
                            best_range = attack_range
                            best_enemy = enemy
                        end
                    end
                end
            end
            ::next_enemy::
        end
        local hitrun_mode = s_hitrun:Get() and (summon_attack_order[key] or is_combo_key_down())
        if hitrun_mode and attacking_now then
            goto continue
        end
        if not need_retreat or not best_enemy then
            last_issued[key] = nil
            last_order_time[key] = nil
            goto continue
        end
        if not hitrun_mode and summon_attack_order[key] then
            goto continue
        end
        local cooldown = (s_order_cooldown:Get() or 5) / 10.0
        if cooldown < ORDER_COOLDOWN then cooldown = ORDER_COOLDOWN end
        local last_time = last_order_time[key]
        if last_time and (now - last_time) < cooldown then
            goto continue
        end
        local enemy_pos = Entity.GetAbsOrigin(best_enemy)
        local enemy_range = get_enemy_attack_range(best_enemy)
        local tx, ty = retreat_position(unit_pos, enemy_pos, enemy_range, SAFETY_MARGIN)
        local last = last_issued[key]
        local target_changed = not last or math.abs(last.x - tx) > 30 or math.abs(last.y - ty) > 30
        if target_changed then
            last_issued[key] = { x = tx, y = ty }
            last_order_time[key] = now
            local target = Vector(tx, ty, unit_pos.z)
            NPC.MoveTo(unit, target, false, false, false, true)
        end
        ::continue::
    end
end

return AutoSummons
