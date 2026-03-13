-- Follow Selected Hero: follow a selected hero with safety logic + Io auto tether and preferred ally follow
---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
local follow = {}

-- -----------------------------------------------------------------------------
-- Lazy UI building
-- -----------------------------------------------------------------------------
local ui = {}
local built = false

local function BuildUI()
    if built then return end

    -- Use same menu pattern as other scripts (3-arg Create + double Create)
    local tab = Menu.Create("Heroes", "Hero List", "Io")

    -- Main controls
    local mainSettings = tab:Create("Main Settings")
    local group = mainSettings:Create("Auto Follow")
    ui.enabled = group:Switch("Ativar", true, "\u{f011}")
    ui.team = group:Combo("Time do Alvo", {"Aliados", "Inimigos"}, 0)
    -- Default to "None" so script does not follow anyone until the user explicitly selects
    ui.target = group:Combo("Herói Alvo", {"Nenhum"}, 0)
    ui.distance = group:Slider("Distância de Seguimento", 100, 1200, 350, "%d")
    ui.interval = group:Slider("Intervalo de Ordem (ms)", 50, 500, 150, "%d ms")
    ui.attack_move_enemy = group:Switch("Atacar-mover se inimigo", false, "\u{f140}")
    ui.stick_behind = group:Switch("Ficar atrás do alvo", true, "\u{f061}")
    ui.debug = group:Switch("Debug", false, "\u{f188}")

    -- Teleport options
    ui.tp_enabled = group:Switch("Usar TP/BoT quando longe", true, "\u{f362}")
    ui.tp_distance = group:Slider("Distância Mínima para TP", 1500, 10000, 3000, "%d")
    ui.tp_prefer_travels = group:Switch("Preferir Boots of Travel para unidade", true, "\u{f554}")

    -- Safety options
    ui.safe_follow = group:Switch("Seguimento Seguro Perto de Inimigos", true, "\u{f3ed}") -- shield-alt
    ui.enemy_radius = group:Slider("Raio de Perigo", 300, 2000, 900, "%d")
    ui.min_enemy_distance = group:Slider("Manter Distância de Inimigo", 200, 1800, 700, "%d")
    ui.team_cluster_radius = group:Slider("Raio de Agrupamento do Time", 500, 2500, 1200, "%d")
    ui.min_allies = group:Slider("Mínimo de Aliados no Grupo", 1, 5, 2, "%d")

    -- Io Assistant (new menu for Io-only features)
    local ioTab = mainSettings:Create("Tether Settings")
    ui.io_enabled = ioTab:Switch("Ativar Auto Tether do Io", true, "\u{f0c1}") -- link icon
    ui.io_use_follow_target = ioTab:Switch("Usar Alvo de Seguimento (Aliados)", true, "\u{f058}")

    -- By default, do not auto-follow preferred allies until the user enables it
    ui.io_force_follow_pref = ioTab:Switch("Sempre Seguir Aliado Preferido", false, "\u{f245}")

    -- Preferred allies list (multi-select)
    ui.io_pref_allies = ioTab:MultiSelect("Aliados Preferidos", {
        { "Sem aliados", "", false }
    }, true)

    -- Fallback single combo
    ui.io_target = ioTab:Combo("Alvo do Tether (Aliados)", {"Sem aliados"}, 0)

    ui.io_recast = ioTab:Switch("Re-conectar Tether se Quebrado", true, "\u{f2f1}")
    ui.io_interval = ioTab:Slider("Intervalo de Tentativa de Tether (ms)", 100, 1500, 300, "%d ms")

    built = true
end

-- -----------------------------------------------------------------------------
-- State / Utils
-- -----------------------------------------------------------------------------
local state = {
    targets = {},
    last_build_time = 0,
    next_order_time = 0,
    my_hero = nil,

    -- Io state
    io_allies = {},
    io_last_ally_update = 0,
    io_next_tether_time = 0,

    -- Order dedup
    last_move_dest = nil,

    -- Suppress movement after TP attempt to avoid canceling channel
    tp_suppress_until = 0
}

