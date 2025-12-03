local OraclePlugin = {}
local ui = {}
local firstTab = Menu.Create("Heroes", "Hero List", "Oracle")
local subTab = firstTab:Create("Z-Plugin")
subTab:Icon("\u{E288}")
local protectionGroup = firstTab:Create("Z-Plugin"):Create("Proteção Automática")
ui.protectEnable = protectionGroup:Switch("Ultimate Automático", true)
ui.protectEnable:Image("panorama/images/spellicons/oracle_false_promise_png.vtex_c")
ui.protectList = protectionGroup:MultiSelect("Alvos de Proteção", {{"1", "", false}}, true)
ui.protectList:Icon("\u{E068}")
ui.singleTargetMode = protectionGroup:Switch("Focar Apenas Primeiro Vivo na Lista", false,"\u{E058}")
ui.enemyDetectionRange = protectionGroup:Slider("Alcance de Detecção de Inimigos", 300, 3000, 1200)
ui.enemyDetectionRange:Icon("\u{E105}")
ui.minHealthThreshold = protectionGroup:Slider("Condição 1: HP Mínimo Absoluto", 100, 2000, 200)
ui.minHealthThreshold:Icon("\u{E0B1}")
ui.minHealthPercentage = protectionGroup:Slider("Condição 2: HP Mínimo Percentual", 5, 100, 25)
ui.minHealthPercentage:Icon("\u{E0B1}")
ui.healthLossThreshold = protectionGroup:Slider("Condição 3: Perda Máxima de HP %", 20, 90, 40)
ui.healthLossThreshold:Icon("\u{E0B0}")
ui.healthLossTime = protectionGroup:Slider("Condição 3: Janela de Tempo", 0.1, 1.0, 0.2)
ui.healthLossTime:Icon("\u{F843}")
ui.useBlinkDagger = protectionGroup:Switch("Usar Blink Dagger", false)
ui.useBlinkDagger:Image("panorama/images/items/blink_png.vtex_c")
local ultimateGroup = firstTab:Create("Z-Plugin"):Create("Suporte Ultimate")
ui.autoSupportUltimateTarget = ultimateGroup:Switch("Usar Skills/Itens em Alvo do Ultimate", true)
ui.autoSupportUltimateTarget:Image("panorama/images/spellicons/oracle_false_promise_png.vtex_c")
ui.enabledSkills = ultimateGroup:MultiSelect("Habilidades Ativas", {{"1", "", false}}, true)
ui.enabledSkills:Icon("\u{F809}")
ui.enabledRecoverItems = ultimateGroup:MultiSelect("Itens de Recuperação Ativos", {{"1", "", false}}, true)
ui.enabledRecoverItems:Icon("\u{F7E6}")
ui.enabledItems = ultimateGroup:MultiSelect("Itens de Suporte Ativos", {{"1", "", false}}, true)
ui.enabledItems:Icon("\u{F7D4}")
local aimAllyGroup = firstTab:Create("Z-Plugin"):Create("Suporte de Cura")
ui.autoFireAlly = aimAllyGroup:Switch("Curar Auto Alvos com Fate's Edict", false, "\u{F82F}")
ui.autoFireBarrierAlly = aimAllyGroup:Switch("Curar Auto Alvos com Escudo", false, "\u{F82F}")
ui.autoFireAllyMaxHealthPercentage = aimAllyGroup:Slider("Percentual de HP do Alvo", 1, 95, 85)
ui.autoFireAllyMaxHealthPercentage:Icon("\u{E0B1}")
local aimEnemyGroup = firstTab:Create("Z-Plugin"):Create("Suporte Contra Inimigos")
ui.autoDisarmTarget = aimEnemyGroup:Switch("Desarmar Heróis Inimigos", false)
ui.autoDisarmTarget:Image("panorama/images/spellicons/oracle_fates_edict_png.vtex_c")
ui.onlyDisarmAttacking = aimEnemyGroup:Switch("Desarmar Apenas Inimigos Atacando", true)
ui.onlyDisarmAttacking:Icon("\u{F0E3}")
ui.disarmList = aimEnemyGroup:MultiSelect("Alvos para Desarmar", {{"1", "", false}}, true)
ui.disarmList:Icon("\u{F4FA}")
ui.autoFireEnemy = aimEnemyGroup:Switch("Purifying Flames após Fortune's End", false)
ui.autoFireEnemy:Icon("\u{2604}")
ui.fortunesEndKey = aimEnemyGroup:Bind("Tecla para Fortune's End", Enum.ButtonCode.KEY_Q, "\u{2604}")
local testGroup = firstTab:Create("Z-Plugin"):Create("Notas Importantes")
testGroup:Label("Script gratuito por: Mayfail","\u{26A0}")
local needsInitialization = true
local playerHero = nil
local allies = { ["heroName"] = { ["unit"] = nil, ["isProtect"] = false, ["previousHealth"] = 0 } }
local enemies = { ["heroName"] = { ["unit"] = nil } }
local actionCooldownEndTime = -100
local nextHealthRecordTime = -100
local RECOVER_SKILLS = {
    "oracle_purifying_flames", 
    "oracle_rain_of_destiny"   
}
local RECOVER_ITEMS = {
    "item_holy_locket",        
    "item_guardian_greaves",   
    "item_mekansm",            
    "item_cheese",             
    "item_famango",            
    "item_great_famango",      
    "item_greater_famango"     
}
local SUPPORT_ITEMS = {
    "item_crimson_guard",      
    "item_pipe",               
    "item_lotus_orb",          
    "item_glimmer_cape",       
    "item_solar_crest",        
    "item_pavise"              
}
local function GetBlink(target)
    return NPC.GetItem(target, "item_blink", true)
    or NPC.GetItem(target, "item_overwhelming_blink", true)
    or NPC.GetItem(target, "item_swift_blink", true)
    or NPC.GetItem(target, "item_arcane_blink", true)
