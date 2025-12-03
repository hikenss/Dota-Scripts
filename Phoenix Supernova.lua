local script = {}



local Menu = Menu.Create("Heroes", "Hero List", "Phoenix", "Main Settings", "Supernova Settings")

local ShowIfGonnaSurvive = Menu:Switch("Mostrar se vai sobreviver com Supernova", true,
  "panorama/images/spellicons/phoenix_supernova_png.vtex_c")

local EscapeSettings = Menu:Label("Dive Escape Inteligente")
local EscapeKey = Menu:Bind("Tecla de Escape", Enum.ButtonCode.KEY_NONE)
local AutoCancelDive = Menu:Switch("Cancelar Dive no Alcance Máximo", true)

-- Panel customization settings

local PanelSettings = Menu:Label("Configurações do Painel")

local PanelSize = Menu:Slider("Tamanho do Painel", 50, 150, 100, 5)

local PanelOffsetX = Menu:Slider("Deslocamento X do Painel", -500, 500, 0, 1)

local PanelOffsetY = Menu:Slider("Deslocamento Y do Painel", -500, 500, -160, 1)

local PanelOpacity = Menu:Slider("Opacidade do Painel", 0, 255, 230, 5)

local ShowProgressBar = Menu:Switch("Mostrar Barra de Progresso", true)

local ShowSubtext = Menu:Switch("Mostrar Subtexto", true)



local hero = nil

local font = Render.LoadFont("Arial", 0, 500)

local fontSmall = Render.LoadFont("Arial", 0, 400)



-- Helpers

local function clamp(x, a, b) if x < a then return a elseif x > b then return b else return x end end

local function Dist2D(a, b)

  return a:Distance(b)

end



local function C(r, g, b, a)

  return Color(r, g, b, a or 255)

end



local function getEggDuration(supernova)

  local dur = Ability.GetLevelSpecialValueFor(supernova, "duration")

  if not dur or dur <= 0 then dur = Ability.GetLevelSpecialValueFor(supernova, "egg_duration") end

  if not dur or dur <= 0 then dur = 6.0 end

  return dur

end



local function getEffectiveAttackRange(attacker, eggHolder)

  local base = NPC.GetAttackRange(attacker) or 0

  local bonus = NPC.GetAttackRangeBonus(attacker) or 0

  local aHull = NPC.GetPaddedCollisionRadius(attacker) or NPC.GetHullRadius(attacker) or 8

  local eHull = NPC.GetPaddedCollisionRadius(eggHolder) or NPC.GetHullRadius(eggHolder) or 64

  -- Center-to-center effective range, include both hulls (approx for egg)

  return base + bonus + aHull + eHull

end



local function getDisableDurations(u)

  local states_to_check = {

    [Enum.ModifierState.MODIFIER_STATE_STUNNED] = true,

    [Enum.ModifierState.MODIFIER_STATE_HEXED] = true,

    [Enum.ModifierState.MODIFIER_STATE_DISARMED] = true,

    [Enum.ModifierState.MODIFIER_STATE_ROOTED] = true,

  }

  local s = NPC.GetStatesDuration(u, states_to_check, true) or {}

  return

      (s[Enum.ModifierState.MODIFIER_STATE_STUNNED] or 0.0),

      (s[Enum.ModifierState.MODIFIER_STATE_HEXED] or 0.0),

      (s[Enum.ModifierState.MODIFIER_STATE_DISARMED] or 0.0),

      (s[Enum.ModifierState.MODIFIER_STATE_ROOTED] or 0.0)

end



-- First damage time from a single attacker to the egg position

