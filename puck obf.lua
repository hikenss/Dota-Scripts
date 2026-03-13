-- Refactored Puck Auto Phase Shift (cleaned & extended)
local PuckAPS = {}

-- Menu setup
local menuRoot = Menu.Create("Heroes", "Hero List", "Puck")
local globalGroup = menuRoot:Create("Auto Phase Shift"):Create("Global")
local mainGroup   = menuRoot:Create("Auto Phase Shift"):Create("Principal")

local cfg = {}
cfg.enabled          = globalGroup:Switch("Ativar Script", true, "\u{f058}")
cfg.logicEnabled     = mainGroup:Switch("Ativar Lógica", true, "\u{f00c}")
cfg.projectileNeeded = mainGroup:Slider("Mín Projéteis para Desviar", 1, 5, 1, "%d")
cfg.memorySeconds    = mainGroup:Slider("Memória de Projéteis (s)", 2, 10, 5, function(v) return string.format("%.1f", v/10) end) -- scaled (divide by 10)
cfg.cooldownSeconds  = mainGroup:Slider("Intervalo Mín Entre Uso (ms)", 300, 3000, 1200, "%d")
cfg.showOverlay      = mainGroup:Switch("Mostrar Overlay", true)
cfg.ignoreCreepProj  = mainGroup:Switch("Ignorar Projéteis de Creep", true)
cfg.ignoreHeroProj   = mainGroup:Switch("Ignorar Projéteis de Herói", false)
cfg.mode             = mainGroup:Combo("Modo de Detecção", {"Qualquer Projétil","Apenas Habilidades de Heróis"}, 0)
cfg.aoeChannelRadius = mainGroup:Slider("Raio de Canal AOE", 300, 1200, 600, "%d")
cfg.useAbilityList   = mainGroup:Switch("Usar Lista de Habilidades (canais)", false)

-- Internal state
local localHero = nil
local projectiles = {}    -- id -> {source=unit, time=time}
local genIdCounter = 0
local lastCastTime = 0
local attackHistory = {} -- source -> {times = {t1,t2,...}}
local channelStamp = 0
local prevReady = {} -- track previous ready state for cast detection

local function IsChanneling(unit)
	local f = NPC.IsChannelling or NPC.IsChanneling
	return f and f(unit)
end

local function GetHero()
	if not localHero then localHero = Heroes.GetLocal() end
	return localHero
end

local function IsPuck(hero)
	return hero and NPC.GetUnitName(hero) == "npc_dota_hero_puck"
end

local function MemoryWindow()
	-- Slider stores value 2..10, scale down (value/10) for seconds (0.2 .. 1.0)
	return cfg.memorySeconds:Get() / 10.0
end

local function CooldownWindow()
	return cfg.cooldownSeconds:Get() / 1000.0
end

local function ActiveProjectileCount(now)
	local count = 0
	local mem = MemoryWindow()
	for id, data in pairs(projectiles) do
		if (now - data.time) < mem then
			count = count + 1
		else
			projectiles[id] = nil
		end
	end
	return count
end

-- Load ability whitelist once
local abilityWhitelist = {}
do
	local path = "assets/abilities_whitelist.json"
	local f = io.open(path, "r")
	if f then
		local raw = f:read("*a"); f:close()
		local ok, decoded = pcall(function() return json and json.decode(raw) end)
		if ok and decoded and decoded.abilities then
			for _, name in ipairs(decoded.abilities) do
				abilityWhitelist[name] = true
			end
		else
			-- fallback manual parse (simple pattern) if json lib absent
			for a in raw:gmatch('"([%w_%-%d]+)"') do abilityWhitelist[a] = true end
		end
	end
end

function PuckAPS.OnProjectile(ev)
	local hero = GetHero(); if not hero or not IsPuck(hero) then return end
	if not cfg.enabled:Get() or not cfg.logicEnabled:Get() then return end
	if not Entity.IsAlive(hero) then return end
	local src = ev.source; local tgt = ev.target
	-- Filters requested: ignore creeps / ignore hero projectiles
	if src then
		if cfg.ignoreCreepProj:Get() and not NPC.IsHero(src) then return end
		if cfg.ignoreHeroProj:Get() and NPC.IsHero(src) then return end
	end
	-- Mode: Hero Abilities Only (0 = any, 1 = abilities only)
	if cfg.mode:Get() == 1 then
		-- Only consider projectiles from heroes, skip if source is attacking (likely auto-attack) or spam frequency
		if not (src and NPC.IsHero(src)) then return end
		if NPC.IsAttacking(src) then return end
		local now = GameRules.GetGameTime()
		attackHistory[src] = attackHistory[src] or {times = {}} 
		local tList = attackHistory[src].times
		-- prune old timestamps > 0.8s
		for i=#tList,1,-1 do if now - tList[i] > 0.8 then table.remove(tList,i) end end
		-- if more than 2 recent projectiles in <0.8s treat as attack spam
		if #tList >= 2 then return end
		table.insert(tList, now)
	end
	if tgt == hero and src and not Entity.IsSameTeam(hero, src) then
		local pid = ev.id
		if not pid or pid == 0 then
			genIdCounter = genIdCounter + 1
			pid = "gen" .. genIdCounter
		end
		projectiles[pid] = { source = src, time = GameRules.GetGameTime() }
	end
