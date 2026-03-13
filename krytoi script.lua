local script = {}

local function safe_call(fn, ...)
    if not fn then return nil end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

local combo_group = nil
local display_group = nil
local ui = {}

local function create_group_safe(parent, name, side)
    if not parent or not parent.Create then return nil end
    local ok, result = pcall(function() return parent:Create(name, side) end)
    if ok and result then return result end
    local ok2, result2 = pcall(function() return parent:Create(name) end)
    if ok2 then return result2 end
    return nil
end

local function create_bind_safe(group, name)
    if not group or not group.Bind then return nil end
    local code = (Enum and Enum.ButtonCode and Enum.ButtonCode.KEY_NONE) or nil
    if code ~= nil then
        local ok, bind = pcall(function() return group:Bind(name, code) end)
        if ok and bind then return bind end
    end
    local ok2, bind2 = pcall(function() return group:Bind(name) end)
    if ok2 and bind2 then return bind2 end
    return nil
end

if Menu and Menu.Create then
    local tab = Menu.Create("Heroes", "Hero List", "Terrorblade")
    if tab and tab.Create then
        local section = tab:Create("Sunder + Dagon")
        if section and section.Create then
            combo_group = create_group_safe(section, "\u{041a}\u{043e}\u{043c}\u{0431}\u{043e}", 1)
            display_group = create_group_safe(section, "\u{041e}\u{0442}\u{043e}\u{0431}\u{0440}\u{0430}\u{0436}\u{0435}\u{043d}\u{0438}\u{0435}", 2)
        end
    end
end

if combo_group then
    ui.enable = combo_group:Switch("\u{0412}\u{043a}\u{043b}\u{044e}\u{0447}\u{0438}\u{0442}\u{044c}", true)
    ui.combo_key = create_bind_safe(combo_group, "\u{041a}\u{043b}\u{0430}\u{0432}\u{0438}\u{0448}\u{0430} \u{043a}\u{043e}\u{043c}\u{0431}\u{043e}")
    ui.use_ethereal = combo_group:Switch("Ethereal Blade \u{0432} \u{043a}\u{043e}\u{043c}\u{0431}\u{043e}", false)
    ui.safe_mode = combo_group:Switch("\u{0422}\u{043e}\u{043b}\u{044c}\u{043a}\u{043e} \u{0435}\u{0441}\u{043b}\u{0438} \u{043c}\u{043e}\u{0436}\u{043d}\u{043e} \u{0443}\u{0431}\u{0438}\u{0442}\u{044c}", true)
    ui.auto_cast = combo_group:Switch("\u{0410}\u{0432}\u{0442}\u{043e} \u{043a}\u{0430}\u{0441}\u{0442} (\u{0432} \u{0440}\u{0430}\u{0434}\u{0438}\u{0443}\u{0441}\u{0435} Sunder)", false)
end

if display_group then
    ui.draw_indicator = display_group:Switch("\u{0418}\u{043d}\u{0434}\u{0438}\u{043a}\u{0430}\u{0442}\u{043e}\u{0440}", true)
    ui.indicator_size = display_group:Slider("\u{0420}\u{0430}\u{0437}\u{043c}\u{0435}\u{0440}", 8, 30, 9, "%d")
    ui.y_offset = display_group:Slider("Y \u{0441}\u{043c}\u{0435}\u{0449}\u{0435}\u{043d}\u{0438}\u{0435}", -300, 200, -100, "%d")
    ui.draw_radiance = display_group:Switch("\u{0420}\u{0430}\u{0434}\u{0438}\u{0443}\u{0441} Radiance \u{0432}\u{0440}\u{0430}\u{0433}\u{043e}\u{0432}", true)
    ui.draw_autocast_range = display_group:Switch("\u{0420}\u{0430}\u{0434}\u{0438}\u{0443}\u{0441} \u{0430}\u{0432}\u{0442}\u{043e}\u{043a}\u{0430}\u{0441}\u{0442}\u{0430}", true)
end

