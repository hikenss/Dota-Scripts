local mapdraw = {}

--#region
local CONFIG = {
    START_POS = {x = -8000, y = -8000},
    SCALE = 200,
    LETTER_SPACING = 12,
    LINE_SPACING = 18,
    MAX_CHARS_PER_LINE = 7,
    DRAW_DELAY = 0.02,
    
    MIN_CURVE_DISTANCE = 300,
    CURVE_INTENSITY = 0.1,
    
    QUEUE_SHUFFLE_WINDOW = 3,
}


local HUMANIZE_PRESETS = {
    {name = "Mode1", wobble = 5, angle_var = 0.02, length_var = 0.05, delay_var = 0.01},
    {name = "Mode2", wobble = 15, angle_var = 0.05, length_var = 0.08, delay_var = 0.02}
}
--#endregion

--#region UI
local tab = Menu.Create("Scripts", "Other", "Chat no Mapa v2")
tab:Icon("\u{f075}")
local group = tab:Create("Principal"):Create("Grupo")

local ui = {
    global_switch = group:Switch("Ativado", false, "\u{f00c}"),
    text_input = group:Input("Texto para desenhar", "", "\u{f040}"),
    humanize_level = group:Slider("Nível de Humanização", 1, #HUMANIZE_PRESETS, 1, 1, "\u{f1de}"),
    draw_button = nil 
}

ui.draw_button = group:Button("Desenhar no mapa", function()
    local text = ui.text_input:Get()
    if ui.global_switch:Get() and text ~= "" then
        mapdraw.DrawTextOnMinimap(text, ui.humanize_level:Get())
    end
end, false, 1.0)


ui.global_switch:SetCallback(function()
    local enabled = ui.global_switch:Get()
    ui.text_input:Disabled(not enabled)
    ui.draw_button:Disabled(not enabled)
    ui.humanize_level:Disabled(not enabled)
end, true)
--#endregion

--#region
local state = {
    my_hero = nil,
    drawing_queue = {},
    last_draw_time = 0,
    random_seed = os.clock() * 1000000
}
--#endregion

--#region
local LETTER_PATTERNS = {
    A = {{1,10,5,0},{5,0,9,10},{3,6,7,6}},
    B = {{1,0,1,10},{1,0,7,0},{1,5,7,5},{1,10,7,10},{7,0,8,2},{8,2,7,5},{7,5,8,8},{8,8,7,10}},
    C = {{8,2,7,0},{7,0,3,0},{3,0,1,2},{1,2,1,8},{1,8,3,10},{3,10,7,10},{7,10,8,8}},
    D = {{1,0,1,10},{1,0,6,0},{1,10,6,10},{6,0,8,2},{8,2,8,8},{8,8,6,10}},
    E = {{1,0,1,10},{1,0,8,0},{1,5,6,5},{1,10,8,10}},
    F = {{1,0,1,10},{1,0,8,0},{1,5,6,5}},
    G = {{8,2,7,0},{7,0,3,0},{3,0,1,2},{1,2,1,8},{1,8,3,10},{3,10,7,10},{7,10,8,8},{8,8,8,6},{8,6,6,6}},
    H = {{1,0,1,10},{9,0,9,10},{1,5,9,5}},
    I = {{3,0,7,0},{5,0,5,10},{3,10,7,10}},
    J = {{2,0,8,0},{5,0,5,8},{5,8,4,10},{4,10,2,10},{2,10,1,8}},
    K = {{1,0,1,10},{1,5,9,0},{1,5,9,10}},
    L = {{1,0,1,10},{1,10,8,10}},
    M = {{1,10,1,0},{1,0,5,4},{5,4,9,0},{9,0,9,10}},
    N = {{1,10,1,0},{1,0,9,10},{9,10,9,0}},
    O = {{3,0,7,0},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,3,10},{3,10,1,8},{1,8,1,2},{1,2,3,0}},
    P = {{1,10,1,0},{1,0,7,0},{7,0,8,2},{8,2,7,5},{7,5,1,5}},
    Q = {{3,0,7,0},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,3,10},{3,10,1,8},{1,8,1,2},{1,2,3,0},{6,7,9,10}},
    R = {{1,10,1,0},{1,0,7,0},{7,0,8,2},{8,2,7,5},{7,5,1,5},{5,5,9,10}},
    S = {{8,2,7,0},{7,0,2,0},{2,0,1,2},{1,2,2,4},{2,4,7,4},{7,4,8,6},{8,6,7,8},{7,8,2,8},{2,8,1,10}},
    T = {{1,0,9,0},{5,0,5,10}},
    U = {{1,0,1,8},{1,8,3,10},{3,10,7,10},{7,10,9,8},{9,8,9,0}},
    V = {{1,0,5,10},{5,10,9,0}},
    W = {{1,0,2,10},{2,10,5,6},{5,6,8,10},{8,10,9,0}},
    X = {{1,0,9,10},{9,0,1,10}},
    Y = {{1,0,5,5},{9,0,5,5},{5,5,5,10}},
    Z = {{1,0,9,0},{9,0,1,10},{1,10,9,10}},
    

    ["А"] = {{1,10,5,0},{5,0,9,10},{3,6,7,6}},
    ["Б"] = {{1,0,1,10},{1,0,8,0},{1,5,6,5},{6,5,8,7},{8,7,8,10},{8,10,1,10}},
    ["В"] = {{1,0,1,10},{1,0,7,0},{1,5,7,5},{1,10,7,10},{7,0,8,2},{8,2,7,5},{7,5,8,8},{8,8,7,10}},
    ["Г"] = {{1,0,1,10},{1,0,8,0}},
    ["Д"] = {{3,0,7,0},{7,0,7,8},{7,8,9,8},{9,8,9,10},{1,10,1,8},{1,8,3,8},{3,8,3,0},{2,8,8,8}},
    ["Е"] = {{1,0,1,10},{1,0,8,0},{1,5,6,5},{1,10,8,10}},
    ["Ё"] = {{1,0,1,10},{1,0,8,0},{1,5,6,5},{1,10,8,10},{3,-2,3,-1},{6,-2,6,-1}},
    ["Ж"] = {{1,0,5,5},{9,0,5,5},{5,5,5,10},{1,10,5,5},{9,10,5,5}},
    ["З"] = {{1,2,3,0},{3,0,7,0},{7,0,8,2},{8,2,6,5},{6,5,8,8},{8,8,7,10},{7,10,3,10},{3,10,1,8}},
    ["И"] = {{1,10,1,0},{9,10,9,0},{1,10,9,0}},
    ["Й"] = {{1,10,1,0},{9,10,9,0},{1,10,9,0},{3,-2,5,-1},{5,-1,7,-2}},
    ["К"] = {{1,0,1,10},{1,5,9,0},{1,5,9,10}},
    ["Л"] = {{2,10,5,0},{5,0,8,10}},
    ["М"] = {{1,10,1,0},{1,0,5,4},{5,4,9,0},{9,0,9,10}},
    ["Н"] = {{1,0,1,10},{9,0,9,10},{1,5,9,5}},
    ["О"] = {{3,0,7,0},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,3,10},{3,10,1,8},{1,8,1,2},{1,2,3,0}},
    ["П"] = {{1,10,1,0},{1,0,9,0},{9,0,9,10}},
    ["Р"] = {{1,10,1,0},{1,0,7,0},{7,0,8,2},{8,2,7,5},{7,5,1,5}},
    ["С"] = {{8,2,7,0},{7,0,3,0},{3,0,1,2},{1,2,1,8},{1,8,3,10},{3,10,7,10},{7,10,8,8}},
    ["Т"] = {{1,0,9,0},{5,0,5,10}},
    ["У"] = {{1,0,5,5},{9,0,5,5},{5,5,3,10},{3,10,1,10},{1,10,0,8}},
    ["Ф"] = {{5,0,5,10},{3,2,7,2},{7,2,8,3},{8,3,8,7},{8,7,7,8},{7,8,3,8},{3,8,2,7},{2,7,2,3},{2,3,3,2}},
    ["Х"] = {{1,0,9,10},{9,0,1,10}},
    ["Ц"] = {{1,0,1,10},{7,0,7,10},{1,10,7,10},{7,10,8,12},{8,12,9,12}},
    ["Ч"] = {{1,0,1,5},{1,5,7,5},{7,0,7,10}},
    ["Ш"] = {{1,0,1,10},{5,0,5,10},{9,0,9,10},{1,10,9,10}},
    ["Щ"] = {{1,0,1,10},{5,0,5,10},{9,0,9,10},{1,10,9,10},{9,10,10,12},{10,12,11,12}},
    ["Ъ"] = {{1,0,4,0},{4,0,4,5},{4,5,8,5},{8,5,9,6},{9,6,9,9},{9,9,8,10},{8,10,4,10},{4,10,4,10}},
    ["Ы"] = {{1,0,1,10},{1,5,5,5},{5,5,6,6},{6,6,6,9},{6,9,5,10},{5,10,1,10},{8,0,8,10}},
    ["Ь"] = {{1,0,1,10},{1,5,7,5},{7,5,8,6},{8,6,8,9},{8,9,7,10},{7,10,1,10}},
    ["Э"] = {{8,2,7,0},{7,0,3,0},{3,0,1,2},{1,2,1,8},{1,8,3,10},{3,10,7,10},{7,10,8,8},{4,5,7,5}},
    ["Ю"] = {{1,0,1,10},{1,5,5,5},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,5,10},{5,10,5,0},{5,0,7,0}},
    ["Я"] = {{9,10,9,0},{9,0,3,0},{3,0,2,2},{2,2,3,5},{3,5,9,5},{5,5,1,10}},


    ["0"] = {{3,0,7,0},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,3,10},{3,10,1,8},{1,8,1,2},{1,2,3,0}},
    ["1"] = {{4,0,5,0},{5,0,5,10},{5,10,5,10}},
    ["2"] = {{1,2,3,0},{3,0,7,0},{7,0,9,2},{9,2,9,4},{9,4,1,10},{1,10,9,10}},
    ["3"] = {{1,2,3,0},{3,0,7,0},{7,0,9,2},{9,2,7,5},{7,5,9,8},{9,8,7,10},{7,10,3,10},{3,10,1,8}},
    ["4"] = {{1,0,1,6},{1,6,8,6},{8,0,8,10}},
    ["5"] = {{9,0,1,0},{1,0,1,5},{1,5,7,5},{7,5,9,7},{9,7,9,8},{9,8,7,10},{7,10,2,10},{2,10,1,8}},
    ["6"] = {{7,0,3,0},{3,0,1,2},{1,2,1,8},{1,8,3,10},{3,10,7,10},{7,10,9,8},{9,8,9,6},{9,6,7,5},{7,5,3,5}},
    ["7"] = {{1,0,9,0},{9,0,3,10}},
    ["8"] = {{3,0,7,0},{7,0,8,1},{8,1,8,4},{8,4,7,5},{7,5,3,5},{3,5,2,4},{2,4,2,1},{2,1,3,0},{3,5,7,5},{7,5,8,6},{8,6,8,9},{8,9,7,10},{7,10,3,10},{3,10,2,9},{2,9,2,6},{2,6,3,5}},
    ["9"] = {{7,5,3,5},{3,5,1,4},{1,4,1,2},{1,2,3,0},{3,0,7,0},{7,0,9,2},{9,2,9,8},{9,8,7,10},{7,10,3,10}},
    
    [" "] = {}
}


