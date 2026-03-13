--#region Menu

local settingsMenu = Menu.Create("Info Screen", "Main", "Damage Calculator", "Settings")

settingsMenu:Parent():Icon("\u{f1ec}")

local mainSettingsMenu = settingsMenu:Create("Main Settings")
local targetSettingsMenu = settingsMenu:Create("Target Settings")

local settings = {
	enable = mainSettingsMenu:Switch("Enable", true, "\u{f00c}"),
	offsetX = mainSettingsMenu:Slider("X Offset", -250, 250, 0),
	offsetY = mainSettingsMenu:Slider("Y Offset", -250, 250, 0),
	scale = mainSettingsMenu:Slider("Scale", 0.25, 3, 1, "%.2f"),

	lastSeenIntegration = targetSettingsMenu:Switch("Last Seen Position Integration", true, "\u{f3c5}"),
	ignoreTempResists = targetSettingsMenu:Switch("Ignore Temporary Resists", false, "\u{f6de}"),
}

settings.offsetX:Icon("\u{f0b2}")
settings.offsetY:Icon("\u{f0b2}")
settings.scale:Icon("\u{f424}")

settings.lastSeenIntegration:ToolTip("Display damage info above the last location hero seen")
settings.ignoreTempResists:ToolTip("Excludes some resists from the calculation to see the damage that can be dealt after the effect ends")

settings.ignoreTempResistsGear = settings.ignoreTempResists:Gear("Ignored Temporary Resists")

settings.ignoreBlackKingBar = settings.ignoreTempResistsGear:Switch(
	"Black King Bar",
	false,
	"panorama/images/items/black_king_bar_png.vtex_c"
)
settings.ignoreRepeal = settings.ignoreTempResistsGear:Switch(
	"Repeal",
	false,
	"panorama/images/spellicons/omniknight_repel_png.vtex_c"
)
settings.ignoreFrostShield = settings.ignoreTempResistsGear:Switch(
	"Frost Shield",
	false,
	"panorama/images/spellicons/lich_frost_shield_png.vtex_c"
)
settings.ignoreEnrage = settings.ignoreTempResistsGear:Switch(
	"Enrage",
	false,
	"panorama/images/spellicons/ursa_enrage_png.vtex_c"
)
settings.ignoreRage = settings.ignoreTempResistsGear:Switch(
	"Rage",
	false,
	"panorama/images/spellicons/life_stealer_rage_png.vtex_c"
)

settings.ignoreTempResists:SetCallback(function(self)
	settings.ignoreTempResistsGear:Visible(self:Get())
end)
settings.ignoreTempResistsGear:Visible(settings.ignoreTempResists:Get())

---@param switch CMenuSwitch
local function enableSwitchCallback(switch)
	local disabled = not switch:Get()

	for settingKey, settingElement in pairs(settings) do
		if (settingKey ~= "enable") then
			settingElement:Disabled(disabled)
		end
	end
end

enableSwitchCallback(settings.enable)

settings.enable:SetCallback(enableSwitchCallback)

--#endregion Menu

--#region LastSeenPosition

---@class LastSeenPosition
local lastSeenPotision = {
	switch = Menu.Find("Info Screen", "Main", "Show Me More", "Main", "Maphack", "Last Seen Position") --[[@as CMenuSwitch]],
	---@param self LastSeenPosition
	---@return boolean
	IsEnabled = function(self)
		return self.switch and self.switch:Get() or false
	end,
	duration = Menu.Find("Info Screen", "Main", "Show Me More", "Main", "Maphack", "Last Seen Position", "Last Seen Position", "Duration") --[[@as CMenuSliderInt]],
	---@param self LastSeenPosition
	---@return integer
	GetDuration = function(self)
		return self.duration and self.duration:Get() or 0
	end,
}
--#endregion LastSeenPosition

--#region Utils

---@class Utils
local utils = {
	---@type table<string, integer?>
	cachedIcons = {},

	---@param self Utils
	---@param abilityName string
	---@return integer
	GetAbilityIcon = function(self, abilityName)
		local cachedIcon = self.cachedIcons[abilityName]
		if (cachedIcon) then
			return cachedIcon
		end

		local icon = Render.LoadImage("panorama/images/spellicons/" .. abilityName .. "_png.vtex_c")

		return icon
	end,

	---@param hero userdata
	---@param facetName string
	---@return boolean
	heroHasFacet = function(hero, facetName)
		local heroFacets = Hero.GetFacetAbilities(hero)

		for i = 1, #heroFacets do
			local heroFacetName = Ability.GetName(heroFacets[i])

			if (heroFacetName == facetName) then
				return true
			end
		end

		return false
	end,

	---@param hero userdata
	---@param category string
	---@param itemName string
	isItemEnabled = function(hero, category, itemName)
		local heroDisplayName = Engine.GetDisplayNameByUnitName(NPC.GetUnitName(hero))

		if (not heroDisplayName) then
			return true
		end

		local itemsSection = Menu.Find(
			"Heroes",
			"Hero List",
			heroDisplayName,
			"Main Settings",
			"Items Settings",
			"Items Usage",
			"Items Usage",
			category
		) --[[@as CMenuMultiSelect]]

		return itemsSection:Get(itemName) or true
	end,

	---@param ability userdata
	---@param key string
	---@param levelOrGetLevel integer | boolean?
	getAbilityValue = function(ability, key, levelOrGetLevel)
		local abilityLevel = levelOrGetLevel

		if (type(levelOrGetLevel) == "boolean") then
			abilityLevel = Ability.GetLevel(ability) - 1
		elseif (type(levelOrGetLevel) ~= "number") then
			abilityLevel = nil
		end

		return Ability.GetLevelSpecialValueFor(
			ability, key, abilityLevel --[[@as number|nil]]
		) or 0
	end,

	---@param ability userdata
	---@return boolean
	isAbilityReady = function(ability)
		return Ability.CanBeExecuted(ability) == -1
	end,
	---@param ability userdata
	---@return boolean
	isAbilityAvailable = function(ability)
		return Ability.GetCooldown(ability) == 0.0
	end,
	---@param item userdata
	---@return boolean
	isItemReady = function(item)
		return Ability.IsReady(item)
	end,

	---@param totalMagicResist integer
	---@param additionalMagicResists integer
	---@return integer
	sumMagicResist = function(totalMagicResist, additionalMagicResists)
		return 1 - (1 - totalMagicResist) * (1 - additionalMagicResists)
	end,
	---@param totalMagicResist integer
	---@param additionalMagicResists integer
	---@return integer
	subMagicResist = function(totalMagicResist, additionalMagicResists)
		return 1 - (1 - totalMagicResist) / (1 - additionalMagicResists)
	end,
}
--#endregion Utils

--#region Eternal Shroud

---@class EternalShroudFields
---@
---@field comboInfo ComboInfo
---@
---@field heroResistWithout integer
---@field baseResist integer
---@
---@field maxStacks integer
---@field currentStacks integer
---@field freeStacks integer
---@field stackThreshold integer
---@field stackResist integer
---@
---@field retainedDamage integer

local eternalShroudStatsCache = {
	baseResist = 0,
	maxStacks = 0,
	stackThreshold = 0,
	stackResist = 0,
}

---@class EternalShroud : EternalShroudFields
local eternalShroudMethods = {}

eternalShroudMethods.addStack = function(self)
	self.currentStacks = math.min(self.maxStacks, self.currentStacks + 1)
	return self
end
---@param count integer
eternalShroudMethods.addStacks = function(self, count)
	self.currentStacks = math.min(self.maxStacks, self.currentStacks + count)
	return self
end
---@param damageValue integer
eternalShroudMethods.takeDamage = function(self, damageValue)
	damageValue = damageValue + self.retainedDamage

	local newStacks = math.floor(damageValue / eternalShroudStatsCache.stackThreshold)
	self.retainedDamage = damageValue % eternalShroudStatsCache.stackThreshold

	local previousStacks = self.currentStacks

	self:addStacks(newStacks)

	self.comboInfo.magicResist = utils.sumMagicResist(
		utils.subMagicResist(
			self.comboInfo.magicResist,
			eternalShroudStatsCache.baseResist + eternalShroudStatsCache.stackResist * previousStacks
		),
		eternalShroudStatsCache.baseResist + eternalShroudStatsCache.stackResist * self.currentStacks
	)

	return self
end

---@param comboInfo ComboInfo
---@return EternalShroud?
local function createEternalShroud(comboInfo)
	local target = comboInfo.target

	local shroudItem = NPC.GetItem(target, "item_eternal_shroud")

	if (not shroudItem) then
		return
	end

	if (eternalShroudStatsCache.baseResist == 0) then
		eternalShroudStatsCache = {
			baseResist = utils.getAbilityValue(shroudItem, "bonus_spell_resist") / 100,
			maxStacks = utils.getAbilityValue(shroudItem, "max_stacks"),
			stackThreshold = utils.getAbilityValue(shroudItem, "stack_threshold"),
			stackResist = utils.getAbilityValue(shroudItem, "stack_resist") / 100,
		}
	end

	local shroudModifier = NPC.GetModifier(target, "modifier_item_eternal_shroud")

	local currentShroudStacks = shroudModifier and Modifier.GetStackCount(shroudModifier) or 0

	---@type EternalShroudFields
	local shroud = {
		comboInfo = comboInfo,
		heroResistWithout = utils.isItemReady(shroudItem) and utils.subMagicResist(
			NPC.GetMagicalArmorValue(target),
			eternalShroudStatsCache.baseResist + eternalShroudStatsCache.stackResist * currentShroudStacks
		) or NPC.GetMagicalArmorValue(target),
		baseResist = eternalShroudStatsCache.baseResist,
		maxStacks = eternalShroudStatsCache.maxStacks,
		currentStacks = currentShroudStacks,
		freeStacks = eternalShroudStatsCache.maxStacks - currentShroudStacks,
		stackThreshold = eternalShroudStatsCache.stackThreshold,
		stackResist = eternalShroudStatsCache.stackResist,
		retainedDamage = 0,
	}

	return setmetatable(shroud, { __index = eternalShroudMethods }) --[[@as EternalShroud]]
end
--#endregion Shroud

--#region Gravekeepers Cloak

---@class Layer
---@
---@field isActive boolean
---@field recoveryTime integer

---@class GravekeepersCloakFields
---@
---@field comboInfo ComboInfo
---@
---@field maxLayers integer
---@
---@field layers Layer[]
---@
---@field damageThreshold integer
---@field damageReductionPerLayer integer
---@
---@field layerRecoveryTime integer

---@class GravekeepersCloak : GravekeepersCloakFields
local gravekeepersCloakMethods = {}

---@param damageValue integer
gravekeepersCloakMethods.HandleDamage = function(self, damageValue)
	if (damageValue < self.damageThreshold) then
		return damageValue
	end

	local activeLayersCount = 0

	local layerIsBroke = false

	for layerNum = 1, self.maxLayers do
		local layer = self.layers[layerNum]

		if (not layer.isActive and not self.comboInfo.isBreakApplied and self.comboInfo.comboDuration > layer.recoveryTime) then
			layer.isActive = true
			layer.recoveryTime = 0
		end

		if (layer.isActive) then
			activeLayersCount = activeLayersCount + 1

			if (not layerIsBroke) then
				layerIsBroke = true

				layer.isActive = false
				layer.recoveryTime = self.comboInfo.comboDuration + self.layerRecoveryTime
			end
		end
	end

	return damageValue * (1 - self.damageReductionPerLayer * activeLayersCount)
end

---@param comboInfo ComboInfo
local function createGravekeepersCloak(comboInfo)
	local target = comboInfo.target

	local gravekeepersCloakAbility = NPC.GetAbility(target, "visage_gravekeepers_cloak")
	if (not gravekeepersCloakAbility or Ability.GetLevel(gravekeepersCloakAbility) < 1) then
		return
	end

	local layers = {}

	---@type GravekeepersCloakFields
	local gravekeepersCloakFields = {
		comboInfo = comboInfo,

		maxLayers = utils.getAbilityValue(gravekeepersCloakAbility, "max_layers"),

		layers = layers,

		damageThreshold = utils.getAbilityValue(gravekeepersCloakAbility, "minimum_damage"),
		damageReductionPerLayer = utils.getAbilityValue(gravekeepersCloakAbility, "damage_reduction", true) / 100,

		layerRecoveryTime = utils.getAbilityValue(gravekeepersCloakAbility, "recovery_time", true),
	}

	for layerNum = 1, gravekeepersCloakFields.maxLayers do
		layers[layerNum] = {
			isActive = true,
			recoveryTime = 0,
		}
	end

	local gravekeepersCloak = setmetatable(gravekeepersCloakFields, { __index = gravekeepersCloakMethods }) --[[@as GravekeepersCloak]]

	return gravekeepersCloak
end

--#endregion Gravekeepers Cloak

--#region ComboInfo

--#region ComboInfoFields

---@class ComboInfoFields
---@
---@field cache {kayaLikeAmp: integer?, dispersionDamageMult: integer?, bristlebackDamageMult: integer?}
---@
---@field hero userdata
---@
---@field attackDamage integer
---@
---@field target userdata
---@field targetName string
---@
---@field isDead boolean
---@
---@field level integer
---@
---@field targetIsMedusa boolean
---@
---@field shroud EternalShroud?
---@
---@field spellAmp integer
---@
---@field health integer
---@field healthWithoutRefresher integer
---@
---@field maxHealth integer
---@field healthRegen integer
---@
---@field mana integer
---@field manaWithoutRefresher integer
---@
---@field maxMana integer
---@field manaRegen integer
---@
---@field armor integer
---@
---@field physResist integer
---@field magicResist integer
---@
---@field physDamageReductionMult integer?
---@field magicDamageReductionMult integer?
---@
---@field sharedBarrier integer
---@field sharedBarrierWithoutRefresher integer
---@field physBarrier integer
---@field physBarrierWithoutRefresher integer
---@field magicBarrier integer
---@field magicBarrierWithoutRefresher integer
---@
---@field physDamageBlock integer
---@
---@field jidiPollenBagDamage integer?
---@
---@field abilityOrder string[]
---@field abilityOrderWithoutRefresher string[]
---@
---@field comboDuration integer
---@field comboDurationWithoutRefresher integer
---@
---@field totalDamage integer
---@field totalDamageWithoutRefresher integer
---@
---@field divineRegaliaMult integer?
---@
---@field hasRefresher boolean
---@field refresherUsed boolean
---@
---@field isEtherealUsed boolean
---@
---@field isBreakApplied boolean
---@
---@field isPhylactaryLikeUsed boolean
---@field timeToRecoverPhylactaryLikeDamage integer
---@
---@field gravekeepersCloak GravekeepersCloak?

