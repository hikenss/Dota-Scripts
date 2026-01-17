-- ForceStaffEscape (Atualizado para framework moderno de scripts)
-- Reage ao início da Cronosfera do Faceless Void e usa Force Staff / Hurricane Pike
-- Compatibilidade: usa callbacks no estilo return { ... } com Menu.Create

-- Menu (usando estrutura moderna)
local menu = Menu.Create("Scripts", "Utility", "Force Staff Escape")
menu:Icon("\u{f0e7}")

local ui = {}
ui.enabled = menu:Switch("Enabled", true)
ui.toggle = menu:Bind("Toggle Key", Enum.ButtonCode.KEY_NONE)
ui.mode_force = menu:Combo("Force Staff", {"Use for yourself", "Use to the enemy"}, 0)
ui.mode_pike  = menu:Combo("Hurricane Pike", {"Use for yourself", "Use to the enemy"}, 1)

-- Estado
local enabled_state = true
local my_hero = nil
local timers = {}

-- Utilitários
local function now()
	return GameRules.GetGameTime()
end

local function set_timer(name, duration)
	timers[name] = now() + duration
end

local function check_timer(name)
	return timers[name] and now() < timers[name]
end

local function is_enabled()
	return ui.enabled:Get() and enabled_state
end

local function get_hero()
	if not my_hero or not Entity.IsAlive(my_hero) then
		my_hero = Heroes.GetLocal()
	end
	return my_hero
end

local function has_mana_and_ready(owner, ability)
	if not ability then return false end
	if not Ability.IsCastable(ability, NPC.GetMana(owner)) then return false end
	local cd = Ability.GetCooldown(ability) or 0.0
	if cd > 0.0 then return false end
	return true
end

local function can_cast_self(owner, item)
	return has_mana_and_ready(owner, item)
end

local function can_cast_target(owner, target, item)
	if not has_mana_and_ready(owner, item) then return false end
	local range = Ability.GetCastRange(item) or 0
	if range < 0 then range = 0 end
	-- bônus de alcance caso a API suporte
	local bonus = NPC.GetCastRangeBonus and NPC.GetCastRangeBonus(owner) or 0
	range = range + (bonus or 0)
	return NPC.IsEntityInRange(owner, target, range + 50)
end

local function use_force(owner, target)
	if not owner then return false end
	local fs = NPC.GetItem(owner, "item_force_staff", true)
	if not fs then return false end
	local mode = ui.mode_force:Get()
	if mode == 0 then
		if not can_cast_self(owner, fs) then return false end
		Ability.CastNoTarget(fs)
		if Players.GetLocal() then
			Player.HoldPosition(Players.GetLocal(), owner)
		end
		return true
	else
		if not target or Entity.IsSameTeam(target, owner) then return false end
		if not can_cast_target(owner, target, fs) then return false end
		Ability.CastTarget(fs, target)
		if Players.GetLocal() then
			Player.HoldPosition(Players.GetLocal(), owner)
		end
		return true
	end
end

local function use_pike(owner, target)
	if not owner then return false end
	local pike = NPC.GetItem(owner, "item_hurricane_pike", true)
	if not pike then return false end
	local mode = ui.mode_pike:Get()
	if mode == 0 then
		if not can_cast_self(owner, pike) then return false end
		Ability.CastNoTarget(pike)
		if Players.GetLocal() then
			Player.HoldPosition(Players.GetLocal(), owner)
		end
		return true
	else
		if not target or Entity.IsSameTeam(target, owner) then return false end
		if not can_cast_target(owner, target, pike) then return false end
		Ability.CastTarget(pike, target)
		if Players.GetLocal() then
			Player.HoldPosition(Players.GetLocal(), owner)
		end
		return true
	end
end

-- Detecção da crono por animação
local function handle_animation(data)
	local hero = get_hero()
	if not hero then return end
	if not is_enabled() then return end
	if not data or not data.unit then return end
	if Entity.IsSameTeam(data.unit, hero) then return end
	if not Entity.IsHero(data.unit) or NPC.IsIllusion(data.unit) then return end
	-- Nome clássico de sequência para cast da Chronosphere (pode variar por build)
	if data.sequenceName ~= "chronosphere_anim" then return end
	-- Precisa reagir antes de ficar stunado
	if NPC.IsStunned(hero) or NPC.IsSilenced(hero) then return end
	-- Tentar Force, depois Pike
	if use_force(hero, data.unit) then return end
	use_pike(hero, data.unit)
end

-- Fallback: detectar modificador da Crono aplicado no Void durante o cast (ou logo após)
-- Algumas builds expõem modificador do cast/thinker. Tentamos reagir no primeiro tick.
local known_crono_mods = {
	["modifier_faceless_void_chronosphere_freeze"] = true,   -- alvo preso
	["modifier_faceless_void_chronosphere"] = true,          -- efeito raiz/area
	["modifier_chronosphere_thinker"] = true                 -- thinker/area
}

local function handle_modifier_added(data)
	-- data: { entity, name }
	local hero = get_hero()
	if not hero then return end
	if not is_enabled() then return end
	if not data or not data.entity or not data.name then return end
	-- Reagir quando o herói local recebe o efeito (se ainda puder agir)
	if data.entity == hero and known_crono_mods[data.name] then
		if not NPC.IsStunned(hero) and not NPC.IsSilenced(hero) then
			-- Sem alvo confiável aqui; usar self-cast prioritário
			if use_force(hero, nil) then return end
			use_pike(hero, nil)
		end
	end
end

-- Toggle handler
local function handle_toggle()
	if ui.toggle and ui.toggle:IsPressed() and not check_timer("toggle_cd") then
		enabled_state = not enabled_state
		set_timer("toggle_cd", 0.25)
	end
end

return {
	OnUpdate = function()
		handle_toggle()
	end,

	OnUnitAnimation = function(data)
		handle_animation(data)
	end,

	OnModifierAdded = function(data)
		handle_modifier_added(data)
	end,

	OnGameEnd = function()
		my_hero = nil
		timers = {}
		enabled_state = true
	end,
}