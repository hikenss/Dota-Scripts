--------------------------------------------------------------------------------
-- BUILD ENGINE — Main entry-point script
-- Ties together api_client, match_collector, threat_detector.
-- Fetches meta builds from OpenDota, adapts the next 3 items based on
-- enemy threats, updates every 60 seconds.
--------------------------------------------------------------------------------
local script = {}

--------------------------------------------------------------------------------
-- FILE LOGGER  — defined first so loadMod failures are visible in the log
--------------------------------------------------------------------------------
local LOG_FILE = "smart_build_debug.txt"
local _logFileHandle = nil
local function FLog(msg)
    local line = os.date("%H:%M:%S") .. " " .. tostring(msg)
    if not _logFileHandle then
        _logFileHandle = io.open(LOG_FILE, "a")
        if not _logFileHandle then
            _logFileHandle = io.open("c:\\UB\\scripts\\smart_build_debug.txt", "a")
        end
    end
    if _logFileHandle then
        _logFileHandle:write(line .. "\n")
        _logFileHandle:flush()
    end
    if type(Log) == "table" and type(Log.Write) == "function" then
        pcall(Log.Write, line)
    end
end
FLog("[BuildEngine] script loading…")

--------------------------------------------------------------------------------
-- MODULE LOADING
-- Tries require() first (works when Umbrella proxies local scripts), then
-- falls back to dofile() with relative and absolute paths.
--------------------------------------------------------------------------------
local function loadMod(name)
    -- 1) standard require (Umbrella may proxy this for scripts in the folder)
    local ok, mod = pcall(require, name)
    if ok and type(mod) == "table" then
        FLog("[loadMod] require OK: " .. name)
        return mod
    end
    FLog("[loadMod] require failed for " .. name .. ": " .. tostring(mod))

    -- 2) dofile with relative path (file next to build_engine.lua)
    ok, mod = pcall(dofile, name .. ".lua")
    if ok and type(mod) == "table" then
        FLog("[loadMod] dofile OK: " .. name)
        return mod
    end
    FLog("[loadMod] dofile failed for " .. name .. ".lua: " .. tostring(mod))

    -- 3) dofile with common absolute Umbrella path
    ok, mod = pcall(dofile, "c:\\UB\\scripts\\" .. name .. ".lua")
    if ok and type(mod) == "table" then
        FLog("[loadMod] dofile(abs) OK: " .. name)
        return mod
    end
    FLog("[loadMod] dofile(abs) failed for " .. name .. ": " .. tostring(mod))

    return nil
end

local api       = loadMod("api_client")
local collector = loadMod("match_collector")
local threats   = loadMod("threat_detector")

-- Log what loaded so the debug file always shows the true picture
FLog("[BuildEngine] api=" .. tostring(api ~= nil)
    .. " collector=" .. tostring(collector ~= nil)
    .. " threats=" .. tostring(threats ~= nil))

-- NOTE: we do NOT return early here even when modules are nil.
-- OnDraw will render an error message instead — this keeps the overlay
-- visible and the debug log reachable even during module load failures.

-- Initialize integrated STRATZ token before menu creation so the UI field
-- reflects the backend state even after Umbrella reloads scripts.
if api and type(api.initFromConfig) == "function" then
    api.initFromConfig()
end

-- Extended modules (non-fatal if missing)
local metaFetcher = loadMod("meta_fetcher")
local predictor   = loadMod("enemy_item_predictor")
local timingEng   = loadMod("item_timing_engine")
local learningEng = loadMod("learning_engine")

-- Cross-inject to break circular require: each module gets a reference to
-- the other through a setter rather than through require().
if threats   and predictor and type(threats.setPredictor)   == "function" then threats.setPredictor(predictor) end
if predictor and threats   and type(predictor.setThreats)   == "function" then predictor.setThreats(threats)   end

