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

-- ============ STATE ============
local tp_particles = {}
local active_teleports = {}
local schedule = {}
local casted_for = {}
local last_cleanup = 0
local preview = nil

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
  
  return math.min(0.98, math.max(0.3, chance))
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
    if not casted_for[tp_id] and not InDanger(me) and 
       ShouldCastAt(tp.dest, Entity.GetTeamNum(me)) and TryCastSS(me, tp.dest) then
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
        if not casted_for[job.tp_id] and not InDanger(me) and 
           ShouldCastAt(job.pos, Entity.GetTeamNum(me)) and TryCastSS(me, job.pos) then
          casted_for[job.tp_id] = true
          log("CAST SCHEDULE ent=%d", job.tp_id)
        end
        table.remove(schedule, i)
      end
    end
  end

  cleanup()

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
  local bestChance = 0.6 -- Mínimo 60% de chance

  for _, enemy in ipairs(Heroes.GetAll()) do
    if enemy ~= me and Entity.IsAlive(enemy) and Entity.GetTeamNum(enemy) ~= myTeam and
       not NPC.IsIllusion(enemy) and Entity.IsVisible(me, enemy) then

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

          if not valid and not ui.auto_ss_stationary:Get() and not ui.auto_ss_stun:Get() then
            valid = true
          end

          if valid then
            local hitChance = CalculateHitChance(enemy, total_delay)
            if hitChance > bestChance then
              bestChance = hitChance
              bestTarget = enemy
            end
          end
        end
      end
    end
  end

  if bestTarget then
    local predictPos = PredictPositionAdvanced(bestTarget, total_delay)
    
    if TryCastSS(me, predictPos) then
      last_auto_ss_cast = now
      auto_ss_target = {hero = bestTarget, pos = predictPos, t = now + total_delay, chance = bestChance}
      log("AUTO SS on %s (chance: %.0f%%)", NPC.GetUnitName(bestTarget) or "?", bestChance * 100)
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