ui.enable = ui.enable or { Get = function() return true end }
ui.combo_key = ui.combo_key or { IsDown = function() return false end, IsPressed = function() return false end }
ui.use_ethereal = ui.use_ethereal or { Get = function() return false end }
ui.safe_mode = ui.safe_mode or { Get = function() return true end }
ui.auto_cast = ui.auto_cast or { Get = function() return false end }
ui.draw_indicator = ui.draw_indicator or { Get = function() return true end }
ui.indicator_size = ui.indicator_size or { Get = function() return 9 end }
ui.y_offset = ui.y_offset or { Get = function() return -100 end }
ui.draw_radiance = ui.draw_radiance or { Get = function() return true end }
ui.draw_autocast_range = ui.draw_autocast_range or { Get = function() return true end }

local existing_combo_key = nil
pcall(function()
    existing_combo_key = Menu.Find("Heroes", "Hero List", "Terrorblade", "Main Settings", "Hero Settings", "Combo Key")
end)

local font = nil
pcall(function()
    font = Render.LoadFont("Arial", Enum.FontCreate.FONTFLAG_OUTLINE, Enum.FontWeight.BOLD)
end)

local font_small = nil
pcall(function()
    font_small = Render.LoadFont("Arial", Enum.FontCreate.FONTFLAG_OUTLINE, Enum.FontWeight.NORMAL)
end)

local DAGON_NAMES = {
    "item_dagon", "item_dagon_2", "item_dagon_3", "item_dagon_4", "item_dagon_5"
}
local DAGON_DAMAGE_TABLE = { 400, 500, 600, 700, 800 }
local SUNDER_ABILITY_NAME = "terrorblade_sunder"
local SUNDER_MIN_PCT_TABLE = { 35, 30, 25 }
local SUNDER_CAST_RANGE = 475
local RADIANCE_RADIUS = 700
local DEFAULT_MAGIC_RESIST = 0.25
local ETHEREAL_MAGIC_AMP = 0.40
local COMBO_TIMEOUT = 4.0
local ORDER_INTERVAL = 0.15
local CIRCLE_SEGMENTS = 64

local PURPLE_MAIN = Color(140, 60, 200, 230)
local PURPLE_DARK = Color(80, 30, 130, 220)
local PURPLE_LIGHT = Color(180, 120, 255, 240)
local PURPLE_BG = Color(40, 15, 65, 200)
local PURPLE_KILL = Color(200, 50, 255, 240)
local PURPLE_KILL_BG = Color(130, 20, 180, 220)
local WHITE = Color(255, 255, 255, 255)
local WHITE_SOFT = Color(240, 230, 255, 230)
local GRAY_BG = Color(50, 30, 70, 180)
local BAR_BG = Color(30, 15, 45, 200)
local BAR_FILL = Color(170, 70, 240, 230)
local BAR_FILL_KILL = Color(220, 80, 255, 250)
local RADIANCE_COLOR = Color(255, 160, 30, 80)
local RADIANCE_COLOR_BORDER = Color(255, 180, 50, 140)
local AUTOCAST_COLOR = Color(140, 60, 200, 70)
local AUTOCAST_COLOR_BORDER = Color(180, 80, 255, 130)

local function is_terrorblade(hero)
    local name = safe_call(NPC.GetUnitName, hero)
    return name == "npc_dota_hero_terrorblade"
end

local function get_game_time()
    return tonumber(safe_call(GameRules.GetGameTime) or 0) or 0
end

local function get_hp(npc)
    return tonumber(safe_call(Entity.GetHealth, npc) or 0) or 0
end

local function get_max_hp(npc)
    local v = tonumber(safe_call(Entity.GetMaxHealth, npc) or 1) or 1
    return v > 0 and v or 1
end

local function get_mana(npc)
    return tonumber(safe_call(NPC.GetMana, npc) or 0) or 0
end

local function get_dagon(hero)
    if not NPC or not NPC.GetItem then return nil, 0 end
    for i = #DAGON_NAMES, 1, -1 do
        local item = safe_call(NPC.GetItem, hero, DAGON_NAMES[i], true)
        if item then
            return item, i
        end
    end
    return nil, 0
end

local function get_ethereal_blade(hero)
    if not NPC or not NPC.GetItem then return nil end
    return safe_call(NPC.GetItem, hero, "item_ethereal_blade", true)
end

