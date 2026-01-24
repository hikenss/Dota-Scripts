
-- Force Staff Direction Indicator
-- Script for visualizing push directions of Force Staff and Hurricane Pike

local ForceStaffIndicator = {}

-- =============================================================================
-- CONSTANTS
-- =============================================================================

local FORCE_STAFF_RANGE = 600
local HURRICANE_PIKE_RANGE = 450
local PSYCHIC_HEADBAND_RANGE = 400
local ITEM_NAMES = {
    FORCE_STAFF = "item_force_staff",
    FORCE_STAFF_2 = "item_force_staff_2",
    HURRICANE_PIKE = "item_hurricane_pike",
    PSYCHIC_HEADBAND = "item_psychic_headband"
}


local enemy_heroes_names = {}
local enemy_heroes_enabled = {}
local ally_heroes_names = {}
local ally_heroes_enabled = {}
local hero_display_to_code = {}
local hero_code_to_display = {}

local last_heroes_update_time = 0

local fs_menu = Menu.Create("Scripts", "Outros", "Force Staff Direction")
fs_menu:Icon("\u{2614}")

local main_group = Menu.Create("Scripts", "Outros", "Force Staff Direction", "Principal", "Geral")
local Toggle = main_group:Switch("Ativar indicador", true)
local s_toggle_bind = main_group:Bind("Tecla para ligar/desligar", Enum.ButtonCode.BUTTON_CODE_INVALID)
local s_show_allies = main_group:Switch("Mostrar aliados e eu", true)
local s_show_enemies = main_group:Switch("Mostrar inimigos", true)
local s_hover_radius = main_group:Slider("Raio de mira", 5, 80, 50, "%d")
local s_show_on_cooldown = main_group:Switch("Mostrar mesmo em recarga", false)
s_show_on_cooldown:ToolTip("Mostrar o indicador mesmo se o item estiver em recarga.\nNão funciona junto com a opção 'Apenas quando ativo'.")
local s_only_when_active = main_group:Switch("Apenas quando ativo", false)
s_only_when_active:ToolTip("Mostrar o indicador só quando Force Staff ou \nHurricane Pike estiver selecionado para uso (modo de alvo)")


local draw_group = Menu.Create("Scripts", "Outros", "Force Staff Direction", "Principal", "Exibição nos heróis")
local s_always_self = draw_group:Switch("Sempre mostrar o próprio herói", false)
s_always_self:ToolTip("Mostrar sempre a trajetória para você \nsem precisar passar o cursor")
local s_always_allies_switch = draw_group:Switch("Sempre mostrar aliados", false)
s_always_allies_switch:ToolTip("Mostrar sempre a trajetória dos aliados escolhidos \nsem precisar passar o cursor")
local s_always_allies = draw_group:MultiCombo("Quais aliados mostrar", {}, {})
local s_always_enemies_switch = draw_group:Switch("Sempre mostrar inimigos", false)
s_always_enemies_switch:ToolTip("Escolha inimigos cuja trajetória \nserá exibida sempre, sem passar o cursor.")
local s_always_enemies = draw_group:MultiCombo("Quais inimigos mostrar", {}, {})
local s_always_override_active = draw_group:MultiCombo("Ignorar 'Apenas quando ativo' para:", {"Herói principal", "Aliados", "Inimigos"}, {"Herói principal", "Aliados", "Inimigos"})
s_always_override_active:ToolTip("Permite que 'Sempre mostrar' funcione \nmesmo com 'Apenas quando ativo'.")

local extra_group = Menu.Create("Scripts", "Outros", "Force Staff Direction", "Principal", "Extras")
local s_resistance_heroes = extra_group:MultiCombo("Heróis com resistência", {}, {})
s_resistance_heroes:ToolTip("Selecione heróis que têm \n40% de resistência ao empurrão da habilidade Tough")
local s_include_meepo_clones = extra_group:Switch("Clones do Meepo", false)
s_include_meepo_clones:ToolTip("Considera clones do Meepo ao mostrar no modo 'Sempre mostrar...'.")
local s_prioritize_headband = extra_group:Switch("Priorizar Psychic Headband", false)
s_prioritize_headband:ToolTip("Se ligado, Psychic Headband tem prioridade sobre Pike/Force Staff ao calcular trajetória.")
local s_show_creeps = extra_group:Switch("Mostrar creeps", false)
s_show_creeps:ToolTip("Desenhar a trajetória de um creep ao apontar.")