local function estimateFirstDamageTime(attacker, eggHolder, eggPos)

  -- Ignore dead or invalid

  if not attacker or not Entity.IsAlive(attacker) then return nil end



  -- Only heroes and hero illusions count

  if not (NPC.IsHero(attacker)) then return nil end



  -- Attacker params

  local aps = NPC.GetAttacksPerSecond(attacker, false) or 0.0

  if aps <= 0.01 then return nil end



  local secPerAttack = NPC.GetSecondsPerAttack(attacker, false) or (1.0 / aps)

  if secPerAttack <= 0.0 then secPerAttack = 1.0 / math.max(aps, 0.01) end



  local animPoint = clamp(NPC.GetAttackAnimPoint(attacker) or 0.3, 0.0, 1.0)

  local attackPointTime = secPerAttack * animPoint



  local isRanged = NPC.IsRanged(attacker)

  local projSpeed = 0

  if isRanged then

    projSpeed = NPC.GetAttackProjectileSpeed(attacker) or 900

    if projSpeed < 1 then projSpeed = 900 end

  end



  -- Disable durations

  local stun, hex, disarm, root = getDisableDurations(attacker)



  -- Geometry

  local pos = Entity.GetAbsOrigin(attacker)

  local dist = Dist2D(pos, eggPos)

  local effRange = getEffectiveAttackRange(attacker, eggHolder)

  local outOfRange = dist > effRange



  -- Movement calculations

  local ms = NPC.GetMoveSpeed(attacker) or 300

  if ms < 1 then ms = 1 end



  local distToCover = outOfRange and (dist - effRange) or 0.0

  if distToCover < 0 then distToCover = 0 end



  -- Calculate when the unit can start moving

  -- Stun and hex prevent all actions (movement and attacking)

  local immobileTime = math.max(stun, hex)



  -- If out of range and rooted, add root duration to movement delay

  -- (root only matters if they need to move)

  local moveStartDelay = immobileTime

  if outOfRange and root > moveStartDelay then

    moveStartDelay = root

  end



  local moveTime = distToCover / ms



  -- Facing time

  local faceTime = NPC.GetTimeToFacePosition and (NPC.GetTimeToFacePosition(attacker, eggPos) or 0.0) or 0.0

  -- Roughly subtract the portion of turning that can happen while moving

  local faceAfterMove = math.max(0.0, faceTime - moveTime)



  -- Time when they can launch the first attack (after moving into range and facing)

  local readyToAttackTime = moveStartDelay + moveTime + faceAfterMove + attackPointTime



  -- But they also can't attack while disarmed, stunned, or hexed

  -- We already accounted for stun/hex in movement, but need to check if disarm extends beyond that

  local attackBlockedUntil = math.max(stun, hex, disarm)



  -- The actual attack launch time is the later of these two

  local attackLaunchTime = math.max(readyToAttackTime, attackBlockedUntil)



  -- Projectile travel (ranged only). Distance at launch ~ in-range distance.

  local launchDistance = math.min(dist, effRange)

  local projectileTime = (isRanged and (launchDistance / projSpeed)) or 0.0



  local firstDamageTime = attackLaunchTime + projectileTime

  return firstDamageTime, secPerAttack

end



-- Build per-attacker damage timelines

local function buildAttackEventsWithinDuration(hero, eggPos, duration)

  local units = Entity.GetUnitsInRadius(hero, 1200)

  if not units then return {} end



  local myTeam = Entity.GetTeamNum(hero)

  local events = {}



  for _, u in ipairs(units) do

    if u and u ~= hero and Entity.IsAlive(u) and Entity.GetTeamNum(u) ~= myTeam then

      if NPC.IsHero(u) then

        local tFirst, dt = estimateFirstDamageTime(u, hero, eggPos)

        if tFirst and dt and tFirst <= duration then

          table.insert(events, { t = tFirst, dt = dt })

        end

      end

    end

  end



  return events

end



-- Merge timelines to see if/when egg dies

local function simulateEggDestructionTime(events, duration, hitsRequired)

  if hitsRequired <= 0 then return nil end

  if #events == 0 then return nil end



  local hits = 0

  while true do

    -- Find the soonest event

    local idxMin, tMin = nil, nil

    for i = 1, #events do

      local e = events[i]

      if e and e.t then

        if not tMin or e.t < tMin then

          tMin = e.t

          idxMin = i

        end

      end

    end



    if not idxMin or not tMin then break end

    if tMin > duration then break end



    hits = hits + 1

    if hits >= hitsRequired then

      return tMin

    end



    -- Advance that attacker's next hit by its attack period

    local e = events[idxMin]

    e.t = e.t + e.dt

    if e.t > duration then

      table.remove(events, idxMin)

      if #events == 0 then break end

    end

  end



  return nil

end



local function getTotalAPS(hero)

  local units = Entity.GetUnitsInRadius(hero, 1200)

  if not units then return 0 end

  local myTeam = Entity.GetTeamNum(hero)

  local total = 0.0

  for _, u in ipairs(units) do

    if u and u ~= hero and Entity.IsAlive(u) and Entity.GetTeamNum(u) ~= myTeam then

      if NPC.IsHero(u) then

        total = total + (NPC.GetAttacksPerSecond(u, false) or 0.0)

      end

    end

  end

  return total