---@class ComboInfo : ComboInfoFields
local comboInfoMethods = {}
--#endregion ComboInfoFields

--#region ModifyArmorBy

---@param armor integer
comboInfoMethods.ModifyArmorBy = function(self, armor)
	local newArmor = self.armor + armor
	self.armor = newArmor

	self.physResist = (0.06 * newArmor) / (1 + 0.06 * math.abs(newArmor))

	return self
end
--#endregion ModifyArmorBy

--#region GetKayaLikeAmp

---@type {itemName: string, cachedAmp: integer?}[]
local kayaLikeItems = {
	{
		itemName = "item_kaya_and_sange",
	},
	{
		itemName = "item_yasha_and_kaya",
	},
	{
		itemName = "item_kaya",
	},
}

comboInfoMethods.GetKayaLikeAmp = function(self)
	if (self.cache.kayaLikeAmp) then
		return self.cache.kayaLikeAmp --[[@as integer]]
	end

	for i = 1, #kayaLikeItems do
		local kayaLikeItem = kayaLikeItems[i]

		local inventoryItem = NPC.GetItem(self.hero, kayaLikeItem.itemName)

		if (inventoryItem) then
			local kayaAmp = kayaLikeItem.cachedAmp

			if (not kayaLikeItem.cachedAmp) then
				kayaAmp = utils.getAbilityValue(inventoryItem, "spell_amp") / 100
				kayaLikeItem.cachedAmp = kayaAmp
			end

			self.cache.kayaLikeAmp = kayaAmp

			return kayaAmp
		end
	end

	return 0
end
--#endregion GetKayaLikeAmp

--#region ApplyArmorReductions

---@type {blightStone: integer?, orbOfCorrosion: integer?, desolator: integer?, assaultCuirass: integer?}
local armorReductionCache = {}

comboInfoMethods.ApplyArmorReductions = function(self)
	local blightStone = NPC.GetItem(self.hero, "item_blight_stone")
	if (blightStone) then
		if (not NPC.HasModifier(self.target, "modifier_blight_stone_buff")) then
			local armorReduction = armorReductionCache.blightStone

			if (not armorReduction) then
				armorReduction = utils.getAbilityValue(blightStone, "corruption_armor")
				armorReductionCache.blightStone = armorReduction
			end

			self:ModifyArmorBy(armorReduction)
		end
	end

	local orbOfCorrosion = NPC.GetItem(self.hero, "item_orb_of_corrosion")
	if (orbOfCorrosion) then
		if (not NPC.HasModifier(self.target, "modifier_orb_of_corrosion_debuff")) then
			local armorReduction = armorReductionCache.orbOfCorrosion

			if (not armorReduction) then
				armorReduction = utils.getAbilityValue(orbOfCorrosion, "corruption_armor")
				armorReductionCache.orbOfCorrosion = armorReduction
			end

			self:ModifyArmorBy(armorReduction)
		end
	end

	local desolator = NPC.GetItem(self.hero, "item_desolator")
	if (desolator) then
		if (not NPC.HasModifier(self.target, "modifier_desolator_buff")) then
			local armorReduction = armorReductionCache.desolator

			if (not armorReduction) then
				armorReduction = utils.getAbilityValue(desolator, "corruption_armor")
				armorReductionCache.desolator = armorReduction
			end

			self:ModifyArmorBy(armorReduction)
		end
	end

	local stygianDesolator = NPC.GetItem(self.hero, "item_desolator_2")
	if (stygianDesolator) then
		if (not NPC.HasModifier(self.target, "modifier_desolator_2_buff")) then
			self:ModifyArmorBy(utils.getAbilityValue(stygianDesolator, "corruption_armor"))
		end
	end

	local assaultCuirass = NPC.GetItem(self.hero, "item_assault")
	if (assaultCuirass) then
		if (not NPC.HasModifier(self.target, "modifier_item_assault_negative_armor")) then
			local armorReduction = armorReductionCache.blightStone

			if (not armorReduction) then
				armorReduction = utils.getAbilityValue(assaultCuirass, "aura_negative_armor")
				armorReductionCache.blightStone = armorReduction
			end

			self:ModifyArmorBy(armorReduction)
		end
	end
end
--#endregion ApplyArmorReductions

--#region GetBaseSpellAmp

comboInfoMethods.GetBaseSpellAmp = function(self)
	return 1 + NPC.GetBaseSpellAmp(self.hero) / 100 + self:GetKayaLikeAmp()
end
--#endregion GetBaseSpellAmp

--#region Magic Resist Math

---@param magicResistToAdd integer
comboInfoMethods.SumMagicResist = function(self, magicResistToAdd)
	self.magicResist = utils.sumMagicResist(self.magicResist, magicResistToAdd)

	return self
end

---@param magicResistToSub integer
comboInfoMethods.SubMagicResist = function(self, magicResistToSub)
	self.magicResist = utils.subMagicResist(self.magicResist, magicResistToSub)

	return self
end
--#endregion Magic Resist Math

--#region Hero Handlers

---@type {absorptionPerc: integer, baseDamagePerMana: integer, damagePerManaPerLevel: integer}?
local medusaManaShieldCache

local function createMedusaManaShieldCache(medusaHero)
	if (medusaManaShieldCache) then
		return medusaManaShieldCache
	end

	local manaShield = NPC.GetAbility(medusaHero, "medusa_mana_shield")

	medusaManaShieldCache = {
		absorptionPerc = manaShield and (utils.getAbilityValue(manaShield, "absorption_pct") / 100) or 0,
		baseDamagePerMana = manaShield and utils.getAbilityValue(manaShield, "damage_per_mana") or 0,
		damagePerManaPerLevel = manaShield and utils.getAbilityValue(manaShield, "damage_per_mana_per_level") or 0,
	}

	return medusaManaShieldCache
end

---@type table<string, (fun(self: ComboInfo, damageValue: integer): integer)?>
local heroDamageHandlers = {
	["npc_dota_hero_medusa"] = function(self, damageValue)
		if (self.mana <= 0 or self.health <= 0) then
			return damageValue
		end

		if (not medusaManaShieldCache) then
			medusaManaShieldCache = createMedusaManaShieldCache(self.target)
		end

		local manaDamage = damageValue * medusaManaShieldCache.absorptionPerc

		local damageCanBeTakenPerMana = medusaManaShieldCache.baseDamagePerMana
			+ medusaManaShieldCache.damagePerManaPerLevel * self.level

		local manaShieldCanTakeDamage = self.mana * damageCanBeTakenPerMana

		if (manaDamage > manaShieldCanTakeDamage) then
			self.mana = 0

			self.totalDamage = self.totalDamage + manaShieldCanTakeDamage

			return (manaDamage - manaShieldCanTakeDamage)
				/ medusaManaShieldCache.absorptionPerc
				+ damageValue * (1 - medusaManaShieldCache.absorptionPerc)
		else
			self.mana = math.max(0, self.mana - manaDamage / damageCanBeTakenPerMana)

			self.totalDamage = self.totalDamage + manaDamage

			return damageValue * (1 - medusaManaShieldCache.absorptionPerc)
		end
	end,
	["npc_dota_hero_bristleback"] = function(self, damageValue)
		if (self.isBreakApplied) then
			return damageValue
		end

		local cachedMult = self.cache.bristlebackDamageMult

		if (cachedMult) then
			return damageValue * cachedMult
		end

		local bristleback = NPC.GetAbility(self.target, "bristleback_bristleback")
		if (not bristleback or Ability.GetLevel(bristleback) < 1) then
			return damageValue
		end

		local bristlebackDamageMult = 1 - utils.getAbilityValue(bristleback, "back_damage_reduction", true) / 100

		self.cache.bristlebackDamageMult = bristlebackDamageMult

		return damageValue * bristlebackDamageMult
	end,
	["npc_dota_hero_spectre"] = function(self, damageValue)
		if (self.isBreakApplied) then
			return damageValue
		end

		local cachedMult = self.cache.dispersionDamageMult

		if (cachedMult) then
			return damageValue * cachedMult
		end

		local dispersion = NPC.GetAbility(self.target, "spectre_dispersion")
		if (not dispersion or Ability.GetLevel(dispersion) < 1) then
			return damageValue
		end

		local dispersionDamageMult = 1 - utils.getAbilityValue(dispersion, "damage_reflection_pct", true) / 100

		self.cache.dispersionDamageMult = dispersionDamageMult

		return damageValue * dispersionDamageMult
	end,
	["npc_dota_hero_visage"] = function(self, damageValue)
		if (not self.gravekeepersCloak) then
			return damageValue
		end

		return self.gravekeepersCloak:HandleDamage(damageValue)
	end,
}
--#endregion Hero Damage Handlers

--#region Deal Damage

---@param damageValue integer
comboInfoMethods.DealPhysDamage = function(self, damageValue)
	if (self.divineRegaliaMult) then
		damageValue = damageValue * self.divineRegaliaMult
	end

	if (self.physDamageBlock > damageValue) then
		return self
	end

	damageValue = damageValue - self.physDamageBlock

	if (self.physDamageReductionMult) then
		if (self.physDamageReductionMult <= 0) then
			return self
		end

		damageValue = damageValue * self.physDamageReductionMult
	end

	local heroDamageHandler = heroDamageHandlers[self.targetName]
	if (heroDamageHandler) then
		damageValue = heroDamageHandler(self, damageValue)
	end

	damageValue = damageValue * (1 - self.physResist)

	self.totalDamage = self.totalDamage + damageValue

	if (self.physBarrier > 0) then
		local barrierDamage = math.min(damageValue, self.physBarrier)

		self.physBarrier = self.physBarrier - barrierDamage
		damageValue = damageValue - barrierDamage

		if (damageValue == 0) then
			return self
		end
	end

	if (self.sharedBarrier > 0) then
		local barrierDamage = math.min(damageValue, self.sharedBarrier)

		self.sharedBarrier = self.sharedBarrier - barrierDamage
		damageValue = damageValue - barrierDamage

		if (damageValue == 0) then
			return self
		end
	end

	self.health = self.health - damageValue

	if (self.health <= 0) then
		self.isDead = true
	end
end

comboInfoMethods.Attack = function(self)
	return self:DealPhysDamage(self.attackDamage)
end

---@param damageValue integer
---@param ignoreSpellAmp boolean?
---@param isPureDamage boolean?
---@param ignoreBarriers boolean?
---@param ignoreShroud boolean?
comboInfoMethods.DealMagicDamage = function(self, damageValue, ignoreSpellAmp, isPureDamage, ignoreBarriers, ignoreShroud)
	if (self.divineRegaliaMult) then
		damageValue = damageValue * self.divineRegaliaMult
	end

	if (not ignoreSpellAmp) then
		damageValue = damageValue * self.spellAmp
	end

	-- pure damage triggers shroud
	-- shroud stacks applies before any damage manipulations
	if (self.shroud and not ignoreShroud) then
		self.shroud:takeDamage(damageValue)
	end

	if (self.magicDamageReductionMult) then
		if (self.magicDamageReductionMult <= 0) then
			return self
		end

		damageValue = damageValue * self.magicDamageReductionMult
	end

	local heroDamageHandler = heroDamageHandlers[self.targetName]
	if (heroDamageHandler) then
		damageValue = heroDamageHandler(self, damageValue)
	end

	if (not isPureDamage) then
		damageValue = damageValue * (1 - self.magicResist)
	end

	self.totalDamage = self.totalDamage + damageValue

	if (not ignoreBarriers) then
		if (not isPureDamage and self.magicBarrier > 0) then
			local barrierDamage = math.min(damageValue, self.magicBarrier)

			self.magicBarrier = self.magicBarrier - barrierDamage
			damageValue = damageValue - barrierDamage

			if (damageValue == 0) then
				return self
			end
		end

		if (self.sharedBarrier > 0) then
			local barrierDamage = math.min(damageValue, self.sharedBarrier)

			self.sharedBarrier = self.sharedBarrier - barrierDamage
			damageValue = damageValue - barrierDamage

			if (damageValue == 0) then
				return self
			end
		end
	end

	self.health = self.health - damageValue

	if (self.health <= 0) then
		self.isDead = true
	end

	return self
end
--#endregion Deal Damage

--#region PushComboOrder
---@param abilityName string
comboInfoMethods.PushComboOrder = function(self, abilityName)
	table.insert(self.abilityOrder, abilityName)

	return self
end
--#endregion PushComboOrder

--#region IncComboDuration

---@param incValue integer | userdata
---@param includeModifiers boolean?
comboInfoMethods.IncComboDuration = function(self, incValue, includeModifiers)
	---@type integer
	local incValueNum = type(incValue) == "number"
		and incValue
		or Ability.GetCastPoint(incValue --[[@as userdata]], not includeModifiers and true or false)

	local oldComboDuration = self.comboDuration
	self.comboDuration = self.comboDuration + incValueNum

	if (not self.isDead) then
		self.health = math.min(self.maxHealth, self.health + self.healthRegen * incValue)
		self.mana = math.min(self.maxMana, self.mana + self.manaRegen * incValue)
	end

	if (self.jidiPollenBagDamage) then
		local oldComboDurationFloored = math.floor(oldComboDuration)
		local comboDurationFloored = math.floor(self.comboDuration)

		if (oldComboDurationFloored ~= comboDurationFloored) then
			self:DealMagicDamage(self.jidiPollenBagDamage * (comboDurationFloored - oldComboDurationFloored))
		end
	end

	return incValueNum
end
--#endregion IncComboDuration

--#region Combo Items

local ETHEREAL_BLADE_COMBO_DURATION = .35

local etherealBladeAttributes = {
	[Enum.Attributes.DOTA_ATTRIBUTE_STRENGTH] = Hero.GetStrengthTotal,
	[Enum.Attributes.DOTA_ATTRIBUTE_AGILITY] = Hero.GetAgilityTotal,
	[Enum.Attributes.DOTA_ATTRIBUTE_INTELLECT] = Hero.GetIntellectTotal,
	---@param target userdata
	[Enum.Attributes.DOTA_ATTRIBUTE_ALL] = function(target)
		return (Hero.GetStrengthTotal(target)
			+ Hero.GetAgilityTotal(target)
			+ Hero.GetIntellectTotal(target)) * .45
	end,
}