local visual_group = Menu.Create("Scripts", "Outros", "Force Staff Direction", "Visual", "Opções visuais")
local s_thickness = visual_group:Slider("Espessura da linha", 1, 20, 8, "%d")
local s_end_point_size = visual_group:Slider("Tamanho do ponto final", 0, 20, 8, "%d")
local s_creep_thickness_mult = visual_group:Slider("Multiplicador de espessura para creeps", 0.1, 1, 0.6, "%.1f")
local s_gradient_length = visual_group:Slider("Comprimento do gradiente", 0, 50, 25, "%d")
local s_enable_gradient = visual_group:Switch("Ativar gradiente", true)
local s_gradient_alpha_start = visual_group:Slider("Opacidade do gradiente", 0, 100, 90, "%d%%")
local s_color_self = visual_group:ColorPicker("Cor do herói principal", Color(38, 120, 235, 255))
local s_color_ally = visual_group:ColorPicker("Cor dos aliados", Color(20, 198, 20, 255))
local s_color_enemy = visual_group:ColorPicker("Cor dos inimigos", Color(170, 38, 38, 255))

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

local function GetHeroFacingDirection(hero)
    if not hero then return Vector(0, 0, 0) end
    local rotation = Entity.GetRotation(hero)
    return rotation:GetForward()
end

local function HasPushItem(hero)
    if not hero or not Entity.IsAlive(hero) then
        return false, nil, nil
    end

    local items
    -- Порядок проверки с опциональным приоритетом Psychic Headband
    if s_prioritize_headband:Get() then
        items = {ITEM_NAMES.PSYCHIC_HEADBAND, ITEM_NAMES.HURRICANE_PIKE, ITEM_NAMES.FORCE_STAFF, ITEM_NAMES.FORCE_STAFF_2}
    else
        items = {ITEM_NAMES.HURRICANE_PIKE, ITEM_NAMES.PSYCHIC_HEADBAND, ITEM_NAMES.FORCE_STAFF, ITEM_NAMES.FORCE_STAFF_2}
    end

    local show_on_cd = s_show_on_cooldown:Get()

    for _, item_name in ipairs(items) do
        local item = NPC.GetItem(hero, item_name)
        if item then
            local is_ready = Ability.IsReady(item)
            local should_show = is_ready or (is_ready or show_on_cd)
            if should_show then
                local item_type = "force_staff"
                if item_name == ITEM_NAMES.HURRICANE_PIKE then
                    item_type = "hurricane_pike"
                elseif item_name == ITEM_NAMES.PSYCHIC_HEADBAND then
                    item_type = "psychic_headband"
                end
                return true, item, item_type
            end
        end
    end
    return false, nil, nil
end

local function GetPushRange(hero, local_hero, base_range)
    if not hero or not local_hero then return base_range end
    local is_enemy = Entity.GetTeamNum(hero) ~= Entity.GetTeamNum(local_hero)

    local push_resistance = 0
    if is_enemy then
        local hero_name = NPC.GetUnitName(hero)
        if hero_name == "npc_dota_hero_magnataur" then
            -- Проверка на дебафф "break" (снятие сопротивления статусу)
            local modifiers = NPC.GetModifiers(hero)
            local has_break = false
            for _, mod in ipairs(modifiers) do
                local mod_name = Modifier.GetName(mod)
                if mod_name and string.find(mod_name, "break") then
                    has_break = true
                    break
                end
            end
            if not has_break then
                push_resistance = 0.5
            end
        end

        if s_resistance_heroes then
            local enabled_heroes = s_resistance_heroes:ListEnabled()
            for _, enabled_display in ipairs(enabled_heroes) do
                local enabled_code = hero_display_to_code[enabled_display]
                if enabled_code == hero_name then
                    push_resistance = push_resistance + 0.4
                    break
                end
            end
        end
    end

    return base_range * (1 - push_resistance)
