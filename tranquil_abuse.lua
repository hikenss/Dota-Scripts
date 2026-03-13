local script = {}

local root = Menu.Create("General", "Main", "Tranquil Abuse")
root:Icon("\u{f782}")
local rootMenu = root:Create("Principal")

local generalGroup = rootMenu:Create("Geral")
local Toggle = generalGroup:Switch("Ativar", true, "\u{f205}")
local AbuseWhenOnCooldown = generalGroup:Switch("Usar Com Bota em Cooldown", false, "\u{f078}")
local DisableAfterToggle = generalGroup:Switch("Desativar Após", true, "\u{f078}")
local DisableAfter = generalGroup:Slider("Desativar Após", 5, 50, 10, "%d min")
local IgnoreRadius = generalGroup:Slider("Ignorar Raio de Inimigos", 100, 800, 150, "%d")
local BlockOrders = generalGroup:Switch("Bloquear Comandos Durante Ciclo", false, "\u{f078}")

local realGroup = rootMenu:Create("Antecipação em Tempo Real")
local RealTimeLead = realGroup:Switch("Ativar Antecipação em Tempo Real", true, "\u{f017}")
local RTTravelPercent = realGroup:Slider("% Tempo de Viagem", 5, 60, 25, "%d%%")
local RTMinLead = realGroup:Slider("Antecipação Mínima", 20, 350, 60, "%d ms")
local RTMaxLead = realGroup:Slider("Antecipação Máxima", 80, 650, 650, "%d ms")
local RTMultiExtra = realGroup:Slider("Extra por Projétil", 0, 200, 30, "%d ms")
local RTPingScale = realGroup:Slider("Escala de Ping %", 0, 150, 60, "%d%%")

local manualGroup = rootMenu:Create("Antecipação Manual")
local BaseDropLead = manualGroup:Slider("Antecipação Base para Drop", 50, 400, 120, "%d ms")
local PingCompensation = manualGroup:Switch("Compensação de Ping", true, "\u{f078}")

local safetyGroup = rootMenu:Create("Segurança e Coleta")
local PickupBuffer = safetyGroup:Slider("Buffer de Segurança para Pegar", 50, 700, 150, "%d ms")
local ProjectileGrouping = safetyGroup:Slider("Janela de Agrupamento de Projéteis", 40, 300, 170, "%d ms")

local advGroup = rootMenu:Create("Avançado")
local ADV_InputLatency = advGroup:Slider("Latência de Entrada", 10, 60, 30, "%d ms")
local ADV_EarlyFudge = advGroup:Slider("Ajuste de Antecipação", 10, 40, 25, "%d ms")
local ADV_ImmediateThreshold = advGroup:Slider("Limite Imediato", 10, 120, 60, "%d ms")
local ADV_EmergencyWindow = advGroup:Slider("Janela de Emergência", 40, 120, 75, "%d ms")
local ADV_PostPickupSuppress = advGroup:Slider("Supressão Após Pegar", 80, 300, 180, "%d ms")
local ADV_UncertaintyBuffer = advGroup:Slider("Incerteza de Impacto", 20, 60, 30, "%d ms")
local ADV_MinDropInterval = advGroup:Slider("Intervalo Mínimo de Drop", 30, 120, 50, "%d ms")

local debugGroup = rootMenu:Create("Debug e Telemetria")
local DebugMode = debugGroup:Switch("Modo Debug", false, "\u{f188}")
local LogProjectiles = debugGroup:Switch("Registrar Projéteis", false, "\u{f188}")
debugGroup:SearchHidden(true)

local function ApplyMenuState()
  local enabled = Toggle:Get()
  realGroup:Disabled(not enabled)
  manualGroup:Disabled(not enabled or (enabled and RealTimeLead:Get()))
  safetyGroup:Disabled(not enabled)
  advGroup:Disabled(not enabled)
  debugGroup:Disabled(not enabled)
  IgnoreRadius:Disabled(not enabled)
  BlockOrders:Disabled(not enabled)
  DisableAfter:Disabled(not enabled)
  DisableAfterToggle:Disabled(not enabled)
end