local function get_sunder(hero)
    if not NPC or not NPC.GetAbility then return nil end
    return safe_call(NPC.GetAbility, hero, SUNDER_ABILITY_NAME)
end

local function has_radiance(hero)
    if not NPC or not NPC.GetItem then return false end
    local rad = safe_call(NPC.GetItem, hero, "item_radiance", true)
    if rad then return true end
    return false
end

local function is_ability_ready(hero, ability)
    if not ability then return false end
    local mana = get_mana(hero)
    return safe_call(Ability.IsCastable, ability, mana) == true
end

local function get_special_value(ability, key)
    if not ability then return 0 end
    local val = 0
    if Ability and Ability.GetSpecialValueFor then
        val = tonumber(safe_call(Ability.GetSpecialValueFor, ability, key) or 0) or 0
    end
    if val <= 0 and Ability and Ability.GetLevelSpecialValueFor then
        val = tonumber(safe_call(Ability.GetLevelSpecialValueFor, ability, key, -1) or 0) or 0
    end
    return val
end

local function get_ability_level(ability)
    if not ability then return 0 end
    if Ability and Ability.GetLevel then
        return tonumber(safe_call(Ability.GetLevel, ability) or 0) or 0
    end
    return 0
end

local function get_cursor_world()
    if Input and Input.GetWorldCursorPos then
        return safe_call(Input.GetWorldCursorPos)
    end
    return nil
end

local function get_sunder_cast_range(hero)
    local sunder = get_sunder(hero)
    if not sunder then return SUNDER_CAST_RANGE end
    if Ability and Ability.GetCastRange then
        local r = tonumber(safe_call(Ability.GetCastRange, sunder) or 0) or 0
        if r > 0 then return r end
    end
    return SUNDER_CAST_RANGE
end

local function dist_between(a, b)
    local ax = a.x or 0
    local ay = a.y or 0
    local bx = b.x or 0
    local by = b.y or 0
    local dx = ax - bx
    local dy = ay - by
    return math.sqrt(dx * dx + dy * dy)
end

local function draw_world_circle(origin, radius, segments, color_fill, color_line, line_width)
    if not Render or not Render.WorldToScreen then return end
    local pts = {}
    local vis = {}
    local any_visible = false
    for s = 0, segments do
        local angle = (s / segments) * math.pi * 2
        local wx = (origin.x or 0) + math.cos(angle) * radius
        local wy = (origin.y or 0) + math.sin(angle) * radius
        local wz = origin.z or 0
        local sp, v = Render.WorldToScreen(Vector(wx, wy, wz))
        pts[s + 1] = sp
        vis[s + 1] = v
        if v then any_visible = true end
    end
    if not any_visible then return end
    if Render.Line then
        for s = 1, #pts - 1 do
            if vis[s] and vis[s + 1] and pts[s] and pts[s + 1] then
                Render.Line(pts[s], pts[s + 1], color_line or color_fill, line_width or 1.5)
            end
        end
    end
end

local function calculate_combo(my_hero, target)
    local my_hp = get_hp(my_hero)
    local my_max_hp = get_max_hp(my_hero)
    local target_max_hp = get_max_hp(target)
    local my_hp_pct = my_hp / my_max_hp

    local sunder = get_sunder(my_hero)
    local sunder_level = get_ability_level(sunder)

    local condemned = false
    local ignore_min = get_special_value(sunder, "ignore_minimum_pct_for_enemies")
    if ignore_min >= 1 then condemned = true end

    local min_pct = get_special_value(sunder, "hit_point_minimum_pct")
    if min_pct <= 0 and sunder_level > 0 and sunder_level <= #SUNDER_MIN_PCT_TABLE then
        min_pct = SUNDER_MIN_PCT_TABLE[sunder_level]
    end
    if min_pct <= 0 then min_pct = 35 end
    min_pct = min_pct / 100

    local enemy_hp_after_sunder
    if condemned then
        enemy_hp_after_sunder = my_hp_pct * target_max_hp
    else
        enemy_hp_after_sunder = math.max(my_hp_pct, min_pct) * target_max_hp
    end

    local dagon, dagon_level = get_dagon(my_hero)
    local dagon_base_damage = 0
    if dagon and dagon_level > 0 then
        dagon_base_damage = get_special_value(dagon, "damage")
        if dagon_base_damage <= 0 then
            dagon_base_damage = DAGON_DAMAGE_TABLE[dagon_level] or 0
        end
    end

    local magic_resist = DEFAULT_MAGIC_RESIST
    local total_damage = dagon_base_damage * (1 - magic_resist)

    local killable = enemy_hp_after_sunder <= total_damage
    local hp_deficit = enemy_hp_after_sunder - total_damage

    local sunder_ready = is_ability_ready(my_hero, sunder)
    local dagon_ready = dagon and is_ability_ready(my_hero, dagon) or false
    local combo_ready = sunder_ready and dagon_ready

    return {
        killable = killable,
        hp_deficit = hp_deficit,
        enemy_hp_after_sunder = enemy_hp_after_sunder,
        total_damage = total_damage,
        combo_ready = combo_ready,
        sunder_ready = sunder_ready,
        dagon_ready = dagon_ready,
        dagon = dagon,
        sunder = sunder,
        condemned = condemned,
        dagon_level = dagon_level,
    }
