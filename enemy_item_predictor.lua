--------------------------------------------------------------------------------
-- ENEMY ITEM PREDICTOR — Predicts what enemy heroes will build next.
-- Extracted from threat_detector.lua + enhanced with confidence decay
-- and accuracy tracking.
--
-- Three prediction layers (checked in order):
--   1. Hero-specific build progression patterns
--   2. Role-based generic predictions
--   3. OpenDota meta build cache lookups
--------------------------------------------------------------------------------
local M = {}

local threats = nil
pcall(function() threats = require("threat_detector") end)

--------------------------------------------------------------------------------
-- BUILD PROGRESSIONS — if hero has item A, they likely build item B next
--------------------------------------------------------------------------------
M.BUILD_PROGRESSIONS = {
    npc_dota_hero_phantom_assassin = {
        {has="item_battlefury",    predict={"item_desolator","item_black_king_bar"}},
        {has="item_desolator",     predict={"item_black_king_bar","item_satanic"}},
        {has="item_black_king_bar",predict={"item_satanic","item_abyssal_blade"}},
    },
    npc_dota_hero_faceless_void = {
        {has="item_maelstrom",     predict={"item_black_king_bar","item_mjollnir"}},
        {has="item_mjollnir",      predict={"item_butterfly","item_satanic"}},
        {has="item_battlefury",    predict={"item_black_king_bar","item_butterfly"}},
    },
    npc_dota_hero_juggernaut = {
        {has="item_battlefury",    predict={"item_manta","item_butterfly"}},
        {has="item_maelstrom",     predict={"item_manta","item_black_king_bar"}},
        {has="item_manta",         predict={"item_butterfly","item_skadi"}},
    },
    npc_dota_hero_terrorblade = {
        {has="item_manta",         predict={"item_skadi","item_butterfly"}},
        {has="item_skadi",         predict={"item_butterfly","item_satanic"}},
    },
    npc_dota_hero_phantom_lancer = {
        {has="item_diffusal_blade",predict={"item_heart","item_manta"}},
        {has="item_heart",         predict={"item_butterfly","item_skadi"}},
    },
    npc_dota_hero_slark = {
        {has="item_diffusal_blade",predict={"item_black_king_bar","item_silver_edge"}},
        {has="item_silver_edge",   predict={"item_skadi","item_butterfly"}},
    },
    npc_dota_hero_ursa = {
        {has="item_blink",         predict={"item_black_king_bar","item_diffusal_blade"}},
        {has="item_black_king_bar",predict={"item_abyssal_blade","item_satanic"}},
    },
    npc_dota_hero_sven = {
        {has="item_blink",         predict={"item_black_king_bar","item_daedalus"}},
        {has="item_black_king_bar",predict={"item_daedalus","item_satanic"}},
    },
    npc_dota_hero_medusa = {
        {has="item_manta",         predict={"item_skadi","item_butterfly"}},
        {has="item_skadi",         predict={"item_butterfly","item_satanic"}},
    },
    npc_dota_hero_troll_warlord = {
        {has="item_battlefury",    predict={"item_black_king_bar","item_satanic"}},
        {has="item_black_king_bar",predict={"item_satanic","item_abyssal_blade"}},
    },
    npc_dota_hero_morphling = {
        {has="item_ethereal_blade",predict={"item_black_king_bar","item_linken"}},
        {has="item_manta",         predict={"item_butterfly","item_skadi"}},
    },
    npc_dota_hero_spectre = {
        {has="item_blade_mail",    predict={"item_manta","item_radiance"}},
        {has="item_radiance",      predict={"item_heart","item_butterfly"}},
        {has="item_manta",         predict={"item_skadi","item_butterfly"}},
    },
    npc_dota_hero_monkey_king = {
        {has="item_desolator",     predict={"item_black_king_bar","item_daedalus"}},
        {has="item_battlefury",    predict={"item_desolator","item_black_king_bar"}},
    },
    npc_dota_hero_weaver = {
        {has="item_desolator",     predict={"item_black_king_bar","item_daedalus"}},
        {has="item_sphere",        predict={"item_skadi","item_butterfly"}},
    },
    npc_dota_hero_invoker = {
        {has="item_hand_of_midas", predict={"item_blink","item_aghanims_shard"}},
        {has="item_blink",         predict={"item_octarine_core","item_sheepstick"}},
    },
    npc_dota_hero_storm_spirit = {
        {has="item_kaya",          predict={"item_bloodstone","item_orchid"}},
        {has="item_orchid",        predict={"item_bloodthorn","item_black_king_bar"}},
        {has="item_bloodstone",    predict={"item_sheepstick","item_black_king_bar"}},
    },
    npc_dota_hero_tinker = {
        {has="item_blink",         predict={"item_sheepstick","item_shivas_guard"}},
        {has="item_sheepstick",    predict={"item_shivas_guard","item_bloodstone"}},
    },
    npc_dota_hero_lina = {
        {has="item_cyclone",       predict={"item_black_king_bar","item_daedalus"}},
        {has="item_black_king_bar",predict={"item_daedalus","item_satanic"}},
    },
    npc_dota_hero_ember_spirit = {
        {has="item_maelstrom",     predict={"item_black_king_bar","item_gungir"}},
        {has="item_kaya",          predict={"item_octarine_core","item_shivas_guard"}},
    },
    npc_dota_hero_queenofpain = {
        {has="item_orchid",        predict={"item_black_king_bar","item_bloodthorn"}},
        {has="item_black_king_bar",predict={"item_aghanims_shard","item_sheepstick"}},
    },
    npc_dota_hero_axe = {
        {has="item_blink",         predict={"item_blade_mail","item_black_king_bar"}},
        {has="item_blade_mail",    predict={"item_black_king_bar","item_heart"}},
    },
    npc_dota_hero_tidehunter = {
        {has="item_blink",         predict={"item_shivas_guard","item_refresher"}},
    },
    npc_dota_hero_legion_commander = {
        {has="item_blink",         predict={"item_blade_mail","item_black_king_bar"}},
        {has="item_black_king_bar",predict={"item_desolator","item_assault"}},
    },
    npc_dota_hero_doom_bringer = {
        {has="item_blink",         predict={"item_black_king_bar","item_shivas_guard"}},
    },
    npc_dota_hero_lion = {
        {has="item_blink",         predict={"item_aghanims_shard","item_aether_lens"}},
    },
    npc_dota_hero_enigma = {
        {has="item_blink",         predict={"item_black_king_bar","item_refresher"}},
        {has="item_black_king_bar",predict={"item_refresher","item_aghanims_shard"}},
    },
}