if Toggle.SetCallback and RealTimeLead.SetCallback then
  Toggle:SetCallback(ApplyMenuState)
  RealTimeLead:SetCallback(ApplyMenuState)
end
ApplyMenuState()

local player, hero
local gameTime = 0

local pingSec = 0
local nextPingRefresh = 0
local PING_REFRESH_INTERVAL = 0.25

local maxWindows = 16
local windowsStart, windowsEnd, windowsCount = {}, {}, {}
local windowsN = 0
local earliestIdx = 0

local STATE_IDLE, STATE_DROPPING, STATE_READY, STATE_PICKING = 0, 1, 2, 3
local state = STATE_IDLE

local dropAt = 0
local dropTime = 0
local itemEntity
local retryTime = 0
local suppressGuardsUntil = 0
local lastImmediateAttempt = 0
local lastOrderTime = 0
local lastDropAttempt = 0

local earliestImpactTime = 0
local earliestProj = nil

local ORDER_COOLDOWN = 0.010
local PROJECTILE_CLEANUP_INTERVAL = 0.015
local nextWindowsCleanup = 0

local MIN_PROJECTILE_SPEED = 50
local DEFAULT_PROJECTILE_SPEED = 900

local function DebugLog(msg)
  if DebugMode:Get() then print("[Tranquil] " .. msg) end
end

local function GetPingSeconds()
  if not NetChannel or not NetChannel.GetAvgLatency then return 0 end
  local ok, v = pcall(NetChannel.GetAvgLatency)
  if not ok or not v then return 0 end
  if v > 3 then return math.min(1.0, v / 1000.0) end
  return math.min(1.0, math.max(0, v))
end

local function HasTranquils()
  return hero and NPC.HasItem(hero, "item_tranquil_boots")
end

local function RecomputeEarliest()
  earliestIdx = 0
  local best = math.huge
  for i = 1, windowsN do
    local s = windowsStart[i]
    if s < best then
      best = s; earliestIdx = i
    end
  end
end

local function AddWindow(s, e)
  local mergeTol = (ProjectileGrouping:Get() * 0.001) * 2
  for i = 1, windowsN do
    if s <= windowsEnd[i] + mergeTol and e >= windowsStart[i] - mergeTol then
      if s < windowsStart[i] then windowsStart[i] = s end
      if e > windowsEnd[i] then windowsEnd[i] = e end
      windowsCount[i] = (windowsCount[i] or 1) + 1
      if earliestIdx == 0 or windowsStart[i] < windowsStart[earliestIdx] then earliestIdx = i end
      return i
    end
  end
  if windowsN < maxWindows then
    windowsN = windowsN + 1
    windowsStart[windowsN] = s
    windowsEnd[windowsN] = e
    windowsCount[windowsN] = 1
    if earliestIdx == 0 or s < windowsStart[earliestIdx] then earliestIdx = windowsN end
    return windowsN
  else
    local worstIdx, worstStart = 1, windowsStart[1]
    for i = 2, windowsN do
      if windowsStart[i] > worstStart then
        worstStart = windowsStart[i]; worstIdx = i
      end
    end
    if s < worstStart then
      windowsStart[worstIdx] = s
      windowsEnd[worstIdx] = e
      windowsCount[worstIdx] = 1
      RecomputeEarliest()
      return worstIdx
    end
  end
end

local function CleanupWindows(now)
  local cutoff = now - (PickupBuffer:Get() * 0.001)
  local w = 1
  for i = 1, windowsN do
    if windowsEnd[i] > cutoff then
      if w ~= i then
        windowsStart[w] = windowsStart[i]
        windowsEnd[w] = windowsEnd[i]
        windowsCount[w] = windowsCount[i]
      end
      w = w + 1
    end
  end
  for i = w, windowsN do
    windowsStart[i] = nil
    windowsEnd[i] = nil
    windowsCount[i] = nil
  end
  windowsN = w - 1
  RecomputeEarliest()
end

local function IsSafeToPickup(now)
  local safeTime = now + (PickupBuffer:Get() * 0.001)
  for i = 1, windowsN do
    if windowsStart[i] <= safeTime and windowsEnd[i] >= now then
      return false
    end
  end
  return true
end