end

local function cast_on_target(local_player, hero, ability, target, queue)
    local order_type = Enum and Enum.UnitOrder and Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET
    local issuer = Enum and Enum.PlayerOrderIssuer and Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY
    if not order_type or not issuer or not local_player then return false end
    local ok = pcall(function()
        Player.PrepareUnitOrders(
            local_player, order_type, target, Vector(0, 0, 0),
            ability, issuer, hero, queue == true,
            true, false, true, "tb_sd", false
        )
    end)
    return ok
end

local combo_phase = 0
local combo_target = nil
local combo_start_time = 0
local combo_order_time = 0

local function draw_rounded_box(x, y, w, h, bg, border, rounding)
    if Render.FilledRect then
        Render.FilledRect(Vec2(x, y), Vec2(x + w, y + h), bg, rounding, Enum.DrawFlags.RoundCornersAll)
    end
    if Render.Rect then
        Render.Rect(Vec2(x, y), Vec2(x + w, y + h), border, rounding, Enum.DrawFlags.RoundCornersAll, 1.5)
    end
end

local function draw_bar(x, y, w, h, fill_pct, bg_col, fill_col, rounding)
    if not Render.FilledRect then return end
    Render.FilledRect(Vec2(x, y), Vec2(x + w, y + h), bg_col, rounding, Enum.DrawFlags.RoundCornersAll)
    if fill_pct > 0 then
        local fw = math.max(w * math.min(fill_pct, 1.0), rounding * 2)
        Render.FilledRect(Vec2(x, y), Vec2(x + fw, y + h), fill_col, rounding, Enum.DrawFlags.RoundCornersAll)
    end
end

