local MMRTracker = {}

-- [[ 1. МЕНЮ ]]

local g_main = Menu.Create("Scripts", "Other", "MMR Tracker Ultimate", "Settings", "Main")
g_main:Parent():Parent():Icon("\u{f080}") 


local s_enable = g_main:Switch("Ativar painel", true)
local s_lock   = g_main:Switch("Travar posição", false)

local s_x = g_main:Slider("Posição X", 0, 1920, 300, "%d")
local s_y = g_main:Slider("Posição Y", 0, 1080, 100, "%d")
s_x:Visible(false)
s_y:Visible(false)

g_main:Button("Redefinir posição", function() 
    s_x:Set(300) 
    s_y:Set(100) 
end)

-- === ГРУППА 2: СТАТИСТИКА ===
local g_stats = Menu.Create("Scripts", "Other", "MMR Tracker Ultimate", "Settings", "\u{f080} Estatísticas")

local s_session_show  = g_stats:Switch("Mostrar sessão", true)
local s_history_show  = g_stats:Switch("Mostrar histórico de partidas", true)
local s_history_count = g_stats:Slider("Qtd. de partidas no histórico", 3, 10, 5, "%d")

g_stats:Button("Redefinir sessão", function() 
    MMRTracker.ResetSession() 
end)

-- === ГРУППА 3: КАЛЬКУЛЯТОР ===
local g_calc = Menu.Create("Scripts", "Other", "MMR Tracker Ultimate", "Settings", "\u{f1ec} Calculadora")

local s_avg_delta  = g_calc:Slider("MMR médio por partida", 10, 100, 25, "%d")
local s_calc_show  = g_calc:Switch("Mostrar calculadora de partidas", true)
local s_target_use = g_calc:Switch("Usar meta personalizada", false)
local s_target_val = g_calc:Slider("Meta de MMR", 1000, 12000, 5000, "%d")

-- === ГРУППА 4: TILT GUARD ===
local g_tilt = Menu.Create("Scripts", "Other", "MMR Tracker Ultimate", "Settings", "\u{f132} Proteção contra Tilt")

local s_tilt_enable = g_tilt:Switch("Ativar proteção contra tilt", true)
local s_tilt_limit  = g_tilt:Slider("Limite de derrotas para alerta", 50, 200, 75, "-%d")


-- [[ 2. КОНФИГУРАЦИЯ И ДАННЫЕ ]]

local theme = {
    bg      = Color(20, 20, 20, 240),
    border  = Color(60, 60, 60, 255),
    text    = Color(220, 220, 220, 255),
    accent  = Color(255, 195, 15, 255),
    bar     = Color(255, 195, 15, 255),
    
    tilt_bg     = Color(50, 0, 0, 240),
    tilt_border = Color(255, 0, 0, 255),
    tilt_text   = Color(255, 50, 50, 200),
    
    win     = Color(100, 255, 100, 255),
    loss    = Color(255, 100, 100, 255),
    dim     = Color(150, 150, 150, 255),
    subtext = Color(200, 200, 200, 180)
}

local fonts = {
    main = Render.LoadFont("Verdana", 14, 16),
    bold = Render.LoadFont("Verdana", 14, 800),
    small = Render.LoadFont("Verdana", 11, 16),
    icon = Render.LoadFont("FontAwesomeEx", 14, 16),
    warn = Render.LoadFont("Verdana", 24, 800)
}

local session = {
    startMMR = 0,
    initialized = false,
    history = {} 
}

local state = {
    lastMMR = 0,
    drag = { active = false, offset = Vec2(0,0) },
    ui_height = 95
}

local rankTable = {
    {154,"Herald",2}, {308,"Herald",3}, {462,"Herald",4}, {616,"Herald",5},
    {770,"Guardian",1}, {924,"Guardian",2}, {1078,"Guardian",3}, {1232,"Guardian",4}, {1386,"Guardian",5},
    {1540,"Crusader",1}, {1694,"Crusader",2}, {1848,"Crusader",3}, {2002,"Crusader",4}, {2156,"Crusader",5},
    {2310,"Archon",1}, {2464,"Archon",2}, {2618,"Archon",3}, {2772,"Archon",4}, {2926,"Archon",5},
    {3080,"Legend",1}, {3234,"Legend",2}, {3388,"Legend",3}, {3542,"Legend",4}, {3696,"Legend",5},
    {3850,"Ancient",1}, {4004,"Ancient",2}, {4158,"Ancient",3}, {4312,"Ancient",4}, {4466,"Ancient",5},
    {4620,"Divine",1}, {4820,"Divine",2}, {5020,"Divine",3}, {5220,"Divine",4}, {5420,"Divine",5},
    {5600,"Immortal",0}
}

-- [[ 3. ЛОГИКА ]]

local function Lerp(a, b, t)
    return a + (b - a) * t
end

function MMRTracker.ResetSession()
    session.initialized = false
    session.history = {}
    session.startMMR = 0
end

local function GetSystemTime()
    local date = os.date("*t")
    return string.format("%02d:%02d", date.hour, date.min)
end

