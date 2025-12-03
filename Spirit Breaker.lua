---@diagnostic disable: undefined-global, param-type-mismatch, inject-field
local aghanim_intercept = {}

--==============================================================
-->> UI & Configuration
--==============================================================

local tab               = Menu.Find("Heroes", "Hero List", "Spirit Breaker", "Main Settings")
local group             = tab:Create("Aghanim Scepter")

local ui                = {
  enabled   = group:Switch("Ativar Interceptação", true),
  radius    = group:Slider("Raio de Interceptação", 100, 700, 700),
  angle     = group:Slider("Ângulo de Direção", 10, 180, 90),
  log       = group:Switch("Ativar Log", false),
  abilities = group:MultiSelect("Habilidades Inimigas", {}, true)
}

--==============================================================
-->> Internal Data
--==============================================================

local ability_names     = {} -- [hero] = { "ability_name1", ... }
local pending_heroes    = {} -- [entity] = os.clock()
local GENERIC_SEQUENCES = {
  attack = true,
  attack_anim = true,
  run = true,
  move = true,
  idle = true,
  walk = true,
  death = true,
  spawn = true,
}

--==============================================================
-->> Utility Functions
--==============================================================

local function is_valid_target(target)
  return target
      and Entity.IsAlive(target)
      and not NPC.HasModifier(target, "modifier_spirit_breaker_planar_pocket")
end

local function get_ability_icon(name)
  return "panorama/images/spellicons/" .. name .. "_png.vtex_c"
end

local function is_team_or_both_target_ability(ability)
  if not ability then return false end

  local behavior = Ability.GetBehavior(ability)

  local function has_flag(flag)
    return behavior % (flag * 2) >= flag
  end

  if not has_flag(8) then return false end -- UNIT_TARGET
  if has_flag(256) or has_flag(2) or has_flag(1) or has_flag(131072) or has_flag(512) then
    return false
  end

  local team = Ability.GetTargetTeam(ability)
  return team and (team == 1 or team == 3 or team == 4)
end

local function should_intercept_ability(name)
  return name and ui.abilities and ui.abilities:Get(name)
end

local function guess_ability_by_sequence(hero, sequence)
  if not hero or not sequence or not ability_names[hero] then return nil end

  local seq = sequence:lower():gsub("^_+", "")
      :gsub("_anim$", ""):gsub("_cast$", "")
      :gsub("_ability$", ""):gsub("_spell$", "")
      :gsub("^%a+%d*", "")

  if GENERIC_SEQUENCES[seq] or #seq < 4 then return nil end

  for _, name in ipairs(ability_names[hero]) do
    local ab      = name:lower()
    local nounder = ab:gsub("_", "")
    local suffix  = ab:match("([^_]+)$") or ab

    if #nounder >= 4 and not GENERIC_SEQUENCES[nounder] then
      if seq == nounder or seq:find(nounder, 1, true) or nounder:find(seq, 1, true)
          or seq == suffix or suffix:find(seq, 1, true)
          or seq == ab or ab:find(seq, 1, true)
      then
        return name
      end
    end
  end

  return nil
end

local function handle_animation_event(npc, sequenceName, activity)
  if not ui.enabled:Get() then return end

  local my_hero = Heroes.GetLocal()
  if not my_hero or not NPC.HasScepter(my_hero) then return end
  if NPC.GetUnitName(my_hero) ~= "npc_dota_hero_spirit_breaker" then return end
  if not npc or npc == my_hero or not Entity.IsHero(npc) or Entity.IsSameTeam(npc, my_hero) then return end

  -- Try to resolve ability from activity ID
  local abilityName = nil
  if activity then
    local ability = NPC.GetAbilityByActivity(npc, activity)
    if ability then
      abilityName = Ability.GetName(ability)
    end
  end

  -- Fallback to guess from animation name
  if not abilityName then
    abilityName = guess_ability_by_sequence(npc, sequenceName)
  end

  if not should_intercept_ability(abilityName) then return end

  local target = NPC.FindFacing(npc, Enum.TeamType.TEAM_FRIEND, ui.radius:Get(), ui.angle:Get(), {})
  if not is_valid_target(target) then return end
  if Entity.GetAbsOrigin(Heroes.GetLocal()):Distance(Entity.GetAbsOrigin(target)) > ui.radius:Get() then return end

  local planar = NPC.GetAbility(my_hero, "spirit_breaker_planar_pocket")
  if planar and Ability.GetCooldown(planar) == 0.0 then
    Ability.CastTarget(planar, target, false, false, true)

    if ui.log:Get() then
      Log.Write(string.format("[AghanimIntercept] Casted %s on %s (ability: %s | seq: %s | activity: %s)",
        "spirit_breaker_planar_pocket", NPC.GetUnitName(target),
        tostring(abilityName), tostring(sequenceName), tostring(activity)))
    end
  end
end
--==============================================================
-->> Ability Collection & Menu Sync
--==============================================================

local function update_abilities_multiselect()
  local my_hero = Heroes.GetLocal()
  if not my_hero then return end

  local heroes = Heroes.GetAll()
  local items = {}
  local seen = {}

  for _, hero in ipairs(heroes) do
    if not Entity.IsSameTeam(hero, my_hero) then
      ability_names[hero] = {}

      for i = 0, 23 do
        local ab = NPC.GetAbilityByIndex(hero, i)
        if ab and is_team_or_both_target_ability(ab) and not Ability.IsInnate(ab)
            and not Ability.IsPassive(ab) and not Ability.IsHidden(ab)
        then
          local name = Ability.GetName(ab)
          if name and name ~= "" and not name:find("bonus") and not seen[name] then
            seen[name] = true
            table.insert(ability_names[hero], name)
            table.insert(items, { name, get_ability_icon(name), true })
          end
        end
      end
    end
  end

  if ui.abilities then
    ui.abilities:Update(items, true, true)
  else
    ui.abilities = group:MultiSelect("Habilidades Inimigas", items, true)
  end
end

--==============================================================
-->> Engine Hooks
--==============================================================

function aghanim_intercept.OnUnitAddGesture(data)
  handle_animation_event(data.npc, data.sequenceName, data.activity)
end

function aghanim_intercept.OnUnitAnimation(data)
  handle_animation_event(data.unit, data.sequenceName, data.activity)
end

function aghanim_intercept.OnEntityCreate(entity)
  if Entity.IsHero(entity) and NPC.GetUnitName(Heroes.GetLocal()) == "npc_dota_hero_spirit_breaker" then
    pending_heroes[entity] = os.clock()
  end
end

function aghanim_intercept.OnUpdate()
  local my_hero = Heroes.GetLocal()
  if not my_hero or NPC.GetUnitName(my_hero) ~= "npc_dota_hero_spirit_breaker" then return end

  local all_heroes = Heroes.GetAll()
  local active_heroes = {}
  for _, h in ipairs(all_heroes) do active_heroes[h] = true end

  for entity, t in pairs(pending_heroes) do
    if active_heroes[entity] then
      update_abilities_multiselect()
      pending_heroes[entity] = nil
    elseif os.clock() - t > 2 then
      pending_heroes[entity] = nil
    end
  end
end

function aghanim_intercept.OnGameEnd()
  if ui.abilities then
    ui.abilities:Update({}, true)
  end
end

function aghanim_intercept.OnScriptsLoaded()
  if Engine.IsInGame() then
    update_abilities_multiselect()
  end
end

return aghanim_intercept
