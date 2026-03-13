local script                                 = {}

local AutoTakeRunes                          = Menu.Create("Heroes", "Hero List", "Arc Warden", "Main Settings",
  "Utility"):Switch(
  "Pegar Runas Automaticamente", true, "panorama/images/items/bottle_xp_png.vtex_c")
local Gear                                   = AutoTakeRunes:Gear("Configurações")
local ToTake                                 = Gear:MultiSelect(
  "Runas para pegar",
  {
    { "0", "panorama/images/items/bottle_doubledamage_png.vtex_c", true },
    { "1", "panorama/images/items/bottle_haste_png.vtex_c",        true },
    { "2", "panorama/images/items/bottle_illusion_png.vtex_c",     true },
    { "3", "panorama/images/items/bottle_invisibility_png.vtex_c", true },
    { "4", "panorama/images/items/bottle_regeneration_png.vtex_c", true },
    { "5", "panorama/images/items/bottle_bounty_png.vtex_c",       true },
    { "6", "panorama/images/items/bottle_arcane_png.vtex_c",       true },
    { "7", "panorama/images/items/bottle_water_png.vtex_c",        true },
    { "9", "panorama/images/items/bottle_shield_png.vtex_c",       true },
  },
  true
)

local BehaviorMode                           = Gear:Combo("Modo de Pegar Runas", { "Sempre", "Apenas quando inimigos próximos" }, 0)
local EnemyRange                             = Gear:Slider("Alcance de Inimigo Próximo", 200, 2000, 800, "%d")

local RuneSpawnPosition1, RuneSpawnPosition2 = Vector(-1656, 1126, 0), Vector(1193, -1198, 0)

local function EnemyNearbyRune(runePos, checkRange)
  for _, hero in pairs(Heroes.GetAll()) do
    if hero and Entity.IsAlive(hero) and not Entity.IsSameTeam(Heroes.GetLocal(), hero) then
      local lastPos = Hero.GetLastMaphackPos(hero) or Entity.GetAbsOrigin(hero)
      if lastPos and runePos:Distance2D(lastPos) <= checkRange then
        return true
      end
    end
  end
  return false
end

local function IsRuneSpawnTime(gameTime)
  return gameTime >= 120 and math.fmod(gameTime, 120) < 1.0
end

local function TryCastAtRune(me, mf, runePos, castRange, pullRadius, hasPullingFacet)
  if not runePos then return false end
  local mePos = Entity.GetAbsOrigin(me)
  local dist  = mePos:Distance2D(runePos)

  if dist <= castRange then
    Ability.CastPosition(mf, runePos)
    return true
  elseif hasPullingFacet and dist <= castRange + pullRadius then
    local castPos = mePos + (runePos - mePos):Normalized() * castRange
    Ability.CastPosition(mf, castPos)
    return true
  end
  return false
end

script.OnUpdate = function()
  if not AutoTakeRunes:Get() then return end

  local me = Heroes.GetLocal()
  if not me or Entity.GetUnitName(me) ~= "npc_dota_hero_arc_warden" then return end

  local time = GameRules.GetDOTATime(false, true)
  local runeJustSpawned = IsRuneSpawnTime(time)

  local mf = NPC.GetAbility(me, "arc_warden_magnetic_field")
  if not mf or not Ability.IsReady(mf) then return end

  local hasPullingFacet = Hero.GetFacetID(me) == 4
  local castRange = Ability.GetCastRange(mf)
  local pullRadius = Ability.GetLevelSpecialValueFor(mf, "rune_pull_radius")
  local mePos = Entity.GetAbsOrigin(me)

  local visibleRunes = {}
  for _, rune in pairs(Runes.GetAll()) do
    local runeType = Rune.GetRuneType(rune)
    if ToTake:Get(tostring(runeType)) then
      table.insert(visibleRunes, rune)
    end
  end

  if #visibleRunes > 0 then
    table.sort(visibleRunes, function(a, b)
      return mePos:Distance2D(Entity.GetAbsOrigin(a)) < mePos:Distance2D(Entity.GetAbsOrigin(b))
    end)
    local rune = visibleRunes[1]
    local runePos = Entity.GetAbsOrigin(rune)

    if BehaviorMode:Get() == 1 and not EnemyNearbyRune(runePos, EnemyRange:Get()) then
      return
    end
    if TryCastAtRune(me, mf, runePos, castRange, pullRadius, hasPullingFacet) then return end
  end

  if runeJustSpawned then
    local spawn1Visible = FogOfWar.IsPointVisible(RuneSpawnPosition1)
    local spawn2Visible = FogOfWar.IsPointVisible(RuneSpawnPosition2)

    if not spawn1Visible and not spawn2Visible then
      local midpoint = (RuneSpawnPosition1 + RuneSpawnPosition2) * 0.5
      if hasPullingFacet and mePos:Distance2D(midpoint) <= castRange + pullRadius then
        if BehaviorMode:Get() == 0 or EnemyNearbyRune(midpoint, EnemyRange:Get()) then
          local castPos = mePos + (midpoint - mePos):Normalized() * castRange
          Ability.CastPosition(mf, castPos)
          return
        end
      end
    else
      local targetPos = nil
      if spawn1Visible and not spawn2Visible then
        targetPos = RuneSpawnPosition2
      elseif spawn2Visible and not spawn1Visible then
        targetPos = RuneSpawnPosition1
      end

      if targetPos then
        if BehaviorMode:Get() == 0 or EnemyNearbyRune(targetPos, EnemyRange:Get()) then
          TryCastAtRune(me, mf, targetPos, castRange, pullRadius, hasPullingFacet)
          return
        end
      end
    end
  end
end

return script
