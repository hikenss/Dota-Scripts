local script = {}

local radiant = Vector(6752.5625, 6281.28125, 384.0)
local dire = Vector(-6988.40625, -6464.71875, 384.0)

local Menu = Menu.Create("Heroes", "Hero List", "Timbersaw", "Main Settings", "Harass Position")
local Bind = Menu:Bind("Harass Key", Enum.ButtonCode.BUTTON_CODE_INVALID)
local MinTreeDistance = Menu:Slider("Minimum Distance From Cursor", 500, 2000, 1200)

Bind:ToolTip(
  "Для работы необходим первый скилл,второй скилл и блинк (Обязательно все кнопки без кд)\nДаст цепь в самое безопасное дерево после блинк и скилы (сейф харасс)")

local bestTreeGlobal = nil
local enemyTowers = {}
local state = "idle"
local chainCastTime, blinkCastTime, chakramCastTime = 0, 0, 0
local lastTowerUpdate, lastTreeScan = 0, 0
local cachedTrees = {}

local function pointLineDistance(p, a, b)
  local ab = b - a
  local ap = p - a
  local ab_len_sq = ab:Length2DSqr()
  if ab_len_sq == 0 then return ap:Length2D() end
  local t = ap:Dot(ab) / ab_len_sq
  t = math.max(0, math.min(1, t))
  return (p - (a + ab * t)):Length2D()
end

local function isPathClear(startPos, endPos, trees, targetTree)
  local dir = endPos - startPos
  local dirLenSq = dir:Length2DSqr()
  if dirLenSq == 0 then return false end
  for _, tree in ipairs(trees) do
    if tree ~= targetTree then
      local tpos = Entity.GetAbsOrigin(tree)
      if (tpos.x >= math.min(startPos.x, endPos.x) - 100 and tpos.x <= math.max(startPos.x, endPos.x) + 100)
          and (tpos.y >= math.min(startPos.y, endPos.y) - 100 and tpos.y <= math.max(startPos.y, endPos.y) + 100) then
        local d = pointLineDistance(tpos, startPos, endPos)
        if d < 75 then
          local proj = (tpos - startPos):Dot(dir) / dirLenSq
          if proj > 0 and proj < 1 then return false end
        end
      end
    end
  end
  return true
end

local function getTreeScore(treePos, heroPos, hero, enemies, fountainPos, enemyFountainPos, towers)
  local s = 0
  local fw, dmgR = 100, 225
  local alive = {}
  for _, e in ipairs(enemies) do
    if not Entity.IsSameTeam(e, hero) and Entity.IsHero(e) and Entity.IsAlive(e) then
      table.insert(alive, Entity.GetAbsOrigin(e))
    end
  end
  for _, epos in ipairs(alive) do
    if pointLineDistance(epos, heroPos, treePos) <= fw then
      s = s + 10000
    end
  end
  local closest = math.huge
  for _, epos in ipairs(alive) do
    closest = math.min(closest, (treePos - epos):Length2D())
  end
  if closest > dmgR and closest < 800 then
    s = s + (800 - closest)
  end
  s = s + (treePos - heroPos):Length2D() * 0.25
  s = s + ((treePos - heroPos):Normalized():Dot((fountainPos - heroPos):Normalized()) * 5000)
  local fd = (treePos - fountainPos):Length2D()
  s = s + (1500 / (fd + 1))
  local efd = (treePos - enemyFountainPos):Length2D()
  if efd < 1200 then
    s = s - (5000 * (1 - efd / 1200))
  end
  for _, tower in ipairs(towers) do
    local td = (treePos - Entity.GetAbsOrigin(tower)):Length2D()
    if td < 900 then
      s = s - (3000 * (1 - td / 900))
    end
  end
  return s
end