end
local function GetAlliesTable(localHero)
    local allyHeroes = Entity.GetHeroesInRadius(localHero, 99999, Enum.TeamType.TEAM_FRIEND)
    local allyList = {}
    for _, hero in ipairs(allyHeroes) do
        local heroName = Entity.GetUnitName(hero)
		local start, _ = string.find(Entity.GetClassName(hero), "DOTA_Unit_Hero_")
        if start then
            allyList[heroName] = {
                unit = hero,
                isProtected = false,
                previousHealth = 0
            }
        end
    end
    return allyList
end
local function GetEnemiesTable(localHero)
    local enemyHeroes = Entity.GetHeroesInRadius(localHero, 99999, Enum.TeamType.TEAM_ENEMY)
    local enemyList = {}
    for _, hero in ipairs(enemyHeroes) do
        local heroName = Entity.GetUnitName(hero)
        local start, _ = string.find(Entity.GetClassName(hero), "DOTA_Unit_Hero_")
        if start then
            enemyList[heroName] = {
                unit = hero
            }
        end
    end
    return enemyList
end
local function UpdateProtectionStatus()
    local selectedAllies = ui.protectList:ListEnabled()
    for _, allyInfo in pairs(allies) do
        allyInfo.isProtected = false
    end
    for _, allyName in ipairs(selectedAllies) do
        local allyInfo = allies[allyName]
        if allyInfo then
            allyInfo.isProtected = true
        end
    end
end
local function NotTargetHaveModifiers(target, ...)
    local modifiers = {...}
    for i = 1, #modifiers do
        if NPC.HasModifier(target, modifiers[i]) then return false end
    end
    return true
end
local function NotTargetHaveStates(target, ...)
    local states = {...}
    for i = 1, #states do
        if NPC.HasState(target, states[i]) then return false end
    end
    return true
end
local function CheckAbility(ability)
    return ability and Ability.IsCastable(ability, NPC.GetMana(Heroes.GetLocal()))
