-- SMART BUILD v8
-- Menu registrado em "Scripts > User Scripts" (padrao Umbrella)
-- Hero detection exaustiva via match_collector

local script = {}
local UI = {}
local S = { lastSnapshot = nil, recommendations = {}, lastUpdateAt = 0, errorMsg = nil }

--------------------------------------------------------------------------------
-- FILE LOGGER
--------------------------------------------------------------------------------
local LOG_FILE = "smart_build_debug.txt"
local _logH = nil
local function FLog(msg)
    local line = os.date("%H:%M:%S") .. " " .. tostring(msg)
    if not _logH then
        _logH = io.open(LOG_FILE, "a")
        if not _logH then _logH = io.open("c:\\UB\\scripts\\smart_build_debug.txt", "a") end
    end
    if _logH then _logH:write(line .. "\n"); _logH:flush() end
    if type(Log) == "table" and type(Log.Write) == "function" then
        pcall(Log.Write, line)
    end
end
FLog("[BuildEngine] v8 loading...")

--------------------------------------------------------------------------------
-- MODULE LOADING
--------------------------------------------------------------------------------
local function loadMod(name)
    local ok, mod = pcall(require, name)
    if ok and type(mod) == "table" then FLog("[loadMod] require OK: " .. name); return mod end
    ok, mod = pcall(dofile, name .. ".lua")
    if ok and type(mod) == "table" then FLog("[loadMod] dofile OK: " .. name); return mod end
    ok, mod = pcall(dofile, "c:\\UB\\scripts\\" .. name .. ".lua")
    if ok and type(mod) == "table" then FLog("[loadMod] dofile(abs) OK: " .. name); return mod end
    FLog("[loadMod] FAILED: " .. name)
    return nil
end

local api       = loadMod("api_client")
local collector = loadMod("match_collector")
FLog("[BuildEngine] api=" .. tostring(api ~= nil) .. " collector=" .. tostring(collector ~= nil))

if api and type(api.initFromConfig) == "function" then
    pcall(api.initFromConfig)
end

--------------------------------------------------------------------------------
-- SAFE UI HELPER
--------------------------------------------------------------------------------
local function safeGet(uiObj, default)
    if not uiObj then return default end
    if type(uiObj.Get) == "function" then
        local ok, val = pcall(uiObj.Get, uiObj)
        if ok then return val end
    end
    if type(uiObj.GetValue) == "function" then
        local ok, val = pcall(uiObj.GetValue, uiObj)
        if ok then return val end
    end
    return default
end

--------------------------------------------------------------------------------
-- MENU
-- Path 1: "Scripts > User Scripts > Smart Build" (standard)
-- Path 2: "General > Main > Smart Build"
-- Path 3: flat "Smart Build" (legacy)
--------------------------------------------------------------------------------
local function initMenu()
    local tab

    local ok1, t1 = pcall(Menu.Create, "Scripts", "User Scripts", "Smart Build")
    if ok1 and t1 then
        tab = t1
        FLog("[Menu] Created at Scripts > User Scripts > Smart Build")
    end

    if not tab then
        local ok2, t2 = pcall(Menu.Create, "General", "Main", "Smart Build")
        if ok2 and t2 then
            tab = t2
            FLog("[Menu] Created at General > Main > Smart Build")
        end
    end

    if not tab then
        local ok3, t3 = pcall(Menu.Create, "Smart Build")
        if ok3 and t3 then
            tab = t3
            FLog("[Menu] Created at flat Smart Build")
        end
    end

    if not tab then
        FLog("[Menu] ERROR: all Menu.Create paths failed")
        return
    end

    if type(tab.Icon) == "function" then
        pcall(tab.Icon, tab, "\u{f1e0}")
    end

    -- Settings section
    local section = tab
    if type(tab.Create) == "function" then
        local okS, s = pcall(tab.Create, tab, "Settings")
        if okS and s and type(s.Create) == "function" then
            local okS2, s2 = pcall(s.Create, s, "Main")
            section = (okS2 and s2) or s
        elseif okS and s then
            section = s
        end
    end

    -- Switches & combos
    local okE, en = pcall(section.Switch, section, "Enable Smart Build", true, "\u{f00c}")
    if okE and en then UI.enabled = en end

    local okV, vm = pcall(section.Combo, section, "Show Panel", {"Always", "Only Shop"}, 0)
    if okV and vm then UI.visibilityMode = vm end

    local okM, mi = pcall(section.Slider, section, "Max Suggestions", 1, 6, 3)
    if okM and mi then UI.maxItems = mi end

    local okT, tw = pcall(section.Switch, section, "Show Threat Warnings", true, "\u{f071}")
    if okT and tw then UI.showThreats = tw end

    local okA, ax = pcall(section.Switch, section, "Show Threat Axes", true, "\u{f080}")
    if okA and ax then UI.showAxes = ax end

    local okP, pr = pcall(section.Switch, section, "Show Enemy Predictions", false, "\u{f1e0}")
    if okP and pr then UI.showPredictions = pr end

    local okD, dl = pcall(section.Switch, section, "Debug Logs", false, "\u{f188}")
    if okD and dl then UI.debugLogs = dl end

    -- ToolTips (safe)
    if UI.enabled and type(UI.enabled.ToolTip) == "function" then
        pcall(UI.enabled.ToolTip, UI.enabled, "Master toggle for Smart Build")
    end
    if UI.visibilityMode and type(UI.visibilityMode.ToolTip) == "function" then
        pcall(UI.visibilityMode.ToolTip, UI.visibilityMode, "Always | Only Shop")
    end

    -- STRATZ auto-configure
    if api and type(api.configureStratz) == "function" then
        local token = (api.getStratzToken and api.getStratzToken()) or ""
        pcall(api.configureStratz, token, true)
    end

    FLog("[Menu] Init complete. enabled=" .. tostring(UI.enabled ~= nil))