local function ComputeLead(travelTime, projCount)
  local base = (BaseDropLead:Get() * 0.001) + (ADV_InputLatency:Get() * 0.001) + (ADV_EarlyFudge:Get() * 0.001)
  if not RealTimeLead:Get() then
    local pingPart = PingCompensation:Get() and pingSec or 0
    return math.min(base + pingPart, math.max(0, travelTime - 0.01))
  end

  local pingPart = (PingCompensation:Get() and pingSec or 0) * (RTPingScale:Get() * 0.01)
  local lead = base
      + pingPart
      + (travelTime * (RTTravelPercent:Get() * 0.01))
      + math.max(0, (projCount or 1) - 1) * (RTMultiExtra:Get() * 0.001)

  local minLead = RTMinLead:Get() * 0.001
  local maxLead = RTMaxLead:Get() * 0.001
  if lead < minLead then lead = minLead end
  if lead > maxLead then lead = maxLead end

  local safety = 0.015
  if lead > travelTime - safety then
    lead = math.max(minLead, travelTime - safety)
  end
  return lead
end

local function GetVerifyDelay()
  return math.max(0.15, math.min(0.14, pingSec * 1.2 + 0.035))
end

local function ClearCycle(now)
  dropAt = 0
  earliestImpactTime = 0
  earliestProj = nil
  local eps = 0.005
  local w = 1
  for i = 1, windowsN do
    if windowsEnd[i] > now + eps then
      if w ~= i then
        windowsStart[w] = windowsStart[i]
        windowsEnd[w] = windowsEnd[i]
        windowsCount[w] = windowsCount[i]
      end
      w = w + 1
    end
  end
  for i = w, windowsN do
    windowsStart[i] = nil
    windowsEnd[i] = nil
    windowsCount[i] = nil
  end
  windowsN = w - 1
  RecomputeEarliest()
end

local function DropTranquils(now, priority)
  if not hero or not player then return false end
  if not HasTranquils() then return false end

  if (not priority) and (now - lastOrderTime < ORDER_COOLDOWN) then return false end
  if now - lastDropAttempt < (ADV_MinDropInterval:Get() * 0.001) then return false end

  local tranquil = NPC.GetItem(hero, "item_tranquil_boots")
  local cooldown = Ability.GetCooldown(tranquil)
  if not tranquil then return false end
  if AbuseWhenOnCooldown:Get() == false and cooldown > 0 then return false end

  local ok = pcall(function()
    Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_DROP_ITEM,
      nil, Entity.GetAbsOrigin(hero), tranquil,
      Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
      hero, false, false, false, true)
  end)

  if ok then
    lastOrderTime = now
    lastDropAttempt = now
    dropTime = now
    dropAt = 0
    earliestImpactTime = 0
    earliestProj = nil
    state = STATE_DROPPING
    DebugLog(priority and "Drop sent (PRIORITY)" or "Drop sent")
    return true
  end
  return false
end

local function FindDroppedTranquils()
  local items = PhysicalItems.GetAll()
  if not items or #items == 0 then return false end
  local heroPos = Entity.GetAbsOrigin(hero)
  local best, bestD = nil, 1e9
  for i = 1, #items do
    local fitem = items[i]
    local item = PhysicalItem.GetItem(fitem)
    if item and Entity.GetClassName(item) == "C_DOTA_Item_TranquilBoots" then
      local ipos = Entity.GetAbsOrigin(fitem)
      local d = ipos and heroPos:Distance(ipos) or 0
      if d < bestD then
        best = fitem; bestD = d
      end
    end
  end
  if best then
    itemEntity = best
    return true
  end
  return false
end

local function PickupTranquils(now)
  if not itemEntity then return false end
  if now - lastOrderTime < ORDER_COOLDOWN then return false end

  local ok = pcall(function()
    Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_PICKUP_ITEM,
      itemEntity, Vector(0, 0, 0), nil,
      Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
      hero, false, false, false, true)
  end)
  if ok then
    lastOrderTime = now
    retryTime = now + 0.08
    DebugLog("Pickup order")
    return true
  end
  return false
end

local function GetProjectilePos(data)
  return data.position or data.pos or data.origin or data.startPos or data.start or data.start_position or
      data.spawnOrigin or data.spawn_origin