end
local function CheckDistance(entity1, entity2, distance)
     return NPC.IsEntityInRange(entity1, entity2, distance)
end
local function GetDistance(entity1, entity2)
     return Entity.GetAbsOrigin(entity1):Distance2D(Entity.GetAbsOrigin(entity2))
end
local function AddToSelectionList(list, item)
    for _, existingItem in ipairs(list) do
        if existingItem[1] == item[1] then
            return
        end
    end
    table.insert(list, item)
end
local function InitializeSelectionLists()
    local skillList = {}
    for _, skillName in ipairs(RECOVER_SKILLS) do
        AddToSelectionList(skillList, {
            skillName,
            "panorama/images/spellicons/" .. skillName .. "_png.vtex_c",
            true
        })
    end
    ui.enabledSkills:Update(skillList, true)
    local itemList = {}
    for _, itemName in ipairs(RECOVER_ITEMS) do
        AddToSelectionList(itemList, {
            itemName,
            "panorama/images/items/" .. itemName:gsub("item_", "") .. "_png.vtex_c",
            true
        })
    end
    ui.enabledRecoverItems:Update(itemList, true)
    itemList = {}
    for _, itemName in ipairs(SUPPORT_ITEMS) do
        AddToSelectionList(itemList, {
            itemName,
            "panorama/images/items/" .. itemName:gsub("item_", "") .. "_png.vtex_c",
            true
        })
    end
    ui.enabledItems:Update(itemList, true)
    local heroList = {}
    for heroName, _ in pairs(allies) do
        table.insert(heroList, {
            heroName,
            "panorama/images/heroes/icons/" .. heroName .. "_png.vtex_c",
            true
        })
    end
    ui.protectList:Update(heroList, true)
    heroList = {}
    for heroName, _ in pairs(enemies) do
        table.insert(heroList, {
            heroName,
            "panorama/images/heroes/icons/" .. heroName .. "_png.vtex_c",
            false
        })
    end
    ui.disarmList:Update(heroList, true)
end
local function InitializePlugin()
    allies = GetAlliesTable(Heroes.GetLocal())
    enemies = GetEnemiesTable(Heroes.GetLocal())
    InitializeSelectionLists()
    actionCooldownEndTime = -100
    needsInitialization = false
end
local function HasBehaviorFlag(value, flag)
    if not value or not flag then
        return false
    end
    if bit32 and bit32.band then
        return bit32.band(value, flag) ~= 0
    end
    if bit and bit.band then
        return bit.band(value, flag) ~= 0
    end
    local success, result = pcall(function()
        return (value & flag) ~= 0
    end)
    if success then
        return result
    end
    return (value % (flag * 2)) >= flag
end
local function GetNextUsableAbility(caster, target, uiList)
    local enabledAbilities = uiList:ListEnabled()
    for _, abilityName in ipairs(enabledAbilities) do
        local ability = nil
        if string.match(abilityName, "item_([^%.]+)") then
            ability = NPC.GetItem(caster, abilityName, true)
        else
            ability = NPC.GetAbility(caster, abilityName)
        end
        local castRange = Ability.GetCastRange(ability)
        if castRange <= 0 then
            castRange = Ability.GetLevelSpecialValueFor(ability, "aura_radius") or 0
        end
        if ability
        and CheckAbility(ability)
        and CheckDistance(caster, target, castRange)
        then
            local behavior = Ability.GetBehavior(ability)
            if HasBehaviorFlag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
                return {
                    caster = caster,
                    target = target,
                    ability = ability,
                    castType = "target"
                }
            elseif HasBehaviorFlag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_POINT) then
                return {
                    caster = caster,
                    target = target,
                    ability = ability,
                    castType = "position"
                }
            elseif HasBehaviorFlag(behavior, Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_NO_TARGET) then
                return {
                    caster = caster,
                    target = target,
                    ability = ability,
                    castType = "no_target"
                }
            end
        end
    end
    return nil