local function GetRankInfo(mmr)
    if mmr == 0 then return nil, nil end 

    local current = {mmr=0, name="Herald", tier=1}
    local nextRank = nil
    for i, data in ipairs(rankTable) do
        if mmr < data[1] then
            nextRank = {mmr = data[1], name = data[2], tier = data[3]}
            if i > 1 then
                local prev = rankTable[i-1]
                current = {mmr = prev[1], name = prev[2], tier = prev[3]}
            end
            break
        end
    end
    return current, nextRank
end

local function HandleDrag(pos, size)
    if s_lock:Get() then return end
    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
        local cursor = Vec2(Input.GetCursorPos())
        if not state.drag.active and Input.IsCursorInRect(pos.x, pos.y, size.x, size.y) then
            state.drag.active = true
            state.drag.offset = cursor - pos
        elseif state.drag.active then
            local newPos = cursor - state.drag.offset
            s_x:Set(math.floor(newPos.x))
            s_y:Set(math.floor(newPos.y))
        end
    else
        state.drag.active = false
    end
end

local function UpdateMatchHistory(currentMMR)
    if state.lastMMR == 0 then state.lastMMR = currentMMR return end
    if currentMMR == 0 then return end 
    
    local diff = currentMMR - state.lastMMR
    if diff ~= 0 then
        local entry = {
            change = diff,
            time = GetSystemTime(),
            result = diff > 0 and "WIN" or "LOSS"
        }
        table.insert(session.history, 1, entry)
        if #session.history > 20 then table.remove(session.history) end
        
        state.lastMMR = currentMMR
    end
end

-- [[ 4. ОТРИСОВКА ]]

