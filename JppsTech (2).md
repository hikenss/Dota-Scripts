--.name JppsTech
--.author Jpps
--.description JppsTech Dota 2 Brain v9.0 — Unified HUD + Map Control + Tempo Coach

local script = {}

--------------------------------------------------------------------------------
-- SAVE SYSTEM
--------------------------------------------------------------------------------
local SAVE_FILE = "jppstech_v9.dat"
local savedData = {}

local function savePath()
    return (os.getenv("APPDATA") or ".") .. "\\" .. SAVE_FILE
end

local function loadSave()
    pcall(function()
        local f = io.open(savePath(), "r")
        if not f then return end
        for line in f:lines() do
            local k, v = line:match("^(.-)=(.+)$")
            if k and v then savedData[k] = tonumber(v) or 0 end
        end
        f:close()
    end)
end

local function writeSave()
    pcall(function()
        local f = io.open(savePath(), "w")
        if not f then return end
        for k, v in pairs(savedData) do
            f:write(k .. "=" .. tostring(math.floor(v)) .. "\n")
        end
        f:close()
    end)
end

local function sGet(k, d) return savedData[k] or d end
local function sSet(k, v) savedData[k] = v end

loadSave()
local saveTimer = 0

--------------------------------------------------------------------------------
-- LANGUAGE
--------------------------------------------------------------------------------
local LANG = "en"
if savedData["lang"] == 1 then LANG = "ru" elseif savedData["lang"] == 2 then LANG = "pt" end

local T = {
    en = {
        brain = "BRAIN", intel = "INTEL", tracker = "TRACKER", sidebar = "SIDEBAR",
        enable = "Enable", ui_scale = "UI Scale", lock = "Lock Panels", language = "Language",
        kill_matrix = "Kill Matrix", panel = "Panel", overhead = "Overhead",
        reverse = "Reverse Threat", world_circles = "World Circles",
        hp_bar = "HP Bar", dmg_nums = "Damage Numbers", threshold = "Threshold",
        mia_circles = "MIA Circles", dashboard = "Dashboard", momentum = "Momentum",
        tips = "Tips", fight_tips = "Fight Tips",
        rune_timer = "Rune Timer", stack_timer = "Stack Timer",
        combo = "Combo", show_dmg = "Show Damage", show_mana = "Show Mana",
        show_time = "Cast Time", initiation = "Initiation",
        min_enemies = "Min Enemies",
        show_marker = "Marker", show_aoe = "AoE", show_count = "Count",
        tower_range = "Tower Range", show_blink = "Blink Range",
        smoke_alert = "Smoke Alert", linken = "Linken Tracker",
        last_hit = "Last Hit Helper", kill_flash = "Kill Flash",
        dodge = "Dodge Assist", gank_alert = "Gank Alert",
        auto_phase = "Auto Phase", auto_stick = "Auto Stick/Wand",
        auto_faerie = "Auto Faerie", hp_threshold = "HP %",
        power_graph = "Power Graph", history = "History",
        items = "Item Tracker", items_cd = "Cooldowns",
        spells = "Spell Tracker",
        cosmic_en = "Cosmic Background", cosmic_dark = "Darkness",
        cosmic_stars = "Stars", cosmic_nebula = "Nebula",
        cosmic_shooting = "Shooting Stars", cosmic_aurora = "Aurora",
        cosmic_attract = "Cursor Attract", cosmic_glow = "Particle Glow",
        cosmic_size = "Particle Size",
        dead = "DEAD", missing = "MIA", retreat = "RETREAT", push = "PUSH",
        ready = "READY", on_cd = "CD", no_mana = "MANA",
        vs = "vs", s = "s", hits = "h",
        gpm = "GPM", nw = "NW", win = "Win", alive = "Alive",
        power = "Power", us = "Us", them = "Them",
        rune = "Rune", stack = "Stack",
        damage = "Dmg", mana_word = "Mana", cast_point = "Cast", respawning = "Resp",
        enemy_down = "KILL!", smoke_detected = "SMOKE!", dodge_alert = "DODGE!",
        danger = "DANGER", enemies = "enemies", score = "Score",
        linken_active = "Lnk", no_items = "No tracked items",
        gank_inc = "GANK!",
        -- Tempo Coach
        tempo_coach = "Tempo Coach", tempo_defend = "DEFEND", tempo_push = "PUSH",
        tempo_fight = "FIGHT", tempo_farm = "FARM", tempo_stand = "STAND",
        tempo_roshan = "ROSHAN", tempo_retreat = "RETREAT", tempo_smoke = "SMOKE GANK",
        tempo_spike = "POWER SPIKE!", tempo_bkb = "BKB! Force fights!",
        tempo_rosh_check = "Check Roshan?",
        -- Map Control
        map_control = "MAP CONTROL", safe_farm = "Safe Farm",
        split_advice = "Split Push", map_missing = "Missing World",
        map_grouped = "Enemies grouped! Split push!",
        map_many_mia = "Many MIA - play safe",
        map_all_mia = "ALL MIA - danger!",
        -- HUD
        level = "Level", armor = "Armor", mr = "Magic Res",
        attack_dmg = "Attack", move_spd = "MS", attack_range = "Range",
        game_time = "Game Time", bounty_rune = "Bounty",
        no_target = "No target", xpm = "XPM", cs_min = "CS/m",
        uptime = "Uptime", dead_time = "Dead", alive_time = "Alive",
        -- Tempo hardcoded
        msg_go = "AVANTE!", msg_back = "RECUAR!", msg_outnumbered = "outnumbered",
        msg_outpowered = "outpowered", msg_low_support = "low support",
        msg_low_resources = "low HP+mana",
        msg_gank_pressure = "gank pressure", msg_avoid_cast = "avoid cast zone",
        msg_check_map = "check map before pathing", msg_forward_risk = "forward risk",
        msg_free_rune = "free rune", msg_contest_rune = "contest rune",
        msg_glyph_ready = "glyph ready", msg_enemy_glyph = "enemy glyph up",
        msg_smoke_ready = "smoke ready", msg_isolated = "isolated",
        msg_check_pit = "check pit", msg_setup_vision = "setup vision",
        msg_prepare_map = "prepare map", msg_safe_farm = "safe farm",
        msg_hold_info = "hold info", msg_all_mia = "All MIA",
        msg_bb_risk = "BB risk", msg_free_shard = "free shard window",
        msg_rosh_alive = "Rosh alive", msg_rosh_window = "window",
        msg_rosh_in = "Rosh in", msg_rosh_suspect = "Rosh suspicious",
        msg_rosh_killed = "Roshan killed", msg_level_up = "Level up",
        msg_rune_taken = "Rune taken", msg_glyph_used = "Glyph used",
        msg_rosh_respawn = "Rosh respawn", msg_torm_available = "Tormentor available",
        msg_bb_warn = "Buyback risk", msg_enemy_glyph_ready = "Enemy glyph ready",
        msg_rune_contest = "Rune contest", msg_free_rune_map = "Free rune",
        msg_psy = "PSY", msg_psy_rosh = "rosh suspicion",
        msg_paused = "Paused", msg_reset = "reset",
        msg_threat_label = "Threat",
    },
    pt = {
        brain = "CEREBRO", intel = "INTEL", tracker = "RASTREIO", sidebar = "LATERAL",
        enable = "Ativar", ui_scale = "Escala UI", lock = "Travar Paineis", language = "Idioma",
        kill_matrix = "Matriz de Abate", panel = "Painel", overhead = "Acima",
        reverse = "Ameaca Reversa", world_circles = "Circulos Mundo",
        hp_bar = "Barra HP", dmg_nums = "Numeros de Dano", threshold = "Limite",
        mia_circles = "Circulos MIA", dashboard = "Painel Info", momentum = "Impulso",
        tips = "Dicas", fight_tips = "Dicas de Luta",
        rune_timer = "Timer de Runa", stack_timer = "Timer de Stack",
        combo = "Combo", show_dmg = "Mostrar Dano", show_mana = "Mostrar Mana",
        show_time = "Tempo de Cast", initiation = "Iniciacao",
        min_enemies = "Min Inimigos",
        show_marker = "Marcador", show_aoe = "AoE", show_count = "Contagem",
        tower_range = "Alcance Torre", show_blink = "Alcance Blink",
        smoke_alert = "Alerta Smoke", linken = "Rastreio Linken",
        last_hit = "Ajuda Last Hit", kill_flash = "Flash de Kill",
        dodge = "Ajuda Dodge", gank_alert = "Alerta Gank",
        auto_phase = "Auto Phase", auto_stick = "Auto Stick/Wand",
        auto_faerie = "Auto Faerie", hp_threshold = "HP %",
        power_graph = "Grafico Poder", history = "Historico",
        items = "Rastreio Itens", items_cd = "Cooldowns",
        spells = "Rastreio Skills",
        cosmic_en = "Fundo Cosmico", cosmic_dark = "Escuridao",
        cosmic_stars = "Estrelas", cosmic_nebula = "Nebulosa",
        cosmic_shooting = "Estrelas Cadentes", cosmic_aurora = "Aurora",
        cosmic_attract = "Atrair Cursor", cosmic_glow = "Brilho",
        cosmic_size = "Tamanho Particula",
        dead = "MORTO", missing = "SUMIU", retreat = "RECUAR", push = "EMPURRAR",
        ready = "PRONTO", on_cd = "CD", no_mana = "MANA",
        vs = "vs", s = "s", hits = "h",
        gpm = "OPM", nw = "PL", win = "Vitoria", alive = "Vivo",
        power = "Poder", us = "Nos", them = "Eles",
        rune = "Runa", stack = "Stack",
        damage = "Dano", mana_word = "Mana", cast_point = "Cast", respawning = "Resp",
        enemy_down = "ABATE!", smoke_detected = "SMOKE!", dodge_alert = "DESVIE!",
        danger = "PERIGO", enemies = "inimigos", score = "Pont",
        linken_active = "Lnk", no_items = "Sem itens rastreados",
        gank_inc = "GANK!",
        -- Tempo Coach
        tempo_coach = "Tempo Coach", tempo_defend = "DEFENDER", tempo_push = "EMPURRAR",
        tempo_fight = "LUTAR", tempo_farm = "FARMAR", tempo_stand = "ESPERAR",
        tempo_roshan = "ROSHAN", tempo_retreat = "RECUAR", tempo_smoke = "SMOKE GANK",
        tempo_spike = "PICO DE PODER!", tempo_bkb = "BKB! Force lutas!",
        tempo_rosh_check = "Checar Roshan?",
        -- Map Control
        map_control = "CONTROLE MAPA", safe_farm = "Farm Seguro",
        split_advice = "Split Push", map_missing = "Sumiram do Mapa",
        map_grouped = "Inimigos agrupados! Split push!",
        map_many_mia = "Muitos sumiram - jogue seguro",
        map_all_mia = "TODOS SUMIRAM - perigo!",
        -- HUD
        level = "Nivel", armor = "Armadura", mr = "Res Magica",
        attack_dmg = "Ataque", move_spd = "VM", attack_range = "Alcance",
        game_time = "Tempo de Jogo", bounty_rune = "Runa Bounty",
        no_target = "Sem alvo", xpm = "XPM", cs_min = "CS/m",
        uptime = "Tempo Ativo", dead_time = "Morto", alive_time = "Vivo",
        -- Tempo hardcoded
        msg_go = "AVANTE!", msg_back = "RECUAR!", msg_outnumbered = "em desvantagem",
        msg_outpowered = "mais fracos", msg_low_support = "sem apoio",
        msg_low_resources = "HP+mana baixos",
        msg_gank_pressure = "pressao de gank", msg_avoid_cast = "zona de perigo",
        msg_check_map = "checar mapa antes de ir", msg_forward_risk = "risco ao avancar",
        msg_free_rune = "runa livre", msg_contest_rune = "disputar runa",
        msg_glyph_ready = "glyph pronto", msg_enemy_glyph = "glyph inimigo pronto",
        msg_smoke_ready = "smoke pronto", msg_isolated = "isolado(s)",
        msg_check_pit = "checar rosh pit", msg_setup_vision = "colocar visao",
        msg_prepare_map = "preparar mapa", msg_safe_farm = "farm seguro",
        msg_hold_info = "sem info", msg_all_mia = "Todos sumiram",
        msg_bb_risk = "risco Buyback", msg_free_shard = "janela de shard gratis",
        msg_rosh_alive = "Rosh vivo", msg_rosh_window = "janela",
        msg_rosh_in = "Rosh em", msg_rosh_suspect = "Rosh suspeito",
        msg_rosh_killed = "Roshan abatido", msg_level_up = "Subiu de nivel",
        msg_rune_taken = "Runa pega", msg_glyph_used = "Glyph usado",
        msg_rosh_respawn = "Rosh respawn", msg_torm_available = "Tormentor disponivel",
        msg_bb_warn = "Risco de Buyback", msg_enemy_glyph_ready = "Glyph inimigo pronto",
        msg_rune_contest = "Disputa de Runa", msg_free_rune_map = "Runa livre",
        msg_psy = "PSY", msg_psy_rosh = "suspeita de rosh",
        msg_paused = "Pausado", msg_reset = "resetar",
        msg_threat_label = "Perigo",
    },
    ru = {},
}

-- RU strings in source were previously saved with mojibake (UTF-8 bytes shown as CP1251 text).
-- Decode them at runtime so we can keep the file stable and still switch EN/RU correctly.
local CP1251_REV = {
    [0x0402]=0x80,[0x0403]=0x81,[0x201A]=0x82,[0x0453]=0x83,[0x201E]=0x84,[0x2026]=0x85,[0x2020]=0x86,[0x2021]=0x87,
    [0x20AC]=0x88,[0x2030]=0x89,[0x0409]=0x8A,[0x2039]=0x8B,[0x040A]=0x8C,[0x040C]=0x8D,[0x040B]=0x8E,[0x040F]=0x8F,
    [0x0452]=0x90,[0x2018]=0x91,[0x2019]=0x92,[0x201C]=0x93,[0x201D]=0x94,[0x2022]=0x95,[0x2013]=0x96,[0x2014]=0x97,
    [0x2122]=0x99,[0x0459]=0x9A,[0x203A]=0x9B,[0x045A]=0x9C,[0x045C]=0x9D,[0x045B]=0x9E,[0x045F]=0x9F,
    [0x00A0]=0xA0,[0x040E]=0xA1,[0x045E]=0xA2,[0x0408]=0xA3,[0x00A4]=0xA4,[0x0490]=0xA5,[0x00A6]=0xA6,[0x00A7]=0xA7,
    [0x0401]=0xA8,[0x00A9]=0xA9,[0x0404]=0xAA,[0x00AB]=0xAB,[0x00AC]=0xAC,[0x00AD]=0xAD,[0x00AE]=0xAE,[0x0407]=0xAF,
    [0x00B0]=0xB0,[0x00B1]=0xB1,[0x0406]=0xB2,[0x0456]=0xB3,[0x0491]=0xB4,[0x00B5]=0xB5,[0x00B6]=0xB6,[0x00B7]=0xB7,
    [0x0451]=0xB8,[0x2116]=0xB9,[0x0454]=0xBA,[0x00BB]=0xBB,[0x0458]=0xBC,[0x0405]=0xBD,[0x0455]=0xBE,[0x0457]=0xBF,
}
local RU_DECODE_CACHE = {}
local RU_CP1251_CACHE = {}
local RU_RENDER_CP1251 = false -- use UTF-8 by default
local RU_RENDER_AUTO = false
local RU_RENDER_MODE_CACHE = {}
local RU_TRANSLIT_CACHE = {}
local RU_FORCE_TRANSLIT = false -- keep real Russian text by default; enable only as last-resort fallback
local RU_TRANSLIT_CP_SAFE = {
    [0x0410]="A",[0x0411]="B",[0x0412]="V",[0x0413]="G",[0x0414]="D",[0x0415]="E",[0x0401]="Yo",[0x0416]="Zh",[0x0417]="Z",[0x0418]="I",[0x0419]="Y",
    [0x041A]="K",[0x041B]="L",[0x041C]="M",[0x041D]="N",[0x041E]="O",[0x041F]="P",[0x0420]="R",[0x0421]="S",[0x0422]="T",[0x0423]="U",[0x0424]="F",
    [0x0425]="Kh",[0x0426]="Ts",[0x0427]="Ch",[0x0428]="Sh",[0x0429]="Sch",[0x042A]="'",[0x042B]="Y",[0x042C]="'",[0x042D]="E",[0x042E]="Yu",[0x042F]="Ya",
    [0x0430]="a",[0x0431]="b",[0x0432]="v",[0x0433]="g",[0x0434]="d",[0x0435]="e",[0x0451]="yo",[0x0436]="zh",[0x0437]="z",[0x0438]="i",[0x0439]="y",
    [0x043A]="k",[0x043B]="l",[0x043C]="m",[0x043D]="n",[0x043E]="o",[0x043F]="p",[0x0440]="r",[0x0441]="s",[0x0442]="t",[0x0443]="u",[0x0444]="f",
    [0x0445]="kh",[0x0446]="ts",[0x0447]="ch",[0x0448]="sh",[0x0449]="sch",[0x044A]="'",[0x044B]="y",[0x044C]="'",[0x044D]="e",[0x044E]="yu",[0x044F]="ya",
    [0x2116]="#",[0x2013]="-",[0x2014]="-",[0x00AB]="\"",[0x00BB]="\"",
}

local function decodeRuMojibake(s)
    if type(s) ~= "string" or s == "" then return s end
    if RU_DECODE_CACHE[s] ~= nil then return RU_DECODE_CACHE[s] end
    if not utf8 then
        RU_DECODE_CACHE[s] = s
        return s
    end
    local bytes = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(s) do
            local b = nil
            if cp <= 0x7F then
                b = cp
            elseif cp >= 0x0410 and cp <= 0x044F then
                b = cp - 0x350 -- Unicode Cyrillic range -> CP1251 C0..FF
            else
                b = CP1251_REV[cp]
            end
            if not b then error("cp1251-map") end
            bytes[#bytes+1] = string.char(b)
        end
    end)
    if not ok then
        RU_DECODE_CACHE[s] = s
        return s
    end
    local out = table.concat(bytes)
    local okUtf8, utf8Len = pcall(utf8.len, out)
    if (not okUtf8) or (not utf8Len) then
        RU_DECODE_CACHE[s] = s
        return s
    end
    RU_DECODE_CACHE[s] = out
    return out
end

local function encodeCp1251ForRender(s)
    if type(s) ~= "string" or s == "" then return s end
    if RU_CP1251_CACHE[s] ~= nil then return RU_CP1251_CACHE[s] end
    if not utf8 then
        RU_CP1251_CACHE[s] = s
        return s
    end
    local bytes = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(s) do
            local b = nil
            if cp <= 0x7F then
                b = cp
            elseif cp >= 0x0410 and cp <= 0x044F then
                b = cp - 0x350
            else
                b = CP1251_REV[cp]
            end
            if not b then b = 0x3F end -- '?'
            bytes[#bytes+1] = string.char(b)
        end
    end)
    if not ok then
        RU_CP1251_CACHE[s] = s
        return s
    end
    local out = table.concat(bytes)
    RU_CP1251_CACHE[s] = out
    return out
end

function translitRuToAscii(s)
    if type(s) ~= "string" or s == "" then return s end
    if RU_TRANSLIT_CACHE[s] ~= nil then return RU_TRANSLIT_CACHE[s] end
    local res = translitRuToAsciiSafe(s)
    RU_TRANSLIT_CACHE[s] = res
    return res
end

function translitRuToAsciiSafe(s)
    if type(s) ~= "string" or s == "" then return s end
    if RU_TRANSLIT_CACHE[s] ~= nil then return RU_TRANSLIT_CACHE[s] end
    if not utf8 then
        RU_TRANSLIT_CACHE[s] = s
        return s
    end
    local out = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(s) do
            out[#out+1] = RU_TRANSLIT_CP_SAFE[cp] or utf8.char(cp)
        end
    end)
    if not ok then
        RU_TRANSLIT_CACHE[s] = s
        return s
    end
    local res = table.concat(out)
    RU_TRANSLIT_CACHE[s] = res
    return res
end

local function hasNonAsciiBytes(s)
    if type(s) ~= "string" or s == "" then return false end
    for i = 1, #s do
        if s:byte(i) > 127 then return true end
    end
    return false
end

local function textSizeX(font, size, txt)
    if not font then return nil end
    local ok, r = pcall(Render.TextSize, font, size, txt)
    if ok and r and r.x then return r.x end
    return nil
end

local function pickRuRenderMode(font, size)
    local key = tostring(size or 0)
    if RU_RENDER_MODE_CACHE[key] then return RU_RENDER_MODE_CACHE[key] end
    local mode = RU_RENDER_CP1251 and "cp1251" or "utf8"
    if not (RU_RENDER_AUTO and font and utf8 and type(Render.TextSize) == "function") then
        RU_RENDER_MODE_CACHE[key] = mode
        return mode
    end

    -- Probe font glyph path: some builds expect UTF-8, others render CP1251 bytes.
    local probeUtf = decodeRuMojibake((T.ru and (T.ru.safe_farm or T.ru.map_control)) or "")
    if not hasNonAsciiBytes(probeUtf) then
        RU_RENDER_MODE_CACHE[key] = mode
        return mode
    end
    local probeCp = encodeCp1251ForRender(probeUtf)
    local probeChars = #probeUtf
    if utf8 and utf8.len then
        local okLen, chLen = pcall(utf8.len, probeUtf)
        if okLen and chLen and chLen > 0 then probeChars = chLen end
    end
    local probeQ = string.rep("?", math.max(1, probeChars))
    local wu = textSizeX(font, size, probeUtf)
    local wc = textSizeX(font, size, probeCp)
    local wq = textSizeX(font, size, probeQ)

    if wu and wq and math.abs(wu - wq) > 0.5 then
        mode = "utf8"
    elseif wc and wq and math.abs(wc - wq) > 0.5 then
        mode = "cp1251"
    else
        mode = "translit"
    end
    RU_RENDER_MODE_CACHE[key] = mode
    return mode
end

local function renderTextForFont(txt, font, size)
    txt = tostring(txt or "")
    if txt == "" or LANG ~= "ru" or not hasNonAsciiBytes(txt) then return txt end
    if RU_FORCE_TRANSLIT then return translitRuToAsciiSafe(txt) end
    local mode = pickRuRenderMode(font, size)
    if mode == "cp1251" then
        return encodeCp1251ForRender(txt)
    elseif mode == "translit" then
        return translitRuToAsciiSafe(txt)
    end
    return txt
end

local function L(k)
    local v = T[LANG] and T[LANG][k]
    if LANG == "ru" and type(v) == "string" then
        v = decodeRuMojibake(v)
    end
    if type(v) == "string" then return v end
    return (T.en[k]) or k
end

function uiGetVal(widget, default)
    if widget and widget.Get then
        local ok, v = pcall(widget.Get, widget)
        if ok and v ~= nil then return v end
    end
    return default
end

function clearLocaleRuntimeCaches()
    RU_DECODE_CACHE = {}
    RU_CP1251_CACHE = {}
    RU_TRANSLIT_CACHE = {}
    RU_RENDER_MODE_CACHE = {}
end

function applyRuRenderModeIndex(idx)
    idx = tonumber(idx) or 1
    -- 0=Auto, 1=UTF-8, 2=CP1251, 3=Translit
    if idx == 0 then
        RU_RENDER_AUTO = true
        RU_RENDER_CP1251 = false
        RU_FORCE_TRANSLIT = false
    elseif idx == 2 then
        RU_RENDER_AUTO = false
        RU_RENDER_CP1251 = true
        RU_FORCE_TRANSLIT = false
    elseif idx == 3 then
        RU_RENDER_AUTO = false
        RU_RENDER_CP1251 = false
        RU_FORCE_TRANSLIT = true
    else
        RU_RENDER_AUTO = false
        RU_RENDER_CP1251 = false
        RU_FORCE_TRANSLIT = false
    end
end

--------------------------------------------------------------------------------
-- SCREEN & SCALING
--------------------------------------------------------------------------------
local gScale = 1.0
local SW, SH = 1920, 1080

local function refreshScreen()
    local getter = Render.ScreenSize or Render.GetScreenSize
    if not getter then return end
    local ok, r = pcall(getter)
    if ok and r and r.x and r.y and r.x > 0 then SW, SH = r.x, r.y end
end

local function sc(v) return math.floor(v * gScale + 0.5) end
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local F = math.floor

--------------------------------------------------------------------------------
-- FONT SYSTEM
--------------------------------------------------------------------------------
local FontCache = {}
local fontsOK = false
local FONT_NAMES = {"Segoe UI", "Tahoma", "Arial", "Verdana"}

local function getFont(sz)
    sz = clamp(F(sz + 0.5), 8, 72)
    if FontCache[sz] then return FontCache[sz] end
    local flags = Enum.FontCreate and Enum.FontCreate.FONTFLAG_ANTIALIAS or nil
    for _, name in ipairs(FONT_NAMES) do
        local ok, f = pcall(function()
            if Render.LoadFont then
                return Render.LoadFont(name, flags)
            end
            return nil
        end)
        if ok and f and f ~= 0 then
            FontCache[sz] = f; fontsOK = true; return f
        end
        local ok2, f2 = pcall(function()
            if Render.CreateFont then
                local weight = (Enum.FontWeight and (Enum.FontWeight.MEDIUM or Enum.FontWeight.NORMAL)) or 500
                return Render.CreateFont(name, sz, weight, flags)
            end
            return nil
        end)
        if ok2 and f2 and f2 ~= 0 then
            FontCache[sz] = f2; fontsOK = true; return f2
        end
    end
    return nil
end

local function initFonts()
    if fontsOK then return true end
    for _, s in ipairs({8,9,10,11,12,14,16,18,20,24,28,32,36,48}) do getFont(s) end
    return fontsOK
end

--------------------------------------------------------------------------------
-- COLOR HELPERS
--------------------------------------------------------------------------------
local function col(r, g, b, a) return Color(r, g, b, F(clamp(a or 255, 0, 255))) end
local function colA(c, a) return Color(c.r, c.g, c.b, F(clamp(a, 0, 255))) end

local C = {
    bg_panel   = col(10, 13, 22, 238),
    bg_section = col(16, 20, 32, 228),
    bg_row     = col(26, 32, 48, 212),
    bg_row_alt = col(20, 25, 38, 208),
    bg_hover   = col(35, 42, 65, 220),
    border     = col(45, 55, 85, 180),
    accent     = col(80, 140, 255, 255),
    white      = col(245, 248, 255, 255),
    text       = col(222, 228, 242, 255),
    gray       = col(150, 160, 184, 255),
    dark       = col(70, 80, 100, 255),
    green      = col(45, 220, 80, 255),
    red        = col(255, 65, 65, 255),
    yellow     = col(255, 200, 40, 255),
    orange     = col(255, 140, 40, 255),
    cyan       = col(40, 200, 255, 255),
    purple     = col(160, 100, 255, 255),
    pink       = col(255, 100, 180, 255),
    gold       = col(255, 190, 50, 255),
    hp         = col(55, 200, 80, 255),
    hp_bg      = col(35, 60, 40, 180),
    mana       = col(55, 130, 255, 255),
    mana_bg    = col(30, 45, 80, 180),
    kill_yes   = col(45, 255, 90, 255),
    kill_may   = col(255, 200, 50, 255),
    kill_no    = col(255, 80, 80, 255),
    cb_ok      = col(45, 220, 80, 255),
    cb_cd      = col(255, 100, 100, 255),
    cb_mana    = col(100, 150, 255, 255),
    smoke      = col(255, 60, 200, 255),
    tower      = col(255, 90, 90, 100),
    resize     = col(100, 110, 140, 150),
    separator  = col(50, 60, 90, 120),
    stat_label = col(140, 150, 170, 255),
    stat_value = col(220, 225, 240, 255),
    -- Tempo
    tempo_defend  = col(70, 130, 255, 255),
    tempo_push    = col(255, 180, 40, 255),
    tempo_fight   = col(255, 145, 20, 255),
    tempo_farm    = col(100, 220, 60, 255),
    tempo_stand   = col(160, 160, 180, 255),
    tempo_roshan  = col(255, 140, 0, 255),
    tempo_retreat = col(255, 100, 100, 255),
    tempo_smoke   = col(200, 80, 255, 255),
    -- Map Control
    map_safe   = col(40, 220, 80, 200),
    map_danger = col(255, 80, 60, 200),
    map_warn   = col(255, 200, 50, 200),
}

--------------------------------------------------------------------------------
-- SAFE WRAPPERS
--------------------------------------------------------------------------------
local function sG(fn, ...)
    if not fn then return nil end
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

local function sN(fn, ...)
    local r = sG(fn, ...)
    return (type(r) == "number") and r or 0
end

--------------------------------------------------------------------------------
-- DATA / ASSETS
--------------------------------------------------------------------------------
local API_ASSETS_ROOT = "C:\\Users\\Euphoria\\Documents\\API assets"
local ENABLE_LOCAL_IMAGE_FILES = false
local CANON = {loaded=false, items=nil, abilities=nil}
local DYN_ITEM_CACHE = {}
local HERO_ICON_CACHE = {}
local UI_ASSETS = {icons={}, loaded=false}

local function resolveRootDir()
    local info = (type(debug) == "table" and debug.getinfo) and debug.getinfo(1, "S") or nil
    local src = info and info.source or nil
    if type(src) == "string" and src:sub(1, 1) == "@" then
        local p = src:sub(2):gsub("/", "\\")
        local root = p:match("^(.*)\\scripts\\[^\\]+%.lua$")
        if root and root ~= "" then return root end
    end
    return "C:\\Umbrella"
end

local ROOT_DIR = resolveRootDir()
ABILITY_ICON_OVERRIDES = {
    -- Valve internal ability name typo; texture/file typically uses corrected spelling.
    antimage_persectur = "antimage_persecutor",
}
ITEM_ICON_OVERRIDES = {}

local function decodeJson(text)
    if type(text) ~= "string" or text == "" then return nil end
    local ok, jsonLib = pcall(require, "assets.JSON")
    if not ok or type(jsonLib) ~= "table" then
        ok, jsonLib = pcall(function()
            local loader = loadfile(ROOT_DIR .. "\\assets\\JSON.lua")
            return loader and loader() or nil
        end)
    end
    if not ok or type(jsonLib) ~= "table" then return nil end

    local okDirect, outDirect = pcall(function()
        return jsonLib.decode and jsonLib.decode(text) or nil
    end)
    if okDirect and outDirect then return outDirect end

    local okObject, outObject = pcall(function()
        return jsonLib.decode and jsonLib:decode(text) or nil
    end)
    if okObject and outObject then return outObject end

    return nil