end
local function CalculateKeepDistancePosition(entity1, entity2, keepDistance)
    local pos1 = Entity.GetAbsOrigin(entity1)
    local pos2 = Entity.GetAbsOrigin(entity2)
    local direction = pos1 - pos2
    local currentDistance = direction:Length()
    if currentDistance <= keepDistance then
        return pos1
    end
    direction:Normalize()
    local newPosition = pos2 + direction:Scaled(keepDistance)
    return newPosition
end
local function RecordAlliesHealth()
    for _, allyInfo in pairs(allies) do
        allyInfo.previousHealth = Entity.GetHealth(allyInfo.unit)
    end
end
local function FindEndangeredAlly()
    local selectedAllies = ui.protectList:ListEnabled()
    for _, allyName in ipairs(selectedAllies) do
        local allyInfo = allies[allyName]
        if Entity.IsAlive(allyInfo.unit)
        and not NPC.IsEntityInRange(playerHero, allyInfo.unit, 2500)
        then goto continue end
        local currentHealth = Entity.GetHealth(allyInfo.unit)
        local maxHealth = Entity.GetMaxHealth(allyInfo.unit)
        local healthLossPercentage = (allyInfo.previousHealth - currentHealth) / maxHealth
        local threshold = ui.healthLossThreshold:Get() / 100.0
        if allyInfo.isProtected
        and healthLossPercentage > threshold
        and NotTargetHaveModifiers(allyInfo.unit, "modifier_oracle_false_promise_timer")
        then
            return allyInfo.unit
        end
        if ui.singleTargetMode:Get() then
            return nil
        end
        ::continue::
    end
    return nil
end
local function GetCondition3Allies(ultimateAbility)
    local needHelpAllies = {}
    if nextHealthRecordTime > GameRules.GetGameTime() then return needHelpAllies end
    if Entity.IsAlive(playerHero)
    and CheckAbility(ultimateAbility)
    then
        UpdateProtectionStatus()
        if GameRules.GetGameTime() - nextHealthRecordTime < 1 then
            local endangeredAlly = FindEndangeredAlly()
            if endangeredAlly then
                table.insert(needHelpAllies, endangeredAlly)
            end
        end
    end
    RecordAlliesHealth()
    nextHealthRecordTime = GameRules.GetGameTime() + ui.healthLossTime:Get() 
    return needHelpAllies
end
local function GetCondition12Allies(ultimateAbility)
    local needHelpAllies = {}
    if CheckAbility(ultimateAbility) then
        local selectedAllies = ui.protectList:ListEnabled()
        for _, allyName in ipairs(selectedAllies) do
            local ally = allies[allyName] and allies[allyName].unit
            if not ally
            or not Entity.IsAlive(ally)
            or not NPC.IsEntityInRange(playerHero, ally, 2500) 
            then
                goto continue
            end
			
            local minHealth = ui.minHealthThreshold:Get()
            local calculatedMinHealth = Entity.GetMaxHealth(ally) * ui.minHealthPercentage:Get() / 100.0
            local dangerThreshold = math.max(minHealth, calculatedMinHealth)
            local nearbyEnemies = Entity.GetHeroesInRadius(ally, ui.enemyDetectionRange:Get(), Enum.TeamType.TEAM_ENEMY)
            if #nearbyEnemies > 0 then
                for _, enemy in ipairs(nearbyEnemies) do
                    local executeAbility = NPC.GetAbility(enemy, "axe_culling_blade")
                    if executeAbility then
                        local damage = Ability.GetDamage(executeAbility)
                        if damage <= 0 then
                            damage = Ability.GetLevelSpecialValueFor(executeAbility, "damage") or 0
                        end
                        local executeThreshold = damage + 100 + (10 * NPC.GetCurrentLevel(enemy))
                        dangerThreshold = math.max(dangerThreshold, executeThreshold)
                    end
                end
                if Entity.GetHealth(ally) <= dangerThreshold
                and NotTargetHaveModifiers(ally, "modifier_oracle_false_promise_timer")
                then
                    table.insert(needHelpAllies, ally)
                end
            end
            if ui.singleTargetMode:Get() then
                return needHelpAllies
            end
            ::continue::
        end
    end
    return needHelpAllies