function script.OnDraw()
    if not Engine or not Engine.IsInGame or not Engine.IsInGame() then return end
    if not font then return end
    if not ui.enable:Get() then return end

    local local_hero = safe_call(Heroes.GetLocal)
    if not local_hero or not is_terrorblade(local_hero) then return end
    if not Entity.IsAlive(local_hero) then return end

    local my_pos = safe_call(Entity.GetAbsOrigin, local_hero)

    if ui.draw_autocast_range:Get() and my_pos then
        local sunder_range = get_sunder_cast_range(local_hero)
        draw_world_circle(my_pos, sunder_range, CIRCLE_SEGMENTS, AUTOCAST_COLOR, AUTOCAST_COLOR_BORDER, 1.5)
    end

    local dagon_item = get_dagon(local_hero)
    if not dagon_item then return end

    local heroes = safe_call(Heroes.GetAll)
    if not heroes then return end

    local local_team = tonumber(safe_call(Entity.GetTeamNum, local_hero) or -1) or -1
    local fsize = ui.indicator_size:Get()
    local fsize_small = math.max(fsize - 2, 7)
    local y_off = ui.y_offset:Get()

    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= local_hero
            and safe_call(Entity.IsHero, enemy)
            and Entity.IsAlive(enemy)
            and safe_call(NPC.IsIllusion, enemy) ~= true
            and safe_call(Entity.IsDormant, enemy) ~= true
        then
            local enemy_team = tonumber(safe_call(Entity.GetTeamNum, enemy) or -1) or -1
            if enemy_team >= 0 and enemy_team ~= local_team then
                local epos = safe_call(Entity.GetAbsOrigin, enemy)

                if ui.draw_radiance:Get() and epos and has_radiance(enemy) then
                    draw_world_circle(epos, RADIANCE_RADIUS, CIRCLE_SEGMENTS, RADIANCE_COLOR, RADIANCE_COLOR_BORDER, 1.5)
                end

                if ui.draw_indicator:Get() then
                    local data = calculate_combo(local_hero, enemy)
                    if epos then
                        local bar_h = tonumber(safe_call(NPC.GetHealthBarOffset, enemy) or 0) or 0
                        local draw_pos = epos + Vector(0, 0, bar_h + 10)
                        local screen_pos, visible = Render.WorldToScreen(draw_pos)

                        if visible and screen_pos then
                            local sx = screen_pos.x
                            local sy = screen_pos.y + y_off

                            local main_text, sub_text
                            local main_color, box_bg, box_border, bar_color

                            if data.killable and data.combo_ready then
                                main_text = "\u{0423}\u{0411}\u{0418}\u{0422}\u{042c}"
                                sub_text = "Sunder + Dagon " .. tostring(data.dagon_level)
                                main_color = WHITE
                                box_bg = PURPLE_KILL_BG
                                box_border = PURPLE_KILL
                                bar_color = BAR_FILL_KILL
                            elseif data.killable then
                                main_text = "\u{0423}\u{0411}\u{0418}\u{0422}\u{042c} (\u{041a}\u{0414})"
                                sub_text = "\u{041e}\u{0436}\u{0438}\u{0434}\u{0430}\u{043d}\u{0438}\u{0435} \u{043a}\u{0443}\u{043b}\u{0434}\u{0430}\u{0443}\u{043d}\u{0430}"
                                main_color = PURPLE_LIGHT
                                box_bg = PURPLE_DARK
                                box_border = PURPLE_MAIN
                                bar_color = BAR_FILL
                            else
                                local deficit = math.ceil(data.hp_deficit)
                                main_text = "+" .. tostring(deficit) .. " HP"
                                sub_text = "\u{041d}\u{0435} \u{0445}\u{0432}\u{0430}\u{0442}\u{0430}\u{0435}\u{0442} \u{0443}\u{0440}\u{043e}\u{043d}\u{0430}"
                                main_color = WHITE_SOFT
                                box_bg = GRAY_BG
                                box_border = PURPLE_DARK
                                bar_color = BAR_FILL
                            end

                            local ts_main = Render.TextSize(font, fsize, main_text)
                            local ts_sub = font_small and Render.TextSize(font_small, fsize_small, sub_text) or nil

                            local pad_x = 6
                            local pad_y = 3
                            local gap = 1
                            local content_w = ts_main.x
                            local content_h = ts_main.y
                            if ts_sub then
                                content_w = math.max(content_w, ts_sub.x)
                                content_h = content_h + gap + ts_sub.y
                            end

                            local bw = content_w + pad_x * 2
                            local bh = content_h + pad_y * 2
                            local bx = sx - bw / 2
                            local by = sy - bh / 2

                            if Render.FilledRect then
                                Render.FilledRect(
                                    Vec2(bx - 1, by - 1), Vec2(bx + bw + 1, by + bh + 1),
                                    Color(140, 60, 200, 30), 4, Enum.DrawFlags.RoundCornersAll
                                )
                            end

                            draw_rounded_box(bx, by, bw, bh, box_bg, box_border, 3)

                            local text_y = by + pad_y
                            Render.Text(font, fsize, main_text,
                                Vec2(sx - ts_main.x / 2, text_y), main_color)

                            if ts_sub and font_small then
                                text_y = text_y + ts_main.y + gap
                                Render.Text(font_small, fsize_small, sub_text,
                                    Vec2(sx - ts_sub.x / 2, text_y),
                                    Color(200, 180, 230, 180))
                            end

                            local bar_w = bw - 4
                            local bar_height = 2
                            local bar_x = bx + 2
                            local bar_y = by + bh + 2

                            if data.enemy_hp_after_sunder > 0 then
                                local fill = math.min(1.0, data.total_damage / data.enemy_hp_after_sunder)
                                draw_bar(bar_x, bar_y, bar_w, bar_height, fill, BAR_BG, bar_color, 2)
                            else
                                draw_bar(bar_x, bar_y, bar_w, bar_height, 1.0, BAR_BG, bar_color, 2)
                            end

                            if data.condemned then
                                local tag = "\u{0427}\u{0421}\u{0412} \u{041c}\u{0443}\u{0442}\u{0430}\u{043d}\u{0442}"
                                local tag_size = math.max(fsize - 2, 7)
                                if font_small then
                                    local tts = Render.TextSize(font_small, tag_size, tag)
                                    local tag_bg_w = tts.x + 4
                                    local tag_bg_h = tts.y + 2
                                    local tag_x = sx - tag_bg_w / 2
                                    local tag_y = by - tag_bg_h - 2

                                    draw_rounded_box(tag_x, tag_y, tag_bg_w, tag_bg_h,
                                        Color(100, 40, 160, 180), Color(160, 80, 240, 200), 2)

                                    Render.Text(font_small, tag_size, tag,
                                        Vec2(sx - tts.x / 2, tag_y + 1),
                                        Color(220, 180, 255, 230))
                                end
                            end

                            if data.killable and data.combo_ready and Render.FilledRect then
                                local pulse = math.abs(math.sin(get_game_time() * 3.0))
                                local alpha = math.floor(12 + pulse * 20)
                                Render.FilledRect(
                                    Vec2(bx - 2, by - 2), Vec2(bx + bw + 2, by + bh + bar_height + 6),
                                    Color(160, 60, 240, alpha), 5, Enum.DrawFlags.RoundCornersAll
                                )
                            end
                        end
                    end
                end
            end
        end
    end
