local script = {}

local root = Menu.Create("Heroes", "Hero List", "Templar Assassin", "Main Settings", "Auto Meld")
local switch = root:Switch("Auto Meld", true, "panorama/images/spellicons/templar_assassin_meld_png.vtex_c")
local manathreshold = root:Slider("Limiar de Mana", 1, 100, 20, "%d%%")

local hero = nil
local player = nil

local pending = { target = nil, expire = 0.0 }
local lastMeldTime = 0.0

script.OnUnitAnimation = function(data)
  if not hero then
    hero = Heroes.GetLocal()
    player = Players.GetLocal()
  end
  if not hero or not player then return end
  if not switch:Get() then return end

  local npc = data.unit
  if not npc or npc ~= hero then return end
  if NPC.GetUnitName(npc) ~= "npc_dota_hero_templar_assassin" then return end

  local seq = data.sequenceName or ""
  if seq == "" or not string.find(string.lower(seq), "attack") then return end

  if GameRules.GetGameTime() - lastMeldTime < 0.12 then return end

  local Meld = NPC.GetAbility(npc, "templar_assassin_meld")
  if not Meld or not Ability.IsReady(Meld) then return end

  local mana = NPC.GetMana(npc)
  local maxMana = NPC.GetMaxMana(npc)
  if maxMana <= 0 then return end
  local mp = math.floor((mana / maxMana) * 100)
  if mp < manathreshold:Get() then return end

  local baseRange = NPC.GetAttackRange(npc) + NPC.GetAttackRangeBonus(npc) + NPC.GetHullRadius(npc)

  local target = NPC.FindFacing(npc, Enum.TeamType.TEAM_ENEMY, baseRange + 100, 90,
    { NPCs.GetAll(Enum.UnitTypeFlags.TYPE_HERO) })
  if not target or not Entity.IsHero(target) then return end
  if Entity.IsDormant and Entity.IsDormant(target) then return end
  if Entity.IsAlive and not Entity.IsAlive(target) then return end

  local dist = Entity.GetAbsOrigin(npc):Distance(Entity.GetAbsOrigin(target))
  local attackRange = baseRange + (NPC.GetHullRadius and NPC.GetHullRadius(target))
  if dist > attackRange then return end

  Ability.CastNoTarget(Meld)
  lastMeldTime = GameRules.GetGameTime()

  Player.PrepareUnitOrders(player, Enum.UnitOrder.DOTA_UNIT_ORDER_STOP, nil, nil, nil,
    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, hero, false, false, false, true)

  pending.target = target
  pending.expire = GameRules.GetGameTime() + 0.5
end

script.OnUpdate = function()
  if not hero or not player then return end
  if not switch:Get() then return end
  if not pending.target then return end

  local t = pending.target
  if GameRules.GetGameTime() > pending.expire then
    pending.target = nil
    return
  end

  if not NPC.HasModifier or not NPC.HasModifier(hero, "modifier_templar_assassin_meld") then
    return
  end

  if not Entity.IsAlive(t) then
    pending.target = nil
    return
  end

  local dist = Entity.GetAbsOrigin(hero):Distance(Entity.GetAbsOrigin(t))
  local attackRange = NPC.GetAttackRange(hero) + NPC.GetAttackRangeBonus(hero) + NPC.GetHullRadius(hero) +
      (NPC.GetHullRadius and NPC.GetHullRadius(t))
  if dist > attackRange + 10 then
    pending.target = nil
    return
  end

  Player.AttackTarget(player, hero, t)
  pending.target = nil
end

return script