local function now()
    return GlobalVars.GetCurTime() or 0
end

local function my()
    state.my_hero = state.my_hero or Heroes.GetLocal()
    return state.my_hero
end

local function get_display_name(hero)
    local unit_name = NPC.GetUnitName(hero)
    local display = Engine.GetDisplayNameByUnitName(unit_name)
    return display or unit_name
end

local function hero_icon_for(unit_name)
    local short = string.match(unit_name or "", "npc_dota_hero_(.+)") or unit_name or "unknown"
    return "panorama/images/heroes/icons/" .. short .. "_png.vtex_c"
end

local function is_valid_follow_target(h)
    if not h then return false end
    if not Entity.IsAlive(h) then return false end
    if NPC.IsIllusion(h) then return false end
    if h == my() then return false end
    return true
end

-- Build ally list for Io menus (combo + multiselect)
local function rebuild_io_ally_list(force)
    if not built then return end

    local t = now()
    if not force and (t - state.io_last_ally_update) < 1.0 then return end
    state.io_last_ally_update = t

    if not Engine.IsInGame() then
        state.io_allies = {}
        ui.io_target:Update({"Sem aliados"}, 0)
        if ui.io_pref_allies then
            ui.io_pref_allies:Update({{"Sem aliados","",false}}, true)
        end
        return
    end

    local me = my()
    if not me then
        state.io_allies = {}
        ui.io_target:Update({"Sem aliados"}, 0)
        if ui.io_pref_allies then
            ui.io_pref_allies:Update({{"Sem aliados","",false}}, true)
        end
        return
    end

    local allies = {}
    local ally_names = {}
    local ms_options = {}
    for _, h in ipairs(Heroes.GetAll() or {}) do
        if h ~= me and Entity.IsAlive(h) and not NPC.IsIllusion(h) and Entity.IsSameTeam(me, h) then
            table.insert(allies, h)
            local disp = get_display_name(h)
            table.insert(ally_names, disp)
            table.insert(ms_options, { disp, hero_icon_for(NPC.GetUnitName(h)), false })
        end
    end

    if #allies == 0 then
        state.io_allies = {}
        ui.io_target:Update({"Sem aliados"}, 0)
        if ui.io_pref_allies then
            ui.io_pref_allies:Update({{"Sem aliados","",false}}, true)
        end
        return
    end

    state.io_allies = allies
    ui.io_target:Update(ally_names, 0)
    if ui.io_pref_allies then
        ui.io_pref_allies:Update(ms_options, true)
    end
end

local function rebuild_target_list(force)
    if not built then return end

    local t = now()
    if not force and (t - state.last_build_time) < 1.0 then
        rebuild_io_ally_list(false)
        return
    end
    state.last_build_time = t

    if not Engine.IsInGame() then
        -- In menu or not in game, show None so we never auto-follow
        ui.target:Update({"Nenhum"}, 0)
        state.targets = {}
        rebuild_io_ally_list(true)
        return
    end

    state.targets = {}
    local list = {"Nenhum"} -- sentinel as item 0, so default is no-follow

    local me = my()
    if not me then
        ui.target:Update(list, 0)
        rebuild_io_ally_list(true)
        return
    end

    local list_allies = (ui.team:Get() == 0)
    for _, h in ipairs(Heroes.GetAll() or {}) do
        if is_valid_follow_target(h) then
            local same = Entity.IsSameTeam(me, h)
            if (list_allies and same) or (not list_allies and not same) then
                table.insert(state.targets, h)                -- indices start at 1
                table.insert(list, get_display_name(h))       -- UI index 0 = None, 1..N = heroes
            end
        end
    end

    ui.target:Update(list, 0) -- keep selection at None by default
    rebuild_io_ally_list(true)
end