end



-- Drawing helpers (Render v2)

local function drawPanel(center, headerColor, verdictText, subText, percent)

  -- Get size multiplier

  local scale = PanelSize:Get() / 100



  -- Base dimensions

  local baseW, baseH = 280, 92

  local w = baseW * scale

  local h = baseH * scale



  -- Get offsets

  local offsetX = PanelOffsetX:Get()

  local offsetY = PanelOffsetY:Get()

  local opacity = PanelOpacity:Get()



  -- Calculate position with offsets

  local x = center.x - w * 0.5 + offsetX

  local y = center.y + offsetY



  local p0 = Vector(x, y, 0)

  local p1 = Vector(x + w, y + h, 0)



  -- Adjust opacity for all colors

  local function adjustOpacity(color, alpha)

    return C(color.r, color.g, color.b, math.floor(alpha * opacity / 255))

  end



  -- Shadow + background + border

  Render.Shadow(p0, p1, adjustOpacity(C(0, 0, 0), 180), 22 * scale, 10 * scale)

  Render.Gradient(p0, p1,

    adjustOpacity(C(20, 22, 28), 230),

    adjustOpacity(C(20, 22, 28), 230),

    adjustOpacity(C(12, 14, 18), 230),

    adjustOpacity(C(12, 14, 18), 230),

    10 * scale)

  Render.OutlineGradient(p0, p1,

    adjustOpacity(C(70, 70, 80), 70),

    adjustOpacity(C(70, 70, 80), 70),

    adjustOpacity(C(30, 30, 35), 70),

    adjustOpacity(C(30, 30, 35), 70),

    10 * scale, nil, 1.5 * scale)



  -- Header

  local header = "Estado da Supernova"

  local headerPos = Vector(x + 12 * scale, y + 10 * scale, 0)

  Render.Text(font, 18 * scale, header, headerPos, adjustOpacity(C(180, 190, 210), 255))



  -- Verdict

  local verdictPos = Vector(x + 12 * scale, y + 36 * scale, 0)

  Render.Text(font, 18 * scale, verdictText, verdictPos, adjustOpacity(headerColor, 255))



  -- Subtext (if enabled)

  if ShowSubtext:Get() then

    local subPos = Vector(x + 12 * scale, y + 60 * scale, 0)

    Render.Text(fontSmall, 14 * scale, subText, subPos, adjustOpacity(C(210, 215, 225), 220))

  end



  -- Progress bar (if enabled)

  if ShowProgressBar:Get() then

    local barStart = Vector(x + 12 * scale, y + h - 16 * scale, 0)

    local barEnd   = Vector(x + w - 12 * scale, y + h - 6 * scale, 0)

    local barColor = adjustOpacity(headerColor, 255)

    Render.RoundedProgressRect(barStart, barEnd, barColor, clamp(percent, 0, 1), 6 * scale, 2.0 * scale)

  end

end



script.OnDraw = function()

  if not ShowIfGonnaSurvive:Get() then return end



  if hero == nil then

    hero = Heroes.GetLocal()

  end

  if not hero or not Entity.IsAlive(hero) then return end



  local heroname = NPC.GetUnitName(hero)

  if heroname ~= "npc_dota_hero_phoenix" then return end



  local supernova = NPC.GetAbility(hero, "phoenix_supernova")

  if not supernova then return end



  if Ability.GetCooldown(supernova) > 0.0 then return end

  if NPC.GetMana(hero) < Ability.GetManaCost(supernova) then return end

  if Ability.GetLevel(supernova) <= 0 then return end



  local hitsRequired = math.floor(Ability.GetLevelSpecialValueFor(supernova, "max_hero_attacks"))

  if NPC.HasScepter and NPC.HasScepter(hero) then

    local level = Ability.GetLevel(supernova)

    hitsRequired = hitsRequired + level

  end

  if not hitsRequired or hitsRequired <= 0 then return end



  local eggDuration = getEggDuration(supernova)

  local eggPos = Entity.GetAbsOrigin(hero)



  -- Build events with movement/range/attack type/turning/projectile considered

  local events = buildAttackEventsWithinDuration(hero, eggPos, eggDuration)



  -- Simulate egg destruction

  local killedAt = simulateEggDestructionTime(events, eggDuration, hitsRequired)

  local survive = (killedAt == nil)



  -- For UI only

  local totalAPS = getTotalAPS(hero)



  -- Draw UI panel near hero

  local screenPos, visible = Render.WorldToScreen(eggPos)

  if not visible then return end



  local verdictText, color, percent

  if survive then

    verdictText = "VAI SOBREVIVER"

    color = C(82, 222, 127, 255)

    percent = 0.0

  else

    verdictText = string.format("VAI MORRER em %.2fs", killedAt)

    color = C(255, 105, 105, 255)

    percent = (eggDuration > 0) and (killedAt / eggDuration) or 1.0

  end



  local subText = string.format("APS Inimigo: %.2f | Hits: %d | Ovo: %.1fs", totalAPS, hitsRequired, eggDuration)
  drawPanel(screenPos, color, verdictText, subText, percent)
