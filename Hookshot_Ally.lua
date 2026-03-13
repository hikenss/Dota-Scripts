local script = {}

local Menu = Menu.Create("Heroes", "Hero List", "Clockwerk", "Main Settings", "Ally Hookshot")
local HookBind = Menu:Bind("Tecla Hook Aliado", Enum.ButtonCode.BUTTON_CODE_INVALID)

HookBind:ToolTip("Segure para dar Hookshot no herói aliado mais próximo ao cursor.\nInclui predição simples de movimento.")

local lastCastTime = 0

local allyTrack = {}

local function getIndex(ent)
  return Entity.GetIndex(ent)
end

local function updateVelocity(ent, now)
  local id = getIndex(ent)
  if id == -1 then return Vector(0, 0, 0) end

  local pos = Entity.GetAbsOrigin(ent)
  local rec = allyTrack[id]
  if rec then
    local dt = now - rec.t
    if dt > 0 and dt < 1.0 then
      rec.v = (pos - rec.pos) * (1.0 / dt)
    end
    rec.pos = pos
    rec.t = now
  else
    allyTrack[id] = { pos = pos, t = now, v = Vector(0, 0, 0) }
  end
  return allyTrack[id].v or Vector(0, 0, 0)
end

local function predictHookAim(mePos, allyPos, allyVel, castPointSec, latencySec, HOOK_SPEED)
  local t = (allyPos - mePos):Length2D() / HOOK_SPEED + castPointSec + latencySec
  for _ = 1, 3 do
    local predicted = allyPos + allyVel * t
    t = (predicted - mePos):Length2D() / HOOK_SPEED + castPointSec + latencySec
  end
  return allyPos + allyVel * t
end

script.OnUpdate = function()
  local me = Heroes.GetLocal()
  if not me or not Entity.IsAlive(me) then return end

  local now = GameRules.GetGameTime()
  for _, h in ipairs(Heroes.GetAll()) do
    if h ~= me and Entity.IsHero(h) and Entity.IsAlive(h) and Entity.IsSameTeam(h, me) then
      updateVelocity(h, now)
    end
  end

  if not HookBind:IsDown() then return end

  if NPC.GetUnitName(me) ~= "npc_dota_hero_rattletrap" then return end

  local hook = NPC.GetAbility(me, "rattletrap_hookshot")
  if not hook or Ability.CanBeExecuted(hook) ~= -1 then return end

  local ally = Input.GetNearestHeroToCursor(Entity.GetTeamNum(me), Enum.TeamType.TEAM_FRIEND)
  if not ally then return end

  local myPos = Entity.GetAbsOrigin(me)
  local allyPos = Entity.GetAbsOrigin(ally)
  local allyVel = updateVelocity(ally, now)

  local castRange = Ability.GetCastRange(hook)
  local castPointSec = 300 / 1000.0
  local latencySec = 50 / 1000.0
  local speed = Ability.GetLevelSpecialValueFor(hook, "speed")

  local aimPos = predictHookAim(myPos, allyPos, allyVel, castPointSec, latencySec, speed)

  local distToPred = (aimPos - myPos):Length2D()
  if distToPred > (castRange + 50) then
    return
  end

  if now - lastCastTime < 0.05 then return end

  Ability.CastPosition(hook, aimPos, false, false, true, false)
  lastCastTime = now
end

return script
