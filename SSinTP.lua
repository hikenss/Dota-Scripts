---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
-- Invoker: Sun Strike AI Enhanced

local M = {}

-- ============ MENU ============
local ui = {}
do
  local ok, auto = pcall(Menu.Find, "Heroes", "Hero List", "Invoker", "Auto Usage", "Sun Strike Settings", "Auto Use")
  ui.auto_hook = ok and auto or nil

  local tab = Menu.Create("Heroes", "Hero List", "Invoker", "Auto Usage")
  local g = tab:Create("Sun Strike TP Snipe")

  ui.enable_fallback = g:Switch("Ativar", true, "\u{f0e7}")
  ui.only_enemy_tp = g:Switch("Apenas TPs Inimigos", true)
  ui.auto_invoke = g:Switch("Auto Invocar SS", false)
  ui.min_mana = g:Slider("Mana Mínima %", 0, 100, 10, "%d")
  ui.cast_safety_ms = g:Slider("Margem Segurança (ms)", 0, 300, 50, "%d")
  ui.net_ping = g:Slider("Ping (ms)", 0, 250, 40, "%d")
  ui.danger_range = g:Slider("Cancelar se Inimigos <", 0, 1200, 700, "%d")
  ui.draw_preview = g:Switch("Desenhar Prévia", true, "\u{f5b0}")
  ui.debug = g:Switch("Debug", false)

  -- Opções de Fonte/TP (fundindo Sunstrike_On_Fountain)
  local gF = tab:Create("Fonte/TP")
  ui.fountain_strike = gF:Switch("Auto SS na Fonte (início)", true, "\u{f015}")
  ui.tp_fountain_strike = gF:Switch("SS em TP na Fonte (KILL)", true, "\u{f0e7}")
  ui.tp_anywhere_strike = gF:Switch("SS em TP em qualquer lugar", true, "\u{26a1}")
  ui.tp_damage_threshold = gF:Slider("Mín. Dano em TP %", 10, 80, 30, "%d")
  ui.min_visible_enemies = gF:Slider("Mín. Inimigos visíveis (início)", 0, 5, 2, "%d")

  local g2 = tab:Create("Auto Sun Strike IA")
  ui.auto_ss_enabled = g2:Switch("Ativar Auto SS IA", false, "\u{2600}")
  ui.ai_prediction = g2:Switch("Predição Avançada", true)
  ui.ai_pattern_learning = g2:Switch("Aprendizado de Padrões", true)
  ui.ai_dodge_detection = g2:Switch("Detectar Tentativa de Desvio", true)
  ui.auto_ss_channeling = g2:Switch("Alvo Canalizando", true)
  ui.auto_ss_stun = g2:Switch("Alvo Atordoado/Enraizado", true)
  ui.auto_ss_stationary = g2:Switch("Alvo Parado", true)
  ui.auto_ss_min_hp = g2:Slider("HP Mínimo %", 0, 100, 15, "%d")
  ui.auto_ss_max_hp = g2:Slider("HP Máximo %", 0, 100, 85, "%d")
  ui.auto_ss_cooldown = g2:Slider("Intervalo (s)", 0, 10, 2, "%d")
  ui.auto_ss_range = g2:Slider("Alcance Máximo", 500, 5000, 2500, "%d")
  ui.auto_ss_draw = g2:Switch("Desenhar Indicador", true, "\u{f192}")
  ui.min_hit_chance = g2:Slider("Chance mínima %", 20, 95, 35, "%d")
  ui.aggressive_mode = g2:Switch("Modo Agressivo (arriscar mais)", true)
  ui.ignore_danger = g2:Switch("Ignorar perigo próximo", false)
end

-- ============ HELPERS ============
local function log(fmt, ...)
  if ui.debug and ui.debug:Get() then
    print(("[SS-IA] " .. fmt):format(...))
  end
end

local function AutoUseEnabled()
  if ui.auto_hook and ui.auto_hook:Get() then return true end
  if (not ui.auto_hook) and ui.enable_fallback and ui.enable_fallback:Get() then return true end
  return false
end

local function IsInvoker(me)
  return me and NPC.GetUnitName(me) == "npc_dota_hero_invoker"
end

local function GetSunStrike(me)
  return NPC.GetAbility(me, "invoker_sun_strike")
end

local function AbilityDelaySeconds(ss)
  return Ability.GetLevelSpecialValueFor(ss, "delay") or 1.7
end

local function CastPoint(ss)
  return Ability.GetCastPoint(ss) or 0.05
end