--------------------------------------------------------------------------------
-- ITEM DATABASE  (counter-items + meta-eligible items with tags & triggers)
-- phase: 1=early, 2=mid, 3=late
-- triggers: enemy tags that make this item relevant
-- tags: item capability tags (matched by COUNTER_RULES)
--------------------------------------------------------------------------------
local ITEM_DB = {
    -- Physical defense
    {name="item_ghost",          display="Ghost Scepter",     cost=1500, phase={1,2},   tags={"vs_phys","save"}},
    {name="item_blade_mail",     display="Blade Mail",        cost=2100, phase={1,2},   tags={"vs_phys","vs_burst","armor","reflect"},
     triggers={"carry","phys_burst","phys_dps"}},
    {name="item_vanguard",       display="Vanguard",          cost=1700, phase={1,2},   tags={"hp","block","tanky"}},
    {name="item_pavise",         display="Pavise",            cost=1100, phase={1,2},   tags={"vs_phys","save","armor"},
     triggers={"phys_dps","phys_burst"}},
    {name="item_crimson_guard",  display="Crimson Guard",     cost=3600, phase={2,3},   tags={"vs_phys","team","block","armor"},
     triggers={"phys_dps","summons","illusions","push"}},
    {name="item_assault",        display="Assault Cuirass",   cost=5125, phase={2,3},   tags={"armor","attack_speed","aura","vs_phys"},
     triggers={"phys_dps","carry","armor_reduce"}},
    {name="item_shivas_guard",   display="Shiva's Guard",     cost=5175, phase={2,3},   tags={"armor","vs_phys","slow","int"},
     triggers={"phys_dps","carry","heal","attack_speed"}},
    {name="item_heavens_halberd",display="Heaven's Halberd",  cost=3550, phase={2,3},   tags={"vs_phys","disarm","evasion","hp"},
     triggers={"carry","phys_dps","phys_burst"}},
    {name="item_solar_crest",    display="Solar Crest",       cost=2625, phase={1,2},   tags={"armor","vs_phys","buff","debuff"}},
    -- Magical defense
    {name="item_pipe",           display="Pipe of Insight",   cost=3475, phase={2,3},   tags={"vs_magic","team","magic_resist","barrier"},
     triggers={"magic_burst"}},
    {name="item_glimmer_cape",   display="Glimmer Cape",      cost=1950, phase={1,2},   tags={"vs_magic","save","invis"},
     triggers={"magic_burst","disable"}},
    {name="item_black_king_bar", display="BKB",               cost=4050, phase={2,3},   tags={"vs_magic","magic_immune","vs_disable"},
     triggers={"disable","stun","silence","hex","magic_burst","doom"}},
    -- Anti-heal
    {name="item_spirit_vessel",  display="Spirit Vessel",     cost=2980, phase={1,2},   tags={"anti_heal","hp","move_speed"},
     triggers={"heal","save","tanky"}},
    -- Anti-evasion
    {name="item_monkey_king_bar",display="MKB",               cost=4975, phase={2,3},   tags={"vs_evasion","phys_dps","attack"},
     triggers={"evasion"}},
    -- Anti-invis
    {name="item_dust",           display="Dust of Appearance", cost=80,  phase={1,2,3}, tags={"vs_invis","detection"},
     triggers={"invis"}},
    {name="item_ward_sentry",    display="Sentry Ward",        cost=50,  phase={1,2,3}, tags={"vs_invis","detection"},
     triggers={"invis"}},
    -- Anti-illusions
    {name="item_mjollnir",       display="Mjollnir",          cost=5600, phase={2,3},   tags={"vs_illusions","attack_speed","phys_dps","cleave"},
     triggers={"illusions","summons","push"}},
    {name="item_battlefury",     display="Battle Fury",       cost=4100, phase={1,2},   tags={"vs_illusions","cleave","farm","phys_dps"},
     triggers={"illusions","summons"}},
    {name="item_radiance",       display="Radiance",          cost=5150, phase={2,3},   tags={"vs_illusions","burn","miss","farm"},
     triggers={"illusions","summons","invis"}},
    {name="item_maelstrom",      display="Maelstrom",         cost=2700, phase={1,2},   tags={"vs_illusions","attack_speed","farm"},
     triggers={"illusions","summons"}},
    {name="item_gungir",         display="Gleipnir",          cost=5500, phase={2,3},   tags={"root","vs_illusions","attack_speed","phys_dps"},
     triggers={"mobility","illusions","invis"}},
    -- Mobility / Positioning
    {name="item_blink",          display="Blink Dagger",      cost=2250, phase={1,2,3}, tags={"mobility","initiation"}},
    {name="item_force_staff",    display="Force Staff",       cost=2200, phase={1,2},   tags={"mobility","save","vs_slow"},
     triggers={"slow","root"}},
    {name="item_hurricane_pike", display="Hurricane Pike",    cost=4450, phase={2,3},   tags={"mobility","save","vs_melee","ranged"}},
    {name="item_harpoon",        display="Harpoon",           cost=4700, phase={2,3},   tags={"initiation","gap_close","stats"}},
    -- Dispel / Purge
    {name="item_lotus_orb",      display="Lotus Orb",         cost=3850, phase={2,3},   tags={"dispel","reflect","armor","mana"},
     triggers={"disable","stun","hex","silence","doom"}},
    {name="item_manta",          display="Manta Style",       cost=4600, phase={2,3},   tags={"dispel","illusions","stats","phys_dps"},
     triggers={"silence","slow","root"}},
    {name="item_disperser",      display="Disperser",         cost=5300, phase={2,3},   tags={"dispel","mobility","agi","slow"},
     triggers={"silence","slow","root","disable"}},
    {name="item_cyclone",        display="Eul's Scepter",     cost=2725, phase={1,2},   tags={"dispel","mana","mobility","disable"},
     triggers={"silence","slow","disable"}},
    -- Protection / Save
    {name="item_sphere",         display="Linken's Sphere",   cost=4600, phase={2,3},   tags={"block_spell","save","stats"},
     triggers={"disable","hex","doom","duel","black_hole"}},
    {name="item_aeon_disk",      display="Aeon Disk",         cost=3000, phase={2,3},   tags={"save","vs_burst","dispel"},
     triggers={"phys_burst","magic_burst","chrono","black_hole"}},
    {name="item_wind_waker",     display="Wind Waker",        cost=5150, phase={2,3},   tags={"save","dispel","mobility","mana"},
     triggers={"disable","chrono","black_hole"}},
    -- Offensive
    {name="item_desolator",      display="Desolator",         cost=3500, phase={2},     tags={"armor_reduce","phys_dps"}},
    {name="item_daedalus",       display="Daedalus",          cost=5150, phase={2,3},   tags={"crit","phys_dps"}},
    {name="item_butterfly",      display="Butterfly",         cost=4975, phase={3},     tags={"evasion","attack_speed","agi","phys_dps"}},
    {name="item_satanic",        display="Satanic",           cost=5050, phase={3},     tags={"lifesteal","hp","save","phys_dps"}},
    {name="item_skadi",          display="Eye of Skadi",      cost=5300, phase={3},     tags={"slow","stats","hp","anti_heal"},
     triggers={"heal","tanky","mobility"}},
    {name="item_abyssal_blade",  display="Abyssal Blade",     cost=6250, phase={3},     tags={"stun","bash","vs_bkb","phys_dps","block"},
     triggers={"magic_immune","carry"}},
    {name="item_nullifier",      display="Nullifier",         cost=4725, phase={3},     tags={"dispel","vs_save","phys_dps"},
     triggers={"save","invis","evasion"}},
    {name="item_bloodthorn",     display="Bloodthorn",        cost=6800, phase={3},     tags={"silence","crit","vs_evasion","attack_speed"},
     triggers={"evasion","mobility","magic_burst"}},
    {name="item_silver_edge",    display="Silver Edge",       cost=5450, phase={2,3},   tags={"invis","break","phys_dps"},
     triggers={"tanky","evasion"}},
    {name="item_diffusal_blade", display="Diffusal Blade",    cost=2500, phase={1,2},   tags={"mana_burn","slow","agi","phys_dps"},
     triggers={"mana_burn"}},
    -- Utility
    {name="item_rod_of_atos",    display="Rod of Atos",       cost=2750, phase={1,2},   tags={"root","hp","int"},
     triggers={"mobility","invis"}},
    {name="item_orchid",         display="Orchid Malevolence", cost=3475, phase={2},     tags={"silence","mana","attack_speed"},
     triggers={"magic_burst","mobility","versatile"}},
    {name="item_sheepstick",     display="Scythe of Vyse",    cost=5675, phase={3},     tags={"hex","disable","mana","int"},
     triggers={"carry","magic_immune","mobility"}},
    {name="item_heart",          display="Heart of Tarrasque", cost=5000, phase={3},     tags={"hp","tanky","regen"},
     triggers={"phys_dps","magic_burst"}},
    -- Support aura items
    {name="item_mekansm",        display="Mekansm",           cost=1775, phase={1,2},   tags={"heal","team","armor"}},
    {name="item_guardian_greaves",display="Guardian Greaves",  cost=4950, phase={2,3},   tags={"heal","team","dispel","armor","mana"},
     triggers={"disable","silence"}},
    {name="item_vladmir",        display="Vladmir's Offering",cost=2200, phase={1,2},   tags={"team","aura","armor","mana","lifesteal"}},
    -- Boots
    {name="item_phase_boots",    display="Phase Boots",       cost=1500, phase={1,2},   tags={"mobility","phys_dps","armor"}},
    {name="item_power_treads",   display="Power Treads",      cost=1400, phase={1,2},   tags={"attack_speed","stats","sustain"}},
    {name="item_arcane_boots",   display="Arcane Boots",      cost=1300, phase={1,2},   tags={"mana","team_utility"}},
    -- Aghs
    {name="item_ultimate_scepter",display="Aghanim's Scepter",cost=4200, phase={2,3},   tags={"ultimate","stats"}},
    {name="item_aghanims_shard", display="Aghanim's Shard",   cost=1400, phase={2,3},   tags={"ultimate","ability"}},
}

