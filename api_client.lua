--------------------------------------------------------------------------------
-- API CLIENT — OpenDota API integration with caching and rate limiting
-- Handles HTTP requests, response parsing, disk caching, and backoff
--------------------------------------------------------------------------------
local M = {}

local JSON = nil
pcall(function() JSON = require("assets.JSON") end)

local OPENDOTA_URL = "https://api.opendota.com/api/heroes/%d/itemPopularity"
local CACHE_FILE   = "item_build_opendota_v2"
local CACHE_TTL    = 3600   -- 1 hour disk-cache validity (seconds, os.time based)
local MIN_INTERVAL = 60     -- Minimum seconds between API calls (game-time based)
local MAX_FAILURES = 6
local BASE_BACKOFF = 30

local state = {
    inFlight       = false,
    lastRequestAt  = -1000,   -- negative: allows first request immediately on game start
    failCount      = 0,
    nextRetryAt    = 0,       -- game-time before which no request may fire
    memCache       = {},      -- [heroID] = { data=table, gt=game_time }
    itemNameMap    = nil,     -- lazy-loaded itemID -> item_key map
}

--------------------------------------------------------------------------------
-- JSON helpers
--------------------------------------------------------------------------------
local function decodeJSON(text)
    if not JSON or type(text) ~= "string" or text == "" then return nil end
    local ok, r = pcall(function()
        if type(JSON.decode) == "function" then return JSON.decode(text) end
        if type(JSON) == "table" and JSON.decode then return JSON:decode(text) end
    end)
    return ok and r or nil
end

local function encodeJSON(tbl)
    if not JSON then return nil end
    local ok, r = pcall(function()
        if type(JSON.encode) == "function" then return JSON.encode(tbl) end
        if type(JSON) == "table" and JSON.encode then return JSON:encode(tbl) end
    end)
    return ok and r or nil
end
M.encodeJSON = encodeJSON

--------------------------------------------------------------------------------
-- Item-ID → item_key mapping (reads /assets/data/items.json once)
--------------------------------------------------------------------------------
local function ensureItemMap()
    if state.itemNameMap then return end
    state.itemNameMap = {}
    local ok, content = pcall(function()
        local f = io.open((Engine and Engine.GetGameDir and Engine.GetGameDir() or ".") ..
                          "/assets/data/items.json", "r")
        if not f then return nil end
        local c = f:read("*all"); f:close(); return c
    end)
    if not ok or not content then return end
    local data = decodeJSON(content)
    if type(data) ~= "table" then return end
    for key, def in pairs(data) do
        if type(def) == "table" and def.id then
            state.itemNameMap[tostring(def.id)] = "item_" .. key
        end
    end
end

function M.itemKeyFromID(id)
    ensureItemMap()
    return state.itemNameMap and state.itemNameMap[tostring(id)]
end

--------------------------------------------------------------------------------
-- Config persistence
--------------------------------------------------------------------------------
local function cfgRead(section, key, default)
    if type(Config) ~= "table" or type(Config.ReadString) ~= "function" then
        return default
    end
    local ok, v = pcall(Config.ReadString, CACHE_FILE, section, key, default or "")
    return ok and v or default
end

local function cfgWrite(section, key, value)
    if type(Config) ~= "table" or type(Config.WriteString) ~= "function" then return end
    pcall(Config.WriteString, CACHE_FILE, section, key, tostring(value))
end

--------------------------------------------------------------------------------
-- Rate limiting
--------------------------------------------------------------------------------
local function gameTime()
    local ok, v = pcall(GameRules.GetGameTime)
    return ok and v or 0
end

local function unixNow()
    if type(os) == "table" and type(os.time) == "function" then
        local ok, t = pcall(os.time)
        if ok then return math.floor(t) end
    end
    return 0
end

function M.canRequest()
    if state.inFlight then return false end
    local now = gameTime()
    -- Game time jumped backwards = new game started. Reset rate limiter.
    if now < state.lastRequestAt - 10 then
        state.lastRequestAt = -1000
        state.nextRetryAt   = 0
        state.failCount     = 0
    end
    if now < state.nextRetryAt then return false end
    if (now - state.lastRequestAt) < MIN_INTERVAL then return false end
    return true
end

function M.isLoading() return state.inFlight end