local function ManaOK(me)
  if not ui.min_mana then return true end
  local need = ui.min_mana:Get() / 100.0
  if need <= 0 then return true end
  local mana = Entity.GetMana(me)
  local maxm = Entity.GetMaxMana(me)
  return mana >= maxm * need
end

local function CanExecute(ability)
  return ability and Ability.CanBeExecuted(ability) == -1
end

local function TryCastSS(me, pos)
  if not me or not pos then return false end
  local ss = GetSunStrike(me)
  if not ss or not ManaOK(me) or not CanExecute(ss) then return false end
  Ability.CastPosition(ss, pos)
  return true
end

local function EnsureSunStrikeInvoked(me)
  if not ui.auto_invoke:Get() then return GetSunStrike(me) end
  local ss = GetSunStrike(me)
  if ss and CanExecute(ss) then return ss end
  local invoke = NPC.GetAbility(me, "invoker_invoke")
  if invoke and CanExecute(invoke) then
    Ability.CastNoTarget(invoke)
  end
  return GetSunStrike(me)
end

local function safety_total()
  return (ui.cast_safety_ms:Get() / 1000.0) + (ui.net_ping:Get() / 1000.0)
end

local function InDanger(me)
  local r = ui.danger_range:Get()
  if r <= 0 then return false end
  if ui.ignore_danger and ui.ignore_danger:Get() then return false end
  local myTeam = Entity.GetTeamNum(me)
  local myPos = Entity.GetAbsOrigin(me)
  for _, h in ipairs(Heroes.GetAll()) do
    if h ~= me and Entity.IsAlive(h) and Entity.GetTeamNum(h) ~= myTeam and not NPC.IsIllusion(h) then
      if (Entity.GetAbsOrigin(h) - myPos):Length2D() <= r then
        return true
      end
    end
  end
  return false
end

local function ShouldCastAt(pos, myTeam)
  if not pos then return false end
  for _, h in ipairs(Heroes.GetAll()) do
    if Entity.IsAlive(h) and Entity.GetTeamNum(h) ~= myTeam and not NPC.IsIllusion(h) then
      if (Entity.GetAbsOrigin(h) - pos):Length2D() <= 450 then
        return true
      end
    end
  end
  for _, u in ipairs(NPCs.GetAll()) do
    if Entity.IsAlive(u) and Entity.GetTeamNum(u) ~= myTeam and NPC.IsStructure(u) then
      if (Entity.GetAbsOrigin(u) - pos):Length2D() <= 500 then
        return true
      end
    end
  end
  return false
end

local function SnapToNearestUnit(pos, team)
  if not pos then return nil end
  local best, bestD = nil, 1200
  for _, u in ipairs(NPCs.GetAll()) do
    if Entity.IsAlive(u) and Entity.GetTeamNum(u) == team then
      local d = (Entity.GetAbsOrigin(u) - pos):Length2D()
      if d < bestD then best, bestD = u, d end
    end
  end
  return best and Entity.GetAbsOrigin(best) or pos
end

local function drawCircleSafe(pos, radius, color)
  if _G.Debug and Debug.DrawCircle then
    Debug.DrawCircle(pos, radius, color)
  end
end

-- ========= DANO/KILL =========
local function calculateSunStrikeDamage(me, ss, target)
  if not ss or not target then return 0 end
  local level = Ability.GetLevel(ss)
  if level == 0 then return 0 end
  local baseDamage = {100, 162.5, 225, 287.5}
  local damage = baseDamage[level] or 0
  local magicResist = NPC.GetMagicalArmorValue(target)
  damage = damage * (1 - (magicResist or 0))
  if me then
    local spellAmp = NPC.GetSpellAmplification(me) or 0
    damage = damage * (1 + spellAmp)
  end
  return damage
end

local function canKillWithSunStrike(me, ss, target)
  if not target then return false end
  local hp = Entity.GetHealth(target) or 0
  local dmg = calculateSunStrikeDamage(me, ss, target)
  return dmg >= hp and hp > 0
end

local function willDealSignificantDamage(me, ss, target, thresholdPct)
  if not target then return false end
  local maxHp = Entity.GetMaxHealth(target) or 1
  local dmg = calculateSunStrikeDamage(me, ss, target)
  local pct = (dmg / maxHp) * 100
  return pct >= (thresholdPct or ui.tp_damage_threshold:Get())
end