end
pcall(initMenu)

--------------------------------------------------------------------------------
-- DEBUG HELPER
--------------------------------------------------------------------------------
local function dbg(msg)
    if safeGet(UI.debugLogs, false) then
        pcall(Log.Write, "[BuildEngine] " .. tostring(msg))
    end
end

--------------------------------------------------------------------------------
-- SHOP DETECTION
--------------------------------------------------------------------------------
local _shopPanel, _shopPanelAt, _shopCache, _shopCacheAt = nil, -999, false, -999

local function findShopPanel()
    if _shopPanel then return _shopPanel end
    local now = (GameRules and GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    if now - _shopPanelAt < 1.0 then return nil end
    _shopPanelAt = now
    if type(Panorama) ~= "table" or type(Panorama.GetPanelByName) ~= "function" then return nil end
    local ok, p = pcall(Panorama.GetPanelByName, "shop", false)
    if ok and p then _shopPanel = p; return p end
    ok, p = pcall(Panorama.GetPanelByName, "ShopPanel", false)
    if ok and p then _shopPanel = p; return p end
    return nil
end

local function IsShopOpen()
    local now = (GameRules and GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    if now - _shopCacheAt < 0.2 then return _shopCache end
    _shopCacheAt = now
    local panel = findShopPanel()
    if panel and type(panel.HasClass) == "function" then
        local ok, has = pcall(panel.HasClass, panel, "ShopOpen")
        if ok then _shopCache = (has == true); return _shopCache end
    end
    _shopCache = false
    return false
end

--------------------------------------------------------------------------------
-- CALLBACKS
--------------------------------------------------------------------------------
function script.OnUpdate()
    if not safeGet(UI.enabled, true) then return end

    local now = (GameRules and GameRules.GetGameTime and GameRules.GetGameTime()) or 0
    if (now - S.lastUpdateAt) >= 10.0 then
        S.lastUpdateAt = now
        if collector then
            local ok, snap = pcall(collector.collectSnapshot)
            if ok and snap then
                S.lastSnapshot = snap
                S.errorMsg = nil
                dbg("Snapshot OK: hero=" .. tostring(snap.heroName) .. " enemies=" .. tostring(#snap.enemies))
            elseif not ok then
                S.errorMsg = "collectSnapshot error: " .. tostring(snap)
                FLog("[BuildEngine] " .. S.errorMsg)
            else
                S.errorMsg = "Snapshot nil - hero not detected yet"
                FLog("[BuildEngine] " .. S.errorMsg)
            end
        else
            S.errorMsg = "match_collector not loaded"
        end
    end
end

local function ShouldDrawPanel()
    if not safeGet(UI.enabled, true) then return false end
    local mode = safeGet(UI.visibilityMode, 0)
    if mode >= 1 then return IsShopOpen() end
    return true
end

--------------------------------------------------------------------------------
-- DRAW
--------------------------------------------------------------------------------
function script.OnDraw()
    if not ShouldDrawPanel() then return end
    if not Render then return end

    local x, y = 50, 250
    local w = 280
    local lineH = 18

    -- Module error panel
    if not api or not collector then
        pcall(Render.FilledRect, Vec2(x, y), Vec2(x+w, y+60), Color(14, 16, 22, 220), 6)
        pcall(Render.Text, 1, 14, "Smart Build - module error", Vec2(x+8, y+8), Color(240, 80, 70, 255))
        local missing = {}
        if not api       then missing[#missing+1] = "api_client" end
        if not collector then missing[#missing+1] = "match_collector" end
        pcall(Render.Text, 1, 11, "Missing: " .. table.concat(missing, ", "), Vec2(x+8, y+28), Color(150, 155, 165, 220))
        pcall(Render.Text, 1, 11, "See smart_build_debug.txt", Vec2(x+8, y+44), Color(150, 155, 165, 220))
        return
    end

    -- Build rows
    local rows = {}
    local snap = S.lastSnapshot

    if not snap then
        rows[#rows+1] = { text = S.errorMsg or "Aguardando Snapshot...", color = Color(255, 100, 100, 255) }
    else
        local heroDisplay = collector.getDisplayName(snap.heroName)
        local phStr  = collector.phaseLabel(snap.phase)
        local timeStr = math.floor(snap.gameTime / 60) .. "m"
        rows[#rows+1] = { text = heroDisplay .. "  " .. phStr .. "  " .. timeStr, color = Color(100, 200, 255, 255) }

        local src = "-"
        if api.isLoading and api.isLoading() then src = "Loading..."
        elseif api.isStratzEnabled and api.isStratzEnabled() then src = "STRATZ"
        end
        rows[#rows+1] = { text = "Source: " .. src, color = Color(150, 155, 165, 220), small = true }

        rows[#rows+1] = { text = "Enemies: " .. tostring(#snap.enemies), color = Color(220, 220, 220, 255), small = true }

        local nwColor = snap.isLosing and Color(240, 80, 70, 255) or
                         snap.isWinning and Color(80, 210, 100, 255) or Color(220, 220, 220, 255)
        rows[#rows+1] = { text = "NW diff: " .. tostring(snap.nwAdvantage), color = nwColor, small = true }

        rows[#rows+1] = { text = "Gold: " .. tostring(snap.myGold), color = Color(255, 200, 60, 255), small = true }

        if snap.myItems and #snap.myItems > 0 then
            local itemList = {}
            for i, it in ipairs(snap.myItems) do
                if i > 4 then break end
                itemList[#itemList+1] = it:gsub("^item_", ""):gsub("_", " ")
            end
            rows[#rows+1] = { text = "Items: " .. table.concat(itemList, ", "), color = Color(150, 155, 165, 220), small = true }
        end
    end

    local shopStr = IsShopOpen() and "  [SHOP]" or ""

    local headerH = 26
    local pad = 8
    local contentH = 0
    for _, r in ipairs(rows) do contentH = contentH + (r.small and 15 or lineH) end
    local panelH = headerH + pad + contentH + pad

    pcall(Render.FilledRect, Vec2(x, y), Vec2(x+w, y+panelH), Color(14, 16, 22, 220), 6)
    pcall(Render.FilledRect, Vec2(x, y), Vec2(x+w, y+headerH), Color(22, 28, 42, 230), 6)

    pcall(Render.Text, 1, 14, "Smart Build v8" .. shopStr, Vec2(x+pad, y+6), Color(100, 200, 255, 255))

    local cy = y + headerH + pad
    for _, r in ipairs(rows) do
        local sz = r.small and 11 or 13
        pcall(Render.Text, 1, sz, r.text, Vec2(x+pad, cy), r.color)
        cy = cy + (r.small and 15 or lineH)
    end
end

FLog("[BuildEngine] v8 loaded OK")
return script