end

script.OnProjectile = function(data)
  if not data then return end
  local now = GameRules.GetGameTime()
  if not hero then return end

  if DisableAfterToggle:Get() and now >= (DisableAfter:Get() * 60) then return end
  if not Toggle:Get() then return end

  local target = data.target
  if not target or target ~= hero then return end
  local source = data.source
  if not source or Entity.IsSameTeam(hero, source) or not Entity.IsHero(source) then return end

  local heroPos = Entity.GetAbsOrigin(hero)
  local projPos = GetProjectilePos(data)
  local srcPos = (not projPos) and Entity.GetAbsOrigin(source) or nil
  local distance = heroPos:Distance(projPos or srcPos)
  if distance <= IgnoreRadius:Get() then return end

  if LogProjectiles:Get() then
    print(string.format("[Proj] %s->me spd=%s dst=%.0f",
      NPC.GetUnitName(source) or "?", tostring(data.moveSpeed or data.original_move_speed), distance))
  end

  if now < suppressGuardsUntil then suppressGuardsUntil = now end

  local speed = math.max(MIN_PROJECTILE_SPEED, data.moveSpeed or data.original_move_speed or DEFAULT_PROJECTILE_SPEED)
  local impactTime = (data.maxImpactTime and data.maxImpactTime > now) and data.maxImpactTime
      or (data.expireTime and data.expireTime > now) and data.expireTime
      or (now + distance / speed)

  local uncertainty = ADV_UncertaintyBuffer:Get() * 0.001
  AddWindow(impactTime - uncertainty, impactTime + uncertainty)

  if state ~= STATE_IDLE or not HasTranquils() then return end

  local travel = impactTime - now
  local count = 1
  for i = 1, windowsN do
    if windowsStart[i] <= impactTime + 0.05 and windowsEnd[i] >= now then
      local c = windowsCount[i] or 1
      if c > count then count = c end
    end
  end

  local lead = ComputeLead(travel, count)
  local dropTimeAt = impactTime - lead

  local emergencyWindow = ADV_EmergencyWindow:Get() * 0.001
  local immediateThreshold = ADV_ImmediateThreshold:Get() * 0.001

  if travel <= emergencyWindow then
    if now - lastImmediateAttempt > 0.010 then
      lastImmediateAttempt = now
      DropTranquils(now, true)
    end
    return
  end

  if dropTimeAt <= now + immediateThreshold then
    if now - lastImmediateAttempt > 0.010 then
      lastImmediateAttempt = now
      DropTranquils(now, true)
    end
  else
    if dropAt == 0 or dropTimeAt < dropAt - 0.004 then
      dropAt = dropTimeAt
      earliestImpactTime = impactTime
      earliestProj = { src = source, speed = speed, dist0 = distance }
      DebugLog(string.format("Scheduled drop in %.3fs (lead %.3fs)", dropAt - now, lead))
    end
  end
end

