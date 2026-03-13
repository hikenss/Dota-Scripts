local MMRTracker = {}
local DB_KEY = "mmr_tracker_ult"

local function InitDB()
    if type(db["x"]) ~= "userdata" then db["x"] = {} end
    if type(db["x"][DB_KEY]) ~= "userdata" then db["x"][DB_KEY] = {} end
end

-- Menu
local g_main = Menu.Create("Scripts", "Outros", "MMR Tracker Ultimate", "Configurações", "Principal")
g_main:Parent():Parent():Icon("\u{f080}")

local s_enable, s_lock, s_transparent = g_main:Switch("Ativar painel", true), g_main:Switch("Bloquear posição", false), g_main:Switch("Fundo transparente", true)
local s_trans_alpha = g_main:Slider("Opacidade do fundo", 0, 100, 60, "%d%%")
local s_x, s_y = g_main:Slider("Pos X", 0, 1920, 300, "%d"), g_main:Slider("Pos Y", 0, 1080, 100, "%d")
s_x:Visible(false) s_y:Visible(false)
g_main:Button("Redefinir posição", function() s_x:Set(300) s_y:Set(100) end)

local g_stats = Menu.Create("Scripts", "Outros", "MMR Tracker Ultimate", "Configurações", "\u{f080} Estatísticas")
local s_session_show = g_stats:Switch("Mostrar sessão", true)
g_stats:Button("Resetar sessão", function() MMRTracker.ResetSession() end)

local g_calc = Menu.Create("Scripts", "Outros", "MMR Tracker Ultimate", "Configurações", "\u{f1ec} Calculadora")
local s_avg_delta, s_calc_show = g_calc:Slider("MMR médio por jogo", 10, 100, 25, "%d"), g_calc:Switch("Mostrar calculadora de partidas", true)
local s_target_use, s_target_val = g_calc:Switch("Usar meta própria", false), g_calc:Slider("Meta de MMR", 1000, 12000, 5000, "%d")
local s_rank_icon = g_calc:Switch("Mostrar ícone de ranking", false)

local g_tilt = Menu.Create("Scripts", "Outros", "MMR Tracker Ultimate", "Configurações", "\u{f132} Tilt Guard")
local s_tilt_enable, s_tilt_limit = g_tilt:Switch("Ativar proteção contra tilt", true), g_tilt:Slider("Limite de perda para alerta", 50, 200, 75, "-%d")

-- Theme & Fonts
local theme = {
    bg = Color(20, 20, 20, 255), border = Color(60, 60, 60, 255), text = Color(220, 220, 220, 255),
    accent = Color(255, 195, 15, 255), bar = Color(255, 195, 15, 255),
    tilt_bg = Color(50, 0, 0, 240), tilt_border = Color(255, 0, 0, 255), tilt_text = Color(255, 50, 50, 200),
    win = Color(100, 255, 100, 255), loss = Color(255, 100, 100, 255), dim = Color(150, 150, 150, 255),
    subtext = Color(200, 200, 200, 180)
}

local fonts = {
    main = Render.LoadFont("Segoe UI", 11, Enum.FontWeight.BOLD),
    small = Render.LoadFont("Segoe UI", 9, Enum.FontWeight.NORMAL),
    icon = Render.LoadFont("FontAwesomeEx", 10, 12)
}

local rank_icon_thresholds = {
    {5620,80},{5420,75},{5220,74},{5020,73},{4820,72},{4620,71},{4466,65},{4312,64},{4158,63},{4004,62},{3850,61},
    {3696,55},{3542,54},{3388,53},{3234,52},{3080,51},{2926,45},{2772,44},{2618,43},{2464,42},{2310,41},
    {2156,35},{2002,34},{1848,33},{1694,32},{1540,31},{1386,25},{1232,24},{1078,23},{924,22},{770,21},
    {616,15},{462,14},{308,13},{154,12}
}

local function rank_icon_id(mmr)
    for _, t in ipairs(rank_icon_thresholds) do if mmr >= t[1] then return t[2] end end
    return mmr > 0 and 11 or 0
end

local session = {startMMR = 0, initialized = false, wins = 0, losses = 0}
local rank_icon_cache = {}
local state = {lastMMR = 0, mmr_diff = 0, drag = {active = false, offset = Vec2(0, 0)}, ui_height = 65, panel_pos = Vec2(0, 0), panel_size = Vec2(200, 65), panel_visible = false}