comboInfoMethods.TryEtherealBlade = function(self)
	if (not utils.isItemEnabled(self.hero, "Semi-Important Items", "item_ethereal_blade")) then
		return false
	end

	local etherealBlade = NPC.GetItem(self.hero, "item_ethereal_blade")

	if (not etherealBlade or (not utils.isItemReady(etherealBlade) and not self.refresherUsed)) then
		return false
	end

	local attribuneFunc = etherealBladeAttributes[Hero.GetPrimaryAttribute(self.target)]

	if (not attribuneFunc) then
		return false
	end

	if (not NPC.HasModifier(self.target, "modifier_ghost_state") and not self.isEtherealUsed) then
		self:SumMagicResist(-(utils.getAbilityValue(etherealBlade, "ethereal_damage_bonus") * -1 / 100))
	end

	local damage = (
		utils.getAbilityValue(etherealBlade, "blast_agility_multiplier") * attribuneFunc(self.target)
		+ utils.getAbilityValue(etherealBlade, "blast_damage_base")
	)

	self:DealMagicDamage(damage)
	self.isEtherealUsed = true

	return true
end

---@type {itemName: string, cachedDamage: integer?}[]
local dagonLevelItems = {
	{
		itemName = "item_dagon",
	},
	{
		itemName = "item_dagon_2",
	},
	{
		itemName = "item_dagon_3",
	},
	{
		itemName = "item_dagon_4",
	},
	{
		itemName = "item_dagon_5",
	},
}

comboInfoMethods.TryDagon = function(self)
	if (not utils.isItemEnabled(self.hero, "Semi-Important Items", "item_dagon")) then
		return false
	end

	for i = 5, 1, -1 do
		local dagonItem = dagonLevelItems[i]

		local inventoryItem = NPC.GetItem(self.hero, dagonItem.itemName)

		if (inventoryItem and (self.refresherUsed or utils.isAbilityReady(inventoryItem))) then
			local damage = dagonItem.cachedDamage

			if (not damage) then
				damage = utils.getAbilityValue(inventoryItem, "damage", i)
				dagonItem.cachedDamage = damage
			end

			self:DealMagicDamage(damage)

			return true
		end
	end

	return false
end

comboInfoMethods.TryCripplingCrossbow = function(self)
	if (not utils.isItemEnabled(self.hero, "Semi-Important Items", "item_crippling_crossbow")) then
		return false
	end

	local cripplingCrossbow = NPC.GetItem(self.hero, "item_crippling_crossbow")

	if (cripplingCrossbow and (self.refresherUsed or utils.isAbilityReady(cripplingCrossbow))) then
		self:DealMagicDamage(utils.getAbilityValue(cripplingCrossbow, "damage"))

		self.healthRegen = self.healthRegen * (1 - utils.getAbilityValue(cripplingCrossbow, "heal_reduce") / 100)

		return true
	end

	return false
end

comboInfoMethods.TryJidiPollenBag = function(self)
	if (not utils.isItemEnabled(self.hero, "Semi-Important Items", "item_jidi_pollen_bag")) then
		return false
	end

	local jidiPollenBag = NPC.GetItem(self.hero, "item_jidi_pollen_bag")

	if (jidiPollenBag and (self.refresherUsed or utils.isAbilityReady(jidiPollenBag))) then
		self.jidiPollenBagDamage = self.maxHealth * utils.getAbilityValue(jidiPollenBag, "hp_damage") / 100

		self.healthRegen = self.healthRegen * (1 - utils.getAbilityValue(jidiPollenBag, "health_regen_loss") / 100)

		return true
	end

	return false
end

---@type {itemName: string, cachedDamage: integer?}[]
local phylacteryLikeItems = {
	{
		itemName = "item_angels_demise",
	},
	{
		itemName = "item_phylactery",
	},
}

comboInfoMethods.TryPhylacteryLike = function(self)
	if (self.isPhylactaryLikeUsed) then
		return false
	end

	for i = 1, #phylacteryLikeItems do
		local phylacteryLikeItem = phylacteryLikeItems[i]
		local inventoryItem = NPC.GetItem(self.hero, phylacteryLikeItem.itemName)

		if (inventoryItem and (self.refresherUsed or utils.isItemReady(inventoryItem))) then
			local damage = phylacteryLikeItem.cachedDamage

			if (not damage) then
				damage = utils.getAbilityValue(inventoryItem, "bonus_spell_damage")
				phylacteryLikeItem.cachedDamage = damage
			end

			local oldHealth = self.health

			self:DealMagicDamage(damage)
			self.isPhylactaryLikeUsed = true
			self.isBreakApplied = phylacteryLikeItem.itemName == "item_angels_demise"

			self.timeToRecoverPhylactaryLikeDamage = (oldHealth - self.health) / self.healthRegen

			return true
		end
	end

	return false
end
--#endregion Combo Items

--#region Refresher Methods

comboInfoMethods.SaveWithoutRefresherInfo = function(self)
	self.healthWithoutRefresher = self.health
	self.manaWithoutRefresher = self.mana

	self.sharedBarrierWithoutRefresher = self.sharedBarrier
	self.physBarrierWithoutRefresher = self.physBarrier
	self.magicBarrierWithoutRefresher = self.magicBarrier

	local abilityOrder = self.abilityOrder
	for abilityNum = 1, #abilityOrder do
		table.insert(self.abilityOrderWithoutRefresher, abilityOrder[abilityNum])
	end

	self.comboDurationWithoutRefresher = self.comboDuration

	self.totalDamageWithoutRefresher = self.totalDamage

	return self
end

comboInfoMethods.TryRefresher = function(self)
	if (not self.hasRefresher) then
		return false
	end

	self.refresherUsed = true

	self.isPhylactaryLikeUsed = false
	self.timeToRecoverPhylactaryLikeDamage = 0

	return true
end
--#endregion Refresher Methods

--#region Combo Info Creation

-- idk
local repelModifiersBlacklist = {
	["modifier_nyx_assassin_jolt_damage_tracker"] = true,
	["modifier_nyx_assassin_nyxth_sense_effect"] = true,
	-- ["Modifier_VengefulSpirit_Revenge_Tracker"]
}

---@param hero userdata
---@param target userdata
---@return ComboInfo
local function createComboInfo(hero, target)
	local targetName = Entity.GetUnitName(target)

	local barriers = NPC.GetBarriers(target)

	local initialHealth = Entity.GetHealth(target)
	local initialMana = NPC.GetMana(target)

	local initialSharedBarrier = 0
	local initialPhysicBarrier = 0
	local initialMagicBarrier = 0

	if (barriers) then
		initialSharedBarrier = barriers.all.current or 0
		initialPhysicBarrier = barriers.physical.current or 0
		initialMagicBarrier = barriers.magic.current or 0
	end

	local divineRegaliaMult
	if (NPC.HasModifier(hero, "modifier_item_divine_regalia")) then
		local divineRegalia = NPC.GetItem(hero, "item_divine_regalia")

		if (divineRegalia) then
			divineRegaliaMult = 1 + utils.getAbilityValue(divineRegalia, "outgoing_damage") / 100
		end
	end

	local magicResist = NPC.GetMagicalArmorValue(target)

	local blackKingBarModifier = NPC.GetModifier(target, "modifier_black_king_bar_immune")
	if (blackKingBarModifier and (settings.ignoreTempResists:Get() and settings.ignoreBlackKingBar:Get())) then
		local blackKingBar = NPC.GetItem(target, "item_black_king_bar")
		local blackKingBarMagicResist = blackKingBar and (utils.getAbilityValue(blackKingBar, "magic_resist", true) / 100) or 0

		if (blackKingBarMagicResist ~= 0) then
			magicResist = utils.subMagicResist(magicResist, blackKingBarMagicResist)
		end
	end

	local maxHealth = Entity.GetMaxHealth(target)
	local healthRegen = NPC.GetHealthRegen(target)

	local repelModifier = NPC.GetModifier(target, "modifier_omniknight_martyr")
	if (repelModifier and (settings.ignoreTempResists:Get() and settings.ignoreRepeal:Get())) then
		local caster = Modifier.GetCaster(repelModifier)
		if (caster) then
			local repel = NPC.GetAbility(caster, "omniknight_martyr")
			if (repel) then
				local repelMagicResist = utils.getAbilityValue(repel, "magic_resist", true) / 100

				magicResist = utils.subMagicResist(magicResist, repelMagicResist)

				local repelStrengthAndRegenPerDebuff = utils.getAbilityValue(repel, "strength_bonus", true)

				local debuffsCount = 0

				-- client-side value is not updated when new debuff appear
				-- local debuffsCount = Modifier.GetField(repelModifier, "nDebuffAmount") or 0

				local modifiers = NPC.GetModifiers(target)

				for modifierNum = 1, #modifiers do
					local modifier = modifiers[modifierNum]

					if (Modifier.IsDebuff(modifier) and not repelModifiersBlacklist[Modifier.GetName(modifier)]) then
						debuffsCount = debuffsCount + 1
					end
				end

				-- print(Modifier.GetAttributes(repelModifier))
				-- print(Modifier.GetStackCount(repelModifier))
				-- print(Modifier.GetState(repelModifier))

				-- print(Modifier.(repelModifier))

				-- for k, v in pairs(Enum.ModifierState) do
				-- 	table.insert(statesToCheck, v)
				-- end

				-- local states = NPC.GetStatesDuration(target, statesToCheck)

				-- print(states)

				-- local modifiers = NPC.GetModifiers(target)

				-- for modifierNum = 1, #modifiers do
				-- 	local modifier = modifiers[modifierNum]

				-- 	-- Enum.ModifierState.

				-- 	if (Modifier.IsDebuff(modifier) and not Ability.IsInnate(Modifier.GetAbility(modifier))) then
				-- 		print(Modifier.GetName(modifier))
				-- 		local enabled, _ = Modifier.GetState(modifier)
				-- 		local mod_is_root = (enabled >> Enum.ModifierState.MODIFIER_STATE_ROOTED & 1) > 0
				-- 		print(mod_is_root)
				-- 		debuffsCount = debuffsCount + 1
				-- 	end
				-- end

				-- print(NPC.GetModifierProperty(target, Enum.ModifierFunction.MODIFIER_PROPERTY_FORCE_MAX_HEALTH))
				-- print(NPC.GetModifierProperty(target, Enum.ModifierFunction.MODIFIER_PROPERTY_HEALTH_BONUS))
				-- print(NPC.GetModifierProperty(target, Enum.ModifierFunction.MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS))

				-- print(Modifier.GetField(repelModifier, "strength_bonus"))

				local repelStrength = utils.getAbilityValue(repel, "base_strength", true) + repelStrengthAndRegenPerDebuff * debuffsCount
				local repelHealthRegen = utils.getAbilityValue(repel, "base_hpregen", true) + repelStrengthAndRegenPerDebuff * debuffsCount

				initialHealth = initialHealth - repelStrength * 22
				maxHealth = maxHealth - repelStrength * 22
				healthRegen = healthRegen - repelHealthRegen - repelStrength * .1
			end
		end
	end

	local physDamageReductionMult, magicDamageReductionMult

	local frostShieldModifier = NPC.GetModifier(target, "modifier_lich_frost_shield")
	if (frostShieldModifier and not (settings.ignoreTempResists:Get() or settings.ignoreFrostShield:Get())) then
		local caster = Modifier.GetCaster(frostShieldModifier)
		if (caster) then
			local frostShield = NPC.GetAbility(caster, "lich_frost_shield")
			local frostShieldDamageReductionMult = frostShield
				and (utils.getAbilityValue(frostShield, "damage_reduction", true) / 100)
				or 0

			if (frostShieldDamageReductionMult ~= 0) then
				physDamageReductionMult = (physDamageReductionMult or 1) - frostShieldDamageReductionMult
			end
		end
	end

	if (targetName == "npc_dota_hero_ursa") then
		if (NPC.HasModifier(target, "modifier_ursa_enrage") and not (settings.ignoreTempResists:Get() or settings.ignoreEnrage:Get())) then
			local enrage = NPC.GetAbility(target, "ursa_enrage")
			local enrageDamageMult = enrage
				and (utils.getAbilityValue(enrage, "damage_reduction") / 100)
				or 0

			if (enrageDamageMult) then
				physDamageReductionMult = (physDamageReductionMult or 1) - enrageDamageMult
				magicDamageReductionMult = (magicDamageReductionMult or 1) - enrageDamageMult
			end
		end
	elseif (targetName == "npc_dota_hero_life_stealer") then
		local rageModifier = NPC.GetModifier(target, "modifier_life_stealer_rage")
		if (rageModifier and (settings.ignoreTempResists:Get() and settings.ignoreRage:Get())) then
			local rageMagicResist = Modifier.GetField(rageModifier, "magic_resist") or 0

			if (rageMagicResist ~= 0) then
				magicResist = utils.subMagicResist(magicResist, rageMagicResist / 100)
			end
		end
	end

	---@type ComboInfo
	local comboInfoFields = {
		cache                             = {},

		hero                              = hero,

		attackDamage                      = NPC.GetTrueDamage(hero),

		target                            = target,
		targetName                        = targetName,

		isRanged                          = NPC.IsRanged(target),

		isDead                            = false,

		level                             = NPC.GetCurrentLevel(target),

		targetIsMedusa                    = targetName == "npc_dota_hero_medusa",

		shroud                            = nil,

		spellAmp                          = 0,

		health                            = initialHealth,
		healthWithoutRefresher            = initialHealth,

		maxHealth                         = maxHealth,
		healthRegen                       = healthRegen,

		mana                              = initialMana,
		manaWithoutRefresher              = initialMana,

		maxMana                           = NPC.GetMaxMana(target),
		manaRegen                         = NPC.GetManaRegen(target),

		armor                             = NPC.GetPhysicalArmorValue(target, false),

		physResist                        = NPC.GetPhysicalDamageReduction(target),
		magicResist                       = magicResist,

		physDamageReductionMult           = physDamageReductionMult,
		magicDamageReductionMult          = magicDamageReductionMult,

		sharedBarrier                     = initialSharedBarrier,
		sharedBarrierWithoutRefresher     = initialSharedBarrier,
		physBarrier                       = initialPhysicBarrier,
		physBarrierWithoutRefresher       = initialPhysicBarrier,
		magicBarrier                      = initialMagicBarrier,
		magicBarrierWithoutRefresher      = initialMagicBarrier,

		-- https://dota2.fandom.com/wiki/Damage_Block#Physical_Damage_Block
		physDamageBlock                   = NPC.IsRanged(target) and 0 or 16,

		abilityOrder                      = {},
		abilityOrderWithoutRefresher      = {},

		comboDuration                     = 0,
		comboDurationWithoutRefresher     = 0,

		totalDamage                       = 0,
		totalDamageWithoutRefresher       = 0,

		divineRegaliaMult                 = divineRegaliaMult,

		hasRefresher                      = false,
		refresherUsed                     = false,

		isEtherealUsed                    = false,

		isBreakApplied                    = NPC.HasModifier(hero, "modifier_item_silver_edge_windwalk")
			or (
				NPC.HasItem(hero, "item_silver_edge")
				and utils.isItemReady(NPC.GetItem(hero, "item_silver_edge") --[[@as userdata]])
			),

		isPhylactaryLikeUsed              = false,
		timeToRecoverPhylactaryLikeDamage = 0,
	}

	local comboInfo = setmetatable(comboInfoFields, { __index = comboInfoMethods }) --[[@as ComboInfo]]

	comboInfo.shroud = createEternalShroud(comboInfo)

	if (comboInfo.targetName == "npc_dota_hero_visage") then
		comboInfo.gravekeepersCloak = createGravekeepersCloak(comboInfo)
	end

	comboInfo.spellAmp = comboInfo:GetBaseSpellAmp()

	return comboInfo