end
local function AutoSupport()
    for _, allyInfo in pairs(allies) do
        local ally = allyInfo.unit
        if Entity.IsAlive(ally) then
            if NPC.HasModifier(ally, "modifier_oracle_false_promise_timer") then
                local abilityInfo = nil
                if NotTargetHaveModifiers(ally, "modifier_doom_bringer_doom", "modifier_ice_blast") then
                    abilityInfo = GetNextUsableAbility(playerHero, ally, ui.enabledSkills)
                    or GetNextUsableAbility(playerHero, ally, ui.enabledRecoverItems)
                    or GetNextUsableAbility(playerHero, ally, ui.enabledItems)
                else
                    abilityInfo = GetNextUsableAbility(playerHero, ally, ui.enabledItems)
                end
                if abilityInfo then
                    if abilityInfo.castType == "target" then
                        Ability.CastTarget(abilityInfo.ability, abilityInfo.target)
                    elseif abilityInfo.castType == "position" then
                        Ability.CastPosition(abilityInfo.ability, Entity.GetAbsOrigin(abilityInfo.target))
                    elseif abilityInfo.castType == "no_target" then
                        Ability.CastNoTarget(abilityInfo.ability)
                    end
                    actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(abilityInfo.ability)
                    return true
                end
            elseif NotTargetHaveModifiers(ally, "modifier_doom_bringer_doom", "modifier_ice_blast")
            and Entity.GetHealth(ally) < Entity.GetMaxHealth(ally) * (ui.autoFireAllyMaxHealthPercentage:Get() / 100.0)
            then
                local ability = NPC.GetAbility(playerHero, "oracle_purifying_flames")
                local barriers = NPC.GetBarriers(ally) 
                if (ui.autoFireAlly:Get() and NPC.HasModifier(ally, "modifier_oracle_fates_edict")) 
                or (ui.autoFireBarrierAlly:Get() and barriers and (barriers.magic.current > 0 or barriers.all.current > 0)) 
                then
                    if CheckAbility(ability) and CheckDistance(playerHero, ally, Ability.GetCastRange(ability)) then
                        Ability.CastTarget(ability, ally)
                        actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(ability)
                        return true
                    end
                end
            end
        end
    end
    return false
end
local function AutoUltimate()
    local ultimateAbility = NPC.GetAbility(playerHero, "oracle_false_promise")
    local allies = GetCondition3Allies(ultimateAbility)
	allies = #allies == 0 and GetCondition12Allies(ultimateAbility) or allies
    for i = 1, #allies do
        local ally = allies[i]
        local item_blink = GetBlink(playerHero)
        local distance = GetDistance(playerHero, ally)
        if ui.useBlinkDagger:Get()
        and CheckAbility(item_blink)
        and distance > Ability.GetCastRange(ultimateAbility) - 10
        and distance < Ability.GetCastRange(item_blink) + Ability.GetCastRange(ultimateAbility) - 100
        then
            local blinkPoint = CalculateKeepDistancePosition(playerHero, ally, Ability.GetCastRange(ultimateAbility) - 100)
            Ability.CastPosition(item_blink, blinkPoint)
            Ability.CastTarget(ultimateAbility, ally)
            actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(ultimateAbility) + Ability.GetCastPoint(item_blink) + 0.1
            return true
        end
        if distance < Ability.GetCastRange(ultimateAbility) then
            Ability.CastTarget(ultimateAbility, ally)
            actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(ultimateAbility)
            return true
        end
    end
    return false
