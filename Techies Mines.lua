local script = {}

local main = Menu.Create("General", "Main", "Techies Mines")
local menu = main:Create("Main Settings"):Create("Main Settings")

local IsToggled = menu:Switch("Destruir Minas Automaticamente", true, "panorama/images/spellicons/techies_land_mines_png.vtex_c")
local AvoidRisky = menu:Switch("Evitar Ataques Arriscados", true)
AvoidRisky:ToolTip("Se ativado, o herói fugirá se não houver tempo para destruir a mina.")
local SafetyMargin = menu:Slider("Margem de Segurança (ms)", 0, 500, 100)
SafetyMargin:ToolTip("Tempo extra de segurança para o cálculo de risco.")

local hero = nil
local player = nil
local IsRanged = nil
local DETONATION_DELAY = 1.0 

-- Tabela para rastrear quando as minas entraram no alcance
local MinesTracker = {}

local function GetDistanceFromTo(From, To)
  return From:Distance(To)
end

-- Função auxiliar para verificar se está de frente
local function IsFacing(unit, targetPos, angle)
    local forward = unit:GetForward()
    local toTarget = (targetPos - unit:GetAbsOrigin()):Normalized()
    local dot = forward:Dot(toTarget)
    return dot > (angle or 0.9)
end

script.OnUpdate = function()
  if not IsToggled:Get() then return end

  if hero == nil or not Entity.IsAlive(hero) then
    hero = Heroes.GetLocal()
    player = Players.GetLocal()
    if hero then IsRanged = NPC.IsRanged(hero) end
    return
  end

  local AttackRange = NPC.GetAttackRange(hero) + NPC.GetAttackRangeBonus(hero)
  -- Aumentamos o raio de busca para pegar minas ANTES de elas ativarem (500 range)
  local SearchRadius = math.max(AttackRange + 200, 1000)
  
  local Surroundings = Entity.GetUnitsInRadius(hero, SearchRadius, Enum.TeamType.TEAM_ENEMY)
  
  local closestMine = nil
  local closestMineDist = math.huge
  local now = GameRules.GetGameTime()
  local currentMines = {}

  for _, Unit in pairs(Surroundings) do
    local name = Entity.GetUnitName(Unit)
    if (name == "npc_dota_techies_mines" or name == "npc_dota_techies_land_mine") and Entity.IsAlive(Unit) then
      local index = Entity.GetIndex(Unit)
      currentMines[index] = true
      
      local dist = GetDistanceFromTo(Entity.GetAbsOrigin(hero), Entity.GetAbsOrigin(Unit))
      
      -- Se a mina entrou no raio de ativação (500), registramos o tempo
      if dist <= 500 then
          if not MinesTracker[index] then
            MinesTracker[index] = now
          end
      else
          -- Se saiu do raio ou ainda não entrou, limpamos o tracker
          MinesTracker[index] = nil
      end
      
      if dist < closestMineDist then
        closestMineDist = dist
        closestMine = Unit
      end
    end
  end

  -- Limpeza de memória
  for index, _ in pairs(MinesTracker) do
    if not currentMines[index] then
      MinesTracker[index] = nil
    end
  end

  if closestMine then
    local index = Entity.GetIndex(closestMine)
    local distToMine = closestMineDist
    
    -- CASO 1: Mina fora do alcance de detonação (> 500)
    -- É seguro atacar sempre.
    if distToMine > 500 then
        if distToMine <= AttackRange + 100 then
            Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, closestMine, nil, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, hero)
        end
        return
    end

    -- CASO 2: Mina dentro do alcance de detonação (<= 500)
    -- O relógio está correndo.
    local timeInRadius = now - (MinesTracker[index] or now)
    local remainingTime = DETONATION_DELAY - timeInRadius
    
    -- Se já vai explodir agora, não adianta fazer nada
    if remainingTime <= 0.05 then return end

    -- Cálculos de tempo para ataque
    local AttackPoint = NPC.GetAttackAnimPoint(hero)
    local TimeToFace = 0
    if not IsFacing(hero, Entity.GetAbsOrigin(closestMine), 0.8) then
        TimeToFace = NPC.GetTimeToFace(hero, closestMine)
    end

    local latency = NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING)
    local safety = SafetyMargin:Get() / 1000
    local totalAttackTime = 0

    if IsRanged then
      local ProjectileSpeed = NPC.GetAttackProjectileSpeed(hero)
      local projectileTime = 0
      if ProjectileSpeed > 0 then
        projectileTime = distToMine / ProjectileSpeed
      end
      totalAttackTime = TimeToFace + AttackPoint + projectileTime
    else
      local MoveSpeed = NPC.GetMoveSpeed(hero)
      local walkTime = 0
      if distToMine > AttackRange then
        if MoveSpeed > 0 then
            walkTime = (distToMine - AttackRange) / MoveSpeed
        end
      end
      totalAttackTime = walkTime + TimeToFace + AttackPoint
    end

    local timeNeeded = totalAttackTime + latency + safety

    -- Decisão
    if timeNeeded < remainingTime then
       -- Dá tempo: ATACAR
       Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET, closestMine, nil, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, hero)
    else
       -- Não dá tempo
       if AvoidRisky:Get() then
           -- FUGIR: Move para longe da mina
           local myPos = Entity.GetAbsOrigin(hero)
           local minePos = Entity.GetAbsOrigin(closestMine)
           local escapeDir = (myPos - minePos):Normalized()
           local escapePos = myPos + escapeDir * 600
           Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, hero)
       end
       -- Se AvoidRisky estiver desligado, ele simplesmente ignora e deixa o jogador decidir (ou morrer tentando)
    end
  end
end

script.OnGameEnd = function()
  hero = nil
  player = nil
  MinesTracker = {}
end

return script