end
--#endregion Combo Info Creation
--#endregion ComboInfo

--#region Hero Calculators

---@alias HeroComboCalculator fun(self: ComboInfo): ComboInfo

---@type table<string, HeroComboCalculator | nil>
local heroComboCalculators = {}

--#region Skywrath Mage
heroComboCalculators["npc_dota_hero_skywrath_mage"] = function(self)
	local hero = self.hero
	local hasRefresher = self.hasRefresher

	local arcaneBolt = NPC.GetAbility(hero, "skywrath_mage_arcane_bolt")
	arcaneBolt = arcaneBolt and Ability.GetLevel(arcaneBolt) > 0 and arcaneBolt or nil
	local arcaneBoltIsReady = false
	---@type integer, integer
	local arcaneBoltDamage, arcaneBoltCastPoint
	if (arcaneBolt) then
		arcaneBoltIsReady = utils.isAbilityReady(arcaneBolt)
		arcaneBoltDamage = utils.getAbilityValue(arcaneBolt, "bolt_damage", true)
			+ utils.getAbilityValue(arcaneBolt, "int_multiplier", true)
			* Hero.GetIntellectTotal(hero)
		arcaneBoltCastPoint = arcaneBolt and Ability.GetCastPoint(arcaneBolt)
	end

	local concussiveShot = NPC.GetAbility(hero, "skywrath_mage_concussive_shot")
	concussiveShot = concussiveShot and Ability.GetLevel(concussiveShot) > 0 and concussiveShot or nil
	local concussiveShotIsReady = false
	---@type integer
	local concussiveShotDamage
	if (concussiveShot) then
		concussiveShotIsReady = utils.isAbilityReady(concussiveShot)
		concussiveShotDamage = utils.getAbilityValue(concussiveShot, "damage", true)
	end

	local ancientSeal = NPC.GetAbility(hero, "skywrath_mage_ancient_seal")
	ancientSeal = ancientSeal and Ability.GetLevel(ancientSeal) > 0 and ancientSeal or nil
	local ancientSealIsReady = false
	---@type integer
	local ancientSealMagicResistReduction,
	ancientSealCastPoint
	if (ancientSeal) then
		ancientSealIsReady = utils.isAbilityReady(ancientSeal)
		ancientSealMagicResistReduction = utils.getAbilityValue(ancientSeal, "resist_debuff", true) / 100
		ancientSealCastPoint = Ability.GetCastPoint(ancientSeal)
	end

	local mysticFlare = NPC.GetAbility(hero, "skywrath_mage_mystic_flare")
	mysticFlare = mysticFlare and Ability.GetLevel(mysticFlare) > 0 and mysticFlare or nil
	local mysticFlareIsReady = false
	local mysticFlareDamageTicksCount = 19
	---@type integer, integer, integer
	local mysticFlareDamagePerTick, mysticFlareCastPoint, mysticFlareDuration
	if (mysticFlare) then
		mysticFlareIsReady = utils.isAbilityReady(mysticFlare)
		-- sometimes mystic flare deals damage 19 times instead 20
		mysticFlareDamagePerTick = utils.getAbilityValue(mysticFlare, "damage", true) / (mysticFlareDamageTicksCount + 1)
		mysticFlareCastPoint = Ability.GetCastPoint(mysticFlare)
		mysticFlareDuration = utils.getAbilityValue(mysticFlare, "duration")
	end

	if (ancientSealIsReady) then
		self:PushComboOrder("skywrath_mage_ancient_seal")

		self:TryPhylacteryLike()

		if (not NPC.HasModifier(self.target, "modifier_skywrath_mage_ancient_seal")) then
			self:SumMagicResist(ancientSealMagicResistReduction)
		end
	end

	if (self:TryEtherealBlade() and self.isPhylactaryLikeUsed) then
		self:IncComboDuration(math.min(ETHEREAL_BLADE_COMBO_DURATION, self.timeToRecoverPhylactaryLikeDamage))
	end

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (arcaneBoltIsReady) then
		self:PushComboOrder("skywrath_mage_arcane_bolt")
		self:IncComboDuration(arcaneBoltCastPoint)

		self:TryPhylacteryLike()

		self:DealMagicDamage(arcaneBoltDamage)
	end

	if (concussiveShotIsReady) then
		self:PushComboOrder("skywrath_mage_concussive_shot")
		self:DealMagicDamage(concussiveShotDamage)
	end

	if (mysticFlareIsReady) then
		self:PushComboOrder("skywrath_mage_mystic_flare")
		self:IncComboDuration(mysticFlareCastPoint)

		for _ = 1, mysticFlareDamageTicksCount do
			self:DealMagicDamage(mysticFlareDamagePerTick)
		end

		if (not hasRefresher) then
			self:IncComboDuration(mysticFlareDuration)
		end
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		if (ancientSeal) then
			self:TryPhylacteryLike()

			if (not ancientSealIsReady and not NPC.HasModifier(self.target, "modifier_skywrath_mage_ancient_seal")) then
				self:SumMagicResist(ancientSealMagicResistReduction)
			end

			if (not ancientSealIsReady) then
				self:IncComboDuration(ancientSealCastPoint)
			end
		end

		self:TryEtherealBlade()

		self:TryDagon()
		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()

		if (arcaneBolt) then
			self:PushComboOrder("skywrath_mage_arcane_bolt")

			self:IncComboDuration(arcaneBoltCastPoint)

			self:TryPhylacteryLike()

			self:DealMagicDamage(arcaneBoltDamage)
		end

		if (concussiveShot) then
			self:PushComboOrder("skywrath_mage_concussive_shot")

			self:DealMagicDamage(concussiveShotDamage)
		end

		if (mysticFlare) then
			self:PushComboOrder("skywrath_mage_mystic_flare")

			self:IncComboDuration(mysticFlareCastPoint)

			for _ = 1, mysticFlareDamageTicksCount do
				self:DealMagicDamage(mysticFlareDamagePerTick)
			end

			self:IncComboDuration(mysticFlareDuration)
		end
	end

	return self
end
--#endregion Skywrath Mage

--#region Lina
heroComboCalculators["npc_dota_hero_lina"] = function(self)
	local hero = self.hero
	local hasRefresher = self.hasRefresher

	local facetMult

	if (utils.heroHasFacet(hero, "lina_slow_burn")) then
		facetMult = 1.25

		local slowBurn = NPC.GetAbility(hero, "lina_slow_burn")

		if (slowBurn) then
			self:IncComboDuration(utils.getAbilityValue(slowBurn, "burn_duration"))
		end
	else
		facetMult = 1
	end

	local dragonSlave = NPC.GetAbility(hero, "lina_dragon_slave")
	dragonSlave = dragonSlave and Ability.GetLevel(dragonSlave) > 0 and dragonSlave or nil
	local dragonSlaveIsReady = false
	---@type integer, integer
	local dragonSlaveDamage, dragonSlaveCastPoint
	if (dragonSlave) then
		dragonSlaveIsReady = utils.isAbilityReady(dragonSlave)
		dragonSlaveDamage = facetMult * utils.getAbilityValue(dragonSlave, "dragon_slave_damage", true)
		dragonSlaveCastPoint = Ability.GetCastPoint(dragonSlave)
	end

	local lightStrike = NPC.GetAbility(hero, "lina_light_strike_array")
	lightStrike = lightStrike and Ability.GetLevel(lightStrike) > 0 and lightStrike or nil
	local lightStrikeIsReady = false
	---@type integer, integer
	local lightStrikeDamage, lightStrikeCastPoint
	if (lightStrike) then
		lightStrikeIsReady = utils.isAbilityReady(lightStrike)
		lightStrikeDamage = facetMult * utils.getAbilityValue(lightStrike, "light_strike_array_damage", true)
		lightStrikeCastPoint = Ability.GetCastPoint(lightStrike)
	end

	local flameCloak = NPC.GetAbility(hero, "lina_flame_cloak")
	flameCloak = flameCloak and NPC.HasScepter(hero) and flameCloak or nil
	local flameCloakIsReady = false
	---@type integer
	local flameCloakSpellAmp
	if (flameCloak) then
		flameCloakIsReady = utils.isAbilityReady(flameCloak)
		flameCloakSpellAmp = utils.getAbilityValue(flameCloak, "spell_amp") / 100
	end

	local lagunaBlade = NPC.GetAbility(hero, "lina_laguna_blade")
	lagunaBlade = lagunaBlade and Ability.GetLevel(lagunaBlade) > 0 and lagunaBlade or nil
	local lagunaBladeIsReady = false
	---@type integer, integer
	local lagunaBladeDamage, lagunaBladeCastPoint
	if (lagunaBlade) then
		lagunaBladeIsReady = utils.isAbilityReady(lagunaBlade)
		lagunaBladeDamage = facetMult * utils.getAbilityValue(lagunaBlade, "damage", true)
		lagunaBladeCastPoint = Ability.GetCastPoint(lagunaBlade)
	end

	if (flameCloakIsReady and not NPC.HasModifier(hero, "modifier_lina_flame_cloak")) then
		local heroBaseSpellAmp = NPC.GetBaseSpellAmp(hero) / 100 + self:GetKayaLikeAmp()

		self.spellAmp = self.spellAmp
			/ (1 + heroBaseSpellAmp)
			* (1 + heroBaseSpellAmp + flameCloakSpellAmp)
	end

	if (self:TryEtherealBlade()) then
		self:IncComboDuration(ETHEREAL_BLADE_COMBO_DURATION)
	end

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (lightStrikeIsReady) then
		self:IncComboDuration(lightStrikeCastPoint)
		self:DealMagicDamage(lightStrikeDamage)
	end

	-- if dragon slave won't be casted after laguna blade
	-- and combo will be continued by refresher
	-- then due to .25 sec laguna blade damage delay
	-- laguna blade damage will be affected by flame cloak
	if (hasRefresher and not dragonSlaveIsReady) then
		if (not flameCloakIsReady and flameCloak and not NPC.HasModifier(hero, "modifier_lina_flame_cloak")) then
			local heroBaseSpellAmp = NPC.GetBaseSpellAmp(hero) / 100 + self:GetKayaLikeAmp()

			self.spellAmp = self.spellAmp
				/ (1 + heroBaseSpellAmp)
				* (1 + heroBaseSpellAmp + flameCloakSpellAmp)
		end
	end

	if (lagunaBladeIsReady) then
		self:IncComboDuration(lagunaBladeCastPoint)
		self:DealMagicDamage(lagunaBladeDamage)
	end

	if (dragonSlaveIsReady) then
		self:IncComboDuration(dragonSlaveCastPoint)
		self:DealMagicDamage(dragonSlaveDamage)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		if (dragonSlaveIsReady) then
			if (not flameCloakIsReady and flameCloak and not NPC.HasModifier(hero, "modifier_lina_flame_cloak")) then
				local heroBaseSpellAmp = NPC.GetBaseSpellAmp(hero) / 100 + self:GetKayaLikeAmp()

				self.spellAmp = self.spellAmp
					/ (1 + heroBaseSpellAmp)
					* (1 + heroBaseSpellAmp + flameCloakSpellAmp)
			end
		end

		local isEtherealUsedBefore = self.isEtherealUsed

		if (not isEtherealUsedBefore) then
			self:TryEtherealBlade()
		else
			self:TryDagon()
			self:TryCripplingCrossbow()
		end

		self:TryJidiPollenBag()

		if (lagunaBlade) then
			self:IncComboDuration(lagunaBladeCastPoint)
			self:DealMagicDamage(lagunaBladeDamage)
		end

		if (lightStrike) then
			self:IncComboDuration(lightStrikeCastPoint)
			self:DealMagicDamage(lightStrikeDamage)
		end

		if (dragonSlave) then
			self:IncComboDuration(dragonSlaveCastPoint)
			self:DealMagicDamage(dragonSlaveDamage)
		end

		if (isEtherealUsedBefore) then
			self:TryEtherealBlade()
		else
			self:TryDagon()
			self:TryCripplingCrossbow()
		end
	end

	return self
end
--#endregion Lina

