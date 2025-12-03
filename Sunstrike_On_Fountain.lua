local script = {}

-- Menu
local tab = Menu.Create("Heroes", "Hero List", "Invoker", "Auto Usage", "Sun Strike Settings")
local settings = {}
settings.fountain_strike = tab:Switch("Auto SS na Fonte (Kill)", true, "\u{f015}")
settings.tp_fountain_strike = tab:Switch("Auto SS TP Fonte (Kill)", true, "\u{f0e7}")
settings.tp_anywhere_strike = tab:Switch("Auto SS TP Qualquer Lugar", true, "\u{26a1}")
settings.tp_damage_threshold = tab:Slider("Dano Mínimo TP %", 20, 80, 40, "%d")
settings.min_enemies = tab:Slider("Mín. Inimigos Visíveis", 0, 5, 3, "%d")
settings.auto_invoke = tab:Switch("Auto Invocar SS", true)
settings.debug = tab:Switch("Debug", false)

-- Constantes
local RADIANT_FOUNTAIN = Vector(-7200, -6666, 384)
local DIRE_FOUNTAIN = Vector(6846, 6251, 384)
local FOUNTAIN_RADIUS = 1500

local State = {
  localHero = nil,
  localPlayer = nil,
  exort = nil,
  invoke = nil,
  sunstrike = nil,
  lastExortTap = 0,
  lastInvokeTap = 0,
  hasBeenCastThisGame = false,
  teleportParticles = {},
  activeTeleports = {},
  castedFor = {}
}

local function log(msg)
  if settings.debug:Get() then
    print("[SS Fountain] " .. msg)
  end
end

local function getExortOrbCount()
  if not State.localHero then return 0 end
  local mods = NPC.GetModifiers(State.localHero) or {}
  local count = 0
  for i = 1, #mods do
    if Modifier.GetName(mods[i]) == "modifier_invoker_exort_instance" then
      count = count + 1
      if count == 3 then break end
    end
  end
  return count
end

local function ensureSunstrikeInvoked()
  if not settings.auto_invoke:Get() then
    return State.sunstrike and Ability.IsReady(State.sunstrike)
  end
  
  if not State.exort or not State.invoke then return false end
  
  if State.sunstrike and Ability.IsReady(State.sunstrike) then
    return true
  end
  
  if Ability.GetCooldown(State.invoke) > 0 then return false end
  
  local currentTime = GameRules.GetGameTime()
  
  if getExortOrbCount() < 3 then
    if currentTime - State.lastExortTap >= 0.10 then
      Player.PrepareUnitOrders(State.localPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET, 
        nil, nil, State.exort, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, State.localHero)
      State.lastExortTap = currentTime
    end
    return false
  end
  
  if currentTime - State.lastInvokeTap >= 0.05 then
    Player.PrepareUnitOrders(State.localPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_NO_TARGET, 
      nil, nil, State.invoke, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, State.localHero)
    State.lastInvokeTap = currentTime
  end
  
  return false
end

local function castSunstrikeAt(position, reason)
  if not State.sunstrike or not position then return false end
  
  if Ability.IsReady(State.sunstrike) then
    local castPosition = Vector(position.x, position.y, 0)
    Player.PrepareUnitOrders(State.localPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION, 
      nil, castPosition, State.sunstrike, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, State.localHero)
    log("Cast SS: " .. reason)
    return true
  end
  return false
end

local function isNearFountain(pos, team)
  local fountain = (team == 2) and RADIANT_FOUNTAIN or DIRE_FOUNTAIN
  return (pos - fountain):Length2D() < FOUNTAIN_RADIUS
end

local function countVisibleEnemies()
  if not State.localHero then return 0 end
  local myTeam = Entity.GetTeamNum(State.localHero)
  local count = 0
  
  for _, hero in ipairs(Heroes.GetAll()) do
    if Entity.IsAlive(hero) and Entity.GetTeamNum(hero) ~= myTeam and 
       not NPC.IsIllusion(hero) and Entity.IsVisible(State.localHero, hero) then
      count = count + 1
    end
  end
  
  return count
end