-- When team filter changes, rebuild list
local function EnsureCallbacks()
    if not built then return end
    if ui._callbacks_set then return end
    ui.team:SetCallback(function()
        rebuild_target_list(true)
    end)
    ui._callbacks_set = true
end

local function distance(a, b) return (b - a):Length2D() end

local function compute_dest(my_pos, target)
    local target_pos = Entity.GetAbsOrigin(target)
    local want = ui.distance:Get()
    local dest
    if ui.stick_behind:Get() then
        local forward = Entity.GetAbsRotation(target):GetForward():Normalized()
        dest = target_pos - forward * want
    else
        local dir = (target_pos - my_pos):Normalized()
        dest = target_pos - dir * want
    end
    return dest
end

-- Snap destination to a traversable position to avoid stuck oscillation on unpathable tiles
local function ensure_traversable_from(src, pos)
    if GridNav.IsTraversable(pos) then return pos end
    local dir = (pos - src):Normalized()
    local step = 64
    for i = 1, 12 do
        local test1 = pos + dir * (step * i)
        if GridNav.IsTraversable(test1) then return test1 end
        local test2 = pos - dir * (step * i)
        if GridNav.IsTraversable(test2) then return test2 end
    end
    return pos
end

-- -----------------------------------------------------------------------------
-- Teleport helpers
-- -----------------------------------------------------------------------------
local function is_in_fountain(unit)
    return NPC.HasModifier(unit, "modifier_fountain_aura")
end

-- Forward declarations for helpers used before their definitions
local get_item_by_names

local function get_tp_scroll(me)
    return get_item_by_names(me, { ["item_tpscroll"] = true, ["item_town_portal_scroll"] = true })
end

local function is_item_enabled(item)
    if not item then return false end
    if Item.IsItemEnabled and not Item.IsItemEnabled(item) then return false end
    return true
end

local function get_item_charges(item)
    if not item then return 0 end
    if Item.GetCurrentCharges then
        return Item.GetCurrentCharges(item) or 0
    end
    return 0
end

local function is_item_ready(item)
    if not item then return false end
    if not is_item_enabled(item) then return false end
    local charges = get_item_charges(item)
    if charges ~= nil and charges <= 0 then return false end
    return true
end

function get_item_by_names(me, names)
    for i = 0, 20 do
        local it = NPC.GetItemByIndex(me, i, true)
        if it then
            local nm = Ability.GetName(it)
            if nm and names[nm] then
                return it
            end
        end
    end
    return nil
end

local function get_travels(me)
    return get_item_by_names(me, { ["item_travel_boots"] = true, ["item_travel_boots_2"] = true })
end

local function issue_cast_target(me, ability, target)
    local p = Players.GetLocal()
    if not p or not ability or not target then return false end
    Player.PrepareUnitOrders(
        p,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
        target,
        nil,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        me
    )
    return true
end

local function issue_cast_position(me, ability, position)
    local p = Players.GetLocal()
    if not p or not ability or not position then return false end
    Player.PrepareUnitOrders(
        p,
        Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION,
        nil,
        position,
        ability,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        me
    )
    return true
end

local function nearest_allied_tower_to(position, me)
    local best, bestDist = nil, nil
    for _, t in ipairs(Towers.GetAll() or {}) do
        if t and Entity.IsAlive(t) and Entity.IsSameTeam(me, t) then
            local d = (position - Entity.GetAbsOrigin(t)):Length2D()
            if not best or d < bestDist then
                best, bestDist = t, d
            end
        end
    end
    return best
end

local function is_teleporting(unit)
    return NPC.HasModifier(unit, "modifier_teleporting")
end