--#region Lion
heroComboCalculators["npc_dota_hero_lion"] = function(self)
	local hero = self.hero

	local earthSpike = NPC.GetAbility(hero, "lion_impale")
	earthSpike = earthSpike and Ability.GetLevel(earthSpike) > 0 and earthSpike or nil
	local earthSpikeIsReady = false
	---@type integer, integer
	local earthSpikeDamage, earthSpikeCastPoint
	if (earthSpike) then
		earthSpikeIsReady = utils.isAbilityReady(earthSpike)
		earthSpikeDamage = utils.getAbilityValue(earthSpike, "damage", true)
		earthSpikeCastPoint = Ability.GetCastPoint(earthSpike)
	end

	local hex = NPC.GetAbility(hero, "lion_voodoo")
	hex = hex and Ability.GetLevel(hex) > 0 and hex or nil
	local hexIsReady = false
	if (hex) then
		hexIsReady = utils.isAbilityReady(hex)
	end

	local fingerOfDeath = NPC.GetAbility(hero, "lion_finger_of_death")
	fingerOfDeath = fingerOfDeath and Ability.GetLevel(fingerOfDeath) > 0 and fingerOfDeath or nil
	local fingerOfDeathIsReady = false
	---@type integer, integer
	local fingerOfDeathDamage, fingerOfDeathCastPoint
	if (fingerOfDeath) then
		fingerOfDeathIsReady = utils.isAbilityReady(fingerOfDeath)
		fingerOfDeathDamage = utils.getAbilityValue(fingerOfDeath, "damage", true)

		local fingerStacksModifier = NPC.GetModifier(hero, "modifier_lion_finger_of_death_kill_counter")

		if (fingerStacksModifier) then
			fingerOfDeathDamage = fingerOfDeathDamage
				+ utils.getAbilityValue(fingerOfDeath, "damage_per_kill")
				* Modifier.GetStackCount(fingerStacksModifier)
		end

		fingerOfDeathCastPoint = Ability.GetCastPoint(fingerOfDeath)
	end

	if (hexIsReady) then
		self:TryPhylacteryLike()
	end

	if (self:TryEtherealBlade() and self.isPhylactaryLikeUsed) then
		self:IncComboDuration(math.min(ETHEREAL_BLADE_COMBO_DURATION, self.timeToRecoverPhylactaryLikeDamage))
	end

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (earthSpikeIsReady) then
		self:IncComboDuration(earthSpikeCastPoint)

		self:DealMagicDamage(earthSpikeDamage)
	end

	if (fingerOfDeathIsReady) then
		self:IncComboDuration(fingerOfDeathCastPoint)

		self:TryPhylacteryLike()

		self:DealMagicDamage(fingerOfDeathDamage)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		if (hex) then
			self:TryPhylacteryLike()
		end

		self:TryEtherealBlade()

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (earthSpike) then
			self:IncComboDuration(earthSpikeCastPoint)

			self:DealMagicDamage(earthSpikeDamage)
		end

		if (fingerOfDeath) then
			self:IncComboDuration(fingerOfDeathCastPoint)

			self:TryPhylacteryLike()

			self:DealMagicDamage(fingerOfDeathDamage)
		end
	end

	return self
end
--#endregion Lion

--#region Magnus
heroComboCalculators["npc_dota_hero_magnataur"] = function(self)
	local hero = self.hero

	local shockwave = NPC.GetAbility(hero, "magnataur_shockwave")
	local shockwaveLevel = shockwave and Ability.GetLevel(shockwave) or 0
	shockwave = shockwave and shockwaveLevel > 0 and shockwave or nil
	local shockwaveIsReady = false
	---@type integer, integer, integer
	local shockwaveDamage, shockwaveCastPoint, shockwaveLevel
	if (shockwave) then
		shockwaveIsReady = utils.isAbilityReady(shockwave)
		shockwaveDamage = utils.getAbilityValue(shockwave, "shock_damage", true)
		shockwaveCastPoint = Ability.GetCastPoint(shockwave)
	end

	local skewer = NPC.GetAbility(hero, "magnataur_skewer")
	skewer = skewer and Ability.GetLevel(skewer) > 0 and skewer or nil
	local skewerIsReady = false
	---@type integer, integer
	local skewerDamage, skewerCastPoint
	if (skewer) then
		skewerIsReady = utils.isAbilityReady(skewer)
		skewerDamage = utils.getAbilityValue(skewer, "skewer_damage", true)
		skewerCastPoint = Ability.GetCastPoint(skewer)
	end

	local hornToss = NPC.GetAbility(hero, "magnataur_horn_toss")
	hornToss = hornToss and Ability.GetLevel(hornToss) > 0 and hornToss or nil
	local hornTossIsReady = false
	---@type integer, integer
	local hornTossDamage, hornTossCastPoint
	if (hornToss) then
		hornTossIsReady = utils.isAbilityReady(hornToss)
		hornTossDamage = utils.getAbilityValue(hornToss, "damage", true)
		hornTossCastPoint = Ability.GetCastPoint(hornToss)
	end

	local reversePolarity = NPC.GetAbility(hero, "magnataur_reverse_polarity")
	reversePolarity = reversePolarity and Ability.GetLevel(reversePolarity) > 0 and reversePolarity or nil
	local reversePolarityIsReady = false
	---@type integer, integer
	local reversePolarityDamage, reversePolarityCastPoint
	if (reversePolarity) then
		reversePolarityIsReady = utils.isAbilityReady(reversePolarity)
		reversePolarityDamage = utils.getAbilityValue(reversePolarity, "polarity_damage", true)
		reversePolarityCastPoint = Ability.GetCastPoint(reversePolarity)
	end

	self:TryEtherealBlade()

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (shockwaveIsReady) then
		self:IncComboDuration(shockwaveCastPoint)
		self:DealMagicDamage(shockwaveDamage)

		if (shockwaveLevel == 5) then
			self:DealMagicDamage(shockwaveDamage / 2)
		end
	end

	if (skewerIsReady) then
		self:IncComboDuration(skewerCastPoint)
		self:DealMagicDamage(skewerDamage)
	end

	if (hornTossIsReady) then
		self:IncComboDuration(hornTossCastPoint)
		self:DealMagicDamage(hornTossDamage)
	end

	if (reversePolarityIsReady) then
		self:IncComboDuration(reversePolarityCastPoint)
		self:DealMagicDamage(reversePolarityDamage)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		self:TryEtherealBlade()

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (shockwave) then
			self:IncComboDuration(shockwaveCastPoint)
			self:DealMagicDamage(shockwaveDamage)
				:IncComboDuration(shockwaveCastPoint)

			if (shockwaveLevel == 5) then
				self:DealMagicDamage(shockwaveDamage / 2)
			end
		end

		if (skewer) then
			self:IncComboDuration(skewerCastPoint)
			self:DealMagicDamage(skewerDamage)
		end

		if (hornToss) then
			self:IncComboDuration(hornTossCastPoint)
			self:DealMagicDamage(hornTossDamage)
		end

		if (reversePolarity) then
			self:IncComboDuration(reversePolarityCastPoint)
			self:DealMagicDamage(reversePolarityDamage)
		end
	end

	return self
end
--#endregion Magnus

--#region Tiny
heroComboCalculators["npc_dota_hero_tiny"] = function(self)
	local hero = self.hero

	local avalanche = NPC.GetAbility(hero, "tiny_avalanche")
	avalanche = avalanche and Ability.GetLevel(avalanche) > 0 and avalanche or nil
	local avalancheIsReady = false
	---@type integer, integer
	local avalancheTicksCount, avalancheDamagePerTick
	if (avalanche) then
		avalancheIsReady = utils.isAbilityReady(avalanche)
		avalancheTicksCount = utils.getAbilityValue(avalanche, "tick_count")
		avalancheDamagePerTick = utils.getAbilityValue(avalanche, "avalanche_damage") / avalancheTicksCount
	end

	local toss = NPC.GetAbility(hero, "tiny_toss")
	toss = toss and Ability.GetLevel(toss) > 0 and toss or nil
	local tossIsReady = false
	---@type integer, integer, boolean, integer, integer
	local tossDamage, tossDuration, tossWithCharges, tossCharges, tossMaxCharges
	if (toss) then
		tossIsReady = utils.isAbilityReady(toss)
		tossDamage = utils.getAbilityValue(toss, "toss_damage")
		tossDuration = utils.getAbilityValue(toss, "duration")

		tossWithCharges = Ability.ChargeRestoreTimeRemaining(toss) ~= 0

		if (tossWithCharges) then
			tossCharges = Ability.GetCurrentCharges(toss)
			tossMaxCharges = utils.getAbilityValue(toss, "AbilityCharges")
		end
	end

	self:TryEtherealBlade()

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (avalancheIsReady) then
		for _ = 1, avalancheTicksCount do
			self:DealMagicDamage(avalancheDamagePerTick)
		end
	end

	if (tossIsReady) then
		if (not tossWithCharges) then
			self:TryPhylacteryLike()

			self:DealMagicDamage(tossDamage)
				:IncComboDuration(tossDuration)
		else
			for _ = 1, tossCharges do
				self:TryPhylacteryLike()
				self:DealMagicDamage(tossDamage)
			end

			self:IncComboDuration(tossDuration * tossCharges)
		end
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		self:TryEtherealBlade()

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (avalanche) then
			for _ = 1, avalancheTicksCount do
				self:DealMagicDamage(avalancheDamagePerTick)
			end
		end

		if (toss) then
			if (not tossWithCharges) then
				self:TryPhylacteryLike()

				self:DealMagicDamage(tossDamage)
					:IncComboDuration(tossDuration)
			else
				for _ = 1, tossMaxCharges do
					self:TryPhylacteryLike()
					self:DealMagicDamage(tossDamage)
				end

				self:IncComboDuration(tossDuration * tossMaxCharges)
			end
		end
	end

	return self
end
--#endregion Tiny

--#region Tinker
heroComboCalculators["npc_dota_hero_tinker"] = function(self)
	local hero = self.hero

	local hasScepter = NPC.HasScepter(hero)

	local laser = NPC.GetAbility(hero, "tinker_laser")
	laser = laser and Ability.GetLevel(laser) > 0 and laser or nil
	local laserIsReady = false
	---@type integer, integer, integer
	local laserDamage, laserHealthReduction, laserCastPoint
	if (laser) then
		laserIsReady = utils.isAbilityReady(laser)
		laserDamage = utils.getAbilityValue(laser, "laser_damage", true)
		laserHealthReduction = utils.getAbilityValue(laser, "scepter_reduction_pct") / 100
		laserCastPoint = Ability.GetCastPoint(laser)
	end

	local withEtherealBlade = self:TryEtherealBlade()

	if (not withEtherealBlade) then
		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()
	end

	if (laserIsReady) then
		self:IncComboDuration(laserCastPoint)

		self:TryPhylacteryLike()

		if (hasScepter) then
			local healthReductionAmount = self.health * laserHealthReduction

			self:DealMagicDamage(healthReductionAmount, true, true, true)
		end

		self:DealMagicDamage(laserDamage, false, true, true)
	end

	if (withEtherealBlade) then
		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		local isEtherealUsedBefore = self.isEtherealUsed

		if (not isEtherealUsedBefore) then
			self:TryEtherealBlade()
		else
			self:TryCripplingCrossbow()
			self:TryDagon()
		end

		self:TryJidiPollenBag()

		if (laser) then
			self:IncComboDuration(laserCastPoint)

			self:TryPhylacteryLike()

			if (hasScepter) then
				local healthReductionAmount = self.health * laserHealthReduction

				self:DealMagicDamage(healthReductionAmount, true, true, true)
			end

			self:DealMagicDamage(laserDamage, false, true, true)
		end

		if (isEtherealUsedBefore) then
			self:TryEtherealBlade()
		else
			self:TryCripplingCrossbow()
			self:TryDagon()
		end
	end

	return self
end
--#endregion Tinker

--#region Shadow Fiend
heroComboCalculators["npc_dota_hero_nevermore"] = function(self)
	local hero = self.hero

	local hasScepter = NPC.HasScepter(hero)

	local shadowRazeInfo = {
		baseDamage = 0,
		razeStacks = 0,
		damagePerStack = 0,
	}

	local shadowRaze1 = NPC.GetAbility(hero, "nevermore_shadowraze1")
	shadowRaze1 = shadowRaze1 and Ability.GetLevel(shadowRaze1) > 0 and shadowRaze1 or nil
	local shadowRaze1IsReady = false
	---@type integer
	local shadowRazeCastPoint
	if (shadowRaze1) then
		shadowRaze1IsReady = utils.isAbilityReady(shadowRaze1)

		shadowRazeCastPoint = Ability.GetCastPoint(shadowRaze1)

		local shadowRazeDamage = utils.getAbilityValue(shadowRaze1, "shadowraze_damage", true)

		shadowRazeInfo.baseDamage = shadowRazeDamage

		local shadowRazeStacksModifier = NPC.GetModifier(self.target, "modifier_nevermore_shadowraze_counter")

		if (shadowRazeStacksModifier) then
			shadowRazeInfo.razeStacks = Modifier.GetStackCount(shadowRazeStacksModifier)
		end

		shadowRazeInfo.damagePerStack = utils.getAbilityValue(shadowRaze1, "stack_bonus_damage", true)
	end

	local shadowRaze2 = NPC.GetAbility(hero, "nevermore_shadowraze2")
	shadowRaze2 = shadowRaze2 and Ability.GetLevel(shadowRaze2) > 0 and shadowRaze2 or nil
	local shadowRaze2IsReady = false
	if (shadowRaze2) then
		shadowRaze2IsReady = utils.isAbilityReady(shadowRaze2)
	end

	local shadowRaze3 = NPC.GetAbility(hero, "nevermore_shadowraze2")
	shadowRaze3 = shadowRaze3 and Ability.GetLevel(shadowRaze3) > 0 and shadowRaze3 or nil
	local shadowRaze3IsReady = false
	if (shadowRaze3) then
		shadowRaze3IsReady = utils.isAbilityReady(shadowRaze3)
	end

	local requiem = NPC.GetAbility(hero, "nevermore_requiem")
	requiem = requiem and Ability.GetLevel(requiem) > 0 and requiem or nil
	local requiemIsReady = false
	local necromastery = NPC.GetModifier(hero, "modifier_nevermore_necromastery")
	---@type integer, integer, integer
	local soulsCount, requiemDamagePerSoul, requiemMagicResistReduction
	if (requiem and necromastery) then
		requiemIsReady = true

		soulsCount = Modifier.GetStackCount(necromastery)
		requiemDamagePerSoul = Ability.GetDamage(requiem)
		requiemMagicResistReduction = utils.getAbilityValue(requiem, "requiem_reduction_mres") / 100
	end

	local eulItem = NPC.GetItem(hero, "item_cyclone") or NPC.GetItem(hero, "item_wind_waker")
	local eulDuration = eulItem and utils.getAbilityValue(eulItem, "cyclone_duration") or nil

	self:TryEtherealBlade()

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	local dagonApplied = self:TryDagon()

	if (requiemIsReady) then
		self:SumMagicResist(requiemMagicResistReduction)

		for _ = 1, math.floor(soulsCount * .62) do
			self:DealMagicDamage(requiemDamagePerSoul)
		end

		if (hasScepter) then
			for _ = 1, math.floor(soulsCount * .1) do
				self:DealMagicDamage(requiemDamagePerSoul)
			end
		end

		if (dagonApplied and eulDuration) then
			self:IncComboDuration(eulDuration)
		end
	end

	local function castShadowRaze()
		self:IncComboDuration(shadowRazeCastPoint)
		self:DealMagicDamage(shadowRazeInfo.baseDamage + shadowRazeInfo.razeStacks * shadowRazeInfo.damagePerStack)
		shadowRazeInfo.razeStacks = shadowRazeInfo.razeStacks + 1
	end

	if (shadowRaze1IsReady) then
		castShadowRaze()
	end
	if (shadowRaze2IsReady) then
		castShadowRaze()
	end
	if (shadowRaze3IsReady) then
		castShadowRaze()
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		self:TryEtherealBlade()

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (requiem) then
			if (not requiemIsReady) then
				self:SumMagicResist(requiemMagicResistReduction)
			end

			for _ = 1, math.floor(soulsCount * .62) do
				self:DealMagicDamage(requiemDamagePerSoul)
			end

			if (hasScepter) then
				for _ = 1, math.floor(soulsCount * .1) do
					self:DealMagicDamage(requiemDamagePerSoul)
				end
			end

			if (eulDuration) then
				self:IncComboDuration(eulDuration)
			end
		end

		if (shadowRaze1) then
			castShadowRaze()
		end
		if (shadowRaze2) then
			castShadowRaze()
		end
		if (shadowRaze3) then
			castShadowRaze()
		end
	end

	return self