function MMRTracker.OnFrame()
    if not s_enable:Get() then return end
    if Engine.GetUIState() ~= Enum.UIState.DOTA_GAME_UI_STATE_DASHBOARD then return end

    local pos = Vec2(s_x:Get(), s_y:Get())
    local myMMR = Engine.GetMMR and Engine.GetMMR() or 0
    
    -- Инициализация сессии
    if not session.initialized and myMMR > 0 then
        session.startMMR = myMMR
        session.initialized = true
        state.lastMMR = myMMR
    end

    UpdateMatchHistory(myMMR)

    local currentRank, nextRank = GetRankInfo(myMMR)
    local avgGain = s_avg_delta:Get()
    
    -- [[ РАСЧЕТ РАЗМЕРА И ОТСТУПОВ ]]
    local pad_y = 10
    local gap = 15
    local row_h = 15
    
    -- 1. Высота блока Ранга
    local h_rank = 0
    if myMMR == 0 then 
        h_rank = 70 -- Высота для Uncalibrated
    elseif not nextRank then 
        h_rank = 40 -- Высота для Immortal
    else 
        h_rank = 50 -- Высота для обычного ранга (Текст + Бар + Текст)
    end
    
    -- 2. Высота блока Сессии
    local h_session = 0
    if s_session_show:Get() then
        h_session = 20 -- Разделитель + Текст
    end
    
    -- 3. Высота блока Истории
    local h_history = 0
    local hist_limit = 0
    if s_history_show:Get() and #session.history > 0 then
        hist_limit = math.min(#session.history, s_history_count:Get())
        h_history = 5 + (hist_limit * row_h) -- Отступ + строки
    end
    
    -- Считает полную высоту
    local total_h = pad_y + h_rank
    if h_session > 0 then total_h = total_h + gap + h_session end
    if h_history > 0 then total_h = total_h + gap + h_history end
    total_h = total_h + pad_y
    
    -- Анимация
    local dt = GlobalVars.GetAbsFrameTime and GlobalVars.GetAbsFrameTime() or 0.016
    if dt > 0.1 then dt = 0.016 end 
    state.ui_height = Lerp(state.ui_height, total_h, dt * 10) 
    
    local size = Vec2(240, state.ui_height)

    HandleDrag(pos, size)

    -- [[ ФОН ]]
    local sessionDiff = myMMR - session.startMMR
    local isTilt = s_tilt_enable:Get() and (sessionDiff <= -(s_tilt_limit:Get())) and (myMMR > 0)
    
    local bgColor = isTilt and theme.tilt_bg or theme.bg
    local borderColor = isTilt and theme.tilt_border or theme.border

    Render.FilledRect(pos, pos + size, bgColor, 5)
    Render.Rect(pos, pos + size, borderColor, 5, 0, 1)

    if isTilt then
        Render.TextCentered(fonts.warn, pos.x + 120, pos.y + size.y / 2 - 10, "PARE DE JOGAR!", theme.tilt_text)
        Render.TextCentered(fonts.small, pos.x + 120, pos.y + size.y / 2 + 15, "Limite de derrotas atingido", theme.subtext)
    end

    local drawY = pad_y

    -- [[ 1. DESENHO DO RANK ]]
    if myMMR == 0 then
        -- Não calibrado
        Render.Text(fonts.icon, 16, "\u{f059}", pos + Vec2(20, drawY), theme.accent)
        Render.Text(fonts.main, 15, "Sem Rank", pos + Vec2(45, drawY), theme.accent)
        
        Render.Text(fonts.main, 14, "Não calibrado", pos + Vec2(20, drawY + 22), theme.text)
        
        local barStart = pos + Vec2(15, drawY + 45)
        Render.FilledRect(barStart, barStart + Vec2(210, 5), Color(0,0,0,150), 2)
        Render.Text(fonts.small, 11, "Jogue Ranqueada para desbloquear", pos + Vec2(15, drawY + 55), theme.subtext)
        
        drawY = drawY + h_rank
    
    elseif not nextRank then 
        -- Imortal
        Render.Text(fonts.icon, 16, "\u{f091}", pos + Vec2(20, drawY+5), theme.accent)
        Render.Text(fonts.main, 15, "Imortal", pos + Vec2(45, drawY+5), theme.accent)
        Render.Text(fonts.main, 14, "MMR: " .. myMMR, pos + Vec2(20, drawY+30), theme.text)
        
        drawY = drawY + h_rank
    else
        -- Normal
        local curName = currentRank.name .. " " .. currentRank.tier
        local targetVal = s_target_use:Get() and s_target_val:Get() or nextRank.mmr
        local targetName = s_target_use:Get() and "Meta" or (nextRank.name .. " " .. nextRank.tier)

        Render.Text(fonts.main, 14, curName, pos + Vec2(15, drawY), theme.text)
        local arrowX = 15 + Render.TextSize(fonts.main, 14, curName).x + 10
        Render.Text(fonts.icon, 12, "\u{f061}", pos + Vec2(arrowX, drawY+2), theme.accent)
        Render.Text(fonts.main, 14, targetName, pos + Vec2(arrowX + 20, drawY), theme.text)

        -- Barra em +25
        local barStart = pos + Vec2(15, drawY + 25)
        local barW = 210
        local startRange = currentRank.mmr
        local totalRange = targetVal - startRange
        local progress = myMMR - startRange
        local pct = math.max(0, math.min(1, progress / totalRange))

        Render.FilledRect(barStart, barStart + Vec2(barW, 5), Color(0,0,0,150), 2)
        if pct > 0 then
            Render.FilledRect(barStart, barStart + Vec2(barW * pct, 5), theme.bar, 2)
        end

        -- Texto em +35
        Render.Text(fonts.small, 11, string.format("%d / %d", myMMR, targetVal), pos + Vec2(15, drawY + 35), theme.subtext)

        if s_calc_show:Get() then
            local needed = targetVal - myMMR
            if needed > 0 then
                local wins = math.ceil(needed / avgGain)
                local dd = math.ceil(needed / (avgGain * 2))
                local tStr = string.format("%d V (%d DD)", wins, dd)
                local tSize = Render.TextSize(fonts.small, 11, tStr)
                Render.Text(fonts.small, 11, tStr, pos + Vec2(225 - tSize.x, drawY + 35), theme.text)
            end
        end
        
        drawY = drawY + h_rank
    end

    -- [[ 2. DESENHO DA SESSÃO ]]
    if h_session > 0 then
        drawY = drawY + gap -- Adiciona espaço ANTES da sessão
        
        Render.Rect(pos + Vec2(15, drawY), pos + Vec2(225, drawY), Color(255,255,255,20), 1) -- Separador
        
        local txt, col = "Sessão: 0", theme.text
        if sessionDiff > 0 then 
            txt = string.format("Sessão: +%d (~%d V)", sessionDiff, math.ceil(sessionDiff/avgGain))
            col = theme.win
        elseif sessionDiff < 0 then
            txt = string.format("Sessão: %d (~%d D)", sessionDiff, math.ceil(math.abs(sessionDiff)/avgGain))
            col = theme.loss
        end
        
        Render.Text(fonts.small, 12, txt, pos + Vec2(15, drawY + 5), col)
        
        drawY = drawY + h_session
    end

    -- [[ 3. DESENHO DO HISTÓRICO ]]
    if h_history > 0 then
        drawY = drawY + gap -- Adiciona espaço ANTES do histórico
        
        Render.Rect(pos + Vec2(15, drawY), pos + Vec2(225, drawY), Color(255,255,255,20), 1) -- Separador
        
        local startY = drawY + 5
        local count = 0
        
        for _, match in ipairs(session.history) do
            if count >= hist_limit then break end
            
            local relativeY = startY + (count * row_h)
            if relativeY + row_h < state.ui_height then
                local y = pos.y + relativeY
                local resColor = match.change > 0 and theme.win or theme.loss
                local sign = match.change > 0 and "+" or ""
                
                Render.Text(fonts.small, 11, match.time, pos + Vec2(15, y - pos.y), theme.dim)
                Render.Text(fonts.small, 11, match.result == "WIN" and "VITÓRIA" or "DERROTA", pos + Vec2(60, y - pos.y), resColor)
                local diffText = sign .. match.change
                local dSize = Render.TextSize(fonts.small, 11, diffText)
                Render.Text(fonts.small, 11, diffText, pos + Vec2(225 - dSize.x, y - pos.y), resColor)
            end
            
            count = count + 1
        end
    end
end

return MMRTracker