local function findBestTimberChainTree(hero, ability, enemies, trees)
  local best, bestScore = nil, -1
  local range = Ability.GetCastRange(ability)
  local pos = Entity.GetAbsOrigin(hero)
  local team = Entity.GetTeamNum(hero)
  local fountain = (team == 2) and dire or radiant
  local enemyFountain = (team == 2) and radiant or dire
  local minDist = MinTreeDistance:Get()
  for _, tree in ipairs(trees) do
    local treePos = Entity.GetAbsOrigin(tree)
    local dist = (treePos - pos):Length2D()
    if dist <= range and dist >= minDist then
      if isPathClear(pos, treePos, trees, tree) then
        local score = getTreeScore(treePos, pos, hero, enemies, fountain, enemyFountain, enemyTowers)
        if score > bestScore then
          bestScore, best = score, tree
        end
      end
    end
  end
  return best
end

local function updateEnemyTowers(hero, now)
  if now - lastTowerUpdate < 5 then return end
  lastTowerUpdate = now
  enemyTowers = {}
  for _, v in pairs(NPCs.GetAll(Enum.UnitTypeFlags.TYPE_TOWER)) do
    if not Entity.IsSameTeam(v, hero) and Entity.IsAlive(v) then
      table.insert(enemyTowers, v)
    end
  end
end

local function updateNearbyTrees(hero, ability, now)
  if now - lastTreeScan < 0.3 then return cachedTrees end
  lastTreeScan = now
  local pos = Entity.GetAbsOrigin(hero)
  cachedTrees = Trees.InRadius(pos, Ability.GetCastRange(ability))
  return cachedTrees
end

script.OnUpdate = function()
  local me = Heroes.GetLocal()
  if not me or not Entity.IsAlive(me) then return end
  if not Bind:IsDown() then
    state = "idle"
    return
  end

  local pos = Entity.GetAbsOrigin(me)
  local chain = NPC.GetAbility(me, "shredder_timber_chain")
  local death = NPC.GetAbility(me, "shredder_whirling_death")
  local chakram = NPC.GetAbility(me, "shredder_chakram")
  local retChakram = NPC.GetAbility(me, "shredder_return_chakram")
  local blink = NPC.GetItem(me, "item_blink", true)
      or NPC.GetItem(me, "item_overwhelming_blink", true)
      or NPC.GetItem(me, "item_swift_blink", true)
      or NPC.GetItem(me, "item_arcane_blink", true)
  if not blink then return end

  local cursor = Input.GetWorldCursorPos()
  if (cursor - pos):Length2D() > Ability.GetCastRange(blink) then return end

  local now = GameRules.GetGameTime()

  if state == "idle" then
    if chain and death and chakram and blink
        and Ability.CanBeExecuted(chain) == -1
        and Ability.CanBeExecuted(death) == -1
        and Ability.CanBeExecuted(blink) == -1 then
      updateEnemyTowers(me, now)
      local heroes = Heroes.GetAll()
      local trees = updateNearbyTrees(me, chain, now)
      bestTreeGlobal = findBestTimberChainTree(me, chain, heroes, trees)
      if bestTreeGlobal then
        Ability.CastPosition(chain, Entity.GetAbsOrigin(bestTreeGlobal), false, false, true, false)
      else
        return
      end
      chainCastTime = now
      state = "afterChain"
    end
  elseif state == "afterChain" then
    if now - chainCastTime >= 0.1 then
      Ability.CastPosition(blink, cursor, false, false, true, false)
      blinkCastTime = now
      state = "afterBlink"
    end
  elseif state == "afterBlink" then
    if now - blinkCastTime >= 0.1 then
      Ability.CastNoTarget(death, false, false, true, false)
      Ability.CastPosition(chakram, cursor, false, false, true, false, true)
      chakramCastTime = now
      state = "waitingReturn"
    end
  elseif state == "waitingReturn" then
    if now - chakramCastTime >= 1.0 then
      if retChakram and Ability.CanBeExecuted(retChakram) == -1 then
        Ability.CastNoTarget(retChakram)
      end
      state = "done"
    end
  end
end

return script