end
--#endregion Shadow Fiend

--#region Zeus
heroComboCalculators["npc_dota_hero_zuus"] = function(self)
	local hero = self.hero

	local hasScepter = NPC.HasScepter(hero)

	local arcLightning = NPC.GetAbility(self.hero, "zuus_arc_lightning")
	arcLightning = arcLightning and Ability.GetLevel(arcLightning) > 0 and arcLightning or nil
	local arcLightningIsReady = false
	---@type integer, integer
	local arcLightningDamage, arcLightningCastPoint
	if (arcLightning) then
		arcLightningIsReady = utils.isAbilityReady(arcLightning)
		arcLightningDamage = utils.getAbilityValue(arcLightning, "arc_damage", true)
		arcLightningCastPoint = Ability.GetCastPoint(arcLightning)
	end

	local lightningBolt = NPC.GetAbility(self.hero, "zuus_lightning_bolt")
	lightningBolt = lightningBolt and Ability.GetLevel(lightningBolt) > 0 and lightningBolt or nil
	local lightningBoltIsReady = false
	---@type integer, integer
	local lightningBoltDamage, lightningBoltCastPoint
	if (lightningBolt) then
		lightningBoltIsReady = utils.isAbilityReady(lightningBolt)
		lightningBoltDamage = Ability.GetDamage(lightningBolt)
		lightningBoltCastPoint = Ability.GetCastPoint(lightningBolt)
	end

	local heavenlyJump = NPC.GetAbility(self.hero, "zuus_heavenly_jump")
	heavenlyJump = heavenlyJump and Ability.GetLevel(heavenlyJump) > 0 and heavenlyJump or nil
	local heavenlyJumpIsReady = false
	---@type integer, integer
	local heavenlyJumpDamage, heavenlyJumpDuration
	if (heavenlyJump) then
		heavenlyJumpIsReady = utils.isAbilityReady(heavenlyJump)
		heavenlyJumpDamage = utils.getAbilityValue(heavenlyJump, "damage", true)
		heavenlyJumpDuration = utils.getAbilityValue(heavenlyJump, "duration")
	end

	local nimbus = NPC.GetAbility(self.hero, "zuus_cloud")
	nimbus = hasScepter and lightningBolt and nimbus or nil
	local nimbusIsReady = false
	---@type integer, integer
	local nimbusDamage, nimbusCastPoint
	if (nimbus) then
		nimbusIsReady = utils.isAbilityReady(nimbus)
		nimbusDamage = lightningBoltDamage
		nimbusCastPoint = Ability.GetCastPoint(nimbus)
	end

	local thundergodsWrath = NPC.GetAbility(self.hero, "zuus_thundergods_wrath")
	thundergodsWrath = thundergodsWrath and Ability.GetLevel(thundergodsWrath) > 0 and thundergodsWrath or nil
	local thundergodsWrathIsReady = false
	---@type integer, integer
	local thundergodsWrathDamage, thundergodsWrathCastPoint
	if (thundergodsWrath) then
		thundergodsWrathIsReady = utils.isAbilityReady(thundergodsWrath)
		thundergodsWrathDamage = utils.getAbilityValue(thundergodsWrath, "damage", true)
		thundergodsWrathCastPoint = Ability.GetCastPoint(thundergodsWrath)
	end

	local staticField = NPC.GetAbility(hero, "zuus_static_field")
	---@type integer
	local staticFieldPercDamage
	if (staticField) then
		if (Hero.GetFacetID(hero) == 1) then
			staticFieldPercDamage = utils.getAbilityValue(staticField, "damage_health_pct_min_close", true) / 100
		else
			staticFieldPercDamage = utils.getAbilityValue(staticField, "damage_health_pct", true) / 100
		end
	end

	local function applyStaticField()
		if (not staticFieldPercDamage) then
			return
		end

		self:DealMagicDamage(self.health * staticFieldPercDamage)
	end

	local withEtherealBlade = self:TryEtherealBlade()

	if (not withEtherealBlade) then
		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()
	end

	if (lightningBoltIsReady) then
		self:IncComboDuration(lightningBoltCastPoint)

		self:TryPhylacteryLike()

		applyStaticField()

		self:DealMagicDamage(lightningBoltDamage)
	end

	if (withEtherealBlade) then
		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()
	end

	if (nimbusIsReady) then
		self:IncComboDuration(nimbusCastPoint)

		applyStaticField()

		self:DealMagicDamage(nimbusDamage)
	end

	if (thundergodsWrathIsReady) then
		self:IncComboDuration(thundergodsWrathCastPoint)

		applyStaticField()

		self:DealMagicDamage(thundergodsWrathDamage)
	end

	if (arcLightningIsReady) then
		self:IncComboDuration(arcLightningCastPoint)

		self:TryPhylacteryLike()

		applyStaticField()

		self:DealMagicDamage(arcLightningDamage)
	end

	if (heavenlyJumpIsReady) then
		applyStaticField()

		self:DealMagicDamage(heavenlyJumpDamage)
		self:IncComboDuration(heavenlyJumpDuration)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		self:TryJidiPollenBag()

		local isEtherealUsedBefore = self.isEtherealUsed

		if (lightningBolt) then
			self:IncComboDuration(lightningBoltCastPoint)

			self:TryPhylacteryLike()

			applyStaticField()

			self:DealMagicDamage(lightningBoltDamage)
		end

		if (not isEtherealUsedBefore) then
			self:TryEtherealBlade()
			self:TryCripplingCrossbow()
			self:TryDagon()
		end

		if (nimbus) then
			self:IncComboDuration(nimbusCastPoint)

			applyStaticField()

			self:DealMagicDamage(nimbusDamage)
		end

		if (thundergodsWrath) then
			self:IncComboDuration(thundergodsWrathCastPoint)

			applyStaticField()

			self:DealMagicDamage(thundergodsWrathDamage)
		end

		if (arcLightning) then
			self:IncComboDuration(arcLightningCastPoint)

			self:TryPhylacteryLike()

			applyStaticField()

			self:DealMagicDamage(arcLightningDamage)
		end

		if (heavenlyJump) then
			applyStaticField()

			self:DealMagicDamage(heavenlyJumpDamage)

			self:IncComboDuration(heavenlyJumpDuration)
		end

		if (isEtherealUsedBefore) then
			self:TryEtherealBlade()
			self:TryCripplingCrossbow()
			self:TryDagon()
		end
	end

	return self
end
--#endregion Zeus

--#region Techies
heroComboCalculators["npc_dota_hero_techies"] = function(self)
	local hero = self.hero

	local stickyBomb = NPC.GetAbility(hero, "techies_sticky_bomb")
	stickyBomb = stickyBomb and Ability.GetLevel(stickyBomb) > 0 and stickyBomb or nil
	local stickyBombIsReady = false
	---@type integer, integer
	local stickyBombDamage, stickyBombDuration
	if (stickyBomb) then
		stickyBombIsReady = utils.isAbilityReady(stickyBomb)
		stickyBombDamage = utils.getAbilityValue(stickyBomb, "damage", true)
		stickyBombDuration = utils.getAbilityValue(stickyBomb, "duration") + Ability.GetCastPoint(stickyBomb)
	end
	local blastOff = NPC.GetAbility(hero, "techies_suicide")
	blastOff = blastOff and Ability.GetLevel(blastOff) > 0 and blastOff or nil
	local blastOffIsReady = false
	---@type integer, integer, integer
	local blastOffDamage, blastOffDamageAsHealthPerc, blastOffDuration
	if (blastOff) then
		blastOffIsReady = utils.isAbilityReady(blastOff)
		blastOffDamage = utils.getAbilityValue(blastOff, "damage", true)
		blastOffDamageAsHealthPerc = utils.getAbilityValue(blastOff, "hp_dmg") / 100
		blastOffDuration = Ability.GetCastPoint(blastOff) + utils.getAbilityValue(blastOff, "duration")
	end
	local minefieldSign = NPC.GetAbility(hero, "techies_minefield_sign")
	minefieldSign = minefieldSign and Ability.GetLevel(minefieldSign) > 0 and minefieldSign or nil
	local minefieldSignIsReady = false
	---@type integer, integer
	local minefieldSignCastPoint, minefieldSignAmplify
	if (minefieldSign) then
		minefieldSignIsReady = utils.isAbilityReady(minefieldSign)
		minefieldSignCastPoint = Ability.GetCastPoint(minefieldSign)
		minefieldSignAmplify = utils.getAbilityValue(minefieldSign, "bonus_mine_damage_pct") / 100
	end
	local proximityMine = NPC.GetAbility(hero, "techies_land_mines")
	proximityMine = proximityMine and Ability.GetLevel(proximityMine) > 0 and proximityMine or nil
	---@type integer, integer, integer
	local proximityMineDamage, proximityMineMagicResistReduction, proximityMineMaxCharges
	local proximityMineCharges = 0
	if (proximityMine) then
		-- a bit reduce mine damage due to reduced damage if too far from target
		proximityMineDamage = utils.getAbilityValue(proximityMine, "damage", true) * .85
		proximityMineMagicResistReduction = -utils.getAbilityValue(proximityMine, "mres_reduction", true) / 100
		proximityMineCharges = Ability.GetCurrentCharges(proximityMine)
		proximityMineMaxCharges = 3
	end

	if (blastOffIsReady) then
		self:IncComboDuration(blastOffDuration)

		local damage = blastOffDamage

		if (blastOffDamageAsHealthPerc) then
			damage = damage + Entity.GetMaxHealth(hero) * blastOffDamageAsHealthPerc
		end

		self:DealMagicDamage(damage)
	end

	self:TryEtherealBlade()

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (minefieldSignIsReady) then
		self:IncComboDuration(minefieldSignCastPoint, true)
	end

	if (proximityMineCharges > 0) then
		local damage = proximityMineDamage

		if (minefieldSignIsReady and minefieldSignAmplify and Ability.GetLevel(NPC.GetAbility(hero, "special_bonus_unique_techies_4") --[[@as userdata]]) == 0) then
			damage = damage * (1 + minefieldSignAmplify)
		end

		for _ = 1, proximityMineCharges do
			self:SumMagicResist(proximityMineMagicResistReduction)

			self:DealMagicDamage(damage, true)
		end
	end

	if (stickyBombIsReady) then
		self:IncComboDuration(stickyBombDuration)

		local damage = stickyBombDamage

		if (minefieldSignIsReady and minefieldSignAmplify) then
			damage = damage * (1 + minefieldSignAmplify)
		end

		self:DealMagicDamage(damage)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		local isEtherealUsedBefore = self.isEtherealUsed

		if (not isEtherealUsedBefore) then
			self:TryEtherealBlade()
		end

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (blastOff) then
			self:IncComboDuration(blastOffDuration)

			local damage = blastOffDamage

			if (blastOffDamageAsHealthPerc) then
				damage = damage + Entity.GetMaxHealth(hero) * blastOffDamageAsHealthPerc
			end

			self:DealMagicDamage(damage)
		end

		if (proximityMineMaxCharges) then
			local damage = proximityMineDamage

			if (not minefieldSignIsReady and minefieldSignAmplify and Ability.GetLevel(NPC.GetAbility(hero, "special_bonus_unique_techies_4") --[[@as userdata]]) == 0) then
				damage = damage * (1 + minefieldSignAmplify)
			end

			for _ = 1, proximityMineMaxCharges do
				self:SumMagicResist(proximityMineMagicResistReduction)

				self:DealMagicDamage(damage, true)
			end
		end

		if (stickyBomb) then
			self:IncComboDuration(stickyBombDuration)

			local damage = stickyBombDamage

			if (minefieldSignAmplify) then
				damage = damage * (1 + minefieldSignAmplify)
			end

			self:DealMagicDamage(damage)
		end

		if (isEtherealUsedBefore) then
			self:TryEtherealBlade()
		end
	end

	return self
end
--#endregion Techies

--#region Nyx Assassin