local function calculateSunStrikeDamage(target)
  if not State.sunstrike or not target then return 0 end
  
  local level = Ability.GetLevel(State.sunstrike)
  if level == 0 then return 0 end
  
  local baseDamage = {100, 162.5, 225, 287.5}
  local damage = baseDamage[level] or 0
  
  -- Aplica resistência mágica
  local magicResist = NPC.GetMagicalArmorValue(target)
  damage = damage * (1 - magicResist)
  
  -- Considera amplificação de dano mágico do Invoker
  if State.localHero then
    local spellAmp = NPC.GetSpellAmplification(State.localHero)
    damage = damage * (1 + spellAmp)
  end
  
  return damage
end

local function canKillWithSunStrike(target)
  if not target then return false end
  
  local hp = Entity.GetHealth(target)
  local damage = calculateSunStrikeDamage(target)
  
  return damage >= hp
end

local function willDealSignificantDamage(target)
  if not target then return false end
  
  local hp = Entity.GetHealth(target)
  local maxHp = Entity.GetMaxHealth(target)
  local damage = calculateSunStrikeDamage(target)
  
  local damagePercent = (damage / maxHp) * 100
  local threshold = settings.tp_damage_threshold:Get()
  
  return damagePercent >= threshold
end

-- Detecção de partículas de teleporte
script.OnParticleCreate = function(particle)
  if not settings.tp_fountain_strike:Get() then return end
  if not particle or not particle.fullName then return end
  
  local name = particle.fullName:lower()
  if name:find("teleport_end") or name:find("boots_of_travel") then
    State.teleportParticles[particle.index] = {
      entity = particle.entity,
      created = GameRules.GetGameTime(),
      pos = nil
    }
    log("TP particle detected: " .. particle.index)
  end
end

script.OnParticleUpdate = function(particle)
  if not settings.tp_fountain_strike:Get() then return end
  if not particle or not particle.index then return end
  
  local tpInfo = State.teleportParticles[particle.index]
  if tpInfo and particle.controlPoint == 0 and particle.position then
    tpInfo.pos = particle.position
    
    -- Verifica se o TP é para a fonte inimiga
    if State.localHero then
      local myTeam = Entity.GetTeamNum(State.localHero)
      local enemyTeam = (myTeam == 2) and 3 or 2
      
      if isNearFountain(particle.position, enemyTeam) then
        log("TP to enemy fountain detected!")
        
        -- Agenda o cast do Sun Strike
        local tpEntity = tpInfo.entity
        if tpEntity and not State.castedFor[Entity.GetIndex(tpEntity)] then
          State.activeTeleports[Entity.GetIndex(tpEntity)] = {
            pos = particle.position,
            time = GameRules.GetGameTime()
          }
        end
      end
    end
  end
end

script.OnParticleDestroy = function(particle)
  if particle and particle.index then
    State.teleportParticles[particle.index] = nil
  end
end

-- Detecção de modifier de teleporte
script.OnModifierCreate = function(entity, modifier)
  if not settings.tp_fountain_strike:Get() then return end
  if not entity or not modifier then return end
  if not State.localHero then return end
  
  local modName = Modifier.GetName(modifier)
  if modName ~= "modifier_teleporting" then return end
  
  local myTeam = Entity.GetTeamNum(State.localHero)
  local entityTeam = Entity.GetTeamNum(entity)
  
  -- Apenas inimigos
  if entityTeam == myTeam then return end
  
  local idx = Entity.GetIndex(entity)
  local duration = Modifier.GetRemainingTime(modifier) or 3.0
  
  State.activeTeleports[idx] = {
    entity = entity,
    start = GameRules.GetGameTime(),
    finish = GameRules.GetGameTime() + duration,
    pos = nil
  }
  
  log("Enemy TP started: " .. idx)
end

script.OnModifierDestroy = function(entity, modifier)
  if not entity or not modifier then return end
  local modName = Modifier.GetName(modifier)
  if modName == "modifier_teleporting" then
    local idx = Entity.GetIndex(entity)
    State.activeTeleports[idx] = nil
    State.castedFor[idx] = nil
  end
end

