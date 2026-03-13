--------------------------------------------------------------------------------
-- MATCH COLLECTOR — Game-state collection: heroes, items, phase, gold, NW
-- Consolidates hero detection, inventory scanning, and team enumeration
-- from the three original scripts into a single, cached module.
--------------------------------------------------------------------------------
local M = {}

local diag = {
    lastReason = nil,
}

local function logDiag(reason)
    if diag.lastReason == reason then return end
    diag.lastReason = reason
    Log.Write("[MatchCollector] " .. tostring(reason))
end

--------------------------------------------------------------------------------
-- SAFE-CALL WRAPPERS
--------------------------------------------------------------------------------
local function safeCall(fn, ...)
    if not fn then return nil end
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

local function safeStatic(tbl, method, ...)
    if type(tbl) ~= "table" then return nil end
    local fn = tbl[method]
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, ...)
    return ok and r or nil
end

local function safeMethod(obj, method, ...)
    if not obj then return nil end
    local fn = obj[method]
    if type(fn) ~= "function" then return nil end
    local ok, r = pcall(fn, obj, ...)
    return ok and r or nil
end

-- Exported for other modules to reuse
M.safeCall   = safeCall
M.safeStatic = safeStatic
M.safeMethod = safeMethod

--------------------------------------------------------------------------------
-- GAME PHASE
--------------------------------------------------------------------------------
M.PHASE_EARLY = 1
M.PHASE_MID   = 2
M.PHASE_LATE  = 3

function M.getGamePhase(gameTime)
    if gameTime < 840  then return M.PHASE_EARLY end   -- < 14 min
    if gameTime < 1800 then return M.PHASE_MID end     -- < 30 min
    return M.PHASE_LATE
end

function M.phaseLabel(phase)
    if phase == M.PHASE_EARLY then return "Early" end
    if phase == M.PHASE_MID   then return "Mid"   end
    return "Late"
end

--------------------------------------------------------------------------------
-- GAME TIME
--------------------------------------------------------------------------------
function M.getGameTime()
    local gt  = safeCall(GameRules.GetGameTime) or 0
    local gst = safeCall(GameRules.GetGameStartTime) or 0
    local t = gt - gst
    return t > 0 and t or 0
end

function M.getRawGameTime()
    return safeCall(GameRules.GetGameTime) or 0
end

function M.isInGame()
    -- Engine.IsInGame() may not exist in all Umbrella versions.
    -- Use Heroes.GetLocal() as the reliable fallback (same approach as Item Build.lua).
    local byEngine = safeCall(Engine.IsInGame)
    if byEngine == true then return true end
    -- Fallback: if a local hero entity exists, we're in an active game
    local hero = safeStatic(Heroes, "GetLocal")
    if hero then return true end
    logDiag("isInGame: false (Engine.IsInGame=" .. tostring(byEngine) .. ", Heroes.GetLocal=nil)")
    return false
end

--------------------------------------------------------------------------------
-- HERO IDENTIFICATION
--------------------------------------------------------------------------------
function M.getLocalHeroID()
    -- Path 1: player team data
    local player = safeStatic(Players, "GetLocal")
    if player then
        local td = safeStatic(Player, "GetTeamData", player)
        if td and td.selected_hero_id and td.selected_hero_id ~= 0 then
            return td.selected_hero_id
        end
        -- Path 2: iterate all players looking for our ID
        local pid = safeStatic(Player, "GetPlayerID", player)
        if pid then
            local all = safeStatic(Players, "GetAll") or {}
            for _, p in pairs(all) do
                if safeStatic(Player, "GetPlayerID", p) == pid then
                    local td2 = safeStatic(Player, "GetTeamData", p)
                    if td2 and td2.selected_hero_id and td2.selected_hero_id ~= 0 then
                        return td2.selected_hero_id
                    end
                end
            end
        end
    end
    -- Path 3: resolve from hero unit name
    local hero = safeStatic(Heroes, "GetLocal")
    if hero then
        local name = safeStatic(NPC, "GetUnitName", hero)
        if name and type(Engine) == "table" and Engine.GetHeroIDByName then
            return safeCall(Engine.GetHeroIDByName, name)
        end
    end
    return nil
end

function M.getLocalHeroName()
    local hero = safeStatic(Heroes, "GetLocal")
    if not hero then return nil end
    return safeStatic(NPC, "GetUnitName", hero)
end

function M.getDisplayName(unitName)
    if not unitName then return "Unknown" end
    local dn = safeCall(Engine.GetDisplayNameByUnitName, unitName)
    if dn and dn ~= "" then return dn end
    -- Fallback: strip prefix and prettify
    local n = unitName:gsub("^npc_dota_hero_", ""):gsub("_", " ")
    return n:gsub("(%a)([%w']*)", function(a, b) return a:upper() .. b end)
end