heroComboCalculators["npc_dota_hero_nyx_assassin"] = function(self)
	local hero = self.hero

	local impale = NPC.GetAbility(hero, "nyx_assassin_impale")
	impale = impale and Ability.GetLevel(impale) > 0 and impale or nil
	local impaleIsReady = false
	---@type integer, integer
	local impaleDamage, impaleCastPoint
	if (impale) then
		impaleIsReady = utils.isAbilityReady(impale)
		impaleDamage = utils.getAbilityValue(impale, "impale_damage", true)
		impaleCastPoint = Ability.GetCastPoint(impale)
	end

	local mindFlare = NPC.GetAbility(hero, "nyx_assassin_jolt")
	mindFlare = mindFlare and Ability.GetLevel(mindFlare) > 0 and mindFlare or nil
	local mindFlareIsReady = false
	---@type integer, integer, integer
	local mindFlareDamage, mindFlareBonusDamagePerc, mindFlareCastPoint
	if (mindFlare) then
		mindFlareIsReady = utils.isAbilityReady(mindFlare)
		mindFlareDamage = self.maxMana * utils.getAbilityValue(mindFlare, "max_mana_as_damage_pct", true) / 100
		-- mindFlareBonusDamagePerc = utils.getAbilityValue(mindFlare, "damage_echo_pct", true) / 100
		mindFlareCastPoint = Ability.GetCastPoint(mindFlare)
	end

	local vendetta = NPC.GetAbility(hero, "nyx_assassin_vendetta")
	vendetta = vendetta and Ability.GetLevel(vendetta) > 0 and vendetta or nil
	local vendettaIsReady = false
	---@type integer
	local vendettaDamage
	if (vendetta) then
		vendettaIsReady = utils.isAbilityReady(vendetta) or NPC.HasModifier(hero, "modifier_nyx_assassin_vendetta")
		vendettaDamage = utils.getAbilityValue(vendetta, "bonus_damage", true)
	end

	if (vendettaIsReady) then
		if (NPC.HasShard(hero)) then
			self.isBreakApplied = true
		end

		self:DealMagicDamage(vendettaDamage, nil, true)
		self:Attack()
	end

	self:TryEtherealBlade()

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (impaleIsReady) then
		self:IncComboDuration(impaleCastPoint)
		self:DealMagicDamage(impaleDamage)
	end

	if (mindFlareIsReady) then
		self:IncComboDuration(mindFlareCastPoint)
		self:DealMagicDamage(mindFlareDamage)
		-- it's not working in dota?
		-- self:DealMagicDamage(mindFlareDamage + self.totalDamage * mindFlareBonusDamagePerc)
	end

	self:SaveWithoutRefresherInfo()

	if (self:TryRefresher()) then
		if (vendetta and not self.isEtherealUsed) then
			if (NPC.HasShard(hero)) then
				self.isBreakApplied = true
			end

			self:DealMagicDamage(vendettaDamage, nil, true)
			self:Attack()
		end

		self:TryEtherealBlade()

		self:TryCripplingCrossbow()
		self:TryJidiPollenBag()
		self:TryDagon()

		if (impale) then
			self:IncComboDuration(impaleCastPoint)
			self:DealMagicDamage(impaleDamage)
		end

		if (mindFlare) then
			self:IncComboDuration(mindFlareCastPoint)
			self:DealMagicDamage(mindFlareDamage)
			-- it's not working in dota?
			-- self:DealMagicDamage(mindFlareDamage + self.totalDamage * mindFlareBonusDamagePerc)
		end
	end

	return self
end
--#endregion Nyx Assassin

--#region Tusk

heroComboCalculators["npc_dota_hero_tusk"] = function(self)
	local hero = self.hero

	local iceShards = NPC.GetAbility(hero, "tusk_ice_shards")
	iceShards = iceShards and Ability.GetLevel(iceShards) > 0 and iceShards or nil
	local iceShardsIsReady = false
	---@type integer, integer
	local iceShardsDamage, iceShardsCastPoint
	if (iceShards) then
		iceShardsIsReady = utils.isAbilityReady(iceShards)
		iceShardsDamage = utils.getAbilityValue(iceShards, "shard_damage", true)
		iceShardsCastPoint = Ability.GetCastPoint(iceShards)
	end

	local snowball = NPC.GetAbility(hero, "tusk_snowball")
	snowball = snowball and Ability.GetLevel(snowball) > 0 and snowball or nil
	local snowballIsReady = false
	---@type integer, integer
	local snowballDamage, snowballCastPoint
	if (snowball) then
		snowballIsReady = utils.isAbilityReady(snowball)
		snowballDamage = utils.getAbilityValue(snowball, "snowball_damage", true)
		snowballCastPoint = Ability.GetCastPoint(snowball)
	end

	local tagTeam = NPC.GetAbility(hero, "tusk_tag_team")
	tagTeam = tagTeam and Ability.GetLevel(tagTeam) > 0 and tagTeam or nil
	local tagTeamIsReady = false
	---@type integer
	local tagTeamBonusDamage
	if (tagTeam) then
		tagTeamIsReady = utils.isAbilityReady(tagTeam)
		tagTeamBonusDamage = utils.getAbilityValue(tagTeam, "bonus_damage", true)
	end

	local warlusKick = NPC.GetAbility(hero, "tusk_walrus_kick")
	warlusKick = warlusKick and NPC.HasScepter(hero) and warlusKick or nil
	local warlusKickIsReady = false
	---@type integer, integer
	local warlusKickDamage, warlusKickCastPoint
	if (warlusKick) then
		warlusKickIsReady = utils.isAbilityReady(warlusKick)
		warlusKickDamage = utils.getAbilityValue(warlusKick, "damage", true)
		warlusKickCastPoint = Ability.GetCastPoint(warlusKick)
	end

	local warlusPunch = NPC.GetAbility(hero, "tusk_walrus_punch")
	warlusPunch = warlusPunch and Ability.GetLevel(warlusPunch) > 0 and warlusPunch or nil
	local warlusPunchIsReady = false
	---@type integer, integer
	local warlusPunchDamageMult, warlusPunchBonusDamage
	if (warlusPunch) then
		warlusPunchIsReady = utils.isAbilityReady(warlusPunch)
		warlusPunchDamageMult = utils.getAbilityValue(warlusPunch, "crit_multiplier", true) / 100
		warlusPunchBonusDamage = utils.getAbilityValue(warlusPunch, "bonus_damage", true)
	end

	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (iceShardsIsReady) then
		self:IncComboDuration(iceShardsCastPoint)
		self:DealMagicDamage(iceShardsDamage)
	end

	if (snowballIsReady) then
		self:IncComboDuration(snowballCastPoint)
		self:DealMagicDamage(snowballDamage)
	end

	if (warlusPunchIsReady) then
		self:DealPhysDamage((self.attackDamage + warlusPunchBonusDamage + (tagTeamIsReady and tagTeamBonusDamage or 0))
			* warlusPunchDamageMult)
	end

	if (warlusKickIsReady) then
		self:IncComboDuration(warlusKickCastPoint)
		self:DealMagicDamage(warlusKickDamage)
	end

	self:SaveWithoutRefresherInfo()

	self.hasRefresher = false

	return self
end
--#endregion Tusk

--#region Mars
heroComboCalculators["npc_dota_hero_mars"] = function(self)
	local hero = self.hero

	local spear = NPC.GetAbility(hero, "mars_spear")
	spear = spear and Ability.GetLevel(spear) > 0 and spear or nil
	local spearIsReady = false
	local spearDamage, spearCastPoint
	if (spear) then
		spearIsReady = utils.isAbilityReady(spear)
		spearDamage = utils.getAbilityValue(spear, "damage", true)
		spearCastPoint = Ability.GetCastPoint(spear)
	end

	local godsRebuke = NPC.GetAbility(hero, "mars_gods_rebuke")
	godsRebuke = godsRebuke and Ability.GetLevel(godsRebuke) > 0 and godsRebuke or nil
	local godsRebukeIsReady = false
	local godsRebukeDamage, godsRebukeCastPoint
	if (godsRebuke) then
		godsRebukeIsReady = utils.isAbilityReady(godsRebuke)
		godsRebukeDamage = utils.getAbilityValue(godsRebuke, "damage", true)
		godsRebukeCastPoint = Ability.GetCastPoint(godsRebuke)
	end

	local arena = NPC.GetAbility(hero, "mars_arena_of_blood")
	arena = arena and Ability.GetLevel(arena) > 0 and arena or nil
	local arenaIsReady = false
	local arenaDamage, arenaDuration
	if (arena) then
		arenaIsReady = utils.isAbilityReady(arena)
		arenaDamage = utils.getAbilityValue(arena, "warrior_damage", true)
		arenaDuration = utils.getAbilityValue(arena, "duration", true)
	end

	self:TryEtherealBlade()
	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (spearIsReady) then
		self:IncComboDuration(spearCastPoint)
		self:DealMagicDamage(spearDamage)
	end

	if (godsRebukeIsReady) then
		self:IncComboDuration(godsRebukeCastPoint)
		self:DealPhysDamage(godsRebukeDamage)
	end

	if (arenaIsReady) then
		for i = 1, arenaDuration do
			self:DealMagicDamage(arenaDamage)
		end
	end

	self:SaveWithoutRefresherInfo()
	self.hasRefresher = false

	return self
end
--#endregion Mars

--#region Timbersaw
heroComboCalculators["npc_dota_hero_shredder"] = function(self)
	local hero = self.hero

	local timberChain = NPC.GetAbility(hero, "shredder_timber_chain")
	timberChain = timberChain and Ability.GetLevel(timberChain) > 0 and timberChain or nil
	local timberChainIsReady = false
	local timberChainDamage
	if (timberChain) then
		timberChainIsReady = utils.isAbilityReady(timberChain)
		timberChainDamage = utils.getAbilityValue(timberChain, "damage", true)
	end

	local whirlingDeath = NPC.GetAbility(hero, "shredder_whirling_death")
	whirlingDeath = whirlingDeath and Ability.GetLevel(whirlingDeath) > 0 and whirlingDeath or nil
	local whirlingDeathIsReady = false
	local whirlingDeathDamage
	if (whirlingDeath) then
		whirlingDeathIsReady = utils.isAbilityReady(whirlingDeath)
		whirlingDeathDamage = utils.getAbilityValue(whirlingDeath, "whirling_damage", true)
	end

	local chakram = NPC.GetAbility(hero, "shredder_chakram")
	chakram = chakram and Ability.GetLevel(chakram) > 0 and chakram or nil
	local chakramIsReady = false
	local chakramDamage, chakramDuration
	if (chakram) then
		chakramIsReady = utils.isAbilityReady(chakram)
		chakramDamage = utils.getAbilityValue(chakram, "pass_damage", true) + utils.getAbilityValue(chakram, "damage_per_second", true)
		chakramDuration = 2
	end

	local chakram2 = NPC.GetAbility(hero, "shredder_chakram_2")
	chakram2 = chakram2 and Ability.GetLevel(chakram2) > 0 and chakram2 or nil
	local chakram2IsReady = false
	local chakram2Damage, chakram2Duration
	if (chakram2) then
		chakram2IsReady = utils.isAbilityReady(chakram2)
		chakram2Damage = utils.getAbilityValue(chakram2, "pass_damage", true) + utils.getAbilityValue(chakram2, "damage_per_second", true)
		chakram2Duration = 2
	end

	self:TryEtherealBlade()
	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (timberChainIsReady) then
		self:DealMagicDamage(timberChainDamage)
	end

	if (whirlingDeathIsReady) then
		self:DealMagicDamage(whirlingDeathDamage)
	end

	if (chakramIsReady) then
		for i = 1, chakramDuration do
			self:DealMagicDamage(chakramDamage)
		end
	end

	if (chakram2IsReady) then
		for i = 1, chakram2Duration do
			self:DealMagicDamage(chakram2Damage)
		end
	end

	self:SaveWithoutRefresherInfo()
	self.hasRefresher = false

	return self
end
--#endregion Timbersaw

--#region Legion Commander
heroComboCalculators["npc_dota_hero_legion_commander"] = function(self)
	local hero = self.hero

	local overwhelmingOdds = NPC.GetAbility(hero, "legion_commander_overwhelming_odds")
	overwhelmingOdds = overwhelmingOdds and Ability.GetLevel(overwhelmingOdds) > 0 and overwhelmingOdds or nil
	local overwhelmingOddsIsReady = false
	local overwhelmingOddsDamage
	local overwhelmingOddsAttackSpeed = 0
	if (overwhelmingOdds) then
		overwhelmingOddsIsReady = utils.isAbilityReady(overwhelmingOdds)
		overwhelmingOddsDamage = utils.getAbilityValue(overwhelmingOdds, "damage", true)
		overwhelmingOddsAttackSpeed = utils.getAbilityValue(overwhelmingOdds, "bonus_attack_speed", true)
	else
		local heroLevel = NPC.GetCurrentLevel(hero)
		local skillLevel = math.min(4, math.max(1, math.floor(heroLevel / 5)))
		local damagePerLevel = {100, 175, 250, 325}
		overwhelmingOddsDamage = damagePerLevel[skillLevel] or 100
		overwhelmingOddsAttackSpeed = 125
	end

	local duel = NPC.GetAbility(hero, "legion_commander_duel")
	duel = duel and Ability.GetLevel(duel) > 0 and duel or nil
	local duelDuration
	if (duel) then
		duelDuration = utils.getAbilityValue(duel, "duration", true)
	end

	-- Calcula ataques do duel COM o buff de attack speed do Overwhelming Odds
	if (duelDuration) then
		local baseAttackSpeed = NPC.GetAttackSpeed(hero)
		local attackSpeedWithBuff = baseAttackSpeed + (overwhelmingOddsAttackSpeed / 100)
		local myAttacksInDuel = math.floor(duelDuration * attackSpeedWithBuff)
		for i = 1, myAttacksInDuel do
			self:Attack()
		end
	end

	self:TryEtherealBlade()
	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (overwhelmingOddsIsReady or overwhelmingOddsDamage) then
		self:DealMagicDamage(overwhelmingOddsDamage)
	end

	self:SaveWithoutRefresherInfo()
	self.hasRefresher = false

	return self
end
--#endregion Legion Commander

--#region Hoodwink
heroComboCalculators["npc_dota_hero_hoodwink"] = function(self)
	local hero = self.hero

	local acornShot = NPC.GetAbility(hero, "hoodwink_acorn_shot")
	acornShot = acornShot and Ability.GetLevel(acornShot) > 0 and acornShot or nil
	local acornShotIsReady = false
	local acornShotDamage
	if (acornShot) then
		acornShotIsReady = utils.isAbilityReady(acornShot)
		acornShotDamage = utils.getAbilityValue(acornShot, "projectile_damage", true)
	end

	local bushwhack = NPC.GetAbility(hero, "hoodwink_bushwhack")
	bushwhack = bushwhack and Ability.GetLevel(bushwhack) > 0 and bushwhack or nil
	local bushwhackIsReady = false
	local bushwhackDamage
	if (bushwhack) then
		bushwhackIsReady = utils.isAbilityReady(bushwhack)
		bushwhackDamage = utils.getAbilityValue(bushwhack, "total_damage", true)
	end

	local sharpshooter = NPC.GetAbility(hero, "hoodwink_sharpshooter")
	sharpshooter = sharpshooter and Ability.GetLevel(sharpshooter) > 0 and sharpshooter or nil
	local sharpshooterIsReady = false
	local sharpshooterDamage
	if (sharpshooter) then
		sharpshooterIsReady = utils.isAbilityReady(sharpshooter)
		sharpshooterDamage = utils.getAbilityValue(sharpshooter, "max_damage", true)
	end

	self:TryEtherealBlade()
	self:TryCripplingCrossbow()
	self:TryJidiPollenBag()
	self:TryDagon()

	if (acornShotIsReady) then
		self:DealMagicDamage(acornShotDamage)
	end

	if (bushwhackIsReady) then
		self:DealMagicDamage(bushwhackDamage)
	end

	if (sharpshooterIsReady) then
		self:DealMagicDamage(sharpshooterDamage)
	end

	self:Attack()

	self:SaveWithoutRefresherInfo()
	self.hasRefresher = false

	return self