local function attempt_tp_to_target(me, target)
    if not ui.tp_enabled:Get() then return false end
    if not me or not target then return false end

    state.next_tp_time = state.next_tp_time or 0
    if now() < state.next_tp_time then return false end

    local my_pos = Entity.GetAbsOrigin(me)
    local tg_pos = Entity.GetAbsOrigin(target)
    local dist = (my_pos - tg_pos):Length2D()
    local sameTeam = Entity.IsSameTeam(me, target)

    -- If we're in fountain, prefer using TP Scroll regardless of distance
    if is_in_fountain(me) then
        local tp = get_tp_scroll(me)
        if is_item_ready(tp) and Ability.IsCastable(tp, NPC.GetMana(me)) then
            local tower = nearest_allied_tower_to(tg_pos, me)
            if tower then
                if ui.debug:Get() then
                    print(string.format("[Follow][TP] Base: attempting TP Scroll to tower target (dist=%d, castable=true)", math.floor(dist)))
                end
                Ability.CastTarget(tp, tower)
                -- immediate position fallback to ensure TP fires
                Ability.CastPosition(tp, Entity.GetAbsOrigin(tower))
                issue_cast_position(me, tp, Entity.GetAbsOrigin(tower))
                state.next_tp_time = now() + 1.0
                state.tp_suppress_until = now() + 4.0
                if ui.debug:Get() then
                    print(string.format("[Follow][TP] In base: TP Scroll to tower near %s (dist=%d)", get_display_name(target), math.floor(dist)))
                end
                return true
            end
        end
        -- If no scroll, optionally try travels to ally unit
        if ui.tp_prefer_travels:Get() and sameTeam then
            local travels = NPC.GetItem(me, "item_travel_boots") or NPC.GetItem(me, "item_travel_boots_2")
            if travels and Ability.IsCastable(travels, NPC.GetMana(me)) then
                Ability.CastTarget(travels, target)
                state.next_tp_time = now() + 1.0
                if ui.debug:Get() then
                    print(string.format("[Follow][TP] In base: Boots of Travel to %s (dist=%d)", get_display_name(target), math.floor(dist)))
                end
                return true
            end
        end
    end

    if dist < ui.tp_distance:Get() then return false end
    if ui.debug:Get() then
        print(string.format("[Follow][TP] considering: dist=%d, sameTeam=%s", math.floor(dist), tostring(sameTeam)))
    end

    -- Prefer Boots of Travel directly to the unit if enabled
    if ui.tp_prefer_travels:Get() and sameTeam then
        local travels = get_travels(me)
        if travels and Ability.IsCastable(travels, NPC.GetMana(me)) then
            if ui.debug:Get() then
                print("[Follow][TP] attempting BoT to ally (Ability.CastTarget + order, castable=true)")
            end
            Ability.CastTarget(travels, target)
            issue_cast_target(me, travels, target)
            state.next_tp_time = now() + 2.5
            state.tp_suppress_until = now() + 4.0
            if ui.debug:Get() then
                print(string.format("[Follow][TP] Boots of Travel to %s (dist=%d)", get_display_name(target), math.floor(dist)))
            end
            return true
        end
    end

    -- Otherwise use TP Scroll to the nearest allied tower to the target
    local tp = get_tp_scroll(me)
    if is_item_ready(tp) and Ability.IsCastable(tp, NPC.GetMana(me)) then
        local tower = nearest_allied_tower_to(tg_pos, me)
        if tower then
            if ui.debug:Get() then print("[Follow][TP] attempting TP Scroll to tower target (Ability.CastTarget + order, castable=true)") end
            Ability.CastTarget(tp, tower)
            issue_cast_target(me, tp, tower)
            -- immediate position fallback to ensure TP fires
            Ability.CastPosition(tp, Entity.GetAbsOrigin(tower))
            issue_cast_position(me, tp, Entity.GetAbsOrigin(tower))
            state.next_tp_time = now() + 2.5
            state.tp_suppress_until = now() + 4.0
            if ui.debug:Get() then
                print(string.format("[Follow][TP] TP Scroll to tower near %s (dist=%d)", get_display_name(target), math.floor(dist)))
            end
            return true
        end
        -- fallback: try ground position near target
        if ui.debug:Get() then
            print("[Follow][TP] tower not found; attempting TP Scroll to target position (castable=true)")
        end
        Ability.CastPosition(tp, tg_pos)
        issue_cast_position(me, tp, tg_pos)
        state.next_tp_time = now() + 2.5
        state.tp_suppress_until = now() + 4.0
        return true
    end

    if ui.debug:Get() then
        local tp_dbg = get_tp_scroll(me)
        local charges = get_item_charges(tp_dbg)
        print(string.format("[Follow][TP] no TP/BoT available or not castable (tp=%s, charges=%s, enabled=%s)", tostring(tp_dbg ~= nil), tostring(charges), tostring(tp_dbg and is_item_enabled(tp_dbg))))
    end

    return false