end

local function is_combo_key_down()
    if ui.combo_key and ui.combo_key.IsDown then
        local ok, down = pcall(function() return ui.combo_key:IsDown() end)
        if ok and down == true then return true end
    end
    if existing_combo_key and existing_combo_key.IsDown then
        local ok, down = pcall(function() return existing_combo_key:IsDown() end)
        if ok and down == true then return true end
    end
    return false
end

local function find_best_target(local_hero)
    local heroes = safe_call(Heroes.GetAll)
    if not heroes then return nil, nil end

    local local_team = tonumber(safe_call(Entity.GetTeamNum, local_hero) or -1) or -1
    local cursor = get_cursor_world()
    if not cursor then return nil, nil end

    local best = nil
    local best_dist = 99999
    local best_data = nil
    local best_killable = false

    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= local_hero
            and safe_call(Entity.IsHero, enemy)
            and Entity.IsAlive(enemy)
            and safe_call(NPC.IsIllusion, enemy) ~= true
            and safe_call(Entity.IsDormant, enemy) ~= true
        then
            local enemy_team = tonumber(safe_call(Entity.GetTeamNum, enemy) or -1) or -1
            if enemy_team >= 0 and enemy_team ~= local_team then
                local epos = safe_call(Entity.GetAbsOrigin, enemy)
                if epos then
                    local dist = dist_between(cursor, epos)
                    local data = calculate_combo(local_hero, enemy)

                    local dominated = false
                    if data.killable and data.combo_ready and not best_killable then
                        dominated = true
                    elseif data.killable and data.combo_ready and best_killable and dist < best_dist then
                        dominated = true
                    elseif not best_killable and dist < best_dist then
                        dominated = true
                    end

                    if dominated then
                        best = enemy
                        best_dist = dist
                        best_data = data
                        best_killable = data.killable and data.combo_ready
                    end
                end
            end
        end
    end
    return best, best_data
end