-- Build fast lookup
local ITEM_LOOKUP = {}
for _, def in ipairs(ITEM_DB) do ITEM_LOOKUP[def.name] = def end

-- Item name aliases (canonical form)
local ITEM_ALIASES = {
    item_bkb = "item_black_king_bar", item_bfury = "item_battlefury",
    item_mkb = "item_monkey_king_bar", item_linkens = "item_sphere",
    item_euls = "item_cyclone", item_shadow_blade = "item_invis_sword",
    item_gleipnir = "item_gungir", item_glimmer = "item_glimmer_cape",
    item_scythe_of_vyse = "item_sheepstick",
}

local function canonItem(name)
    return ITEM_ALIASES[name] or name
end

--------------------------------------------------------------------------------
-- ITEM REASON STRINGS  (concise explanations for the UI)
--------------------------------------------------------------------------------
local ITEM_REASONS = {
    item_ghost           = "Panic button vs right-click focus",
    item_blade_mail      = "Damage reflection vs carry commits",
    item_crimson_guard   = "Team phys damage shield + block",
    item_assault         = "Armor aura + enemy armor reduction",
    item_shivas_guard    = "Armor + slow vs phys DPS",
    item_heavens_halberd = "Disarm shuts down right-click cores",
    item_pipe            = "Team magic barrier vs spell spam",
    item_glimmer_cape    = "Save ally + magic resist + fade",
    item_black_king_bar  = "Magic immunity — must have vs CC",
    item_spirit_vessel   = "45% heal reduction",
    item_monkey_king_bar = "True Strike vs evasion",
    item_dust            = "Reveal invisible heroes",
    item_ward_sentry     = "Sentry for invis vision + deward",
    item_mjollnir        = "Lightning chain vs illusions/summons",
    item_battlefury      = "Cleave clears illusions + farm",
    item_blink           = "Mobility and initiation",
    item_force_staff     = "Escape from slows / reposition",
    item_lotus_orb       = "Self-dispel + reflect targeted spells",
    item_manta           = "Dispel + illusions for push/fight",
    item_sphere          = "Blocks one targeted spell",
    item_aeon_disk       = "Prevents getting bursted 100 → 0",
    item_nullifier       = "Purge enemy buffs (Ghost/Glimmer/Aeon)",
    item_orchid          = "Silence vs casters / mobile cores",
    item_sheepstick      = "Hex — strongest disable in the game",
    item_heart           = "Huge HP pool for late game",
    item_silver_edge     = "Break disables passives (Bristle, PA)",
    item_disperser       = "Strong self-dispel + enemy slow",
    item_wind_waker      = "Save ally (Tornado + dispel)",
    item_skadi           = "Slow + stats + heal reduction",
    item_abyssal_blade   = "Pierces BKB + bash",
    item_desolator       = "Armor reduction for phys damage",
    item_daedalus        = "Critical strike for late game DPS",
    item_butterfly       = "Evasion + agi + attack speed",
    item_bloodthorn      = "Silence + True Strike + crit",
    item_guardian_greaves = "Greaves: aura + dispel + heal",
    item_radiance        = "Burn aura + miss vs illusions",
    item_gungir          = "AoE root + lightning vs mobile heroes",
    item_harpoon         = "Pull to enemy for initiation",
    item_cyclone         = "Self-dispel / setup / cancel channels",
    item_hurricane_pike  = "Spacing from melee jumpers",
    item_rod_of_atos     = "Root pins down mobile heroes",
    item_diffusal_blade  = "Mana burn + slow",
    item_satanic         = "Lifesteal + active heal in fights",
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local S = {
    metaBuild       = nil,   -- normalized OpenDota build { start, early, mid, late }
    stratzBuild     = nil,   -- normalized STRATZ build (same format)
    mergedBuild     = nil,   -- merged OpenDota + STRATZ build
    metaSource      = "none",
    metaHeroID      = nil,
    threatProfile   = nil,   -- last computed threat analysis
    teamAxes        = nil,   -- 5-axis team threat breakdown
    enemyItemInfo   = nil,   -- enemy item analysis (alerts, counters)
    predictions     = nil,   -- predictive enemy item data
    metaScores      = nil,   -- meta_fetcher popularity scores { itemKey = 0.0–1.0 }
    recommendations = {},    -- top N adapted items (with 6-factor breakdown)
    warnings        = {},    -- threat warning strings
    lastUpdateAt    = -100,  -- negative ensures first refresh fires as soon as isInGame() = true
    lastSnapshot    = nil,   -- most recent match_collector snapshot
    lastUIStateKey  = nil,
    initialized     = false,
}

--------------------------------------------------------------------------------
-- FONT (loaded once, cached)
-- fontHandle = 1 is a hardcoded handle that always works in Umbrella.
-- We try to load a nicer font first, but fall back to 1 unconditionally.
--------------------------------------------------------------------------------
local _font = nil
local function ensureFont()
    if _font then return _font end
    local flags = (Enum and Enum.FontCreate and Enum.FontCreate.FONTFLAG_ANTIALIAS) or 0
    if Render and Render.LoadFont then
        local ok, f
        ok, f = pcall(Render.LoadFont, "Segoe UI", 14, flags)
        if ok and f and f ~= 0 then _font = f; return _font end
        ok, f = pcall(Render.LoadFont, "Tahoma", 14, flags)
        if ok and f and f ~= 0 then _font = f; return _font end
        ok, f = pcall(Render.LoadFont, "Arial", 14, flags)
        if ok and f and f ~= 0 then _font = f; return _font end
    end
    _font = 1  -- builtin handle, always available in Umbrella
    return _font
end

--------------------------------------------------------------------------------
-- SHOP DETECTION  (same approach as Item Build.lua)
--------------------------------------------------------------------------------
local _shopPanel         = nil
local _shopPanelDoneAt   = -999
local _shopCache         = false
local _shopCacheAt       = -999

local function _findShopPanel()
    if _shopPanel then
        local valid = true
        if type(_shopPanel) == "table" and type(_shopPanel.IsValid) == "function" then
            local ok, v = pcall(_shopPanel.IsValid, _shopPanel)
            valid = not ok or v == true
        end
        if valid then return _shopPanel end
        _shopPanel = nil
    end
    local now = (GameRules and GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    if now - _shopPanelDoneAt < 1.0 then return nil end
    _shopPanelDoneAt = now
    if type(Panorama) ~= "table" then return nil end
    if type(Panorama.GetPanelByName) == "function" then
        local ok, p = pcall(Panorama.GetPanelByName, "shop", false)
        if ok and p then _shopPanel = p; return p end
        ok, p = pcall(Panorama.GetPanelByName, "ShopPanel", false)
        if ok and p then _shopPanel = p; return p end
        -- fallback: search inside Hud
        local okH, hud = pcall(Panorama.GetPanelByName, "Hud", false)
        if okH and hud and type(hud.FindChildTraverse) == "function" then
            local okF, nested = pcall(hud.FindChildTraverse, hud, "shop")
            if okF and nested then _shopPanel = nested; return nested end
        end
    end
    return nil
end

local function IsShopOpen()
    local now = (GameRules and GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    if now - _shopCacheAt < 0.2 then return _shopCache end
    _shopCacheAt = now
    local panel = _findShopPanel()
    if panel and type(panel.HasClass) == "function" then
        local ok, has = pcall(panel.HasClass, panel, "ShopOpen")
        if ok then _shopCache = (has == true); return _shopCache end
    end
    _shopCache = false
    return false
end

--------------------------------------------------------------------------------
local UI = {}

do
    local tab = Menu.Create("General", "AI", "Smart Build")
    if tab then
        tab:Icon("\u{f07a}")

        local main = tab:Create("Main")
        local settings = main:Create("Settings")

        UI.enabled         = settings:Switch("Enable Smart Build", true, "\u{f00c}")
        UI.visibilityMode  = settings:Combo("Show Panel", {"Always", "Only Shop"}, 0)
        UI.maxItems        = settings:Slider("Max Suggestions", 1, 6, 3, "%d")
        UI.showThreats     = settings:Switch("Show Threat Warnings", true, "\u{f071}")
        UI.showAxes        = settings:Switch("Show Threat Axes", true, "\u{f080}")
        UI.showPredictions = settings:Switch("Show Enemy Predictions", false, "\u{f1e0}")
        UI.debugLogs       = settings:Switch("Debug Logs", false, "\u{f188}")

        UI.enabled:ToolTip("Master toggle for Smart Build item recommendations")
        UI.visibilityMode:ToolTip("Always: always visible | Only Shop: show only when shop is open")
        UI.showAxes:ToolTip("Display 5-axis threat breakdown bars")
        UI.showPredictions:ToolTip("Show predicted enemy item purchases")
        UI.debugLogs:ToolTip("Print scoring details to console log")

        -- STRATZ is now always enabled with the built-in token.
        -- No token input needed in the menu.
        if api and type(api.configureStratz) == "function" then
            api.configureStratz(api.getStratzToken and api.getStratzToken() or "", true)
        end
    end
end

-- Initialize learning engine (loads persistent stats from disk)
if learningEng then learningEng.init() end

S.initialized = true
FLog("[BuildEngine] Loaded. Modules: api_client, match_collector, threat_detector"
    .. (metaFetcher and ", meta_fetcher" or "")
    .. (predictor and ", enemy_item_predictor" or "")
    .. (timingEng and ", item_timing_engine" or "")
    .. (learningEng and ", learning_engine" or "")
)

local function dbg(msg)
    if UI.debugLogs and UI.debugLogs:Get() then
        Log.Write("[BuildEngine] " .. tostring(msg))
    end
end

local function logUIState(key, msg)
    if S.lastUIStateKey == key then return end
    S.lastUIStateKey = key
    FLog("[BuildEngine|UI] " .. tostring(msg))
end

--------------------------------------------------------------------------------
-- 6-FACTOR SCORING ALGORITHM
--
-- final_score = meta_score + threat_score + counter_score
--             + timing_score + prediction_score + learning_score
--
-- Each factor is computed independently and stored in the recommendation
-- object for debug visibility.
--
-- meta_score      — How popular this item is in high-level play (0–10)
-- threat_score    — How well it counters current enemy threats (0–30+)
-- counter_score   — Bonus for countering specific enemy items  (0–10)
-- timing_score    — Bonus/penalty based on purchase timing     (-5 to +5)
-- prediction_score— Counters items enemies are predicted to buy (0–6)
-- learning_score  — Cross-match win-rate signal for hero+item  (-4 to +4)
--------------------------------------------------------------------------------
local function adaptBuild(snapshot, metaBuild, profile, maxItems, enemyItemAnalysis, teamAxes)
    maxItems = maxItems or 3
    local phase = snapshot.phase
    local gameTime = snapshot.gameTime or 0

    -- Pre-compute meta popularity via meta_fetcher (if available)
    local metaPopScores = S.metaScores  -- { itemKey = 0.0–1.0 }

    -- Fallback: compute meta popularity from raw build data
    if not metaPopScores then
        metaPopScores = {}
        local metaPhaseKeys = {}
        if phase == collector.PHASE_EARLY then
            metaPhaseKeys = {"early", "start"}
        elseif phase == collector.PHASE_MID then
            metaPhaseKeys = {"mid", "early"}
        else
            metaPhaseKeys = {"late", "mid"}
        end
        local maxPop = 1
        if metaBuild then
            for _, pk in ipairs(metaPhaseKeys) do
                local bucket = metaBuild[pk]
                if bucket then
                    for _, entry in ipairs(bucket) do
                        if entry.pop > maxPop then maxPop = entry.pop end
                    end
                end
            end
            for _, pk in ipairs(metaPhaseKeys) do
                local bucket = metaBuild[pk]
                if bucket then
                    for _, entry in ipairs(bucket) do
                        local key = canonItem(entry.key)
                        if not metaPopScores[key] then
                            metaPopScores[key] = entry.pop / maxPop
                        end
                    end
                end
            end
        end
    end

    -- Score every item in ITEM_DB through 6 factors
    local candidates = {}
    local seen = {}
    for _, itemDef in ipairs(ITEM_DB) do
        local key = itemDef.name
        if seen[key] then goto next_item end
        seen[key] = true

        -- FACTOR 1: threat_score — from threat_detector.scoreItem()
        local threat_score = threats.scoreItem(itemDef, profile, phase,
                                               snapshot.myItemSet, snapshot.heroName,
                                               enemyItemAnalysis, teamAxes)
        if threat_score < 0 then goto next_item end  -- owned or excluded

        -- Losing adaptation boost baked into threat_score
        if snapshot.isLosing and itemDef.tags then
            local defTags = {vs_phys=true, vs_magic=true, save=true, vs_disable=true,
                             hp=true, armor=true, magic_immune=true, vs_burst=true}
            for _, tag in ipairs(itemDef.tags) do
                if defTags[tag] then
                    threat_score = threat_score + 3
                    break
                end
            end
        end

        -- FACTOR 2: meta_score — popularity in high-level play (0–10)
        local metaPop    = metaPopScores[key] or 0
        local meta_score = metaPop * 10

        -- FACTOR 3: counter_score — bonus for countering specific enemy items
        local counter_score = 0
        if enemyItemAnalysis and enemyItemAnalysis.counterSuggestions then
            for _, suggestion in ipairs(enemyItemAnalysis.counterSuggestions) do
                if suggestion == key then
                    counter_score = counter_score + 4
                end
            end
        end
        -- Extra: direct ITEM_VS_ITEM counter matches
        if enemyItemAnalysis and enemyItemAnalysis.allItems then
            for _, enemyItem in ipairs(enemyItemAnalysis.allItems) do
                local counters = threats.ITEM_VS_ITEM[enemyItem]
                if counters then
                    for _, c in ipairs(counters) do
                        if c == key then counter_score = counter_score + 2 end
                    end
                end
            end
        end
        counter_score = math.min(counter_score, 10)

        -- FACTOR 4: timing_score — purchase timing bonus/penalty (-5 to +5)
        local timing_score = 0
        if timingEng then
            timing_score = timingEng.computeTimingScore(key, gameTime)
        end

        -- FACTOR 5: prediction_score — counter items enemies are predicted to buy
        local prediction_score = 0
        if S.predictions and S.predictions.anticipatedItems then
            for anticipatedItem in pairs(S.predictions.anticipatedItems) do
                local counters = threats.ITEM_VS_ITEM[anticipatedItem]
                if counters then
                    for _, c in ipairs(counters) do
                        if c == key then prediction_score = prediction_score + 2 end
                    end
                end
            end
            prediction_score = math.min(prediction_score, 6)
        end

        -- FACTOR 6: learning_score — cross-match win-rate signal (-4 to +4)
        local learning_score = 0
        if learningEng then
            learning_score = learningEng.computeScore(snapshot.heroName, key)
        end

        -- Affordability micro-bonus (not a full factor, keeps tiebreakers practical)
        local affordBonus = 0
        if snapshot.myGold and snapshot.myGold > 0 and itemDef.cost then
            if itemDef.cost <= snapshot.myGold then affordBonus = 1 end
        end

        -- FINAL 6-FACTOR SCORE
        local final_score = meta_score + threat_score + counter_score
                          + timing_score + prediction_score + learning_score
                          + affordBonus

        if final_score > 0 then
            candidates[#candidates + 1] = {
                key              = key,
                display          = itemDef.display,
                cost             = itemDef.cost,
                score            = final_score,
                -- Individual factors (for debug panel)
                meta_score       = meta_score,
                threat_score     = threat_score,
                counter_score    = counter_score,
                timing_score     = timing_score,
                prediction_score = prediction_score,
                learning_score   = learning_score,
                reason           = ITEM_REASONS[key] or "",
                fromMeta         = metaPop > 0,
            }
        end
        ::next_item::
    end

    -- Sort descending by score
    table.sort(candidates, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return (a.cost or 0) > (b.cost or 0)
    end)

    -- Diversity filter: avoid recommending items with identical primary function
    local selected = {}
    local functionUsed = {}
    for _, c in ipairs(candidates) do
        if #selected >= maxItems then break end
        local dominated = false
        local def = ITEM_LOOKUP[c.key]
        if def and def.triggers then
            local dominantTag = def.triggers[1]
            if dominantTag then
                local uses = functionUsed[dominantTag] or 0
                if uses >= 2 then dominated = true end
                functionUsed[dominantTag] = uses + 1
            end
        end
        if not dominated then
            selected[#selected + 1] = c
        end
    end

    return selected
end

--------------------------------------------------------------------------------
-- FULL REFRESH (called every UPDATE_INTERVAL seconds)
--------------------------------------------------------------------------------
local function fullRefresh()
    local snap = collector.collectSnapshot()
    if not snap then
        FLog("[BuildEngine] fullRefresh: collectSnapshot returned nil")
        return
    end
    S.lastSnapshot = snap
    FLog(string.format("[BuildEngine] fullRefresh: hero=%s heroID=%s phase=%s gt=%.0f enemies=%d gold=%s",
        tostring(snap.heroName), tostring(snap.heroID),
        tostring(snap.phase), snap.gameTime or 0,
        #snap.enemies, tostring(snap.myGold)))

    -- 1. Fetch / refresh meta build (OpenDota)
    local heroID = snap.heroID
    if heroID and heroID ~= S.metaHeroID then
        -- New hero — fetch immediately
        S.metaHeroID = heroID
        api.fetchBuild(heroID, function(data, source)
            S.metaBuild  = data
            S.metaSource = source
            local total = 0
            if data then
                for _, ph in ipairs({"start","early","mid","late"}) do
                    total = total + #(data[ph] or {})
                end
            end
            Log.Write(string.format("[BuildEngine] OpenDota callback: source=%s items=%d", tostring(source), total))
            FLog(string.format("[BuildEngine] OpenDota callback: source=%s items=%d", tostring(source), total))
            dbg("Meta build loaded via " .. source)
            -- Merge with STRATZ if available
            if S.stratzBuild then
                S.mergedBuild = api.mergeSources(S.metaBuild, S.stratzBuild)
            else
                S.mergedBuild = S.metaBuild
            end
        end)
        -- Also fetch STRATZ if enabled
        if api.canStratzRequest() then
            api.fetchStratzBuild(heroID, function(data, source)
                S.stratzBuild = data
                dbg("STRATZ build loaded via " .. source)
                S.mergedBuild = api.mergeSources(S.metaBuild, S.stratzBuild)
            end)
        end
    elseif heroID and api.canRequest() then
        -- Periodic re-fetch
        api.fetchBuild(heroID, function(data, source)
            S.metaBuild  = data
            S.metaSource = source
            if S.stratzBuild then
                S.mergedBuild = api.mergeSources(S.metaBuild, S.stratzBuild)
            else
                S.mergedBuild = S.metaBuild
            end
        end)
        if api.canStratzRequest() then
            api.fetchStratzBuild(heroID, function(data, source)
                S.stratzBuild = data
                S.mergedBuild = api.mergeSources(S.metaBuild, S.stratzBuild)
            end)
        end
    end

    -- 2. Threat analysis + 5-axis scoring
    if #snap.enemies > 0 then
        S.threatProfile = threats.analyze(snap.enemies)
        S.warnings      = S.threatProfile.warnings
        S.teamAxes      = threats.computeTeamThreatAxes(snap.enemies, snap.gameTime)
        S.enemyItemInfo = threats.analyzeEnemyItems(snap.enemies)

        -- Use enemy_item_predictor module if available, fallback to threat_detector
        if predictor then
            S.predictions = predictor.predict(snap.enemies, api, snap.gameTime)
        else
            S.predictions = threats.predictEnemyItems(snap.enemies, api, snap.gameTime)
        end

        -- Add enemy item alerts to warnings
        if S.enemyItemInfo and S.enemyItemInfo.alerts then
            for i = 1, math.min(#S.enemyItemInfo.alerts, 3) do
                local a = S.enemyItemInfo.alerts[i]
                S.warnings[#S.warnings + 1] = a.hero .. ": " .. a.note
            end
        end
    else
        S.threatProfile = nil
        S.teamAxes      = nil
        S.enemyItemInfo = nil
        S.predictions   = nil
        S.warnings      = {}
    end

    -- 2b. Fetch meta popularity scores via meta_fetcher
    if metaFetcher and heroID then
        metaFetcher.fetch(heroID, snap.phase, function(scores)
            S.metaScores = scores
        end)
    end

    -- 3. Adapt build using merged data + all analysis
    if S.threatProfile then
        local maxItems = UI.maxItems and UI.maxItems:Get() or 3
        local buildData = S.mergedBuild or S.metaBuild
        S.recommendations = adaptBuild(snap, buildData, S.threatProfile, maxItems,
                                       S.enemyItemInfo, S.teamAxes)
    else
        S.recommendations = {}
    end

    S.lastUpdateAt = collector.getRawGameTime()
    local recCount = #S.recommendations
    FLog(string.format("[BuildEngine] fullRefresh DONE: enemies=%d warnings=%d recs=%d axes=%s meta=%s",
        #snap.enemies, #S.warnings, recCount,
        S.teamAxes and S.teamAxes.dominant or "n/a", S.metaSource))
    if recCount == 0 then
        FLog("[BuildEngine] WARNING: 0 recommendations generated. metaBuild=" ..
            tostring(S.metaBuild ~= nil) .. " threatProfile=" .. tostring(S.threatProfile ~= nil) ..
            " mergedBuild=" .. tostring(S.mergedBuild ~= nil))
    end
    dbg(string.format("Refresh: %d enemies, %d warnings, %d recs, axes=%s",
        #snap.enemies, #S.warnings, recCount,
        S.teamAxes and S.teamAxes.dominant or "n/a"))
end

--------------------------------------------------------------------------------
-- CALLBACKS
--------------------------------------------------------------------------------
function script.OnUpdate()
    if not (UI.enabled and UI.enabled:Get()) then return end

    local now = collector.getRawGameTime()
    if (now - S.lastUpdateAt) >= UPDATE_INTERVAL then
        collector.invalidateCache()
        fullRefresh()
    end
end

local function ShouldDrawPanel()
    if not (UI.enabled and UI.enabled:Get()) then return false end
    if UI.visibilityMode then
        local mode = UI.visibilityMode:Get() or 0
        if mode >= 1 then  -- Only Shop
            return IsShopOpen()
        end
    end
    return true  -- Always
end

function script.OnDraw()
    if not ShouldDrawPanel() then return end

    -- If core modules failed to load, draw a visible error panel instead.
    if not api or not collector or not threats then
        local font  = ensureFont()
        local cBg   = Color(14, 16, 22, 220)
        local cRed  = Color(240, 80, 70, 255)
        local cDim  = Color(150, 155, 165, 220)
        Render.FilledRect(Vec2(20, 140), Vec2(340, 195), cBg, 6)
        Render.Text(font, 14, "Smart Build — module load error", Vec2(28, 147), cRed)
        local missing = {}
        if not api       then missing[#missing+1] = "api_client" end
        if not collector then missing[#missing+1] = "match_collector" end
        if not threats   then missing[#missing+1] = "threat_detector" end
        Render.Text(font, 11, "Missing: " .. table.concat(missing, ", "), Vec2(28, 165), cDim)
        Render.Text(font, 11, "See smart_build_debug.txt for details", Vec2(28, 179), cDim)
        return
    end

    -- Fallback bootstrap: if OnUpdate did not populate the first snapshot yet,
    -- try once from OnDraw so the panel does not remain stuck forever.
    if not S.lastSnapshot then
        local bootSnap = collector.collectSnapshot()
        if bootSnap then
            S.lastSnapshot = bootSnap
            FLog("[BuildEngine|UI] Bootstrap snapshot acquired from OnDraw")
            local now = collector.getRawGameTime()
            if (now - S.lastUpdateAt) >= UPDATE_INTERVAL then
                fullRefresh()
            end
        end
    end

    -- ── Layout constants ────────────────────────────────────────────────────
    local font      = ensureFont()   -- always returns at least 1
    local panelW    = 280
    local headerH   = 28
    local footerH   = 20
    local rowH      = 22
    local rowIconSz = 20
    local pad       = 8
    local rounding  = 6
    local fTitle    = 14
    local fText     = 13
    local fSmall    = 11

    -- ── Colors ───────────────────────────────────────────────────────────────
    local cBg       = Color(14, 16, 22, 220)
    local cHeader   = Color(22, 28, 42, 230)
    local cBorder   = Color(70, 90, 130, 100)
    local cTitle    = Color(100, 200, 255, 255)
    local cText     = Color(220, 220, 220, 255)
    local cDim      = Color(150, 155, 165, 220)
    local cGold     = Color(255, 200, 60, 255)
    local cRed      = Color(240, 80, 70, 255)
    local cGreen    = Color(80, 210, 100, 255)
    local cCyan     = Color(80, 200, 255, 255)
    local cOrange   = Color(255, 160, 50, 255)
    local cRowA     = Color(60, 80, 120, 20)
    local cRowB     = Color(60, 80, 120, 36)
    local cAccent   = Color(100, 200, 255, 180)

    -- ── Panel X/Y (top-right, fixed) ─────────────────────────────────────────
    local screenW, screenH = 1920, 1080
    if Render and Render.ScreenSize then
        local ok, sz = pcall(Render.ScreenSize)
        if ok and sz then screenW = sz.x or 1920; screenH = sz.y or 1080 end
    end
    local panelX = screenW - panelW - 12
    local panelY = 140

    -- ── Content rows ─────────────────────────────────────────────────────────
    local snap = S.lastSnapshot
    local rows  = {}   -- {text, subtext, color, subcolor, icon}

    if not snap then
        rows[#rows+1] = {text="Waiting for game data...", color=cDim}
    else
        -- Hero info row
        local heroDisplay = collector.getDisplayName(snap.heroName)
        local phStr  = collector.phaseLabel(snap.phase)
        local timeStr= math.floor(snap.gameTime / 60) .. "m"
        rows[#rows+1] = {
            text    = heroDisplay,
            subtext = phStr .. "  " .. timeStr .. (snap.isLosing and "  LOSING" or snap.isWinning and "  AHEAD" or ""),
            color   = snap.isLosing and cRed or cText,
            subcolor= snap.isLosing and cRed or cDim,
        }
        -- API source row
        local srcLabels = {live="Live",cache="Cached",disk_cache="Disk"}
        local src = srcLabels[S.metaSource] or "—"
        local stratzTxt = api.isStratzEnabled() and "+S" or ""
        local loadTxt   = api.isLoading() and " …" or ""
        rows[#rows+1] = {text="OpenDota: "..src..stratzTxt..loadTxt, color=cDim, small=true}

        -- 5-Axis threat bars
        if UI.showAxes and UI.showAxes:Get() and S.teamAxes then
            rows[#rows+1] = {text="THREAT AXES", color=cCyan, header=true}
            local axes = {
                {key="magic",    label="Magic",    c=Color(150,100,255,255)},
                {key="physical", label="Physical", c=Color(255,120,80,255)},
                {key="disables", label="Disables", c=Color(255,200,50,255)},
                {key="invis",    label="Invis",    c=Color(180,180,255,255)},
                {key="push",     label="Push",     c=Color(100,220,100,255)},
            }
            local axMax = 1
            for _,a in ipairs(axes) do
                local v = S.teamAxes[a.key] or 0
                if v > axMax then axMax = v end
            end
            for _,a in ipairs(axes) do
                local v = S.teamAxes[a.key] or 0
                local isDom = a.key == S.teamAxes.dominant
                rows[#rows+1] = {
                    text    = (isDom and "* " or "  ") .. a.label .. ": " .. tostring(v),
                    color   = isDom and a.c or cDim,
                    bar     = {fill = v / axMax, color = a.c},
                    small   = true,
                }
            end
        end

        -- Threat warnings
        if UI.showThreats and UI.showThreats:Get() and #S.warnings > 0 then
            for i = 1, math.min(#S.warnings, 4) do
                rows[#rows+1] = {text="!! " .. S.warnings[i], color=cRed, small=true}
            end
        end

        -- Recommended items
        rows[#rows+1] = {text="NEXT ITEMS", color=cGold, header=true}
        if #S.recommendations == 0 then
            rows[#rows+1] = {
                text = api.isLoading() and "Loading item stats..." or "No recommendations yet",
                color = cDim,
            }
        else
            for _, rec in ipairs(S.recommendations) do
                local costTxt = (rec.cost and rec.cost > 0) and ("  " .. tostring(rec.cost) .. "g") or ""
                local iconPath = "panorama/images/items/" .. rec.key:gsub("^item_","") .. "_png.vtex_c"
                local icon = nil
                pcall(function() icon = Render.LoadImage(iconPath) end)
                rows[#rows+1] = {
                    text    = rec.display,
                    subtext = rec.reason ~= "" and rec.reason or nil,
                    color   = cText,
                    subcolor= cGreen,
                    extra   = costTxt,
                    icon    = icon,
                }
            end
        end

        -- Enemy predictions
        if UI.showPredictions and UI.showPredictions:Get() and S.predictions and S.predictions.predictions then
            local hasPreds = false
            for _ in pairs(S.predictions.predictions) do hasPreds = true; break end
            if hasPreds then
                rows[#rows+1] = {text="ENEMY BUYS", color=cOrange, header=true}
                local cnt = 0
                for hName, preds in pairs(S.predictions.predictions) do
                    if cnt >= 3 then break end
                    local dn = collector.getDisplayName(hName)
                    local parts = {}
                    for _, p in ipairs(preds) do
                        local def = ITEM_LOOKUP[p.item]
                        parts[#parts+1] = (def and def.display or p.item:gsub("^item_",""):gsub("_"," "))
                    end
                    rows[#rows+1] = {text=dn..": "..table.concat(parts,", "), color=cDim, small=true}
                    cnt = cnt + 1
                end
            end
        end
    end

    -- ── Measure total height ─────────────────────────────────────────────────
    local function rowHeight(r)
        local h = rowH
        if r.small  then h = 17 end
        if r.header then h = 20 end
        if r.subtext then h = h + 14 end
        if r.bar then h = math.max(h, 16) end
        return h
    end
    local contentH = 0
    for _, r in ipairs(rows) do contentH = contentH + rowHeight(r) end
    local panelH = headerH + pad + contentH + pad + footerH

    -- ── Draw background ───────────────────────────────────────────────────────
    Render.FilledRect(Vec2(panelX, panelY), Vec2(panelX+panelW, panelY+panelH), cBg, rounding)
    Render.FilledRect(Vec2(panelX, panelY), Vec2(panelX+panelW, panelY+headerH), cHeader, rounding)
    pcall(Render.Rect, Vec2(panelX, panelY), Vec2(panelX+panelW, panelY+panelH), cBorder, rounding)

    -- ── Header ────────────────────────────────────────────────────────────────
    Render.Text(font, fTitle, "Smart Build", Vec2(panelX+pad, panelY+6), cTitle)
    local shopStr = IsShopOpen() and "  [shop]" or ""
    Render.Text(font, fSmall, "AI"..shopStr, Vec2(panelX+panelW-50, panelY+8), cAccent)

    -- divider line
    local divY = panelY + headerH
    pcall(Render.Line, Vec2(panelX+pad, divY), Vec2(panelX+panelW-pad, divY), cBorder, 1)

    -- ── Rows ──────────────────────────────────────────────────────────────────
    local cy = panelY + headerH + pad
    for idx, r in ipairs(rows) do
        local rh = rowHeight(r)
        local rowBg = (idx % 2 == 0) and cRowB or cRowA
        if not r.header then
            Render.FilledRect(Vec2(panelX+2, cy-1), Vec2(panelX+panelW-2, cy+rh-1), rowBg, 3)
        end

        local tx = panelX + pad
        -- icon
        if r.icon then
            pcall(Render.Image, r.icon, Vec2(tx, cy+1), Vec2(rowIconSz, rowIconSz), cText, 3)
            tx = tx + rowIconSz + 5
        end
        -- bar (threat axes)
        if r.bar then
            local barMaxW = panelW - pad*2 - 80
            local barW    = math.floor(barMaxW * r.bar.fill)
            local bx      = panelX + panelW - barMaxW - pad
            if barW > 0 then
                Render.FilledRect(Vec2(bx, cy+5), Vec2(bx+barW, cy+11), r.bar.color, 2)
            end
        end

        local sz = r.header and fText or (r.small and fSmall or fText)
        Render.Text(font, sz, r.text or "", Vec2(tx, cy), r.color or cText)
        -- extra (cost) right-aligned
        if r.extra then
            Render.Text(font, fSmall, r.extra, Vec2(panelX+panelW-pad-50, cy+1), cGold)
        end
        if r.subtext then
            Render.Text(font, fSmall, r.subtext, Vec2(tx, cy+sz+2), r.subcolor or cDim)
        end
        cy = cy + rh
    end

    -- ── Footer ────────────────────────────────────────────────────────────────
    local footerY = panelY + panelH - footerH
    pcall(Render.Line, Vec2(panelX+pad, footerY), Vec2(panelX+panelW-pad, footerY), cBorder, 1)
    local nextIn = math.max(0, UPDATE_INTERVAL - (collector.getRawGameTime() - S.lastUpdateAt))
    local footTxt = "next update: " .. math.floor(nextIn) .. "s  |  " .. (S.metaSource or "none")
    Render.Text(font, fSmall, footTxt, Vec2(panelX+pad, footerY+3), cDim)

    -- log state once
    if snap then
        logUIState("draw_recs_"..tostring(#S.recommendations), "drawing "..tostring(#S.recommendations).." recs, source="..tostring(S.metaSource))
    else
        logUIState("draw_waiting", "drawing: waiting for snapshot")
    end
end

function script.OnGameEnd()
    -- Record learning data before resetting state
    if learningEng and S.lastSnapshot then
        local snap = S.lastSnapshot
        -- Determine win/loss from final NW advantage (approximation)
        local won = snap.isWinning or false
        -- Try to get a more accurate signal from GameRules
        if type(GameRules) == "table" and GameRules.GetGameWinner then
            local okW, winner = pcall(GameRules.GetGameWinner)
            if okW and winner then
                -- Compare winner team with our team
                local myTeam = nil
                if type(Players) == "table" and Players.GetLocal then
                    local okP, lp = pcall(Players.GetLocal)
                    if okP and lp and lp.GetTeamID then
                        local okT, tid = pcall(lp.GetTeamID, lp)
                        if okT then myTeam = tid end
                    end
                end
                if myTeam then won = (winner == myTeam) end
            end
        end
        local items = {}
        for _, it in ipairs(snap.myItems or {}) do items[#items+1] = it end
        learningEng.recordOutcome(snap.heroName, items, won)
    end

    S.metaBuild       = nil
    S.stratzBuild     = nil
    S.mergedBuild     = nil
    S.metaSource      = "none"
    S.metaHeroID      = nil
    S.threatProfile   = nil
    S.teamAxes        = nil
    S.enemyItemInfo   = nil
    S.predictions     = nil
    S.metaScores      = nil
    S.recommendations = {}
    S.warnings        = {}
    S.lastUpdateAt    = 0
    S.lastSnapshot    = nil
    collector.invalidateCache()
    collector.resetTracking()
    if metaFetcher then metaFetcher.reset() end
    if predictor then predictor.reset() end
    FLog("[BuildEngine] Game ended — state reset")
end

return script