end

-- -----------------------------------------------------------------------------
-- Safety helpers
-- -----------------------------------------------------------------------------
local function get_nearest_enemy(me, radius)
    local enemies = Entity.GetHeroesInRadius(me, radius, Enum.TeamType.TEAM_ENEMY) or {}
    local my_pos = Entity.GetAbsOrigin(me)
    local nearest, best = nil, nil
    for _, e in ipairs(enemies) do
        if e and Entity.IsAlive(e) and not NPC.IsIllusion(e) then
            local d = (my_pos - Entity.GetAbsOrigin(e)):Length2D()
            if not best or d < best then
                best = d
                nearest = e
            end
        end
    end
    return nearest, best
end

local function get_nearest_enemy_to(unit, radius)
    local enemies = Entity.GetHeroesInRadius(unit, radius, Enum.TeamType.TEAM_ENEMY) or {}
    local upos = Entity.GetAbsOrigin(unit)
    local nearest, best = nil, nil
    for _, e in ipairs(enemies) do
        if e and Entity.IsAlive(e) and not NPC.IsIllusion(e) then
            local d = (upos - Entity.GetAbsOrigin(e)):Length2D()
            if not best or d < best then
                best = d
                nearest = e
            end
        end
    end
    return nearest, best
end

local function get_allies_cluster(me, radius)
    local allies = Entity.GetHeroesInRadius(me, radius, Enum.TeamType.TEAM_FRIEND) or {}
    local sum = Vector(0,0,0)
    local n = 0
    for _, a in ipairs(allies) do
        if a and a ~= me and Entity.IsAlive(a) and not NPC.IsIllusion(a) then
            local p = Entity.GetAbsOrigin(a)
            sum = Vector(sum.x + p.x, sum.y + p.y, sum.z + p.z)
            n = n + 1
        end
    end
    if n == 0 then return nil, 0 end
    return Vector(sum.x / n, sum.y / n, World.GetGroundZ(sum.x / n, sum.y / n)), n
end

local function is_wisp(me)
    local name = me and NPC.GetUnitName(me) or nil
    return name == "npc_dota_hero_wisp" or name == "npc_dota_hero_io"
end