end
local function AutoDisarm()
    local disarmAbility = NPC.GetAbility(playerHero, "oracle_fates_edict")
    if not CheckAbility(disarmAbility) then return false end
    local disarmRange = Ability.GetCastRange(disarmAbility)
    local selectedEnemies = ui.disarmList:ListEnabled()
    for _, enemyName in ipairs(selectedEnemies) do
        local enemy = enemies[enemyName] and enemies[enemyName].unit
        if enemy
        and Entity.IsAlive(enemy)
        and NPC.IsVisible(enemy)
        and (not ui.onlyDisarmAttacking:Get() or NPC.IsAttacking(enemy))
        and CheckDistance(playerHero, enemy, disarmRange - 10)
        and NotTargetHaveStates(enemy, Enum.ModifierState.MODIFIER_STATE_DISARMED, Enum.ModifierState.MODIFIER_STATE_DEBUFF_IMMUNE, Enum.ModifierState.MODIFIER_STATE_STUNNED, Enum.ModifierState.MODIFIER_STATE_HEXED)
        then
            Ability.CastTarget(disarmAbility, enemy)
            actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(disarmAbility)
            return true
        end
    end
    return false
end
local fireEnemy = nil
local fireEnemyWaitTimmer = -100
local function AutoFireEnemy()
    if fireEnemyWaitTimmer > GameRules.GetGameTime() then return false end
    local fortunesEndAbility = NPC.GetAbility(playerHero, "oracle_fortunes_end")
    if Input.IsKeyDown(ui.fortunesEndKey:Get()) and not fireEnemy
    then
        local selectEnemy = Input.GetNearestHeroToCursor(Entity.GetTeamNum(playerHero), Enum.TeamType.TEAM_ENEMY)
        local animaInfo = NPC.GetAnimationInfo(playerHero)
        if CheckAbility(fortunesEndAbility) or animaInfo.name == "cast1_FortunesEnd_channel" then
            fireEnemyWaitTimmer = GameRules.GetGameTime() + 0.1
            fireEnemy = selectEnemy
        end
        return false
    end
    if fireEnemy
    and not NPC.IsChannellingAbility(playerHero)
    and not CheckAbility(fortunesEndAbility)
    then
        local fireAbility = NPC.GetAbility(playerHero, "oracle_purifying_flames")
        local enemyBarrierValue = NPC.GetBarriers(fireEnemy) and (NPC.GetBarriers(fireEnemy).magic.current + NPC.GetBarriers(fireEnemy).all.current) or 0
        if CheckAbility(fireAbility)
        and CheckDistance(playerHero, fireEnemy, Ability.GetCastRange(fireAbility))
        and NotTargetHaveStates(fireEnemy, Enum.ModifierState.MODIFIER_STATE_DEBUFF_IMMUNE)
        and NPC.GetMagicalArmorValue(fireEnemy) < 0.8
        and enemyBarrierValue < 50
        then
            Ability.CastTarget(fireAbility, fireEnemy)
            actionCooldownEndTime = GameRules.GetGameTime() + Ability.GetCastPoint(fireAbility)
            fireEnemy = nil
            return true
        end
        fireEnemy = nil
        return false
    end
end
function OraclePlugin.OnUpdate()
    if not Engine.IsInGame() then
        return
    end
    playerHero = Heroes.GetLocal()
    if not playerHero or
       not Entity.IsAlive(playerHero) or
       NPC.GetUnitName(playerHero) ~= "npc_dota_hero_oracle"
    then
        return
    end
    if actionCooldownEndTime > GameRules.GetGameTime() then
        return
    end
    if needsInitialization then
        InitializePlugin()
    end
    if ui.protectEnable:Get() then
        if AutoUltimate()
        then return end
    end
    if ui.autoSupportUltimateTarget:Get() or ui.autoFireAlly:Get() or ui.autoFireBarrierAlly:Get() then
        if AutoSupport()
        then return end
    end
    if ui.autoDisarmTarget:Get() then
        if AutoDisarm()
        then return end
    end
    if ui.autoFireEnemy:Get() then
        if AutoFireEnemy()
        then return end
    end
end
return OraclePlugin