script.OnUpdate = function()
  hero = hero or Heroes.GetLocal()
  player = player or Players.GetLocal()
  gameTime = GameRules.GetGameTime()

  if not hero or not player then return end

  if gameTime >= nextPingRefresh then
    nextPingRefresh = gameTime + PING_REFRESH_INTERVAL
    pingSec = PingCompensation:Get() and GetPingSeconds() or 0
  end

  if not Toggle:Get() then return end
  if DisableAfterToggle:Get() and gameTime >= (DisableAfter:Get() * 60) then return end

  if gameTime >= nextWindowsCleanup then
    nextWindowsCleanup = gameTime + PROJECTILE_CLEANUP_INTERVAL
    CleanupWindows(gameTime)
  end

  if state == STATE_IDLE and HasTranquils() and dropAt > 0 and gameTime >= dropAt then
    DropTranquils(gameTime, true)
  end

  if state == STATE_IDLE and HasTranquils() and earliestProj and earliestImpactTime > 0 then
    local src = earliestProj.src
    if src and Entity.IsAlive(src) then
      local d = Entity.GetAbsOrigin(hero):Distance(Entity.GetAbsOrigin(src))
      if d + 20 < (earliestProj.dist0 or d) then
        local speed = earliestProj.speed or DEFAULT_PROJECTILE_SPEED
        local newImpact = gameTime + (d / speed)
        if newImpact + 0.005 < earliestImpactTime then
          local count = 1
          for i = 1, windowsN do
            if windowsStart[i] <= newImpact + 0.05 and windowsEnd[i] >= gameTime then
              local c = windowsCount[i] or 1
              if c > count then count = c end
            end
          end
          local newLead = ComputeLead(newImpact - gameTime, count)
          local newDropAt = newImpact - newLead
          earliestImpactTime = newImpact
          earliestProj.dist0 = d

          local emergencyWindow = ADV_EmergencyWindow:Get() * 0.001
          local immediateThreshold = ADV_ImmediateThreshold:Get() * 0.001

          if (newImpact - gameTime) <= emergencyWindow then
            DropTranquils(gameTime, true)
          elseif newDropAt <= gameTime + immediateThreshold then
            DropTranquils(gameTime, true)
          elseif dropAt == 0 or newDropAt < dropAt - 0.006 then
            dropAt = newDropAt
            DebugLog(string.format("Rescheduled drop in %.3fs", dropAt - gameTime))
          end
        end
      end
    else
      earliestProj = nil
      earliestImpactTime = 0
    end
  end

  if state == STATE_IDLE and HasTranquils() and gameTime >= suppressGuardsUntil and windowsN > 0 then
    local idx = earliestIdx
    if idx ~= 0 then
      local ts = windowsStart[idx] - gameTime
      local te = windowsEnd[idx] - gameTime
      local emergencyWindow = ADV_EmergencyWindow:Get() * 0.001
      if te > 0 and (ts <= emergencyWindow or te <= emergencyWindow) then
        DropTranquils(gameTime, true)
      end
    end
  end

  if state == STATE_DROPPING then
    if gameTime - dropTime >= GetVerifyDelay() then
      if HasTranquils() then
        state = STATE_IDLE
        dropAt = 0
        DebugLog("Drop verify failed (still on hero)")
      elseif FindDroppedTranquils() then
        state = STATE_READY
        DebugLog("Drop verified")
      else
        if gameTime - dropTime > 0.6 then
          state = STATE_IDLE
          dropAt = 0
          DebugLog("Drop timeout: can't find boots")
        end
      end
    end
  elseif state == STATE_READY then
    if not itemEntity and not FindDroppedTranquils() then
      state = STATE_IDLE
      dropAt = 0
      DebugLog("Lost dropped boots")
    else
      if IsSafeToPickup(gameTime) then
        if PickupTranquils(gameTime) then
          state = STATE_PICKING
        end
      else
        if gameTime - dropTime > 4.0 then
          state = STATE_IDLE
          dropAt = 0
          DebugLog("Pickup aborted (timeout)")
        end
      end
    end
  elseif state == STATE_PICKING then
    if HasTranquils() then
      state = STATE_IDLE
      itemEntity = nil
      suppressGuardsUntil = gameTime + (ADV_PostPickupSuppress:Get() * 0.001)
      ClearCycle(gameTime)
      DebugLog("Pickup verified")
    elseif retryTime > 0 and gameTime >= retryTime then
      retryTime = 0
      if IsSafeToPickup(gameTime) then
        PickupTranquils(gameTime)
      else
        state = STATE_READY
      end
    elseif gameTime - dropTime > 2.5 then
      state = STATE_IDLE
      DebugLog("Pickup timeout")
    end
  end
end

local blocked_orders = {
  [Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_DIRECTION] = true,
  [Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_TARGET] = true,
  [Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION] = true,
  [Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_MOVE] = true,
  [Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET] = true,
  [Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION] = true,
}

script.OnPrepareUnitOrders = function(order)
  if not Toggle:Get() or not BlockOrders:Get() then return end
  if state == STATE_IDLE then return end
  if order.order == Enum.UnitOrder.DOTA_UNIT_ORDER_PICKUP_ITEM then
    return true
  end
  return not blocked_orders[order.order]
end

script.OnGameEnd = function()
  if hero then
    hero = nil
    player = nil
  end
end

return script