local function onFailure()
    state.failCount = math.min(state.failCount + 1, MAX_FAILURES)
    local delay = math.min(BASE_BACKOFF * (2 ^ (state.failCount - 1)), 600)
    state.nextRetryAt = gameTime() + delay
end

local function onSuccess()
    state.failCount = 0
    state.nextRetryAt = 0
end

--------------------------------------------------------------------------------
-- Disk cache
--------------------------------------------------------------------------------
local function saveDiskCache(heroID, raw)
    local sec = "hero_" .. tostring(heroID)
    cfgWrite(sec, "json", raw)
    cfgWrite(sec, "ts", tostring(unixNow()))
end

function M.loadDiskCache(heroID)
    local sec = "hero_" .. tostring(heroID)
    local raw = cfgRead(sec, "json", "")
    if raw == "" then return nil end
    local ts = tonumber(cfgRead(sec, "ts", "0")) or 0
    local now = unixNow()
    if now > 0 and (now - ts) > CACHE_TTL then return nil end
    return decodeJSON(raw)
end

--- Load disk cache ignoring TTL — stale data is better than nothing
function M.loadDiskCacheStale(heroID)
    local sec = "hero_" .. tostring(heroID)
    local raw = cfgRead(sec, "json", "")
    if raw == "" then return nil end
    return decodeJSON(raw)
end

--------------------------------------------------------------------------------
-- Normalize OpenDota response: convert item IDs to item_key names,
-- split into phase buckets.
-- Returns { start={}, early={}, mid={}, late={} }
-- Each bucket is a list of {key="item_xxx", pop=number} sorted desc.
--------------------------------------------------------------------------------
local PHASE_MAP = {
    start_game_items = "start",
    early_game_items = "early",
    mid_game_items   = "mid",
    late_game_items  = "late",
}