M.GENERIC_PREDICTIONS = {
    carry = {
        early = {"item_black_king_bar","item_manta","item_desolator"},
        late  = {"item_butterfly","item_satanic","item_abyssal_blade","item_daedalus"},
    },
    mid = {
        early = {"item_black_king_bar","item_blink"},
        late  = {"item_sheepstick","item_octarine_core","item_bloodstone"},
    },
    offlane = {
        early = {"item_blink","item_blade_mail","item_pipe"},
        late  = {"item_black_king_bar","item_shivas_guard","item_assault","item_lotus_orb"},
    },
}

--------------------------------------------------------------------------------
-- ACCURACY TRACKING — Records whether past predictions came true so
-- we can scale confidence over the session.
--------------------------------------------------------------------------------
local accuracy = {
    correct   = 0,
    incorrect = 0,
    pending   = {},  -- [heroName] = { {item=..., predictedAt=...}, ... }
}

--- Internal: check which pending predictions came true based on current enemy items
local function updateAccuracy(enemies)
    for _, enemy in ipairs(enemies) do
        local pend = accuracy.pending[enemy.name]
        if pend then
            local owned = {}
            for _, it in ipairs(enemy.items or {}) do owned[it] = true end
            local remaining = {}
            for _, p in ipairs(pend) do
                if owned[p.item] then
                    accuracy.correct = accuracy.correct + 1
                else
                    remaining[#remaining + 1] = p
                end
            end
            accuracy.pending[enemy.name] = #remaining > 0 and remaining or nil
        end
    end
end

--- Get a multiplier (0.5–1.5) that reflects how well our predictions have been.
function M.getAccuracyMultiplier()
    local total = accuracy.correct + accuracy.incorrect
    if total < 5 then return 1.0 end  -- not enough data
    local rate = accuracy.correct / total
    return 0.5 + rate  -- maps 0% → 0.5x, 50% → 1.0x, 100% → 1.5x
end

--------------------------------------------------------------------------------
-- PREDICT — Main prediction function
--
-- Parameters:
--   enemies   — list of {name, items, level, ...} from match_collector
--   apiCache  — optional: api_client module for meta build lookups
--   gameTime  — current game time in seconds
--
-- Returns: {
--   predictions      = { [heroName] = { {item, confidence, reason}, ... } },
--   anticipatedItems = set of all predicted item names
-- }
--------------------------------------------------------------------------------
function M.predict(enemies, apiCache, gameTime)
    -- Update accuracy from previous predictions
    updateAccuracy(enemies)

    local accMul = M.getAccuracyMultiplier()
    local predictions = {}
    local anticipatedItems = {}

    -- Confidence decays as game goes late (predictions become less certain)
    local timeFactor = 1.0
    if (gameTime or 0) > 2400 then timeFactor = 0.7
    elseif (gameTime or 0) > 1800 then timeFactor = 0.85
    end

    for _, enemy in ipairs(enemies) do
        local preds = {}
        local owned = {}
        for _, it in ipairs(enemy.items or {}) do owned[it] = true end

        -- 1. Hero-specific progression patterns
        local patterns = M.BUILD_PROGRESSIONS[enemy.name]
        if patterns then
            for _, pat in ipairs(patterns) do
                if owned[pat.has] then
                    for _, pred in ipairs(pat.predict) do
                        if not owned[pred] then
                            preds[#preds + 1] = {
                                item       = pred,
                                confidence = math.min(1.0, 0.8 * timeFactor * accMul),
                                reason     = "Common after " .. (pat.has:gsub("^item_", "")),
                            }
                            anticipatedItems[pred] = true
                        end
                    end
                end
            end
        end

        -- 2. Generic role-based predictions
        if #preds == 0 and threats and threats.HERO_ROLES then
            local roleInfo = threats.HERO_ROLES[enemy.name]
            if roleInfo then
                local generic = M.GENERIC_PREDICTIONS[roleInfo.role]
                if generic then
                    local phase = (gameTime or 0) < 1800 and "early" or "late"
                    for _, pred in ipairs(generic[phase] or {}) do
                        if not owned[pred] then
                            preds[#preds + 1] = {
                                item       = pred,
                                confidence = math.min(1.0, 0.4 * timeFactor * accMul),
                                reason     = "Common for " .. roleInfo.role,
                            }
                            anticipatedItems[pred] = true
                        end
                    end
                end
            end
        end

        -- 3. OpenDota meta build lookup
        if apiCache and type(apiCache.getCachedBuild) == "function" then
            local heroID = nil
            if type(Engine) == "table" and Engine.GetHeroIDByName then
                local ok, id = pcall(Engine.GetHeroIDByName, enemy.name)
                if ok and id and id ~= 0 then heroID = id end
            end
            if heroID then
                local metaBuild = apiCache.getCachedBuild(heroID)
                if metaBuild then
                    local phase = (gameTime or 0) < 840 and "early"
                                  or (gameTime or 0) < 1800 and "mid"
                                  or "late"
                    local bucket = metaBuild[phase]
                    if bucket then
                        local count = 0
                        for _, entry in ipairs(bucket) do
                            if count >= 3 then break end
                            local key = entry.key
                            if key and not owned[key] then
                                local dup = false
                                for _, p in ipairs(preds) do
                                    if p.item == key then
                                        p.confidence = math.min(1.0, p.confidence + 0.2)
                                        dup = true
                                        break
                                    end
                                end
                                if not dup then
                                    preds[#preds + 1] = {
                                        item       = key,
                                        confidence = math.min(1.0, 0.5 * timeFactor * accMul),
                                        reason     = "Meta popular for hero",
                                    }
                                    anticipatedItems[key] = true
                                end
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end

        -- Sort by confidence, keep top 3
        table.sort(preds, function(a, b) return a.confidence > b.confidence end)
        local topPreds = {}
        for i = 1, math.min(#preds, 3) do topPreds[i] = preds[i] end

        if #topPreds > 0 then
            predictions[enemy.name] = topPreds
            -- Register as pending for accuracy tracking
            accuracy.pending[enemy.name] = {}
            for _, p in ipairs(topPreds) do
                accuracy.pending[enemy.name][#accuracy.pending[enemy.name]+1] = {
                    item = p.item, predictedAt = gameTime or 0,
                }
            end
        end
    end

    return {
        predictions      = predictions,
        anticipatedItems = anticipatedItems,
    }
end

--------------------------------------------------------------------------------
-- RESET (on game end)
--------------------------------------------------------------------------------
function M.reset()
    accuracy.correct   = 0
    accuracy.incorrect = 0
    accuracy.pending   = {}
end

return M