end

function PuckAPS.OnUpdate()
	if not cfg.enabled:Get() or not cfg.logicEnabled:Get() then return end
	local hero = GetHero(); if not hero or not IsPuck(hero) then return end
	if not Entity.IsAlive(hero) then return end
	local now = GameRules.GetGameTime()
	local count = ActiveProjectileCount(now)

	-- Sonic Wave (Queen of Pain) non-projectile linear wave detection
	-- Adds a pseudo projectile if Qop casts sonic wave facing Puck within width cone
	-- Recount after adding wave threats
	count = ActiveProjectileCount(now)
	-- Sonic Wave detection via modifier on Puck
	-- Debug: print all modifiers on Puck if hit by any new modifier
	local lastMods = PuckAPS._lastMods or {}
	local mods = {}
	for i=0,31 do
		local mod = NPC.GetModifierName(hero, i)
		if mod then mods[mod] = true end
	end
	for mod,_ in pairs(mods) do
		if not lastMods[mod] then
			print("[PuckAPS] Novo modificador na Puck:", mod)
		end
	end
	PuckAPS._lastMods = mods

	local sonicMod = "modifier_queenofpain_sonic_wave"
	if NPC.HasModifier(hero, sonicMod) then
		if not projectiles[sonicMod] then
			projectiles[sonicMod] = { source = hero, time = now }
			print("[PuckAPS] Sonic Wave modifier detected on Puck! Pseudo projectile injected.")
		end
	else
		projectiles[sonicMod] = nil
	end
	count = ActiveProjectileCount(now)
	-- Add pseudo events for channeling AOEs (mode 1 only)
	if cfg.mode:Get() == 1 then
		local radius = cfg.aoeChannelRadius:Get()
		for _, enemy in ipairs(Heroes.GetAll()) do
			if enemy ~= hero and Entity.IsAlive(enemy) and not Entity.IsSameTeam(hero, enemy) and NPC.IsHero(enemy) then
				if IsChanneling(enemy) then
					local dist = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(hero)):Length2D()
					if dist <= radius then
						-- treat channel as ability threat: inject once per channel cycle
						local key = "chan_" .. tostring(enemy)
						local allow = true
						if cfg.useAbilityList:Get() then
							allow = false
							-- scan abilities of enemy hero for any whitelisted channelling ability (name match)
							for i=0,23 do
								local ab = NPC.GetAbilityByIndex(enemy, i)
								if ab then
									local n = Ability.GetName(ab)
									if abilityWhitelist[n] then allow = true; break end
								end
							end
						end
						if allow and not projectiles[key] then
							projectiles[key] = { source = enemy, time = now }
						end
					end
				end
			end
		end
		count = ActiveProjectileCount(now) -- recount after pseudo additions
	end
	if count >= cfg.projectileNeeded:Get() then
		if (now - lastCastTime) >= CooldownWindow() then
			local phase = NPC.GetAbility(hero, "puck_phase_shift")
			if phase and Ability.IsReady(phase) then
				Ability.CastNoTarget(phase)
				lastCastTime = now
				projectiles = {}
			end
		end
	end
end

function PuckAPS.OnDraw()
	if not cfg.enabled:Get() or not cfg.showOverlay:Get() then return end
	local hero = GetHero(); if not IsPuck(hero) then return end
	local selected = Player.GetSelectedUnits(Players.GetLocal()) or {}
	local found = false
	for _,u in ipairs(selected) do if u == hero then found = true break end end
	if not found then return end
	local now = GameRules.GetGameTime()
	local count = ActiveProjectileCount(now)
	local font = Renderer.LoadFont("Arial", 16, Enum.FontCreate.FONTFLAG_OUTLINE)
	local x, y = 50, 260
	local lines = {
		"Puck Auto Phase Shift",
		string.format("Projectiles: %d / %d", count, cfg.projectileNeeded:Get()),
		string.format("Memory: %.1fs", MemoryWindow()),
		string.format("Ready In: %.1fs", math.max(0, CooldownWindow() - (now - lastCastTime))),
		"Mode: " .. (cfg.mode:Get()==0 and "Any" or "Abilities"),
		"AOE Radius: " .. tostring(cfg.aoeChannelRadius:Get()),
		"Whitelist: " .. (cfg.useAbilityList:Get() and ("ON (" .. tostring((function() local c=0 for _ in pairs(abilityWhitelist) do c=c+1 end return c end)()) .. ")") or "OFF")
	}
	local h = 18 * (#lines + 1)
	Renderer.FilledRect(Vec2(x, y), Vec2(x + 240, y + h), Color(20, 20, 20, 160), 6)
	Renderer.Text(font, 14, lines[1], Vec2(x + 10, y + 8), Color(150, 210, 255, 255))
	for i = 2, #lines do
		Renderer.Text(font, 12, lines[i], Vec2(x + 10, y + 8 + 16 * (i - 1)), Color(230, 230, 220, 255))
	end
end

function PuckAPS.OnScriptLoad() GetHero() end

return PuckAPS