local function normalizeResponse(data)
    if type(data) ~= "table" then
        Log.Write("[API|Parse] OpenDota: response is not a table — parse failed")
        return nil
    end
    -- Ensure item map is populated; warn if empty (items.json not found)
    ensureItemMap()
    local mapSize = 0
    if state.itemNameMap then
        for _ in pairs(state.itemNameMap) do mapSize = mapSize + 1 end
    end
    if mapSize == 0 then
        Log.Write("[API|Parse] WARNING: item ID map is empty — items.json may be missing. All item IDs will be unresolved.")
    end
    local result = { start = {}, early = {}, mid = {}, late = {} }
    for rawKey, phaseLabel in pairs(PHASE_MAP) do
        local bucket = data[rawKey]
        if type(bucket) == "table" then
            local list = result[phaseLabel]
            local skipped = 0
            for idStr, pop in pairs(bucket) do
                local key = M.itemKeyFromID(idStr)
                if key then
                    list[#list + 1] = { key = key, pop = tonumber(pop) or 0 }
                else
                    skipped = skipped + 1
                end
            end
            if skipped > 0 then
                Log.Write(string.format("[API|Parse] %s: %d item IDs not resolved (map size=%d)",
                    phaseLabel, skipped, mapSize))
            end
            table.sort(list, function(a, b) return a.pop > b.pop end)
        end
    end
    Log.Write(string.format("[API|Parse] OpenDota normalized: start=%d early=%d mid=%d late=%d",
        #result.start, #result.early, #result.mid, #result.late))
    return result
end

--------------------------------------------------------------------------------
-- HTTP helpers — signatures verified against working Item Build.lua script.
-- Primary:  HTTP.Request(method, url, { timeout=N }, callback)
--   callback receives: string body  OR  table {response, body, error, errorMsg, status, code}
-- Fallback: HTTP.Request(method, url, { timeout=N, success=fn, error=fn })
--------------------------------------------------------------------------------
local function parseRawResponse(raw)
    local body, status, errMsg
    if type(raw) == "string" then
        body = raw; status = 200
    elseif type(raw) == "table" then
        body   = raw.response or raw.body
        status = tonumber(raw.status or raw.code)
        errMsg = raw.error or raw.errorMsg
    end
    return body, status, errMsg
end

local function httpGet(url, onBody, onFail)
    Log.Write("[API|HTTP] GET => " .. tostring(url))
    if type(HTTP) ~= "table" or type(HTTP.Request) ~= "function" then
        Log.Write("[API|HTTP] FATAL: HTTP.Request not available in this runtime")
        onFail(0); return
    end

    -- Primary signature: HTTP.Request(method, url, options, callback)
    local ok1, err1 = pcall(HTTP.Request, "GET", url, { timeout = 10000 }, function(raw)
        local body, status, errMsg = parseRawResponse(raw)
        Log.Write(string.format("[API|HTTP] GET cb: status=%s len=%d err=%s",
            tostring(status), type(body) == "string" and #body or 0, tostring(errMsg or "")))
        if errMsg and errMsg ~= "" then
            Log.Write("[API|HTTP] GET error field: " .. tostring(errMsg))
            onFail(status or 0); return
        end
        if status and (status < 200 or status >= 300) then
            Log.Write("[API|HTTP] GET bad HTTP status: " .. tostring(status))
            onFail(status); return
        end
        if type(body) == "string" and body ~= "" then
            onBody(body)
        else
            Log.Write("[API|HTTP] GET body is empty or nil")
            onFail(status or 0)
        end
    end)
    if ok1 then return end

    Log.Write("[API|HTTP] Primary GET failed (" .. tostring(err1) .. "), trying success/error signature")

    -- Fallback signature: HTTP.Request(method, url, { success=fn, error=fn })
    local ok2, err2 = pcall(HTTP.Request, "GET", url, {
        timeout = 10000,
        success = function(status, body, headers)
            Log.Write(string.format("[API|HTTP] GET fallback success: status=%s len=%d",
                tostring(status), type(body) == "string" and #body or 0))
            if type(body) == "string" and body ~= "" then
                onBody(body)
            else
                onFail(status or 0)
            end
        end,
        error = function(errMsg)
            Log.Write("[API|HTTP] GET fallback error: " .. tostring(errMsg))
            onFail(0)
        end,
    })
    if not ok2 then
        Log.Write("[API|HTTP] FATAL: both GET signatures failed: " .. tostring(err2))
        onFail(0)
    end
end

local function httpPost(url, body, authToken, onBody, onFail)
    Log.Write(string.format("[API|HTTP] POST => %s (token_len=%d body_len=%d)",
        tostring(url), #(authToken or ""), #(body or "")))
    if type(HTTP) ~= "table" or type(HTTP.Request) ~= "function" then
        Log.Write("[API|HTTP] FATAL: HTTP.Request not available for POST")
        onFail(0); return
    end

    -- Primary signature
    local ok1, err1 = pcall(HTTP.Request, "POST", url, {
        timeout = 12000,
        headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. (authToken or ""),
            ["User-Agent"]    = "SmartBuild/2.0",
        },
        body = body,
    }, function(raw)
        local respBody, status, errMsg = parseRawResponse(raw)
        Log.Write(string.format("[API|HTTP] POST cb: status=%s len=%d err=%s",
            tostring(status), type(respBody) == "string" and #respBody or 0, tostring(errMsg or "")))
        if errMsg and errMsg ~= "" then
            Log.Write("[API|HTTP] POST error field: " .. tostring(errMsg))
            onFail(status or 0); return
        end
        if status and (status < 200 or status >= 300) then
            Log.Write("[API|HTTP] POST bad HTTP status: " .. tostring(status))
            onFail(status); return
        end
        if type(respBody) == "string" and respBody ~= "" then
            onBody(respBody)
        else
            Log.Write("[API|HTTP] POST body is empty or nil")
            onFail(status or 0)
        end
    end)
    if ok1 then return end

    Log.Write("[API|HTTP] Primary POST failed (" .. tostring(err1) .. "), trying success/error signature")

    -- Fallback signature
    local ok2, err2 = pcall(HTTP.Request, "POST", url, {
        timeout = 12000,
        headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. (authToken or ""),
        },
        body = body,
        success = function(status, respBody, headers)
            Log.Write(string.format("[API|HTTP] POST fallback success: status=%s len=%d",
                tostring(status), type(respBody) == "string" and #respBody or 0))
            if type(respBody) == "string" and respBody ~= "" then
                onBody(respBody)
            else
                onFail(status or 0)
            end
        end,
        error = function(errMsg)
            Log.Write("[API|HTTP] POST fallback error: " .. tostring(errMsg))
            onFail(0)
        end,
    })
    if not ok2 then
        Log.Write("[API|HTTP] FATAL: both POST signatures failed: " .. tostring(err2))
        onFail(0)
    end
end

--------------------------------------------------------------------------------
-- PUBLIC: Fetch item popularity from OpenDota (async)
-- callback(buildData, source)  source: "live"|"cache"|"disk_cache"
-- Returns true if a response (possibly cached) was delivered or in-flight.
--------------------------------------------------------------------------------
function M.fetchBuild(heroID, callback)
    if not heroID or heroID == 0 then
        Log.Write("[API|OpenDota] fetchBuild called with invalid heroID")
        return false
    end

    -- Memory cache hit
    local mem = state.memCache[heroID]
    if mem then
        Log.Write("[API|OpenDota] hero=" .. heroID .. " served from memory cache")
        callback(mem.data, "cache")
        return true
    end

    -- Can we fire a request?
    if not M.canRequest() then
        local now = gameTime()
        local reason
        if state.inFlight then
            reason = "in-flight"
        elseif now < state.nextRetryAt then
            reason = string.format("backoff %.0fs remaining, fail_count=%d",
                state.nextRetryAt - now, state.failCount)
        else
            reason = string.format("rate-limit (%.0fs / %ds interval)",
                now - state.lastRequestAt, MIN_INTERVAL)
        end
        Log.Write("[API|OpenDota] hero=" .. heroID .. " request blocked: " .. reason)
        -- Try fresh cache, then fall back to stale (better than nothing)
        local disk = M.loadDiskCache(heroID) or M.loadDiskCacheStale(heroID)
        if disk then
            Log.Write("[API|OpenDota] hero=" .. heroID .. " serving from disk cache")
            local norm = normalizeResponse(disk)
            if norm then
                state.memCache[heroID] = { data = norm, gt = gameTime() }
                callback(norm, "disk_cache")
                return true
            end
        end
        Log.Write("[API|OpenDota] hero=" .. heroID .. " no cache available — no data returned")
        return false
    end

    state.inFlight = true
    state.lastRequestAt = gameTime()

    local url = string.format(OPENDOTA_URL, heroID)
    Log.Write("[API|OpenDota] hero=" .. heroID .. " firing HTTP request at gt=" .. tostring(state.lastRequestAt))
    httpGet(url,
        function(body)
            state.inFlight = false
            Log.Write(string.format("[API|OpenDota] hero=%d response received, body_len=%d",
                heroID, #body))
            local data = decodeJSON(body)
            if type(data) == "table" then
                onSuccess()
                saveDiskCache(heroID, body)
                local norm = normalizeResponse(data)
                if norm then
                    local total = #norm.start + #norm.early + #norm.mid + #norm.late
                    Log.Write(string.format("[API|OpenDota] hero=%d SUCCESS: %d items across phases",
                        heroID, total))
                    state.memCache[heroID] = { data = norm, gt = gameTime() }
                    callback(norm, "live")
                    return
                end
                Log.Write("[API|OpenDota] hero=" .. heroID .. " normalize returned nil after successful decode")
            else
                Log.Write("[API|OpenDota] hero=" .. heroID .. " JSON decode failed (type=" .. type(data) .. ")")
            end
            onFailure()
            Log.Write("[API|OpenDota] hero=" .. heroID .. " falling back to disk cache after parse failure")
            local disk = M.loadDiskCache(heroID) or M.loadDiskCacheStale(heroID)
            if disk then
                local n = normalizeResponse(disk)
                if n then callback(n, "disk_cache") end
            end
        end,
        function(status)
            state.inFlight = false
            Log.Write("[API|OpenDota] hero=" .. heroID .. " HTTP failed, status=" .. tostring(status))
            onFailure()
            local disk = M.loadDiskCache(heroID) or M.loadDiskCacheStale(heroID)
            if disk then
                Log.Write("[API|OpenDota] hero=" .. heroID .. " falling back to disk cache after HTTP failure")
                local n = normalizeResponse(disk)
                if n then callback(n, "disk_cache") end
            else
                Log.Write("[API|OpenDota] hero=" .. heroID .. " no disk cache — no data returned")
            end
        end
    )
    return true
end

--- Return already-fetched build (no network). nil if not cached.
function M.getCachedBuild(heroID)
    local mem = state.memCache[heroID]
    if mem then return mem.data end
    local disk = M.loadDiskCache(heroID)
    if disk then
        local norm = normalizeResponse(disk)
        if norm then state.memCache[heroID] = { data = norm, gt = gameTime() } end
        return norm
    end
    return nil
end

--------------------------------------------------------------------------------
-- STRATZ API  (secondary data source — GraphQL, bracket-filtered)
-- Requires a free API token from https://stratz.com/api
--------------------------------------------------------------------------------
local STRATZ_URL = "https://api.stratz.com/graphql"
local STRATZ_MIN_INTERVAL = 120
local STRATZ_CACHE_FILE   = "item_build_stratz_v1"

local stratz = {
    token      = "",
    enabled    = false,
    inFlight   = false,
    lastReqAt  = -1000,   -- negative: allows first STRATZ request immediately
    failCount  = 0,
    cache      = {},   -- [heroID] = normalized data
}

function M.configureStratz(token, enabled)
    stratz.token   = token or ""
    stratz.enabled = enabled and stratz.token ~= ""
end

function M.isStratzEnabled() return stratz.enabled end
function M.isStratzLoading() return stratz.inFlight end
function M.getStratzToken()  return stratz.token end

function M.canStratzRequest()
    if not stratz.enabled then return false end
    if stratz.inFlight then return false end
    if stratz.token == "" then return false end
    local now = gameTime()
    -- Game time jumped backwards = new game started. Reset rate limiter.
    if now < stratz.lastReqAt - 10 then
        stratz.lastReqAt  = -1000
        stratz.failCount  = 0
    end
    if (now - stratz.lastReqAt) < STRATZ_MIN_INTERVAL then return false end
    return true
end

-- GraphQL query: hero item popularity filtered to Divine/Immortal bracket.
-- Uses heroStats.guide which returns top builds from high-MMR matches.
-- Adjust this query if the STRATZ schema changes.
local STRATZ_QUERY_FMT = [[{"query":"{ heroStats { guide(heroId: %d, take: 20) { heroId matchCount winCount } stats(heroIds: [%d], bracketBasicIds: [DIVINE_IMMORTAL]) { matchCount winCount } } }"}]]

--- Walk response tree looking for arrays of objects with itemId fields.
local function findItemArrays(obj, results)
    results = results or {}
    if type(obj) ~= "table" then return results end
    if obj[1] and type(obj[1]) == "table" and obj[1].itemId then
        results[#results + 1] = obj
        return results
    end
    for _, v in pairs(obj) do
        if type(v) == "table" then findItemArrays(v, results) end
    end
    return results
end

--- Normalize STRATZ response into the same {start,early,mid,late} format.
--- Falls back to placing all items in a "mid" bucket if schema is unexpected.
local function normalizeStratzResponse(data)
    if type(data) ~= "table" then return nil end

    local result = { start = {}, early = {}, mid = {}, late = {} }

    -- Try structured phase keys first
    local phaseKeys = {
        startingItems     = "start",  itemStartingPurchase = "start",
        earlyGameItems    = "early",  earlyItems           = "early",
        midGameItems      = "mid",    midItems             = "mid",
        lateGameItems     = "late",   lateItems            = "late",
        itemFullPurchase  = "mid",    itemBootPurchase     = "early",
    }

    local foundPhased = false
    local walk
    walk = function(node)
        if type(node) ~= "table" then return end
        for k, v in pairs(node) do
            if type(k) == "string" and phaseKeys[k] and type(v) == "table" then
                local phase = phaseKeys[k]
                local list = result[phase]
                if v[1] and type(v[1]) == "table" then
                    for _, entry in ipairs(v) do
                        local id = entry.itemId or entry.item_id
                        if id then
                            local key = M.itemKeyFromID(id)
                            if key then
                                local pop = entry.matchCount or entry.match_count or entry.count or 1
                                local wins = entry.winCount or entry.win_count or 0
                                local winRate = pop > 0 and (wins / pop) or 0.5
                                list[#list + 1] = { key = key, pop = pop, winRate = winRate }
                                foundPhased = true
                            end
                        end
                    end
                end
            end
            if type(v) == "table" then walk(v) end
        end
    end
    walk(data)

    -- Fallback: scan for any itemId arrays and dump into mid
    if not foundPhased then
        local arrays = findItemArrays(data)
        for _, arr in ipairs(arrays) do
            for _, entry in ipairs(arr) do
                local id = entry.itemId or entry.item_id
                if id then
                    local key = M.itemKeyFromID(id)
                    if key then
                        local pop = entry.matchCount or entry.count or 1
                        result.mid[#result.mid + 1] = { key = key, pop = pop, winRate = 0.5 }
                    end
                end
            end
        end
    end

    -- Sort each bucket
    for _, phase in ipairs({"start", "early", "mid", "late"}) do
        table.sort(result[phase], function(a, b) return a.pop > b.pop end)
    end

    local total = #result.start + #result.early + #result.mid + #result.late
    Log.Write(string.format("[API|Parse] STRATZ normalized: start=%d early=%d mid=%d late=%d total=%d foundPhased=%s",
        #result.start, #result.early, #result.mid, #result.late, total, tostring(foundPhased)))
    return total > 0 and result or nil
end

--- Fetch from STRATZ (async). Calls callback(data, "stratz") on success.
function M.fetchStratzBuild(heroID, callback)
    if not heroID or heroID == 0 then
        Log.Write("[API|STRATZ] fetchStratzBuild called with invalid heroID")
        return false
    end
    if not M.canStratzRequest() then
        local reason
        if not stratz.enabled then
            reason = "not enabled (no token)"
        elseif stratz.inFlight then
            reason = "in-flight"
        elseif stratz.token == "" then
            reason = "token is empty"
        else
            local now = gameTime()
            reason = string.format("rate-limit (%.0fs / %ds interval)",
                now - stratz.lastReqAt, STRATZ_MIN_INTERVAL)
        end
        Log.Write("[API|STRATZ] hero=" .. heroID .. " blocked: " .. reason)
        local cached = stratz.cache[heroID]
        if cached then
            Log.Write("[API|STRATZ] hero=" .. heroID .. " served from memory cache")
            callback(cached, "stratz_cache")
            return true
        end
        return false
    end

    stratz.inFlight = true
    stratz.lastReqAt = gameTime()
    Log.Write(string.format("[API|STRATZ] hero=%d firing POST, token_len=%d gt=%.0f",
        heroID, #stratz.token, stratz.lastReqAt))

    local body = string.format(STRATZ_QUERY_FMT, heroID, heroID)
    httpPost(STRATZ_URL, body, stratz.token,
        function(respBody)
            stratz.inFlight = false
            Log.Write(string.format("[API|STRATZ] hero=%d response received, body_len=%d",
                heroID, #respBody))
            local parsed = decodeJSON(respBody)
            if parsed then
                local d = parsed.data or parsed
                local norm = normalizeStratzResponse(d)
                if norm then
                    local total = #norm.start + #norm.early + #norm.mid + #norm.late
                    Log.Write(string.format("[API|STRATZ] hero=%d SUCCESS: %d items across phases",
                        heroID, total))
                    stratz.failCount = 0
                    stratz.cache[heroID] = norm
                    local sec = "stratz_" .. tostring(heroID)
                    cfgWrite(sec, "json", respBody)
                    cfgWrite(sec, "ts", tostring(unixNow()))
                    callback(norm, "stratz")
                    return
                end
                Log.Write("[API|STRATZ] hero=" .. heroID .. " normalizeStratzResponse returned nil")
            else
                Log.Write("[API|STRATZ] hero=" .. heroID .. " JSON decode failed")
            end
            stratz.failCount = stratz.failCount + 1
            Log.Write("[API|STRATZ] hero=" .. heroID .. " failed (fail_count=" .. stratz.failCount .. ")")
        end,
        function(status)
            stratz.inFlight = false
            stratz.failCount = stratz.failCount + 1
            Log.Write("[API|STRATZ] hero=" .. heroID .. " HTTP failed status=" .. tostring(status)
                .. " (fail_count=" .. stratz.failCount .. ")")
        end
    )
    return true
end

--------------------------------------------------------------------------------
-- SOURCE MERGING: combine OpenDota + STRATZ data with high-MMR weighting.
-- STRATZ data gets 1.5x weight since it's bracket-filtered.
-- Win-rate boosts items that actually win more.
--------------------------------------------------------------------------------
function M.mergeSources(opendota, stratzData)
    if not opendota and not stratzData then return nil end
    if not stratzData then return opendota end
    if not opendota then return stratzData end

    local result = { start = {}, early = {}, mid = {}, late = {} }
    for _, phase in ipairs({"start", "early", "mid", "late"}) do
        local merged = {}

        -- OpenDota items weight 1.0
        for _, item in ipairs(opendota[phase] or {}) do
            merged[item.key] = {
                key     = item.key,
                pop     = item.pop,
                winRate = item.winRate or 0,
            }
        end

        -- STRATZ items weight 1.5 (high-MMR data is more valuable)
        for _, item in ipairs(stratzData[phase] or {}) do
            local existing = merged[item.key]
            if existing then
                existing.pop = existing.pop + item.pop * 1.5
                if (item.winRate or 0) > existing.winRate then
                    existing.winRate = item.winRate
                end
            else
                merged[item.key] = {
                    key     = item.key,
                    pop     = item.pop * 1.5,
                    winRate = item.winRate or 0,
                }
            end
        end

        -- Win-rate boost: items above 52% win rate get up to 20% popularity bonus
        local list = {}
        for _, v in pairs(merged) do
            if v.winRate > 0.52 then
                v.pop = v.pop * (1 + (v.winRate - 0.50) * 0.5)
            end
            list[#list + 1] = v
        end
        table.sort(list, function(a, b) return a.pop > b.pop end)
        result[phase] = list
    end
    return result
end

--------------------------------------------------------------------------------
-- Auto-initialize STRATZ from persisted config or pre-baked default token.
-- Called at module load so token is always available without user interaction.
-- Also callable from build_engine.lua after a reload via M.initFromConfig().
--------------------------------------------------------------------------------
local function initFromConfig()
    Log.Write("[API|Init] initFromConfig called")

    -- 1. Try api_client's own storage location
    local saved = cfgRead("stratz_config", "token", "")
    if saved and saved ~= "" then
        Log.Write(string.format("[API|Init] STRATZ token loaded from api_client config (len=%d)", #saved))
        stratz.token   = saved
        stratz.enabled = true
        return
    end

    -- 2. Try build_engine's UI storage (item_build_settings/stratz/token)
    if type(Config) == "table" and Config.ReadString then
        local ok, v = pcall(Config.ReadString, "item_build_settings", "stratz", "token", "")
        if ok and type(v) == "string" and v ~= "" then
            Log.Write(string.format("[API|Init] STRATZ token migrated from build_engine UI config (len=%d)", #v))
            saved = v
            cfgWrite("stratz_config", "token", saved)  -- migrate
            stratz.token   = saved
            stratz.enabled = true
            return
        end
    end

    -- 3. Pre-baked default — works without any user setup
    Log.Write("[API|Init] No saved token found — applying pre-baked default STRATZ token")
    local DEFAULT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJTdWJqZWN0IjoiYjkxNmU1ZjItNzIzYi00ODQyLTgwMGItMmEwMzQ3NWUxY2UwIiwiU3RlYW1JZCI6IjExMjYxNzI4MyIsIkFQSVVzZXIiOiJ0cnVlIiwibmJmIjoxNzcyOTc0NjYxLCJleHAiOjE4MDQ1MTA2NjEsImlhdCI6MTc3Mjk3NDY2MSwiaXNzIjoiaHR0cHM6Ly9hcGkuc3RyYXR6LmNvbSJ9.T7q82XtR5fB7d4zfJi6ohahX8AoujbNMybTY3G3Ltzc"
    stratz.token   = DEFAULT_TOKEN
    stratz.enabled = true
    cfgWrite("stratz_config", "token", DEFAULT_TOKEN)
    if type(Config) == "table" and Config.WriteString then
        pcall(Config.WriteString, "item_build_settings", "stratz", "token", DEFAULT_TOKEN)
    end
    Log.Write("[API|Init] Pre-baked STRATZ token applied and persisted")
end

M.initFromConfig = initFromConfig
initFromConfig()  -- run immediately at require() time

return M