end


local function DrawTerrainAwareTrajectory(start_pos, direction, range, color, segments, size_mult)
    if not start_pos or not direction then return end

    local mul = size_mult or 1

    local thickness = s_thickness:Get() * mul
    local enable_gradient = s_enable_gradient:Get()
    local gradient_alpha_start = (100 - s_gradient_alpha_start:Get()) * 255 / 100
    local gradient_length = s_gradient_length:Get() / 50
    local end_point_size = s_end_point_size:Get() * mul

    local dir_length = math.sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
    if dir_length == 0 then return end

    local points = {}
    local start_screen = Render.WorldToScreen(start_pos + Vector(0, 0, 50))
    if not start_screen then return end
    
    points[1] = start_screen

    for i = 1, segments do
        local t = i / segments
        local distance = range * t
        
        local trajectory_pos = start_pos + direction * distance
        local ground_z = World.GetGroundZ(trajectory_pos.x, trajectory_pos.y)
        local final_pos = Vector(trajectory_pos.x, trajectory_pos.y, ground_z)
        local final_screen = Render.WorldToScreen(final_pos + Vector(0, 0, 50))
        
        if final_screen then
            points[i + 1] = final_screen
        end
    end

    for i = 1, #points - 1 do
        local t = (i - 1) / segments
        local alpha
        
        if enable_gradient and gradient_length > 0 then
            if t < gradient_length then
                alpha = math.floor(gradient_alpha_start + (color.a - gradient_alpha_start) * (t / gradient_length))
            else
                alpha = color.a
            end
        else
            alpha = color.a
        end
        
        local line_color = Color(color.r, color.g, color.b, alpha)
        if points[i] and points[i + 1] then
            Render.Line(points[i], points[i + 1], line_color, thickness)
        end
    end

    if #points > 0 and end_point_size > 0 then
        Render.FilledCircle(points[#points], end_point_size, color)
    end
end

-- =============================================================================
-- MAIN DRAW FUNCTION
-- =============================================================================

function ForceStaffIndicator.OnDraw()

    if Input.IsKeyDownOnce(s_toggle_bind:Get()) then
        Toggle:Set(not Toggle:Get())
    end

    if not Toggle:Get() or not Engine.IsInGame() or Engine.IsShopOpen() then return end

    local local_hero = Heroes.GetLocal()
    if not local_hero then return end

    -- Обновление списков героев не чаще, чем раз в 1 секунду
    local now = os.clock()
    if now - last_heroes_update_time > 1 then
        last_heroes_update_time = now

        local was_empty_before = (#enemy_heroes_names == 0 and #ally_heroes_names == 0)
        local prev_resistance_enabled = s_resistance_heroes and s_resistance_heroes:ListEnabled() or {}
        local prev_always_allies_enabled = s_always_allies and s_always_allies:ListEnabled() or {}
        local prev_always_enemies_enabled = s_always_enemies and s_always_enemies:ListEnabled() or {}

        local local_team = Entity.GetTeamNum(local_hero)
        local all_heroes = Heroes.GetAll()
        local new_enemy_heroes_names, new_ally_heroes_names = {}, {}
        local seen_enemy, seen_ally = {}, {}
        local new_ally_heroes_enabled, new_enemy_heroes_enabled = {}, {}
        local new_resistance_enabled = {}
        local new_hero_display_to_code, new_hero_code_to_display = {}, {}
        for _, hero in ipairs(all_heroes) do
            if NPC.IsHero(hero) then
                local code_name = NPC.GetUnitName(hero)
                local display_name = GameLocalizer.FindNPC(code_name)
                if display_name == "" then display_name = code_name end
                new_hero_display_to_code[display_name] = code_name
                new_hero_code_to_display[code_name] = display_name
                -- Исключаем иллюзии из списков и дедуплицируем по имени
                local is_illusion = NPC.IsIllusion and NPC.IsIllusion(hero) or false
                if not is_illusion then
                    if Entity.GetTeamNum(hero) ~= local_team then
                        if not seen_enemy[display_name] then
                            table.insert(new_enemy_heroes_names, display_name)
                            seen_enemy[display_name] = true
                        end
                    elseif hero ~= local_hero then
                        if not seen_ally[display_name] then
                            table.insert(new_ally_heroes_names, display_name)
                            table.insert(new_ally_heroes_enabled, display_name)
                            seen_ally[display_name] = true
                        end
                    end
                end
            end
        end
        local need_update = false
        if #new_enemy_heroes_names ~= #enemy_heroes_names or #new_ally_heroes_names ~= #ally_heroes_names then
            need_update = true
        else
            for i, v in ipairs(new_enemy_heroes_names) do if v ~= enemy_heroes_names[i] then need_update = true break end end
            for i, v in ipairs(new_ally_heroes_names) do if v ~= ally_heroes_names[i] then need_update = true break end end
        end
        if need_update then
            enemy_heroes_names = new_enemy_heroes_names
            ally_heroes_names = new_ally_heroes_names

            -- Сохраняем выбор пользователя (пересечение), а при первом заполнении задаём дефолты
            if was_empty_before and #prev_always_allies_enabled == 0 then
                for i = 1, #ally_heroes_names do
                    new_ally_heroes_enabled[#new_ally_heroes_enabled + 1] = ally_heroes_names[i]
                end
            else
                local set_prev = {}
                for _, v in ipairs(prev_always_allies_enabled) do set_prev[v] = true end
                for _, v in ipairs(ally_heroes_names) do
                    if set_prev[v] then
                        new_ally_heroes_enabled[#new_ally_heroes_enabled + 1] = v
                    end
                end
            end

            if was_empty_before and #prev_always_enemies_enabled == 0 then
                for i = 1, #enemy_heroes_names do
                    new_enemy_heroes_enabled[#new_enemy_heroes_enabled + 1] = enemy_heroes_names[i]
                end
            else
                local set_prev = {}
                for _, v in ipairs(prev_always_enemies_enabled) do set_prev[v] = true end
                for _, v in ipairs(enemy_heroes_names) do
                    if set_prev[v] then
                        new_enemy_heroes_enabled[#new_enemy_heroes_enabled + 1] = v
                    end
                end
            end

            do
                local set_prev = {}
                for _, v in ipairs(prev_resistance_enabled) do set_prev[v] = true end
                for _, v in ipairs(enemy_heroes_names) do
                    if set_prev[v] then
                        new_resistance_enabled[#new_resistance_enabled + 1] = v
                    end
                end
            end

            ally_heroes_enabled = new_ally_heroes_enabled
            enemy_heroes_enabled = new_enemy_heroes_enabled
            hero_display_to_code = new_hero_display_to_code
            hero_code_to_display = new_hero_code_to_display

            if s_resistance_heroes then
                s_resistance_heroes:Update(enemy_heroes_names, new_resistance_enabled)
            end
            if s_always_allies then
                s_always_allies:Update(ally_heroes_names, ally_heroes_enabled)
            end
            if s_always_enemies then
                s_always_enemies:Update(enemy_heroes_names, enemy_heroes_enabled)
            end
        end
    end

    local player = Players.GetLocal and Players.GetLocal() or nil
    local allow_draw = false
    if s_only_when_active:Get() and player then
        local active_ability = Player.GetActiveAbility(player)
        local active_name = active_ability and Ability.GetName(active_ability) or nil
        local is_force_active = active_name == ITEM_NAMES.FORCE_STAFF or active_name == ITEM_NAMES.FORCE_STAFF_2
        local is_pike_active = active_name == ITEM_NAMES.HURRICANE_PIKE
        local is_headband_active = active_name == ITEM_NAMES.PSYCHIC_HEADBAND
        if is_force_active or is_pike_active or is_headband_active then
            allow_draw = true
        end
    end

    -- Подготовка флагов override для логики по каждому герою
    local override_list = s_always_override_active:ListEnabled()
    local override_self = false
    local override_allies = false
    local override_enemies = false
    for _, v in ipairs(override_list) do
        if v == "Herói principal" then override_self = true end
        if v == "Aliados" then override_allies = true end
        if v == "Inimigos" then override_enemies = true end
    end

    -- Если включено "Только когда активно" и предмет не в режиме выбора цели,
    -- то ничего не делаем, кроме случаев, когда есть override для себя/союзников
    if s_only_when_active:Get() and not allow_draw then
        local show_all_self = s_always_self:Get() and override_self
        local show_all_allies = s_always_allies_switch:Get() and override_allies
        local always_allies = s_always_allies:ListEnabled()
        local show_all_enemies = s_always_enemies_switch and s_always_enemies_switch:Get() and override_enemies
        local always_enemies = s_always_enemies and s_always_enemies:ListEnabled() or {}

        local local_hero = Heroes.GetLocal()
        if not local_hero then return end

        local heroes_to_process = {}
        if show_all_self then
            table.insert(heroes_to_process, local_hero)
        end
        if show_all_allies and s_show_allies:Get() then
            for _, display_name in ipairs(always_allies) do
                local code_name = hero_display_to_code[display_name]
                for _, hero in ipairs(Heroes.GetAll()) do
                    if NPC.GetUnitName(hero) == code_name and Entity.IsAlive(hero) then
                        local is_illusion = NPC.IsIllusion and NPC.IsIllusion(hero) or false
                        if not is_illusion then
                            table.insert(heroes_to_process, hero)
                            if not (s_include_meepo_clones:Get() and code_name == "npc_dota_hero_meepo") then
                                break
                            end
                        end
                    end
                end
            end
        end
        if show_all_enemies and s_show_enemies:Get() then
            for _, display_name in ipairs(always_enemies) do
                local code_name = hero_display_to_code[display_name]
                for _, hero in ipairs(Heroes.GetAll()) do
                    if NPC.GetUnitName(hero) == code_name and Entity.IsAlive(hero) then
                        local is_illusion = NPC.IsIllusion and NPC.IsIllusion(hero) or false
                        if not is_illusion then
                            table.insert(heroes_to_process, hero)
                            if not (s_include_meepo_clones:Get() and code_name == "npc_dota_hero_meepo") then
                                break
                            end
                        end
                    end
                end
            end
        end
        -- если нечего рисовать — просто выйти
        if #heroes_to_process == 0 then return end

        -- рисуем только для себя/союзников/врагов с override
        local item_type = nil
        local has_item, _, _item_type = HasPushItem(local_hero)
        if not has_item then return end
        item_type = _item_type
        local cursor_x, cursor_y = Input.GetCursorPos()
        for _, hovered_hero in ipairs(heroes_to_process) do
            local is_self = hovered_hero == local_hero
            local is_creep = not NPC.IsHero(hovered_hero)
            local is_ally = Entity.GetTeamNum(hovered_hero) == Entity.GetTeamNum(local_hero)
            local is_enemy = not is_ally
            local hero_origin = Entity.GetAbsOrigin(hovered_hero)
            local is_visible = Render.WorldToScreen(hero_origin + Vector(0, 0, 50))
            if not is_visible then goto continue_override end
            if (is_ally and not s_show_allies:Get()) or (is_enemy and not s_show_enemies:Get()) then goto continue_override end
            local color = (is_self and s_color_self:Get()) or (is_ally and s_color_ally:Get()) or s_color_enemy:Get()
            local size_mult = is_creep and s_creep_thickness_mult:Get() or 1
            if is_self and s_always_self:Get() and item_type == "hurricane_pike" then
                -- Если override для себя, то всегда рисуем только траекторию вперёд, не учитывая наведение на врага
                local direction = GetHeroFacingDirection(hovered_hero)
                local range = GetPushRange(hovered_hero, local_hero, FORCE_STAFF_RANGE)
                local self_color = s_color_self:Get()
                DrawTerrainAwareTrajectory(hero_origin, direction, range, self_color, 100, size_mult)
            elseif item_type == "force_staff" or (item_type == "hurricane_pike" and is_ally) then
                local direction = GetHeroFacingDirection(hovered_hero)
                local range = GetPushRange(hovered_hero, local_hero, FORCE_STAFF_RANGE)
                DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
            elseif item_type == "psychic_headband" and not is_self then
                local local_pos = Entity.GetAbsOrigin(local_hero)
                local direction = (hero_origin - local_pos):Normalized()
                local range = GetPushRange(hovered_hero, local_hero, PSYCHIC_HEADBAND_RANGE)
                DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
            elseif is_enemy then
                -- Для врагов: рисовать только если включён 'Всегда показывать врагов' и враг выбран в списке
                if s_always_enemies_switch and s_always_enemies_switch:Get() and override_enemies then
                    local code_name = NPC.GetUnitName(hovered_hero)
                    local display_name = hero_code_to_display[code_name] or code_name
                    local found = false
                    for _, v in ipairs(always_enemies) do
                        if v == display_name then found = true break end
                    end
                    if found then
                        local range = GetPushRange(hovered_hero, local_hero, FORCE_STAFF_RANGE)
                        if item_type == "hurricane_pike" then
                            -- Pike: направление от врага в противоположную сторону от основного героя
                            local local_pos = Entity.GetAbsOrigin(local_hero)
                            local direction = (hero_origin - local_pos):Normalized()
                            range = GetPushRange(hovered_hero, local_hero, HURRICANE_PIKE_RANGE)
                            DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
                        else
                            -- Force Staff: обычная стрелка вперёд
                            local direction = GetHeroFacingDirection(hovered_hero)
                            DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
                        end
                    end
                end
            end
            ::continue_override::
        end
        return
    end

    local has_item, _, item_type = HasPushItem(local_hero)
    if not has_item then return end

    -- Всегда использовать выбранный (активный) предмет для отрисовки траектории, если это Force Staff или Pike
    local player = Players.GetLocal and Players.GetLocal() or nil
    local is_pike_selected = false
    if player then
        local active_ability = Player.GetActiveAbility(player)
        local active_name = active_ability and Ability.GetName(active_ability) or nil
        is_pike_selected = active_name == ITEM_NAMES.HURRICANE_PIKE
        if active_name == ITEM_NAMES.HURRICANE_PIKE then
            item_type = "hurricane_pike"
        elseif active_name == ITEM_NAMES.FORCE_STAFF or active_name == ITEM_NAMES.FORCE_STAFF_2 then
            item_type = "force_staff"
        elseif active_name == ITEM_NAMES.PSYCHIC_HEADBAND then
            item_type = "psychic_headband"
        end
    end

    local cursor_x, cursor_y = Input.GetCursorPos()
    
    local show_all_self = s_always_self:Get()
    local show_all_allies = s_always_allies_switch:Get()
    local always_allies = s_always_allies:ListEnabled()
    local show_all_enemies = s_always_enemies_switch and s_always_enemies_switch:Get() or false
    local always_enemies = s_always_enemies and s_always_enemies:ListEnabled() or {}

    local heroes_to_process = {}

    if show_all_self then
        table.insert(heroes_to_process, local_hero)
    end

    if show_all_allies then
        for _, display_name in ipairs(always_allies) do
            local code_name = hero_display_to_code[display_name]
            for _, hero in ipairs(Heroes.GetAll()) do
                if NPC.GetUnitName(hero) == code_name and Entity.IsAlive(hero) then
                    local is_illusion = NPC.IsIllusion and NPC.IsIllusion(hero) or false
                    if not is_illusion then
                        table.insert(heroes_to_process, hero)
                        if not (s_include_meepo_clones:Get() and code_name == "npc_dota_hero_meepo") then
                            break
                        end
                    end
                end
            end
        end
    end

    if show_all_enemies then
        for _, display_name in ipairs(always_enemies) do
            local code_name = hero_display_to_code[display_name]
            for _, hero in ipairs(Heroes.GetAll()) do
                if NPC.GetUnitName(hero) == code_name and Entity.IsAlive(hero) then
                    local is_illusion = NPC.IsIllusion and NPC.IsIllusion(hero) or false
                    if not is_illusion then
                        table.insert(heroes_to_process, hero)
                        if not (s_include_meepo_clones:Get() and code_name == "npc_dota_hero_meepo") then
                            break
                        end
                    end
                end
            end
        end
    end
    
    local hovered_hero = Input.GetNearestHeroToCursor(Entity.GetTeamNum(local_hero), Enum.TeamType.TEAM_BOTH)
    if hovered_hero and Entity.IsAlive(hovered_hero) then
        local hero_origin = Entity.GetAbsOrigin(hovered_hero)
        local hero_screen = Render.WorldToScreen(hero_origin + Vector(0, 0, 50))
        if hero_screen then
            local dist = math.sqrt((cursor_x - hero_screen.x)^2 + (cursor_y - hero_screen.y)^2)
            if dist <= s_hover_radius:Get() then
                local is_hovered_ally = Entity.GetTeamNum(hovered_hero) == Entity.GetTeamNum(local_hero)
                local already_in_list = false
                for _, h in ipairs(heroes_to_process) do
                    if h == hovered_hero then
                        already_in_list = true
                        break
                    end
                end
                if not already_in_list then
                    if is_hovered_ally then
                        table.insert(heroes_to_process, hovered_hero)
                    else
                        -- враг: только если активен режим выбора цели
                        if (not s_only_when_active:Get()) or allow_draw then
                            table.insert(heroes_to_process, hovered_hero)
                        end
                    end
                end
            end
        end
    end

    -- Hover creeps: только при наведении/режиме выбора цели, без "всегда показывать"
    if s_show_creeps:Get() then
        local get_nearest_creep = Input.GetNearestNPCToCursor or Input.GetNearestUnitToCursor
        if get_nearest_creep then
            local creep = get_nearest_creep(Entity.GetTeamNum(local_hero), Enum.TeamType.TEAM_BOTH)
            if creep and Entity.IsAlive(creep) and not NPC.IsHero(creep) then
                local creep_pos = Entity.GetAbsOrigin(creep)
                local creep_screen = Render.WorldToScreen(creep_pos + Vector(0, 0, 50))
                if creep_screen then
                    local dist = math.sqrt((cursor_x - creep_screen.x)^2 + (cursor_y - creep_screen.y)^2)
                    local can_draw_creep = (not s_only_when_active:Get()) or allow_draw
                    if dist <= s_hover_radius:Get() and can_draw_creep then
                        local already = false
                        for _, h in ipairs(heroes_to_process) do if h == creep then already = true break end end
                        if not already then
                            table.insert(heroes_to_process, creep)
                        end
                    end
                end
            end
        end
    end
    
    for _, hovered_hero in ipairs(heroes_to_process) do
        local is_self = hovered_hero == local_hero
        local is_creep = not NPC.IsHero(hovered_hero)
        local is_ally = Entity.GetTeamNum(hovered_hero) == Entity.GetTeamNum(local_hero)
        local is_enemy = not is_ally
        
        local hero_origin = Entity.GetAbsOrigin(hovered_hero)
        local is_visible = Render.WorldToScreen(hero_origin + Vector(0, 0, 50))

        if not is_visible then goto continue end

        if (is_ally and not s_show_allies:Get()) or (not is_ally and not s_show_enemies:Get()) then
            goto continue
        end

        -- Применить ограничения "только когда активно" для каждого героя
        if s_only_when_active:Get() and is_enemy then
            -- Для врагов: пропустить, если не в режиме выбора цели
            local player = Players.GetLocal and Players.GetLocal() or nil
            local allow_draw_enemy = false
            if player then
                local active_ability = Player.GetActiveAbility(player)
                local active_name = active_ability and Ability.GetName(active_ability) or nil
                local is_force_active = active_name == ITEM_NAMES.FORCE_STAFF or active_name == ITEM_NAMES.FORCE_STAFF_2
                local is_pike_active = active_name == ITEM_NAMES.HURRICANE_PIKE
                local is_headband_active = active_name == ITEM_NAMES.PSYCHIC_HEADBAND
                if is_force_active or is_pike_active or is_headband_active then
                    allow_draw_enemy = true
                end
            end
            if not allow_draw_enemy then
                goto continue
            end
        elseif s_only_when_active:Get() and (is_self or is_ally) then
            -- Для себя/союзников: проверяем флаги override
            if not allow_draw then
                if (is_self and not (override_self and s_always_self:Get())) or (not is_self and is_ally and not (override_allies and s_always_allies_switch:Get())) then
                    goto continue
                end
            end
        end

        local color = (is_self and s_color_self:Get()) or (is_ally and s_color_ally:Get()) or s_color_enemy:Get()
        local size_mult = is_creep and s_creep_thickness_mult:Get() or 1

        if is_self and s_always_self:Get() and item_type == "hurricane_pike" then
            local cursor_on_enemy = false
            if is_pike_selected then
                local nearest = Input.GetNearestHeroToCursor(Entity.GetTeamNum(local_hero), Enum.TeamType.TEAM_BOTH)
                if nearest and Entity.IsAlive(nearest) then
                    local is_nearest_ally = Entity.GetTeamNum(nearest) == Entity.GetTeamNum(local_hero)
                    if not is_nearest_ally then
                        local nearest_origin = Entity.GetAbsOrigin(nearest)
                        local nearest_screen = Render.WorldToScreen(nearest_origin + Vector(0, 0, 50))
                        if nearest_screen then
                            local dist = math.sqrt((cursor_x - nearest_screen.x)^2 + (cursor_y - nearest_screen.y)^2)
                            if dist <= s_hover_radius:Get() then
                                cursor_on_enemy = true
                            end
                        end
                    end
                end
            end

            if not cursor_on_enemy then
                local direction = GetHeroFacingDirection(hovered_hero)
                local range = GetPushRange(hovered_hero, local_hero, FORCE_STAFF_RANGE)
                local self_color = s_color_self:Get()
                DrawTerrainAwareTrajectory(hero_origin, direction, range, self_color, 100)
            end
        elseif item_type == "force_staff" or (item_type == "hurricane_pike" and is_ally) then
            local direction = GetHeroFacingDirection(hovered_hero)
            local range = GetPushRange(hovered_hero, local_hero, FORCE_STAFF_RANGE)
            DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
        elseif item_type == "psychic_headband" and not is_self then
            local local_pos = Entity.GetAbsOrigin(local_hero)
            local direction = (hero_origin - local_pos):Normalized()
            local range = GetPushRange(hovered_hero, local_hero, PSYCHIC_HEADBAND_RANGE)
            DrawTerrainAwareTrajectory(hero_origin, direction, range, color, 100, size_mult)
        elseif item_type == "hurricane_pike" and not is_ally then
            local local_pos = Entity.GetAbsOrigin(local_hero)
            local direction = (hero_origin - local_pos):Normalized()

            local h_range = GetPushRange(hovered_hero, local_hero, HURRICANE_PIKE_RANGE)
            local l_range = HURRICANE_PIKE_RANGE

            DrawTerrainAwareTrajectory(hero_origin, direction, h_range, color, 100, size_mult)

            if is_pike_selected and is_visible then
                local dist = math.sqrt((cursor_x - is_visible.x)^2 + (cursor_y - is_visible.y)^2)
                if dist <= s_hover_radius:Get() then
                    local opposite_direction = direction * -1
                    DrawTerrainAwareTrajectory(local_pos, opposite_direction, l_range, s_color_self:Get(), 100, size_mult)
                end
            end
        end
        
        ::continue::
    end
end

return ForceStaffIndicator