local CYRILLIC_UPPER = {
    ["а"]="А", ["б"]="Б", ["в"]="В", ["г"]="Г", ["д"]="Д", ["е"]="Е", ["ё"]="Ё",
    ["ж"]="Ж", ["з"]="З", ["и"]="И", ["й"]="Й", ["к"]="К", ["л"]="Л", ["м"]="М",
    ["н"]="Н", ["о"]="О", ["п"]="П", ["р"]="Р", ["с"]="С", ["т"]="Т", ["у"]="У",
    ["ф"]="Ф", ["х"]="Х", ["ц"]="Ц", ["ч"]="Ч", ["ш"]="Ш", ["щ"]="Щ", ["ъ"]="Ъ",
    ["ы"]="Ы", ["ь"]="Ь", ["э"]="Э", ["ю"]="Ю", ["я"]="Я"
}
--#endregion

--#region
local function get_natural_random(min, max)
    state.random_seed = (state.random_seed * 1103515245 + 12345) % 2147483647
    local normalized = state.random_seed / 2147483647
    return min + (max - min) * normalized
end

local function parse_utf8_chars(str)
    local chars = {}
    local byte_pos = 1
    local str_len = #str
    
    while byte_pos <= str_len do
        local byte = string.byte(str, byte_pos)
        local char_len = 1

        if byte >= 240 then char_len = 4
        elseif byte >= 224 then char_len = 3
        elseif byte >= 192 then char_len = 2
        end
        
        chars[#chars + 1] = string.sub(str, byte_pos, byte_pos + char_len - 1)
        byte_pos = byte_pos + char_len
    end
    
    return chars
end

local function to_uppercase(text)
    local chars = parse_utf8_chars(text)
    local result = {}
    
    for i, char in ipairs(chars) do
        result[i] = CYRILLIC_UPPER[char] or string.upper(char)
    end
    
    return table.concat(result)
end

local function apply_humanization(x, y, preset)

    local wobble_x = get_natural_random(-preset.wobble, preset.wobble)
    local wobble_y = get_natural_random(-preset.wobble, preset.wobble)
    

    local angle = get_natural_random(-preset.angle_var, preset.angle_var)
    local cos_a, sin_a = math.cos(angle), math.sin(angle)
    
    return x * cos_a - y * sin_a + wobble_x,
           x * sin_a + y * cos_a + wobble_y
end


local function generate_curve_points(x1, y1, x2, y2, preset)
    local points = {{x1, y1}}
    local distance = math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
    

    if distance > CONFIG.MIN_CURVE_DISTANCE then
        local mid_x = (x1 + x2) * 0.5
        local mid_y = (y1 + y2) * 0.5

        local perp_x = -(y2 - y1) / distance
        local perp_y = (x2 - x1) / distance
        

        local curve_amount = get_natural_random(-distance * CONFIG.CURVE_INTENSITY, 
                                              distance * CONFIG.CURVE_INTENSITY) * preset.length_var
        
        mid_x = mid_x + perp_x * curve_amount
        mid_y = mid_y + perp_y * curve_amount
        
        mid_x, mid_y = apply_humanization(mid_x, mid_y, preset)
        points[#points + 1] = {mid_x, mid_y}
    end
    
    points[#points + 1] = {x2, y2}
    return points
end


local function split_into_lines(chars)
    local lines = {}
    local current_line = {}
    
    for _, char in ipairs(chars) do
        current_line[#current_line + 1] = char
        
        if #current_line >= CONFIG.MAX_CHARS_PER_LINE then
            lines[#lines + 1] = current_line
            current_line = {}
        end
    end
    
    if #current_line > 0 then
        lines[#lines + 1] = current_line
    end
    
    return lines
end


local function shuffle_queue(queue, window_size)
    local shuffled = {}
    local temp_queue = {}
    
    for i, v in ipairs(queue) do
        temp_queue[i] = v
    end
    
    while #temp_queue > 0 do
        local window = math.min(window_size, #temp_queue)
        local index = math.random(window)
        shuffled[#shuffled + 1] = temp_queue[index]
        table.remove(temp_queue, index)
    end
    
    return shuffled
end
--#endregion

--#region
function mapdraw.DrawTextOnMinimap(text, humanize_level)
    if not text or text == "" then return end
    humanize_level = math.max(1, math.min(humanize_level or 1, #HUMANIZE_PRESETS))
    
    local preset = HUMANIZE_PRESETS[humanize_level]
    
    local upper_text = to_uppercase(text)
    local chars = parse_utf8_chars(upper_text)
    local lines = split_into_lines(chars)
    
    state.drawing_queue = {}
    
    local letter_spacing = CONFIG.LETTER_SPACING * CONFIG.SCALE
    local line_spacing = CONFIG.LINE_SPACING * CONFIG.SCALE
    
    for line_num, line_chars in ipairs(lines) do
        local line_rotation = get_natural_random(-preset.angle_var * 0.5, preset.angle_var * 0.5)
        local line_offset_x = get_natural_random(-preset.wobble * 2, preset.wobble * 2)
        local line_offset_y = get_natural_random(-preset.wobble, preset.wobble)
        
        for char_pos, char in ipairs(line_chars) do
            local pattern = LETTER_PATTERNS[char]
            if not pattern then goto continue end
            
            local spacing_variation = get_natural_random(-letter_spacing * 0.1, letter_spacing * 0.1)
            local char_x = CONFIG.START_POS.x + (char_pos - 1) * (letter_spacing + spacing_variation) + line_offset_x
            local char_y = CONFIG.START_POS.y + (line_num - 1) * line_spacing + line_offset_y
            
            local char_rotation = line_rotation + get_natural_random(-preset.angle_var * 0.3, preset.angle_var * 0.3)
            local char_scale = 1 + get_natural_random(-preset.length_var * 0.2, preset.length_var * 0.2)
            local cos_r, sin_r = math.cos(char_rotation), math.sin(char_rotation)
            
            for _, line_data in ipairs(pattern) do

                local x1 = line_data[1] * CONFIG.SCALE * char_scale
                local y1 = (10 - line_data[2]) * CONFIG.SCALE * char_scale
                local x2 = line_data[3] * CONFIG.SCALE * char_scale
                local y2 = (10 - line_data[4]) * CONFIG.SCALE * char_scale
                
                local rot_x1 = x1 * cos_r - y1 * sin_r
                local rot_y1 = x1 * sin_r + y1 * cos_r
                local rot_x2 = x2 * cos_r - y2 * sin_r
                local rot_y2 = x2 * sin_r + y2 * cos_r
                
                local final_x1, final_y1 = apply_humanization(char_x + rot_x1, char_y + rot_y1, preset)
                local final_x2, final_y2 = apply_humanization(char_x + rot_x2, char_y + rot_y2, preset)
                
                local curve_points = generate_curve_points(final_x1, final_y1, final_x2, final_y2, preset)
                
                for i = 1, #curve_points - 1 do
                    state.drawing_queue[#state.drawing_queue + 1] = {
                        start_pos = Vector(curve_points[i][1], curve_points[i][2], 0),
                        end_pos = Vector(curve_points[i+1][1], curve_points[i+1][2], 0),
                        delay_variation = get_natural_random(-preset.delay_var, preset.delay_var)
                    }
                end
            end
            
            ::continue::
        end
    end
    
    if humanize_level >= 2 then
        state.drawing_queue = shuffle_queue(state.drawing_queue, CONFIG.QUEUE_SHUFFLE_WINDOW)
    end
end
--#endregion

--#region
function mapdraw.OnUpdate()

    if not ui.global_switch:Get() then return end
    
    if not state.my_hero then 
        state.my_hero = Heroes.GetLocal()
        return 
    end
    
    if #state.drawing_queue > 0 then
        local current_time = os.clock()
        local line_data = state.drawing_queue[1]
        local delay = CONFIG.DRAW_DELAY + (line_data.delay_variation or 0)
        
        if (current_time - state.last_draw_time) >= delay then
            table.remove(state.drawing_queue, 1)
            MiniMap.SendLine(line_data.start_pos, true, false)
            MiniMap.SendLine(line_data.end_pos, false, false)
            state.last_draw_time = current_time
        end
    end
end
--#endregion

return mapdraw