-- ========= FILTROS DE ALVO =========
local INVULN_MODS = {
  "modifier_eul_cyclone",
  "modifier_obsidian_destroyer_astral_imprisonment_prison",
  "modifier_shadow_demon_disruption",
  "modifier_puck_phase_shift",
  "modifier_invulnerable"
}
local PROTECT_MODS = {
  "modifier_dazzle_shallow_grave",
  "modifier_oracle_false_promise"
}

local SAFE_WINDOW_MODS = {
  {mod = "modifier_eul_cyclone", skill = "Euls", duration = 2.5},
  {mod = "modifier_obsidian_destroyer_astral_imprisonment_prison", skill = "Astral", duration = 4.0},
  {mod = "modifier_shadow_demon_disruption", skill = "Disruption", duration = 2.5},
  {mod = "modifier_puck_phase_shift", skill = "Phase Shift", duration = 1.25},
  {mod = "modifier_wind_waker_cyclone", skill = "Wind Waker", duration = 2.5}
}

local function HasAnyModifier(unit, names)
  local mods = NPC.GetModifiers(unit)
  if not mods then return false end
  for i = 1, #mods do
    local n = Modifier.GetName(mods[i])
    if n then
      for _, m in ipairs(names) do
        if n == m then return true end
      end
    end
  end
  return false
end

local function IsMagicImmune(unit)
  if NPC.HasState then
    return NPC.HasState(unit, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE)
  end
  return false
end

local function IsUnhittable(unit)
  return IsMagicImmune(unit) or HasAnyModifier(unit, INVULN_MODS)
end

local function IsProtectedFromDeath(unit)
  return HasAnyModifier(unit, PROTECT_MODS)
end

local function GetActiveImmunityModifier(unit)
  if not unit then return nil, 0 end
  local mods = NPC.GetModifiers(unit)
  if not mods then return nil, 0 end
  for i = 1, #mods do
    local m = mods[i]
    local mod_name = Modifier.GetName(m)
    for _, sw in ipairs(SAFE_WINDOW_MODS) do
      if mod_name == sw.mod then
        return sw, Modifier.GetRemainingTime(m) or 0
      end
    end
  end
  return nil, 0
end

-- ============ STATE ============
local tp_particles = {}
local active_teleports = {}
local schedule = {}
local casted_for = {}
local last_cleanup = 0
local preview = nil
local has_cast_fountain_start = false

-- Adaptativo
local adaptive_results = {}
local adaptive_bias = 0 -- negativo = mais conservador; positivo = mais agressivo
local pending_ss = {} -- {t, pos, targets={entityIdx,...}}


-- IA: Rastreamento de movimento
local enemy_movement_history = {} -- [entity_index] = {positions = {}, times = {}, velocities = {}}
local last_auto_ss_cast = 0
local auto_ss_target = nil

local TELEPORT_END_HINTS = {
  "particles/items2_fx/teleport_end",
  "particles/items3_fx/boots_of_travel",
  "teleport_end",
}

local function isTeleportEnd(name)
  if not name or type(name) ~= "string" then return false end
  local s = name:lower()
  for _, h in ipairs(TELEPORT_END_HINTS) do
    if s:find(h, 1, true) then return true end
  end
  return false
end

local FOUNTAIN = {
  [2] = Vector(-7200, -6666, 384),
  [3] = Vector(7200, 6666, 384),
}

local function isNearFountain(pos, team)
  if not pos or not team then return false end
  local f = FOUNTAIN[team]
  if not f then return false end
  return (pos - f):Length2D() < 1600
end

-- ============ IA AVANÇADA ============

