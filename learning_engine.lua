--------------------------------------------------------------------------------
-- LEARNING ENGINE — Persists win/loss data across matches.
-- Tracks per-hero + per-item performance and derives a learning_score.
--
-- Formula: learning_score = (winrate - 0.5) * LEARNING_WEIGHT
--
-- Data is stored via Config.ReadString / Config.WriteString to persist
-- across game sessions.
--
-- On each game end:
--   • Record which items were owned at end
--   • Record win/loss outcome
--   • Update per-hero per-item statistics
--
-- During scoring:
--   • Look up hero+item combo
--   • Compute learning_score contribution
--------------------------------------------------------------------------------
local M = {}

local JSON = nil
pcall(function() JSON = require("assets.JSON") end)

--------------------------------------------------------------------------------
-- CONFIG
--------------------------------------------------------------------------------
local LEARNING_WEIGHT = 8   -- how strongly learning influences final score
local MIN_GAMES       = 3   -- minimum games before learning_score kicks in
local CONFIG_SECTION  = "item_build_learning"

--------------------------------------------------------------------------------
-- STATE
-- heroStats[heroName][itemKey] = { wins = N, losses = N }
--------------------------------------------------------------------------------
local heroStats = {}

--------------------------------------------------------------------------------
-- PERSISTENCE — Load / Save via Config
--------------------------------------------------------------------------------
local function loadStats()
    if not (type(Config) == "table" and Config.ReadString) then return end
    local ok, raw = pcall(Config.ReadString, CONFIG_SECTION, "data", "stats", "")
    if not ok or not raw or raw == "" then return end
    if not JSON then return end
    local ok2, data = pcall(JSON.decode, JSON, raw)
    if ok2 and type(data) == "table" then
        heroStats = data
    end
end

local function saveStats()
    if not (type(Config) == "table" and Config.WriteString) then return end
    if not JSON then return end
    local ok, encoded = pcall(JSON.encode, JSON, heroStats)
    if ok and encoded then
        pcall(Config.WriteString, CONFIG_SECTION, "data", "stats", encoded)
    end
end

--------------------------------------------------------------------------------
-- RECORD MATCH OUTCOME
-- Called from build_engine.OnGameEnd with the final snapshot + win/loss.
--
-- heroName: unit name (e.g. "npc_dota_hero_axe")
-- items:    list of item keys owned at game end
-- won:      true/false
--------------------------------------------------------------------------------
function M.recordOutcome(heroName, items, won)
    if not heroName or not items then return end

    if not heroStats[heroName] then
        heroStats[heroName] = {}
    end
    local hs = heroStats[heroName]

    for _, itemKey in ipairs(items) do
        if not hs[itemKey] then
            hs[itemKey] = { wins = 0, losses = 0 }
        end
        if won then
            hs[itemKey].wins = hs[itemKey].wins + 1
        else
            hs[itemKey].losses = hs[itemKey].losses + 1
        end
    end

    saveStats()
end

--------------------------------------------------------------------------------
-- COMPUTE LEARNING SCORE
-- Returns a value from roughly -4 to +4:
--   Items with >50% winrate on this hero → positive
--   Items with <50% winrate on this hero → negative
--   Items with insufficient data → 0
--
-- Formula: (winrate - 0.5) * LEARNING_WEIGHT
--   e.g. 70% winrate → (0.7 - 0.5) * 8 = +1.6
--   e.g. 30% winrate → (0.3 - 0.5) * 8 = -1.6
--------------------------------------------------------------------------------
function M.computeScore(heroName, itemKey)
    local hs = heroStats[heroName]
    if not hs then return 0 end
    local stat = hs[itemKey]
    if not stat then return 0 end

    local total = stat.wins + stat.losses
    if total < MIN_GAMES then return 0 end

    local winrate = stat.wins / total
    return (winrate - 0.5) * LEARNING_WEIGHT
end

--------------------------------------------------------------------------------
-- BATCH SCORE — Score multiple items for a hero at once.
-- Returns { [itemKey] = learningScore }
--------------------------------------------------------------------------------
function M.batchScore(heroName, itemKeys)
    local results = {}
    for _, key in ipairs(itemKeys) do
        results[key] = M.computeScore(heroName, key)
    end
    return results
end

--------------------------------------------------------------------------------
-- GET STATS (for UI / debug)
--------------------------------------------------------------------------------
function M.getStats(heroName, itemKey)
    local hs = heroStats[heroName]
    if not hs then return nil end
    return hs[itemKey]
end

function M.getHeroStats(heroName)
    return heroStats[heroName]
end

--------------------------------------------------------------------------------
-- INIT / RESET
--------------------------------------------------------------------------------
function M.init()
    loadStats()
end

function M.reset()
    -- Note: we do NOT clear heroStats on game end — they persist.
    -- Only call reset() if user wants to clear all learning data.
    heroStats = {}
    saveStats()
end

return M