local rankTable = {
    {154,"Herald",2},{308,"Herald",3},{462,"Herald",4},{616,"Herald",5},
    {770,"Guardian",1},{924,"Guardian",2},{1078,"Guardian",3},{1232,"Guardian",4},{1386,"Guardian",5},
    {1540,"Crusader",1},{1694,"Crusader",2},{1848,"Crusader",3},{2002,"Crusader",4},{2156,"Crusader",5},
    {2310,"Archon",1},{2464,"Archon",2},{2618,"Archon",3},{2772,"Archon",4},{2926,"Archon",5},
    {3080,"Legend",1},{3234,"Legend",2},{3388,"Legend",3},{3542,"Legend",4},{3696,"Legend",5},
    {3850,"Ancient",1},{4004,"Ancient",2},{4158,"Ancient",3},{4312,"Ancient",4},{4466,"Ancient",5},
    {4620,"Divine",1},{4820,"Divine",2},{5020,"Divine",3},{5220,"Divine",4},{5420,"Divine",5},
    {5600,"Immortal",0}
}

local function save_session(mmr, steam, wins, losses)
    db["x"][DB_KEY]["session_start_mmr"], db["x"][DB_KEY]["session_steam_id"] = mmr, steam
    db["x"][DB_KEY]["session_wins"], db["x"][DB_KEY]["session_losses"] = wins or 0, losses or 0
end

local function load_or_init_session(mmr, steam)
    if mmr <= 0 then
        session.initialized, session.startMMR, session.wins, session.losses = false, 0, 0, 0
        save_session(nil, nil, nil, nil)
        return
    end
    local stored_id = db["x"][DB_KEY]["session_steam_id"]
    if stored_id ~= steam or db["x"][DB_KEY]["session_start_mmr"] == nil then
        session.startMMR, session.wins, session.losses, session.initialized = mmr, 0, 0, true
        save_session(mmr, steam, 0, 0)
    else
        session.startMMR = db["x"][DB_KEY]["session_start_mmr"]
        session.wins, session.losses = db["x"][DB_KEY]["session_wins"] or 0, db["x"][DB_KEY]["session_losses"] or 0
        session.initialized = true
    end
end

function MMRTracker.ResetSession()
    InitDB()
    local mmr, steamid = Engine.GetMMRV2(), GC.GetSteamID()
    state.lastMMR, state.mmr_diff = 0, 0
    load_or_init_session(mmr, steamid)
    db["x"][DB_KEY]["mmr"], db["x"][DB_KEY]["steam_id"] = nil, nil
end

function MMRTracker.OnGameThreadInit()
    InitDB()
    local mmr, steamid = Engine.GetMMRV2(), GC.GetSteamID()
    if db["x"][DB_KEY]["mmr"] and db["x"][DB_KEY]["steam_id"] == steamid then
        state.mmr_diff = mmr - db["x"][DB_KEY]["mmr"]
    end
    load_or_init_session(mmr, steamid)
    db["x"][DB_KEY]["mmr"], db["x"][DB_KEY]["steam_id"], state.lastMMR = mmr, steamid, mmr
end