--------------------------------------------------------------------------------
-- ITEM SCANNING
--------------------------------------------------------------------------------
local function scanItems(npc)
    local items = {}
    if not npc then return items end
    -- Main inventory (0-5) + backpack (6-8)
    for i = 0, 8 do
        local item = safeStatic(NPC, "GetItemByIndex", npc, i)
        if item then
            local name = safeStatic(Ability, "GetName", item)
            if name and name ~= "" then items[#items + 1] = name end
        end
    end
    -- Neutral item slot (16)
    local neutral = safeStatic(NPC, "GetItemByIndex", npc, 16)
    if neutral then
        local name = safeStatic(Ability, "GetName", neutral)
        if name and name ~= "" then items[#items + 1] = name end
    end
    return items
end

local function estimateHeroNW(npc)
    local nw = 0
    for i = 0, 8 do
        local item = safeStatic(NPC, "GetItemByIndex", npc, i)
        if item then
            local cost = safeMethod(item, "GetCost")
            if cost and cost > 0 then nw = nw + cost end
        end
    end
    return nw
end

M.scanItems = scanItems

--------------------------------------------------------------------------------
-- ENEMY ITEM TRACKING  (detects new purchases between snapshots)
--------------------------------------------------------------------------------
local prevEnemyItems = {}   -- [heroName] = { item1, item2, ... }

function M.detectNewPurchases(enemies)
    local result = {}
    for _, enemy in ipairs(enemies) do
        local prev = prevEnemyItems[enemy.name]
        if prev then
            local prevSet = {}
            for _, it in ipairs(prev) do prevSet[it] = true end
            local bought = {}
            for _, it in ipairs(enemy.items or {}) do
                if not prevSet[it] then bought[#bought + 1] = it end
            end
            if #bought > 0 then result[enemy.name] = bought end
        end
        prevEnemyItems[enemy.name] = enemy.items or {}
    end
    return result
end

function M.resetTracking()
    prevEnemyItems = {}
end

--------------------------------------------------------------------------------
-- SNAPSHOT COLLECTION
-- Returns a full match state table (or nil if not in game).
-- Caches for `cacheInterval` game-time seconds.
--------------------------------------------------------------------------------
local cache = { lastAt = 0, interval = 2, snap = nil }

function M.invalidateCache() cache.lastAt = 0 end

function M.collectSnapshot()
    local now = M.getRawGameTime()
    if cache.snap and (now - cache.lastAt) < cache.interval then
        return cache.snap
    end

    local me = safeStatic(Heroes, "GetLocal")
    if not me then
        logDiag("collectSnapshot: Heroes.GetLocal() returned nil")
        return nil
    end
    local myTeam = safeStatic(Entity, "GetTeamNum", me)
    if not myTeam then
        logDiag("collectSnapshot: Entity.GetTeamNum(localHero) returned nil")
        return nil
    end

    diag.lastReason = nil

    local gameTime = M.getGameTime()
    local phase    = M.getGamePhase(gameTime)
    local myItems  = scanItems(me)
    local myItemSet = {}
    for _, it in ipairs(myItems) do myItemSet[it] = true end

    -- Enumerate heroes once
    local allies, enemies = {}, {}
    local allyItemCounts, enemyItemCounts = {}, {}
    local myTeamNW, enemyTeamNW = estimateHeroNW(me), 0
    local seenNames = {}
    local enemyItemSets = {}

    local allHeroes = safeStatic(Heroes, "GetAll") or {}
    for _, hero in ipairs(allHeroes) do
        if not hero or hero == me then goto next_hero end
        local team = safeStatic(Entity, "GetTeamNum", hero)
        if not team then goto next_hero end
        -- Skip phantoms
        if safeStatic(NPC, "IsIllusion", hero) then goto next_hero end
        if safeStatic(NPC, "IsClone", hero) then goto next_hero end
        if safeStatic(NPC, "IsTempestDouble", hero) then goto next_hero end

        local name = safeStatic(NPC, "GetUnitName", hero) or ""
        if name == "" or seenNames[name] then goto next_hero end
        seenNames[name] = true

        local heroItems = scanItems(hero)
        local heroData = {
            name        = name,
            displayName = M.getDisplayName(name),
            level       = safeStatic(NPC, "GetCurrentLevel", hero) or 0,
            alive       = safeStatic(Entity, "IsAlive", hero) ~= false,
            items       = heroItems,
        }

        local heroNW = estimateHeroNW(hero)
        if team == myTeam then
            allies[#allies + 1] = heroData
            myTeamNW = myTeamNW + heroNW
            for _, it in ipairs(heroItems) do
                allyItemCounts[it] = (allyItemCounts[it] or 0) + 1
            end
        else
            enemies[#enemies + 1] = heroData
            enemyTeamNW = enemyTeamNW + heroNW
            local eSet = {}
            for _, it in ipairs(heroItems) do
                enemyItemCounts[it] = (enemyItemCounts[it] or 0) + 1
                eSet[it] = true
            end
            enemyItemSets[name] = eSet
        end
        ::next_hero::
    end

    -- Aggregate all enemy items into a single set for quick lookup
    local allEnemyItems = {}
    for _, iset in pairs(enemyItemSets) do
        for it in pairs(iset) do allEnemyItems[it] = true end
    end

    -- Gold
    local myGold = 0
    local player = safeStatic(Players, "GetLocal")
    if player then
        local g = safeStatic(Player, "GetTotalGold", player)
        if g and g > 0 then myGold = g end
    end

    local nwDiff = myTeamNW - enemyTeamNW
    local snapshot = {
        heroName          = safeStatic(NPC, "GetUnitName", me) or "",
        heroID            = M.getLocalHeroID(),
        gameTime          = gameTime,
        phase             = phase,
        myItems           = myItems,
        myItemSet         = myItemSet,
        myGold            = myGold,
        allies            = allies,
        enemies           = enemies,
        allyItemCounts    = allyItemCounts,
        enemyItemCounts   = enemyItemCounts,
        myTeamNW          = myTeamNW,
        enemyTeamNW       = enemyTeamNW,
        nwAdvantage       = nwDiff,
        isLosing          = nwDiff < -5000,
        isWinning         = nwDiff > 5000,
        enemyItemSets     = enemyItemSets,
        allEnemyItems     = allEnemyItems,
        newEnemyPurchases = M.detectNewPurchases(enemies),
    }

    cache.snap   = snapshot
    cache.lastAt = now
    return snapshot
end

return M