-- Io-aware safety
local function apply_safety(dest, follow_target)
    if not ui.safe_follow:Get() then return dest end
    local me = my()
    if not me then return dest end

    local io_mode = is_wisp(me) and follow_target and Entity.IsSameTeam(me, follow_target)

    if io_mode then
        local enemy = select(1, get_nearest_enemy_to(follow_target, ui.enemy_radius:Get() + 200))
        if not enemy then return dest end

        local ally_pos = Entity.GetAbsOrigin(follow_target)
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local away_dir = (ally_pos - enemy_pos):Normalized()

        local tether = NPC.GetAbility(me, "wisp_tether") or NPC.GetAbility(me, "io_tether")
        local tether_range = (tether and Ability.GetCastRange(tether)) or 1000

        local minStick = 250
        local maxStick = math.max(500, math.floor(tether_range * 0.45))
        local stick = ui.distance:Get()
        if stick < minStick then stick = minStick end
        if stick > maxStick then stick = maxStick end

        local chosen = ally_pos + away_dir * stick

        local minEnemy = ui.min_enemy_distance:Get()
        local d2 = (chosen - enemy_pos):Length2D()
        if d2 < minEnemy then
            local dir = (chosen - enemy_pos):Normalized()
            chosen = enemy_pos + dir * minEnemy
        end

        return chosen
    end

    local enemy = select(1, get_nearest_enemy(me, ui.enemy_radius:Get()))
    if not enemy then return dest end

    local cluster_center, count = get_allies_cluster(me, ui.team_cluster_radius:Get())
    local chosen = dest

    if cluster_center and count >= ui.min_allies:Get() then
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local away = (cluster_center - enemy_pos):Normalized()
        local want = math.max(ui.distance:Get(), ui.min_enemy_distance:Get())
        chosen = cluster_center + away * want
    else
        local enemy_pos = Entity.GetAbsOrigin(enemy)
        local my_pos = Entity.GetAbsOrigin(me)
        local away = (my_pos - enemy_pos):Normalized()
        chosen = my_pos + away * math.max(300, ui.min_enemy_distance:Get())
    end

    local enemy_pos2 = Entity.GetAbsOrigin(enemy)
    local d2 = (chosen - enemy_pos2):Length2D()
    local min_d = ui.min_enemy_distance:Get()
    if d2 < min_d then
        local dir = (chosen - enemy_pos2):Normalized()
        chosen = enemy_pos2 + dir * min_d
    end

    return chosen
end

-- -----------------------------------------------------------------------------
-- Io Tether logic
-- -----------------------------------------------------------------------------
local function is_tethered_to_any(target)
    if not target then return false end
    return NPC.HasModifier(target, "modifier_wisp_tether")
end

local function pick_preferred_ally()
    if not built or not ui.io_pref_allies then return nil end
    local me = my()
    if not me then return nil end

    local enabled = {}
    if ui.io_pref_allies.ListEnabled then
        for _, n in ipairs(ui.io_pref_allies:ListEnabled() or {}) do
            enabled[n] = true
        end
    end
    if not next(enabled) then return nil end

    local best, bestDist = nil, nil
    local mePos = Entity.GetAbsOrigin(me)
    for _, ally in ipairs(state.io_allies or {}) do
        if Entity.IsAlive(ally) and not NPC.IsIllusion(ally) then
            local disp = get_display_name(ally)
            if enabled[disp] then
                local d = (mePos - Entity.GetAbsOrigin(ally)):Length2D()
                if not best or d < bestDist then
                    best = ally
                    bestDist = d
                end
            end
        end
    end
    return best
end

local function attempt_io_tether(follow_target)
    local me = my()
    if not me or not is_wisp(me) then return end
    if not ui.io_enabled:Get() then return end
    if now() < state.io_next_tether_time then return end

    -- Determine tether target
    local tether_target = nil
    if ui.io_use_follow_target:Get() and follow_target and Entity.IsSameTeam(me, follow_target) then
        tether_target = follow_target
    else
        tether_target = pick_preferred_ally()
        if not tether_target then
            local idx = (ui.io_target:Get() or 0) + 1
            tether_target = state.io_allies and state.io_allies[idx] or nil
        end
    end
    if not tether_target or not Entity.IsAlive(tether_target) then return end

    -- IMPORTANT: Do not recast if already tethered to chosen target (prevents crazy stuck behavior)
    if is_tethered_to_any(tether_target) and not ui.io_recast:Get() then
        return
    end

    local tether = NPC.GetAbility(me, "wisp_tether") or NPC.GetAbility(me, "io_tether")
    if not tether then return end

    local mana_ok = Ability.IsCastable(tether, NPC.GetMana(me))
    local cast_range = Ability.GetCastRange(tether)
    if not cast_range or cast_range <= 0 then cast_range = 1000 end

    local my_pos = Entity.GetAbsOrigin(me)
    local tg_pos = Entity.GetAbsOrigin(tether_target)
    local dist = (my_pos - tg_pos):Length2D()

    if mana_ok and dist <= cast_range + 50 then
        Ability.CastTarget(tether, tether_target)
        state.io_next_tether_time = now() + (ui.io_interval:Get() / 1000.0)
        if ui.debug:Get() then
            print(string.format("[Io] Tether cast to %s (dist=%d)", get_display_name(tether_target), math.floor(dist)))
        end
    end
