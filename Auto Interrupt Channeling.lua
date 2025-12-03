local brewInterrupt = {}
local baseMenu = Menu.Find("Heroes", "Hero List", "Brewmaster", "Main Settings", "Hero Settings")

local interruptEnabled = baseMenu:Switch("Ativar Auto Interrupção", true)

local interruptAbilities = baseMenu:MultiSelect("Interromper com", {
  { "cyclone", "panorama/images/spellicons/brewmaster_storm_cyclone_png.vtex_c",      true },
  { "hurl",    "panorama/images/spellicons/brewmaster_earth_hurl_boulder_png.vtex_c", true },
}, true)

local myHero
local cycloneRange = 800 -- approximate range for storm cyclone
local hurlRange = 1000   -- approximate range for hurl boulder

local nextCastTime = 0
local castCooldown = 0.5

function brewInterrupt.OnUpdate()
  if not interruptEnabled:Get() then return end

  myHero = Heroes.GetLocal()
  if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_brewmaster" then return end
  if not Entity.IsAlive(myHero) or NPC.IsWaitingToSpawn(myHero) then return end
  if GameRules.GetGameTime() < nextCastTime then return end
  local units = Entity.GetUnitsInRadius(myHero, 1200, Enum.TeamType.TEAM_FRIEND)

  local HurlUnit = nil
  local CycloneUnit = nil

  for _, unit in ipairs(units) do
    Log.Write(NPC.GetUnitName(unit))
    if string.find(NPC.GetUnitName(unit), "npc_dota_brewmaster_earth") then HurlUnit = unit end
    if string.find(NPC.GetUnitName(unit), "npc_dota_brewmaster_storm") then CycloneUnit = unit end
  end
  if HurlUnit == nil or CycloneUnit == nil then return end
  local cyclone = NPC.GetAbility(CycloneUnit, "brewmaster_storm_cyclone")
  local hurl = NPC.GetAbility(HurlUnit, "brewmaster_earth_hurl_boulder")
  if not cyclone and not hurl then return end

  local enemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY)

  for _, enemy in ipairs(enemies) do
    if enemy and Entity.IsAlive(enemy) and NPC.IsChannellingAbility(enemy) then
      local dist = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D()

      if interruptAbilities:Get("cyclone") and cyclone and Ability.GetCooldown(cyclone) <= 0.0 and dist <= cycloneRange then
        Log.Write("Casting Cyclone")
        Ability.CastTarget(cyclone, enemy)
        nextCastTime = GameRules.GetGameTime() + castCooldown
        return
      end

      if interruptAbilities:Get("hurl") and hurl and Ability.IsCastable(hurl) and dist <= hurlRange then
        Log.Write("Casting Hurl Boulder")
        Ability.CastTarget(hurl, enemy)
        nextCastTime = GameRules.GetGameTime() + castCooldown
        return
      end
    end
  end
end

return brewInterrupt