script.OnGameStart = function()
  State.hasBeenCastThisGame = false
  State.localHero = Heroes.GetLocal()
  if not State.localHero then return end
  
  State.localPlayer = Players.GetLocal()
  State.exort = NPC.GetAbility(State.localHero, "invoker_exort")
  State.invoke = NPC.GetAbility(State.localHero, "invoker_invoke")
  State.sunstrike = NPC.GetAbility(State.localHero, "invoker_sun_strike")
  
  if State.exort and Ability.GetLevel(State.exort) == 0 then
    Player.PrepareUnitOrders(State.localPlayer, Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY, 
      nil, nil, State.exort, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, State.localHero)
  end
  
  State.teleportParticles = {}
  State.activeTeleports = {}
  State.castedFor = {}
end

script.OnUpdate = function()
  if not State.localHero or Entity.GetUnitName(State.localHero) ~= "npc_dota_hero_invoker" then
    return
  end
  
  -- Atualiza referências de habilidades
  if not State.sunstrike then
    State.sunstrike = NPC.GetAbility(State.localHero, "invoker_sun_strike")
  end
  
  -- Tenta invocar Sun Strike
  ensureSunstrikeInvoked()
  
  -- Sun Strike na fonte no início do jogo
  if settings.fountain_strike:Get() and not State.hasBeenCastThisGame then
    if GameRules.GetGameTime() < 200 and GameRules.GetGameState() == Enum.GameState.DOTA_GAMERULES_STATE_PRE_GAME then
      local visibleEnemies = countVisibleEnemies()
      if visibleEnemies >= settings.min_enemies:Get() then
        local myTeam = Entity.GetTeamNum(State.localHero)
        local enemyFountainPos = (myTeam == 2) and DIRE_FOUNTAIN or RADIANT_FOUNTAIN
        
        if castSunstrikeAt(enemyFountainPos, "Fountain strike at game start") then
          State.hasBeenCastThisGame = true
        end
      end
    end
  end
  
  -- Sun Strike em TPs
  if settings.tp_fountain_strike:Get() or settings.tp_anywhere_strike:Get() then
    local now = GameRules.GetGameTime()
    local myTeam = Entity.GetTeamNum(State.localHero)
    local enemyFountain = (myTeam == 2) and DIRE_FOUNTAIN or RADIANT_FOUNTAIN
    
    for idx, tpData in pairs(State.activeTeleports) do
      if not State.castedFor[idx] and tpData.entity then
        local delay = 1.7
        local castPoint = 0.05
        local timeToLand = tpData.finish and (tpData.finish - now) or 0
        
        if timeToLand > 0 and timeToLand <= (delay + castPoint + 0.1) then
          local shouldCast = false
          local reason = ""
          
          -- TP para fonte
          if tpData.pos and isNearFountain(tpData.pos, (myTeam == 2) and 3 or 2) then
            if settings.tp_fountain_strike:Get() and canKillWithSunStrike(tpData.entity) then
              shouldCast = true
              reason = "TP to fountain (KILL)"
            end
          -- TP para qualquer lugar
          elseif tpData.pos and settings.tp_anywhere_strike:Get() then
            if canKillWithSunStrike(tpData.entity) then
              shouldCast = true
              reason = "TP anywhere (KILL)"
            elseif willDealSignificantDamage(tpData.entity) then
              shouldCast = true
              local dmgPct = (calculateSunStrikeDamage(tpData.entity) / Entity.GetMaxHealth(tpData.entity)) * 100
              reason = string.format("TP anywhere (%.0f%% damage)", dmgPct)
            end
          end
          
          if shouldCast and castSunstrikeAt(tpData.pos, reason) then
            State.castedFor[idx] = true
          end
        -- Fallback para fonte
        elseif not tpData.pos and tpData.finish and (tpData.finish - now) <= 1.8 then
          if settings.tp_fountain_strike:Get() and canKillWithSunStrike(tpData.entity) then
            if castSunstrikeAt(enemyFountain, "TP to fountain fallback (KILL)") then
              State.castedFor[idx] = true
            end
          end
        end
      end
    end
    
    -- Limpa TPs antigos
    for idx, tpData in pairs(State.activeTeleports) do
      if tpData.time and (now - tpData.time > 10) then
        State.activeTeleports[idx] = nil
        State.castedFor[idx] = nil
      end
    end
  end
end

script.OnGameEnd = function()
  State.hasBeenCastThisGame = false
  State.teleportParticles = {}
  State.activeTeleports = {}
  State.castedFor = {}
end

return script
