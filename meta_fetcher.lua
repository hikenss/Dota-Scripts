--------------------------------------------------------------------------------
-- META FETCHER — Downloads item build statistics from OpenDota API
-- and converts them into normalized popularity scores (0.0 – 1.0).
--
-- Wraps api_client for the HTTP layer; this module owns the concept of
-- "meta score" — how popular / successful an item is in high-level play.
--
-- Output format per hero:
--   { item_blink = 0.62, item_blade_mail = 0.51, ... }
--
-- Integrates OpenDota + STRATZ data when available.
--------------------------------------------------------------------------------
local M = {}

local api = nil
pcall(function() api = require("api_client") end)

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local REFRESH_INTERVAL = 10800  -- 3 hours (unix seconds) before forced re-fetch
local PHASE_WEIGHT = {
    start = 0.6,
    early = 0.9,
    mid   = 1.0,
    late  = 1.0,
}

--------------------------------------------------------------------------------
-- STATE  (per-hero cached popularity maps)
--------------------------------------------------------------------------------
local state = {
    scores      = {},   -- [heroID] = { [itemKey] = popScore }
    fetchedAt   = {},   -- [heroID] = unix timestamp of last successful fetch
    pendingMerge= {},   -- [heroID] = true while waiting for second source
}

--------------------------------------------------------------------------------
-- INTERNAL: convert a normalized build (from api_client) into a flat
-- popularity map { item_key = score }.  Scores are 0.0–1.0 range.
--
-- `phase` is the collector phase constant (1=early, 2=mid, 3=late)
-- When provided, items matching the current phase get an extra weight.
--------------------------------------------------------------------------------
local function buildToScores(buildData, currentPhase)
    if not buildData then return {} end

    local raw = {}      -- item -> accumulated weighted popularity
    local maxRaw = 1    -- for normalization

    local phaseMap = {
        [1] = {"start", "early"},
        [2] = {"early", "mid"},
        [3] = {"mid", "late"},
    }
    local relevantPhases = phaseMap[currentPhase] or {"start", "early", "mid", "late"}

    -- First pass: collect all items from ALL phases with weights
    for _, phaseKey in ipairs({"start", "early", "mid", "late"}) do
        local bucket = buildData[phaseKey]
        if bucket then
            -- Is this phase relevant right now?
            local isRelevant = false
            for _, rp in ipairs(relevantPhases) do
                if rp == phaseKey then isRelevant = true; break end
            end
            local phaseW = PHASE_WEIGHT[phaseKey] or 0.5
            if isRelevant then phaseW = phaseW * 1.5 end

            for _, entry in ipairs(bucket) do
                local key = entry.key
                if key then
                    local pop = (entry.pop or 0) * phaseW
                    -- Win-rate bonus baked into STRATZ merged data already,
                    -- but apply a small extra nudge if available
                    if entry.winRate and entry.winRate > 0.52 then
                        pop = pop * (1 + (entry.winRate - 0.50) * 0.3)
                    end
                    raw[key] = (raw[key] or 0) + pop
                    if raw[key] > maxRaw then maxRaw = raw[key] end
                end
            end
        end
    end

    -- Normalize to 0.0–1.0
    local scores = {}
    for key, val in pairs(raw) do
        scores[key] = val / maxRaw
    end
    return scores
end

--------------------------------------------------------------------------------
-- PUBLIC: Fetch and compute meta scores for a hero.
-- Async — calls `callback(scores)` when done.
-- `currentPhase` (1/2/3) weights phase-relevant items higher.
--
-- Returns cached scores immediately if fresh enough.
--------------------------------------------------------------------------------
function M.fetch(heroID, currentPhase, callback)
    if not heroID or heroID == 0 then return end
    if not api then
        callback({})
        return
    end

    -- Check freshness
    local unixNow = 0
    if type(os) == "table" and os.time then
        local ok, t = pcall(os.time)
        if ok then unixNow = math.floor(t) end
    end
    local lastFetch = state.fetchedAt[heroID] or 0
    local cached    = state.scores[heroID]

    if cached and (unixNow - lastFetch) < REFRESH_INTERVAL then
        callback(cached)
        return
    end

    -- Attempt merged fetch (OpenDota + STRATZ)
    local opendotaData = nil
    local stratzData   = nil
    local delivered     = false

    local function tryDeliver()
        if delivered then return end
        -- Wait for both if STRATZ is enabled and in flight
        if api.isStratzEnabled() and state.pendingMerge[heroID] then return end

        local merged = api.mergeSources(opendotaData, stratzData)
        local scores = buildToScores(merged or opendotaData, currentPhase)
        state.scores[heroID]    = scores
        state.fetchedAt[heroID] = unixNow
        delivered = true
        callback(scores)
    end

    -- OpenDota
    api.fetchBuild(heroID, function(data, source)
        opendotaData = data
        tryDeliver()
    end)

    -- STRATZ (if available)
    if api.isStratzEnabled() and api.canStratzRequest() then
        state.pendingMerge[heroID] = true
        api.fetchStratzBuild(heroID, function(data, source)
            stratzData = data
            state.pendingMerge[heroID] = false
            tryDeliver()
        end)
    end

    -- Fallback: if no network, use disk cache
    if not delivered then
        local diskData = api.loadDiskCache(heroID)
        if diskData then
            -- loadDiskCache returns raw data — we need to get normalized version
            local normalized = api.getCachedBuild(heroID)
            if normalized then
                local scores = buildToScores(normalized, currentPhase)
                state.scores[heroID]    = scores
                state.fetchedAt[heroID] = unixNow
                callback(scores)
                delivered = true
            end
        end
    end
end

--------------------------------------------------------------------------------
-- PUBLIC: Get cached meta scores (no network).
-- Returns table or nil.
--------------------------------------------------------------------------------
function M.getCached(heroID)
    return state.scores[heroID]
end

--------------------------------------------------------------------------------
-- PUBLIC: Get single item's meta score.
-- Returns 0.0–1.0, or 0 if unknown.
--------------------------------------------------------------------------------
function M.getItemScore(heroID, itemKey)
    local s = state.scores[heroID]
    if not s then return 0 end
    return s[itemKey] or 0
end

--------------------------------------------------------------------------------
-- PUBLIC: Reset state (on game end).
--------------------------------------------------------------------------------
function M.reset()
    state.scores       = {}
    state.fetchedAt    = {}
    state.pendingMerge = {}
end

return M