local function find_autocast_target(local_hero)
    local heroes = safe_call(Heroes.GetAll)
    if not heroes then return nil, nil end

    local local_team = tonumber(safe_call(Entity.GetTeamNum, local_hero) or -1) or -1
    local my_pos = safe_call(Entity.GetAbsOrigin, local_hero)
    if not my_pos then return nil, nil end

    local sunder_range = get_sunder_cast_range(local_hero)
    local best = nil
    local best_hp = 999999
    local best_data = nil

    for i = 1, #heroes do
        local enemy = heroes[i]
        if enemy and enemy ~= local_hero
            and safe_call(Entity.IsHero, enemy)
            and Entity.IsAlive(enemy)
            and safe_call(NPC.IsIllusion, enemy) ~= true
            and safe_call(Entity.IsDormant, enemy) ~= true
        then
            local enemy_team = tonumber(safe_call(Entity.GetTeamNum, enemy) or -1) or -1
            if enemy_team >= 0 and enemy_team ~= local_team then
                local epos = safe_call(Entity.GetAbsOrigin, enemy)
                if epos then
                    local dist = dist_between(my_pos, epos)
                    if dist <= sunder_range then
                        local data = calculate_combo(local_hero, enemy)
                        if data.killable and data.combo_ready then
                            local ehp = data.enemy_hp_after_sunder
                            if ehp < best_hp then
                                best = enemy
                                best_hp = ehp
                                best_data = data
                            end
                        end
                    end
                end
            end
        end
    end
    return best, best_data
end

function script.OnUpdate()
    if not Engine or not Engine.IsInGame or not Engine.IsInGame() then return end
    if not ui.enable:Get() then return end

    local local_hero = safe_call(Heroes.GetLocal)
    if not local_hero or not is_terrorblade(local_hero) then return end
    if not Entity.IsAlive(local_hero) then
        combo_phase = 0
        combo_target = nil
        return
    end

    local now = get_game_time()
    local combo_key_down = is_combo_key_down()

    if not combo_key_down and combo_phase == 0 and ui.auto_cast:Get() then
        local local_player = safe_call(Players.GetLocal)
        if local_player and now - combo_order_time >= ORDER_INTERVAL then
            local target, data = find_autocast_target(local_hero)
            if target and data and data.killable and data.combo_ready then
                combo_target = target
                combo_start_time = now
                combo_phase = 1
            end
        end
    end

    if combo_key_down and combo_phase == 0 then
        local local_player = safe_call(Players.GetLocal)
        if local_player and now - combo_order_time >= ORDER_INTERVAL then
            local target, data = find_best_target(local_hero)
            if target and data then
                if not ui.safe_mode:Get() or data.killable then
                    combo_target = target
                    combo_start_time = now
                    combo_phase = 1
                end
            end
        end
    end

    if not combo_key_down and not ui.auto_cast:Get() then
        combo_phase = 0
        combo_target = nil
        return
    end

    if combo_phase == 0 then return end

    if now - combo_start_time > COMBO_TIMEOUT then
        combo_phase = 0
        combo_target = nil
        return
    end

    if not combo_target
        or not Entity.IsAlive(combo_target)
        or safe_call(Entity.IsDormant, combo_target) == true
    then
        combo_phase = 0
        combo_target = nil
        return
    end

    local local_player = safe_call(Players.GetLocal)
    if not local_player then return end
    if now - combo_order_time < ORDER_INTERVAL then return end

    if combo_phase == 1 then
        local sunder = get_sunder(local_hero)
        if sunder and is_ability_ready(local_hero, sunder) then
            cast_on_target(local_player, local_hero, sunder, combo_target, false)
            combo_order_time = now
            if ui.use_ethereal:Get() and get_ethereal_blade(local_hero) then
                combo_phase = 2
            else
                combo_phase = 3
            end
        end
        return
    end

    if combo_phase == 2 then
        local eth = get_ethereal_blade(local_hero)
        if eth and is_ability_ready(local_hero, eth) then
            cast_on_target(local_player, local_hero, eth, combo_target, false)
            combo_order_time = now
            combo_phase = 3
        elseif not eth then
            combo_phase = 3
        end
        return
    end

    if combo_phase == 3 then
        local dagon = get_dagon(local_hero)
        if dagon and is_ability_ready(local_hero, dagon) then
            cast_on_target(local_player, local_hero, dagon, combo_target, false)
            combo_order_time = now
            combo_phase = 4
        end
        return
    end

    if combo_phase == 4 then
        combo_phase = 0
        combo_target = nil
    end
end

return script
