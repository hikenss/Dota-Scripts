local wardhelper = {}

local custom_wards = {}
local builder_mode = false
local selected_ward_type = "Obs"
local show_custom_wards = true

local selected_team = "Both"
local show_team_specific = false


local function GetCustomWardsPath()
    return "custom_wards.json"
end


-- json xuina
local function SaveCustomWards()
    local JSON = require('assets.JSON')
    local file = io.open(GetCustomWardsPath(), "w")
    if file then
        local json_string = JSON.encode(JSON, custom_wards)
        file:write(json_string)
        file:close()
        Log.Write("[builder ward debug] custom wards saved to file: " .. GetCustomWardsPath())
        Log.Write("[builder ward debug] total wards saved: " .. #custom_wards)
    else
        Log.Write("[builder ward debug] ERROR: could not save custom wards to file!")
    end
end

local function LoadCustomWards()
    local JSON = require('assets.JSON')
    local file = io.open(GetCustomWardsPath(), "r")
    if file then
        local content = file:read("*all")
        file:close()

        local success, data = pcall(JSON.decode, JSON, content)
        if success and data then
            if type(data) == "table" and #data > 0 then
                custom_wards = data
                for i, ward in ipairs(custom_wards) do
                    if not ward.teams then
                        ward.teams = {"Dire", "Radiant"}
                    end
                end
                Log.Write("[builder ward debug] custom wards loaded from file: " .. GetCustomWardsPath())
                Log.Write("[builder ward debug] total wards loaded: " .. #custom_wards)
            elseif type(data) == "table" and data.wards then
                custom_wards = data.wards
                for i, ward in ipairs(custom_wards) do
                    if not ward.teams then
                        ward.teams = {"Dire", "Radiant"}
                    end
                end
                Log.Write("[builder ward debug] custom wards loaded from file (old format): " .. GetCustomWardsPath())
                Log.Write("[builder ward debug] total wards loaded: " .. #custom_wards)
            else
                Log.Write("[builder ward debug] ERROR: invalid data format in custom wards file!")
                custom_wards = {}
            end
        else
            Log.Write("[builder ward debug] ERROR: could not parse custom wards file!")
            custom_wards = {}
        end
    else
        Log.Write("[builder ward debug] no custom wards file found, starting with empty list")
        custom_wards = {}
    end
end

local function IsWardVisibleForTeam(ward)
    if not show_team_specific then
        return true
    end
    
    local hero = Heroes.GetLocal()
    if not hero then
        return true
    end
    
    local player_team = Entity.GetTeamNum(hero)
    local team_name = ""
    
    if player_team == 2 then
        team_name = "Radiant"
    elseif player_team == 3 then
        team_name = "Dire"
    else
        return true
    end
    
    if ward.teams then
        for _, ward_team in ipairs(ward.teams) do
            if ward_team == team_name then
                return true
            end
        end
        return false
    end
    
    return true
end

local tab = Menu.Create("Scripts", "Other", "Ward Helper")
tab:Icon("\u{f06e}")
local group = tab:Create("Main"):Create("Settings")
local shop = tab:Create("Builder"):Create("Settings")

local ui = {}

ui.global_switch = group:Switch("Enabled", false, "\u{f00c}")
ui.iconsize = group:Slider("Icon Size", 10, 50, 20, "%d")
ui.tooltipsize = group:Slider("Font Size", 10, 24, 14, "%d")

ui.show_team_filter = group:Switch("Filter by Team", false, "\u{f0c0}")
ui.show_team_filter:ToolTip("Show only wards for your current team")

ui.onlyalt = group:Switch("Only ALT", false, "\u{f033}")
ui.onlyalt:ToolTip("Display labels in the world only when ALT is pressed")

ui.placehelper = group:Switch("Place Helper", false, "\u{f0c0}")
ui.placehelper:ToolTip("Helps set the ward to the desired pixel when right-clicking on a point.")

ui.placebind = group:Bind("Place Ward Key", Enum.ButtonCode.KEY_MOUSE1, "\u{f11c}")
ui.placebind:ToolTip("A button that, when pressed, will set the ward in the selected location.")

ui.ward_server = group:Combo("Ward Data Server", {"uc.akurise.xyz", "netlify.app", "gist.github.com"}, 0)

ui.debug = group:Switch("Debug", false, "\u{f3c5}")

local function DebugLog(message)
    if ui.debug and ui.debug:Get() then
        Log.Write(message)
    end
end

local function get_ward_server_url()
    local server_index = ui.ward_server:Get()
    local servers = {
        "https://uc.akurise.xyz/wards",
        "https://uc-ward-helper.netlify.app/wards.json",
        "https://gist.githubusercontent.com/akurise/031cf141af6048a8097673ab66a81f63/raw/592e9baf2ef28397e41ddfc864ee364bf6ac25e4/wards.json"
    }
    return servers[server_index + 1] or servers[1]
end

ui.builder_mode = shop:Switch("Builder Mode", false, "\u{f7d9}")
ui.builder_mode:ToolTip("Enable ward builder mode to create custom ward locations")

ui.ward_type = shop:Combo("Ward Type", {"Observer Ward", "Sentry Ward"}, 0)
ui.ward_type:Icon("\u{f06e}")
ui.ward_type:ToolTip("Select ward type for building")

ui.team_type = shop:Combo("Team", {"Dire", "Radiant", "Both"}, 2)
ui.team_type:Icon("\u{f0c0}")
ui.team_type:ToolTip("Select team for ward placement")


ui.show_custom = shop:Switch("Show Custom Wards", true, "\u{f06e}")
ui.show_custom:ToolTip("Show/hide custom ward locations")

ui.add_ward_bind = shop:Bind("Add Ward at Cursor", Enum.ButtonCode.KEY_F5, "\u{f067}")
ui.add_ward_bind:ToolTip("Press this key to add a ward at cursor position when Builder Mode is enabled")

ui.clear_all = shop:Button("Clear All Custom", function()
    Log.Write("[builder ward debug]             CLEARING ALL CUSTOM WARDS             ")
    Log.Write("[builder ward debug] current custom wards count: " .. #custom_wards)

    if #custom_wards > 0 then
        DebugLog("[builder ward debug] clearing " .. #custom_wards .. " custom wards...")
        custom_wards = {}
        DebugLog("[builder ward debug] all custom wards cleared!")

        SaveCustomWards()

        UpdateWardList()

        DebugLog("[builder ward debug]            ALL WARDS CLEARED AND SAVED            ")
    else
        DebugLog("[builder ward debug] no custom wards to clear!")
    end
end)
ui.clear_all:Icon("\u{f1f8}")

ui.save_wards = shop:Button("Save Custom Wards", function()
    Log.Write("[builder ward debug]            MANUAL SAVE            ")
    Log.Write("[builder ward debug] current custom wards count: " .. #custom_wards)

    if #custom_wards > 0 then
        SaveCustomWards()
        DebugLog("[builder ward debug] manual save completed!")
    else
        DebugLog("[builder ward debug] no custom wards to save!")
    end
end)
ui.save_wards:Icon("\u{f0c7}")

ui.info_wards = shop:Button("Show Wards Info", function()
    Log.Write("[builder ward debug]            CUSTOM WARDS INFO            ")
    Log.Write("[builder ward debug] total custom wards: " .. #custom_wards)

    if #custom_wards > 0 then
        local obs_count = 0
        local sentry_count = 0

        for i, ward in ipairs(custom_wards) do
            if ward.type == "Obs" then
                obs_count = obs_count + 1
            elseif ward.type == "Sentry" then
                sentry_count = sentry_count + 1
            end

            Log.Write("[builder ward debug] ward " .. i .. ": " .. ward.x .. ", " .. ward.y .. " (" .. ward.type .. ") - " .. (ward.description or "No description"))
        end

        Log.Write("[builder ward debug] observer wards: " .. obs_count)
        Log.Write("[builder ward debug] sentry wards: " .. sentry_count)
    else
        Log.Write("[builder ward debug] no custom wards found!")
    end
end)
ui.info_wards:Icon("\u{f05a}")

shop:Label("Custom Wards Management", "\u{f06e}")

ui.ward_list = shop:Combo("Select Ward", {"No wards available"}, 0)
ui.ward_list:Icon("\u{f06e}")
ui.ward_list:ToolTip("Select a custom ward to edit or delete")

ui.wards_stats = shop:Label("Total: 0 | Obs: 0 | Sentry: 0", "\u{f080}")

ui.ward_description = shop:Input("Ward Description", "Custom ward location", "\u{f040}")
ui.ward_description:ToolTip("Edit the description that appears in tooltip")

ui.update_ward = shop:Button("Update Description", function()
    local selected_index = ui.ward_list:Get() + 1
    if selected_index > 0 and selected_index <= #custom_wards then
        local new_description = ui.ward_description:Get()
        custom_wards[selected_index].description = new_description
        SaveCustomWards()
        DebugLog("[builder ward debug] updated ward " .. selected_index .. " description: " .. new_description)
        UpdateWardList()
    else
        DebugLog("[builder ward debug] ERROR: no ward selected!")
    end
end)
ui.update_ward:Icon("\u{f044}")

ui.delete_ward = shop:Button("Delete Selected Ward", function()
    local selected_index = ui.ward_list:Get() + 1
    if selected_index > 0 and selected_index <= #custom_wards then
        local deleted_ward = custom_wards[selected_index]
        table.remove(custom_wards, selected_index)
        SaveCustomWards()
        DebugLog("[builder ward debug] deleted ward " .. selected_index .. ": " .. deleted_ward.x .. ", " .. deleted_ward.y .. " (" .. deleted_ward.type .. ")")
        UpdateWardList()
        ui.ward_description:Set("Custom ward location")
    else
        DebugLog("[builder ward debug] ERROR: no ward selected!")
    end
end)
ui.delete_ward:Icon("\u{f1f8}")

ui.duplicate_ward = shop:Button("Duplicate Selected Ward", function()
    local selected_index = ui.ward_list:Get() + 1
    if selected_index > 0 and selected_index <= #custom_wards then
        local original_ward = custom_wards[selected_index]
        local new_ward = {
            x = original_ward.x + 100,
            y = original_ward.y + 100,
            z = original_ward.z,
            type = original_ward.type,
            description = original_ward.description .. " (Copy)",
            teams = original_ward.teams or {"Dire", "Radiant"}
        }
        table.insert(custom_wards, new_ward)
        SaveCustomWards()
        DebugLog("[builder ward debug] duplicated ward " .. selected_index .. " to position: " .. new_ward.x .. ", " .. new_ward.y)
        UpdateWardList()
    else
        DebugLog("[builder ward debug] ERROR: no ward selected!")
    end
end)
ui.duplicate_ward:Icon("\u{f24d}")

shop:Label("Export", "\u{f0c7}")

ui.export_wards = shop:Button("Export to Console", function()
    if #custom_wards > 0 then
        local JSON = require('assets.JSON')
        local json_string = JSON.encode(JSON, custom_wards)

        DebugLog("[builder ward debug]            EXPORTED WARDS            ")
        DebugLog("[builder ward debug] JSON data:")
        DebugLog(json_string)
        DebugLog("[builder ward debug]            END EXPORT            ")
    else
        DebugLog("[builder ward debug] no wards to export!")
    end
end)
ui.export_wards:Icon("\u{f0c7}")

ui.global_switch:SetCallback(function ()
    ui.debug:Disabled(not ui.global_switch:Get())
    ui.iconsize:Disabled(not ui.global_switch:Get())
    ui.tooltipsize:Disabled(not ui.global_switch:Get())
    ui.onlyalt:Disabled(not ui.global_switch:Get())
    ui.placehelper:Disabled(not ui.global_switch:Get())
end, true)

ui.placehelper:SetCallback(function ()
    ui.placebind:Disabled(not ui.placehelper:Get())
end, true)

ui.builder_mode:SetCallback(function()
    builder_mode = ui.builder_mode:Get()
    if builder_mode then
        DebugLog("[builder ward debug] builder mode enabled")
    else
        DebugLog("[builder ward debug] builder mode disabled")
    end
end)

builder_mode = ui.builder_mode:Get()

ui.ward_type:SetCallback(function()
    local ward_types = {"Obs", "Sentry"}
    selected_ward_type = ward_types[ui.ward_type:Get() + 1]
    DebugLog("[builder ward debug] selected ward type: " .. selected_ward_type)
end)

selected_ward_type = "Obs"

ui.team_type:SetCallback(function()
    local team_types = {"Dire", "Radiant", "Both"}
    selected_team = team_types[ui.team_type:Get() + 1]
    DebugLog("[builder ward debug] selected team: " .. selected_team)
end)

ui.show_team_filter:SetCallback(function()
    show_team_specific = ui.show_team_filter:Get()
    DebugLog("[builder ward debug] team filter: " .. (show_team_specific and "ON" or "OFF"))
end)

UpdateWardList = function()
    local ward_options = {}
    local obs_count = 0
    local sentry_count = 0

    for i, ward in ipairs(custom_wards) do
        local teams_text = ""
        if ward.teams then
            teams_text = " [" .. table.concat(ward.teams, ", ") .. "]"
        end
        local option_text = string.format("#%d: %s at (%.0f, %.0f)%s", i, ward.type, ward.x, ward.y, teams_text)
        table.insert(ward_options, option_text)

        if ward.type == "Obs" then
            obs_count = obs_count + 1
        elseif ward.type == "Sentry" then
            sentry_count = sentry_count + 1
        end
    end

    if #ward_options == 0 then
        table.insert(ward_options, "No wards available")
    end

    ui.ward_list:Update(ward_options, 0)

    local stats_text = string.format("Total: %d | Obs: %d | Sentry: %d", #custom_wards, obs_count, sentry_count)
    ui.wards_stats:ForceLocalization(stats_text)

    if #custom_wards == 0 then
        ui.ward_description:Set("Custom ward location")
    else
        ui.ward_list:Set(0)
        local selected_ward = custom_wards[1]
        ui.ward_description:Set(selected_ward.description or "Custom ward location")
    end
end

ui.ward_list:SetCallback(function()
    local selected_index = ui.ward_list:Get() + 1
    if selected_index > 0 and selected_index <= #custom_wards then
        local selected_ward = custom_wards[selected_index]
        ui.ward_description:Set(selected_ward.description or "Custom ward location")
        DebugLog("[builder ward debug] selected ward " .. selected_index .. ": " .. selected_ward.x .. ", " .. selected_ward.y .. " (" .. selected_ward.type .. ")")
    else

        ui.ward_description:Set("Custom ward location")
        if #custom_wards == 0 then
            DebugLog("[builder ward debug] no wards available")
        end
    end
end)

ui.show_custom:SetCallback(function()
    show_custom_wards = ui.show_custom:Get()
    DebugLog("[builder ward debug] show custom wards: " .. (show_custom_wards and "ON" or "OFF"))
end)

local my_hero = nil
local wards_data = {}
local data_loaded = false
local request_sent = false
local ward_particles = {}
local custom_wards_loaded = false

local tooltip_animations = {}
local alpha_animation = 0

local font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)
local icon = Render.LoadFont("FontAwesomeEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)

ui.ward_server:SetCallback(function()
    local server_names = {"uc.akurise.xyz", "netlify.app", "gist.github.com"}
    local selected_server = server_names[ui.ward_server:Get() + 1]
    DebugLog("[builder ward debug] server changed to: " .. selected_server)
    
    data_loaded = false
    request_sent = false
    wards_data = {}
    
    Engine.ReloadScriptSystem()
end)

local placehelp = function (my_hero)
    if not ui.placehelper:Get() or not data_loaded then return end
    if ui.onlyalt:Get() and not Input.IsKeyDown(Enum.ButtonCode.KEY_LALT) then return end

    local ward_observer = NPC.GetItem(my_hero, "item_ward_observer", true)
    local ward_sentry = NPC.GetItem(my_hero, "item_ward_sentry", true)
    local ward_dispenser = NPC.GetItem(my_hero, "item_ward_dispenser", true)

    if not (ward_observer or ward_sentry or ward_dispenser) then return end

    if Input.IsKeyDownOnce(ui.placebind:Get()) then
        local cursorPosScreenX, cursorPosScreenY = Input.GetCursorPos()

        local function check_ward_click(ward)
            local position = Vector(ward.x, ward.y, ward.z)
            local screen_pos = Render.WorldToScreen(position)

            if screen_pos then
                local size = ui.iconsize:Get()

                local render_offset = 15
                local adjusted_screen_pos = Vec2(screen_pos.x, screen_pos.y - render_offset)

                local animation_time = GameRules.GetGameTime() * 2
                local bounce_offset = math.sin(animation_time) * 3
                local animated_screen_pos = Vec2(adjusted_screen_pos.x, adjusted_screen_pos.y + bounce_offset)

                local bg_width = size / 1.5
                local bg_height = size / 1.5

                local is_cursor_in_rect = cursorPosScreenX >= (animated_screen_pos.x - bg_width) and 
                                        cursorPosScreenX <= (animated_screen_pos.x + bg_width) and
                                        cursorPosScreenY >= (animated_screen_pos.y - bg_height) and 
                                        cursorPosScreenY <= (animated_screen_pos.y + bg_height)

                if is_cursor_in_rect then
                    local ward_position = Vector(ward.x, ward.y, ward.z)

                    if ward_dispenser then
                        local is_observer_selected = Ability.GetToggleState(ward_dispenser)

                        if ward.type == "Obs" then
                            if not is_observer_selected then
                                Ability.Toggle(ward_dispenser)
                            end
                            Ability.CastPosition(ward_dispenser, ward_position)
                        elseif ward.type == "Sentry" then
                            if is_observer_selected then
                                Ability.Toggle(ward_dispenser)
                            end
                            Ability.CastPosition(ward_dispenser, ward_position)
                        end
                    elseif ward.type == "Obs" and ward_observer then
                        Ability.CastPosition(ward_observer, ward_position)
                    elseif ward.type == "Sentry" and ward_sentry then
                        Ability.CastPosition(ward_sentry, ward_position)
                    end

                    return true
                end
            end
            return false
        end

        for i, ward in ipairs(wards_data) do
            if check_ward_click(ward) then
                return
            end
        end

        if show_custom_wards then
            for i, ward in ipairs(custom_wards) do
                if check_ward_click(ward) then
                    return
                end
            end
        end
    end
end

local function parse_wards_response(response_text)
    if response_text then
        Log.Write("[WARD HELPER by akurise] Ward data received")
    end

    local JSON = require('assets.JSON')
    local success, wards = pcall(JSON.decode, JSON, response_text)

    if success and wards then
        return wards
    end
    return {}
end

local function load_wards_data()
    if data_loaded or request_sent then return end

    request_sent = true

    local headers = {
        ["User-Agent"] = "Umbrella/1.0",
        ["Content-Type"] = "application/json"
    }

    local callback = function(response)
        wards_data = parse_wards_response(response.response)
        data_loaded = true
        DebugLog("[WARD HELPER by akurise] Ward data received from: " .. get_ward_server_url())
    end

    local server_url = get_ward_server_url()
    DebugLog("[WARD HELPER by akurise] Loading wards from: " .. server_url)

    HTTP.Request("GET", server_url, {
        headers = headers,
        timeout = 5
    }, callback, "wards_request")
end


local function draw_ward_icons()
    if not ui.global_switch:Get() or not data_loaded then return end

    local cursorPosWorld = Input.GetWorldCursorPos()

    local sentry_icon = Render.LoadImage("panorama/images/emoticons/sentry_ward_png.vtex_c")
    local observer_icon = Render.LoadImage("panorama/images/emoticons/observer_ward_png.vtex_c")

    local target_alpha = 0

    if ui.onlyalt:Get() then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_LALT) then
            target_alpha = 1
        else
            target_alpha = 0
        end
    else
        target_alpha = 1
    end

    local alpha_speed = 0.1

    if alpha_animation < target_alpha then
        alpha_animation = math.min(target_alpha, alpha_animation + alpha_speed)
    elseif alpha_animation > target_alpha then
        alpha_animation = math.max(target_alpha, alpha_animation - alpha_speed)
    end

    if alpha_animation <= 0 then return end


    local function draw_single_ward(ward, is_custom, index)
        local position = Vector(ward.x, ward.y, ward.z)
        local screen_pos = Render.WorldToScreen(position)

        if screen_pos then
            local size = ui.iconsize:Get()

            local render_offset = 15
            local adjusted_screen_pos = Vec2(screen_pos.x, screen_pos.y - render_offset)

            local animation_time = GameRules.GetGameTime() * 2
            local bounce_offset = math.sin(animation_time) * 3
            local animated_screen_pos = Vec2(adjusted_screen_pos.x, adjusted_screen_pos.y + bounce_offset)

            local bg_width = size / 1.5
            local bg_height = size / 1.5

            local cursorPosScreenX, cursorPosScreenY = Input.GetCursorPos()
            local is_cursor_in_rect = cursorPosScreenX >= (animated_screen_pos.x - bg_width) and 
                                    cursorPosScreenX <= (animated_screen_pos.x + bg_width) and
                                    cursorPosScreenY >= (animated_screen_pos.y - bg_height) and 
                                    cursorPosScreenY <= (animated_screen_pos.y + bg_height)

            if is_cursor_in_rect then
                local tooltip_font_size = ui.tooltipsize:Get()
                local info_text = ward.description or "No description"

                local text_size = Render.TextSize(font, tooltip_font_size, info_text)

                if not tooltip_animations[index] then
                    tooltip_animations[index] = {
                        width = bg_width * 2,
                        target_width = text_size.x + size + 20,
                        start_time = GameRules.GetGameTime()
                    }
                end

                local anim = tooltip_animations[index]
                local elapsed_time = GameRules.GetGameTime() - anim.start_time
                local animation_duration = 0.1

                if elapsed_time < animation_duration then
                    local progress = elapsed_time / animation_duration
                    progress = 1 - (1 - progress) * (1 - progress) -- ease-out
                    anim.width = (bg_width * 2) + (anim.target_width - (bg_width * 2)) * progress
                else
                    anim.width = anim.target_width
                end

                bg_width = anim.width / 2
            else
                tooltip_animations[index] = nil
            end

            local bg_alpha = math.floor(170 * alpha_animation)
            local icon_alpha = math.floor(256 * alpha_animation)
            local arrow_alpha = math.floor(120 * alpha_animation)
            local text_alpha = math.floor(255 * alpha_animation)

            local bg_color = Color(0, 0, 0, bg_alpha)

            Render.FilledRect(Vec2(animated_screen_pos.x - bg_width, animated_screen_pos.y - bg_height), Vec2(animated_screen_pos.x + bg_width, animated_screen_pos.y + bg_height), bg_color, 6)
            Render.Blur(Vec2(animated_screen_pos.x - bg_width, animated_screen_pos.y - bg_height), Vec2(animated_screen_pos.x + bg_width, animated_screen_pos.y + bg_height), 0/2, 1, 6)

            local icon_x
            if is_cursor_in_rect and tooltip_animations[index] then
                icon_x = animated_screen_pos.x - bg_width + size/10
            else
                icon_x = animated_screen_pos.x - size/2
            end

            Render.Image(ward.type == "Obs" and observer_icon or sentry_icon, Vec2(icon_x, animated_screen_pos.y - size/2), Vec2(size, size), Color(icon_alpha, icon_alpha, icon_alpha))

            local arrow_size = size * 0.4
            local arrow_y = animated_screen_pos.y + size/2 + 10

            Render.Line(
                Vec2(animated_screen_pos.x - arrow_size/2 - 2, arrow_y - arrow_size/2),
                Vec2(animated_screen_pos.x, arrow_y + arrow_size/2),
                Color(255, 255, 255, arrow_alpha),
                2
            )

            Render.Line(
                Vec2(animated_screen_pos.x, arrow_y + arrow_size/2),
                Vec2(animated_screen_pos.x + arrow_size/2 + 2, arrow_y - arrow_size/2),
                Color(255, 255, 255, arrow_alpha),
                2
            )

            if is_cursor_in_rect then
                local tooltip_font_size = ui.tooltipsize:Get()
                local info_text = ward.description or "No description"

                local anim = tooltip_animations[index]
                if anim and anim.width > (size / 1.5) * 3 then
                    local text_alpha_anim = math.min(text_alpha, (anim.width - (size / 1.5) * 3) / ((size / 1.5) * 2) * text_alpha)
                    Render.Text(font, tooltip_font_size, info_text, Vec2(animated_screen_pos.x - bg_width + size + 10, animated_screen_pos.y - tooltip_font_size/1.8), Color(255, 255, 255, text_alpha_anim))
                end
            end
        end
    end

    for i, ward in ipairs(wards_data) do
        if IsWardVisibleForTeam(ward) then
            draw_single_ward(ward, false, i)
        end
    end

    if show_custom_wards then
        for i, ward in ipairs(custom_wards) do
            if IsWardVisibleForTeam(ward) then
                draw_single_ward(ward, true, "custom_" .. i)
            end
        end
    end
end

local draw_debug = function ()
    local cursorPosX, cursorPosY = Input.GetCursorPos()
    local cursorPosWorld = Input.GetWorldCursorPos()
    local cursorPosZ = World.GetGroundZ(cursorPosWorld.x, cursorPosWorld.y)

    Render.Circle(Vec2(cursorPosX, cursorPosY), 10, Color(255, 255, 255, 255))
    Render.Text(font, 20, string.format("POS X: %.2f POS Y: %.2f POS Z: %.2f", cursorPosWorld.x, cursorPosWorld.y, cursorPosZ), Vec2(cursorPosX+30, cursorPosY), Color(255, 255, 255, 255))

    Render.Text(font, 16, string.format("FrameTime: %.4f | Alpha: %.3f | GlobalSwitch: %s", 
        GlobalVars.GetAbsFrameTime(), alpha_animation, ui.global_switch:Get() and "ON" or "OFF"), 
        Vec2(cursorPosX+30, cursorPosY+60), Color(255, 255, 255, 255))

    Render.Text(font, 16, string.format("OnlyAlt: %s | AltPressed: %s | DataLoaded: %s", 
        ui.onlyalt:Get() and "ON" or "OFF",
        Input.IsKeyDown(Enum.ButtonCode.KEY_LALT) and "YES" or "NO",
        data_loaded and "YES" or "NO"), 
        Vec2(cursorPosX+30, cursorPosY+90), Color(255, 255, 255, 255))
end

wardhelper.OnUpdate = function ()
    if not my_hero then 
        my_hero = Heroes.GetLocal()
        return 
    end

    if not request_sent then
        load_wards_data()
    end

    if not custom_wards_loaded then
        LoadCustomWards()
        custom_wards_loaded = true
        UpdateWardList()
    end

    builder_mode = ui.builder_mode:Get()

    if Input.IsKeyDownOnce(ui.add_ward_bind:Get()) then
        if builder_mode then
            local cursorPosWorld = Input.GetWorldCursorPos()
            local groundZ = World.GetGroundZ(cursorPosWorld.x, cursorPosWorld.y)

            local teams = {}
            if selected_team == "Both" then
                teams = {"Dire", "Radiant"}
            else
                teams = {selected_team}
            end

            local new_ward = {
                x = cursorPosWorld.x,
                y = cursorPosWorld.y,
                z = groundZ,
                type = selected_ward_type,
                description = "Custom ward location",
                teams = teams
            }

            table.insert(custom_wards, new_ward)
            SaveCustomWards()
            UpdateWardList()

            DebugLog("[builder ward debug] ward added at: " .. cursorPosWorld.x .. ", " .. cursorPosWorld.y .. " (" .. selected_ward_type .. ") for teams: " .. table.concat(teams, ", "))
        else
            DebugLog("[builder ward debug] ERROR: builder mode is not enabled!")
        end
    end

    placehelp(my_hero)
end

wardhelper.OnDraw = function ()
    if ui.debug:Get() then
        draw_debug()
    end

    if data_loaded then
        draw_ward_icons()
    end

    if ui.onlyalt:Get() then
        local alt_pressed = Input.IsKeyDown(Enum.ButtonCode.KEY_LALT)
        local particles_exist = next(ward_particles) ~= nil
    end
end

return wardhelper