end
--#endregion Hoodwink

--#endregion Hero Calculators

--#region In-Game Handlers

---@type table<string, (fun(hero: userdata): boolean?)?>
local illusionHandlers = {
	["npc_dota_hero_vengefulspirit"] = function(illusion)
		return NPC.HasModifier(illusion, "modifier_vengefulspirit_hybrid_special")
	end,
	["npc_dota_hero_arc_warden"] = function(illusion)
		return NPC.HasModifier(illusion, "modifier_arc_warden_tempest_double")
	end,
}

---@type userdata?, Enum.TeamNum?, HeroComboCalculator?
local localHero, team, heroComboCalculator

local function onGameEnd()
	localHero = nil
	team = nil
	heroComboCalculator = nil
end

---@type table<integer, ComboInfo?>
local targetsData = {}

---@type table<integer, {comboInfo: ComboInfo, pos: Vector, expireTime: integer} | false | nil>
local tagretsLastSeenData = {}

local heroesCount = 0

local lastTickTime = 0
-- local a = 0
local function onUpdate()
	-- local curTime = GameRules.GetGameTime()
	-- if ((a + 5.8) < curTime) then
	-- 	a = curTime

	-- 	local heroes = Heroes.GetAll()

	-- 	local omnik, bara

	-- 	for i = 1, #heroes do
	-- 		local hero = heroes[i]

	-- 		if (NPC.GetUnitName(hero) == "npc_dota_hero_omniknight") then
	-- 			omnik = hero
	-- 		elseif (NPC.GetUnitName(hero) == "npc_dota_hero_spirit_breaker") then
	-- 			bara = hero
	-- 		end
	-- 	end

	-- 	if (omnik and bara) then
	-- 		Player.PrepareUnitOrders(
	-- 			Players.GetLocal(),
	-- 			Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
	-- 			bara,
	-- 			Vector(),
	-- 			NPC.GetAbility(omnik, "omniknight_martyr"),
	-- 			Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
	-- 			omnik,
	-- 			false,
	-- 			false,
	-- 			false,
	-- 			false,
	-- 			nil,
	-- 			false
	-- 		)
	-- 	end
	-- end

	if (not settings.enable:Get()) then
		return
	end

	local curTime = GameRules.GetGameTime()

	if ((lastTickTime + 0.1) > curTime) then
		return
	end

	lastTickTime = curTime

	localHero = localHero or Heroes.GetLocal()
	if (not localHero) then
		return
	end

	team = team or Entity.GetTeamNum(localHero)
	if (not team) then
		return
	end

	heroComboCalculator = heroComboCalculator or heroComboCalculators[NPC.GetUnitName(localHero)]
	if (not heroComboCalculator) then
		return
	end

	local oldTargetsData = targetsData
	targetsData = {}

	local heroes = Heroes.GetAll()

	-- can't be constant due to illussions and etc
	heroesCount = #heroes

	local lastSeenEnabled = lastSeenPotision:IsEnabled()

	for heroNum = 1, heroesCount do
		local target = heroes[heroNum]

		if (Entity.GetTeamNum(target) == team or not Entity.IsAlive(target)) then
			goto onUpdateContinue
		end

		if (NPC.IsIllusion(target)) then
			local illusionHandler = illusionHandlers[NPC.GetUnitName(target)]

			if (not illusionHandler or not illusionHandler(target)) then
				goto onUpdateContinue
			end
		end

		if (not NPC.IsVisible(target)) then
			if (lastSeenEnabled and tagretsLastSeenData[heroNum] == nil) then
				-- it's same as Hero.GetLastMaphackPos(target)
				-- but GetLastMaphackPos need a few ticks to update and oldTargetsData[heroNum] becomes nil
				local lastSeenPos = Entity.GetAbsOrigin(target)

				local comboInfo = oldTargetsData[heroNum]

				if (comboInfo) then
					tagretsLastSeenData[heroNum] = {
						comboInfo = comboInfo,
						pos = lastSeenPos,
						expireTime = curTime + lastSeenPotision:GetDuration() - .1,
					}
				end
			end
		else
			tagretsLastSeenData[heroNum] = nil

			local comboInfo = createComboInfo(localHero, target)

			if (NPC.HasItem(localHero, "item_refresher")) then
				comboInfo.hasRefresher = true
			end

			comboInfo:ApplyArmorReductions()

			heroComboCalculator(comboInfo)

			targetsData[heroNum] = comboInfo
		end

		::onUpdateContinue::
	end
end

local backgroundColor = Color(20, 20, 20)

local greenColor = Color(30, 230, 30)
local redColor = Color(230, 30, 30)
local whiteColor = Color(255, 255, 255)

local refresherImageHandle = Render.LoadImage("panorama/images/items/refresher_png.vtex_c")
local refresherIconSize = { x = 18, y = 12 }
local scaledRefresherIconSize = Vec2(refresherIconSize.x, refresherIconSize.y)

local abilityIconSize = { x = 14, y = 14 }
local scaledAbilityIconSize = Vec2(abilityIconSize.x, abilityIconSize.y)

local fontSize = 13
local fontHandle = 1

local spacing = 4

---:))))))))))))))))
---@param font integer
---@param fontSize integer
---@param text string
---@return integer width, integer height
local function getTextSize(font, fontSize, text)
	local size = Render.TextSize(font, fontSize, text)

	return size.x, size.y * .625
end

---:))))))))))))))))))))))))))))))
---@param font integer The handle to the font used for drawing the text.
---@param fontSize number The size of the font.
---@param text string The text to be drawn.
---@param pos Vec2 The position where the text will be drawn.
---@param color Color The color of the text.
local function renderText(font, fontSize, text, pos, color)
	return Render.Text(font, fontSize, text, Vec2(pos.x, pos.y - Render.TextSize(fontHandle, fontSize, text).y * .168), color)
end

---@class TextInfo
---@field fontHandle integer
---@field fontSize integer
---@field text string
---@field pos Vec2
---@field color Color

---@class AbilityIconInfo
---@field imageHandle integer
---@field pos Vec2

local function onDraw()
	if (not settings.enable:Get()) then
		return
	end

	---@type boolean
	local showRefresher

	local curTime = GameRules.GetGameTime()

	for heroNum = 1, heroesCount do
		local comboInfo = targetsData[heroNum]

		local target, renderPos

		if (not comboInfo) then
			local lastSeenData = tagretsLastSeenData[heroNum]

			if (not lastSeenData) then
				goto onDrawContinue
			end

			if (curTime >= lastSeenData.expireTime) then
				tagretsLastSeenData[heroNum] = false
				goto onDrawContinue
			end

			comboInfo = lastSeenData.comboInfo
			target = comboInfo.target

			renderPos = lastSeenData.pos
		else
			target = comboInfo.target
			renderPos = Entity.GetAbsOrigin(target)
			renderPos.z = renderPos.z + NPC.GetHealthBarOffset(target)
		end

		showRefresher = showRefresher == nil and comboInfo.hasRefresher or showRefresher

		local screenPos, visible = Render.WorldToScreen(renderPos)

		if not visible then
			goto onDrawContinue
		end

		local backgroundWidth = 0

		---@type TextInfo[]
		local textInfos = {}
		---@type AbilityIconInfo[]
		local abilityIconInfos = {}
		---@type Vec2?
		local refresherPos

		local x = screenPos.x + settings.offsetX:Get()
		local y = screenPos.y + settings.offsetY:Get() - 68

		local scale = settings.scale:Get()

		local startY = y

		-- local scaledFontSize = math.floor(fontSize * scale)
		local scaledSpacing = spacing * scale
		local scaledFontSize = fontSize * scale
		scaledRefresherIconSize.x = refresherIconSize.x * scale
		scaledRefresherIconSize.y = refresherIconSize.y * scale
		scaledAbilityIconSize.x = abilityIconSize.x * scale
		scaledAbilityIconSize.y = abilityIconSize.y * scale

		if (showRefresher) then
			local healthWithRefresher = comboInfo.health

			if (comboInfo.targetIsMedusa) then
				if (not medusaManaShieldCache) then
					medusaManaShieldCache = createMedusaManaShieldCache(comboInfo.target)
				end

				healthWithRefresher = healthWithRefresher
					+ comboInfo.mana
					* (medusaManaShieldCache.baseDamagePerMana + medusaManaShieldCache.damagePerManaPerLevel * comboInfo.level)
			end

			local healthWithRefresherString
			local healthWithRefresherColor

			if (healthWithRefresher <= 0) then
				healthWithRefresherString = "KILL (" .. math.floor(comboInfo.totalDamage) .. ")"
				healthWithRefresherColor = greenColor
			else
				healthWithRefresherString = math.floor(healthWithRefresher) .. " HP (" .. math.floor(comboInfo.totalDamage) .. ")"
				healthWithRefresherColor = redColor
			end

			y = y - scaledSpacing

			local textWidth, textHeight = getTextSize(fontHandle, scaledFontSize, healthWithRefresherString)

			table.insert(textInfos, {
				fontHandle = fontHandle,
				fontSize = scaledFontSize,
				text = healthWithRefresherString,
				pos = Vec2(x - textWidth / 2 + scaledRefresherIconSize.x / 2, y - textHeight),
				color = healthWithRefresherColor,
			} --[[@as TextInfo]])

			refresherPos = Vec2(x - textWidth / 2 - scaledSpacing, y - textHeight / 2)

			y = y - textHeight

			-- y = y - spacing

			-- local abilityOrder = comboInfo.abilityOrder
			-- local abilityOrderLength = #abilityOrder

			-- local abilityLineWidth = scaledAbilityIconSize.x * abilityOrderLength + spacing * (abilityOrderLength - 1)

			-- for abilityNum = 1, abilityOrderLength do
			-- 	table.insert(abilityIconInfos, {
			-- 		imageHandle = utils:GetAbilityIcon(abilityOrder[abilityNum]),
			-- 		pos = Vec2(
			-- 			x - abilityLineWidth / 2 + (scaledAbilityIconSize.x + spacing) * (abilityNum - 1),
			-- 			y - scaledAbilityIconSize.y
			-- 		),
			-- 	} --[[@as AbilityIconInfo]])
			-- end

			-- if (#abilityIconInfos ~= 0) then
			-- 	y = y - scaledAbilityIconSize.y
			-- end

			-- backgroundWidth = math.max(abilityLineWidth, textWidth + scaledRefresherIconSize.x + scaledSpacing)

			backgroundWidth = textWidth + scaledRefresherIconSize.x + scaledSpacing
		end

		local healthWithoutRefresher = comboInfo.healthWithoutRefresher

		local healthWithoutRefresherString
		local healthWithoutRefresherColor

		if (comboInfo.healthWithoutRefresher <= 0) then
			healthWithoutRefresherString = "KILL (" .. math.floor(comboInfo.totalDamageWithoutRefresher) .. ")"
			healthWithoutRefresherColor = greenColor
		else
			if (comboInfo.targetIsMedusa) then
				if (not medusaManaShieldCache) then
					medusaManaShieldCache = createMedusaManaShieldCache(comboInfo.target)
				end

				healthWithoutRefresher = healthWithoutRefresher
					+ comboInfo.manaWithoutRefresher
					* (medusaManaShieldCache.baseDamagePerMana + medusaManaShieldCache.damagePerManaPerLevel * comboInfo.level)
			end

			healthWithoutRefresherString = math.floor(healthWithoutRefresher) .. " HP (" .. math.floor(comboInfo.totalDamageWithoutRefresher) .. ")"
			healthWithoutRefresherColor = redColor
		end

		y = y - scaledSpacing

		local textWidth, textHeight = getTextSize(fontHandle, scaledFontSize, healthWithoutRefresherString)

		table.insert(textInfos, {
			fontHandle = fontHandle,
			fontSize = scaledFontSize,
			text = healthWithoutRefresherString,
			pos = Vec2(x - textWidth / 2, y - textHeight),
			color = healthWithoutRefresherColor,
		} --[[@as TextInfo]])

		y = y - textHeight

		y = y - scaledSpacing

		-- local abilityOrder = comboInfo.abilityOrderWithoutRefresher
		-- local abilityOrderLength = #abilityOrder

		-- local abilityLineWidth = scaledAbilityIconSize.x * abilityOrderLength + spacing * (abilityOrderLength - 1)

		-- for abilityNum = 1, abilityOrderLength do
		-- 	table.insert(abilityIconInfos, {
		-- 		imageHandle = utils:GetAbilityIcon(abilityOrder[abilityNum]),
		-- 		pos = Vec2(
		-- 			x - abilityLineWidth / 2 + (scaledAbilityIconSize.x + spacing) * (abilityNum - 1),
		-- 			y - scaledAbilityIconSize.y
		-- 		),
		-- 	} --[[@as AbilityIconInfo]])
		-- end

		-- if (#abilityIconInfos ~= 0) then
		-- 	y = y - scaledAbilityIconSize.y - scaledSpacing
		-- end

		-- backgroundWidth = math.max(backgroundWidth, textWidth, abilityLineWidth)

		backgroundWidth = math.max(backgroundWidth, textWidth)

		Render.FilledRect(
			Vec2(x - backgroundWidth * .5 - scaledSpacing, y),
			Vec2(x + backgroundWidth * .5 + scaledSpacing, startY),
			backgroundColor, 0
		)

		for i = 1, #textInfos do
			local text = textInfos[i]

			renderText(text.fontHandle, text.fontSize, text.text, text.pos, text.color)
		end

		for i = 1, #abilityIconInfos do
			local abilityIcon = abilityIconInfos[i]

			Render.Image(abilityIcon.imageHandle, abilityIcon.pos, scaledAbilityIconSize, whiteColor)
		end

		if (refresherPos) then
			Render.ImageCentered(refresherImageHandle, refresherPos, scaledRefresherIconSize, whiteColor)
		end

		::onDrawContinue::
	end
end

return {
	OnUpdate = onUpdate,
	OnDraw = onDraw,
	OnGameEnd = onGameEnd,
} --[[@as Callbacks]]

--#endregion In-Game Handlers