end

-- Helper para posição da fonte
local function getFountainPos(hero)
  local team = Entity.GetTeamNum(hero)
  -- Radiant: 2, Dire: 3. Coordenadas aproximadas.
  if team == 2 then
    return Vector(-7200, -6666, 384)
  else
    return Vector(7000, 6450, 384)
  end
end

-- Flags para controle do Dive AI
local diveStartedByEscapeAI = false
local pendingEscapeDive = false

script.OnUpdate = function()
  if not hero then hero = Heroes.GetLocal() end
  if not hero or not Entity.IsAlive(hero) then return end

  local dive = NPC.GetAbility(hero, "phoenix_icarus_dive")
  if not dive then return end

  local isDiving = NPC.HasModifier(hero, "modifier_phoenix_icarus_dive")

  -- Toggle automático do switch de cancelamento
  if EscapeKey:IsDown() then
    if not AutoCancelDive:Get() then AutoCancelDive:Set(true) end
  else
    if AutoCancelDive:Get() then AutoCancelDive:Set(false) end
  end

  -- 1. Lógica de Cast (Quando a tecla é pressionada e não está divando)
  if EscapeKey:IsDown() and not isDiving then
    if Ability.IsCastable(dive, NPC.GetMana(hero)) and Ability.GetCooldown(dive) == 0 then
      local myPos = Entity.GetAbsOrigin(hero)
      local fountainPos = getFountainPos(hero)
      local finalDir = (fountainPos - myPos):Normalized()
      local enemies = Entity.GetUnitsInRadius(hero, 1200, Enum.TeamType.TEAM_ENEMY)
      local repulsion = Vector(0, 0, 0)
      local enemyCount = 0
      for _, enemy in ipairs(enemies) do
        if enemy and NPC.IsHero(enemy) and not NPC.IsIllusion(enemy) and Entity.IsAlive(enemy) then
          local enemyPos = Entity.GetAbsOrigin(enemy)
          local diff = myPos - enemyPos
          local dist = diff:Length2D()
          if dist > 0 then
            local weight = 1000 / dist
            repulsion = repulsion + (diff:Normalized() * weight)
            enemyCount = enemyCount + 1
          end
        end
      end
      if enemyCount > 0 then
        finalDir = (finalDir + repulsion):Normalized()
      end
      local castPos = myPos + finalDir * 1000
      Ability.CastPosition(dive, castPos)
    end
  end

  -- 2. Lógica de Cancelamento (padrão: cancela todos os dives se switch estiver ativo)
  if isDiving and AutoCancelDive:Get() then
    local mod = NPC.GetModifier(hero, "modifier_phoenix_icarus_dive")
    if mod then
      local creationTime = Modifier.GetCreationTime(mod)
      local dieTime = Modifier.GetDieTime(mod)
      local duration = dieTime - creationTime
      if duration <= 0 then duration = 2.0 end
      local elapsedTime = GameRules.GetGameTime() - creationTime
      local progress = elapsedTime / duration
      if progress >= 0.5 then
        local stopDive = NPC.GetAbility(hero, "phoenix_icarus_dive_stop")
        if stopDive then Ability.CastNoTarget(stopDive) end
        local spellSlot0 = NPC.GetAbilityByIndex(hero, 0)
        if spellSlot0 and spellSlot0 ~= stopDive then Ability.CastNoTarget(spellSlot0) end
      end
    end
  end
end

return script