-- Atualiza histórico de movimento
local function UpdateMovementHistory(enemy)
  local idx = Entity.GetIndex(enemy)
  local now = GameRules.GetGameTime()
  local pos = Entity.GetAbsOrigin(enemy)
  
  if not enemy_movement_history[idx] then
    enemy_movement_history[idx] = {positions = {}, times = {}, velocities = {}}
  end
  
  local history = enemy_movement_history[idx]
  table.insert(history.positions, pos)
  table.insert(history.times, now)
  
  if #history.positions > 10 then
    table.remove(history.positions, 1)
    table.remove(history.times, 1)
  end
  
  if #history.positions >= 2 then
    local lastPos = history.positions[#history.positions - 1]
    local lastTime = history.times[#history.times - 1]
    local vel = (pos - lastPos) / (now - lastTime)
    table.insert(history.velocities, vel)
    if #history.velocities > 5 then
      table.remove(history.velocities, 1)
    end
  end
end

-- Detecta mudança brusca de direção (tentativa de dodge)
local function DetectDodgeAttempt(enemy)
  if not ui.ai_dodge_detection:Get() then return false end
  
  local idx = Entity.GetIndex(enemy)
  local history = enemy_movement_history[idx]
  if not history or #history.velocities < 3 then return false end
  
  local recent = history.velocities
  local v1 = recent[#recent - 2]
  local v2 = recent[#recent - 1]
  local v3 = recent[#recent]
  
  local angle1 = math.atan2(v1.y, v1.x)
  local angle2 = math.atan2(v2.y, v2.x)
  local angle3 = math.atan2(v3.y, v3.x)
  
  local diff1 = math.abs(angle2 - angle1)
  local diff2 = math.abs(angle3 - angle2)
  
  -- Mudança brusca de direção > 45 graus
  return (diff1 > 0.785 or diff2 > 0.785)
end

-- Predição avançada com aceleração e padrões
local function PredictPositionAdvanced(enemy, delay)
  local pos = Entity.GetAbsOrigin(enemy)
  local vel = Entity.GetVelocity(enemy)
  local speed = vel:Length2D()
  
  if speed < 50 then return pos end
  
  if not ui.ai_prediction:Get() then
    return pos + vel:Normalized():Scaled(speed * delay)
  end
  
  local idx = Entity.GetIndex(enemy)
  local history = enemy_movement_history[idx]
  
  if not history or #history.velocities < 2 then
    return pos + vel:Normalized():Scaled(speed * delay)
  end
  
  -- Calcula aceleração média
  local accel = Vector(0, 0, 0)
  for i = 2, #history.velocities do
    local dt = history.times[i] - history.times[i-1]
    if dt > 0 then
      accel = accel + (history.velocities[i] - history.velocities[i-1]) / dt
    end
  end
  accel = accel / (#history.velocities - 1)
  
  -- Predição com aceleração
  local predictedVel = vel + accel:Scaled(delay * 0.5)
  local avgSpeed = (speed + predictedVel:Length2D()) / 2
  
  -- Detecta padrão de movimento (zigzag, circular, etc)
  if ui.ai_pattern_learning:Get() and #history.positions >= 5 then
    local isZigzag = DetectDodgeAttempt(enemy)
    if isZigzag then
      -- Compensa zigzag prevendo posição central
      local avgPos = Vector(0, 0, 0)
      for i = math.max(1, #history.positions - 3), #history.positions do
        avgPos = avgPos + history.positions[i]
      end
      avgPos = avgPos / math.min(4, #history.positions)
      local dirToAvg = (avgPos - pos):Normalized()
      return pos + dirToAvg:Scaled(avgSpeed * delay * 0.7)
    end
  end
  
  return pos + predictedVel:Normalized():Scaled(avgSpeed * delay)
end

-- Calcula chance de acerto baseado em condições
local BLINK_ITEMS = {"item_blink","item_overwhelming_blink","item_swift_blink","item_arcane_blink"}
local PUSH_ITEMS = {"item_force_staff","item_hurricane_pike"}

local function HasReadyItem(unit, name)\n  local it = NPC.GetItem(unit, name, true)
  if not it then return false end
  return Ability.IsCastable(it, NPC.GetMana(unit))
end

local function HasInstantEscape(unit)
  for _, n in ipairs(BLINK_ITEMS) do if HasReadyItem(unit, n) then return true end end
  return false
end

local function HasPushEscape(unit)
  for _, n in ipairs(PUSH_ITEMS) do if HasReadyItem(unit, n) then return true end end
  return false
end

local function CalculateHitChance(enemy, delay)
  local chance = 0.5 -- Base 50%
  
  -- Parado = 95%
  local vel = Entity.GetVelocity(enemy)
  if vel:Length2D() < 50 then
    chance = 0.95
  end
  
  -- Atordoado/Enraizado = 98%
  if NPC.IsStunned(enemy) or NPC.IsRooted(enemy) then
    chance = 0.98
  end
  
  -- Canalizando = 97%
  if NPC.IsChannellingAbility(enemy) then
    chance = 0.97
  end
  
  -- Movimento previsível aumenta chance
  local idx = Entity.GetIndex(enemy)
  local history = enemy_movement_history[idx]
  if history and #history.velocities >= 3 then
    local consistent = true
    local baseAngle = math.atan2(history.velocities[1].y, history.velocities[1].x)
    for i = 2, #history.velocities do
      local angle = math.atan2(history.velocities[i].y, history.velocities[i].x)
      if math.abs(angle - baseAngle) > 0.3 then
        consistent = false
        break
      end
    end
    if consistent then
      chance = chance + 0.2
    end
  end
  
  -- Tentativa de dodge diminui chance
  if DetectDodgeAttempt(enemy) then
    chance = chance - 0.15
  end

  -- Itens de fuga reduzem chance
  if HasInstantEscape(enemy) then chance = chance - 0.15 end
  if HasPushEscape(enemy) then chance = chance - 0.08 end
  
  return math.min(0.98, math.max(0.2, chance))
end

-- ========= CLUSTERING =========
local function FindBestCluster(me, ss, total_delay, maxRange)
  local myTeam = Entity.GetTeamNum(me)
  local myPos = Entity.GetAbsOrigin(me)
  local candidates = {}
  for _, enemy in ipairs(Heroes.GetAll()) do
    if enemy ~= me and Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= myTeam and not NPC.IsIllusion(enemy) and Entity.IsVisible(me, enemy) and not IsUnhittable(enemy) then
      local enemyPos = Entity.GetAbsOrigin(enemy)
      if (enemyPos - myPos):Length2D() <= maxRange then
        UpdateMovementHistory(enemy)
        table.insert(candidates, {unit = enemy, pos = PredictPositionAdvanced(enemy, total_delay)})
      end
    end
  end
  local best = {count = 0, center = nil, targets = nil}
  for i = 1, #candidates do
    local seed = candidates[i]
    local group = {seed.unit}
    local sum = seed.pos
    for j = 1, #candidates do
      if i ~= j then
        local other = candidates[j]
        if (other.pos - seed.pos):Length2D() <= 175 then
          table.insert(group, other.unit)
          sum = sum + other.pos
        end
      end
    end
    if #group > best.count then
      best.count = #group
      best.center = sum / #group
      best.targets = group
    end
  end
  if best.count >= 2 then return best end
  return nil
end

-- ============ PARTICLES ============
function M.OnParticleCreate(p)
  if not AutoUseEnabled() or not p or not p.fullName then return end
  if not isTeleportEnd(p.fullName) then return end
  tp_particles[p.index] = {
    pos = nil,
    created = GameRules.GetGameTime(),
    alive = true,
    team = p.entity and Entity.GetTeamNum(p.entity) or nil,
  }
  log("ParticleCreate idx=%d", p.index or -1)
end

function M.OnParticleUpdate(p)
  if not AutoUseEnabled() or not p or not p.index then return end
  local info = tp_particles[p.index]
  if not info then return end
  if p.controlPoint == 0 and p.position then
    info.pos = p.position
    if info.bound_teleport_id then
      local tp = active_teleports[info.bound_teleport_id]
      if tp then tp.dest = p.position end
    end
  end
end

function M.OnParticleDestroy(p)
  if not p or not p.index then return end
  local info = tp_particles[p.index]
  if info then info.alive = false end
end

-- ============ MODIFIERS ============
function M.OnModifierCreate(ent, mod)
  if not AutoUseEnabled() or not ent or not mod then return end
  local me = Heroes.GetLocal()
  if not me then return end

  local name = Modifier.GetName(mod) or ""
  if name ~= "modifier_teleporting" then return end

  if ui.only_enemy_tp and Entity.GetTeamNum(ent) == Entity.GetTeamNum(me) then
    return
  end

  local id = Entity.GetIndex(ent)
  local now = GameRules.GetGameTime()
  local rem = Modifier.GetRemainingTime(mod) or Modifier.GetDuration(mod) or 3.0
  local team = Entity.GetTeamNum(ent)

  active_teleports[id] = {
    start = now,
    finish = now + math.max(0.1, rem),
    team = team,
    dest = nil,
    entity = ent,
    particle = nil,
  }
  log("TP start ent=%d rem=%.2f", id, rem)

  local bestIdx, bestInfo = nil, nil
  for idx, info in pairs(tp_particles) do
    if info.alive and info.pos then
      local age = now - info.created
      if age >= 0 and age <= 0.6 then
        bestIdx, bestInfo = idx, info
        break
      end
    end
  end

  if bestInfo then
    active_teleports[id].dest = bestInfo.pos
    active_teleports[id].particle = bestIdx
    bestInfo.bound_teleport_id = id
  else
    active_teleports[id].dest = FOUNTAIN[team]
  end
end

function M.OnModifierDestroy(ent, mod)
  if not ent or not mod then return end
  local name = Modifier.GetName(mod) or ""
  if name ~= "modifier_teleporting" then return end
  local id = Entity.GetIndex(ent)
  active_teleports[id] = nil
  casted_for[id] = nil
  log("TP cancel ent=%d", id)
end

-- ============ SCHEDULER / CAST ============
local function plan_cast(me, ss, tp_id, tp)
  if not tp or not tp.dest then return false end

  tp.dest = SnapToNearestUnit(tp.dest, tp.team)

  local delay = AbilityDelaySeconds(ss)
  local cpoint = CastPoint(ss)
  local t_cast = tp.finish - delay - cpoint - safety_total()
  local now = GameRules.GetGameTime()

  if ui.draw_preview:Get() then
    preview = {pos = tp.dest, t = t_cast}
  end

  if t_cast <= now then
    local myTeam = Entity.GetTeamNum(me)
    local enemyTeam = (myTeam == 2) and 3 or 2
    local okToCast = not casted_for[tp_id] and not InDanger(me) and ShouldCastAt(tp.dest, myTeam)

    if okToCast and tp.entity then
      if IsUnhittable(tp.entity) then okToCast = false end
      local nearEnemyFountain = isNearFountain(tp.dest, enemyTeam)
      if nearEnemyFountain and ui.tp_fountain_strike:Get() then
        local lethal = (not IsProtectedFromDeath(tp.entity)) and canKillWithSunStrike(me, ss, tp.entity)
        okToCast = lethal or willDealSignificantDamage(me, ss, tp.entity, ui.tp_damage_threshold:Get())
      elseif ui.tp_anywhere_strike:Get() then
        local lethal = (not IsProtectedFromDeath(tp.entity)) and canKillWithSunStrike(me, ss, tp.entity)
        okToCast = lethal or willDealSignificantDamage(me, ss, tp.entity, ui.tp_damage_threshold:Get())
      end
    end

    if okToCast and TryCastSS(me, tp.dest) then
      casted_for[tp_id] = true
      log("CAST NOW ent=%d", tp_id)
    end
    return true
  else
    table.insert(schedule, {time = t_cast, pos = tp.dest, tp_id = tp_id})
    log("Schedule ent=%d at %.2f", tp_id, t_cast)
    return false
  end
end

local function cleanup()
  local now = GameRules.GetGameTime()
  if now - last_cleanup < 1.0 then return end
  last_cleanup = now

  for idx, info in pairs(tp_particles) do
    if (not info.alive) or (now - info.created > 4.0) then
      tp_particles[idx] = nil
    end
  end
  for id, tp in pairs(active_teleports) do
    if now - tp.start > 7.0 then
      active_teleports[id] = nil
      casted_for[id] = nil
    end
  end
  
  -- Limpa histórico antigo
  for idx, history in pairs(enemy_movement_history) do
    if #history.times > 0 and now - history.times[#history.times] > 10 then
      enemy_movement_history[idx] = nil
    end
  end

  for idx, track_info in pairs(immunity_exit_tracking) do
    if not track_info.enemy or not Entity.IsAlive(track_info.enemy) or (now - track_info.exit_time > 1) then
      immunity_exit_tracking[idx] = nil
    end
  end
end

function M.OnUpdate()
  if not AutoUseEnabled() then return end

  local me = Heroes.GetLocal()
  if not IsInvoker(me) then return end

  local ss = EnsureSunStrikeInvoked(me)
  if not ss then return end

  for id, tp in pairs(active_teleports) do
    if tp.dest and not casted_for[id] then
      local planned = plan_cast(me, ss, id, tp)
      active_teleports[id].dest = nil
      if planned then
        active_teleports[id] = nil
      end
    end
  end

  if #schedule > 0 then
    local now = GameRules.GetGameTime()
    for i = #schedule, 1, -1 do
      local job = schedule[i]
      if job.time <= now then
        local okToCast = not casted_for[job.tp_id] and not InDanger(me) and ShouldCastAt(job.pos, Entity.GetTeamNum(me))

        local tp = active_teleports[job.tp_id]
        if tp and tp.entity then
          if IsUnhittable(tp.entity) then okToCast = false end
          if ui.tp_fountain_strike:Get() or ui.tp_anywhere_strike:Get() then
            local lethal = (not IsProtectedFromDeath(tp.entity)) and canKillWithSunStrike(me, ss, tp.entity)
            okToCast = okToCast and (lethal or willDealSignificantDamage(me, ss, tp.entity, ui.tp_damage_threshold:Get()))
          end
        end

        if okToCast and TryCastSS(me, job.pos) then
          casted_for[job.tp_id] = true
          log("CAST SCHEDULE ent=%d", job.tp_id)
        end
        table.remove(schedule, i)
      end
    end
  end

  -- Avaliação adaptativa de acertos
  do
    local now = GameRules.GetGameTime()
    for i = #pending_ss, 1, -1 do
      local p = pending_ss[i]
      if now >= p.t then
        local hit = false
        for _, id in ipairs(p.targets or {}) do
          local unit = Entity.GetEntity(id)
          if unit and Entity.IsAlive(unit) and not IsUnhittable(unit) then
            local upos = Entity.GetAbsOrigin(unit)
            if (upos - p.pos):Length2D() <= 190 then
              hit = true; break
            end
          end
        end
        table.remove(pending_ss, i)
        table.insert(adaptive_results, hit and 1 or -1)
        if #adaptive_results > 8 then table.remove(adaptive_results, 1) end
        local sum = 0; for _,v in ipairs(adaptive_results) do sum = sum + v end
        adaptive_bias = math.max(-3, math.min(3, sum))
      end
    end
  end

  cleanup()

  -- SS na fonte no início do jogo
  if ui.fountain_strike:Get() and not has_cast_fountain_start then
    local t = GameRules.GetGameTime()
    if t < 200 then
      local visible = 0
      local myTeam = Entity.GetTeamNum(me)
      for _, hero in ipairs(Heroes.GetAll()) do
        if hero ~= me and Entity.IsAlive(hero) and Entity.GetTeamNum(hero) ~= myTeam and not NPC.IsIllusion(hero) and Entity.IsVisible(me, hero) then
          visible = visible + 1
        end
      end
      if visible >= ui.min_visible_enemies:Get() then
        local enemyTeam = (myTeam == 2) and 3 or 2
        local enemyFountain = FOUNTAIN[enemyTeam]
        if TryCastSS(me, enemyFountain) then
          has_cast_fountain_start = true
          log("Fountain strike at game start")
        end
      end
    end
  end

  if ui.auto_ss_enabled:Get() then
    AutoSunStrikeEnemies(me, ss)
  end
end

-- ============ AUTO SUN STRIKE IA ============
function AutoSunStrikeEnemies(me, ss)
  if not me or not ss or InDanger(me) or not ManaOK(me) then return end

  local now = GameRules.GetGameTime()
  if now - last_auto_ss_cast < ui.auto_ss_cooldown:Get() then return end

  local myTeam = Entity.GetTeamNum(me)
  local myPos = Entity.GetAbsOrigin(me)
  local maxRange = ui.auto_ss_range:Get()
  local minHP = ui.auto_ss_min_hp:Get() / 100.0
  local maxHP = ui.auto_ss_max_hp:Get() / 100.0

  local delay = AbilityDelaySeconds(ss)
  local cpoint = CastPoint(ss)
  local total_delay = delay + cpoint + safety_total()

  local bestTarget = nil
  local baseMin = (ui.min_hit_chance:Get() / 100.0)
  local adjMin = math.max(0.2, math.min(0.9, baseMin - 0.05 * adaptive_bias))
  local bestChance = adjMin

  for _, enemy in ipairs(Heroes.GetAll()) do
    if enemy ~= me and Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= myTeam and
       not NPC.IsIllusion(enemy) and Entity.IsVisible(me, enemy) then

      local swMod, remainingTime = GetActiveImmunityModifier(enemy)
      if swMod then
        local exitTime = now + remainingTime
        local idx = Entity.GetIndex(enemy)
        if remainingTime > 0 then
          immunity_exit_tracking[idx] = {exit_time = exitTime, skill = swMod.skill, enemy = enemy}
          log("Safe window tracked: %s from %s (exits at %.2f)", NPC.GetUnitName(enemy) or "?", swMod.skill, exitTime)
        end
      end

      UpdateMovementHistory(enemy)

      local enemyPos = Entity.GetAbsOrigin(enemy)
      local dist = (enemyPos - myPos):Length2D()

      if dist <= maxRange then
        local hp = Entity.GetHealth(enemy)
        local maxhp = Entity.GetMaxHealth(enemy)
        local hpPct = hp / maxhp

        if hpPct >= minHP and hpPct <= maxHP then
          local valid = false

          if ui.auto_ss_channeling:Get() and NPC.IsChannellingAbility(enemy) then
            valid = true
          end

          if not valid and ui.auto_ss_stun:Get() and (NPC.IsStunned(enemy) or NPC.IsRooted(enemy)) then
            valid = true
          end

          if not valid and ui.auto_ss_stationary:Get() then
            local vel = Entity.GetVelocity(enemy)
            if vel:Length2D() < 50 then
              valid = true
            end
          end

          if not valid and (ui.aggressive_mode:Get()) then
            valid = true
          end

          if valid and not IsUnhittable(enemy) then
            local hitChance = CalculateHitChance(enemy, total_delay)
            if ui.aggressive_mode:Get() then
              hitChance = math.max(hitChance - 0.08, 0.3) -- arriscar um pouco mais
            end
            if hitChance > bestChance then
              bestChance = hitChance
              bestTarget = enemy
            end
          end
        end
      end
    end
  end

  -- Cluster: tenta acertar 2+ alvos próximos
  local cluster = FindBestCluster(me, ss, total_delay, maxRange)
  if cluster and ui.aggressive_mode:Get() then
    if TryCastSS(me, cluster.center) then
      last_auto_ss_cast = now
      auto_ss_target = {hero = cluster.targets[1], pos = cluster.center, t = now + total_delay, chance = bestChance}
      local ids = {}
      for _, u in ipairs(cluster.targets) do table.insert(ids, Entity.GetIndex(u)) end
      table.insert(pending_ss, {t = now + total_delay, pos = cluster.center, targets = ids})
      log("AUTO SS cluster x%d", cluster.count)
      return
    end
  end

  if bestTarget then
    local predictPos = PredictPositionAdvanced(bestTarget, total_delay)
    if not IsUnhittable(bestTarget) and TryCastSS(me, predictPos) then
      last_auto_ss_cast = now
      auto_ss_target = {hero = bestTarget, pos = predictPos, t = now + total_delay, chance = bestChance}
      table.insert(pending_ss, {t = now + total_delay, pos = predictPos, targets = {Entity.GetIndex(bestTarget)}})
      log("AUTO SS on %s (chance: %.0f%%)", NPC.GetUnitName(bestTarget) or "?", bestChance * 100)
    end
  end

  -- Safe window exit handler: schedule SS para quando sair de invulnerabilidade
  do
    for idx, track_info in pairs(immunity_exit_tracking) do
      if track_info.enemy and Entity.IsAlive(track_info.enemy) then
        local rem = track_info.exit_time - now
        if rem > 0.1 and rem <= (delay + cpoint + 0.05) then
          local enemy = track_info.enemy
          local predictedPos = PredictPositionAdvanced(enemy, rem + 0.05)
          if ManaOK(me) and CanExecute(ss) and not InDanger(me) and not IsUnhittable(enemy) then
            if TryCastSS(me, predictedPos) then
              last_auto_ss_cast = now
              log("Safe window exit SS (%s) on %s", track_info.skill, NPC.GetUnitName(enemy) or "?")
              immunity_exit_tracking[idx] = nil
            end
          end
        elseif rem <= 0 then
          immunity_exit_tracking[idx] = nil
        end
      else
        immunity_exit_tracking[idx] = nil
      end
    end
  end
end

function M.OnDraw()
  if ui.draw_preview:Get() and preview and preview.pos then
    local now = GameRules.GetGameTime()
    local remain = preview.t - now

    if remain >= -0.3 then
      drawCircleSafe(preview.pos, 175, Color(255, 180, 30, 120))

      local font = Render.LoadFont("Tahoma", 0, 700)
      local scr = Screen.WorldToScreen(preview.pos)
      if font and scr then
        Render.Text(font, 14, ("SS in %.2fs"):format(math.max(0, remain)),
                    scr + Vec2(0, -20), Color(255, 220, 120, 255))
      end
    else
      preview = nil
    end
  end

  if ui.auto_ss_draw:Get() and auto_ss_target and auto_ss_target.pos then
    local now = GameRules.GetGameTime()
    local remain = auto_ss_target.t - now

    if remain >= -0.3 and Entity.IsAlive(auto_ss_target.hero) then
      drawCircleSafe(auto_ss_target.pos, 175, Color(255, 50, 50, 150))

      local font = Render.LoadFont("Tahoma", 0, 700)
      local scr = Screen.WorldToScreen(auto_ss_target.pos)
      if font and scr then
        local chanceText = string.format("AUTO SS %.1fs (%.0f%%)", 
                                        math.max(0, remain), 
                                        (auto_ss_target.chance or 0.5) * 100)
        Render.Text(font, 14, chanceText, scr + Vec2(0, -40), Color(255, 100, 100, 255))
      end
    else
      auto_ss_target = nil
    end
  end
end

return M