end

-- -----------------------------------------------------------------------------
-- Callbacks
-- -----------------------------------------------------------------------------
function follow.OnScriptsLoaded()
    BuildUI()
    EnsureCallbacks()
    if built then
        ui.target:Update({"Nenhum"}, 0)     -- default to None
        ui.io_target:Update({"Sem aliados"}, 0)
        if ui.io_pref_allies then
            ui.io_pref_allies:Update({{"Sem aliados","",false}}, true)
        end
    end
end

function follow.OnFrame()
    BuildUI()
    EnsureCallbacks()
    rebuild_target_list(false)
end

function follow.OnUpdate()
    BuildUI()
    EnsureCallbacks()

    if not built or not ui.enabled:Get() then return end
    if not Engine.IsInGame() then return end

    local me = my()
    if not me or not Entity.IsAlive(me) then return end

    rebuild_target_list(false)

    -- Determine initial follow target from main UI.
    -- The combo is 0-based with 0 = "None". Only map to state.targets when > 0.
    local target = nil
    local sel = ui.target:Get()
    if sel and sel > 0 and sel <= #state.targets then
        target = state.targets[sel]
        if target and not Entity.IsAlive(target) then target = nil end
    end

    -- If we're playing Io and the user wants to always follow preferred ally, override
    if is_wisp(me) and ui.io_enabled:Get() and ui.io_force_follow_pref:Get() then
        local pref = pick_preferred_ally()
        if pref then
            target = pref
        end
    end

    if not target then
        rebuild_io_ally_list(false)
        return
    end

    -- If we're channeling a teleport, or we just issued one, do nothing
    if is_teleporting(me) then return end
    if now() < state.tp_suppress_until then return end

    -- Try to TP closer if the target is too far
    if attempt_tp_to_target(me, target) then return end

    attempt_io_tether(target)

    local my_pos = Entity.GetAbsOrigin(me)
    local base_dest = compute_dest(my_pos, target)
    local safe_dest = apply_safety(base_dest, target)
    local dest = ensure_traversable_from(my_pos, safe_dest)

    local dist_to_dest = (dest - my_pos):Length2D()
    local move_threshold = 30

    if dist_to_dest < move_threshold then return end
    if now() < state.next_order_time then return end
    if state.last_move_dest and (dest - state.last_move_dest):Length2D() < 20 then
        return
    end

    state.next_order_time = now() + (ui.interval:Get() / 1000.0)
    state.last_move_dest = dest

    local p = Players.GetLocal()
    if not p then return end

    local is_enemy_target = not Entity.IsSameTeam(me, target)
    if is_enemy_target and ui.attack_move_enemy:Get() then
        Player.PrepareUnitOrders(
            p,
            Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE,
            nil,
            dest,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            me
        )
    else
        Player.PrepareUnitOrders(
            p,
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            dest,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            me
        )
    end

    if ui.debug:Get() then
        print(string.format("[Follow] move to (%.0f, %.0f, %.0f) | d=%.0f", dest.x, dest.y, dest.z, math.floor(dist_to_dest)))
    end
end

function follow.OnGameEnd()
    state.targets = {}
    state.my_hero = nil
    state.next_order_time = 0
    state.last_build_time = 0
    state.last_move_dest = nil

    state.io_allies = {}
    state.io_last_ally_update = 0
    state.io_next_tether_time = 0

    if built then
        ui.target:Update({"Nenhum"}, 0)
        ui.io_target:Update({"Sem aliados"}, 0)
        if ui.io_pref_allies then
            ui.io_pref_allies:Update({{"Sem aliados","",false}}, true)
        end
    end
end

return follow