--------------------------------------------------------------------------------
-- ITEM TIMING ENGINE — Tracks ideal purchase timings for items.
-- Computes a timing_score bonus/penalty based on whether a purchase
-- would be on-time, early, or late relative to typical benchmarks.
--
-- Early purchases → small bonus (ahead of curve)
-- On-time purchases → neutral
-- Late purchases → penalty (item value decreases)
--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
-- IDEAL PURCHASE TIMINGS  (game-time in seconds)
-- Based on typical Divine/Immortal bracket benchmarks.
-- {ideal = optimal purchase time, window = acceptable ± range}
--------------------------------------------------------------------------------
local ITEM_TIMINGS = {
    -- Early game items (should be bought by ~12-15 min)
    item_phase_boots      = {ideal =  480, window = 180},
    item_power_treads     = {ideal =  480, window = 180},
    item_arcane_boots     = {ideal =  540, window = 180},
    item_vanguard         = {ideal =  600, window = 240},
    item_mekansm          = {ideal =  720, window = 240},
    item_vladmir          = {ideal =  720, window = 240},
    item_diffusal_blade   = {ideal =  840, window = 240},
    item_cyclone          = {ideal =  780, window = 300},
    item_rod_of_atos      = {ideal =  780, window = 300},
    item_ghost            = {ideal =  720, window = 300},
    item_dust             = {ideal =  300, window = 600},
    item_ward_sentry      = {ideal =  300, window = 600},
    item_pavise           = {ideal =  600, window = 240},
    item_solar_crest      = {ideal =  840, window = 300},
    item_blade_mail       = {ideal =  780, window = 300},
    item_glimmer_cape     = {ideal =  780, window = 300},
    item_maelstrom        = {ideal =  840, window = 300},
    item_orchid           = {ideal =  900, window = 300},
    item_spirit_vessel    = {ideal =  840, window = 300},
    item_force_staff      = {ideal =  780, window = 300},

    -- Mid game core items (should be bought by ~20-28 min)
    item_blink            = {ideal =  900, window = 360},
    item_desolator        = {ideal = 1020, window = 360},
    item_black_king_bar   = {ideal = 1200, window = 420},
    item_manta            = {ideal = 1200, window = 360},
    item_pipe             = {ideal = 1080, window = 360},
    item_crimson_guard    = {ideal = 1080, window = 360},
    item_lotus_orb        = {ideal = 1200, window = 420},
    item_battlefury       = {ideal =  900, window = 300},
    item_disperser        = {ideal = 1200, window = 360},
    item_heavens_halberd  = {ideal = 1200, window = 360},
    item_harpoon          = {ideal = 1200, window = 360},
    item_hurricane_pike   = {ideal = 1080, window = 360},
    item_gungir           = {ideal = 1320, window = 420},
    item_aghanims_shard   = {ideal =  900, window = 300},
    item_ultimate_scepter = {ideal = 1200, window = 420},

    -- Late game items (bought ~28-40+ min)
    item_mjollnir         = {ideal = 1500, window = 420},
    item_assault          = {ideal = 1500, window = 480},
    item_shivas_guard     = {ideal = 1500, window = 480},
    item_heart            = {ideal = 1500, window = 480},
    item_butterfly        = {ideal = 1620, window = 480},
    item_satanic          = {ideal = 1620, window = 480},
    item_skadi            = {ideal = 1620, window = 480},
    item_abyssal_blade    = {ideal = 1680, window = 480},
    item_daedalus         = {ideal = 1500, window = 480},
    item_monkey_king_bar  = {ideal = 1500, window = 480},
    item_nullifier        = {ideal = 1620, window = 480},
    item_bloodthorn       = {ideal = 1620, window = 480},
    item_silver_edge      = {ideal = 1320, window = 420},
    item_sphere           = {ideal = 1320, window = 420},
    item_aeon_disk        = {ideal = 1320, window = 420},
    item_wind_waker       = {ideal = 1500, window = 480},
    item_radiance         = {ideal = 1200, window = 360},
    item_guardian_greaves  = {ideal = 1320, window = 420},
    item_sheepstick       = {ideal = 1620, window = 480},
}

--------------------------------------------------------------------------------
-- COMPUTE TIMING SCORE
--
-- Returns a score from -5 to +5:
--   +3 to +5  → buying early (ahead of meta timing)
--    0        → on-time (within window)
--   -3 to -5  → buying late (item value is diminishing)
--
-- Items without timing data get score 0.
--------------------------------------------------------------------------------
function M.computeTimingScore(itemKey, gameTime)
    local timing = ITEM_TIMINGS[itemKey]
    if not timing then return 0 end

    local diff = gameTime - timing.ideal
    local halfWindow = timing.window / 2

    if math.abs(diff) <= halfWindow then
        -- Within window: slight bonus for being early-side
        return diff < 0 and 1 or 0
    elseif diff < -halfWindow then
        -- Very early purchase: bonus (capped at +5)
        local earlyness = math.abs(diff) / timing.window
        return math.min(5, math.floor(earlyness * 3 + 1))
    else
        -- Late purchase: penalty (capped at -5)
        local lateness = diff / timing.window
        return math.max(-5, -math.floor(lateness * 3))
    end
end

--------------------------------------------------------------------------------
-- BATCH SCORE — Score multiple item candidates at once.
-- Returns table: { [itemKey] = timingScore }
--------------------------------------------------------------------------------
function M.batchScore(itemKeys, gameTime)
    local results = {}
    for _, key in ipairs(itemKeys) do
        results[key] = M.computeTimingScore(key, gameTime)
    end
    return results
end

--------------------------------------------------------------------------------
-- GET IDEAL TIMING (for UI display if needed)
--------------------------------------------------------------------------------
function M.getIdealTiming(itemKey)
    return ITEM_TIMINGS[itemKey]
end

return M