local function GetRankInfo(mmr)
    if mmr == 0 then return nil, nil end
    local current, nextRank = {mmr = 0, name = "Herald", tier = 1}, nil
    for i, data in ipairs(rankTable) do
        if mmr < data[1] then
            nextRank = {mmr = data[1], name = data[2], tier = data[3]}
            if i > 1 then
                local prev = rankTable[i - 1]
                current = {mmr = prev[1], name = prev[2], tier = prev[3]}
            end
            break
        end
    end
    if not nextRank and #rankTable > 0 then
        local last = rankTable[#rankTable]
        current = {mmr = last[1], name = last[2], tier = last[3]}
    end
    return current, nextRank
end

local function HandleDrag(pos, size)
    if s_lock:Get() then return end
    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
        local cursor = Vec2(Input.GetCursorPos())
        if not state.drag.active and Input.IsCursorInRect(pos.x, pos.y, size.x, size.y) then
            state.drag.active, state.drag.offset = true, cursor - pos
        elseif state.drag.active then
            local newPos = cursor - state.drag.offset
            s_x:Set(math.floor(newPos.x)) s_y:Set(math.floor(newPos.y))
        end
    else state.drag.active = false end
end

function MMRTracker.OnFrame()
    if not s_enable:Get() or Engine.GetUIState() ~= Enum.UIState.DOTA_GAME_UI_STATE_DASHBOARD then
        state.panel_visible = false return
    end
    state.panel_visible = true
    local pos, myMMR = Vec2(s_x:Get(), s_y:Get()), Engine.GetMMRV2()
    if not session.initialized and myMMR > 0 then load_or_init_session(myMMR, GC.GetSteamID()) end
    local currentRank, nextRank = GetRankInfo(myMMR)
    local avgGain, pad_x, pad_y, gap = s_avg_delta:Get(), 8, 8, 4

    -- Altura dos blocos
    local h_rank = myMMR == 0 and 38 or (not nextRank and 22 or 32)
    local h_stats = (session.initialized and session.startMMR > 0) and 14 or 0
    local total_h = pad_y + h_rank + (h_stats > 0 and (gap + h_stats) or 0) + pad_y
    
    local dt = GlobalVars.GetAbsFrameTime and GlobalVars.GetAbsFrameTime() or 0.016
    if dt > 0.1 then dt = 0.016 end
    state.ui_height = math.lerp(state.ui_height, total_h, dt * 10)
    local size = Vec2(200, state.ui_height)
    state.panel_pos, state.panel_size = pos, size
    HandleDrag(pos, size)

    -- Fundo e efeitos
    local sessionDiff = myMMR - session.startMMR
    local isTilt = s_tilt_enable:Get() and (sessionDiff <= -(s_tilt_limit:Get())) and (myMMR > 0)
    local bgColor = theme.bg
    if isTilt then bgColor = theme.tilt_bg
    elseif s_transparent:Get() then
        local base, pct = Menu.Style("additional_background"), math.max(0, math.min(100, s_trans_alpha:Get()))
        bgColor = Color(base.r, base.g, base.b, math.floor(pct * 2.55))
    end
    Render.FilledRect(pos, pos + size, bgColor, 10, Enum.DrawFlags.RoundCornersAll)
    if s_transparent:Get() and not isTilt then Render.Blur(pos, pos + size, 1, 0.9, 10, Enum.DrawFlags.RoundCornersAll) end
    if isTilt then
        Render.TextCentered(fonts.main, pos.x + size.x / 2, pos.y + size.y / 2 - 6, "STOP PLAYING!", theme.tilt_text)
        Render.TextCentered(fonts.small, pos.x + size.x / 2, pos.y + size.y / 2 + 8, "Lose limit reached", theme.subtext)
    end
    local drawY, contentX, contentW = pad_y, pos.x + pad_x, size.x - (pad_x * 2)
    if myMMR == 0 then
        Render.Text(fonts.icon, 14, "\u{f059}", Vec2(contentX, pos.y + drawY), theme.accent)
        Render.Text(fonts.main, 11, "Uncalibrated", Vec2(contentX + 20, pos.y + drawY), theme.text)
        drawY = drawY + 16
        Render.FilledRect(Vec2(contentX, pos.y + drawY), Vec2(contentX + contentW, pos.y + drawY + 4), Color(0, 0, 0, 150), 2)
        drawY = drawY + 8
        Render.Text(fonts.small, 9, "Play Ranked to unlock", Vec2(contentX, pos.y + drawY), theme.subtext)
        drawY = drawY + 14
    elseif not nextRank then
        local rank_tier_id, iconSize = math.floor(rank_icon_id(myMMR) / 10), 16
        if s_rank_icon:Get() and rank_icon_cache[rank_tier_id] then
            Render.Image(rank_icon_cache[rank_tier_id], Vec2(contentX, pos.y + drawY), Vec2(iconSize, iconSize), Color(255, 255, 255, 255))
        else Render.Text(fonts.icon, 14, "\u{f091}", Vec2(contentX, pos.y + drawY), theme.accent) end
        Render.Text(fonts.main, 11, "Immortal", Vec2(contentX + 22, pos.y + drawY), theme.accent)
        Render.Text(fonts.small, 10, tostring(myMMR), Vec2(pos.x + size.x - pad_x - Render.TextSize(fonts.small, 10, tostring(myMMR)).x, pos.y + drawY + 1), theme.text)
        drawY = drawY + h_rank
    else
        local curName, targetVal = currentRank.name .. " " .. currentRank.tier, s_target_use:Get() and s_target_val:Get() or nextRank.mmr
        local iconW = 0
        if s_rank_icon:Get() then
            local rank_tier_id = math.floor(rank_icon_id(myMMR) / 10)
            if rank_icon_cache[rank_tier_id] == nil then
                rank_icon_cache[rank_tier_id] = Render.LoadImage("panorama/images/rank_tier_icons/rank" .. tostring(rank_tier_id) .. "_psd.vtex_c")
            end
            Render.Image(rank_icon_cache[rank_tier_id], Vec2(contentX, pos.y + drawY - 1), Vec2(14, 14), Color(255, 255, 255, 255))
            iconW = 18
        end
        Render.Text(fonts.main, 11, curName, Vec2(contentX + iconW, pos.y + drawY), theme.text)
        drawY = drawY + 14
        local barStart, startRange = Vec2(contentX, pos.y + drawY), currentRank.mmr
        local totalRange, progress = targetVal - startRange, myMMR - startRange
        local pct = math.max(0, math.min(1, progress / totalRange))
        Render.FilledRect(barStart, barStart + Vec2(contentW, 4), Color(0, 0, 0, 150), 2)
        if pct > 0 then Render.FilledRect(barStart, barStart + Vec2(contentW * pct, 4), theme.bar, 2) end
        drawY = drawY + 7

        local mmrStr = string.format("%d / %d", myMMR, targetVal)
        Render.Text(fonts.small, 9, mmrStr, Vec2(contentX, pos.y + drawY), theme.subtext)
        if s_calc_show:Get() then
            local needed = targetVal - myMMR
            if needed > 0 then
                local wins, dd = math.ceil(needed / avgGain), math.ceil(needed / (avgGain * 2))
                local tStr, tSize = string.format("%d W (%d DD)", wins, dd), Render.TextSize(fonts.small, 9, string.format("%d W (%d DD)", wins, dd))
                Render.Text(fonts.small, 9, tStr, Vec2(pos.x + size.x - pad_x - tSize.x, pos.y + drawY), theme.text)
            end
        end
        drawY = drawY + 11
    end

    -- Estatísticas de sessão
    if h_stats > 0 then
        drawY = drawY + gap
        Render.FilledRect(Vec2(contentX, pos.y + drawY), Vec2(pos.x + size.x - pad_x, pos.y + drawY + 1), Color(255, 255, 255, 15))
        drawY = drawY + 4
        local totalGames, winrate = session.wins + session.losses, 0
        if totalGames > 0 then winrate = (session.wins / totalGames) * 100 end
        local wrStr = string.format("Session WR: %.1f%% (%dW %dL)", winrate, session.wins, session.losses)
        local wrCol = totalGames == 0 and theme.subtext or (winrate >= 50 and theme.win or theme.loss)
        Render.Text(fonts.small, 9, wrStr, Vec2(contentX, pos.y + drawY), wrCol)
        local sessStr, sessCol = "0", theme.text
        if sessionDiff > 0 then sessStr, sessCol = string.format("+%d", sessionDiff), theme.win
        elseif sessionDiff < 0 then sessStr, sessCol = tostring(sessionDiff), theme.loss end
        Render.Text(fonts.small, 9, sessStr, Vec2(pos.x + size.x - pad_x - Render.TextSize(fonts.small, 9, sessStr).x, pos.y + drawY), sessCol)
    end
end

function MMRTracker.OnGameEnd()
    if not Engine.IsInGame() then
        local mmr = Engine.GetMMRV2()
        state.mmr_diff = mmr - state.lastMMR
        if state.mmr_diff > 0 then
            session.wins = session.wins + 1
            InitDB() db["x"][DB_KEY]["session_wins"] = session.wins
        elseif state.mmr_diff < 0 then
            session.losses = session.losses + 1
            InitDB() db["x"][DB_KEY]["session_losses"] = session.losses
        end
        state.lastMMR, db["x"][DB_KEY]["mmr"] = mmr, mmr
    end
end

function MMRTracker.OnKeyEvent(data)
    if not state.panel_visible then return true end
    if data.event == Enum.EKeyEvent.EKeyEvent_KEY_DOWN and data.key == Enum.ButtonCode.KEY_MOUSE1 then
        local pos, size = state.panel_pos, state.panel_size
        if Input.IsCursorInRect(pos.x, pos.y, size.x, size.y) then return false end
    end
    return true
end

return MMRTracker