end
local function readJsonFile(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local raw = f:read("*all")
    f:close()
    return decodeJson(raw)
end

local function mkShortToken(name, maxLen)
    maxLen = maxLen or 5
    if type(name) ~= "string" then return "?" end
    local s = name:gsub("^item_", ""):gsub("^npc_dota_hero_", ""):gsub("_", " ")
    local out = ""
    for w in s:gmatch("[A-Za-z0-9]+") do
        out = out .. w:sub(1, 1):upper()
        if #out >= maxLen then break end
    end
    if #out == 0 then out = s:gsub("%s+", ""):sub(1, maxLen) end
    return out:sub(1, maxLen)
end

local function loadImageHandle(candidates)
    if type(Render) ~= "table" or type(Render.LoadImage) ~= "function" then return nil end
    for _, path in ipairs(candidates) do
        if type(path) == "string" then
            -- Local file image loading is unstable on some builds and can spam CImageCache errors.
            if ENABLE_LOCAL_IMAGE_FILES or path:sub(1, 9) == "panorama/" then
                local ok, handle = pcall(Render.LoadImage, path)
                if ok and handle and handle ~= 0 then return handle end
            end
        end
    end
    return nil
end

local function loadUIAssets()
    if UI_ASSETS.loaded then return end
    UI_ASSETS.loaded = true
    local rel = "images\\MenuIcons\\"
    local relAlt = "images/MenuIcons/"
    local abs = ROOT_DIR .. "\\images\\MenuIcons\\"
    UI_ASSETS.icons.brain = loadImageHandle({rel.."detective_hat.png", relAlt.."detective_hat.png", abs.."detective_hat.png"})
    UI_ASSETS.icons.intel = loadImageHandle({rel.."binoculars_filled.png", relAlt.."binoculars_filled.png", abs.."binoculars_filled.png"})
    UI_ASSETS.icons.tracker = loadImageHandle({rel.."counter_simple_v2.png", relAlt.."counter_simple_v2.png", abs.."counter_simple_v2.png"})
    UI_ASSETS.icons.sidebar = loadImageHandle({rel.."hp_mp_bars.png", relAlt.."hp_mp_bars.png", abs.."hp_mp_bars.png"})
end

local function loadCanonicalData()
    if CANON.loaded then return end
    CANON.loaded = true

    local items = readJsonFile(API_ASSETS_ROOT .. "\\items.json")
    if type(items) == "table" and type(items.DOTAAbilities) == "table" then
        CANON.items = {}
        for nm, def in pairs(items.DOTAAbilities) do
            if type(nm) == "string" and nm:find("^item_") then
                local c = tonumber((type(def) == "table" and def.ItemCost) or 0) or 0
                local tex = tostring((type(def) == "table" and def.AbilityTextureName) or ""):lower()
                CANON.items[nm] = {
                    cost = c,
                    tags = tostring((type(def) == "table" and def.ItemShopTags) or ""),
                    quality = tostring((type(def) == "table" and def.ItemQuality) or ""),
                    short = mkShortToken(nm, 5),
                    tex = tex ~= "" and tex or nil,
                }
            end
        end
    end

    local abilities = readJsonFile(API_ASSETS_ROOT .. "\\npc_abilities.json")
    if type(abilities) == "table" and type(abilities.DOTAAbilities) == "table" then
        CANON.abilities = {}
        for nm, def in pairs(abilities.DOTAAbilities) do
            if type(nm) == "string" and type(def) == "table" then
                local aType = tostring(def.AbilityType or "")
                local tex = tostring(def.AbilityTextureName or ""):lower()
                local dep = tostring(def.DependentOnAbility or def.LinkedAbility or ""):lower()
                CANON.abilities[nm] = {
                    isUlt = aType:find("ULTIMATE") ~= nil,
                    tex = tex ~= "" and tex or nil,
                    dep = dep ~= "" and dep or nil,
                }
            end
        end
    end
end

local function deriveItemVisual(itemName)
    local cMeta = CANON.items and CANON.items[itemName]
    if not cMeta then return nil end
    local tags = cMeta.tags:lower()
    local cost = cMeta.cost or 0
    local important = cost >= 2200 or tags:find("mobility") or tags:find("support") or tags:find("armor") or tags:find("damage")
    if not important then return nil end
    local c = C.gray
    if tags:find("mobility") or tags:find("teleport") then c = C.yellow
    elseif tags:find("support") or tags:find("heal") then c = C.cyan
    elseif tags:find("damage") then c = C.red
    elseif tags:find("armor") or tags:find("defense") then c = C.green end
    local p = clamp(4 + F(cost / 900), 4, 10)
    return {n=itemName, s=cMeta.short, c=c, p=p}
end

local function resolveItemInfo(itemName, itemLut)
    if itemLut[itemName] then return itemLut[itemName] end
    if DYN_ITEM_CACHE[itemName] ~= nil then
        return DYN_ITEM_CACHE[itemName] or nil
    end
    local info = deriveItemVisual(itemName)
    DYN_ITEM_CACHE[itemName] = info or false
    return info
end

--------------------------------------------------------------------------------
-- DRAW HELPERS
--------------------------------------------------------------------------------
local function dRect(x, y, w, h, c, rnd)
    if w <= 0 or h <= 0 then return end
    pcall(Render.FilledRect, Vec2(F(x), F(y)), Vec2(F(x+w), F(y+h)),
        c or C.bg_panel, rnd or 0, Enum.DrawFlags.RoundCornersAll)
end

local function dBorder(x, y, w, h, c, rnd, t)
    if w <= 0 or h <= 0 then return end
    pcall(Render.Rect, Vec2(F(x), F(y)), Vec2(F(x+w), F(y+h)),
        c or C.border, rnd or 0, Enum.DrawFlags.RoundCornersAll, t or 1)
end

local function dText(sz, txt, x, y, c)
    local fontFloor = math.max(8, tonumber(uiGetVal(ui and ui.ui_font_floor, 9)) or 9)
    local realSz = math.max(fontFloor, F(sz * gScale + 0.5))
    local f = getFont(realSz)
    if not f then return 0 end
    txt = tostring(txt or "")
    if #txt == 0 then return 0 end
    local rtxt = renderTextForFont(txt, f, realSz)
    local tc = c or C.text
    local shadowEnabled = uiGetVal(ui and ui.ui_text_shadow, true)
    local shadowBoost = uiGetVal(ui and ui.ui_high_contrast, false) and 0.95 or 0.75
    local shA = tc.a and F(tc.a * shadowBoost) or (shadowEnabled and 180 or 0)
    if shadowEnabled and shA > 0 then
        pcall(Render.Text, f, realSz, rtxt, Vec2(F(x)+1, F(y)+1), col(0, 0, 0, shA))
        if uiGetVal(ui and ui.ui_high_contrast, false) then
            pcall(Render.Text, f, realSz, rtxt, Vec2(F(x)+1, F(y)), col(0, 0, 0, F(shA * 0.7)))
        end
    end
    pcall(Render.Text, f, realSz, rtxt, Vec2(F(x), F(y)), tc)
    local ok2, r = pcall(Render.TextSize, f, realSz, rtxt)
    return (ok2 and r and r.x) or (realSz * #rtxt * 0.55)
end

local function tW(sz, txt)
    local fontFloor = math.max(8, tonumber(uiGetVal(ui and ui.ui_font_floor, 9)) or 9)
    local realSz = math.max(fontFloor, F(sz * gScale + 0.5))
    local f = getFont(realSz)
    local rawTxt = tostring(txt or "")
    local rtxt = renderTextForFont(rawTxt, f, realSz)
    if f then
        local ok, r = pcall(Render.TextSize, f, realSz, rtxt)
        if ok and r and r.x then return r.x end
    end
    return realSz * #rtxt * 0.55
end

local function dLine(x1, y1, x2, y2, c, t)
    pcall(Render.Line, Vec2(F(x1), F(y1)), Vec2(F(x2), F(y2)), c or C.gray, t or 1)
end

local function dCircle(x, y, r, c, seg)
    pcall(Render.FilledCircle, Vec2(F(x), F(y)), r, c or col(255,255,255,100), nil, nil, seg or 12)
end

local function dImage(handle, x, y, w, h, a, rounding)
    if not handle or handle == 0 then return end
    pcall(Render.Image, handle, Vec2(F(x), F(y)), Vec2(F(w), F(h)), col(255, 255, 255, a or 255), rounding or 0)
end

local function dBar(x, y, w, h, pct, c, bg, rnd)
    pct = clamp(pct or 0, 0, 1); rnd = rnd or sc(2)
    dRect(x, y, w, h, bg or col(0,0,0,120), rnd)
    if pct > 0.005 then
        local fw = math.max(1, F(w * pct))
        dRect(x, y, fw, h, c or C.hp, rnd)
        dRect(x, y, fw, F(h * 0.4), col(255,255,255,20), rnd)
    end
end

function dCard(x, y, w, h, accent, title, titleCol)
    if w <= 2 or h <= 2 then return end
    local rnd = sc(6)
    local hc = accent or C.accent
    dRect(x, y, w, h, col(10, 14, 24, 215), rnd)
    dBorder(x, y, w, h, colA(hc, 80), rnd)
    dRect(x+sc(2), y+sc(2), w-sc(4), sc(2), colA(hc, 140), sc(2))
    if title and title ~= "" then
        dText(8, tostring(title), x+sc(6), y+sc(4), titleCol or hc)
    end
end

function cardContentRect(x, y, w, h, hasTitle)
    local topPad = (hasTitle and sc(18)) or sc(6)
    local pad = sc(6)
    return x + pad, y + topPad, w - pad * 2, h - topPad - pad
end

function drawComboTooltipOverlay()
    local tip = UI_ASSETS and UI_ASSETS.comboTip or nil
    if not tip or not tip.title then return end
    local pad = sc(6)
    local fs1, fs2 = 9, 8
    local l1 = tostring(tip.title or "")
    local l2 = tostring(tip.line2 or "")
    local l3 = tostring(tip.line3 or "")
    local w = math.max(tW(fs1, l1), tW(fs2, l2), (l3 ~= "" and tW(fs2, l3) or 0)) + pad * 2
    local h = sc(28) + (l3 ~= "" and sc(10) or 0)
    local x = F(tip.x or 0)
    local y = F(tip.y or 0)
    if x + w > SW - sc(4) then x = SW - w - sc(4) end
    if y + h > SH - sc(4) then y = SH - h - sc(4) end
    x = math.max(sc(2), x); y = math.max(sc(2), y)
    local ac = tip.col or C.accent
    dRect(x, y, w, h, col(8, 12, 20, 230), sc(5))
    dBorder(x, y, w, h, colA(ac, 120), sc(5))
    dRect(x+sc(1), y+sc(1), sc(2), h-sc(2), colA(ac, 110), sc(3))
    dText(fs1, l1, x + pad, y + sc(4), C.white)
    dText(fs2, l2, x + pad, y + sc(15), C.gray)
    if l3 ~= "" then dText(fs2, l3, x + pad, y + sc(25), C.gray) end
end

local function w2s(v)
    if not v then return nil, nil, false end
    local ok, r = pcall(Render.WorldToScreen, v)
    if ok and r and r.x and r.y then
        local vis = (r.visible == nil) and true or (r.visible == true)
        return r.x, r.y, vis
    end
    return nil, nil, false
end

local function drawCircleW(pos, rad, c, seg)
    if not pos then return end
    seg = seg or 32
    local pts = {}
    for i = 0, seg do
        local a = (i / seg) * 6.2832
        local sx, sy, vis = w2s(Vector(pos.x + math.cos(a) * rad, pos.y + math.sin(a) * rad, pos.z))
        if vis and sx then pts[#pts+1] = {x=sx, y=sy} end
    end
    if #pts < 2 then return end
    for i = 1, #pts - 1 do dLine(pts[i].x, pts[i].y, pts[i+1].x, pts[i+1].y, c) end
end

local function killColor(p)
    if p >= 80 then return C.kill_yes
    elseif p >= 45 then return C.kill_may
    else return C.kill_no end
end

local function dangerColor(p)
    p = clamp(p, 0, 1)
    if p < 0.4 then return col(F(50+400*p), 220, 60, 255)
    else return col(255, F(220-350*(p-0.4)), 60, 255) end
end

local function physMult(a)
    -- Formula correta do Dota 2: armor multiplier
    -- Positivo: reduz dano. Negativo: aumenta dano.
    return 1 - (0.06 * a) / (1 + 0.06 * math.abs(a))
end

local function magMult(mr) return clamp(1 - mr, 0, 2) end

local function drawSep(x, y, w) dLine(x, y, x+w, y, C.separator) end

local function drawStatRow(x, y, w, label, value, valueColor, rh)
    rh = rh or sc(16)
    dText(9, label, x, y, C.stat_label)
    local vw = tW(10, tostring(value))
    dText(10, tostring(value), x+w-vw, y, valueColor or C.stat_value)
    return rh
end

local function fmtTime(seconds)
    if seconds <= 0 then return "0:00" end
    return string.format("%d:%02d", F(seconds/60), F(seconds%60))
end

--------------------------------------------------------------------------------
-- NPC HELPERS
--------------------------------------------------------------------------------
local function nA(n) return n and (sG(Entity.IsAlive, n) == true) end
local function nV(n) return n and (sG(Entity.IsDormant, n) == false) end
local function nP(n) return sG(Entity.GetAbsOrigin, n) end
local function nI(n) return sG(Entity.GetIndex, n) end

local function d2d(a, b)
    if not a or not b then return 99999 end
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
end

local function fN(n)
    n = n or 0
    if math.abs(n) >= 1000 then return string.format("%.1fk", n/1000) end
    return tostring(F(n))
end

local function hName(n)
    if not n then return "?" end
    local nm = (sG(NPC.GetUnitName, n) or ""):gsub("npc_dota_hero_", ""):gsub("_", " ")
    if #nm > 0 then nm = nm:sub(1,1):upper() .. nm:sub(2) end
    return #nm > 10 and nm:sub(1,9) .. "." or nm
end

local function getHeroIconHandle(npc)
    if not npc then return nil end
    local uName = sG(NPC.GetUnitName, npc)
    if type(uName) ~= "string" or uName == "" then return nil end
    if HERO_ICON_CACHE[uName] ~= nil then
        return HERO_ICON_CACHE[uName] or nil
    end
    local short = uName:gsub("^npc_dota_hero_", "")
    local rel1 = "images\\heroes_circle\\" .. short .. ".png"
    local rel2 = "images/heroes_circle/" .. short .. ".png"
    local abs1 = ROOT_DIR .. "\\images\\heroes_circle\\" .. short .. ".png"
    local pano = "panorama/images/heroes/icons/" .. uName .. "_png.vtex_c"
    local h = loadImageHandle({rel1, rel2, abs1, pano})
    HERO_ICON_CACHE[uName] = h or false
    return h
end

function getItemIconHandle(itemName)
    if type(itemName) ~= "string" or itemName == "" then return nil end
    if not CANON.loaded then loadCanonicalData() end
    local key = tostring(itemName):lower()
    UI_ASSETS.itemIcons = UI_ASSETS.itemIcons or {}
    if UI_ASSETS.itemIcons[key] ~= nil then
        return UI_ASSETS.itemIcons[key] or nil
    end
    local short = key:gsub("^item_", "")
    local meta = CANON.items and (CANON.items[key] or CANON.items[itemName])
    local seen, cands = {}, {}
    local function addTextureName(tex)
        if type(tex) ~= "string" or tex == "" then return end
        tex = tex:lower()
        if seen[tex] then return end
        seen[tex] = true
        cands[#cands+1] = "panorama/images/items/" .. tex .. "_png.vtex_c"
        cands[#cands+1] = "panorama/images/items/" .. tex .. ".vtex_c"
    end
    addTextureName(ITEM_ICON_OVERRIDES[key])
    addTextureName(meta and meta.tex or nil)
    addTextureName(short)
    addTextureName(key)
    local h = nil
    for i = 1, #cands do
        local ok, loaded = pcall(Render.LoadImage, cands[i])
        if ok and loaded and loaded ~= 0 then h = loaded; break end
    end
    UI_ASSETS.itemIcons[key] = h or false
    return h
end

function getSpellIconHandle(spellName)
    if type(spellName) ~= "string" or spellName == "" then return nil end
    if not CANON.loaded then loadCanonicalData() end
    local key = tostring(spellName):lower()
    UI_ASSETS.spellIcons = UI_ASSETS.spellIcons or {}
    if UI_ASSETS.spellIcons[key] ~= nil then
        return UI_ASSETS.spellIcons[key] or nil
    end
    local meta = CANON.abilities and (CANON.abilities[key] or CANON.abilities[spellName])
    local seenTex, texKeys = {}, {}
    local function addTexKey(tex)
        if type(tex) ~= "string" or tex == "" then return end
        tex = tex:lower()
        if seenTex[tex] then return end
        seenTex[tex] = true
        texKeys[#texKeys+1] = tex
    end
    addTexKey(ABILITY_ICON_OVERRIDES[key])
    if key:find("persectur", 1, true) then addTexKey(key:gsub("persectur", "persecutor")) end
    addTexKey(meta and meta.tex or nil)
    if meta and meta.dep then
        addTexKey(meta.dep)
        local depMeta = CANON.abilities and CANON.abilities[meta.dep]
        addTexKey(depMeta and depMeta.tex or nil)
    end
    addTexKey(key)

    local cands = {}
    for _, tex in ipairs(texKeys) do
        cands[#cands+1] = "panorama/images/spellicons/" .. tex .. "_png.vtex_c"
        cands[#cands+1] = "panorama/images/spellicons/" .. tex .. ".vtex_c"
    end
    local h = nil
    for i = 1, #cands do
        local ok, loaded = pcall(Render.LoadImage, cands[i])
        if ok and loaded and loaded ~= 0 then h = loaded; break end
    end
    UI_ASSETS.spellIcons[key] = h or false
    return h
end

local function hasItem(n, name)
    if not n then return false, nil end
    local it = sG(NPC.GetItem, n, name, true) or sG(NPC.GetItem, n, name) or sG(NPC.GetItemByName, n, name)
    if not it then
        for i = 0, 16 do
            local byIdx = sG(NPC.GetItemByIndex, n, i)
            if byIdx and (sG(Ability.GetName, byIdx) == name) then
                it = byIdx
                break
            end
        end
    end
    return it ~= nil, it
end

local function getHeroDmg(h) local d = sN(NPC.GetTrueDamage, h); return d > 0 and d or 50 end
local function getAS(h) local a = sN(NPC.GetAttackSpeed, h); return a > 0 and a or 100 end
local function getBAT(h) local b = sN(NPC.GetBaseAttackTime, h); return b > 0 and b or 1.7 end
local function getHeroLevel(h) return math.max(1, sN(NPC.GetCurrentLevel, h)) end
function getArmorBreakdown(h)
    local a = sG(NPC.GetPhysicalArmorValue, h)
    local m = sG(NPC.GetPhysicalArmorMainValue, h)
    local dm = sG(NPC.GetArmorDamageMultiplier, h)
    local hasA = type(a) == "number" and a == a
    local hasM = type(m) == "number" and m == m
    if not hasA and not hasM then return 0, 0, 0 end

    if hasA and not hasM then return a, a, 0 end
    if hasM and not hasA then return m, m, 0 end

    local cands = {
        {total = a,      main = m, bonus = a - m, kind = "a"},
        {total = m,      main = m, bonus = 0,     kind = "m"},
        {total = a + m,  main = m, bonus = a,     kind = "sum"},
    }

    local best = nil
    if type(dm) == "number" and dm == dm and dm > 0 and dm < 3 then
        local bestErr = 999
        for _, c in ipairs(cands) do
            local err = math.abs(physMult(c.total) - dm)
            if err < bestErr then bestErr = err; best = c end
        end
    end
    if not best then
        if math.abs(a - m) > 0.05 then best = cands[3] else best = cands[1] end
    end

    local total = tonumber(best.total) or 0
    local main = tonumber(best.main) or total
    local bonus = tonumber(best.bonus) or (total - main)
    if math.abs((main + bonus) - total) > 0.11 then bonus = total - main end
    return total, main, bonus
end
function getArmorValue(h)
    local total = getArmorBreakdown(h)
    return total or 0
end
local function getMR(h)
    local mr = sG(NPC.GetMagicalArmorValue, h)
    return (mr and type(mr) == "number") and mr or 0.25
end
local function isTower(npc)
    if not npc then return false end
    return ((sG(NPC.GetUnitName, npc) or ""):find("tower") ~= nil)
end

--------------------------------------------------------------------------------
-- ITEMS DATABASE
--------------------------------------------------------------------------------
local ITEMS_DB = {
    {n="item_black_king_bar",s="BKB",c=C.gold,p=10},{n="item_aeon_disk",s="Aeon",c=C.purple,p=9},
    {n="item_sphere",s="Lnk",c=C.cyan,p=9},{n="item_lotus_orb",s="Lotus",c=C.pink,p=8},
    {n="item_manta",s="Manta",c=C.cyan,p=7},{n="item_satanic",s="Sat",c=C.red,p=8},
    {n="item_refresher",s="Refr",c=C.green,p=10},{n="item_sheepstick",s="Hex",c=C.cyan,p=9},
    {n="item_orchid",s="Orch",c=C.pink,p=8},{n="item_bloodthorn",s="BT",c=C.red,p=9},
    {n="item_nullifier",s="Null",c=C.gray,p=8},{n="item_abyssal_blade",s="Abys",c=C.red,p=9},
    {n="item_blink",s="Blnk",c=C.yellow,p=8},{n="item_overwhelming_blink",s="OBl",c=C.red,p=8},
    {n="item_swift_blink",s="SBl",c=C.green,p=8},{n="item_arcane_blink",s="ABl",c=C.purple,p=8},
    {n="item_aegis",s="Aegis",c=C.gold,p=10},{n="item_rapier",s="Rap",c=C.gold,p=10},
    {n="item_dust",s="Dust",c=C.purple,p=5},{n="item_glimmer_cape",s="Glmr",c=C.purple,p=7},
    {n="item_force_staff",s="Force",c=C.cyan,p=7},{n="item_ghost",s="Ghost",c=C.gray,p=6},
    {n="item_pipe",s="Pipe",c=C.green,p=7},{n="item_blade_mail",s="BM",c=C.red,p=6},
    {n="item_shivas_guard",s="Shiva",c=C.cyan,p=7},{n="item_assault",s="AC",c=C.red,p=7},
    {n="item_heart",s="Heart",c=C.red,p=7},{n="item_skadi",s="Skadi",c=C.cyan,p=7},
    {n="item_butterfly",s="Bfly",c=C.green,p=7},{n="item_silver_edge",s="SE",c=C.gray,p=8},
}
local ITEM_LUT = {}
for _, it in ipairs(ITEMS_DB) do ITEM_LUT[it.n] = it end

local BLINK_ITEMS = {
    item_blink = true,
    item_overwhelming_blink = true,
    item_arcane_blink = true,
    item_swift_blink = true,
}

local function hasAnyBlink(npc)
    for itemName, _ in pairs(BLINK_ITEMS) do
        if hasItem(npc, itemName) then return true end
    end
    return false
end

--------------------------------------------------------------------------------
-- ENTITY CACHE
--------------------------------------------------------------------------------
local EC = {
    hero=nil, heroTeam=nil, heroPos=nil, heroAlive=false,
    heroMana=0, heroMaxMana=1, heroHP=0, heroMaxHP=1,
    heroDmg=0, heroLevel=1, heroArmor=0, heroArmorMain=0, heroArmorBonus=0, heroMR=0.25,
    heroAS=100, heroBAT=1.7, heroRange=150, heroMS=300,
    heroName="?",
    allies={}, enemies={}, visEnemies={},
    aliveAllies=0, aliveEnemies=0, deadEnemies=0,
    heroAbilities={}, heroStats={},
    enItems={}, enSpells={},
    allyTowers={}, enemyTowers={},
    currentTarget=nil, targetData={},
    lastFull=0, lastLight=0, valid=false,
}

local function refreshCache(now)
    if now - EC.lastLight < 0.05 then return end
    EC.lastLight = now
    EC.hero = sG(Heroes.GetLocal)
    if not EC.hero then EC.valid = false; return end
    EC.heroAlive = nA(EC.hero)
    EC.heroPos = nP(EC.hero)
    EC.heroTeam = sG(Entity.GetTeamNum, EC.hero)
    EC.heroHP = sN(Entity.GetHealth, EC.hero)
    EC.heroMaxHP = math.max(1, sN(Entity.GetMaxHealth, EC.hero))
    EC.heroMana = sN(NPC.GetMana, EC.hero)
    EC.heroMaxMana = math.max(1, sN(NPC.GetMaxMana, EC.hero))
    EC.heroDmg = getHeroDmg(EC.hero)
    EC.heroLevel = getHeroLevel(EC.hero)
    do
        local at, am, ab = getArmorBreakdown(EC.hero)
        EC.heroArmor = at or 0
        EC.heroArmorMain = am or EC.heroArmor
        EC.heroArmorBonus = ab or (EC.heroArmor - (EC.heroArmorMain or 0))
    end
    EC.heroMR = getMR(EC.hero)
    EC.heroAS = getAS(EC.hero)
    EC.heroBAT = getBAT(EC.hero)
    EC.heroRange = sN(NPC.GetAttackRange, EC.hero)
    EC.heroMS = math.max(200, sN(NPC.GetMoveSpeed, EC.hero))
    EC.heroName = hName(EC.hero)
    if not EC.heroTeam then EC.valid = false; return end
    if not CANON.loaded then loadCanonicalData() end
    EC.valid = true

    EC.currentTarget = sG(Input.GetNearestHeroToCursor, EC.heroTeam == 2 and 3 or 2, 300)

    if now - EC.lastFull < 0.35 then return end
    EC.lastFull = now
    EC.allies, EC.enemies, EC.visEnemies = {}, {}, {}
    EC.aliveAllies, EC.aliveEnemies, EC.deadEnemies = 0, 0, 0
    EC.heroStats, EC.enItems, EC.enSpells = {}, {}, {}
    EC.allyTowers, EC.enemyTowers = {}, {}

    local all = sG(Heroes.GetAll)
    if not all then return end
    for _, h in ipairs(all) do
        local t = sG(Entity.GetTeamNum, h)
        if not t or sG(NPC.IsIllusion, h) then goto cH end
        local alive = nA(h)
        local idx = nI(h)
        if idx then
            EC.heroStats[idx] = {
                hp=sN(Entity.GetHealth,h), maxHp=math.max(1,sN(Entity.GetMaxHealth,h)),
                mana=sN(NPC.GetMana,h), maxMana=math.max(1,sN(NPC.GetMaxMana,h)),
                armor=getArmorValue(h), mr=getMR(h),
                dmg=getHeroDmg(h), as=getAS(h), bat=getBAT(h),
                range=sN(NPC.GetAttackRange,h), ms=math.max(200,sN(NPC.GetMoveSpeed,h)),
                level=getHeroLevel(h), alive=alive, visible=nV(h), pos=nP(h), name=hName(h),
            }
        end
        if t == EC.heroTeam then
            if alive then EC.allies[#EC.allies+1] = h; EC.aliveAllies = EC.aliveAllies + 1 end
        else
            EC.enemies[#EC.enemies+1] = h
            if idx then
                EC.enItems[idx] = {}
                for slot = 0, 8 do
                    local item = sG(NPC.GetItemByIndex, h, slot)
                    if item then
                        local iN = sG(Ability.GetName, item) or ""
                        local info = resolveItemInfo(iN, ITEM_LUT)
                        if info then
                            local cd = sN(Ability.GetCooldown, item)
                            EC.enItems[idx][#EC.enItems[idx]+1] = {n=iN,s=info.s,c=info.c,p=info.p,cd=cd,rdy=(cd<=0)}
                        end
                    end
                end
                table.sort(EC.enItems[idx], function(a,b) return a.p > b.p end)
                EC.enSpells[idx] = {}
                for i = 0, 5 do
                    local ab = sG(NPC.GetAbilityByIndex, h, i)
                    if ab then
                        local nm = sG(Ability.GetName, ab) or ""
                        local lv = sN(Ability.GetLevel, ab)
                        if lv > 0 and not nm:find("generic_hidden") and not nm:find("special_bonus") then
                            local cd = sN(Ability.GetCooldown, ab)
                            local meta = CANON.abilities and CANON.abilities[nm]
                            EC.enSpells[idx][#EC.enSpells[idx]+1] = {
                                n=nm, s=mkShortToken(nm, 5), cd=cd, rdy=(cd<=0), ult=(meta and meta.isUlt) or (i>=3),
                            }
                        end
                    end
                end
            end
            if alive then
                EC.aliveEnemies = EC.aliveEnemies + 1
                if nV(h) then EC.visEnemies[#EC.visEnemies+1] = h end
            else EC.deadEnemies = EC.deadEnemies + 1 end
        end
        ::cH::
    end

    local allNPCs = sG(NPCs.GetAll)
    if allNPCs then
        for _, npc in ipairs(allNPCs) do
            if isTower(npc) and nA(npc) then
                local tt = sG(Entity.GetTeamNum, npc)
                local tp = nP(npc)
                if tt and tp then
                    if tt == EC.heroTeam then EC.allyTowers[#EC.allyTowers+1] = {npc=npc,pos=tp}
                    else EC.enemyTowers[#EC.enemyTowers+1] = {npc=npc,pos=tp} end
                end
            end
        end
    end

    if EC.heroAlive then
        EC.heroAbilities = {}
        for i = 0, 23 do
            local ab = sG(NPC.GetAbilityByIndex, EC.hero, i)
            if not ab then goto cA end
            local nm = sG(Ability.GetName, ab) or ""
            local lv = sN(Ability.GetLevel, ab)
            if lv <= 0 or nm:find("generic_hidden") or nm:find("special_bonus") then goto cA end
            if sG(Ability.IsPassive, ab) == true then goto cA end
            local specDmg = math.max(
                sN(Ability.GetSpecialValueFor,ab,"damage"),
                sN(Ability.GetSpecialValueFor,ab,"strike_damage"),
                sN(Ability.GetSpecialValueFor,ab,"bonus_damage"),
                sN(Ability.GetSpecialValueFor,ab,"base_damage"),
                sN(Ability.GetSpecialValueFor,ab,"total_damage"))
            EC.heroAbilities[#EC.heroAbilities+1] = {
                cd=sN(Ability.GetCooldown,ab), manaCost=sN(Ability.GetManaCost,ab),
                damage=math.max(sN(Ability.GetDamage,ab),specDmg),
                ready=sG(Ability.IsReady,ab) or false,
                castPoint=sN(Ability.GetCastPoint,ab),
                short=nm:gsub(".*_",""):sub(1,6), name=nm, level=lv,
            }
            ::cA::
        end
    end

    if EC.currentTarget and nA(EC.currentTarget) then
        local tIdx = nI(EC.currentTarget)
        EC.targetData = {
            valid=true, name=hName(EC.currentTarget),
            hp=sN(Entity.GetHealth,EC.currentTarget),
            maxHp=math.max(1,sN(Entity.GetMaxHealth,EC.currentTarget)),
            mana=sN(NPC.GetMana,EC.currentTarget),
            maxMana=math.max(1,sN(NPC.GetMaxMana,EC.currentTarget)),
            armor=getArmorValue(EC.currentTarget),
            mr=getMR(EC.currentTarget),
            dmg=getHeroDmg(EC.currentTarget),
            ms=math.max(200,sN(NPC.GetMoveSpeed,EC.currentTarget)),
            level=getHeroLevel(EC.currentTarget),
            items=tIdx and EC.enItems[tIdx] or {},
            spells=tIdx and EC.enSpells[tIdx] or {},
        }
    else EC.targetData = {valid=false} end
end

--------------------------------------------------------------------------------
-- KILL CALCULATOR
--------------------------------------------------------------------------------
local function calcKill(attacker, target)
    if not attacker or not target or not nA(attacker) or not nA(target) then return nil end
    local aI, tI = nI(attacker), nI(target)
    local aS, tS = aI and EC.heroStats[aI], tI and EC.heroStats[tI]
    if not aS or not tS then return nil end
    local pm = physMult(tS.armor)
    local physPerHit = aS.dmg * pm
    local aps = aS.as / math.max(0.01, (aS.bat * 100))
    local secPerAtk = sN(NPC.GetSecondsPerAttack, attacker)
    if secPerAtk <= 0 then
        secPerAtk = aps > 0 and (1 / aps) or 1.7
    end
    secPerAtk = clamp(secPerAtk, 0.18, 3.0)
    local atkDps = physPerHit / secPerAtk
    local htk = physPerHit > 0 and math.ceil(tS.hp / math.max(1, physPerHit)) or 999

    local totalMag, totalMana, allReady = 0, 0, true
    local shortMag, shortMana = 0, 0
    local castSpend = 0
    local spellCount, readyCount = 0, 0
    local targetPos = nP(target)
    local faceT = targetPos and clamp(sN(NPC.GetTimeToFacePosition, attacker, targetPos), 0, 0.65) or 0
    local magImm = (sG(NPC.IsMagicImmune, target) == true) or (sG(NPC.HasState, target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) == true)
    local linkens = sG(NPC.IsLinkensProtected, target) == true
    local lotus = sG(NPC.IsLotusProtected, target) == true
    local bkbReady = hasItem(target, "item_black_king_bar")
    local linkerBroken = false
    local linkerNeedBreaker = false
    local reflectedRisk = false

    for i = 0, 20 do
        local ab = sG(NPC.GetAbilityByIndex, attacker, i)
        if not ab then goto cKA end
        local lv = sN(Ability.GetLevel, ab); if lv <= 0 then goto cKA end
        local nm = sG(Ability.GetName, ab) or ""
        if nm:find("generic_hidden") or nm:find("special_bonus") then goto cKA end
        if sG(Ability.IsPassive, ab) == true then goto cKA end
        local abDmg = math.max(
            sN(Ability.GetAbilityDamage, ab),
            sN(Ability.GetDamage, ab),
            sN(Ability.GetSpecialValueFor,ab,"damage"),
            sN(Ability.GetSpecialValueFor,ab,"strike_damage"),
            sN(Ability.GetSpecialValueFor,ab,"bonus_damage")
        )
        local cp = clamp(sN(Ability.GetCastPoint, ab), 0, 2.5)
        local mc = math.max(0, sN(Ability.GetManaCost, ab))
        local ready = (sG(Ability.IsReady, ab) == true)
        local castable = (sG(Ability.IsCastable, ab, aS.mana) == true) or ready
        local beh = sN(Ability.GetBehavior, ab)
        local cr = math.max(sN(Ability.GetEffectiveCastRange, ab), sN(Ability.GetCastRange, ab))
        local aoe = sN(Ability.GetAOERadius, ab)
        local targetLike = (beh ~= 0 and cr > 0 and aoe <= 0 and not nm:find("blink") and not nm:find("hookshot"))
        local breaker = nm:find("force_staff") or nm:find("hurricane_pike") or nm:find("cyclone") or nm:find("nullifier")
            or nm:find("orchid") or nm:find("bloodthorn") or nm:find("dagon")

        if ready and castable then readyCount = readyCount + 1 else allReady = false end
        if abDmg > 0 then spellCount = spellCount + 1 end
        totalMana = totalMana + mc

        if linkens and targetLike and not linkerBroken then
            if breaker then
                linkerBroken = true
                castSpend = castSpend + cp + 0.05
            else
                linkerNeedBreaker = true
            end
            goto cKA
        end
        if lotus and targetLike and not nm:find("item_") then
            reflectedRisk = true
        end

        if abDmg <= 0 or not (ready and castable) then goto cKA end
        local dmg = abDmg
        if magImm then
            dmg = dmg * 0.05
        else
            dmg = dmg * magMult(tS.mr)
            if bkbReady then
                -- BKB ativo bloqueia 100% de dano magico. Estimar ~60% chance de usar.
                dmg = dmg * 0.4
            end
        end
        totalMag = totalMag + dmg
        local tCast = faceT + castSpend + cp
        if tCast <= 2.6 then
            shortMag = shortMag + dmg
            shortMana = shortMana + mc
        end
        castSpend = castSpend + cp + 0.05
        ::cKA::
    end

    local shortWindow = 2.6
    local fullWindow = 6.0
    local shortPhys = atkDps * math.max(0, shortWindow - math.min(shortWindow, faceT + castSpend * 0.4))
    local fullPhys = atkDps * math.max(0, fullWindow - math.min(fullWindow, faceT + castSpend * 0.35))
    local shortDmg = shortMag + shortPhys
    local rawDmg = totalMag + fullPhys
    local comboTime = faceT + castSpend
    local timeToKill = atkDps > 0 and (tS.hp / math.max(1, atkDps + (totalMag / math.max(1.25, comboTime + 1.0)))) or 99

    local chance = 0
    if tS.hp > 0 then
        local r = rawDmg / tS.hp
        local rShort = shortDmg / tS.hp
        if r >= 3 then chance = 99 elseif r >= 2 then chance = 95 elseif r >= 1.5 then chance = 90
        elseif r >= 1.1 then chance = 78 elseif r >= 0.85 then chance = 55 elseif r >= 0.5 then chance = 30
        else chance = 10 end
        if rShort >= 1.0 then chance = math.min(99, chance + 14)
        elseif rShort < 0.45 then chance = chance - 10 end
        if totalMana > aS.mana then chance = F(chance * 0.5) end
        if not allReady then chance = F(chance * 0.7) end
        if linkens and linkerNeedBreaker and not linkerBroken then chance = chance - 22 end
        if lotus and reflectedRisk then chance = chance - 10 end
        if bkbReady and not magImm and totalMag > fullPhys then chance = chance - 12 end
        if tS.hp / tS.maxHp < 0.3 then chance = math.min(99, chance + 20) end
        if comboTime > 2.8 then chance = chance - F((comboTime - 2.8) * 6) end
    end
    local flags = {}
    if linkens then flags[#flags+1] = "Linken" end
    if lotus then flags[#flags+1] = "Lotus" end
    if bkbReady then flags[#flags+1] = "BKB?" end
    if magImm then flags[#flags+1] = "Immune" end
    return {
        killChance=clamp(F(chance),0,99),
        totalDmg=F(rawDmg),
        shortDmg=F(shortDmg),
        physPerHit=F(physPerHit),
        hitsToKill=htk,
        targetHP=tS.hp, targetMaxHP=tS.maxHp,
        spellCount=spellCount, readySpells=readyCount,
        comboTime=comboTime, timeToKill=timeToKill,
        shortWindow=shortWindow, fullWindow=fullWindow,
        linken=linkens, lotus=lotus, bkbRisk=bkbReady, magicImmune=magImm,
        flags=(#flags > 0) and table.concat(flags, "/") or "",
    }
end

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local KM = {data={}, rev={}, t=0}
local DB = {gpm=0,nw=0,momentum=0,winProb=50,allyPow=0,enemyPow=0,
    tips={},lastTip=0,mia={},init=false,startNW=0,startTime=0,t=0}
local PG = {ally={}, enemy={}, t=0}
local INI = {bestPos=nil, bestScore=0, count=0, radius=450, risk=0, follow=0, travel=0, label="", t=0}
local FLASH = {on=false, t=0, who=""}
local SMOKE = {on=false, t=0}
local GANK = {on=false, t=0, cnt=0}
local LINKEN = {}
local LH = {targets={}, t=0}
local DOD = {txt="", t=0}
local prevAlive = {}
local AUTO = {phase=0, stick=0, faerie=0}
local ui
local CORE = {lastTick=-1, lastHeavy=0, lastFast=0}
local ACTQ = {q={}, seq=0, stats={queued=0, ran=0, dropped=0, dedup=0}, lastRun=0, lastDesc=""}
local GUARD = {lastBlockTime=0, lastBlockReason="", blocks=0, rewrites=0}
local THREAT = {
    events = {},
    byParticle = {},
    byLinear = {},
    cd = {},
    stats = {created=0, expired=0, blockedOrders=0, pings=0},
    nearScore = 0,
    lastAlert = "",
    lastAlertTime = 0,
    lastPingTime = 0,
    t = 0,
}

-- Farm Dashboard state
local FARM = {
    gpm=0, xpm=0, peakGPM=0, csMin=0, lastCS=0,
    deadT=0, aliveT=0, lastAC=0, eff=1,
    goldHist={}, t=0,
}

-- Map Control state
local MAP = {
    safeFarm = {},
    splitAdvice = "",
    rune = {state="", pos=nil, etaUs=0, etaEnemy=0},
    rosh = {suspicion=0, reason=""},
    rotations = {},
    forwardRisk = 0,
    t = 0,
}

-- Farm spot definitions by team (2=Radiant, 3=Dire)
local FARM_SPOTS_BY_TEAM = {
    [2] = {
        {n="Safe Jng", p=Vector(-4100,-4200,0)},
        {n="Triangle", p=Vector(-5000,-3900,0)},
        {n="Ancients", p=Vector(-4500,900,0)},
        {n="Off Jng",  p=Vector(3600,3600,0)},
        {n="Top",      p=Vector(-6000,5000,0)},
        {n="Bot",      p=Vector(6000,-5000,0)},
        {n="Mid",      p=Vector(0,0,0)},
    },
    [3] = {
        {n="Safe Jng", p=Vector(4100,4200,0)},
        {n="Triangle", p=Vector(5000,3900,0)},
        {n="Ancients", p=Vector(4500,-900,0)},
        {n="Off Jng",  p=Vector(-3600,-3600,0)},
        {n="Top",      p=Vector(-6000,5000,0)},
        {n="Bot",      p=Vector(6000,-5000,0)},
        {n="Mid",      p=Vector(0,0,0)},
    },
}

local function getFarmSpots()
    return FARM_SPOTS_BY_TEAM[EC.heroTeam] or FARM_SPOTS_BY_TEAM[2]
end

-- Tempo Coach state (hybrid: reactive + message log)
local TEMPO = {
    current_advice = "",
    prev_advice = "",
    current_score = 0,
    advice_start_time = 0,
    last_update_time = 0,
    confidence = 0,
    sub_reason = "",
    sub_reason2 = "",
    fade_alpha = 0,
    top_choices = {},
    snapshot = {},
    -- Message log (from v3 Tempo)
    messages = {},
    notified = {},
    lastDeathCheck = 0,
    prevAliveState = {},
}
local PSY = {
    enemies = {},
    top = {name="", intent="", conf=0, pos=nil},
    team = {gank=0, push=0, farm=0, retreat=0, rosh=0, rotate=0},
    pressure = {hero=0, map=0, rosh=0},
    t = 0,
}

function psychoEnemyState(h)
    local idx = h and nI(h)
    if not idx then return nil, nil end
    local st = PSY.enemies[idx]
    if not st then
        st = {
            idx = idx,
            name = hName(h),
            pos = nil, lastPos = nil, predPos = nil,
            vel = {x=0,y=0,z=0,speed=0},
            lastSeen = 0, lastSample = 0, missTime = 0,
            intent = "UNKNOWN", conf = 0,
            aggro = 0, retreat = 0, farm = 0, push = 0, rosh = 0, rotate = 0,
            towardHero = 0, laneSide = 0,
        }
        PSY.enemies[idx] = st
    end
    return st, idx
end

function psychoClampPos(p)
    if not p then return nil end
    if sG(GridNav.IsTraversable, p) ~= false then return p end
    return sG(GridNav.GetNearestSafePosition, p) or p
end

function getRoshanPosition()
    local allN = sG(NPCs.GetAll)
    if not allN then return nil end
    for _, npc in ipairs(allN) do
        if npc and nA(npc) and (sG(NPC.IsRoshan, npc) == true) then
            return nP(npc)
        end
    end
    return nil
end

function nearestTowerDist(pos, towerList)
    local best = 99999
    for _, tw in ipairs(towerList or {}) do
        local tp = tw and tw.pos or nil
        if tp then
            local d = d2d(pos, tp)
            if d < best then best = d end
        end
    end
    return best
end

function detectHeroRoleTag(heroName)
    local n = tostring(heroName or ""):lower()
    if n == "" then return "core" end
    if n:find("crystal_maiden") or n:find("lich") or n:find("shadow_shaman") or n:find("witch_doctor")
        or n:find("jakiro") or n:find("oracle") or n:find("dazzle") or n:find("disruptor")
        or n:find("warlock") or n:find("bane") or n:find("omniknight") or n:find("winter_wyvern")
        or n:find("io") or n:find("treant") or n:find("grimstroke") then
        return "support"
    end
    if n:find("axe") or n:find("centaur") or n:find("mars") or n:find("tidehunter") or n:find("slardar")
        or n:find("primal_beast") or n:find("dawnbreaker") or n:find("sand_king") or n:find("magnataur")
        or n:find("earthshaker") or n:find("legion_commander") or n:find("enigma") or n:find("beastmaster")
        or n:find("clockwerk") or n:find("spirit_breaker") then
        return "initiator"
    end
    if n:find("storm_spirit") or n:find("ember_spirit") or n:find("void_spirit") or n:find("queenofpain")
        or n:find("invoker") or n:find("templar_assassin") or n:find("puck") or n:find("shadow_fiend")
        or n:find("outworld_destroyer") or n:find("zeus") or n:find("sniper") or n:find("kunkka")
        or n:find("tinker") then
        return "mid"
    end
    return "carry"
end

function heroSpikeSnapshot(h)
    if not h or not nA(h) then return {score=0, label="", ult=false, blink=false, bkb=false} end
    local score = 0
    local ultReady = false
    local ultCD = 999
    for i = 0, 23 do
        local ab = sG(NPC.GetAbilityByIndex, h, i)
        if ab then
            local lv = sN(Ability.GetLevel, ab)
            if lv > 0 then
                local nm = sG(Ability.GetName, ab) or ""
                if not nm:find("special_bonus") and not nm:find("generic_hidden") then
                    local isUlt = (sG(Ability.IsUltimate, ab) == true) or (i >= 3 and i <= 5)
                    if isUlt then
                        local cd = sN(Ability.GetCooldown, ab)
                        if cd < ultCD then ultCD = cd end
                        if (sG(Ability.IsReady, ab) == true) then ultReady = true end
                    end
                end
            end
        end
    end
    local hasBlink = hasAnyBlink(h)
    local hasBkb = hasItem(h, "item_black_king_bar")
    if ultReady then score = score + 28 end
    if hasBlink then score = score + 18 end
    if hasBkb then score = score + 20 end
    if sN(NPC.GetCurrentLevel, h) >= 12 then score = score + 8 end
    local label = ""
    if score >= 50 then
        label = (hasBlink and "blink " or "") .. (ultReady and "ult " or "") .. (hasBkb and "bkb" or "")
    elseif ultCD > 0 and ultCD < 25 then
        label = "ult "..F(ultCD).."s"
    end
    return {score=score, label=label, ult=ultReady, blink=hasBlink, bkb=hasBkb, ultCD=ultCD}
end

function psychoPredictEnemy(st, h, now)
    if not st then return nil end
    local base = st.pos or st.lastPos or (h and (sG(Hero and Hero.GetLastMaphackPos or nil, h) or nP(h))) or nil
    if not base then return nil end
    local miss = math.max(0, now - (st.lastSeen or 0))
    local lead = st.visible and 0.8 or clamp(miss, 0.6, 2.4)
    local spd = clamp((st.vel and st.vel.speed) or sN(NPC.GetMoveSpeed, h), 180, 650)
    local vx = (st.vel and st.vel.x or 0)
    local vy = (st.vel and st.vel.y or 0)
    local mag = math.sqrt(vx*vx + vy*vy)
    local px, py = base.x, base.y
    if mag > 1 then
        local lim = spd * lead
        px = px + vx / mag * lim
        py = py + vy / mag * lim
    end
    return psychoClampPos(Vector(px, py, base.z or 0))
end

function updPsycho(now)
    if not EC.valid or now - (PSY.t or 0) < 0.45 then return end
    PSY.t = now
    PSY.team = {gank=0, push=0, farm=0, retreat=0, rosh=0, rotate=0}
    PSY.pressure = {hero=0, map=0, rosh=0}
    PSY.top = {name="", intent="", conf=0, pos=nil}
    local roshPos = getRoshanPosition()
    local heroRole = detectHeroRoleTag(EC.heroName)

    for _, h in ipairs(EC.enemies or {}) do
        local st, idx = psychoEnemyState(h)
        if st and idx then
            st.name = hName(h)
            st.alive = nA(h)
            st.visible = st.alive and nV(h) or false
            local nowPos = nil
            if st.visible then
                nowPos = nP(h)
                st.lastSeen = now
            else
                nowPos = sG(Hero and Hero.GetLastMaphackPos or nil, h) or (DB.mia[idx] and DB.mia[idx].lastPos) or st.pos or st.lastPos
            end

            if st.visible and nowPos then
                local dt = now - (st.lastSample or 0)
                if st.pos and dt > 0.03 and dt < 2.0 then
                    local dx = nowPos.x - st.pos.x
                    local dy = nowPos.y - st.pos.y
                    local dz = (nowPos.z or 0) - (st.pos.z or 0)
                    local spd = math.sqrt(dx*dx + dy*dy) / math.max(dt, 0.01)
                    st.vel = {x=dx/math.max(dt,0.01), y=dy/math.max(dt,0.01), z=dz/math.max(dt,0.01), speed=spd}
                end
                st.lastPos = st.pos
                st.pos = nowPos
                st.lastSample = now
            elseif nowPos and not st.pos then
                st.pos = nowPos
                st.lastSample = now
            end

            st.missTime = st.visible and 0 or math.max(0, now - (st.lastSeen or 0))
            st.predPos = psychoPredictEnemy(st, h, now)

            local hpPct = (sN(Entity.GetMaxHealth, h) > 0) and (sN(Entity.GetHealth, h) / math.max(1, sN(Entity.GetMaxHealth, h)) * 100) or 100
            local ep = st.pos or st.predPos
            local conf = 25
            local intent = "UNKNOWN"
            local towardHero = 0
            local dHero = 99999
            if ep and EC.heroPos then
                dHero = d2d(ep, EC.heroPos)
                if st.lastPos then towardHero = d2d(st.lastPos, EC.heroPos) - dHero end
            end
            st.towardHero = towardHero

            if not st.alive then
                intent, conf = "DEAD", 100
            elseif not ep then
                intent, conf = "UNKNOWN", 0
            else
                local enemyPack = countNPCsNear(ep, 1200, "enemy", true, false) - 1
                local allyPack = countNPCsNear(ep, 1200, "ally", true, false)
                local creepPack = countNPCsNear(ep, 900, "enemy", false, true) + countNPCsNear(ep, 900, "ally", false, true)
                local nearOurTower = nearestTowerDist(ep, EC.allyTowers) < 1000
                local nearRosh = roshPos and d2d(ep, roshPos) < 1700
                local recentPain = clamp(sN(Hero and Hero.GetRecentDamage or nil, h) / 250, 0, 40)

                if hpPct <= 35 or recentPain > 12 then
                    if dHero > 1400 or towardHero < -50 then
                        intent, conf = "RETREAT", clamp(65 + F((35 - hpPct) * 1.1) + F(recentPain), 35, 95)
                    end
                end
                if intent == "UNKNOWN" and st.visible and nearOurTower and enemyPack >= 1 then
                    intent, conf = "PUSH", clamp(52 + enemyPack * 12 + (allyPack <= enemyPack and 8 or 0), 30, 92)
                end
                if intent == "UNKNOWN" and st.visible and dHero < 2200 and towardHero > 50 and enemyPack >= allyPack then
                    intent, conf = "GANK", clamp(50 + F(towardHero / 40) + (enemyPack - allyPack) * 10, 30, 96)
                end
                if intent == "UNKNOWN" and nearRosh and (enemyPack >= 2 or (not st.visible and st.missTime > 4)) then
                    intent, conf = "ROSH", clamp(45 + enemyPack * 12 + F(st.missTime * 3), 25, 90)
                end
                if intent == "UNKNOWN" and st.visible and creepPack >= 4 and dHero > 1400 then
                    intent, conf = "FARM", clamp(42 + math.min(24, creepPack * 3), 25, 85)
                end
                if intent == "UNKNOWN" and not st.visible and st.missTime >= 5 then
                    intent, conf = "ROTATE", clamp(34 + F(st.missTime * 2.2) + (heroRole=="mid" and 6 or 0), 20, 88)
                end
                if intent == "UNKNOWN" then
                    if st.visible and dHero < 1800 and towardHero > 15 then
                        intent, conf = "PRESSURE", clamp(30 + F(towardHero / 50), 20, 75)
                    elseif st.visible then
                        intent, conf = "FARM", 28
                    else
                        intent, conf = "ROTATE", clamp(20 + F(st.missTime * 1.6), 10, 70)
                    end
                end
            end

            st.intent = intent
            st.conf = conf

            if intent == "GANK" or intent == "PRESSURE" then
                PSY.team.gank = PSY.team.gank + 1
                PSY.pressure.hero = PSY.pressure.hero + conf * (dHero < 2600 and 1 or 0.35)
            elseif intent == "PUSH" then
                PSY.team.push = PSY.team.push + 1
                PSY.pressure.map = PSY.pressure.map + conf * 0.75
            elseif intent == "FARM" then
                PSY.team.farm = PSY.team.farm + 1
            elseif intent == "RETREAT" then
                PSY.team.retreat = PSY.team.retreat + 1
            elseif intent == "ROSH" then
                PSY.team.rosh = PSY.team.rosh + 1
                PSY.pressure.rosh = PSY.pressure.rosh + conf
            elseif intent == "ROTATE" then
                PSY.team.rotate = PSY.team.rotate + 1
                PSY.pressure.map = PSY.pressure.map + conf * 0.55
            end

            local topWeight = conf + ((intent == "GANK" or intent == "ROSH" or intent == "PUSH") and 12 or 0)
            if topWeight > (PSY.top.conf or 0) then
                PSY.top = {name=st.name or "?", intent=intent, conf=F(topWeight), pos=st.predPos or st.pos}
            end
        end
    end
end

function getRuneObjective(now)
    local out = {state="", pos=nil, etaUs=0, etaEnemy=0}
    if not EC.heroPos or not EC.heroAlive or type(Runes) ~= "table" or type(Runes.GetAll) ~= "function" then return out end
    local runes = sG(Runes.GetAll)
    if not runes or #runes == 0 then return out end
    local bestScore = -99999
    for _, r in ipairs(runes) do
        local rp = sG(Entity.GetAbsOrigin, r) or sG(Rune and Rune.GetAbsOrigin or nil, r)
        if rp then
            local pUs = sN(GridNav.FindPathLength, EC.heroPos, rp)
            if pUs <= 0 then pUs = d2d(EC.heroPos, rp) end
            local etaUs = pUs / math.max(280, EC.heroMS or 300)
            local etaEnemy = 99
            for _, e in ipairs(EC.enemies or {}) do
                local idx = nI(e)
                local st = idx and PSY.enemies[idx] or nil
                local ep = (st and (st.predPos or st.pos)) or nP(e)
                if ep and nA(e) then
                    local pEn = sN(GridNav.FindPathLength, ep, rp)
                    if pEn <= 0 then pEn = d2d(ep, rp) end
                    local ms = math.max(280, sN(NPC.GetMoveSpeed, e))
                    if not nV(e) and st and st.conf then
                        ms = ms * clamp(0.8 + st.conf / 180, 0.8, 1.25)
                    end
                    local eta = pEn / ms
                    if eta < etaEnemy then etaEnemy = eta end
                end
            end
            local score = (20 - etaUs) * 4 + (etaEnemy - etaUs) * 10
            if score > bestScore then
                bestScore = score
                out.pos = rp
                out.etaUs = etaUs
                out.etaEnemy = etaEnemy < 98 and etaEnemy or 0
            end
        end
    end
    if not out.pos then return out end
    local diff = (out.etaEnemy > 0) and (out.etaEnemy - out.etaUs) or 8
    if out.etaUs <= 10 and diff >= 2.5 then out.state = "FREE"
    elseif out.etaUs <= 12 and diff > -1.0 then out.state = "CONTEST"
    elseif out.etaUs <= 15 then out.state = "DANGER"
    else out.state = "IGNORE" end
    return out
end

local function gameNow()
    local t = sN(GameRules.GetGameTime)
    if t > 0 then return t end
    return sN(GlobalVars.GetCurrentTime)
end

local function gameTick()
    local t = sN(GlobalVars.GetTickCount)
    if t > 0 then return t end
    return F(gameNow() * 30)
end

local function latencySec()
    local l = sN(NetChannel.GetLatency, Enum.Flow.OUT)
    if l <= 0 then l = sN(Engine.GetWorkingLatency) end
    if l <= 0 then l = sN(Engine.GetNetworkLatency) end
    return clamp(l, 0, 1.0)
end

local function canUseHumanizer()
    return type(Humanizer) == "table" and type(Humanizer.IsReady) == "function"
end

local function humanizerReady()
    local ok = sG(Humanizer.IsReady)
    return ok == nil and true or ok == true
end

local function humanizerNudge(minS, maxS)
    if not canUseHumanizer() then return end
    if type(Humanizer.TrySleep) == "function" then
        pcall(Humanizer.TrySleep, minS or 0.03, maxS or 0.08)
    elseif type(Humanizer.Sleep) == "function" then
        pcall(Humanizer.Sleep, minS or 0.04)
    end
end

local function queueAction(key, pri, ttl, desc, fn)
    if type(fn) ~= "function" then return false end
    local now = gameNow()
    for i = #ACTQ.q, 1, -1 do
        local a = ACTQ.q[i]
        if not a or (a.expire and now > a.expire) then
            table.remove(ACTQ.q, i)
            ACTQ.stats.dropped = ACTQ.stats.dropped + 1
        elseif key and a.key == key then
            if (pri or 0) > (a.pri or 0) then
                a.pri = pri or a.pri
                a.fn = fn
                a.expire = now + (ttl or 0.25)
                a.desc = desc or a.desc
            end
            ACTQ.stats.dedup = ACTQ.stats.dedup + 1
            return false
        end
    end
    ACTQ.seq = ACTQ.seq + 1
    ACTQ.q[#ACTQ.q+1] = {
        id = ACTQ.seq,
        key = key,
        pri = pri or 0,
        desc = desc or "",
        fn = fn,
        created = now,
        expire = now + (ttl or 0.25),
    }
    ACTQ.stats.queued = ACTQ.stats.queued + 1
    table.sort(ACTQ.q, function(a, b)
        if a.pri ~= b.pri then return a.pri > b.pri end
        return (a.id or 0) < (b.id or 0)
    end)
    return true
end

local function flushActionQueue(now)
    now = now or gameNow()
    if #ACTQ.q == 0 then return end
    for i = #ACTQ.q, 1, -1 do
        local a = ACTQ.q[i]
        if not a or now > (a.expire or now) then
            table.remove(ACTQ.q, i)
            ACTQ.stats.dropped = ACTQ.stats.dropped + 1
        end
    end
    if #ACTQ.q == 0 then return end
    if not (ui and ui.core_human and ui.core_human:Get() == false) then
        if not humanizerReady() then return end
    end
    local a = table.remove(ACTQ.q, 1)
    if not a then return end
    local ok = false
    ok = pcall(a.fn)
    if ok then
        ACTQ.stats.ran = ACTQ.stats.ran + 1
        ACTQ.lastRun = now
        ACTQ.lastDesc = a.desc or ""
        humanizerNudge(0.02, 0.07 + latencySec() * 0.25)
    else
        ACTQ.stats.dropped = ACTQ.stats.dropped + 1
    end
end

local function addThreatEvent(kind, key, pos, radius, severity, ttl, text, color, extra)
    if not pos then return nil end
    local now = gameNow()
    local ev = {
        kind = kind or "generic",
        key = key,
        pos = Vector(pos.x, pos.y, pos.z or 0),
        radius = radius or 250,
        severity = clamp(severity or 20, 1, 100),
        created = now,
        expire = now + (ttl or 1.0),
        text = text or kind or "threat",
        color = color or C.red,
    }
    if type(extra) == "table" then
        for k, v in pairs(extra) do ev[k] = v end
    end
    if key then
        for i = #THREAT.events, 1, -1 do
            local e = THREAT.events[i]
            if e and e.key == key then
                THREAT.events[i] = ev
                return ev
            end
        end
    end
    THREAT.events[#THREAT.events+1] = ev
    THREAT.stats.created = THREAT.stats.created + 1
    if ev.severity >= 55 then
        THREAT.lastAlert = ev.text
        THREAT.lastAlertTime = now
    end
    return ev
end

local function removeThreatEvent(key)
    if not key then return end
    for i = #THREAT.events, 1, -1 do
        local ev = THREAT.events[i]
        if ev and ev.key == key then
            table.remove(THREAT.events, i)
        end
    end
end

local function threatThrottle(key, delay)
    local now = gameNow()
    local t = THREAT.cd[key] or 0
    if now < t then return false end
    THREAT.cd[key] = now + (delay or 0.5)
    return true
end

local function guardBlock(reason, pos)
    local now = gameNow()
    GUARD.lastBlockTime = now
    GUARD.lastBlockReason = tostring(reason or "Blocked order")
    GUARD.blocks = GUARD.blocks + 1
    THREAT.stats.blockedOrders = (THREAT.stats.blockedOrders or 0) + 1
    THREAT.lastAlert = GUARD.lastBlockReason
    THREAT.lastAlertTime = now
    if pos then
        addThreatEvent("guard", "guard:"..F(now*10), pos, 220, 65, 0.8, GUARD.lastBlockReason, C.orange)
    end
end

local function threatDangerAtPos(pos)
    if not pos then return 0 end
    local now = gameNow()
    local score = 0
    for _, ev in ipairs(THREAT.events) do
        if ev and now <= (ev.expire or 0) and ev.pos then
            local d = d2d(pos, ev.pos)
            local r = math.max(80, ev.radius or 250)
            if d <= r * 1.8 then
                local k = clamp(1 - d / (r * 1.8), 0, 1)
                score = score + (ev.severity or 20) * k
            end
        end
    end
    for _, tw in ipairs(EC.enemyTowers or {}) do
        local tpos = tw and tw.pos or (tw and nP(tw)) or nil
        if tpos then
            local d = d2d(pos, tpos)
            if d < 760 then score = score + clamp((760 - d) / 760, 0, 1) * 42 end
        end
    end
    for _, e in ipairs(EC.enemies or {}) do
        if nA(e) then
            local ep = nP(e)
            if ep then
                local vis = nV(e)
                local d = d2d(pos, ep)
                if vis and d < 1400 then
                    score = score + clamp((1400 - d) / 1400, 0, 1) * 26
                end
            end
        end
    end
    return score
end

local function updateThreats(now)
    if now - THREAT.t < 0.05 then return end
    THREAT.t = now
    THREAT.nearScore = 0
    for i = #THREAT.events, 1, -1 do
        local ev = THREAT.events[i]
        if not ev or now > (ev.expire or 0) then
            table.remove(THREAT.events, i)
            THREAT.stats.expired = THREAT.stats.expired + 1
        else
            if ev.kind == "linear" and ev.origin and ev.velocity then
                local dt = now - (ev.created or now)
                ev.pos = Vector(
                    ev.origin.x + ev.velocity.x * dt,
                    ev.origin.y + ev.velocity.y * dt,
                    (ev.origin.z or 0) + (ev.velocity.z or 0) * dt
                )
            end
            if EC.heroPos and ev.pos then
                local d = d2d(EC.heroPos, ev.pos)
                local r = math.max(100, ev.radius or 250)
                if d <= r * 2 then
                    THREAT.nearScore = THREAT.nearScore + (ev.severity or 20) * clamp(1 - d/(r*2), 0, 1)
                end
            end
        end
    end
    if ui and ui.th_minimap and ui.th_minimap:Get() and THREAT.nearScore >= 60 and now - THREAT.lastPingTime > 4 then
        local strongest
        local best = -1
        for _, ev in ipairs(THREAT.events) do
            if ev and ev.pos and (ev.severity or 0) > best then
                strongest, best = ev, ev.severity or 0
            end
        end
        if strongest and MiniMap and MiniMap.Ping then
            pcall(MiniMap.Ping, strongest.pos, 0)
            THREAT.lastPingTime = now
            THREAT.stats.pings = THREAT.stats.pings + 1
            -- Coleta resumo de TODOS os eventos ativos que contribuiram
            local reasons = {}
            local seen = {}
            for _, ev in ipairs(THREAT.events) do
                if ev and ev.pos and EC.heroPos then
                    local d = d2d(EC.heroPos, ev.pos)
                    local r = math.max(100, ev.radius or 250)
                    if d <= r * 2 and (ev.severity or 0) >= 20 then
                        local lbl = ev.text or ev.kind or "?"
                        if not seen[lbl] then
                            seen[lbl] = true
                            reasons[#reasons+1] = lbl
                        end
                    end
                end
            end
            local pingTxt = #reasons > 0 and table.concat(reasons, " + ") or (strongest.text or "Perigo")
            THREAT.pingAlert = pingTxt
            THREAT.pingAlertTime = now
            THREAT.pingAlertColor = strongest.color or C.red
            THREAT.pingAlertSev = strongest.severity or 50
            THREAT.pingAlertPos = strongest.pos  -- posicao no mundo para desenhar label
        end
    end
end

local function canCastTargetAbilityTo(ability, target)
    if not ability or not target then return true end
    local nm = sG(Ability.GetName, ability) or ""
    if nm == "" then return true end
    if sG(NPC.IsLinkensProtected, target) and not nm:find("item_force_staff") and not nm:find("item_hurricane_pike") then
        return false, "Linken"
    end
    if sG(NPC.IsLotusProtected, target) then
        local beh = sN(Ability.GetBehavior, ability)
        if beh ~= 0 then
            return false, "Lotus"
        end
    end
    return true
end

local TEMPO_CONFIG = {
    DEFEND     = {icon="[!]",  key="tempo_defend",  col="tempo_defend",  prio=90},
    RETREAT    = {icon="[<<]", key="tempo_retreat", col="tempo_retreat", prio=85},
    FIGHT      = {icon="[!!]", key="tempo_fight",   col="tempo_fight",   prio=80},
    PUSH       = {icon="[>>]", key="tempo_push",    col="tempo_push",    prio=70},
    ROSHAN     = {icon="[R]",  key="tempo_roshan",  col="tempo_roshan",  prio=65},
    RUNE       = {icon="[~]",  key="rune",          col="cyan",          prio=63},
    SMOKE_GANK = {icon="[S]",  key="tempo_smoke",   col="tempo_smoke",   prio=60},
    FARM       = {icon="[$]",  key="tempo_farm",    col="tempo_farm",    prio=40},
    STAND      = {icon="[.]",  key="tempo_stand",   col="tempo_stand",   prio=10},
}

--------------------------------------------------------------------------------
-- MOUSE
--------------------------------------------------------------------------------
local mouse = {x=0, y=0, dn=false, pr=false, rl=false, pv=false}
local function updMouse()
    local ok, x, y = pcall(Input.GetCursorPos)
    if ok and x and y then mouse.x, mouse.y = x, y end
    local ok2, d = pcall(Input.IsKeyDown, Enum.ButtonCode.KEY_MOUSE1)
    mouse.dn = ok2 and d or false
    mouse.pr = mouse.dn and not mouse.pv
    mouse.rl = not mouse.dn and mouse.pv
    mouse.pv = mouse.dn
end
local function inRect(px,py,rx,ry,rw,rh) return px>=rx and px<=rx+rw and py>=ry and py<=ry+rh end

--------------------------------------------------------------------------------
-- PANEL SYSTEM
--------------------------------------------------------------------------------
local activePanel, activeAction = nil, nil
local allPanels = {}

function resetPanelsRuntime()
    allPanels = {}
    activePanel, activeAction = nil, nil
end

function bringPanelToFront(p)
    if not p or not allPanels or #allPanels <= 1 then return end
    local pos = nil
    for i, it in ipairs(allPanels) do
        if it == p then pos = i break end
    end
    if not pos or pos == #allPanels then return end
    table.remove(allPanels, pos)
    allPanels[#allPanels+1] = p
end

function uiPanelSnapEnabled()
    return uiGetVal(ui and ui.ui_snap, true)
end

function uiPanelSnapDistPx()
    return math.max(2, F((uiGetVal(ui and ui.ui_snap_px, 12) or 12) * gScale + 0.5))
end

function uiPanelCompactMode(p)
    local mode = uiGetVal(ui and ui.ui_panel_mode, 0)
    if mode == 1 then return true end
    if mode ~= 2 then return false end
    local thr = uiGetVal(ui and ui.ui_auto_compact_thr, 65) or 65
    local near = (THREAT and THREAT.nearScore) or 0
    if near >= thr then return true end
    if GANK and GANK.on then return true end
    if DOD and DOD.t and (os.clock() - DOD.t) < 1.2 then return true end
    if p and p.id == "brain" and DB and #((DB and DB.tips) or {}) >= 3 then return true end
    return false
end

function uiPanelTargetHeight(p)
    if not p then return 0 end
    if p.col then return p.headerH or sc(28) end
    if not uiPanelCompactMode(p) then return p.h end
    local factor = p.compactFactor or 0.72
    local minExtra = p.compactMinH or sc(56)
    local headerH = p.headerH or sc(28)
    local target = math.max(headerH + minExtra, F((p.h or 0) * factor + 0.5))
    return math.min(p.h or target, target)
end

function snapPanelNow(p)
    if not p or not uiPanelSnapEnabled() then return end
    local d = uiPanelSnapDistPx()
    local x, y = p.x, p.y
    local pw = p.w or 0
    local ph = p.h or 0

    if math.abs(x) <= d then x = 0 end
    if math.abs(y) <= d then y = 0 end
    if math.abs((x + pw) - SW) <= d then x = SW - pw end
    if math.abs((y + ph) - SH) <= d then y = SH - ph end

    for _, q in ipairs(allPanels) do
        if q ~= p and q and q.vis ~= false then
            local qx, qy = q.x or 0, q.y or 0
            local qw, qh = q.w or 0, q.h or 0
            local overlapY = (y < qy + qh) and (y + ph > qy)
            local overlapX = (x < qx + qw) and (x + pw > qx)
            if overlapY then
                if math.abs(x - (qx + qw)) <= d then x = qx + qw end
                if math.abs((x + pw) - qx) <= d then x = qx - pw end
                if math.abs(x - qx) <= d then x = qx end
                if math.abs((x + pw) - (qx + qw)) <= d then x = qx + qw - pw end
            end
            if overlapX then
                if math.abs(y - (qy + qh)) <= d then y = qy + qh end
                if math.abs((y + ph) - qy) <= d then y = qy - ph end
                if math.abs(y - qy) <= d then y = qy end
                if math.abs((y + ph) - (qy + qh)) <= d then y = qy + qh - ph end
            end
        end
    end

    p.x = clamp(x, 0, math.max(0, SW - pw))
    p.y = clamp(y, 0, math.max(0, SH - ph))
end

function rectOverlapArea(ax, ay, aw, ah, bx, by, bw, bh)
    local ox = math.max(0, math.min(ax + aw, bx + bw) - math.max(ax, bx))
    local oy = math.max(0, math.min(ay + ah, by + bh) - math.max(ay, by))
    return ox * oy
end

function panelOverlapScore(x, y, w, h, extraPad)
    local pad = extraPad or sc(4)
    local score = 0
    for _, p in ipairs(allPanels or {}) do
        if p and p.vis ~= false then
            local ph = p.smoothH or (p.col and p.headerH) or p.h or 0
            local pw = p.w or 0
            local px = p.x or 0
            local py = p.y or 0
            score = score + rectOverlapArea(x, y, w, h, px - pad, py - pad, pw + pad * 2, ph + pad * 2)
        end
    end
    return score
end

function chooseHudRectAvoidPanels(defaultX, defaultY, w, h)
    local cands = {
        {x = defaultX, y = defaultY},
        {x = SW - w - sc(18), y = SH * 0.22},
        {x = sc(18), y = SH * 0.22},
        {x = SW - w - sc(18), y = SH * 0.34},
        {x = sc(18), y = SH * 0.34},
        {x = SW/2 - w/2, y = SH * 0.10},
        {x = SW/2 - w/2, y = SH * 0.40},
    }
    local best = nil
    local bestScore = nil
    for _, c in ipairs(cands) do
        local x = clamp(F(c.x + 0.5), 0, math.max(0, SW - w))
        local y = clamp(F(c.y + 0.5), 0, math.max(0, SH - h))
        local s = panelOverlapScore(x, y, w, h, sc(4))
        if s <= 0 then return x, y end
        if (not bestScore) or s < bestScore then
            bestScore = s
            best = {x=x, y=y}
        end
    end
    return (best and best.x) or defaultX, (best and best.y) or defaultY
end

local function mkPanel(id, dx, dy, dw, dh, title, tCol, mw, mh)
    local p = {
        id=id, title=title, tCol=tCol or C.accent,
        x=sGet(id.."_x",dx), y=sGet(id.."_y",dy),
        w=sGet(id.."_w",dw), h=sGet(id.."_h",dh),
        minW=mw or 200, minH=mh or 60,
        col=sGet(id.."_col",0)==1,
        vis=true, drawContent=nil, smoothH=nil, headerH=28, icon=nil,
        compactFactor=0.72, compactMinH=56,
        minHFn=nil,
        drawer=true,
        drawerHidden=sGet(id.."_hid",0)==1,
        drawerEdge=(sGet(id.."_edge",0)==1) and "right" or "left",
        drawerAnim=(sGet(id.."_hid",0)==1) and 1 or 0,
    }
    if p.w <= 0 then p.w = dw end
    if p.h <= 0 then p.h = dh end
    p.headerH = sc(28); p.smoothH = p.col and p.headerH or p.h

    function p:save()
        sSet(self.id.."_x",self.x); sSet(self.id.."_y",self.y)
        sSet(self.id.."_w",self.w); sSet(self.id.."_h",self.h)
        sSet(self.id.."_col",self.col and 1 or 0)
        sSet(self.id.."_hid", self.drawerHidden and 1 or 0)
        sSet(self.id.."_edge", self.drawerEdge == "right" and 1 or 0)
    end

    function p:drawerEnabled()
        return self.drawer and uiGetVal(ui and ui.ui_drawer_tabs, true)
    end

    function p:drawerResolveEdge()
        if self.drawerEdge == "left" or self.drawerEdge == "right" then return self.drawerEdge end
        return ((self.x + self.w * 0.5) >= (SW * 0.5)) and "right" or "left"
    end

    function p:drawerTabRect()
        if not self:drawerEnabled() then return nil end
        local tw = sc(clamp(uiGetVal(ui and ui.ui_drawer_tab_w, 18) or 18, 12, 32))
        local th = sc(clamp(uiGetVal(ui and ui.ui_drawer_tab_h, 44) or 44, 24, 96))
        local ty = clamp(F(self.y + (self.headerH or sc(28)) * 0.5 - th * 0.5 + 0.5), 0, math.max(0, SH - th))
        local edge = self:drawerResolveEdge()
        local tx = (edge == "right") and math.max(0, SW - tw) or 0
        return tx, ty, tw, th, edge
    end

    function p:toggleDrawer()
        if not self:drawerEnabled() then return false end
        if self.drawerHidden then
            self.drawerHidden = false
            self.x = clamp(self.x, 0, math.max(0, SW - self.w))
            self.y = clamp(self.y, 0, math.max(0, SH - self.headerH))
        else
            self.drawerEdge = self:drawerResolveEdge()
            self.drawerHidden = true
            if activePanel == self then activePanel, activeAction = nil, nil end
        end
        self:save()
        return true
    end

    function p:interact(locked)
        if not self.vis then return false end
        self.headerH = sc(28)
        local dAnim = tonumber(self.drawerAnim or ((self.drawerHidden and 1) or 0)) or 0
        local drawerBusy = self:drawerEnabled() and (self.drawerHidden or dAnim > 0.02)
        if drawerBusy then
            local tx, ty, tw, th = self:drawerTabRect()
            if tx and mouse.pr and inRect(mouse.x, mouse.y, tx, ty, tw, th) then
                bringPanelToFront(self)
                self:toggleDrawer()
                return true
            end
            return false
        end
        local bs = sc(20)
        local gap = sc(4)
        local bx = self.x + self.w - bs - sc(6)
        local by = self.y + (self.headerH - bs) / 2
        local dbs = bs
        local drawerBtn = self:drawerEnabled()
        local dbx = bx - gap - dbs
        if drawerBtn and mouse.pr and inRect(mouse.x,mouse.y,dbx,by,dbs,dbs) then
            bringPanelToFront(self)
            self.drawerEdge = ((self.x + self.w * 0.5) >= (SW * 0.5)) and "right" or "left"
            self:toggleDrawer()
            return true
        end
        if mouse.pr and inRect(mouse.x,mouse.y,bx,by,bs,bs) then
            bringPanelToFront(self)
            self.col = not self.col; self:save(); return true end
        if locked then return false end
        if not self.col then
            local rs = sc(14)
            if mouse.pr and not activePanel and
               inRect(mouse.x,mouse.y,self.x+self.w-rs,self.y+self.smoothH-rs,rs,rs) then
                bringPanelToFront(self)
                activePanel, activeAction = self, "resize"; return true end
        end
        local headerBlock = bs + sc(10) + (drawerBtn and (dbs + gap) or 0)
        if mouse.pr and not activePanel and
           inRect(mouse.x,mouse.y,self.x,self.y,self.w-headerBlock,self.headerH) then
            bringPanelToFront(self)
            activePanel, activeAction = self, "drag"
            self.dragOX = mouse.x - self.x; self.dragOY = mouse.y - self.y; return true
        end
        return false
    end

    function p:updateDrag()
        if activePanel ~= self then return end
        local dynMinH = self.minH
        if self.minHFn then
            local ok, mh = pcall(self.minHFn, self, self.w, self.h)
            if ok and type(mh) == "number" then dynMinH = math.max(dynMinH, F(mh + 0.5)) end
        end
        if activeAction == "drag" then
            self.x = clamp(mouse.x-(self.dragOX or 0), 0, SW-100)
            self.y = clamp(mouse.y-(self.dragOY or 0), 0, SH-50)
        elseif activeAction == "resize" then
            self.w = math.max(self.minW, math.min(mouse.x-self.x, SW-self.x))
            self.h = math.max(dynMinH, math.min(mouse.y-self.y, SH-self.y))
        end
        if mouse.rl then
            if uiPanelSnapEnabled() then snapPanelNow(self) end
            self.drawerEdge = ((self.x + self.w * 0.5) >= (SW * 0.5)) and "right" or "left"
            self:save(); activePanel, activeAction = nil, nil
        end
    end

    function p:render(locked)
        if not self.vis or not fontsOK then return end
        self.headerH = sc(28)
        if self.drawerHidden and not self:drawerEnabled() then self.drawerHidden = false end
        local drawerEnabled = self:drawerEnabled()
        if drawerEnabled then
            local targetAnim = self.drawerHidden and 1 or 0
            self.drawerAnim = (self.drawerAnim or targetAnim) + (targetAnim - (self.drawerAnim or targetAnim)) * 0.28
            if math.abs((self.drawerAnim or 0) - targetAnim) < 0.015 then self.drawerAnim = targetAnim end
        else
            self.drawerAnim = 0
        end
        local dAnim = tonumber(self.drawerAnim or 0) or 0
        local tabX, tabY, tabW, tabH, tabEdge = nil, nil, nil, nil, nil
        local showTab = drawerEnabled and (self.drawerHidden or dAnim > 0.01)
        if showTab then
            tabX, tabY, tabW, tabH, tabEdge = self:drawerTabRect()
            local hov = tabX and inRect(mouse.x, mouse.y, tabX, tabY, tabW, tabH)
            local rndt = sc(6)
            if uiGetVal(ui and ui.ui_blur, true) and type(Render.Blur) == "function" then
                local blurStrength = tonumber(uiGetVal(ui and ui.ui_blur_strength, 7)) or 7
                pcall(Render.Blur, Vec2(F(tabX), F(tabY)), Vec2(F(tabW), F(tabH)), blurStrength)
            end
            dRect(tabX+sc(3), tabY+sc(3), tabW, tabH, col(0,0,0,70), rndt)
            dRect(tabX, tabY, tabW, tabH, uiGetVal(ui and ui.ui_high_contrast, false) and col(8, 10, 18, 248) or C.bg_panel, rndt)
            dBorder(tabX, tabY, tabW, tabH, hov and colA(self.tCol, 220) or colA(self.tCol, 130), rndt)
            if tabEdge == "left" then dRect(tabX+tabW-sc(2), tabY+sc(2), sc(2), tabH-sc(4), colA(self.tCol, 140), sc(2))
            else dRect(tabX, tabY+sc(2), sc(2), tabH-sc(4), colA(self.tCol, 140), sc(2)) end
            local arr = (tabEdge == "right") and "<" or ">"
            dText(14, arr, tabX + tabW/2 - tW(14, arr)/2, tabY + tabH/2 - sc(8), hov and C.white or self.tCol)
            if self.drawerHidden and dAnim >= 0.985 then return end
        end
        local vx = self.x
        if drawerEnabled and dAnim > 0.001 and tabW and tabEdge then
            local hiddenX = (tabEdge == "right") and (SW - tabW) or (0 - self.w + tabW)
            vx = self.x + (hiddenX - self.x) * dAnim
        end
        if self.minHFn and not self.col then
            local ok, mh = pcall(self.minHFn, self, self.w, self.h)
            if ok and type(mh) == "number" then
                mh = math.max(self.minH, F(mh + 0.5))
                if self.h < mh then self.h = mh end
            end
        end
        self.compact = uiPanelCompactMode(self)
        local targetH = uiPanelTargetHeight(self)
        self.smoothH = self.smoothH + (targetH - self.smoothH) * 0.25
        if math.abs(self.smoothH - targetH) < 1 then self.smoothH = targetH end
        local rnd = sc(8)
        if uiGetVal(ui and ui.ui_blur, true) and type(Render.Blur) == "function" then
            local blurStrength = tonumber(uiGetVal(ui and ui.ui_blur_strength, 7)) or 7
            pcall(Render.Blur, Vec2(F(vx), F(self.y)), Vec2(F(self.w), F(self.smoothH)), blurStrength)
        end
        dRect(vx+sc(4), self.y+sc(4), self.w, self.smoothH, col(0,0,0,80), rnd)
        local bgPanel = uiGetVal(ui and ui.ui_high_contrast, false) and col(8, 10, 18, 248) or C.bg_panel
        local bgHeader = uiGetVal(ui and ui.ui_high_contrast, false) and colA(self.tCol, 50) or colA(self.tCol,35)
        local brCol = uiGetVal(ui and ui.ui_high_contrast, false) and colA(C.white, 70) or C.border
        dRect(vx, self.y, self.w, self.smoothH, bgPanel, rnd)
        dRect(vx, self.y, self.w, self.headerH, bgHeader, rnd)
        dRect(vx+sc(3), self.y, self.w-sc(6), sc(2), self.tCol)
        dBorder(vx, self.y, self.w, self.smoothH, brCol, rnd)
        local tx = vx + sc(12)
        if self.icon then
            local isz = sc(16)
            dImage(self.icon, vx+sc(10), self.y+sc(5), isz, isz, 245, sc(3))
            tx = tx + sc(20)
        end
        dText(12, self.title, tx, self.y+sc(6), self.tCol)
        local bs = sc(20)
        local gap = sc(4)
        local bx = vx + self.w - bs - sc(6)
        local by = self.y + (self.headerH - bs) / 2
        local drawerBtn = self:drawerEnabled()
        local dbs = bs
        local dbx = bx - gap - dbs
        if drawerBtn then
            local dhv = inRect(mouse.x,mouse.y,dbx,by,dbs,dbs)
            local hideEdge = ((self.x + self.w * 0.5) >= (SW * 0.5)) and "right" or "left"
            local darr = (hideEdge == "right") and ">" or "<"
            dRect(dbx,by,dbs,dbs, dhv and C.bg_hover or col(40,45,60,100), sc(4))
            dText(11, darr, dbx+dbs/2 - tW(11, darr)/2, by+sc(2), dhv and self.tCol or C.gray)
        end
        local hv = inRect(mouse.x,mouse.y,bx,by,bs,bs)
        dRect(bx,by,bs,bs, hv and C.bg_hover or col(40,45,60,100), sc(4))
        dText(11, self.col and "+" or "-", bx+sc(5), by+sc(2), hv and C.accent or C.gray)
        if self.col then return end
        if self.drawContent then
            local padX = self.compact and sc(8) or sc(10)
            local padTop = self.compact and sc(6) or sc(8)
            local padBottom = self.compact and sc(10) or sc(16)
            local cx = vx + padX; local cy = self.y + self.headerH + padTop
            local cw = self.w - padX * 2; local ch = self.smoothH - self.headerH - padTop - padBottom
            if ch > 5 then
                local clipped = false
                if uiGetVal(ui and ui.ui_clip_panels, true) and type(Render.PushClip) == "function" and type(Render.PopClip) == "function" then
                    -- Some builds expect clip max corner instead of size, despite docs wording.
                    -- Using bottom-right coordinates prevents panels below the top-left quadrant from being fully clipped.
                    clipped = pcall(Render.PushClip, Vec2(F(cx), F(cy)), Vec2(F(cx + cw), F(cy + ch)))
                end
                self.drawContent(self, cx, cy, cw, ch)
                if clipped then pcall(Render.PopClip) end
            end
        end
        if not locked then
            local rs = sc(14); local rrx = vx+self.w-rs; local ry = self.y+self.smoothH-rs
            local rHov = inRect(mouse.x,mouse.y,rrx,ry,rs,rs)
            local rc = rHov and C.accent or C.resize
            for i = 0, 2 do dLine(rrx+rs-sc(2),ry+sc(3)+i*sc(4),rrx+sc(3)+i*sc(4),ry+rs-sc(2),rc) end
        end
    end

    allPanels[#allPanels+1] = p
    return p
end

--------------------------------------------------------------------------------
-- MENU - 3 TABS
--------------------------------------------------------------------------------
ui = {}
local tab = Menu.Create("General", "Main", "JppsTech v9")
tab:Icon("\u{f5dc}")

-- TAB 1: GAMEPLAY
local t1 = tab:Create("\u{f11b} Gameplay")

local g1a = t1:Create("Kill Matrix")
ui.km       = g1a:Switch("Enable", true)
ui.km_pan   = g1a:Switch("Panel", true)
ui.km_oh    = g1a:Switch("Overhead %", true)
ui.km_rev   = g1a:Switch("Reverse Threat", true)

local g1b = t1:Create("Dashboard & Tips")
ui.db       = g1b:Switch("Enable", true)
ui.db_graph = g1b:Switch("Power Graph", true)
ui.db_graph_len = g1b:Slider("Graph History", 30, 150, 80)
ui.db_fight = g1b:Switch("Fight Tips", true)
ui.db_rune  = g1b:Switch("Rune Timer", true)
ui.db_stack = g1b:Switch("Stack Timer", true)

local g1c = t1:Create("Combo & Initiation")
ui.combo      = g1c:Switch("Combo Tracker", true)
ui.combo_dmg  = g1c:Switch("Show Damage", true)
ui.combo_mana = g1c:Switch("Show Mana", true)
ui.combo_view = g1c:Combo("Combo View", {"Icons","Text","Mixed"}, sGet("combo_view", 2))
ui.combo_cd_ov = g1c:Switch("Combo CD Overlay", sGet("combo_cd_ov", 1) == 1)
ui.combo_tip = g1c:Switch("Combo Tooltips", sGet("combo_tip", 1) == 1)
ui.ini        = g1c:Switch("Initiation Finder", true)
ui.ini_min    = g1c:Slider("Min Enemies", 2, 5, 2)

local g1d = t1:Create("Map Control")
ui.map_enable    = g1d:Switch("Enable", true)
ui.map_safe_farm = g1d:Switch("Safe Farm Areas", true)
ui.map_split     = g1d:Switch("Split Push Advisor", true)
ui.map_missing   = g1d:Switch("MIA World Circles", true)

local g1e = t1:Create("Tempo Coach")
ui.tempo_enable   = g1e:Switch("Enable", true)
ui.tempo_screen   = g1e:Switch("Show on Screen", true)
ui.tempo_messages = g1e:Switch("Event Messages", true)
ui.tempo_spikes   = g1e:Switch("Power Spikes", true)
ui.tempo_fight    = g1e:Switch("Fight Advice", true)
ui.tempo_death    = g1e:Switch("Death Alerts", true)
ui.tempo_obj      = g1e:Switch("Objective Windows", true)
ui.tempo_buyback  = g1e:Switch("Buyback Risk", true)
ui.tempo_stable   = g1e:Switch("Anti-Flicker", true)
ui.tempo_alt      = g1e:Switch("Show Alternatives", true)
ui.tempo_font     = g1e:Slider("Font Size", 24, 48, 32)
ui.tempo_duration = g1e:Slider("Duration (sec)", 2, 10, 5)
ui.tempo_max_msg  = g1e:Slider("Max Messages", 2, 8, 5)

local g1f = t1:Create("Auto Items")
ui.auto_phase     = g1f:Switch("Auto Phase Boots", false)
ui.auto_stick     = g1f:Switch("Auto Stick/Wand", false)
ui.auto_stick_hp  = g1f:Slider("Stick HP %", 10, 80, 40, "%d%%")
ui.auto_faerie    = g1f:Switch("Auto Faerie Fire", false)
ui.auto_faerie_hp = g1f:Slider("Faerie HP %", 5, 30, 15, "%d%%")

local g1g = t1:Create("Order Guard")
ui.guard_enable   = g1g:Switch("Enable", true)
ui.guard_move     = g1g:Switch("Block dangerous move/cast pos", true)
ui.guard_cast     = g1g:Switch("Block Linken/Lotus target cast", false)
ui.guard_channel  = g1g:Switch("Protect channels", true)
ui.guard_tower    = g1g:Switch("Tower dive check", true)
ui.guard_thr      = g1g:Slider("Danger threshold", 40, 220, 95)

local g1h = t1:Create("Core Scheduler")
ui.core_q         = g1h:Switch("Action queue", true)
ui.core_human     = g1h:Switch("Use Humanizer gate", true)
ui.core_heavy_ms  = g1h:Slider("Heavy logic interval", 50, 300, 120, "%d ms")
ui.core_flush_ms  = g1h:Slider("Queue flush interval", 10, 120, 30, "%d ms")

-- TAB 2: VISUAL
local t2 = tab:Create("\u{f06e} Visual")

local g2a = t2:Create("Kill Visual")
ui.km_world = g2a:Switch("World Circles", true)
ui.km_hp    = g2a:Switch("HP Bars", true)
ui.km_dmg   = g2a:Switch("Damage Numbers", true)
ui.km_thr   = g2a:Switch("Threshold Line", true)
ui.km_mia   = g2a:Switch("MIA Tracking", true)

local g2b = t2:Create("Enemy Trackers")
ui.ih       = g2b:Switch("Items — Enable", true)
ui.ih_pan   = g2b:Switch("Items — Panel", true)
ui.ih_oh    = g2b:Switch("Items — Overhead", true)
ui.ih_cd    = g2b:Switch("Items — Cooldowns", true)
ui.sp       = g2b:Switch("Spells — Enable", true)
ui.sp_pan   = g2b:Switch("Spells — Panel", true)
ui.sp_oh    = g2b:Switch("Spells — Overhead", true)

local g2c = t2:Create("World & Alerts")
ui.w_tower  = g2c:Switch("Tower Range", true)
ui.w_blink  = g2c:Switch("Blink Range", false)
ui.w_lh     = g2c:Switch("Last Hit Helper", true)
ui.w_flash  = g2c:Switch("Kill Flash", true)
ui.w_smoke  = g2c:Switch("Smoke Alert", true)
ui.w_linken = g2c:Switch("Linken Tracker", true)
ui.w_dodge  = g2c:Switch("Dodge Assist", true)
ui.gank     = g2c:Switch("Gank Alert", true)

local g2d = t2:Create("HUD Panels")
ui.hud_info    = g2d:Switch("Hero Info", true)
ui.hud_timers  = g2d:Switch("Timers", true)
ui.hud_farm    = g2d:Switch("Farm Dashboard", true)
ui.hud_target  = g2d:Switch("Target Info", true)
ui.hud_debug   = g2d:Switch("Debug Panel", false)

local g2e = t2:Create("Threat Engine")
ui.th_enable    = g2e:Switch("Enable", true)
ui.th_project   = g2e:Switch("Projectiles", true)
ui.th_particle  = g2e:Switch("Particles", true)
ui.th_sound     = g2e:Switch("Sounds", true)
ui.th_anim      = g2e:Switch("Animations", true)
ui.th_draw      = g2e:Switch("World Markers", true)
ui.th_lines     = g2e:Switch("Hero-to-threat lines", true)
ui.th_score     = g2e:Switch("Threat HUD", true)
ui.th_minimap   = g2e:Switch("MiniMap Alerts", false)
ui.th_max_draw  = g2e:Slider("Max markers", 2, 12, 6)

-- TAB 3: SETTINGS
local t3 = tab:Create("\u{f013} Settings")

local g3a = t3:Create("General")
ui.scale = g3a:Slider("UI Scale", 50, 200, 100)
ui.lock  = g3a:Switch("Lock Panels", false)
ui.lang  = g3a:Combo("Language", {"English","Russian","Portugues"}, LANG == "ru" and 1 or (LANG == "pt" and 2 or 0))

local g3c = t3:Create("UI & Layout")
ui.ui_panel_mode       = g3c:Combo("Panel Mode", {"Full","Compact","Auto"}, sGet("ui_panel_mode", 0))
ui.ui_auto_compact_thr = g3c:Slider("Auto Compact Threat", 20, 180, sGet("ui_auto_compact_thr", 65))
ui.ui_font_floor       = g3c:Slider("Font Floor", 8, 14, sGet("ui_font_floor", 9))
ui.ui_text_shadow      = g3c:Switch("Text Shadow", sGet("ui_text_shadow", 1) == 1)
ui.ui_high_contrast    = g3c:Switch("High Contrast", sGet("ui_high_contrast", 0) == 1)
ui.ui_blur             = g3c:Switch("Panel Blur", sGet("ui_blur", 1) == 1)
ui.ui_blur_strength    = g3c:Slider("Blur Strength", 1, 16, sGet("ui_blur_strength", 7))
ui.ui_clip_panels      = g3c:Switch("Clip Content", sGet("ui_clip_panels", 1) == 1)
ui.ui_show_panels      = g3c:Switch("Show UI Panels", sGet("ui_show_panels", 1) == 1)
ui.ui_snap             = g3c:Switch("Snap Panels", sGet("ui_snap", 1) == 1)
ui.ui_snap_px          = g3c:Slider("Snap Distance", 4, 30, sGet("ui_snap_px", 12))
ui.ui_drawer_tabs      = g3c:Switch("Edge Drawer Tabs", sGet("ui_drawer_tabs", 1) == 1)
ui.ui_drawer_tab_w     = g3c:Slider("Drawer Tab Width", 12, 32, sGet("ui_drawer_tab_w", 18))
ui.ui_drawer_tab_h     = g3c:Slider("Drawer Tab Height", 24, 96, sGet("ui_drawer_tab_h", 44))
ui.ui_snap_now         = g3c:Button("Snap All Panels", function()
    if not allPanels then return end
    refreshScreen()
    for _, p in ipairs(allPanels) do snapPanelNow(p); p:save() end
end)

local g3d = t3:Create("Localization")
ui.ru_render_mode = g3d:Combo("RU Render Mode", {"Auto","UTF-8","CP1251","Translit"}, sGet("ru_render_mode", 1))
ui.locale_reload  = g3d:Button("Reload Locale Cache", function()
    clearLocaleRuntimeCaches()
    if type(resetPanelsRuntime) == "function" then resetPanelsRuntime() end
end)
ui.locale_rebuild = g3d:Button("Rebuild Panels", function()
    if type(resetPanelsRuntime) == "function" then resetPanelsRuntime() end
end)

local g3b = t3:Create("Cosmic Background")
ui.cos_en       = g3b:Switch("Enable", true)
ui.cos_dark     = g3b:Slider("Darkness", 0, 100, 25, "%d%%")
ui.cos_attract  = g3b:Switch("Cursor Attract", true)
ui.cos_glow     = g3b:Switch("Particle Glow", true)
ui.cos_psz      = g3b:Slider("Particle Size", 1, 5, 2)
ui.cos_stars    = g3b:Switch("Stars", true)
ui.cos_nebula   = g3b:Switch("Nebula", true)
ui.cos_shooting = g3b:Switch("Shooting Stars", true)
ui.cos_aurora   = g3b:Switch("Aurora Borealis", true)
ui.cos_c1       = g3b:ColorPicker("Primary Color", Color(100,200,255,200))
ui.cos_c2       = g3b:ColorPicker("Secondary Color", Color(255,100,200,200))

applyRuRenderModeIndex(sGet("ru_render_mode", 1))

--------------------------------------------------------------------------------
-- PANELS — 4 UNIFIED PANELS
--------------------------------------------------------------------------------
local panels = {}
local panelsInit = false

function setPanelManagerAllVisible(v)
    if ui then
        if ui.pm_brain and ui.pm_brain.Set then pcall(ui.pm_brain.Set, ui.pm_brain, v) end
        if ui.pm_intel and ui.pm_intel.Set then pcall(ui.pm_intel.Set, ui.pm_intel, v) end
        if ui.pm_tracker and ui.pm_tracker.Set then pcall(ui.pm_tracker.Set, ui.pm_tracker, v) end
        if ui.pm_sidebar and ui.pm_sidebar.Set then pcall(ui.pm_sidebar.Set, ui.pm_sidebar, v) end
    end
    if panels then
        for _, p in pairs(panels) do if p then p.vis = v end end
    end
end

function setPanelManagerAllCollapsed(v)
    if not panels then return end
    for _, p in pairs(panels) do
        if p then p.col = v end
        if p and p.save then p:save() end
    end
end

function setPanelManagerAllDrawer(v)
    if not panels then return end
    for _, p in pairs(panels) do
        if p and p.drawerEnabled and p:drawerEnabled() then
            p.drawerEdge = ((p.x + p.w * 0.5) >= (SW * 0.5)) and "right" or "left"
            p.drawerHidden = v and true or false
            p.drawerAnim = v and 1 or 0
            if p.save then p:save() end
        end
    end
end

function applyPanelManagerSettings()
    if not panels or not ui then return end
    if panels.brain and ui.pm_brain then panels.brain.vis = uiGetVal(ui.pm_brain, true) end
    if panels.intel and ui.pm_intel then panels.intel.vis = uiGetVal(ui.pm_intel, true) end
    if panels.tracker and ui.pm_tracker then panels.tracker.vis = uiGetVal(ui.pm_tracker, true) end
    if panels.sidebar and ui.pm_sidebar then panels.sidebar.vis = uiGetVal(ui.pm_sidebar, true) end
end

local g3e = t3:Create("Panel Manager")
ui.pm_brain   = g3e:Switch("Brain Panel", sGet("pm_brain", 1) == 1)
ui.pm_intel   = g3e:Switch("Intel Panel", sGet("pm_intel", 1) == 1)
ui.pm_tracker = g3e:Switch("Tracker Panel", sGet("pm_tracker", 1) == 1)
ui.pm_sidebar = g3e:Switch("Sidebar Panel", sGet("pm_sidebar", 1) == 1)
ui.pm_show_all = g3e:Button("Show All Panels", function() setPanelManagerAllVisible(true) end)
ui.pm_hide_all = g3e:Button("Hide All Panels", function() setPanelManagerAllVisible(false) end)
ui.pm_expand_all = g3e:Button("Expand All", function() setPanelManagerAllCollapsed(false) end)
ui.pm_collapse_all = g3e:Button("Collapse All", function() setPanelManagerAllCollapsed(true) end)
ui.pm_drawer_all = g3e:Button("Drawer Hide All", function() setPanelManagerAllDrawer(true) end)
ui.pm_restore_all = g3e:Button("Drawer Restore All", function() setPanelManagerAllDrawer(false) end)

-- Redefine after local panelsInit declaration so locale/UI callbacks reset the real local state.
function resetPanelsRuntime()
    panelsInit = false
    allPanels = {}
    activePanel, activeAction = nil, nil
end

-- Tabela de poder de combate dos itens (bonus que nao aparece em stats)
local ITEM_POWER = {
    item_black_king_bar = 550,   item_aegis = 800,
    item_rapier = 700,           item_satanic = 450,
    item_butterfly = 500,        item_skadi = 400,
    item_heart = 400,            item_assault = 380,
    item_shivas_guard = 350,     item_sheepstick = 500,
    item_abyssal_blade = 450,    item_bloodthorn = 420,
    item_orchid = 250,           item_nullifier = 350,
    item_sphere = 300,           item_lotus_orb = 280,
    item_manta = 300,            item_pipe = 250,
    item_silver_edge = 350,      item_refresher = 400,
    item_aeon_disk = 300,        item_overwhelming_blink = 280,
    item_swift_blink = 280,      item_arcane_blink = 280,
    item_blink = 200,            item_blade_mail = 180,
    item_glimmer_cape = 150,     item_ghost = 120,
    item_force_staff = 150,      item_hurricane_pike = 280,
    item_daedalus = 400,         item_mjollnir = 350,
    item_monkey_king_bar = 380,  item_desolator = 300,
    item_eye_of_skadi = 400,     item_disperser = 350,
    item_harpoon = 280,          item_khanda = 350,
    item_parasma = 350,          item_ethereal_blade = 280,
    item_radiance = 300,         item_mage_slayer = 200,
    item_sange_and_yasha = 250,  item_kaya_and_sange = 250,
    item_yasha_and_kaya = 250,   item_heavens_halberd = 280,
    item_bloodstone = 280,       item_eternal_shroud = 250,
    item_octarine_core = 280,    item_witch_blade = 120,
    item_armlet = 200,           item_mask_of_madness = 150,
    item_diffusal_blade = 200,   item_echo_sabre = 150,
    item_maelstrom = 180,        item_basher = 200,
    item_dragon_lance = 100,     item_vanguard = 120,
    item_crimson_guard = 220,    item_hood_of_defiance = 100,
    item_solar_crest = 200,      item_rod_of_atos = 150,
    item_spirit_vessel = 200,    item_urn_of_shadows = 80,
    -- Itens baratos: pouco impacto
    item_bracer = 30, item_wraith_band = 30, item_null_talisman = 30,
    item_power_treads = 60, item_phase_boots = 60, item_arcane_boots = 50,
    item_tranquil_boots = 40, item_boots_of_bearing = 180,
    item_guardian_greaves = 300, item_boots_of_travel = 100,
}

local function heroItemPower(h)
    if not h then return 0 end
    local total = 0
    for slot = 0, 8 do
        local item = sG(NPC.GetItemByIndex, h, slot)
        if item then
            local iN = sG(Ability.GetName, item) or ""
            local pw = ITEM_POWER[iN]
            if pw then
                total = total + pw
            elseif iN ~= "" and not iN:find("recipe") and not iN:find("tpscroll") and not iN:find("ward") then
                total = total + 50  -- item desconhecido: bonus minimo
            end
        end
    end
    return total
end

local function heroPower(h)
    if not h or not nA(h) then return 0 end
    local s = EC.heroStats[nI(h)]
    if not s then return 0 end
    -- Usar HP atual, nao maximo — heroi com 20% HP nao tem 100% de poder de luta
    local hpCurrent = s.hp or 0
    local hpMax = s.maxHp or 1
    local hpRatio = clamp(hpCurrent / math.max(1, hpMax), 0, 1)
    -- Fator de HP: heroi com 100% HP = 1.0, 50% HP = 0.7, 20% HP = 0.5, 0% = 0.3
    local hpFactor = 0.3 + hpRatio * 0.7
    -- EHP fisico + magico basico
    local physEHP = hpCurrent * (1 + s.armor * 0.06 / (1 + 0.06 * math.abs(s.armor)))
    local magicEHP = hpCurrent * (1 / math.max(0.25, 1 - (s.mr or 0.25)))
    local ehp = (physEHP + magicEHP) / 2
    -- DPS = dano * velocidade de ataque (nao so dano bruto)
    local aps = (s.as or 100) / math.max(50, (s.bat or 1.7) * 100)
    local dps = s.dmg * clamp(aps, 0.3, 4.0)
    -- Nivel linear com curva suave (nao quadratico)
    local lvlFactor = s.level * 38 + math.max(0, s.level - 15) * 18
    local itemPow = heroItemPower(h)
    -- Mana check: sem mana = menos perigoso (casters)
    local manaPct = s.maxMana > 0 and (s.mana / s.maxMana) or 1
    local manaFactor = 0.6 + manaPct * 0.4
    return F((ehp / 40 + dps * 3.2 + lvlFactor + itemPow) * hpFactor * manaFactor)
end

local function initPanels()
    loadUIAssets()

    -- ═══════════════════════════════════════════════════════════════
    -- PANEL 1: BRAIN — Kill Matrix + Dashboard + Power Graph + Tips
    -- ═══════════════════════════════════════════════════════════════
    panels.brain = mkPanel("brain", 10, 60, 880, 220, L("brain"), C.accent, 400, 120)
    panels.brain.compactFactor = 0.64
    panels.brain.compactMinH = sc(78)
    panels.brain.icon = UI_ASSETS.icons.brain
    panels.brain.drawContent = function(self, x, y, w, h)
        local showKM = ui.km_pan:Get()
        local showDB = ui.db:Get()
        local showPower = ui.db_graph:Get()
        local showTips = true
        local cols = (showKM and 1 or 0) + (showDB and 1 or 0) + (showPower and 1 or 0) + (showTips and 1 or 0)
        if cols <= 0 then
            dText(9, "No BRAIN modules enabled", x+sc(6), y+sc(8), C.gray)
            return
        end
        local colI = 0
        local function nextBrainCol()
            local sx = x + F(w * colI / cols)
            colI = colI + 1
            local nx = x + F(w * colI / cols)
            return sx, math.max(sc(120), nx - sx)
        end

        -- Section 1: Kill Matrix
        if showKM then
            local x, secW = nextBrainCol()
            dRect(x, y, secW-sc(4), h, C.bg_section, sc(6))
            dText(10, L("kill_matrix"):upper(), x+sc(8), y+sc(4), C.accent)
            local ey = y + sc(20); local rh = sc(24)
            for i, e in ipairs(EC.enemies) do
                if ey+rh > y+h then break end
                local idx = nI(e); local d = idx and KM.data[idx]
                local alive, vis = nA(e), nV(e)
                local mia = idx and DB.mia[idx]
                dRect(x+sc(3), ey, secW-sc(10), rh-sc(2), i%2==0 and C.bg_row_alt or C.bg_row, sc(4))
                local nameX = x + sc(6)
                local hIcon = getHeroIconHandle(e)
                if hIcon then
                    dImage(hIcon, nameX, ey+sc(3), sc(14), sc(14), 235, sc(3))
                    nameX = nameX + sc(18)
                end
                dText(9, hName(e), nameX, ey+sc(4), alive and (vis and C.text or C.gray) or C.dark)
                if alive and d then
                    local ch2 = d.killChance; local chC = killColor(ch2)
                    dRect(x+sc(72),ey+sc(2),sc(40),sc(16),colA(chC,25),sc(4))
                    dBorder(x+sc(72),ey+sc(2),sc(40),sc(16),colA(chC,120),sc(4))
                    dText(9,ch2.."%",x+sc(78),ey+sc(3),chC)
                    dBar(x+sc(116),ey+sc(5),sc(36),sc(7),d.targetHP/d.targetMaxHP,C.hp,C.hp_bg,sc(3))
                    local ttkP = (d.timeToKill and d.timeToKill < 99) and string.format("%.1fs", d.timeToKill) or (d.hitsToKill..L("hits"))
                    dText(8,ttkP,x+sc(156),ey+sc(4),C.gray)
                    if d.flags and d.flags ~= "" then dText(7,d.flags,x+sc(196),ey+sc(5),C.orange) end
                    if ui.w_linken:Get() and LINKEN[idx] then dCircle(x+secW-sc(14),ey+sc(10),sc(4),C.purple) end
                elseif not alive then dText(8,L("dead"),x+sc(72),ey+sc(4),C.dark) end
                if alive and not vis and mia and mia.missTime > 5 then
                    local mt = F(mia.missTime)
                    dText(8,mt..L("s"),x+secW-sc(32),ey+sc(4),mt>30 and C.red or (mt>15 and C.orange or C.yellow))
                end
                if ui.km_rev:Get() and alive and idx and KM.rev[idx] and KM.rev[idx].killChance >= 50 then
                    local rv = KM.rev[idx].killChance
                    dText(7,"!"..rv,x+secW-sc(50),ey+sc(5),rv>=75 and C.red or C.orange)
                end
                ey = ey + rh
            end
        end

        -- Section 2: Dashboard
        if showDB then
            local sx2, secW = nextBrainCol()
            dRect(sx2, y, secW-sc(4), h, C.bg_section, sc(6))
            dText(10, L("dashboard"):upper(), sx2+sc(8), y+sc(4), C.cyan)
            local dy = y + sc(20)
            local gC = DB.gpm>500 and C.green or (DB.gpm>300 and C.yellow or C.orange)
            dText(9,L("gpm")..":",sx2+sc(6),dy,C.gray)
            dText(10,tostring(DB.gpm),sx2+sc(38),dy-sc(1),gC)
            dBar(sx2+sc(78),dy+sc(2),sc(55),sc(8),clamp(DB.gpm/800,0,1),gC,nil,sc(3))
            local rating,rC
            if DB.gpm>700 then rating,rC="S+",C.gold elseif DB.gpm>600 then rating,rC="S",C.gold
            elseif DB.gpm>500 then rating,rC="A",C.green elseif DB.gpm>400 then rating,rC="B",C.yellow
            elseif DB.gpm>300 then rating,rC="C",C.orange else rating,rC="D",C.red end
            dText(10,rating,sx2+secW-sc(26),dy-sc(1),rC)
            dy=dy+sc(16); dText(9,L("nw")..":"..fN(DB.nw),sx2+sc(6),dy,C.gold)
            dy=dy+sc(16); dLine(sx2+sc(4),dy,sx2+secW-sc(8),dy,colA(C.accent,40)); dy=dy+sc(4)
            local mc2 = DB.momentum>20 and C.green or (DB.momentum<-20 and C.red or C.gray)
            dText(9,L("momentum"),sx2+sc(6),dy,C.gray)
            dText(10,(DB.momentum>0 and "+" or "")..F(DB.momentum),sx2+sc(68),dy-sc(1),mc2)
            dy=dy+sc(14)
            local mbW = secW - sc(16)
            dRect(sx2+sc(4),dy,mbW,sc(7),col(0,0,0,100),sc(3))
            dLine(sx2+sc(4)+mbW/2,dy,sx2+sc(4)+mbW/2,dy+sc(7),C.dark)
            local pct = (DB.momentum+100)/200; local fw = math.abs(pct-0.5)*mbW
            local fx = pct>0.5 and (sx2+sc(4)+mbW/2) or (sx2+sc(4)+mbW/2-fw)
            dRect(fx,dy,fw,sc(7),mc2,sc(3))
            dy=dy+sc(12)
            dText(8,L("win")..":"..F(DB.winProb).."%",sx2+sc(6),dy,DB.winProb>55 and C.green or (DB.winProb<45 and C.red or C.text))
            dText(8,L("alive")..":"..EC.aliveAllies..L("vs")..EC.aliveEnemies,sx2+sc(78),dy,C.text)
        end

        -- Section 3: Power Graph
        if showPower then
            local sx3, secW = nextBrainCol()
            dRect(sx3, y, secW-sc(4), h, C.bg_section, sc(6))
            dText(10, L("power"):upper(), sx3+sc(8), y+sc(4), C.purple)
            if #PG.ally >= 2 then
                local gy=y+sc(20); local gh=h-sc(26); local gw=secW-sc(16)
                dRect(sx3+sc(4),gy,gw,gh,col(0,0,0,50),sc(4))
                local mx=1
                for _,pt in ipairs(PG.ally) do mx=math.max(mx,pt.v) end
                for _,pt in ipairs(PG.enemy) do mx=math.max(mx,pt.v) end
                for i2=1,3 do dLine(sx3+sc(4),gy+gh*i2/4,sx3+sc(4)+gw,gy+gh*i2/4,col(50,55,70,60)) end
                local function drawG(hist,c2) if #hist<2 then return end
                    for j=2,#hist do dLine(sx3+sc(4)+(j-2)/(#hist-1)*gw,gy+gh-(hist[j-1].v/mx)*gh,
                        sx3+sc(4)+(j-1)/(#hist-1)*gw,gy+gh-(hist[j].v/mx)*gh,c2) end end
                drawG(PG.ally,colA(C.accent,200)); drawG(PG.enemy,colA(C.red,200))
                dCircle(sx3+sc(10),gy+gh+sc(8),sc(3),C.accent); dText(7,L("us"),sx3+sc(16),gy+gh+sc(4),C.gray)
                dCircle(sx3+sc(45),gy+gh+sc(8),sc(3),C.red); dText(7,L("them"),sx3+sc(51),gy+gh+sc(4),C.gray)
            else dText(9,fN(DB.allyPow).." "..L("vs").." "..fN(DB.enemyPow),sx3+sc(12),y+sc(55),C.text) end
        end

        -- Section 4: Tips + Map Control
        if showTips then
            local sx4, tipW = nextBrainCol()
            dRect(sx4, y, tipW, h, C.bg_section, sc(6))
            dText(10, L("tips"):upper(), sx4+sc(8), y+sc(4), C.yellow)
            local ty = y + sc(20)
        -- Fight tips
            for _,tip in ipairs(DB.tips) do if ty+sc(14)>y+h then break end; dText(9,tip.t,sx4+sc(6),ty,tip.c); ty=ty+sc(14) end
        -- Map Control safe farm (compact)
            if ui.map_enable:Get() and ui.map_safe_farm:Get() and #MAP.safeFarm > 0 then
                ty = ty + sc(4)
                dLine(sx4+sc(4),ty,sx4+tipW-sc(8),ty,colA(C.cyan,40)); ty=ty+sc(4)
                dText(8,L("safe_farm"):upper(),sx4+sc(6),ty,C.cyan); ty=ty+sc(12)
                for i,a in ipairs(MAP.safeFarm) do
                    if i > 4 or ty+sc(12) > y+h then break end
                    local sc2 = dangerColor(1-a.safety)
                    dText(8,a.name,sx4+sc(6),ty,C.text)
                    dBar(sx4+sc(55),ty+sc(1),sc(40),sc(6),a.safety,sc2,nil,sc(2))
                    dText(7,F(a.safety*100).."%",sx4+sc(100),ty,sc2)
                    ty=ty+sc(12)
                end
            end
        -- Split advice
            if ui.map_split:Get() and MAP.splitAdvice ~= "" then
                ty = math.min(ty+sc(4), y+h-sc(14))
                dText(8,MAP.splitAdvice,sx4+sc(6),ty,C.yellow)
            end
            if MAP.rune and MAP.rune.state and MAP.rune.state ~= "" then
                ty = math.min(ty+sc(12), y+h-sc(14))
                local rc = (MAP.rune.state=="FREE" and C.green) or (MAP.rune.state=="CONTEST" and C.yellow) or C.orange
                local rTxt = "Rune "..MAP.rune.state
                if (MAP.rune.etaUs or 0) > 0 then rTxt = rTxt .. " "..string.format("%.1fs", MAP.rune.etaUs) end
                dText(8, rTxt, sx4+sc(6), ty, rc)
            end
            if MAP.rosh and (MAP.rosh.suspicion or 0) > 0 then
                ty = math.min(ty+sc(12), y+h-sc(14))
                local rc = (MAP.rosh.suspicion >= 35) and C.orange or C.gray
                dText(8, "Rosh suspect "..F(MAP.rosh.suspicion), sx4+sc(6), ty, rc)
            end
            if MAP.rotations and #MAP.rotations > 0 then
                ty = math.min(ty+sc(12), y+h-sc(14))
                local r = MAP.rotations[1]
                dText(8, "Rotate: "..tostring(r.name).." "..F(r.conf).."%", sx4+sc(6), ty, C.cyan)
            end
        -- Respawn info
            local ry = y + h - sc(18); local deadC = 0
            for _,e in ipairs(EC.enemies) do if not nA(e) then
                if deadC==0 then dText(8,L("respawning")..": "..hName(e).." ~"..(getHeroLevel(e)*2+4)..L("s"),sx4+sc(6),ry,C.red) end
                deadC=deadC+1 end end
            if deadC>1 then dText(7,"+"..deadC-1,sx4+tipW-sc(22),ry,C.gray) end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- PANEL 2: INTEL — Combo + Target + Initiation
    -- ═══════════════════════════════════════════════════════════════
    panels.intel = mkPanel("intel", 10, 295, 580, 130, L("intel"), C.orange, 300, 60)
    panels.intel.compactFactor = 0.82
    panels.intel.compactMinH = sc(64)
    panels.intel.minHFn = function(p, pw)
        local w = pw or p.w or 0
        local stacked = (w < sc(430)) or (uiPanelCompactMode(p) == true)
        local comboEnabled = uiGetVal(ui and ui.combo, false) and EC.heroAlive and #((EC and EC.heroAbilities) or {}) > 0
        local targetEnabled = uiGetVal(ui and ui.hud_target, true)
        local base = (p.headerH or sc(28)) + sc(20)
        local msgRows = (uiGetVal(ui and ui.tempo_messages, true) and #TEMPO.messages > 0) and math.min(#TEMPO.messages, stacked and 2 or 3) or 0
        local msgH = msgRows > 0 and (msgRows * sc(14) + sc(8)) or 0
        local sectionH = 0
        if stacked then
            if comboEnabled then sectionH = sectionH + sc(118) end
            if targetEnabled then sectionH = sectionH + sc(86) + (comboEnabled and sc(8) or 0) end
            if (uiGetVal(ui and ui.ini, true) and INI.bestPos and INI.count>=uiGetVal(ui and ui.ini_min, 2)) then sectionH = sectionH + sc(18) end
            return base + math.max(sc(42), sectionH) + msgH
        end
        local rowBase = (comboEnabled or targetEnabled) and (w < sc(560) and sc(92) or sc(72)) or sc(24)
        local initPad = (uiGetVal(ui and ui.ini, true) and INI.bestPos and INI.count>=uiGetVal(ui and ui.ini_min, 2)) and sc(20) or sc(8)
        return base + rowBase + initPad + msgH
    end
    panels.intel.icon = UI_ASSETS.icons.intel
    panels.intel.drawContent = function(self, x, y, w, ch)
        local td = EC.targetData
        local narrow = w < sc(430)
        local stackMode = self.compact or narrow or (w < sc(520) and ch > sc(88))
        local comboEnabled = ui.combo:Get() and EC.heroAlive and #EC.heroAbilities > 0
        local targetEnabled = ui.hud_target:Get()
        local msgCount = (ui.tempo_messages:Get() and #TEMPO.messages > 0) and math.min(#TEMPO.messages, stackMode and 2 or 3) or 0
        local tempoReserve = (msgCount > 0) and (sc(14) * msgCount + sc(4)) or 0
        local contentBottom = y + ch - tempoReserve

        local function fitTxt(sz, s, maxW)
            s = tostring(s or "")
            if maxW <= sc(18) then return "" end
            if tW(sz, s) <= maxW then return s end
            local cut = s
            if utf8 and utf8.len and utf8.offset then
                local okLen, ulen = pcall(utf8.len, cut)
                if okLen and ulen then
                    while ulen > 1 and tW(sz, cut .. "..") > maxW do
                        ulen = ulen - 1
                        local okOff, off = pcall(utf8.offset, cut, ulen + 1)
                        if not okOff or not off then break end
                        cut = cut:sub(1, off - 1)
                    end
                    return cut .. ".."
                end
            end
            while #cut > 1 and tW(sz, cut .. "..") > maxW do cut = cut:sub(1, -2) end
            return cut .. ".."
        end

        local function drawComboBlock(ax, ay, aw, yLimit, noInnerTitle)
            if not (ui.combo:Get() and EC.heroAlive and #EC.heroAbilities > 0) then return 0 end
            local top = ay
            local rowH = sc(18)
            local rowGap = sc(3)
            local comboLabel = L("combo"):upper()
            local labelPad = noInnerTitle and 0 or clamp(tW(10, comboLabel) + sc(10), sc(42), math.max(sc(42), aw - sc(50)))
            local tagX0 = ax + labelPad
            local totalD, totalM, totalC = 0, 0, 0
            local allRdy = true
            for _,ab in ipairs(EC.heroAbilities) do
                totalD = totalD + (ab.damage or 0)
                totalM = totalM + (ab.manaCost or 0)
                totalC = totalC + (ab.castPoint or 0)
                if (not ab.ready) or ((ab.manaCost or 0) > (EC.heroMana or 0)) then allRdy = false end
            end

            local stT, stC
            if allRdy and totalM <= (EC.heroMana or 0) then stT,stC=L("ready"),C.cb_ok
            elseif not allRdy then stT,stC=L("on_cd"),C.cb_cd else stT,stC=L("no_mana"),C.cb_mana end
            local stW = tW(8, stT) + sc(10)
            local statusInline = aw >= sc(210)
            local comboViewMode = uiGetVal(ui and ui.combo_view, 2) or 2 -- 0 icons, 1 text, 2 mixed
            local comboChipOverlay = uiGetVal(ui and ui.combo_cd_ov, true)
            local comboTipEnabled = uiGetVal(ui and ui.combo_tip, true)

            if not noInnerTitle then
                dText(10, comboLabel, ax, ay, C.orange)
            end
            if statusInline then
                local sx = ax + aw - stW
                dRect(sx, ay, stW, rowH, colA(stC, 30), sc(4))
                dText(8, stT, sx + sc(5), ay + sc(3), stC)
            end

            local maxX = ax + aw - sc(2) - (statusInline and (stW + sc(4)) or 0)
            local tx, ty2 = tagX0, ay
            for _,ab in ipairs(EC.heroAbilities) do
                local c2 = C.cb_ok
                if not ab.ready then c2 = C.cb_cd
                elseif (ab.manaCost or 0) > (EC.heroMana or 0) then c2 = C.cb_mana end
                local short = tostring(ab.short or "?")
                local iconH = getSpellIconHandle(ab.name or ab.n or "")
                local useIcon = (comboViewMode ~= 1) and (iconH ~= nil)
                local useText = (comboViewMode == 1) or (not useIcon) or (comboViewMode == 2)
                local bw
                if useIcon and useText then
                    bw = rowH + sc(3) + tW(8, short) + sc(8)
                elseif useIcon then
                    bw = rowH
                else
                    bw = tW(8, short) + sc(10)
                end
                if tx + bw > maxX and tx > tagX0 then
                    tx = tagX0
                    ty2 = ty2 + rowH + sc(2)
                end
                if yLimit and (ty2 + rowH > yLimit - sc(12)) then break end
                dRect(tx, ty2, bw, rowH, colA(c2,25), sc(4))
                dBorder(tx, ty2, bw, rowH, colA(c2,100), sc(4))
                local iconX = tx + sc(2)
                local iconY = ty2 + sc(2)
                local iconSz = rowH - sc(4)
                if useIcon then
                    dImage(iconH, iconX, iconY, iconSz, iconSz, 255, sc(3))
                    if comboChipOverlay then
                        local cdNow = math.max(0, tonumber(ab.cd or 0) or 0)
                        local noMana = ((ab.manaCost or 0) > (EC.heroMana or 0))
                        if (not ab.ready) and cdNow > 0.05 then
                            dRect(iconX, iconY, iconSz, iconSz, col(0,0,0,120), sc(3))
                            local cdTxt = (cdNow < 10) and string.format("%.1f", cdNow) or tostring(F(cdNow))
                            local tw = tW(6, cdTxt)
                            dRect(iconX + iconSz - tw - sc(4), iconY + iconSz - sc(8), tw + sc(3), sc(8), col(0,0,0,195), sc(2))
                            dText(6, cdTxt, iconX + iconSz - tw - sc(2), iconY + iconSz - sc(8), C.white)
                        elseif noMana then
                            dRect(iconX, iconY + iconSz - sc(8), iconSz, sc(8), colA(C.mana, 80), sc(2))
                            dText(6, "M", iconX + iconSz/2 - tW(6, "M")/2, iconY + iconSz - sc(8), C.white)
                        elseif ab.ready then
                            dRect(iconX + iconSz - sc(5), iconY + sc(1), sc(4), sc(4), colA(C.cb_ok, 180), sc(2))
                        end
                    end
                end
                if useText then
                    local textX = useIcon and (tx + rowH + sc(1)) or (tx + sc(5))
                    local textY = ty2 + sc(3)
                    local textMaxW = math.max(sc(10), tx + bw - textX - sc(2))
                    local drawShort = short
                    while tW(8, drawShort) > textMaxW and #drawShort > 1 do drawShort = drawShort:sub(1, -2) end
                    dText(8, drawShort, textX, textY, c2)
                end
                if comboTipEnabled and inRect(mouse.x, mouse.y, tx, ty2, bw, rowH) then
                    UI_ASSETS.comboTip = UI_ASSETS.comboTip or {}
                    local nmFull = tostring(ab.name or short or "?")
                    local ttl = nmFull:gsub("^.*_", ""):gsub("_", " ")
                    if ttl == "" then ttl = nmFull end
                    local cdTxt = (ab.ready and (ab.cd or 0) <= 0.05) and L("ready") or (string.format("%.1fs", math.max(0, ab.cd or 0)))
                    local l2 = "Lv"..tostring(ab.level or 0).."  CD:"..cdTxt
                    local l3 = L("mana_word")..":"..F(ab.manaCost or 0).."  "..L("damage")..":"..F(ab.damage or 0)
                    UI_ASSETS.comboTip.x = mouse.x + sc(12)
                    UI_ASSETS.comboTip.y = mouse.y + sc(12)
                    UI_ASSETS.comboTip.title = ttl
                    UI_ASSETS.comboTip.line2 = l2
                    UI_ASSETS.comboTip.line3 = l3
                    UI_ASSETS.comboTip.col = c2
                end
                tx = tx + bw + rowGap
            end

            if not statusInline then
                local sy = ty2 + rowH + sc(2)
                local sx = ax
                dRect(sx, sy, stW, rowH, colA(stC, 30), sc(4))
                dText(8, stT, sx + sc(5), sy + sc(3), stC)
                ty2 = sy
            end

            local infoY = math.max(ay + rowH + sc(4), ty2 + rowH + sc(4))
            local manaPct = ((EC.heroMaxMana or 0) > 0) and ((EC.heroMana or 0) / EC.heroMaxMana) or 0
            if aw < sc(330) then
                local line1 = {}
                if ui.combo_dmg:Get() and totalD > 0 then line1[#line1+1] = L("damage")..":"..fN(totalD) end
                if ui.combo_mana:Get() then line1[#line1+1] = L("mana_word")..":"..F(EC.heroMana or 0).."/"..F(totalM) end
                dText(8, table.concat(line1, "  "), ax, infoY, C.gray)
                infoY = infoY + sc(12)
                if aw > sc(90) then
                    dBar(ax, infoY + sc(1), math.max(sc(50), aw - sc(4)), sc(7), manaPct, C.mana, C.mana_bg, sc(3))
                    infoY = infoY + sc(10)
                end
            else
                if ui.combo_dmg:Get() and totalD > 0 then dText(8, L("damage")..":"..fN(totalD), ax, infoY, C.gray) end
                if ui.combo_mana:Get() then
                    local mTxt = L("mana_word")..":"..F(EC.heroMana or 0).."/"..F(totalM)
                    local mx = ax + math.min(sc(100), math.max(sc(70), aw * 0.34))
                    dText(8, mTxt, mx, infoY, C.gray)
                end
                local barW = clamp(F(aw * 0.23), sc(56), sc(110))
                local barX = ax + aw - barW
                dBar(barX, infoY + sc(1), barW, sc(7), manaPct, C.mana, C.mana_bg, sc(3))
                infoY = infoY + sc(12)
            end
            return math.max(sc(24), infoY - top + sc(2))
        end

        local function drawItemBadges(ix, iy, maxW, items, yLimit)
            if not items or #items == 0 then return 0 end
            local x0, curX, curY = ix, ix, iy
            local rowH = sc(14)
            local drawn = 0
            for j,it in ipairs(items) do
                if j > 8 then break end
                local iw = tW(7, it.s) + sc(8)
                if curX + iw > x0 + maxW and curX > x0 then
                    curX = x0
                    curY = curY + rowH + sc(2)
                end
                if yLimit and (curY + rowH > yLimit - sc(2)) then break end
                dRect(curX, curY, iw, rowH, it.rdy and colA(it.c,25) or col(0,0,0,40), sc(3))
                dText(7, it.s, curX + sc(4), curY + sc(1), it.rdy and it.c or C.dark)
                curX = curX + iw + sc(2)
                drawn = curY + rowH - iy
            end
            return math.max(0, drawn)
        end

        local function drawTargetBlock(ax, ay, aw, yLimit)
            local top = ay
            if not ui.hud_target:Get() then return 0 end
            if not (td and td.valid) then
                dText(9, L("no_target"), ax + sc(2), ay + sc(2), C.gray)
                return sc(20)
            end

            local tIcon = EC.currentTarget and getHeroIconHandle(EC.currentTarget) or nil
            local lvlTxt = "Lv"..tostring(td.level or 0)
            local lvlW = tW(8, lvlTxt)
            local iconPad = tIcon and sc(18) or 0
            local nameMaxW = math.max(sc(40), aw - lvlW - iconPad - sc(8))
            if tIcon then dImage(tIcon, ax, ay+sc(1), sc(14), sc(14), 240, sc(3)) end
            dText(10, fitTxt(10, td.name or "?", nameMaxW), ax + iconPad, ay, C.gold)
            dText(8, lvlTxt, ax + aw - lvlW, ay + sc(2), C.gray)

            local barW = math.max(sc(70), aw)
            local hpPct = ((td.maxHp or 0) > 0) and ((td.hp or 0) / td.maxHp) or 0
            local mpPct = ((td.maxMana or 0) > 0) and ((td.mana or 0) / td.maxMana) or 0
            dBar(ax, ay+sc(16), barW, sc(10), hpPct, C.hp, C.hp_bg, sc(3))
            local ht = F(td.hp or 0).."/"..F(td.maxHp or 0)
            dText(7, fitTxt(7, ht, barW - sc(8)), ax + sc(4), ay + sc(17), C.white)
            dBar(ax, ay+sc(28), barW, sc(8), mpPct, C.mana, C.mana_bg, sc(3))

            local curY = ay + sc(40)
            if EC.currentTarget then
                local kd = calcKill(EC.hero, EC.currentTarget)
                if kd then
                    local kC = killColor(kd.killChance)
                    dText(9, "Kill:"..kd.killChance.."%", ax, curY, kC)
                    local ttkTxt = (kd.timeToKill and kd.timeToKill < 99) and string.format(" ttk %.1fs", kd.timeToKill) or ""
                    local dmgTxt = fN(kd.totalDmg).."dmg "..kd.hitsToKill.."h"..ttkTxt
                    if aw < sc(260) then
                        curY = curY + sc(11)
                        dText(7, fitTxt(7, dmgTxt, aw), ax, curY, C.gray)
                    else
                        dText(8, fitTxt(8, dmgTxt, aw - sc(78)), ax+sc(78), curY+sc(1), C.gray)
                    end
                    if kd.flags and kd.flags ~= "" then
                        curY = curY + sc(12)
                        dText(7, fitTxt(7, kd.flags, aw), ax, curY, C.orange)
                    end
                end
            end

            if td.items and #td.items > 0 then
                curY = curY + sc(13)
                local used = drawItemBadges(ax, curY, aw, td.items, yLimit)
                curY = curY + used
            end
            return math.max(sc(34), curY - top + sc(2))
        end

        local baseY = y
        local gapY = sc(6)
        local usedH = 0

        if stackMode then
            local cy = baseY
            if comboEnabled and cy < contentBottom - sc(10) then
                local cardH = math.max(sc(58), math.min(contentBottom - cy, sc(112)))
                local abCount = #EC.heroAbilities
                if abCount > 7 then
                    local extraRows = math.ceil((abCount - 7) / 4)
                    cardH = math.min(contentBottom - cy, cardH + extraRows * sc(18))
                end
                if cardH > sc(24) then
                    dCard(x, cy, w, cardH, C.orange, L("combo"):upper(), C.orange)
                    local cx, cy2, cw, ch2 = cardContentRect(x, cy, w, cardH, true)
                    local comboH = drawComboBlock(cx, cy2, cw, cy + cardH - sc(4), true)
                    cy = cy + math.max(cardH, comboH + sc(20))
                end
            end
            if targetEnabled and cy < contentBottom - sc(10) then
                if cy > baseY then drawSep(x, cy + sc(1), w); cy = cy + gapY end
                local rem = math.max(sc(42), contentBottom - cy)
                dCard(x, cy, w, rem, C.cyan, "TARGET", C.cyan)
                local tx, ty2, tw2, th2 = cardContentRect(x, cy, w, rem, true)
                local targetH = drawTargetBlock(tx, ty2, tw2, cy + rem - sc(4))
                cy = cy + math.max(sc(54), math.min(rem, targetH + sc(20)))
            end
            usedH = cy - baseY
        else
            local rowH = math.max(sc(72), contentBottom - baseY)
            if comboEnabled and targetEnabled then
                local leftW = clamp(F(w * 0.47), sc(150), w - sc(150))
                local gapX = sc(8)
                local rightW = math.max(sc(120), w - leftW - gapX)
                dCard(x, baseY, leftW, rowH, C.orange, L("combo"):upper(), C.orange)
                local cx, cy2, cw, ch2 = cardContentRect(x, baseY, leftW, rowH, true)
                local leftH = drawComboBlock(cx, cy2, cw, baseY + rowH - sc(4), true)
                local rx = x + leftW + gapX
                dCard(rx, baseY, rightW, rowH, C.cyan, "TARGET", C.cyan)
                local tx, ty2, tw2, th2 = cardContentRect(rx, baseY, rightW, rowH, true)
                local rightH = drawTargetBlock(tx, ty2, tw2, baseY + rowH - sc(4))
                usedH = math.max(leftH, rightH)
            elseif comboEnabled then
                dCard(x, baseY, w, rowH, C.orange, L("combo"):upper(), C.orange)
                local cx, cy2, cw, ch2 = cardContentRect(x, baseY, w, rowH, true)
                usedH = drawComboBlock(cx, cy2, cw, baseY + rowH - sc(4), true)
            elseif targetEnabled then
                dCard(x, baseY, w, rowH, C.cyan, "TARGET", C.cyan)
                local tx, ty2, tw2, th2 = cardContentRect(x, baseY, w, rowH, true)
                usedH = drawTargetBlock(tx, ty2, tw2, baseY + rowH - sc(4))
            else
                usedH = 0
            end
        end

        -- Initiation line (responsive)
        if ui.ini:Get() and INI.bestPos and INI.count>=ui.ini_min:Get() then
            local iy = math.min(contentBottom - sc(14), baseY + usedH + sc(4))
            if iy >= baseY and iy + sc(10) <= contentBottom then
                local initTxt
                if w < sc(430) then
                    initTxt = string.format("%s: %dE  S:%d  +%dA  R:%d",
                        L("initiation"):upper(), INI.count or 0, INI.bestScore or 0, (INI.follow or 0), F(INI.risk or 0))
                else
                    initTxt = L("initiation"):upper()..": "..INI.count.." "..L("enemies").." | "..L("score")..":"..INI.bestScore..
                        " | +"..(INI.follow or 0).."A | R:"..F(INI.risk or 0)
                end
                dText(9, fitTxt(9, initTxt, w), x, iy, (INI.bestScore or 0) > 50 and C.green or C.yellow)
            end
        end

        -- Tempo messages (compact log at bottom)
        if msgCount > 0 then
            local ty = y + ch - sc(14) * msgCount
            local gt = sN(GameRules.GetGameTime)
            for i = math.max(1, #TEMPO.messages - (msgCount - 1)), #TEMPO.messages do
                local m = TEMPO.messages[i]
                if m then
                    local age = gt - m.time
                    local alpha = age > (m.dur - 2) and clamp(1-(age-m.dur+2)/2, 0, 1) or 1
                    dText(8, fitTxt(8, m.text, w), x, ty, colA(m.col, F(alpha*255)))
                    ty = ty + sc(14)
                end
            end
        end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- PANEL 3: TRACKER — Enemy Items + Spells (combined)
    -- ═══════════════════════════════════════════════════════════════
    panels.tracker = mkPanel("tracker", 10, 440, 560, 170, L("tracker"), C.purple, 300, 70)
    panels.tracker.compactFactor = 0.68
    panels.tracker.compactMinH = sc(70)
    panels.tracker.minHFn = function(p, pw)
        local w = pw or p.w or 0
        local visibleRows = (w < sc(380)) and 3 or (w < sc(520) and 4 or 5)
        return (p.headerH or sc(28)) + sc(18) + visibleRows * sc(34)
    end
    panels.tracker.icon = UI_ASSETS.icons.tracker
    panels.tracker.drawContent = function(self, x, y, w, ch)
        local rowH = (w < sc(380)) and sc(34) or sc(30)
        local ey = y
        local drawItems = ui.ih:Get() and ui.ih_pan:Get()
        local drawSpells = ui.sp:Get() and ui.sp_pan:Get()
        local function chipWrap(ix, iy, maxW, arr, kind)
            local curX, curY = ix, iy
            local x0 = ix
            local drawnH = sc(12)
            local count = 0
            local iconSz = sc(12)
            for _,it in ipairs(arr or {}) do
                if count >= 8 then break end
                local txt = tostring(it.s or "?")
                local colMain
                local fillAlpha = 20
                if kind == "item" then
                    colMain = it.rdy and (it.c or C.gray) or C.dark
                    fillAlpha = it.rdy and 22 or 14
                else
                    colMain = (it.rdy and ((it.ult and C.gold) or C.cb_ok)) or C.cb_cd
                    fillAlpha = it.rdy and 20 or 14
                end
                local iconH = nil
                if kind == "item" then
                    iconH = getItemIconHandle(it.n)
                else
                    iconH = getSpellIconHandle(it.n)
                end
                local useIcon = (iconH ~= nil and iconH ~= 0)
                local cw = useIcon and (iconSz + sc(4)) or (tW(7, txt) + sc(8))
                if curX + cw > x0 + maxW and curX > x0 then
                    curX = x0
                    curY = curY + sc(14)
                end
                if curY + sc(12) > iy + rowH - sc(2) then break end
                dRect(curX, curY, cw, sc(12), colA(colMain, fillAlpha), sc(3))
                dBorder(curX, curY, cw, sc(12), colA(colMain, 70), sc(3))
                if useIcon then
                    dImage(iconH, curX+sc(1), curY+sc(1), iconSz, iconSz, it.rdy and 245 or 150, sc(2))
                    if not it.rdy then
                        dRect(curX+sc(1), curY+sc(1), iconSz, iconSz, col(0,0,0,90), sc(2))
                    end
                else
                    dText(7, txt, curX+sc(4), curY, colMain)
                end
                if not it.rdy and (it.cd or 0) > 0 and (kind == "item" and ui.ih_cd:Get() or kind == "spell") then
                    local cdTxt = tostring(F(it.cd))
                    local cdW = tW(6, cdTxt)
                    dText(6, cdTxt, curX+cw-cdW-sc(1), curY+sc(6), C.red)
                end
                curX = curX + cw + sc(2)
                drawnH = (curY - iy) + sc(14)
                count = count + 1
            end
            return drawnH
        end

        if not drawItems and not drawSpells then
            dText(9, L("no_items"), x+sc(6), y+sc(8), C.gray)
            return
        end

        for _, e in ipairs(EC.enemies) do
            if ey + rowH > y + ch then break end
            local idx = nI(e); if not idx then goto ct end
            local items = drawItems and (EC.enItems[idx] or {}) or {}
            local spells = drawSpells and (EC.enSpells[idx] or {}) or {}
            if #items == 0 and #spells == 0 then goto ct end
            local alive = nA(e)
            dCard(x, ey, w, rowH-sc(2), C.purple, nil, C.purple)
            dRect(x+sc(1), ey+sc(1), sc(2), rowH-sc(4), alive and colA(C.purple, 120) or colA(C.gray, 60), sc(2))
            local nameX = x + sc(6)
            local hIcon = getHeroIconHandle(e)
            if hIcon then
                dImage(hIcon, nameX, ey+sc(3), sc(14), sc(14), 230, sc(3))
                nameX = nameX + sc(18)
            end
            local heroTxt = hName(e)
            local nameMaxW = math.max(sc(42), w * 0.28)
            local hvTxt = heroTxt
            while tW(9, hvTxt) > nameMaxW and #hvTxt > 2 do hvTxt = hvTxt:sub(1, -2) end
            if hvTxt ~= heroTxt then hvTxt = hvTxt .. "." end
            dText(9, hvTxt, nameX, ey+sc(4), alive and C.text or C.dark)

            local laneX = x + math.max(sc(84), F(w * 0.30))
            local laneW = w - (laneX - x) - sc(6)
            local chipY = ey + sc(4)
            local leftKindW = sc(14)
            if drawItems and #items > 0 then
                dText(6, "I", laneX, chipY+sc(1), C.gray)
                local used = chipWrap(laneX + leftKindW, chipY, math.max(sc(40), laneW - leftKindW), items, "item")
                chipY = chipY + math.max(sc(14), used)
            end
            if drawSpells and #spells > 0 and chipY < ey + rowH - sc(10) then
                if drawItems and #items > 0 then chipY = chipY + sc(1) end
                dText(6, "S", laneX, chipY+sc(1), C.gray)
                chipWrap(laneX + leftKindW, chipY, math.max(sc(40), laneW - leftKindW), spells, "spell")
            end

            ey = ey + rowH
            ::ct::
        end
        if ey == y then dText(9,L("no_items"),x+sc(6),y+sc(8),C.gray) end
    end

    -- ═══════════════════════════════════════════════════════════════
    -- PANEL 4: SIDEBAR — Hero Info + Timers + Farm Dashboard
    -- ═══════════════════════════════════════════════════════════════
    panels.sidebar = mkPanel("sidebar", SW-290, 60, 280, 450, L("sidebar"), C.cyan, 240, 150)
    panels.sidebar.compactFactor = 0.60
    panels.sidebar.compactMinH = sc(120)
    panels.sidebar.icon = UI_ASSETS.icons.sidebar
    panels.sidebar.drawContent = function(self, x, y, w, ch)
        local cy = y
        local rh = sc(16)

        -- Hero Info section
        if ui.hud_info:Get() and EC.heroAlive then
            dText(12, EC.heroName, x, cy, C.white)
            local lt="Lv"..EC.heroLevel; local lw=tW(10,lt)
            dRect(x+w-lw-sc(10),cy,lw+sc(8),sc(16),colA(C.accent,30),sc(4))
            dText(10,lt,x+w-lw-sc(6),cy+sc(1),C.accent); cy=cy+sc(20)
            -- HP/Mana bars
            dBar(x,cy,w,sc(12),EC.heroHP/EC.heroMaxHP,C.hp,C.hp_bg,sc(3))
            local ht=F(EC.heroHP).."/"..F(EC.heroMaxHP); dText(7,ht,x+w/2-tW(7,ht)/2,cy+sc(1),C.white)
            cy=cy+sc(14)
            dBar(x,cy,w,sc(10),EC.heroMana/EC.heroMaxMana,C.mana,C.mana_bg,sc(3))
            local mt=F(EC.heroMana).."/"..F(EC.heroMaxMana); dText(7,mt,x+w/2-tW(7,mt)/2,cy,C.white)
            cy=cy+sc(14)
            -- Stats
            drawSep(x,cy,w); cy=cy+sc(4)
            do
                local aMain = tonumber(EC.heroArmorMain or EC.heroArmor or 0) or 0
                local aBonus = tonumber(EC.heroArmorBonus or 0) or 0
                local hasBonus = math.abs(aBonus) >= 0.05
                if hasBonus then
                    dText(9, L("armor"), x, cy, C.stat_label)
                    local bonusTxt = string.format("%+.1f", aBonus)
                    local mainTxt = string.format("%.1f", aMain)
                    local bw = tW(10, bonusTxt)
                    local mw = tW(10, mainTxt)
                    local bx = x + w - bw
                    local mx = bx - sc(4) - mw
                    dText(10, mainTxt, mx, cy, C.text)
                    dText(10, bonusTxt, bx, cy, aBonus >= 0 and C.green or C.red)
                    cy = cy + rh
                else
                    cy=cy+drawStatRow(x,cy,w,L("armor"),string.format("%.1f",EC.heroArmor),C.text,rh)
                end
            end
            cy=cy+drawStatRow(x,cy,w,L("attack_dmg"),F(EC.heroDmg),C.orange,rh)
            cy=cy+drawStatRow(x,cy,w,L("move_spd"),F(EC.heroMS),EC.heroMS>=400 and C.green or C.text,rh)
            cy=cy+sc(4)
        end

        -- Timers section
        if ui.hud_timers:Get() then
            drawSep(x,cy,w); cy=cy+sc(6)
            local dt = sN(GameRules.GetDOTATime)
            -- Game time
            dRect(x,cy,w,sc(18),C.bg_section,sc(4))
            dText(9,L("game_time"),x+sc(6),cy+sc(2),C.stat_label)
            local gt=fmtTime(dt); dText(10,gt,x+w-tW(10,gt)-sc(6),cy+sc(1),C.white)
            cy=cy+sc(22)
            -- Rune
            if ui.db_rune:Get() then
                local ttr=120-(dt%120)
                dText(9,L("rune"),x+sc(6),cy,ttr<=15 and C.green or C.yellow)
                dText(9,fmtTime(ttr),x+w-tW(9,fmtTime(ttr))-sc(6),cy,ttr<=15 and C.green or C.text)
                cy=cy+sc(16)
            end
            -- Stack
            if ui.db_stack:Get() then
                local tts=60-(dt%60); local ready=tts<=10
                dText(9,L("stack"),x+sc(6),cy,ready and C.green or C.cyan)
                dText(9,fmtTime(tts),x+w-tW(9,fmtTime(tts))-sc(6),cy,ready and C.green or C.text)
                if ready then dText(7,"NOW!",x+sc(60),cy+sc(1),col(45,255,90,F(180+math.sin(os.clock()*4)*75))) end
                cy=cy+sc(16)
            end
            -- Bounty
            local ttb=180-(dt%180)
            dText(9,L("bounty_rune"),x+sc(6),cy,C.gold)
            dText(9,fmtTime(ttb),x+w-tW(9,fmtTime(ttb))-sc(6),cy,ttb<=15 and C.green or C.text)
            cy=cy+sc(20)
        end

        -- Farm Dashboard section
        if ui.hud_farm:Get() then
            drawSep(x,cy,w); cy=cy+sc(6)
            dText(9,"FARM",x+sc(4),cy,C.gold); cy=cy+sc(14)
            local gc = FARM.gpm>500 and C.green or (FARM.gpm>300 and C.yellow or C.orange)
            cy=cy+drawStatRow(x,cy,w,L("gpm"),FARM.gpm,gc,rh)
            cy=cy+drawStatRow(x,cy,w,L("xpm"),FARM.xpm,C.cyan,rh)
            local cc = FARM.csMin>8 and C.green or (FARM.csMin>5 and C.yellow or C.red)
            cy=cy+drawStatRow(x,cy,w,L("cs_min"),FARM.csMin,cc,rh)
            -- Uptime bar
            dText(8,L("uptime"),x,cy,C.gray)
            dBar(x+sc(50),cy+sc(2),sc(80),sc(6),FARM.eff,FARM.eff>0.8 and C.green or C.yellow,nil,sc(3))
            dText(7,F(FARM.eff*100).."%",x+sc(135),cy,C.text)
            cy=cy+sc(14)
            -- Gold graph (mini)
            local keys={}; for k in pairs(FARM.goldHist) do keys[#keys+1]=k end; table.sort(keys)
            local ln=math.min(8,#keys)
            if ln >= 2 then
                local si=#keys-ln+1; local gw=w-sc(10); local gh=sc(22)
                local mx2,mn2=0,999999
                for i=si,#keys do local g=FARM.goldHist[keys[i]]; if g>mx2 then mx2=g end; if g<mn2 then mn2=g end end
                local rng=math.max(1,mx2-mn2)
                dRect(x,cy,gw,gh,col(20,20,30,150),sc(4))
                local pts={}
                for i=si,#keys do
                    local gi=i-si; local g=FARM.goldHist[keys[i]]
                    pts[#pts+1]={x=F(x+sc(4)+(gi/math.max(1,ln-1))*(gw-sc(8))),
                                 y=F(cy+gh-sc(4)-((g-mn2)/rng)*(gh-sc(8)))}
                end
                for i=2,#pts do dLine(pts[i-1].x,pts[i-1].y,pts[i].x,pts[i].y,C.gold) end
            end
            cy=cy+sc(28)
        end

        -- Debug section
        if ui.hud_debug:Get() and EC.heroPos then
            drawSep(x,cy,w); cy=cy+sc(6)
            dText(8,"DBG",x,cy,C.dark)
            dText(7,"X:"..F(EC.heroPos.x).." Y:"..F(EC.heroPos.y),x+sc(30),cy,C.dark)
            cy=cy+rh
            dText(7,EC.aliveAllies.."A "..EC.aliveEnemies.."E "..#EC.visEnemies.."V",x+sc(30),cy,C.dark)
            cy=cy+rh
            dText(7,"Threat:"..F(THREAT.nearScore).." Ev:"..#THREAT.events,x+sc(30),cy,C.dark)
            cy=cy+rh
            dText(7,"PSY:"..tostring((PSY.top and PSY.top.intent) or "-").." "..tostring((PSY.top and PSY.top.conf) or 0),x+sc(30),cy,C.dark)
            cy=cy+rh
            dText(7,"Q:"..#ACTQ.q.." Run:"..ACTQ.stats.ran.." Blk:"..GUARD.blocks,x+sc(30),cy,C.dark)
            cy=cy+rh
            dText(7,"Ping:"..F(latencySec()*1000).."ms",x+sc(30),cy,C.dark)
        end
    end

    if uiPanelSnapEnabled() then
        for _, p in ipairs(allPanels) do snapPanelNow(p) end
    end
    applyPanelManagerSettings()
    panelsInit = true
end

--------------------------------------------------------------------------------
-- UPDATERS
--------------------------------------------------------------------------------
function updKM(now)
    if not ui.km:Get() or now-KM.t<0.45 then return end
    KM.t=now; if not EC.heroAlive then return end
    KM.data,KM.rev={},{}
    for _,e in ipairs(EC.enemies) do
        local idx=nI(e); if idx then
            KM.data[idx]=calcKill(EC.hero,e)
            if ui.km_rev:Get() then KM.rev[idx]=calcKill(e,EC.hero) end
        end
    end
end

function updDB(now)
    if now-DB.t<0.7 then return end
    DB.t=now; if not EC.heroAlive then return end

    -- Keep MIA data fresh even if dashboard rendering is disabled.
    for _,e in ipairs(EC.enemies) do
        local idx=nI(e); if idx then
            if not DB.mia[idx] then DB.mia[idx]={lastSeen=now,visible=false,missTime=0,lastPos=nil} end
            local m=DB.mia[idx]
            if nA(e) and nV(e) then
                m.lastSeen=now; m.visible=true; m.missTime=0; m.lastPos=nP(e)
            else
                m.visible=false; m.missTime=now-m.lastSeen
                local lp = sG(Hero and Hero.GetLastMaphackPos or nil, e)
                if lp then m.lastPos = lp end
            end
        end
    end

    if not ui.db:Get() then return end

    local nw=sN(Player.GetNetworth, sG(Players.GetLocal))
    if nw<=0 then nw=F(sN(GameRules.GetGameTime)/60*200+EC.heroLevel*100) end
    DB.nw=nw
    if not DB.init then DB.startNW=nw; DB.startTime=now; DB.init=true; return end
    local elapsed=now-DB.startTime
    if elapsed>15 then DB.gpm=math.max(0,F((nw-DB.startNW)*60/elapsed)) end
    -- Poder de time considera HP atual (heroPower ja usa HP atual agora)
    local ap,ep=0,0
    for _,h in ipairs(EC.allies) do ap=ap+heroPower(h) end
    for _,h in ipairs(EC.enemies) do if nA(h) then ep=ep+heroPower(h) end end
    DB.allyPow,DB.enemyPow=ap,ep
    -- Momentum multi-fator: poder + vivos + torres
    local powRatio=(ep>0) and ((ap-ep)/math.max(1,ap+ep)*100) or 0
    local aliveDiff = (EC.aliveAllies-EC.aliveEnemies) * 18
    -- Torres: contar diferenca de torres como indicador de controle de mapa
    local towerAdv = (#(EC.allyTowers or {}) - #(EC.enemyTowers or {})) * 8
    DB.momentum=clamp(powRatio + aliveDiff + towerAdv, -100, 100)
    -- Win probability com mais fatores
    local winBase = 50 + DB.momentum * 0.35
    -- Networth advantage (GPM relativo)
    if DB.gpm > 0 then
        local expectedGPM = sN(GameRules.GetGameTime) > 0 and (nw / (sN(GameRules.GetGameTime) / 60)) or 0
        -- GPM acima de 500 = bom sinal
        winBase = winBase + clamp((expectedGPM - 400) * 0.01, -5, 5)
    end
    DB.winProb=clamp(F(winBase),5,95)
    if now-DB.lastTip<2 then return end
    DB.lastTip=now; DB.tips={}
    if ui.db_fight:Get() then
        if EC.deadEnemies>=2 and EC.aliveAllies>=3 then DB.tips[#DB.tips+1]={t=L("push").."!",c=C.green} end
        if EC.aliveEnemies>EC.aliveAllies+1 then DB.tips[#DB.tips+1]={t=L("retreat"),c=C.red} end
    end
    if ui.db_rune:Get() then
        local dt2=sN(GameRules.GetDOTATime); local ttr=120-(dt2%120)
        if ttr<=15 and ttr>12 then DB.tips[#DB.tips+1]={t=L("rune").." "..F(ttr)..L("s"),c=C.yellow} end
    end
    if ui.db_stack:Get() then
        local dt2=sN(GameRules.GetDOTATime)
        if dt2%60>=50 and dt2%60<=53 then DB.tips[#DB.tips+1]={t=L("stack").."! :50",c=C.cyan} end
    end
end

function updPG(now)
    if not ui.db_graph:Get() or now-PG.t<2.5 then return end
    PG.t=now; PG.ally[#PG.ally+1]={v=DB.allyPow}; PG.enemy[#PG.enemy+1]={v=DB.enemyPow}
    local ml=ui.db_graph_len:Get()
    while #PG.ally>ml do table.remove(PG.ally,1) end
    while #PG.enemy>ml do table.remove(PG.enemy,1) end
end

function updINI(now)
    if not ui.ini:Get() or now-INI.t<0.4 then return end
    INI.t=now
    if not EC.heroAlive or #EC.visEnemies<ui.ini_min:Get() then
        INI.bestPos=nil; INI.bestScore=0; INI.count=0; INI.risk=0; INI.follow=0; INI.label=""; return
    end

    local rad = 450
    local pts, uniq = {}, {}
    local cx, cy2, cz, cnt = 0, 0, 0, 0
    local enemies = {}
    for _, e in ipairs(EC.enemies) do
        if nA(e) then
            local idx = nI(e)
            local st = idx and PSY.enemies[idx] or nil
            local p2 = (st and st.predPos and st.conf >= 40 and st.predPos) or nP(e)
            if p2 then
                enemies[#enemies+1] = {e=e, p=p2, conf=(st and st.conf) or 0, vis=nV(e)}
                cx, cy2, cz, cnt = cx + p2.x, cy2 + p2.y, cz + (p2.z or 0), cnt + 1
                local k = F(p2.x/120)..":"..F(p2.y/120)
                if not uniq[k] then uniq[k]=true; pts[#pts+1]=p2 end
            end
        end
    end
    if cnt < ui.ini_min:Get() then INI.bestPos=nil; INI.count=0; return end

    local center = Vector(cx/cnt, cy2/cnt, cz/cnt)
    pts[#pts+1] = center
    for i = 1, #enemies do
        for j = i+1, math.min(i+4, #enemies) do
            local a, b = enemies[i].p, enemies[j].p
            if d2d(a,b) <= 1300 then
                pts[#pts+1] = Vector((a.x+b.x)/2, (a.y+b.y)/2, ((a.z or 0)+(b.z or 0))/2)
            end
        end
    end

    local best = nil
    for _, p in ipairs(pts) do
        local hit, weighted, tight = 0, 0, 0
        for _, ed in ipairs(enemies) do
            local d = d2d(p, ed.p)
            if d <= rad then
                hit = hit + 1
                local w = clamp(1 - d / rad, 0.15, 1)
                if ed.conf and ed.conf > 0 then w = w * clamp(0.65 + ed.conf/150, 0.65, 1.25) end
                weighted = weighted + w
                if d <= 280 then tight = tight + 1 end
            end
        end
        if hit >= ui.ini_min:Get() then
            local follow = math.max(0, countNPCsNear(p, 1150, "ally", true, false) - 1)
            local enemyFollow = countNPCsNear(p, 1150, "enemy", true, false)
            local travel = d2d(EC.heroPos, p)
            local pLen = sN(GridNav.FindPathLength, EC.heroPos, p)
            if pLen > 0 then travel = pLen end
            local blinkReady = hasAnyBlink(EC.hero)
            local risk = threatDangerAtPos(p)
            local towerRisk = 0
            local nearEnemyTower = nearestTowerDist(p, EC.enemyTowers)
            if nearEnemyTower < 850 then towerRisk = towerRisk + clamp((850-nearEnemyTower)/850,0,1) * 28 end
            local score = 0
            score = score + hit * 28 + F(weighted * 18) + tight * 10
            score = score + follow * 8 - math.max(0, enemyFollow - hit) * 4
            score = score - F((risk + towerRisk) * 0.55)
            score = score - F(travel / (blinkReady and 210 or 135))
            if blinkReady and travel <= 1300 then score = score + 14 end
            if GridNav and sG(GridNav.IsTraversable, p) == false then score = score - 999 end

            if not best or score > best.score then
                best = {pos=p, score=F(score), hit=hit, risk=F(risk + towerRisk), follow=follow, travel=F(travel)}
            end
        end
    end

    if not best then
        INI.bestPos=nil; INI.bestScore=0; INI.count=0; INI.risk=0; INI.follow=0; INI.travel=0; INI.label=""
        return
    end
    INI.radius = rad
    INI.bestPos = best.pos
    INI.bestScore = best.score
    INI.count = best.hit
    INI.risk = best.risk
    INI.follow = best.follow
    INI.travel = best.travel
    INI.label = (best.follow > 0 and ("+"..best.follow.." ally") or "solo") .. " | risk "..best.risk
end

-- ══════════════════════════════════════════════
-- MAP CONTROL UPDATER
-- ══════════════════════════════════════════════
function updMapControl(now)
    if not ui.map_enable:Get() or now-MAP.t<0.8 then return end
    MAP.t=now
    if not EC.heroAlive or not EC.heroPos then return end

    updPsycho(now)
    MAP.rune = getRuneObjective(now)
    MAP.rotations = {}
    local fwdPos = EC.heroPos
    local rot = sG(Entity.GetRotation, EC.hero)
    if rot and EC.heroPos then
        local yaw = rot:GetYaw() or 0
        local rad = math.rad(yaw)
        fwdPos = Vector(EC.heroPos.x + math.cos(rad)*850, EC.heroPos.y + math.sin(rad)*850, EC.heroPos.z or 0)
    end
    MAP.forwardRisk = threatDangerAtPos(fwdPos)
    MAP.rosh = {suspicion=0, reason=""}

    MAP.safeFarm = {}
    local campList = sG(Camps.GetAll) or {}
    local roshPos = getRoshanPosition()
    if roshPos then
        local sus = 0
        local reasons = {}
        for _, e in ipairs(EC.enemies) do
            local idx = nI(e)
            local st = idx and PSY.enemies[idx] or nil
            local ep = (st and (st.predPos or st.pos)) or nP(e)
            if nA(e) and ep then
                if d2d(ep, roshPos) < 1800 then
                    local c = (nV(e) and 20 or 10) + ((st and st.intent == "ROSH") and 18 or 0)
                    sus = sus + c
                    if #reasons < 2 then reasons[#reasons+1] = hName(e) end
                elseif st and st.intent == "ROSH" then
                    sus = sus + 12
                end
            end
        end
        MAP.rosh.suspicion = F(sus)
        if #reasons > 0 then
            MAP.rosh.reason = "near pit: "..table.concat(reasons, ", ")
        elseif sus > 0 then
            MAP.rosh.reason = "enemy patterns"
        end
    end

    for _, e in ipairs(EC.enemies) do
        local idx = nI(e)
        local st = idx and PSY.enemies[idx] or nil
        if st and st.intent == "ROTATE" and (st.conf or 0) >= 45 then
            MAP.rotations[#MAP.rotations+1] = {name=st.name or hName(e), conf=F(st.conf), pos=st.predPos or st.pos}
        end
    end
    table.sort(MAP.rotations, function(a,b) return (a.conf or 0) > (b.conf or 0) end)
    while #MAP.rotations > 3 do table.remove(MAP.rotations) end

    for _, fs in ipairs(getFarmSpots()) do
        local threat = 0
        local minD = 99999
        local traversable = (sG(GridNav.IsTraversable, fs.p) ~= false)
        local pathDist = d2d(EC.heroPos, fs.p)
        local pLen = sN(GridNav.FindPathLength, EC.heroPos, fs.p)
        if pLen > 0 then pathDist = pLen end
        local visibleToUs = FogOfWar and sG(FogOfWar.IsPointVisible, fs.p)

        for _, e in ipairs(EC.enemies) do
            if nA(e) then
                local idx = nI(e)
                local ep = nP(e)
                if ep and nV(e) then
                    local d = d2d(fs.p, ep)
                    if d < minD then minD = d end
                    local dPath = sN(GridNav.FindPathLength, ep, fs.p)
                    if dPath <= 0 then dPath = d end
                    threat = threat + clamp((2100 - dPath) / 2100, 0, 1) * 1.2
                end

                local m = idx and DB.mia[idx]
                if m and not m.visible and m.lastPos then
                    local ms = math.max(200, sN(NPC.GetMoveSpeed, e))
                    local spread = 550 + m.missTime * ms * 0.35
                    local dM = d2d(fs.p, m.lastPos)
                    local p = clamp((spread + 900 - dM) / (spread + 900), 0, 1)
                    local recency = clamp(1 - m.missTime / 35, 0.15, 1)
                    threat = threat + p * recency * 0.9
                end

                local st = idx and PSY.enemies[idx]
                if st and st.predPos then
                    local dP = d2d(fs.p, st.predPos)
                    local conf = clamp((st.conf or 0) / 100, 0.1, 1)
                    local intentMul = 1.0
                    if st.intent == "GANK" or st.intent == "PRESSURE" then intentMul = 1.35
                    elseif st.intent == "ROTATE" then intentMul = 1.15
                    elseif st.intent == "ROSH" then intentMul = 0.65
                    elseif st.intent == "RETREAT" then intentMul = 0.5
                    elseif st.intent == "FARM" then intentMul = 0.8 end
                    threat = threat + clamp((2200 - dP) / 2200, 0, 1) * conf * intentMul
                end
            end
        end

        if minD == 99999 then minD = 9999 end
        local safety = clamp(1 - threat / 3.6, 0, 1)
        safety = safety * clamp(minD / 4200, 0.35, 1)
        safety = safety * clamp(pathDist > 0 and (1 - pathDist / 12000) + 0.35 or 1, 0.35, 1)
        if visibleToUs == false then
            safety = safety * (EC.aliveEnemies > #EC.visEnemies and 0.92 or 0.97)
        end
        if not traversable then safety = safety * 0.1 end

        local campBonus = 0
        for _, camp in ipairs(campList) do
            local cp = sG(Camp.GetAbsOrigin, camp)
            if cp and d2d(cp, fs.p) < 950 then
                campBonus = math.max(campBonus, (sG(Camp.IsStacked, camp) and 0.08 or 0.03))
            end
        end
        safety = clamp(safety + campBonus, 0, 1)
        if MAP.forwardRisk and MAP.forwardRisk > 80 and d2d(fs.p, EC.heroPos) > 2200 then
            safety = safety * 0.93
        end
        MAP.safeFarm[#MAP.safeFarm+1] = {
            name=fs.n, pos=fs.p, safety=safety, dist=pathDist, threat=F(threat*100)/100
        }
    end
    table.sort(MAP.safeFarm, function(a,b)
        if math.abs(a.safety - b.safety) > 0.02 then
            return a.safety > b.safety
        end
        return a.dist < b.dist
    end)

    -- Split push advice
    MAP.splitAdvice = ""
    if ui.map_split:Get() then
        local vis = #EC.visEnemies; local tot = #EC.enemies
        if vis >= 3 and tot >= 4 then MAP.splitAdvice = L("map_grouped")
        elseif vis <= 1 and tot >= 3 then MAP.splitAdvice = L("map_many_mia")
        elseif vis == 0 and tot > 0 then MAP.splitAdvice = L("map_all_mia") end
        if MAP.rune and MAP.rune.state == "CONTEST" then
            MAP.splitAdvice = (MAP.splitAdvice ~= "" and (MAP.splitAdvice.." | ") or "") .. L("msg_rune_contest")
        elseif MAP.rune and MAP.rune.state == "FREE" and MAP.rune.etaUs > 0 and MAP.rune.etaUs < 9 then
            MAP.splitAdvice = (MAP.splitAdvice ~= "" and (MAP.splitAdvice.." | ") or "") .. L("msg_free_rune_map")
        end
        if MAP.rosh and (MAP.rosh.suspicion or 0) >= 35 then
            MAP.splitAdvice = (MAP.splitAdvice ~= "" and (MAP.splitAdvice.." | ") or "") .. L("msg_rosh_suspect")
        end
    end
end

-- ══════════════════════════════════════════════
-- FARM DASHBOARD UPDATER
-- ══════════════════════════════════════════════
function updFarm(now)
    if not ui.hud_farm:Get() or now-FARM.t<1 then return end
    FARM.t=now
    if not EC.hero then return end

    -- Alive/dead tracking
    if FARM.lastAC > 0 then
        local dt = now - FARM.lastAC
        if EC.heroAlive then FARM.aliveT=FARM.aliveT+dt else FARM.deadT=FARM.deadT+dt end
    end
    FARM.lastAC = now

    local player = sG(Players.GetLocal)
    if not player then return end
    local nw = sN(Player.GetNetworth, player)
    if now > 0 then FARM.gpm = math.max(0, F(nw / (now/60))) end
    local hk = F(now / 30)
    if not FARM.goldHist[hk] then FARM.goldHist[hk] = nw end
    if FARM.gpm > FARM.peakGPM then FARM.peakGPM = FARM.gpm end

    local cs = sN(Player.GetLastHits, player)
    if now > 60 then FARM.csMin = math.floor((cs / (now/60)) * 10 + 0.5) / 10 end
    FARM.lastCS = cs
    local tot = FARM.aliveT + FARM.deadT
    FARM.eff = tot > 0 and clamp(FARM.aliveT / tot, 0, 1) or 1

    -- XPM estimate
    local xpT = {0,230,600,1080,1680,2300,2940,3600,4280,5080,5900,6740,7640,8865,10115,11390,12690,14015,15415,16905,18405,19905,21405,22905,24405,28405,32405,36405,40405,44405}
    local lv = EC.heroLevel
    local xp = xpT[math.min(lv, #xpT)] or (lv*1000)
    if now > 0 then FARM.xpm = F(xp / (now/60)) end
end

-- ══════════════════════════════════════════════
-- TEMPO COACH — HYBRID (reactive situational + event messages)
-- ══════════════════════════════════════════════
function tempoAddMsg(text, c, dur)
    c = c or C.white; dur = dur or ui.tempo_duration:Get()
    TEMPO.messages[#TEMPO.messages+1] = {text=text, col=c, time=sN(GameRules.GetGameTime), dur=dur}
    while #TEMPO.messages > ui.tempo_max_msg:Get() do table.remove(TEMPO.messages, 1) end
end

local nearCache = {t=0, values={}}

function countNPCsNear(pos, radius, teamFilter, heroOnly, creepOnly)
    if not pos then return 0 end
    local now = sN(GameRules.GetGameTime)
    if now - nearCache.t > 0.20 then
        nearCache.t = now
        nearCache.values = {}
    end
    local kx = F(pos.x / 64)
    local ky = F(pos.y / 64)
    local key = table.concat({kx, ky, radius, teamFilter, heroOnly and 1 or 0, creepOnly and 1 or 0}, ":")
    if nearCache.values[key] ~= nil then
        return nearCache.values[key]
    end

    local count=0
    if heroOnly then
        local heroes = nil
        if EC.heroTeam and type(Heroes) == "table" and type(Heroes.InRadius) == "function" then
            local enemyTT = Enum.TeamType and (Enum.TeamType.TEAM_ENEMY or nil)
            local allyTT  = Enum.TeamType and (Enum.TeamType.TEAM_FRIEND or Enum.TeamType.TEAM_ALLY or nil)
            local teamType = (teamFilter=="ally") and allyTT or enemyTT
            if teamType ~= nil then
            heroes = sG(Heroes.InRadius, pos, radius, EC.heroTeam, teamType)
            end
        end
        if not heroes then heroes=sG(Heroes.GetAll) end
        if heroes then
            for _,h in ipairs(heroes) do
                if nA(h) and not (sG(NPC.IsIllusion,h) or false) then
                    local t=sG(Entity.GetTeamNum,h); local hp=nP(h)
                    if t and hp and d2d(pos,hp)<=radius then
                        local isAlly=(t==EC.heroTeam)
                        if teamFilter=="ally" and isAlly then count=count+1
                        elseif teamFilter=="enemy" and not isAlly then count=count+1 end
                    end
                end
            end
        end
    else
        local allN = nil
        if EC.heroTeam and type(NPCs) == "table" and type(NPCs.InRadius) == "function" then
            local enemyTT = Enum.TeamType and (Enum.TeamType.TEAM_ENEMY or nil)
            local allyTT  = Enum.TeamType and (Enum.TeamType.TEAM_FRIEND or Enum.TeamType.TEAM_ALLY or nil)
            local teamType = (teamFilter=="ally") and allyTT or enemyTT
            if teamType ~= nil then
            allN = sG(NPCs.InRadius, pos, radius, EC.heroTeam, teamType)
            end
        end
        if not allN then allN=sG(NPCs.GetAll) end
        if allN then
            for _,npc in ipairs(allN) do
                if nA(npc) then
                    local t=sG(Entity.GetTeamNum,npc); local np=nP(npc)
                    if t and np and d2d(pos,np)<=radius then
                        local isAlly=(t==EC.heroTeam); local pass=true
                        if creepOnly then pass=(sG(NPC.IsCreep,npc) or false) and not (sG(NPC.IsHero,npc) or false) end
                        if pass then
                            if teamFilter=="ally" and isAlly then count=count+1
                            elseif teamFilter=="enemy" and not isAlly then count=count+1 end
                        end
                    end
                end
            end
        end
    end
    nearCache.values[key] = count
    return count
end

function tempoPush(cands, a, scr, cf, r, r2)
    if not cands or not a then return end
    cands[#cands+1] = {
        a = a,
        sc = F(scr or 0),
        cf = clamp(F(cf or 0), 1, 99),
        r = tostring(r or ""),
        r2 = r2 or "",
    }
end

function heroRespawnTimeSafe(h)
    return math.max(
        sN(Hero and Hero.GetRespawnTime or nil, h),
        sN(NPC and NPC.GetRespawnTime or nil, h),
        0
    )
end

function heroHasBuybackSafe(h)
    if not h then return false end
    local bb = sG(Hero and Hero.HasBuyback or nil, h)
    if bb == true then return true end
    local cd = sN(Hero and Hero.GetBuybackCooldown or nil, h)
    local cost = sN(Hero and Hero.GetBuybackCost or nil, h)
    if cd <= 0 and cost > 0 then return true end
    return false
end

function tempoTeamDeathWindow(list)
    local out = {dead=0, maxResp=0, sumResp=0, buybackReady=0}
    for _, h in ipairs(list or {}) do
        if not nA(h) then
            out.dead = out.dead + 1
            local rt = heroRespawnTimeSafe(h)
            out.sumResp = out.sumResp + rt
            if rt > out.maxResp then out.maxResp = rt end
            if heroHasBuybackSafe(h) then out.buybackReady = out.buybackReady + 1 end
        end
    end
    return out
end

function tempoHeroRosterByTeam(teamNum)
    local out = {}
    local all = sG(Heroes.GetAll)
    if not all then return out end
    for _, h in ipairs(all) do
        if h and not (sG(NPC.IsIllusion, h) or false) and sG(Entity.GetTeamNum, h) == teamNum then
            out[#out+1] = h
        end
    end
    return out
end

function tempoCollectSnapshot(now)
    local snap = {}
    updPsycho(now)
    snap.now = now
    snap.dotatime = sN(GameRules.GetDOTATime)
    snap.paused = sG(GameRules.IsGamePaused) == true
    snap.enNear1200 = (EC.heroPos and countNPCsNear(EC.heroPos, 1200, "enemy", true, false)) or 0
    snap.alNear1200 = (EC.heroPos and countNPCsNear(EC.heroPos, 1200, "ally", true, false)) or 0
    snap.enNear3000 = (EC.heroPos and countNPCsNear(EC.heroPos, 3000, "enemy", true, false)) or 0
    snap.alNear3000 = (EC.heroPos and countNPCsNear(EC.heroPos, 3000, "ally", true, false)) or 0
    snap.creepsNear = (EC.heroPos and countNPCsNear(EC.heroPos, 1000, "enemy", false, true)) or 0
    snap.threat = F(THREAT.nearScore or 0)
    snap.hpPct = EC.heroMaxHP > 0 and (EC.heroHP / EC.heroMaxHP * 100) or 0
    snap.manaPct = EC.heroMaxMana > 0 and (EC.heroMana / EC.heroMaxMana * 100) or 0
    snap.momentum = DB.momentum or 0
    snap.winProb = DB.winProb or 50
    local allyRoster = EC.heroTeam and tempoHeroRosterByTeam(EC.heroTeam) or EC.allies
    local enemyRoster = nil
    if EC.heroTeam == 2 then enemyRoster = tempoHeroRosterByTeam(3)
    elseif EC.heroTeam == 3 then enemyRoster = tempoHeroRosterByTeam(2)
    else enemyRoster = EC.enemies end
    snap.enemyDeaths = tempoTeamDeathWindow(enemyRoster)
    snap.allyDeaths = tempoTeamDeathWindow(allyRoster)
    snap.enemyVisible = #EC.visEnemies
    snap.enemyTotal = #EC.enemies
    snap.miaCount = math.max(0, snap.enemyTotal - snap.enemyVisible)
    snap.bestFarm = (MAP.safeFarm and MAP.safeFarm[1]) or nil
    snap.role = detectHeroRoleTag(EC.heroName)
    snap.spike = heroSpikeSnapshot(EC.hero)
    snap.psyTopIntent = (PSY.top and PSY.top.intent) or ""
    snap.psyTopName = (PSY.top and PSY.top.name) or ""
    snap.psyTopConf = (PSY.top and PSY.top.conf) or 0
    snap.psyHeroPressure = F((PSY.pressure and PSY.pressure.hero) or 0)
    snap.psyMapPressure = F((PSY.pressure and PSY.pressure.map) or 0)
    snap.psyRoshPressure = F((PSY.pressure and PSY.pressure.rosh) or 0)
    snap.rotateCount = #(MAP.rotations or {})
    snap.forwardRisk = F(MAP.forwardRisk or 0)
    snap.rune = MAP.rune or {state="", pos=nil, etaUs=0, etaEnemy=0}
    snap.roshSuspicion = (MAP.rosh and MAP.rosh.suspicion) or 0
    snap.roshReason = (MAP.rosh and MAP.rosh.reason) or ""

    if EC.heroTeam then
        snap.allyGlyph = sN(GameRules.GetGlyphCooldown, EC.heroTeam)
        local enemyTeam = (EC.heroTeam == 2 and 3) or (EC.heroTeam == 3 and 2) or nil
        snap.enemyGlyph = enemyTeam and sN(GameRules.GetGlyphCooldown, enemyTeam) or 0
        snap.enemyRadar = enemyTeam and sN(GameRules.GetRadarCooldown, enemyTeam) or 0
        snap.tormentorAlive = sG(GameRules.IsTormentorAlive, EC.heroTeam) == true
        snap.tormentorResp = sN(GameRules.GetTormentorRespawnTime, EC.heroTeam)
    else
        snap.allyGlyph = 0
        snap.enemyGlyph = 0
        snap.tormentorAlive = false
        snap.tormentorResp = 0
    end

    snap.roshAlive = sG(GameRules.IsRoshanAlive) == true
    snap.roshResp = sN(GameRules.GetRoshanRespawnTime)
    snap.roshKills = sN(GameRules.GetRoshanKillCount)
    TEMPO.snapshot = snap
    return snap
end

function tempoSelectCandidate(cands, now)
    if #cands == 0 then
        TEMPO.top_choices = {}
        return {a="STAND", sc=20, cf=20, r="", r2=""}
    end
    table.sort(cands, function(a, b)
        if a.sc ~= b.sc then return a.sc > b.sc end
        local ap = (TEMPO_CONFIG[a.a] and TEMPO_CONFIG[a.a].prio) or 0
        local bp = (TEMPO_CONFIG[b.a] and TEMPO_CONFIG[b.a].prio) or 0
        return ap > bp
    end)
    TEMPO.top_choices = {}
    for i = 1, math.min(3, #cands) do
        TEMPO.top_choices[i] = cands[i]
    end
    local best = cands[1]
    if not (ui.tempo_stable and ui.tempo_stable:Get()) then return best end

    local age = now - (TEMPO.advice_start_time or 0)
    if not TEMPO.current_advice or TEMPO.current_advice == "" then return best end
    local curCand = nil
    for _, c in ipairs(cands) do
        if c.a == TEMPO.current_advice then curCand = c break end
    end
    if not curCand then return best end

    -- Hysteresis: keep current advice briefly unless the new one is clearly stronger.
    -- Mais forte durante luta ativa pra evitar flip-flop
    local inFight = TEMPO.inFight or false
    local stickyAge = inFight and 3.0 or 1.4
    local stickyMargin1 = inFight and 35 or 20
    local stickyMargin2 = inFight and 22 or 12
    if best.a ~= curCand.a then
        if age < stickyAge and best.sc < curCand.sc + stickyMargin1 then
            return curCand
        end
        if age < stickyAge + 0.6 and best.sc < curCand.sc + stickyMargin2 then
            return curCand
        end
    else
        return curCand
    end
    return best
end

function tempo_evaluate(now)
    if not EC.valid or not EC.heroAlive or not EC.heroPos then
        TEMPO.top_choices = {}
        TEMPO.inFight = false
        return "STAND", 30, "", ""
    end
    now = now or gameNow()
    local s = tempoCollectSnapshot(now)
    if s.paused then return "STAND", 20, L("msg_paused"), "" end

    local cands = {}
    -- Usar raio de 2200 para avaliacao de luta (1200 era muito pequeno)
    local enNear = s.enNear1200
    local alNear = s.alNear1200
    local enWide = s.enNear3000  -- reforcos que podem chegar em ~2s
    local alWide = s.alNear3000
    local localAdv = alNear - enNear
    -- Reforcos: inimigos entre 1200-3000 que podem entrar na luta
    local enReinforce = math.max(0, enWide - enNear)
    local alReinforce = math.max(0, alWide - alNear)
    local effectiveAdv = (alNear + alReinforce * 0.5) - (enNear + enReinforce * 0.6)
    local role = s.role or "core"
    local spikeScore = (s.spike and s.spike.score) or 0
    local spikeLabel = (s.spike and s.spike.label) or ""
    local psyHero = s.psyHeroPressure or 0
    local psyMap = s.psyMapPressure or 0
    local psyTop = s.psyTopIntent or ""

    -- Hard retreat conditions
    if s.hpPct <= 22 and (enNear > 0 or s.threat >= 35) then
        tempoPush(cands, "RETREAT", 260 + F(22 - s.hpPct) * 4 + enNear * 18, clamp(92 - F(s.hpPct * 0.8), 55, 99),
            F(s.hpPct).."% HP", "threat "..s.threat)
    end
    if s.threat >= 90 then
        tempoPush(cands, "RETREAT", 230 + s.threat, clamp(65 + F((s.threat - 90) * 0.6), 55, 99), "Threat "..s.threat, L("msg_avoid_cast"))
    end
    if enNear >= 2 and alNear <= 1 and s.hpPct < 45 then
        tempoPush(cands, "RETREAT", 210 + enNear * 25, clamp(55 + enNear * 10, 50, 95), alNear.."v"..enNear, L("msg_low_support"))
    end
    if psyHero >= 70 and s.miaCount >= 2 and enNear <= 1 then
        tempoPush(cands, "RETREAT", 140 + F(psyHero * 0.9) + s.miaCount * 8, clamp(45 + F(psyHero * 0.35), 35, 92),
            L("msg_psy").." "..psyTop, L("msg_gank_pressure").." "..F(psyHero))
    end
    if s.forwardRisk >= 90 and enNear == 0 and s.miaCount >= 2 then
        tempoPush(cands, "STAND", 72 + F(s.forwardRisk * 0.35), clamp(48 + s.miaCount * 6, 40, 86),
            L("msg_forward_risk").." "..s.forwardRisk, L("msg_check_map"))
    end

    -- Rune objective (role-aware)
    if ui.tempo_obj == nil or ui.tempo_obj:Get() then
        local r = s.rune or {}
        local dt = s.dotatime or 0
        local secToPower = 120 - (dt % 120)
        if r.state == "FREE" and r.etaUs > 0 and r.etaUs <= 10 and secToPower <= 14 and secToPower >= -2 then
            local bonus = (role == "mid" and 26) or (role == "support" and 14) or 6
            tempoPush(cands, "RUNE", 88 + bonus + F((10 - r.etaUs) * 2), clamp(58 + bonus, 35, 92),
                L("msg_free_rune").." "..string.format("%.1f", r.etaUs).."s", role)
        elseif r.state == "CONTEST" and r.etaUs > 0 and r.etaUs <= 12 and secToPower <= 14 and secToPower >= -2 then
            local contestBonus = (role == "support" and 18) or (role == "mid" and 16) or 4
            tempoPush(cands, "RUNE", 68 + contestBonus - F(s.threat * 0.15), clamp(42 + contestBonus, 30, 84),
                L("msg_contest_rune"), (r.etaEnemy or 0) > 0 and ("eta "..string.format("%.1f", r.etaUs).." vs "..string.format("%.1f", r.etaEnemy)) or "")
        end
    end

    -- Tower defense / objective defense
    for _, tw in ipairs(EC.allyTowers) do
        local eh = countNPCsNear(tw.pos, 900, "enemy", true, false)
        if eh > 0 and d2d(EC.heroPos, tw.pos) < 3800 then
            local ac = countNPCsNear(tw.pos, 1200, "ally", true, false)
            local score = 120 + eh * 35 + math.max(0, eh - ac) * 12
            local conf = clamp(42 + eh * 12 + (ac >= eh and 10 or -5), 30, 95)
            local gTxt = (s.allyGlyph and s.allyGlyph <= 0.5) and L("msg_glyph_ready") or ""
            tempoPush(cands, "DEFEND", score, conf, eh.." @tower "..ac.."v"..eh, gTxt)
        end
    end

    -- Calcula poder local real com raio expandido
    local myPow = heroPower(EC.hero)
    local allyLocalPow = myPow
    for _, h in ipairs(EC.allies) do
        if h ~= EC.hero then
            local hp2 = nP(h)
            if hp2 then
                local dist = d2d(EC.heroPos, hp2)
                if dist <= 1200 then
                    allyLocalPow = allyLocalPow + heroPower(h)
                elseif dist <= 2800 then
                    -- Aliados chegando: contribuem parcialmente
                    allyLocalPow = allyLocalPow + heroPower(h) * clamp(1 - (dist - 1200) / 1600, 0.2, 0.7)
                end
            end
        end
    end
    local enemyLocalPow = 0
    for _, h in ipairs(EC.visEnemies) do
        local hp2 = nP(h)
        if hp2 then
            local dist = d2d(EC.heroPos, hp2)
            if dist <= 1200 then
                enemyLocalPow = enemyLocalPow + heroPower(h)
            elseif dist <= 2800 then
                -- Inimigos proximos: contam parcialmente (podem blinkar/entrar)
                enemyLocalPow = enemyLocalPow + heroPower(h) * clamp(1 - (dist - 1200) / 1600, 0.2, 0.7)
            end
        end
    end
    -- Inimigos MIA perto: estimar presenca pelo poder medio
    if enemyLocalPow <= 0 and enNear > 0 then
        enemyLocalPow = enNear * math.max(200, myPow * 0.85)
    end
    -- Reforcos inimigos nao visiveis (MIA) — adicionar pressao
    if enReinforce > 0 then
        enemyLocalPow = enemyLocalPow + enReinforce * myPow * 0.35
    end
    -- powRatio > 1 = voce+aliados mais fortes, < 1 = inimigos mais fortes
    local powRatio = allyLocalPow / math.max(1, enemyLocalPow)

    -- Checagem de ult inimigos em cooldown (vantagem massiva)
    local enemyUltsOnCD = 0
    local enemyUltsTotal = 0
    for _, h in ipairs(EC.visEnemies) do
        local idx = nI(h)
        if idx and EC.enSpells[idx] then
            for _, sp in ipairs(EC.enSpells[idx]) do
                if sp.ult then
                    enemyUltsTotal = enemyUltsTotal + 1
                    if not sp.rdy then enemyUltsOnCD = enemyUltsOnCD + 1 end
                end
            end
        end
    end
    local ultAdvantage = enemyUltsTotal > 0 and (enemyUltsOnCD / enemyUltsTotal) or 0

    -- ══════════════════════════════════════════════════════════════
    -- DECISAO EXCLUSIVA: FIGHT vs RETREAT (nao competem mais)
    -- Se condicoes de retreat forte sao atendidas, NAO gera FIGHT
    -- ══════════════════════════════════════════════════════════════
    local shouldRetreat = false
    local fightViable = false

    if enNear > 0 and s.hpPct > 20 then
        -- Avaliar se deve recuar
        local retreatScore = 0
        local retreatConf = 0
        local retreatR1 = ""
        local retreatR2 = ""

        -- Criterio 1: outnumbered sem poder compensatorio
        if localAdv < 0 and powRatio < 1.4 then
            local rScore = 130 + math.abs(localAdv) * 40 + F(math.max(0, 1.0 - powRatio) * 80)
            -- Reforcos inimigos tornam situacao pior
            rScore = rScore + enReinforce * 15
            local rConf  = clamp(60 + math.abs(localAdv) * 15, 50, 94)
            if rScore > retreatScore then
                retreatScore = rScore; retreatConf = rConf
                retreatR1 = (alNear+1).."v"..(enNear+enReinforce); retreatR2 = L("msg_outnumbered")
            end
        end
        -- Criterio 2: poder inferior mesmo com igualdade ou vantagem numerica
        if powRatio < 0.75 then
            local deficit = 0.75 - powRatio
            local rScore = 100 + F(deficit * 220) + F(math.max(0, 50 - s.hpPct) * 1.2)
            local rConf  = clamp(48 + F(deficit * 100), 40, 92)
            if rScore > retreatScore then
                retreatScore = rScore; retreatConf = rConf
                retreatR1 = L("msg_outpowered"); retreatR2 = F(powRatio * 100).."%"
            end
        end
        -- Criterio 3: HP+mana criticos
        if s.hpPct < 35 and s.manaPct < 20 then
            local rScore = 120 + F((35 - s.hpPct) * 3)
            if rScore > retreatScore then
                retreatScore = rScore; retreatConf = 72
                retreatR1 = F(s.hpPct).."%HP "..F(s.manaPct).."%MP"; retreatR2 = L("msg_low_resources") or ""
            end
        end

        if retreatScore > 0 then
            -- Retreat encontrou razao. Agora, verificar se fight tem chance apesar disso.
            -- So permite fight se: powRatio >= 1.3 E HP > 40% E mana > 25%
            if powRatio >= 1.3 and s.hpPct > 40 and s.manaPct > 25 then
                fightViable = true  -- Ainda pode lutar apesar de alguns sinais de recuo
            else
                shouldRetreat = true
                tempoPush(cands, "RETREAT", retreatScore, clamp(retreatConf, 35, 95), retreatR1, retreatR2)
            end
        else
            fightViable = true
        end

        -- Se nenhum retreat forte, avaliar luta
        if fightViable then
            -- ═════ FIGHT SCORE (redesenhado) ═════
            -- Base: 0 (nao 95). Score positivo = bom pra lutar, negativo = ruim.
            local fScore = 0

            -- Vantagem de poder local (fator principal)
            local powAdvantage = (powRatio - 1.0) * 100  -- +100 se 2x mais forte, -50 se metade
            fScore = fScore + clamp(powAdvantage, -120, 120)

            -- Vantagem numerica
            fScore = fScore + effectiveAdv * 30

            -- HP do seu heroi (20% HP = -80 pts, 100% HP = 0)
            fScore = fScore - clamp((100 - s.hpPct) * 1.0, 0, 80)

            -- Mana do seu heroi (sem mana = grande penalidade pra casters)
            if s.manaPct < 25 then
                local manaPenalty = (role == "support" or role == "mid") and 40 or 15
                fScore = fScore - manaPenalty
            end

            -- Ults inimigos em cooldown = grande vantagem
            fScore = fScore + F(ultAdvantage * 50)

            -- Tower aliada proxima = vantagem
            for _, tw in ipairs(EC.allyTowers) do
                if d2d(EC.heroPos, tw.pos) < 900 then
                    fScore = fScore + 25; break
                end
            end
            -- Tower inimiga proxima = desvantagem
            for _, tw in ipairs(EC.enemyTowers) do
                if d2d(EC.heroPos, tw.pos) < 900 then
                    fScore = fScore - 20; break
                end
            end

            -- Power spikes
            if spikeScore > 0 then
                fScore = fScore + F(spikeScore * 0.3)
            end

            -- Dead enemies ja = vantagem
            if s.enemyDeaths.dead > 0 then
                fScore = fScore + s.enemyDeaths.dead * 18
            end
            if s.allyDeaths.dead > 0 then
                fScore = fScore - s.allyDeaths.dead * 15
            end

            -- Psych gank pressure
            if psyTop == "GANK" and (s.psyTopConf or 0) >= 55 then
                fScore = fScore - 15
            end

            -- Converter fScore (centrado em 0) pra score absoluto pra comparar com outros candidatos
            -- fScore >= 30: bom pra lutar. fScore < -10: melhor nao lutar.
            local finalScore = 100 + fScore  -- base 100 pra competir com outros candidatos
            local conf = clamp(50 + F(powAdvantage * 0.3) + effectiveAdv * 8, 20, 95)

            if fScore >= -10 then
                -- Luta viavel ou boa
                tempoPush(cands, "FIGHT", finalScore, conf,
                    (alNear+1).."v"..(enNear + (enReinforce > 0 and ("+"..enReinforce) or "")),
                    spikeLabel ~= "" and spikeLabel or ("pow "..F(powRatio * 100).."%"))
            else
                -- Luta nao recomendada mas nao e retreat urgente: STAND/CAUTION
                tempoPush(cands, "RETREAT", 90 + math.abs(fScore), clamp(45 + math.abs(F(fScore * 0.3)), 35, 85),
                    L("msg_outpowered"), (alNear+1).."v"..(enNear))
            end
        end
    end

    -- Fight state machine: manter conselho por pelo menos 2.5s durante luta ativa
    if enNear > 0 then
        TEMPO.inFight = true
        TEMPO.lastFightTime = now
    elseif TEMPO.inFight and (now - (TEMPO.lastFightTime or 0)) < 2.5 then
        -- Ainda "em luta" — manter estado anterior sem gerar novos candidatos rapidos
    else
        TEMPO.inFight = false
    end

    -- Push logic with buyback/glyph pressure
    if EC.deadEnemies >= 1 and EC.aliveAllies >= 2 then
        local deadW = s.enemyDeaths.maxResp or 0
        local bbRisk = (ui.tempo_buyback and ui.tempo_buyback:Get()) and (s.enemyDeaths.buybackReady or 0) or 0
        local pScore = 85 + EC.deadEnemies * 18 + math.min(40, deadW)
        local pConf = 48 + EC.deadEnemies * 9 + math.min(18, F(deadW * 0.4))
        if role == "carry" then pScore = pScore + 8 end
        if role == "support" and s.enemyDeaths.buybackReady > 0 then pScore = pScore - 10 end
        if (s.enemyGlyph or 0) <= 0.5 then pScore = pScore - 10; pConf = pConf - 8 end
        if bbRisk > 0 then pScore = pScore - bbRisk * 14; pConf = pConf - bbRisk * 10 end
        tempoPush(cands, "PUSH", pScore, clamp(pConf, 28, 92), EC.deadEnemies.." "..L("dead").." / "..F(deadW).."s", bbRisk > 0 and (L("msg_bb_risk").." "..bbRisk) or "")
    end
    for _,tw in ipairs(EC.enemyTowers) do
        local ac=countNPCsNear(tw.pos,900,"ally",false,true)
        if ac>=2 and d2d(EC.heroPos,tw.pos)<2600 then
            local ah=countNPCsNear(tw.pos,1500,"ally",true,false)
            local eh=countNPCsNear(tw.pos,1500,"enemy",true,false)
            if ah>=eh then
                local pScore = 78 + ac*10 + (ah-eh)*12 - F(s.threat*0.15)
                local pConf = 44 + ac*5 + (ah-eh)*9
                if (s.enemyGlyph or 0) <= 0.5 then pConf = pConf - 10 end
                tempoPush(cands, "PUSH", pScore, clamp(pConf, 25, 90), ac.."c "..ah.."v"..eh, (s.enemyGlyph or 0) <= 0.5 and L("msg_enemy_glyph") or "")
            end
        end
    end

    -- Smoke punish isolated enemies
    local hasSmk=hasItem(EC.hero,"item_smoke_of_deceit")
    if hasSmk and EC.aliveAllies>=EC.aliveEnemies and #EC.visEnemies>0 and s.threat < 40 then
        local iso=0
        for _,e in ipairs(EC.visEnemies) do
            local ep=nP(e); if ep and countNPCsNear(ep,1500,"enemy",true,false)-1<=0 then iso=iso+1 end
        end
        if iso>0 then
            tempoPush(cands, "SMOKE_GANK", 70 + iso*14 + F((DB.momentum or 0)*0.2), clamp(40+iso*15,30,82), iso.." "..L("msg_isolated"), L("msg_smoke_ready"))
        end
    end

    -- Roshan / Tormentor objective windows
    if ui.tempo_obj == nil or ui.tempo_obj:Get() then
        local deadWin = s.enemyDeaths.maxResp or 0
        local roshAdv = (EC.aliveAllies - EC.aliveEnemies) + s.enemyDeaths.dead
        if (s.roshSuspicion or 0) >= 35 and not s.roshAlive and (s.roshResp or 0) > 30 then
            tempoPush(cands, "STAND", 62 + F((s.roshSuspicion or 0) * 0.4), clamp(50 + F((s.roshSuspicion or 0) * 0.2), 40, 90),
                L("msg_rosh_suspect"), s.roshReason or L("msg_check_pit"))
        end
        if s.roshAlive and s.dotatime > 480 then
            local roshScore = 75 + roshAdv * 12 + math.min(35, F(deadWin * 0.8))
            local roshConf = 45 + roshAdv * 8 + math.min(20, F(deadWin * 0.5))
            if (s.psyRoshPressure or 0) >= 50 and roshAdv <= 0 then
                roshScore = roshScore + 12
                roshConf = roshConf + 8
            end
            if s.enemyDeaths.buybackReady > 0 and ui.tempo_buyback and ui.tempo_buyback:Get() then
                roshScore = roshScore - s.enemyDeaths.buybackReady * 12
                roshConf = roshConf - s.enemyDeaths.buybackReady * 9
            end
            if s.threat > 45 then
                roshScore = roshScore - F(s.threat * 0.25)
                roshConf = roshConf - F(s.threat * 0.20)
            end
            if roshAdv > 0 then
                tempoPush(cands, "ROSHAN", roshScore, clamp(roshConf, 30, 90),
                    L("msg_rosh_alive"), deadWin > 0 and (L("msg_rosh_window").." "..F(deadWin).."s") or (s.roshReason or ""))
            end
        elseif s.roshResp > 0 and s.roshResp <= 45 and roshAdv >= 1 then
            tempoPush(cands, "STAND", 58 + (45 - math.min(45, s.roshResp)), clamp(50 + roshAdv * 6, 40, 80),
                L("msg_rosh_in").." "..F(s.roshResp).."s", L("msg_setup_vision"))
        end

        if s.dotatime > 1100 then
            if s.tormentorAlive and EC.aliveAllies >= EC.aliveEnemies and s.threat < 35 then
                local tScore = 66 + math.max(0, EC.aliveAllies - EC.aliveEnemies) * 10 + (s.enemyDeaths.dead * 8)
                local tConf = 42 + math.max(0, EC.aliveAllies - EC.aliveEnemies) * 7
                tempoPush(cands, "ROSHAN", tScore, clamp(tConf, 30, 84), "Tormentor", L("msg_free_shard"))
            elseif s.tormentorResp > 0 and s.tormentorResp <= 30 then
                tempoPush(cands, "STAND", 44 + (30 - math.min(30, s.tormentorResp)), 48, "Tormentor "..F(s.tormentorResp).."s", L("msg_prepare_map"))
            end
        end
    end

    -- Farm / reset
    if enNear == 0 then
        local cr = s.creepsNear
        local farmSafety = (s.bestFarm and s.bestFarm.safety) or 0.5
        local roleFarmBias = (role == "carry" and 12) or (role == "support" and -8) or (role == "mid" and 4) or 0
        local fScore = 45 + cr*5 + F(farmSafety*20) - F(s.threat*0.2) + roleFarmBias
        local fConf = 55 + F(farmSafety*30)
        if spikeScore >= 50 and role ~= "carry" then fScore = fScore - 14; fConf = fConf - 8 end
        if psyMap >= 60 and s.miaCount >= 2 then fScore = fScore - 10; fConf = fConf - 10 end
        if cr>0 then
            tempoPush(cands, "FARM", fScore, clamp(fConf, 40, 90),
                cr.."c", s.bestFarm and (s.bestFarm.name.." "..F(s.bestFarm.safety*100).."%") or "")
        elseif s.miaCount >= 4 then
            tempoPush(cands, "STAND", 52 + s.miaCount*5, clamp(45 + s.miaCount*5, 40, 80), L("msg_all_mia"), L("msg_hold_info"))
        else
            tempoPush(cands, "FARM", 42 + F(farmSafety*18), clamp(48 + F(farmSafety*25), 35, 85),
                s.bestFarm and s.bestFarm.name or L("msg_reset"), L("msg_safe_farm"))
        end
    end

    if #cands == 0 then
        TEMPO.top_choices = {}
        return "STAND",20,"",""
    end
    local sel = tempoSelectCandidate(cands, now)
    return sel.a, sel.cf, sel.r or "", sel.r2 or ""
end

local tempoAdviceColor

function updTempo(now)
    if not ui.tempo_enable:Get() then return end
    if now-TEMPO.last_update_time<1.0 then return end
    TEMPO.last_update_time=now

    -- Reactive advice
    local adv,cf,rsn,rsn2 = tempo_evaluate(now)
    if adv ~= TEMPO.current_advice then
        TEMPO.prev_advice=TEMPO.current_advice; TEMPO.current_advice=adv
        TEMPO.current_score=((TEMPO.top_choices[1] and TEMPO.top_choices[1].sc) or 0)
        TEMPO.confidence=cf; TEMPO.sub_reason=rsn; TEMPO.sub_reason2=rsn2 or ""
        TEMPO.advice_start_time=now; TEMPO.fade_alpha=255
        if ui.tempo_messages:Get() then
            local cfg = TEMPO_CONFIG[adv]
            local msg = ((cfg and cfg.icon) or "[.]") .. " " .. (((cfg and cfg.key) and L(cfg.key)) or adv)
            if rsn and rsn ~= "" then msg = msg .. " - " .. rsn end
            tempoAddMsg(msg, tempoAdviceColor(adv), 4)
        end
    else
        TEMPO.current_score=((TEMPO.top_choices[1] and TEMPO.top_choices[1].sc) or TEMPO.current_score or 0)
        TEMPO.confidence=F((TEMPO.confidence or cf)*0.55 + cf*0.45)
        TEMPO.sub_reason=rsn
        TEMPO.sub_reason2=rsn2 or ""
    end

    -- Event messages (from v3 Tempo)
    if ui.tempo_messages:Get() then
        -- Clean old
        local new={}
        for _,m in ipairs(TEMPO.messages) do if now-m.time<m.dur then new[#new+1]=m end end
        TEMPO.messages=new

        -- Power spikes
        if ui.tempo_spikes:Get() then
            local lv=EC.heroLevel
            for _,sl in ipairs({6,12,18,25}) do
                local k="sp"..sl
                if lv==sl and not TEMPO.notified[k] then
                    TEMPO.notified[k]=true
                    tempoAddMsg(L("tempo_spike").." Lv"..sl, C.gold, 10)
                end
            end
            if hasItem(EC.hero,"item_black_king_bar") and not TEMPO.notified["bkb"] then
                TEMPO.notified["bkb"]=true; tempoAddMsg(L("tempo_bkb"), C.gold, 8)
            end
        end

        -- Roshan reminder
        if now>900 then
            local rk="rosh"..F(now/480)
            if not TEMPO.notified[rk] then TEMPO.notified[rk]=true; tempoAddMsg(L("tempo_rosh_check").." "..fmtTime(now), C.orange, 10) end
        end

        -- Objective window reminders (Rosh/Tormentor/Glyph/Buyback)
        if ui.tempo_obj:Get() and type(TEMPO.snapshot) == "table" then
            local s = TEMPO.snapshot
            if (s.psyHeroPressure or 0) >= 80 and (s.psyTopIntent == "GANK" or s.psyTopIntent == "PRESSURE") then
                local k = "psy_gank"..F(now/6)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_psy")..": "..tostring(s.psyTopName or "?").." "..tostring(s.psyTopIntent).." "..F(s.psyTopConf or 0).."%", C.red, 4)
                end
            elseif (s.roshSuspicion or 0) >= 40 then
                local k = "psy_rosh"..F(now/8)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_psy")..": "..L("msg_psy_rosh").." "..F(s.roshSuspicion), C.orange, 5)
                end
            end

            if s.roshAlive and (s.enemyDeaths and s.enemyDeaths.maxResp or 0) >= 20 then
                local k = "rw"..F(now/8)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    local extra = (s.enemyDeaths.buybackReady or 0) > 0 and (" | BB "..s.enemyDeaths.buybackReady) or ""
                    tempoAddMsg(L("msg_rosh_window").." Rosh "..F(s.enemyDeaths.maxResp).."s"..extra, C.orange, 6)
                end
            elseif (s.roshResp or 0) > 0 and (s.roshResp or 0) <= 20 then
                local k = "rr"..F((s.roshResp or 0))
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_rosh_respawn").." ~"..F(s.roshResp).."s", C.orange, 5)
                end
            end

            if (s.tormentorAlive == true) and s.dotatime > 1100 then
                local k = "torm_alive"..F(now/25)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_torm_available"), C.cyan, 6)
                end
            elseif (s.tormentorResp or 0) > 0 and (s.tormentorResp or 0) <= 15 then
                local k = "torm_resp"..F(s.tormentorResp)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg("Tormentor "..F(s.tormentorResp).."s", C.cyan, 4)
                end
            end

            if ui.tempo_buyback:Get() and (s.enemyDeaths and (s.enemyDeaths.buybackReady or 0) > 0) and (TEMPO.current_advice=="PUSH" or TEMPO.current_advice=="ROSHAN") then
                local k = "bbwarn"..F(now/6)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_bb_warn").." "..s.enemyDeaths.buybackReady, C.red, 5)
                end
            end

            if (s.enemyGlyph or 999) <= 0.5 and TEMPO.current_advice=="PUSH" then
                local k = "glyphwarn"..F(now/10)
                if not TEMPO.notified[k] then
                    TEMPO.notified[k] = true
                    tempoAddMsg(L("msg_enemy_glyph_ready"), C.yellow, 4)
                end
            end
        end

        -- Death alerts
        if ui.tempo_death:Get() and now-TEMPO.lastDeathCheck>=2 then
            TEMPO.lastDeathCheck=now
            for _,ally in ipairs(EC.allies) do
                local idx=nI(ally); if idx then
                    local alive=nA(ally)
                    if TEMPO.prevAliveState[idx]==true and not alive then
                        tempoAddMsg(hName(ally).." "..L("dead").."!", C.red, 8)
                    end
                    TEMPO.prevAliveState[idx]=alive
                end
            end
        end

        -- Fight advice messages
        if ui.tempo_fight:Get() and EC.heroPos then
            local ac,ec=0,0
            for _,a in ipairs(EC.allies) do local ap=nP(a); if ap and d2d(EC.heroPos,ap)<3000 then ac=ac+1 end end
            for _,e in ipairs(EC.visEnemies) do local ep=nP(e); if ep and d2d(EC.heroPos,ep)<3000 then ec=ec+1 end end
            if ac>=ec+2 and ec>0 then
                local k="a"..F(now/10)
                if not TEMPO.notified[k] then TEMPO.notified[k]=true; tempoAddMsg(ac.."v"..ec.." "..L("msg_go"), C.green, 6) end
            elseif ec>=ac+2 and ac>0 then
                local k="d"..F(now/10)
                if not TEMPO.notified[k] then TEMPO.notified[k]=true; tempoAddMsg(ac.."v"..ec.." "..L("msg_back"), C.red, 6) end
            end
        end
    end
end

tempoAdviceColor = function(adv)
    local cfg=TEMPO_CONFIG[adv]; if cfg and C[cfg.col] then return C[cfg.col] end; return C.white
end

function tempoTopChoicesText()
    if not (ui.tempo_alt and ui.tempo_alt:Get()) then return "" end
    if type(TEMPO.top_choices) ~= "table" or #TEMPO.top_choices <= 1 then return "" end
    local parts = {}
    for i = 2, math.min(3, #TEMPO.top_choices) do
        local c = TEMPO.top_choices[i]
        local cfg = TEMPO_CONFIG[c.a]
        local label = (cfg and cfg.key and L(cfg.key)) or c.a
        parts[#parts+1] = label .. " " .. tostring(c.cf or 0) .. "%"
    end
    return table.concat(parts, "  |  ")
end

function tempoObjectiveHint()
    if not (ui.tempo_obj and ui.tempo_obj:Get()) then return "" end
    local s = TEMPO.snapshot
    if type(s) ~= "table" then return "" end
    if s.rune and s.rune.state and (s.rune.state == "FREE" or s.rune.state == "CONTEST") and (s.rune.etaUs or 99) <= 12 then
        return "Rune "..s.rune.state.." "..string.format("%.1fs", s.rune.etaUs or 0)
    end
    if (s.roshSuspicion or 0) >= 35 and (s.roshAlive == false or (s.roshResp or 0) > 25) then
        return "Rosh suspicious | "..F(s.roshSuspicion)
    end
    if s.roshAlive then
        local deadW = s.enemyDeaths and s.enemyDeaths.maxResp or 0
        if deadW > 0 then
            return "Rosh alive | window "..F(deadW).."s"
        end
        return "Rosh alive"
    end
    if (s.roshResp or 0) > 0 and (s.roshResp or 0) <= 45 then
        return "Rosh in "..F(s.roshResp).."s"
    end
    if s.tormentorAlive then
        return "Tormentor up"
    end
    if (s.tormentorResp or 0) > 0 and (s.tormentorResp or 0) <= 30 then
        return "Tormentor "..F(s.tormentorResp).."s"
    end
    return ""
end

-- Draw tempo on-screen overlay (no panel, drawn over world)
function drawTempo()
    if not ui.tempo_enable:Get() or not ui.tempo_screen:Get() or TEMPO.current_advice=="" then return end
    local now=sN(GameRules.GetGameTime); local elapsed=now-TEMPO.advice_start_time
    local duration=ui.tempo_duration:Get()
    local alpha=255
    if elapsed>duration-1.0 then alpha=F(255*clamp((duration-elapsed),0,1)) end
    if elapsed<0.3 then alpha=F(255*clamp(elapsed/0.3,0,1)) end
    if alpha<=5 then return end
    TEMPO.fade_alpha=TEMPO.fade_alpha+(alpha-TEMPO.fade_alpha)*0.3

    local cfg=TEMPO_CONFIG[TEMPO.current_advice]; if not cfg then return end
    local advT=(cfg.icon or "").." "..L(cfg.key)
    local fSz=ui.tempo_font:Get()
    if TEMPO.popupX == nil or TEMPO.popupY == nil then
        TEMPO.popupX = sGet("tempo_popup_x",-1)
        TEMPO.popupY = sGet("tempo_popup_y",-1)
        if (TEMPO.popupX or -1) < 0 then TEMPO.popupX = SW/2 end
        if (TEMPO.popupY or -1) < 0 then TEMPO.popupY = SH*0.28 end
    end
    local posX, posY = TEMPO.popupX, TEMPO.popupY
    local advC=tempoAdviceColor(TEMPO.current_advice)
    local fC=colA(advC, F(TEMPO.fade_alpha))
    local tw2=tW(fSz,advT); local th=fSz*gScale+sc(4)
    local altText = tempoTopChoicesText()
    local objText = tempoObjectiveHint()
    local reason2 = TEMPO.sub_reason2 or ""
    local lineCount = 1
    if reason2 ~= "" then lineCount = lineCount + 1 end
    if objText ~= "" then lineCount = lineCount + 1 end
    if altText ~= "" then lineCount = lineCount + 1 end
    local extraW = math.max(tW(8, TEMPO.sub_reason or ""), tW(8, reason2), tW(8, objText), tW(8, altText))
    local totalW=math.max(tw2+sc(40), extraW + sc(24))
    local totalH=th+sc(16)
    local subH=sc(14) * lineCount
    local bgH=totalH+subH
    posX = clamp(posX, totalW/2 + sc(4), SW - totalW/2 - sc(4))
    posY = clamp(posY, sc(16), SH - bgH - sc(8))
    TEMPO.drag = TEMPO.drag or {on=false, ox=0, oy=0}
    local lockedPanels = ui.lock and ui.lock:Get() or false
    local bgX=posX-totalW/2; local bgY=posY-sc(4)
    if not lockedPanels then
        if mouse.pr and not activePanel and inRect(mouse.x, mouse.y, bgX, bgY, totalW, bgH) then
            TEMPO.drag.on = true
            TEMPO.drag.ox = mouse.x - posX
            TEMPO.drag.oy = mouse.y - posY
        end
        if TEMPO.drag.on then
            if mouse.dn then
                posX = clamp(mouse.x - (TEMPO.drag.ox or 0), totalW/2 + sc(4), SW - totalW/2 - sc(4))
                posY = clamp(mouse.y - (TEMPO.drag.oy or 0), sc(16), SH - bgH - sc(8))
                TEMPO.popupX, TEMPO.popupY = posX, posY
            end
            if mouse.rl then
                TEMPO.drag.on = false
                TEMPO.popupX, TEMPO.popupY = posX, posY
                sSet("tempo_popup_x", F(posX + 0.5))
                sSet("tempo_popup_y", F(posY + 0.5))
            end
        end
    elseif TEMPO.drag and TEMPO.drag.on and mouse.rl then
        TEMPO.drag.on = false
    end
    TEMPO.popupX, TEMPO.popupY = posX, posY
    bgX=posX-totalW/2; bgY=posY-sc(4)
    local bgA=F(190*(TEMPO.fade_alpha/255))
    dRect(bgX,bgY,totalW,bgH,col(10,12,20,bgA),sc(10))
    dBorder(bgX,bgY,totalW,bgH,colA(advC,F(TEMPO.fade_alpha*0.5)),sc(10))
    dRect(bgX+sc(4),bgY,totalW-sc(8),sc(3),colA(advC,F(TEMPO.fade_alpha*0.8)),sc(2))
    -- Shadow + text
    dText(fSz,advT,posX-tw2/2+sc(2),posY+sc(2),col(0,0,0,F(TEMPO.fade_alpha*0.6)))
    dText(fSz,advT,posX-tw2/2,posY,fC)
    -- Confidence + reason
    local infoY=posY+th+sc(4)
    local bW=sc(68); local bX=posX-bW/2
    local cP=TEMPO.confidence/100; local cC=cP>0.7 and C.green or (cP>0.4 and C.yellow or C.red)
    dBar(bX,infoY,bW,sc(5),cP,colA(cC,F(TEMPO.fade_alpha*0.8)),col(0,0,0,F(TEMPO.fade_alpha*0.3)),sc(3))
    dText(8,"S:"..F(TEMPO.current_score or 0), bX+bW+sc(6), infoY-sc(3), col(170,180,205,F(TEMPO.fade_alpha*0.45)))
    if TEMPO.sub_reason~="" then
        local rW=tW(8,TEMPO.sub_reason)
        dText(8,TEMPO.sub_reason,posX-rW/2,infoY+sc(7),col(180,185,200,F(TEMPO.fade_alpha*0.5)))
    end
    local y2 = infoY + sc(7)
    if reason2 ~= "" then
        y2 = y2 + sc(12)
        local rW=tW(8,reason2)
        dText(8,reason2,posX-rW/2,y2,col(160,170,195,F(TEMPO.fade_alpha*0.45)))
    end
    if objText ~= "" then
        y2 = y2 + sc(12)
        local rW=tW(8,objText)
        dText(8,objText,posX-rW/2,y2,col(255,195,90,F(TEMPO.fade_alpha*0.5)))
    end
    if altText ~= "" then
        y2 = y2 + sc(12)
        local rW=tW(8,altText)
        dText(8,altText,posX-rW/2,y2,col(165,175,190,F(TEMPO.fade_alpha*0.42)))
    end
end

function updWorld(now)
    if ui.w_linken:Get() then
        for _,e in ipairs(EC.visEnemies) do
            local idx=nI(e); if idx then LINKEN[idx]=sG(NPC.IsLinkensProtected,e) or false end
        end
    end
    if ui.w_smoke:Get() then
        local found=false
        for _,e in ipairs(EC.enemies) do
            if nA(e) and sG(NPC.HasModifier,e,"modifier_smoke_of_deceit") then found=true; break end
        end
        if found then SMOKE.on=true; SMOKE.t=now end
        if now-SMOKE.t>5 then SMOKE.on=false end
    end
    if ui.w_lh:Get() and now-LH.t>0.12 then
        LH.t=now; LH.targets={}
        if EC.heroAlive and EC.heroPos then
            local allN=sG(NPCs.GetAll); if allN then
                for _,npc in ipairs(allN) do
                    if nA(npc) and sG(NPC.IsCreep,npc) then
                        local t=sG(Entity.GetTeamNum,npc)
                        if t and t~=EC.heroTeam then
                            local cp=nP(npc)
                            if cp and d2d(EC.heroPos,cp)<EC.heroRange+200 then
                                local hp=sN(Entity.GetHealth,npc)
                                local armor=sN(NPC.GetPhysicalArmorValue,npc)
                                if hp>0 and hp<=EC.heroDmg*physMult(armor) then
                                    LH.targets[#LH.targets+1]={pos=cp}
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if ui.w_flash:Get() then
        for _,e in ipairs(EC.enemies) do
            local idx=nI(e); if idx then
                local alive=nA(e)
                if prevAlive[idx] and not alive then FLASH.on=true; FLASH.t=now; FLASH.who=hName(e) end
                prevAlive[idx]=alive
            end
        end
        if now-FLASH.t>1.5 then FLASH.on=false end
    end
    if ui.gank:Get() and EC.heroAlive and EC.heroPos then
        local mC=0
        for _,e in ipairs(EC.enemies) do
            local idx=nI(e); if idx then
                local m=DB.mia[idx]
                if m and not m.visible and nA(e) and m.missTime>3 and m.missTime<20 then
                    if m.lastPos and d2d(EC.heroPos,m.lastPos)<3000 then mC=mC+1 end
                end
            end
        end
        if mC>=2 then GANK.on=true; GANK.t=now; GANK.cnt=mC end
        if now-GANK.t>4 then GANK.on=false end
    end
end

function queueCastNoTarget(ability, key, desc, pri)
    if not ability then return false end
    local castFn = function()
        if not ability then return end
        pcall(Ability.CastNoTarget, ability)
    end
    if ui.core_q and ui.core_q:Get() then
        return queueAction(key, pri or 50, 0.25, desc, castFn)
    end
    local ok = pcall(castFn)
    return ok
end

function processAuto()
    if not EC.heroAlive then return end
    local now = sN(GameRules.GetGameTime)
    local hpPct=EC.heroHP/EC.heroMaxHP*100
    local locked = (sG(NPC.IsStunned, EC.hero) or false) or (sG(NPC.IsHexed, EC.hero) or false)
    if locked then return end

    if ui.auto_phase:Get() then
        local has,it=hasItem(EC.hero,"item_phase_boots")
        if has and it and (now - AUTO.phase) > 0.8 and (sG(NPC.IsRunning,EC.hero) or false)
            and (sG(Ability.IsCastable,it,EC.heroMana) or sG(Ability.IsReady,it) or false) then
            if queueCastNoTarget(it, "auto:phase", "Auto Phase", 35) then
                AUTO.phase = now
            end
        end
    end

    if ui.auto_stick:Get() and hpPct<=ui.auto_stick_hp:Get() then
        local has,it=hasItem(EC.hero,"item_magic_wand")
        if not has then has,it=hasItem(EC.hero,"item_magic_stick") end
        if has and it and (now - AUTO.stick) > 1.1
            and (sG(Ability.IsCastable,it,EC.heroMana) or sG(Ability.IsReady,it) or false) then
            if queueCastNoTarget(it, "auto:stick", "Auto Stick", 80) then
                AUTO.stick = now
            end
        end
    end

    if ui.auto_faerie:Get() and hpPct<=ui.auto_faerie_hp:Get() then
        local has,it=hasItem(EC.hero,"item_faerie_fire")
        if has and it and (now - AUTO.faerie) > 1.2
            and (sG(Ability.IsCastable,it,EC.heroMana) or sG(Ability.IsReady,it) or false) then
            if queueCastNoTarget(it, "auto:faerie", "Auto Faerie", 90) then
                AUTO.faerie = now
            end
        end
    end
end

--------------------------------------------------------------------------------
-- DRAW WORLD
--------------------------------------------------------------------------------
function drawThreatOverlay()
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_draw and ui.th_draw:Get()) then return end
    local now = gameNow()
    if #THREAT.events > 0 then
        local sorted = {}
        for _, ev in ipairs(THREAT.events) do
            if ev and now <= (ev.expire or 0) then sorted[#sorted+1] = ev end
        end
        table.sort(sorted, function(a, b)
            if a.severity ~= b.severity then return (a.severity or 0) > (b.severity or 0) end
            return (a.expire or 0) < (b.expire or 0)
        end)
        local maxDraw = (ui.th_max_draw and ui.th_max_draw:Get()) or 6
        for i = 1, math.min(#sorted, maxDraw) do
            local ev = sorted[i]
            if ev.pos then
                local alpha = clamp((ev.expire - now) / math.max(0.01, (ev.expire - ev.created)), 0.15, 1)
                local cc = colA(ev.color or C.red, F(alpha * 180))
                drawCircleW(ev.pos, ev.radius or 220, cc, 24)
                local sx, sy, vis = w2s(Vector(ev.pos.x, ev.pos.y, (ev.pos.z or 0) + 36))
                if vis and sx then
                    local txt = (ev.text or ev.kind or "Threat")
                    if ev.severity then txt = txt .. " [" .. F(ev.severity) .. "]" end
                    local tw = tW(8, txt)
                    dRect(sx-tw/2-sc(4), sy-sc(10), tw+sc(8), sc(16), col(0,0,0,F(alpha*120)), sc(4))
                    dText(8, txt, sx-tw/2, sy-sc(8), colA(ev.color or C.red, F(alpha * 255)))
                end
                if ui.th_lines and ui.th_lines:Get() and EC.heroPos then
                    local hx, hy, hvis = w2s(Vector(EC.heroPos.x, EC.heroPos.y, EC.heroPos.z + 70))
                    local lineTarget = Vector(ev.pos.x, ev.pos.y, (ev.pos.z or 0) + 10)
                    local canDrawLine = true
                    local rr = tonumber(ev.radius or 0) or 0
                    if rr > 1 then
                        local dx = ev.pos.x - EC.heroPos.x
                        local dy = ev.pos.y - EC.heroPos.y
                        local dxy = math.sqrt(dx*dx + dy*dy)
                        if dxy <= (rr + 24) then
                            canDrawLine = false -- already in/near threat radius, line is not useful
                        elseif dxy > 1 then
                            local ux, uy = dx / dxy, dy / dxy
                            lineTarget = Vector(
                                ev.pos.x - ux * rr,
                                ev.pos.y - uy * rr,
                                (ev.pos.z or EC.heroPos.z or 0) + 10
                            )
                        end
                    end
                    local ex, ey, evis = w2s(lineTarget)
                    if canDrawLine and hvis and evis and hx and ex then
                        dLine(hx, hy, ex, ey, colA(ev.color or C.red, F(alpha * 120)))
                    end
                end
            end
        end
    end

    if ui.th_score and ui.th_score:Get() then
        local danger = clamp((THREAT.nearScore or 0) / 120, 0, 1)
        if danger > 0.02 or (#THREAT.events > 0) or (gameNow() - GUARD.lastBlockTime < 1.5) then
            local bw, bh = sc(220), sc(12)
            local boxW, boxH = bw+sc(16), bh+sc(34)
            local bx, by = SW/2 - bw/2, SH*0.20
            local ax, ay = chooseHudRectAvoidPanels(bx-sc(8), by-sc(16), boxW, boxH)
            bx, by = ax + sc(8), ay + sc(16)
            local bc = dangerColor(danger)
            dRect(bx-sc(8), by-sc(16), bw+sc(16), bh+sc(34), col(8,10,18,170), sc(8))
            dBorder(bx-sc(8), by-sc(16), bw+sc(16), bh+sc(34), colA(bc, 130), sc(8))
            dText(9, L("msg_threat_label").." "..F(THREAT.nearScore), bx, by-sc(14), bc)
            dBar(bx, by, bw, bh, danger, bc, col(0,0,0,120), sc(4))
            if gameNow() - GUARD.lastBlockTime < 1.5 then
                local a = F(255 * clamp(1 - (gameNow() - GUARD.lastBlockTime) / 1.5, 0, 1))
                dText(8, GUARD.lastBlockReason, bx, by+sc(14), col(255,180,80,a))
            elseif THREAT.lastAlert ~= "" and gameNow() - THREAT.lastAlertTime < 2.5 then
                local a = F(255 * clamp(1 - (gameNow() - THREAT.lastAlertTime) / 2.5, 0, 1))
                dText(8, THREAT.lastAlert, bx, by+sc(14), col(255,120,120,a))
            end
            -- Alerta grande nomeado quando o ping dispara
            if THREAT.pingAlert and THREAT.pingAlertTime and gameNow() - THREAT.pingAlertTime < 3.0 then
                local pa = F(255 * clamp(1 - (gameNow() - THREAT.pingAlertTime) / 3.0, 0, 1))
                local sevTxt = (THREAT.pingAlertSev or 0) >= 80 and "!!!" or ((THREAT.pingAlertSev or 0) >= 55 and "!!" or "!")
                local alertFull = sevTxt.." "..THREAT.pingAlert.." "..sevTxt
                local aw = tW(12, alertFull)
                local ax2 = SW/2 - aw/2
                local ay2 = by - sc(38)
                dRect(ax2 - sc(6), ay2 - sc(4), aw + sc(12), sc(22), col(0,0,0,F(pa*0.7)), sc(6))
                dBorder(ax2 - sc(6), ay2 - sc(4), aw + sc(12), sc(22), colA(THREAT.pingAlertColor or C.red, F(pa*0.7)), sc(6))
                dText(12, alertFull, ax2, ay2, colA(THREAT.pingAlertColor or C.red, pa))
            end
        end
    end
end

function drawThreatMiniMap()
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_minimap and ui.th_minimap:Get()) then return end
    if not MiniMap then return end
    local now = gameNow()
    local n = 0
    for _, ev in ipairs(THREAT.events) do
        if n >= 5 then break end
        if ev and ev.pos and now <= (ev.expire or 0) then
            if type(MiniMap.DrawCircle) == "function" then
                pcall(MiniMap.DrawCircle, ev.pos, math.max(120, (ev.radius or 180) * 0.7), colA(ev.color or C.red, 180), 1)
            end
            n = n + 1
        end
    end
end

function drawWorld()
    if not EC.heroAlive then return end

    -- Overhead Kill Matrix
    if ui.km:Get() and ui.km_oh:Get() then
        for _,e in ipairs(EC.visEnemies) do
            local idx=nI(e); local d=idx and KM.data[idx]; local ep=nP(e)
            if not ep or not d then goto nE end
            local sx,sy,vis=w2s(Vector(ep.x,ep.y,ep.z+180)); if not vis or not sx then goto nE end
            local ch2=d.killChance; local chC=killColor(ch2); local chT=ch2.."%"; local tw2=tW(11,chT)
            dRect(sx-tw2/2-sc(8),sy-sc(22),tw2+sc(16),sc(20),col(0,0,0,190),sc(5))
            dBorder(sx-tw2/2-sc(8),sy-sc(22),tw2+sc(16),sc(20),colA(chC,150),sc(5))
            dText(11,chT,sx-tw2/2,sy-sc(20),chC)
            if ui.km_hp:Get() then
                local bw=sc(55); dBar(sx-bw/2,sy+sc(2),bw,sc(6),d.targetHP/d.targetMaxHP,C.hp,C.hp_bg,sc(3))
                if ui.km_thr:Get() and d.totalDmg>0 then
                    local tp=clamp(d.totalDmg/d.targetMaxHP,0,1)
                    dLine(sx-bw/2+bw*(1-tp),sy,sx-bw/2+bw*(1-tp),sy+sc(8),C.yellow)
                end
            end
            if ui.km_dmg:Get() then
                local dmgTxt = fN(d.shortDmg or d.totalDmg).."/"..fN(d.totalDmg)
                dText(9,dmgTxt,sx+sc(32),sy-sc(5),dangerColor(d.totalDmg/(d.targetMaxHP+1)))
                if d.flags and d.flags ~= "" then dText(7,d.flags,sx+sc(32),sy+sc(5),C.orange) end
            end
            if ui.km_world:Get() and ch2>=75 then drawCircleW(ep,80,colA(chC,120),24) end
            if ui.km_rev:Get() and KM.rev[idx] and KM.rev[idx].killChance>=55 then
                local rv=KM.rev[idx].killChance
                dText(9,L("danger")..":"..rv.."%",sx-sc(45),sy+sc(10),rv>=75 and C.red or C.orange)
            end
            if ui.w_linken:Get() and LINKEN[idx] then dText(8,L("linken_active"),sx+sc(32),sy+sc(6),C.purple) end
            -- Overhead items
            if ui.ih_oh:Get() then
                local items=EC.enItems[idx]; if items and #items>0 then
                    local iy=sy+sc(14); local totalW=0
                    for j,it in ipairs(items) do if j>4 then break end; totalW=totalW+tW(7,it.s)+sc(4) end
                    local ix=sx-totalW/2
                    for j,it in ipairs(items) do if j>4 then break end
                        dText(7,it.s,ix,iy,it.rdy and it.c or C.dark); ix=ix+tW(7,it.s)+sc(4) end
                end
            end
            -- Overhead spells
            if ui.sp_oh:Get() then
                local spells=EC.enSpells[idx]; if spells and #spells>0 then
                    local spY=sy+sc(24); local totalW=0
                    for _,sp in ipairs(spells) do totalW=totalW+tW(7,sp.s)+sc(4) end
                    local spX=sx-totalW/2
                    for _,sp in ipairs(spells) do
                        dText(7,sp.s,spX,spY,sp.rdy and (sp.ult and C.gold or C.cb_ok) or C.cb_cd)
                        spX=spX+tW(7,sp.s)+sc(4)
                    end
                end
            end
            ::nE::
        end
    end

    -- MIA Circles (from Map Control)
    if ui.map_missing:Get() or ui.km_mia:Get() then
        for _,e in ipairs(EC.enemies) do
            local idx=nI(e); local m=idx and DB.mia[idx]
            if m and not m.visible and m.missTime>5 and nA(e) then
                local epos=m.lastPos or nP(e); if epos then
                    local ms2=math.max(200,sN(NPC.GetMoveSpeed,e))
                    local rad=math.min(6000,800+m.missTime*ms2*0.4)
                    local a=F(clamp(70-m.missTime*0.8,10,70))
                    drawCircleW(epos,rad,col(255,100,100,a),24)
                    local sx,sy,vis=w2s(epos); if vis and sx then
                        dText(9,L("missing").." "..hName(e).." "..F(m.missTime)..L("s"),sx-sc(30),sy-sc(8),col(255,100,100,a+60))
                    end
                end
            end
        end
    end

    -- Tower range
    if ui.w_tower:Get() and EC.heroPos then
        for _,tw in ipairs(EC.enemyTowers) do
            if d2d(EC.heroPos,tw.pos)<1100 then drawCircleW(tw.pos,700,C.tower,32) end
        end
    end
    -- Blink range
    if ui.w_blink:Get() and EC.heroPos and hasAnyBlink(EC.hero) then drawCircleW(EC.heroPos,1200,colA(C.accent,50),32) end
    -- Last hit
    if ui.w_lh:Get() then
        for _,lh in ipairs(LH.targets) do
            local sx,sy,vis=w2s(Vector(lh.pos.x,lh.pos.y,lh.pos.z+25))
            if vis and sx then dCircle(sx,sy,sc(6),col(C.green.r,C.green.g,C.green.b,F(180+math.sin(os.clock()*6)*75)),8) end
        end
    end
    -- Smoke
    if SMOKE.on and EC.heroPos then
        local sx,sy,vis=w2s(Vector(EC.heroPos.x,EC.heroPos.y,EC.heroPos.z+300))
        if vis and sx then dText(16,L("smoke_detected"),sx-sc(45),sy-sc(20),col(C.smoke.r,C.smoke.g,C.smoke.b,F(200+math.sin(os.clock()*8)*55))) end
    end
    -- Kill flash
    if FLASH.on then
        local age=sN(GameRules.GetGameTime)-FLASH.t; if age<1.5 then
            local a=F(255*clamp(1-age/1.5,0,1)); local th2=sc(3)
            dRect(0,0,SW,th2,colA(C.green,a)); dRect(0,SH-th2,SW,th2,colA(C.green,a))
            dRect(0,0,th2,SH,colA(C.green,a)); dRect(SW-th2,0,th2,SH,colA(C.green,a))
            if age<0.7 then local txt=L("enemy_down").." "..FLASH.who; local tw3=tW(18,txt)
                dText(18,txt,SW/2-tw3/2,SH*0.28,colA(C.green,a)) end
        end
    end
    -- Dodge
    if ui.w_dodge:Get() and os.clock()-DOD.t<1.5 and EC.heroPos then
        local sx,sy,vis=w2s(Vector(EC.heroPos.x,EC.heroPos.y,EC.heroPos.z+260))
        if vis and sx then dText(16,DOD.txt,sx-sc(50),sy-sc(35),col(255,50,50,F(255*(0.5+math.sin(os.clock()*10)*0.5)))) end
    end
    -- Gank alert
    if ui.gank:Get() and GANK.on then
        local now=sN(GameRules.GetGameTime); local el=now-GANK.t; local alpha=F(255*math.max(0,1-el/4))
        if alpha>10 then
            local pulse=0.5+0.5*math.sin(now*6); local a2=F(alpha*(0.7+0.3*pulse))
            local txt=L("gank_inc").." ("..GANK.cnt.." "..L("missing")..")"; local tw4=tW(18,txt)
            dRect(SW/2-tw4/2-sc(10),sc(60),tw4+sc(20),sc(26),col(255,50,50,F(a2*0.15)),sc(5))
            dText(18,txt,SW/2-tw4/2,sc(63),col(255,50,50,a2))
        end
    end
    -- Danger
    if EC.heroAlive and EC.heroPos then
        local nearEn=0
        for _,e in ipairs(EC.visEnemies) do local ep=nP(e); if ep and d2d(EC.heroPos,ep)<1200 then nearEn=nearEn+1 end end
        local nearAl=0
        for _,a in ipairs(EC.allies) do if a~=EC.hero then local ap=nP(a); if ap and d2d(EC.heroPos,ap)<1500 then nearAl=nearAl+1 end end end
        if nearEn>=2 and nearAl==0 then
            local pulse=0.5+0.5*math.sin(os.clock()*5); local alpha=F(180+pulse*75)
            local txt=L("danger").."! "..nearEn.." "..L("enemies"); local tw5=tW(14,txt)
            dRect(SW/2-tw5/2-sc(6),SH-sc(80),tw5+sc(12),sc(20),col(255,50,50,F(alpha*0.15)),sc(4))
            dText(14,txt,SW/2-tw5/2,SH-sc(77),col(255,80,80,alpha))
        end
    end
    -- Initiation
    if ui.ini:Get() and INI.bestPos and INI.count>=ui.ini_min:Get() then
        local sx,sy,vis=w2s(INI.bestPos)
        if vis and sx then
            dText(10,tostring(INI.count),sx-sc(5),sy-sc(7),C.white)
            dText(7,"S"..F(INI.bestScore or 0).." R"..F(INI.risk or 0).." +"..F(INI.follow or 0),sx-sc(28),sy+sc(8),C.cyan)
        end
        drawCircleW(INI.bestPos,INI.radius or 450,colA((INI.risk or 0) >= 90 and C.orange or C.green,80),24)
    end

    -- World-space label at ping position
    if THREAT.pingAlert and THREAT.pingAlertTime and THREAT.pingAlertPos then
        local age = gameNow() - THREAT.pingAlertTime
        if age < 3.5 then
            local pa = F(255 * clamp(1 - age / 3.5, 0, 1))
            local sx3, sy3, vis3 = w2s(Vector(THREAT.pingAlertPos.x, THREAT.pingAlertPos.y, (THREAT.pingAlertPos.z or 0) + 80))
            if vis3 and sx3 then
                local lbl = THREAT.pingAlert
                local tw6 = tW(10, lbl)
                dRect(sx3 - tw6/2 - sc(5), sy3 - sc(12), tw6 + sc(10), sc(18), col(0,0,0,F(pa*0.6)), sc(4))
                dBorder(sx3 - tw6/2 - sc(5), sy3 - sc(12), tw6 + sc(10), sc(18), colA(THREAT.pingAlertColor or C.red, F(pa*0.5)), sc(4))
                dText(10, lbl, sx3 - tw6/2, sy3 - sc(10), colA(THREAT.pingAlertColor or C.red, pa))
            end
        end
    end

    -- Psycho Engine predicted intents (top enemies)
    if ui.map_missing:Get() or ui.gank:Get() then
        local shown = 0
        for _,e in ipairs(EC.enemies) do
            if shown >= 3 then break end
            local idx = nI(e)
            local st = idx and PSY.enemies[idx] or nil
            if st and st.predPos and (st.conf or 0) >= 45 and st.intent and st.intent ~= "FARM" and st.intent ~= "DEAD" then
                -- Nao desenhar ROTATE se o heroi sumiu ha muito tempo (previsao de posicao nao confiavel)
                local missTime = st.missTime or 0
                local skipDraw = (st.intent == "ROTATE" and missTime > 12)
                if not skipDraw then
                    local sx,sy,vis = w2s(Vector(st.predPos.x, st.predPos.y, (st.predPos.z or 0) + 20))
                    if vis and sx then
                        local pc = (st.intent == "GANK" and C.red) or (st.intent == "ROSH" and C.orange)
                            or (st.intent == "ROTATE" and C.cyan) or (st.intent == "PUSH" and C.yellow) or C.gray
                        -- Fade alpha baseado em missTime (mais tempo sumido = mais transparente)
                        local fadeAlpha = st.intent == "ROTATE" and clamp(1.0 - missTime / 15, 0.2, 1.0) or 1.0
                        drawCircleW(st.predPos, 120, colA(pc, F(70 * fadeAlpha)), 20)
                        local rotTxt = (LANG == "pt") and "rotacao" or st.intent
                        dText(8, (st.name or "?").." "..rotTxt.." "..F(st.conf or 0), sx-sc(40), sy-sc(14), colA(pc, F(255 * fadeAlpha)))
                        shown = shown + 1
                    end
                end
            end
        end
    end
    drawThreatOverlay()
    -- Tempo overlay
    drawTempo()
end

--------------------------------------------------------------------------------
-- PROJECTILE CALLBACKS
--------------------------------------------------------------------------------
local THREAT_PARTICLE_PATTERNS = {
    {p="kunkka", q="torrent", text="Torrent", radius=325, sev=74, ttl=1.7, color=C.cyan},
    {p="light_strike", text="LSA", radius=325, sev=72, ttl=1.4, color=C.orange},
    {p="split_earth", text="Split Earth", radius=325, sev=72, ttl=1.4, color=C.orange},
    {p="ice_path", text="Ice Path", radius=440, sev=68, ttl=1.8, color=C.cyan},
    {p="sun_strike", text="Sun Strike", radius=250, sev=95, ttl=1.8, color=C.red},
    {p="chrono", text="Chronosphere", radius=425, sev=99, ttl=4.2, color=C.purple},
    {p="black_hole", text="Black Hole", radius=420, sev=99, ttl=4.0, color=C.purple},
    {p="static_storm", text="Static Storm", radius=450, sev=84, ttl=3.5, color=C.cyan},
    {p="macropyre", text="Macropyre", radius=620, sev=76, ttl=3.5, color=C.orange},
    {p="arena_of_blood", text="Arena", radius=550, sev=88, ttl=4.0, color=C.red},
}

local THREAT_SOUND_PATTERNS = {
    {p="assassinate", text="Assassinate", sev=82, ttl=1.4, color=C.red},
    {p="charge_of_darkness", text="Charge", sev=78, ttl=1.6, color=C.purple},
    {p="requiem", text="Requiem", sev=76, ttl=1.4, color=C.red},
    {p="black_hole", text="Black Hole", sev=96, ttl=2.0, color=C.purple},
    {p="chronosphere", text="Chrono", sev=95, ttl=1.8, color=C.purple},
    {p="ravage", text="Ravage", sev=92, ttl=1.6, color=C.cyan},
}

function matchThreatPattern(name, patterns)
    if type(name) ~= "string" or name == "" then return nil end
    local low = name:lower()
    for _, p in ipairs(patterns) do
        if low:find(p.p, 1, true) and (not p.q or low:find(p.q, 1, true)) then
            return p, low
        end
    end
    return nil, low
end

function threatSourcePos(src, fallback)
    local p = src and nP(src) or nil
    if p then return p end
    if fallback then return fallback end
    return nil
end

function projectileLabel(data)
    if not data then return (LANG == "pt") and "projetil" or "projectile" end
    local srcName = ""
    if data.source then
        local sn = sG(NPC.GetUnitName, data.source)
        if sn and sn:find("hero") then srcName = hName(data.source).." " end
    end
    local a = data.ability
    if a then
        local nm = sG(Ability.GetName, a)
        if nm and nm ~= "" then
            return srcName..nm:gsub(".*_", ""):gsub("_", " ")
        end
    end
    if type(data.name) == "string" and data.name ~= "" then
        return srcName..data.name:gsub(".*:", ""):gsub("_projectile", ""):gsub("_", " ")
    end
    return srcName..((LANG == "pt") and "projetil" or "projectile")
end

function script.OnProjectile(data)
    if not data then return end
    if EC.hero then
        local tgt=data.target
        if ui.w_dodge:Get() and tgt and nI(tgt)==nI(EC.hero) and data.dodgeable and (data.moveSpeed or 0)>0 then
            DOD.txt=L("dodge_alert").." "..projectileLabel(data)
            DOD.t=os.clock()
        end
    end
    if ui.th_enable and ui.th_enable:Get() and ui.th_project and ui.th_project:Get() then
        local src = data.source
        if src and sG(Entity.GetTeamNum, src) ~= EC.heroTeam then
            -- Ignora projeteis de creeps/torres (nao sao perigo real)
            if not (sG(NPC.IsHero, src) == true) and not data.dodgeable then
                -- noop: ataque de creep/torre nao e ameaca relevante
            else
                local pos = threatSourcePos(src, EC.heroPos)
                if pos then
                    addThreatEvent("projectile", "trk:"..tostring(data.handle or 0), pos, 180, data.dodgeable and 62 or 35, 1.2,
                        projectileLabel(data), data.dodgeable and C.red or C.yellow)
                end
            end
        end
    end
end

function script.OnProjectileLoc(data)
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_project and ui.th_project:Get()) then return end
    if not data or not data.origin then return end
    local src = data.source
    if src and sG(Entity.GetTeamNum, src) == EC.heroTeam then return end
    -- Ignora projeteis de posicao de creeps/torres
    if src and not (sG(NPC.IsHero, src) == true) then return end
    addThreatEvent("projloc", "ploc:"..tostring(data.handle or 0), data.origin, 150, 45, 1.0,
        projectileLabel(data), C.yellow)
end

function script.OnLinearProjectileCreate(data)
    if not data or not data.source then return end
    local src = data.source
    if type(src) == "number" and Entities and Entities.Get then
        src = sG(Entities.Get, src)
    end
    if not src and data.ability then
        src = sG(Ability.GetOwner, data.ability)
    end
    if src and sG(Entity.GetTeamNum, src) == EC.heroTeam then return end
    -- Ignora projeteis lineares de creeps/torres
    if src and not (sG(NPC.IsHero, src) == true) then return end
    local origin=data.origin
    if ui.w_dodge:Get() and EC.heroAlive and EC.heroPos and origin and d2d(EC.heroPos,origin)<1500 then
        DOD.txt=L("dodge_alert").." "..projectileLabel(data):sub(1,14)
        DOD.t=os.clock()
    end
    if ui.th_enable and ui.th_enable:Get() and ui.th_project and ui.th_project:Get() and origin then
        local vel = data.velocity or Vector(0,0,0)
        local spd = math.sqrt((vel.x or 0)^2 + (vel.y or 0)^2 + (vel.z or 0)^2)
        local ttl = 1.4
        if spd > 1 and (data.distance or 0) > 1 then ttl = clamp((data.distance / spd) + 0.15, 0.3, 6.0) end
        local key = "lin:"..tostring(data.handle or 0)
        THREAT.byLinear[data.handle or key] = {created=gameNow(), key=key}
        addThreatEvent("linear", key, origin, math.max(110, sN(NPC.GetProjectileCollisionSize, EC.hero)), data.ability and 70 or 52, ttl,
            projectileLabel(data), C.red, {origin=origin, velocity=vel})
    end
end

function script.OnLinearProjectileDestroy(data)
    if not data then return end
    local key = "lin:"..tostring(data.handle or 0)
    THREAT.byLinear[data.handle or key] = nil
    removeThreatEvent(key)
end

function script.OnParticleCreate(data)
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_particle and ui.th_particle:Get()) then return end
    if not data or not data.index then return end
    local pat = matchThreatPattern(data.name, THREAT_PARTICLE_PATTERNS)
    if not pat then return end
    local ent = data.entity
    if ent and EC.heroTeam and sG(Entity.GetTeamNum, ent) == EC.heroTeam then return end
    local cp0 = type(data.controlPoints) == "table" and data.controlPoints[0] or nil
    local pos = cp0 or data.position or (ent and nP(ent)) or nil
    if not pos then return end
    local key = "pt:"..tostring(data.index)
    THREAT.byParticle[data.index] = {key=key, pat=pat}
    addThreatEvent("particle", key, pos, pat.radius, pat.sev, pat.ttl, pat.text, pat.color)
end

function script.OnParticleUpdate(data)
    if not data or not data.index then return end
    local tr = THREAT.byParticle[data.index]
    if not tr or not tr.pat or not data.position then return end
    addThreatEvent("particle", tr.key, data.position, tr.pat.radius, tr.pat.sev, 0.6, tr.pat.text, tr.pat.color)
end

function script.OnParticleUpdateFallback(data)
    if not data or not data.index then return end
    local tr = THREAT.byParticle[data.index]
    if not tr or not tr.pat or not data.position then return end
    addThreatEvent("particle", tr.key, data.position, tr.pat.radius, tr.pat.sev, 0.5, tr.pat.text, tr.pat.color)
end

function script.OnParticleUpdateEntity(data)
    if not data or not data.index then return end
    local tr = THREAT.byParticle[data.index]
    if not tr or not tr.pat then return end
    local pos = (data.entity and nP(data.entity)) or data.fallbackPosition
    if not pos then return end
    addThreatEvent("particle", tr.key, pos, tr.pat.radius, tr.pat.sev, 0.5, tr.pat.text, tr.pat.color)
end

function script.OnParticleDestroy(data)
    if not data or not data.index then return end
    local tr = THREAT.byParticle[data.index]
    if tr then
        removeThreatEvent(tr.key)
        THREAT.byParticle[data.index] = nil
    end
end

function script.OnStartSound(data)
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_sound and ui.th_sound:Get()) then return end
    if not data or not data.name then return end
    local pat = matchThreatPattern(data.name, THREAT_SOUND_PATTERNS)
    if not pat then return end
    local src = data.source
    if src and EC.heroTeam and sG(Entity.GetTeamNum, src) == EC.heroTeam then return end
    local pos = threatSourcePos(src, EC.heroPos)
    if not pos then return end
    local key = "snd:"..tostring(data.hash or data.name)
    if not threatThrottle(key, 1.0) then return end
    addThreatEvent("sound", key, pos, 260, pat.sev, pat.ttl, pat.text, pat.color)
end

function script.OnUnitAnimation(data)
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_anim and ui.th_anim:Get()) then return end
    if not data or not data.npc then return end
    local npc = data.npc
    if not (sG(NPC.IsHero, npc) == true) then return end  -- ignora creeps/torres/neutros
    if EC.heroTeam and sG(Entity.GetTeamNum, npc) == EC.heroTeam then return end
    if not nA(npc) then return end
    local cp = tonumber(data.castPoint or 0) or 0
    if cp <= 0.12 then return end
    local pos = nP(npc)
    if not pos or (EC.heroPos and d2d(pos, EC.heroPos) > 2000) then return end
    local idx = nI(npc) or 0
    local key = "anim:"..idx
    if not threatThrottle(key, 0.35) then return end
    local heroNm = hName(npc)
    local abNm = ""
    if data.sequenceName and data.sequenceName ~= "" then
        abNm = data.sequenceName:gsub(".*_", ""):gsub("_", " ")
    end
    local castWord = (LANG == "pt") and "conjurando" or "cast"
    local txt = heroNm.." "..castWord..(abNm ~= "" and (" "..abNm) or "")
    local sev = cp > 0.4 and 45 or 28
    addThreatEvent("animation", key, pos, 190, sev, clamp(cp + 0.4, 0.4, 1.2), txt, cp > 0.4 and C.orange or C.yellow)
end

function script.OnUnitAddGesture(data)
    if not (ui.th_enable and ui.th_enable:Get() and ui.th_anim and ui.th_anim:Get()) then return end
    if not data or not data.npc then return end
    local npc = data.npc
    if not (sG(NPC.IsHero, npc) == true) then return end  -- ignora creeps/torres/neutros
    if EC.heroTeam and sG(Entity.GetTeamNum, npc) == EC.heroTeam then return end
    local cp = tonumber(data.castPoint or 0) or 0
    if cp <= 0.18 then return end
    local pos = nP(npc)
    if pos and threatThrottle("gst:"..tostring(nI(npc) or 0), 0.45) then
        local wTxt = (LANG == "pt") and "preparando" or "windup"
        addThreatEvent("gesture", "gst:"..tostring(nI(npc) or 0), pos, 190, 36, clamp(cp + 0.25, 0.35, 1.0), hName(npc).." "..wTxt, C.yellow)
    end
end

function script.OnPrepareUnitOrders(data)
    if not (ui.guard_enable and ui.guard_enable:Get()) then return true end
    if not Engine.IsInGame() or not data then return true end
    local hero = EC.hero or sG(Heroes.GetLocal)
    if not hero or not nA(hero) then return true end
    if data.npc and nI(data.npc) and nI(data.npc) ~= nI(hero) then return true end
    local order = data.order
    local pos = data.position
    local queue = data.queue == true

    if ui.guard_channel and ui.guard_channel:Get() and not queue and (sG(NPC.IsChannelling, hero) or false) then
        if order ~= Enum.UnitOrder.STOP and order ~= Enum.UnitOrder.HOLD_POSITION then
            guardBlock("Guard: channel protected", EC.heroPos)
            return false
        end
    end

    if ui.guard_cast and ui.guard_cast:Get() and order == Enum.UnitOrder.CAST_TARGET and data.ability and data.target then
        local tgt = data.target
        if sG(Entity.GetTeamNum, tgt) ~= EC.heroTeam then
            local ok, why = canCastTargetAbilityTo(data.ability, tgt)
            if ok == false then
                guardBlock("Guard: "..tostring(why).." "..hName(tgt), nP(tgt))
                return false
            end
        end
    end

    if ui.guard_move and ui.guard_move:Get() and not queue and pos then
        local isMoveOrder =
            order == Enum.UnitOrder.MOVE_TO_POSITION or
            order == Enum.UnitOrder.ATTACK_MOVE or
            order == Enum.UnitOrder.CAST_POSITION or
            order == Enum.UnitOrder.CAST_TARGET_POSITION or
            order == Enum.UnitOrder.VECTOR_TARGET_POSITION or
            order == Enum.UnitOrder.MOVE_TO_DIRECTION or
            order == Enum.UnitOrder.MOVE_RELATIVE
        if isMoveOrder then
            local score = threatDangerAtPos(pos)
            if ui.guard_tower and not ui.guard_tower:Get() then
                -- crude tower penalty rollback if user disables tower checks
                score = score * 0.75
            end
            local thr = (ui.guard_thr and ui.guard_thr:Get()) or 95
            if score >= thr then
                guardBlock("Guard: danger "..F(score), pos)
                return false
            end
        end
    end
    return true
end

function script.OnUnitInventoryUpdated(data)
    EC.lastLight = 0; EC.lastFull = 0; nearCache.t = 0; nearCache.values = {}
end

function script.OnNpcSpawned(npc)
    EC.lastLight = 0; EC.lastFull = 0; nearCache.t = 0; nearCache.values = {}
end

function script.OnEntityDestroy(entity)
    EC.lastLight = 0; EC.lastFull = 0; nearCache.t = 0; nearCache.values = {}
end

function script.OnSetDormant(npc, dtype)
    EC.lastLight = 0; EC.lastFull = 0; nearCache.t = 0; nearCache.values = {}
end

function script.OnModifierCreate(entity, modifier)
    if entity and modifier then EC.lastLight = 0 end
end

function script.OnModifierDestroy(entity, modifier)
    EC.lastLight = 0
end

function script.OnGameRulesStateChange(data)
    EC.lastLight = 0; EC.lastFull = 0; nearCache.t = 0; nearCache.values = {}
end

function script.OnFireEventClient(ev)
    local name = nil
    if type(ev) == "string" then
        name = ev
    elseif type(ev) == "table" then
        name = ev.name or ev.event or ev[1]
    end
    if type(name) ~= "string" or name == "" then return end
    if not (ui.tempo_enable and ui.tempo_messages and ui.tempo_enable:Get() and ui.tempo_messages:Get()) then return end

    if name == "dota_roshan_kill" then
        tempoAddMsg(L("msg_rosh_killed"), C.orange, 8)
    elseif name == "dota_player_gained_level" then
        tempoAddMsg(L("msg_level_up"), C.gold, 3)
    elseif name == "dota_rune_activated_server" or name == "dota_rune_pickup" then
        tempoAddMsg(L("msg_rune_taken"), C.cyan, 3)
    elseif name == "glyph_used" then
        tempoAddMsg(L("msg_glyph_used"), C.yellow, 4)
    end
end

--------------------------------------------------------------------------------
-- COSMIC BACKGROUND
--------------------------------------------------------------------------------
local cosmic = {time=0, parts={}, stars={}, nebulae={}, shooters={}, inited=false}

function cosmicInit()
    if cosmic.inited then return end; cosmic.inited=true
    for i=1,150 do cosmic.stars[i]={x=math.random(0,1920),y=math.random(0,1080),sz=math.random(1,3),spd=math.random(1,5),ph=math.random()*6.28,br=math.random(50,100)/100} end
    for i=1,80 do cosmic.parts[i]={x=math.random(0,1920),y=math.random(0,1080),sz=math.random(1,3),spd=math.random(20,80)/100,ang=math.random()*6.28,br=math.random(30,100)/100,ci=math.random(1,2)} end
    for i=1,4 do cosmic.nebulae[i]={x=math.random(-100,1920),y=math.random(-100,1080),sz=math.random(200,400),rot=math.random()*6.28,rs=(math.random()-0.5)*0.05,cr=math.random(50,130),cg=math.random(50,130),cb=math.random(80,180),a=math.random(8,20)} end
end

function cosmicUpdate(dt)
    cosmic.time=cosmic.time+dt*0.1; local t=cosmic.time
    local doA=ui.cos_attract:Get()
    for i,p in ipairs(cosmic.parts) do
        if doA then
            local dx=mouse.x-p.x; local dy=mouse.y-p.y; local dist=math.sqrt(dx*dx+dy*dy)
            if dist<150 and dist>1 then
                local force=2.0*(1-dist/150); local tA=math.atan(dy,dx)
                local aD=tA-p.ang; while aD>3.14 do aD=aD-6.28 end; while aD<-3.14 do aD=aD+6.28 end
                p.ang=p.ang+aD*math.min(dt*3,0.3); p.spd=math.min(p.spd+force*dt*5,3.0); p.br=math.min(1.0,p.br+force*dt)
            else p.spd=p.spd+(0.5-p.spd)*dt*0.5; p.br=p.br+(0.5+math.sin(t*2+i)*0.3-p.br)*dt*0.5 end
        else p.br=0.5+math.sin(t*2+i)*0.3 end
        p.x=p.x+math.cos(p.ang)*p.spd*dt*8; p.y=p.y+math.sin(p.ang)*p.spd*dt*8
        if p.x<-30 then p.x=SW+20 end; if p.x>SW+30 then p.x=-20 end
        if p.y<-30 then p.y=SH+20 end; if p.y>SH+30 then p.y=-20 end
    end
    for _,s in ipairs(cosmic.stars) do s.br=0.5+math.sin(t*s.spd+s.ph)*0.5 end
    for _,n in ipairs(cosmic.nebulae) do n.rot=n.rot+n.rs*dt*0.3 end
    if ui.cos_shooting:Get() then
        if math.random()<0.005 then
            cosmic.shooters[#cosmic.shooters+1]={sx=math.random(0,F(SW)),sy=math.random(-50,0),ex=math.random(0,F(SW)),ey=math.random(F(SH),F(SH)+200),pr=0,spd=math.random(5,15)/10,sz=math.random(2,3),tail={}}
        end
        for i=#cosmic.shooters,1,-1 do
            local s=cosmic.shooters[i]; s.pr=s.pr+s.spd*dt*0.3
            if s.pr>=1 then table.remove(cosmic.shooters,i) else
                s.tail[#s.tail+1]={x=s.sx+(s.ex-s.sx)*s.pr,y=s.sy+(s.ey-s.sy)*s.pr}
                if #s.tail>15 then table.remove(s.tail,1) end
            end
        end
    end
end

function cosmicDraw()
    local c1=ui.cos_c1:Get(); local c2=ui.cos_c2:Get(); local dark=ui.cos_dark:Get()
    dRect(0,0,SW,SH,col(0,0,0,F(dark*2.55)))
    if ui.cos_nebula:Get() then
        for _,n in ipairs(cosmic.nebulae) do for j=1,4 do
            dCircle(n.x+math.cos(n.rot+j)*n.sz*0.25,n.y+math.sin(n.rot+j)*n.sz*0.25,n.sz*(0.4+j*0.1),col(n.cr,n.cg,n.cb,F(n.a*0.25)),16) end end
    end
    if ui.cos_stars:Get() then
        for _,s in ipairs(cosmic.stars) do
            local a=F(s.br*220); dCircle(s.x,s.y,s.sz,col(255,255,255,a),6)
            if s.br>0.85 then local rl=s.sz*3; local ra=F(a*0.3)
                dLine(s.x-rl,s.y,s.x+rl,s.y,col(255,255,255,ra)); dLine(s.x,s.y-rl,s.x,s.y+rl,col(255,255,255,ra)) end
        end
    end
    if ui.cos_aurora:Get() then
        local t=cosmic.time
        for wave=1,3 do local px,py
            for x2=0,F(SW),30 do
                local y2=80+math.sin((x2/SW)*6.28+t*2+wave)*150+math.sin((x2/SW)*12.56+t*3)*60
                if px then dLine(px,py,x2,y2,(wave%2==1) and col(100,255,150,F(30*(1-wave/4))) or col(150,100,255,F(30*(1-wave/4)))) end
                px,py=x2,y2
            end
        end
    end
    if ui.cos_shooting:Get() then
        for _,s in ipairs(cosmic.shooters) do
            for j=1,#s.tail-1 do dCircle(s.tail[j].x,s.tail[j].y,s.sz*(j/#s.tail),col(255,255,200,F((j/#s.tail)*180)),6) end
            if #s.tail>0 then local last=s.tail[#s.tail]; dCircle(last.x,last.y,s.sz,col(255,255,255,255),6); dCircle(last.x,last.y,s.sz*2.5,col(255,255,200,80),8) end
        end
    end
    local psz=ui.cos_psz:Get()
    for i,p in ipairs(cosmic.parts) do
        local pC=(p.ci==1) and c1 or c2; local a=F(p.br*140)
        if ui.cos_glow:Get() then dCircle(p.x,p.y,p.sz*psz*2.5,Color(pC.r,pC.g,pC.b,F(a*0.2)),8) end
        dCircle(p.x,p.y,p.sz*psz,Color(pC.r,pC.g,pC.b,a),6)
    end
    local pts=cosmic.parts; local mc=math.min(#pts,80)
    for i=1,mc do for j=i+1,math.min(i+5,mc) do
        local dx=pts[i].x-pts[j].x; local dy=pts[i].y-pts[j].y; local dist=math.sqrt(dx*dx+dy*dy)
        if dist<120 then dLine(pts[i].x,pts[i].y,pts[j].x,pts[j].y,col(255,255,255,F((120-dist)/120*35))) end
    end end
end

--------------------------------------------------------------------------------
-- MAIN CALLBACKS
--------------------------------------------------------------------------------
function runCoreTick()
    if not Engine.IsInGame() then return end
    local gtick = gameTick()
    if gtick > 0 and CORE.lastTick == gtick then return end
    if gtick > 0 then CORE.lastTick = gtick end

    local now = gameNow()
    if now <= 0 then return end
    gScale=(ui.scale:Get() or 100)/100
    local lc = ui.lang:Get()
    local nl = nil
    local li = ui.lang and sG(ui.lang.GetItem, ui.lang) or nil
    if type(li) == "string" then
        local low = li:lower()
        if low:find("russian", 1, true) or low:find("\u{0440}\u{0443}\u{0441}", 1, true) then
            nl = "ru"
        elseif low:find("portug", 1, true) then
            nl = "pt"
        elseif low:find("english", 1, true) or low:find("eng", 1, true) then
            nl = "en"
        end
    end
    if not nl then
        nl = (lc == 1) and "ru" or (lc == 2 and "pt" or "en") -- fallback for builds without GetItem()
    end
    if nl~=LANG then
        LANG=nl; sSet("lang",lc)
        clearLocaleRuntimeCaches()
        resetPanelsRuntime()
    end
    local ruModeIdx = uiGetVal(ui and ui.ru_render_mode, sGet("ru_render_mode", 1))
    if CORE.ruModeIdx ~= ruModeIdx then
        CORE.ruModeIdx = ruModeIdx
        sSet("ru_render_mode", ruModeIdx)
        applyRuRenderModeIndex(ruModeIdx)
        clearLocaleRuntimeCaches()
    end
    sSet("ui_panel_mode", uiGetVal(ui and ui.ui_panel_mode, 0))
    sSet("ui_auto_compact_thr", uiGetVal(ui and ui.ui_auto_compact_thr, 65))
    sSet("ui_font_floor", uiGetVal(ui and ui.ui_font_floor, 9))
    sSet("ui_text_shadow", uiGetVal(ui and ui.ui_text_shadow, true) and 1 or 0)
    sSet("ui_high_contrast", uiGetVal(ui and ui.ui_high_contrast, false) and 1 or 0)
    sSet("ui_blur", uiGetVal(ui and ui.ui_blur, true) and 1 or 0)
    sSet("ui_blur_strength", uiGetVal(ui and ui.ui_blur_strength, 7))
    sSet("ui_clip_panels", uiGetVal(ui and ui.ui_clip_panels, true) and 1 or 0)
    sSet("ui_show_panels", uiGetVal(ui and ui.ui_show_panels, true) and 1 or 0)
    sSet("ui_snap", uiGetVal(ui and ui.ui_snap, true) and 1 or 0)
    sSet("ui_snap_px", uiGetVal(ui and ui.ui_snap_px, 12))
    sSet("ui_drawer_tabs", uiGetVal(ui and ui.ui_drawer_tabs, true) and 1 or 0)
    sSet("ui_drawer_tab_w", uiGetVal(ui and ui.ui_drawer_tab_w, 18))
    sSet("ui_drawer_tab_h", uiGetVal(ui and ui.ui_drawer_tab_h, 44))
    sSet("combo_view", uiGetVal(ui and ui.combo_view, 2))
    sSet("combo_cd_ov", uiGetVal(ui and ui.combo_cd_ov, true) and 1 or 0)
    sSet("combo_tip", uiGetVal(ui and ui.combo_tip, true) and 1 or 0)
    sSet("pm_brain", uiGetVal(ui and ui.pm_brain, true) and 1 or 0)
    sSet("pm_intel", uiGetVal(ui and ui.pm_intel, true) and 1 or 0)
    sSet("pm_tracker", uiGetVal(ui and ui.pm_tracker, true) and 1 or 0)
    sSet("pm_sidebar", uiGetVal(ui and ui.pm_sidebar, true) and 1 or 0)
    applyPanelManagerSettings()
    refreshCache(now); if not EC.valid then return end
    updateThreats(now)

    local heavyInterval = ((ui.core_heavy_ms and ui.core_heavy_ms:Get()) or 120) / 1000
    if now-CORE.lastHeavy>=heavyInterval then
        CORE.lastHeavy=now
        updPsycho(now)
        updKM(now); updDB(now); updPG(now); updINI(now)
        updMapControl(now); updFarm(now); updTempo(now)
        updWorld(now); processAuto()
    end

    local flushInterval = ((ui.core_flush_ms and ui.core_flush_ms:Get()) or 30) / 1000
    if now - (ACTQ.lastRun or 0) >= flushInterval then
        flushActionQueue(now)
    end
    if now-saveTimer>10 then saveTimer=now; writeSave() end
end

function script.OnUpdateEx()
    runCoreTick()
end

function script.OnUpdate()
    runCoreTick()
end

function script.OnPreHumanizer()
    if not Engine.IsInGame() then return end
    flushActionQueue(gameNow())
end

function script.OnDraw()
    if not Engine.IsInGame() then return end
    if not initFonts() then return end
    if not UI_ASSETS.loaded then loadUIAssets() end
    if not panelsInit then refreshScreen(); initPanels() end
    if UI_ASSETS then UI_ASSETS.comboTip = nil end
    updMouse()
    local showPanels = uiGetVal(ui and ui.ui_show_panels, true)
    if not showPanels then
        drawWorld()
        return
    end
    local locked=ui.lock:Get()
    for i = #allPanels, 1, -1 do
        local p = allPanels[i]
        p:interact(locked)
        p:updateDrag()
    end
    for _,p in ipairs(allPanels) do
        if p ~= activePanel then p:render(locked) end
    end
    if activePanel then activePanel:render(locked) end
    drawWorld()
    drawComboTooltipOverlay()
end

function script.OnFrame()
    if not initFonts() then return end
    refreshScreen(); updMouse()
    if ui.cos_en:Get() then
        local menuOpen=false; local ok,val=pcall(function() return Menu.Opened() end)
        if ok and val then menuOpen=true end
        if menuOpen then cosmicInit(); cosmicUpdate(0.016); cosmicDraw() end
    end
end

function script.OnGameEnd()
    writeSave()
    KM={data={},rev={},t=0}
    DB={gpm=0,nw=0,momentum=0,winProb=50,allyPow=0,enemyPow=0,tips={},lastTip=0,mia={},init=false,startNW=0,startTime=0,t=0}
    PG={ally={},enemy={},t=0}; INI={bestPos=nil,bestScore=0,count=0,radius=450,risk=0,follow=0,travel=0,label="",t=0}
    FLASH={on=false,t=0,who=""}; SMOKE={on=false,t=0}; GANK={on=false,t=0,cnt=0}
    LINKEN={}; LH={targets={},t=0}; DOD={txt="",t=0}; prevAlive={}
    AUTO={phase=0,stick=0,faerie=0}; nearCache={t=0,values={}}
    CORE={lastTick=-1,lastHeavy=0,lastFast=0}
    ACTQ={q={},seq=0,stats={queued=0,ran=0,dropped=0,dedup=0},lastRun=0,lastDesc=""}
    GUARD={lastBlockTime=0,lastBlockReason="",blocks=0,rewrites=0}
    THREAT={events={},byParticle={},byLinear={},cd={},stats={created=0,expired=0,blockedOrders=0,pings=0},nearScore=0,lastAlert="",lastAlertTime=0,lastPingTime=0,t=0}
    MAP={safeFarm={},splitAdvice="",rune={state="",pos=nil,etaUs=0,etaEnemy=0},rosh={suspicion=0,reason=""},rotations={},forwardRisk=0,t=0}
    FARM={gpm=0,xpm=0,peakGPM=0,csMin=0,lastCS=0,deadT=0,aliveT=0,lastAC=0,eff=1,goldHist={},t=0}
    TEMPO={current_advice="",prev_advice="",current_score=0,advice_start_time=0,last_update_time=0,confidence=0,sub_reason="",sub_reason2="",fade_alpha=0,top_choices={},snapshot={},messages={},notified={},lastDeathCheck=0,prevAliveState={},inFight=false,lastFightTime=0}
    PSY={enemies={},top={name="",intent="",conf=0,pos=nil},team={gank=0,push=0,farm=0,retreat=0,rosh=0,rotate=0},pressure={hero=0,map=0,rosh=0},t=0}
    panelsInit=false; cosmic.shooters={}; allPanels={}; EC.valid=false
end

function script.OnMiniMapDraw()
    if not Engine.IsInGame() then return end
    drawThreatMiniMap()
end

function script.OnScriptsLoaded()
    initFonts()
    loadCanonicalData()
    loadUIAssets()
end

return script
