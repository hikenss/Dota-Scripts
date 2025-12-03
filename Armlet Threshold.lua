-- Armlet Abuse with Modular Incoming Damage Detection



local example = {}

local ui = {}



local tab = Menu.Create("Miscellaneous", "In Game", "Armlet Abuse")

local group = tab:Create("Main"):Create("Armlet Abuse")

local ht = Menu.Find("Miscellaneous", "In Game", "Armlet Abuse", "Main", "Armlet Abuse", "HP Threshold")



ui.global_switch = group:Switch("Limiar Automático", false)

ui.notifis = group:Switch("Ativar Notificações", false)

ui.custom_radius = group:Slider("Raio de Varredura de Inimigos", 0, 1200, 800, function(value)

    return value == 0 and "Desativado" or tostring(value)

end)

ui.custom_radius:Icon("\u{f1ce}")

ui.reset_delay = group:Slider("Atraso de Reset (seg)", 1, 10, 5, function(value)

    return string.format("%ds", value)

end)



ui.global_switch:SetCallback(function()

    ui.custom_radius:Disabled(not ui.global_switch:Get())

    ui.reset_delay:Disabled(not ui.global_switch:Get())

end, true)



local my_hero = nil

local font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)



local maxIncomingDamage = 0

local lastThreatTime = 0

local lastSetThreshold = 0



local function clamp(value, minVal, maxVal)

    if value < minVal then return minVal end

    if value > maxVal then return maxVal end

    return value

end



local function CalculateActualDamageToLocalHero(ability, rawDamage)

    local dmgType = Ability.GetDamageType(ability)

    if dmgType == Enum.DamageTypes.DAMAGE_TYPE_MAGICAL then

        return rawDamage * (1 - NPC.GetMagicalArmorValue(my_hero))

    elseif dmgType == Enum.DamageTypes.DAMAGE_TYPE_PHYSICAL then

        return rawDamage * NPC.GetArmorDamageMultiplier(my_hero)

    elseif dmgType == Enum.DamageTypes.DAMAGE_TYPE_PURE then

        return rawDamage

    elseif dmgType == Enum.DamageTypes.DAMAGE_TYPE_HP_REMOVAL then

        return rawDamage

    end

    return 0

end



local function GetFlexibleAbilityDamage(ability)

    if not ability then return 0 end



    local level = Ability.GetLevel(ability)

    if level <= 0 then return 0 end



    local abilityName = Ability.GetName(ability)

    local heroName = string.match(abilityName, "([^_]+)")



    local possibleKeys = {

        "max_damage",

        "damage",

        abilityName .. "_damage",

    }



    if heroName then

        local nameWithoutHero = string.gsub(abilityName, heroName .. "_", "")

        table.insert(possibleKeys, nameWithoutHero .. "_damage")

    end



    for _, key in ipairs(possibleKeys) do

        local val = Ability.GetLevelSpecialValueFor(ability, key, -1)

        if val and val ~= 0 then

            if type(val) == "table" and val.value then

                local split = tostring(val.value):split(" ")

                return tonumber(split[level]) or tonumber(split[1]) or 0

            end



            -- Handle string like "100 200 300"

            if type(val) == "string" then

                local split = tostring(val):split(" ")

                return tonumber(split[level]) or tonumber(split[1]) or 0

            end



            -- Handle direct number (unlikely but safe)

            if type(val) == "number" then

                return val

            end

        end

    end



    return 0

end



local function GetEffectiveAbilityDamage(ability)

    local rawDmg = GetFlexibleAbilityDamage(ability)

    return CalculateActualDamageToLocalHero(ability, rawDmg)

end



local function GetBaseAttackDamage(enemy)

    -- local minDmg = NPC.GetMinDamage(enemy)

    -- local maxDmg = NPC.GetMaxDamage(enemy)

    -- local baseDmg = (minDmg + maxDmg) * 0.5

    local baseDmg = NPC.GetTrueMaximumDamage(enemy)

    local critMultiplier = 1



    if NPC.HasItem(enemy, "item_greater_crit") then

        critMultiplier = 2.25

    elseif NPC.HasItem(enemy, "item_lesser_crit") then

        critMultiplier = 1.6

    elseif NPC.HasItem(enemy, "item_giant_maul") then

        critMultiplier = 1.5

    end



    return baseDmg * critMultiplier

end



local function GetBonusAttackEffects(enemy, baseDmg)

    local bonusDmg = 0

    local resist = NPC.GetMagicalArmorValue(my_hero)

    local armorMult = NPC.GetArmorDamageMultiplier(my_hero)



    if NPC.HasItem(enemy, "item_revenants_brooch") then

        bonusDmg = bonusDmg + (baseDmg * 0.8 * (1 - resist))

    end



    if NPC.HasItem(enemy, "item_gunpowder_gauntlets") then

        bonusDmg = bonusDmg + (120 * (1 - resist))

    end



    if NPC.HasItem(enemy, "item_serrated_shiv") then

        bonusDmg = bonusDmg + (Entity.GetHealth(my_hero) * 0.08 * armorMult)

    end



    return bonusDmg

end



local function ApplyDamageBlock(dmg)

    local block = 0



    if NPC.HasItem(my_hero, "item_poor_mans_shield", true) then

        block = block + (NPC.IsRanged(my_hero) and 20 or 30)

    end



    -- Disabled them because they are chance based

    -- if NPC.HasItem(my_hero, "item_vanguard", true) then

    --     block = block + (NPC.IsRanged(my_hero) and 25 or 50)

    -- end



    -- if NPC.HasItem(my_hero, "item_crimson_guard", true) then

    --     block = block + (NPC.IsRanged(my_hero) and 50 or 75)

    -- end



    return math.max(0, dmg - block)

end



local function ScanMostDangerousAbility()

    if not Entity.IsAlive(my_hero) then return end



    local radius = ui.custom_radius:Get()

    if radius == 0 then return end



    local enemies = Entity.GetHeroesInRadius(my_hero, radius, Enum.TeamType.TEAM_ENEMY, true, true)

    if #enemies == 0 then return end



    lastThreatTime = os.clock()



    local topDmg = 0

    local totalPotentialDamage = 0



    for _, enemy in ipairs(enemies) do

        for i = 0, 23 do

            local ability = NPC.GetAbilityByIndex(enemy, i)

            local lvl = Ability.GetLevel(ability)

            if ability and not Ability.IsHidden(ability) and Ability.IsReady(ability)

                and lvl > 0 and not Ability.IsPassive(ability) then

                local actualDmg = GetEffectiveAbilityDamage(ability)

                totalPotentialDamage = totalPotentialDamage + actualDmg

                if actualDmg > topDmg then

                    topDmg = actualDmg

                end

            end

        end



        local base = GetBaseAttackDamage(enemy)

        local phys = base * NPC.GetArmorDamageMultiplier(my_hero)

        phys = ApplyDamageBlock(phys)

        local bonus = GetBonusAttackEffects(enemy, base)



        local total = phys + bonus



        totalPotentialDamage = totalPotentialDamage + total

        if total > topDmg then

            topDmg = total

        end

    end



    if totalPotentialDamage > maxIncomingDamage then

        maxIncomingDamage = totalPotentialDamage

    end



    local clamped = math.floor(clamp(maxIncomingDamage, 200, 500))

    if ht and clamped ~= lastSetThreshold then

        ht:Set(clamped)

        lastSetThreshold = clamped

        if ui.notifis:Get() then

            Notification({

                duration = 3,

                timer = 3,

                primary_text = "Auto Threshold",

                primary_image = "panorama/images/emoticons/dotakin_roshan_stars_png.vtex_c",

                secondary_image = "\u{2b}",

                secondary_text = "Alterado para " .. clamped,

            })

        end

    end

end



local initialThreshold = 250



-- if ht then

--     initialThreshold = ht:Get()

-- end



example.OnUpdate = function()

    if not ui.global_switch:Get() then return end



    if not my_hero then

        my_hero = Heroes.GetLocal()

        return

    end

    ScanMostDangerousAbility()

    if not NPC.HasItem(my_hero, "item_armlet", true) then return end

    local resetDelay = ui.reset_delay:Get()

    if os.clock() - lastThreatTime > resetDelay and maxIncomingDamage ~= initialThreshold then

        maxIncomingDamage = initialThreshold



        if ht then

            ht:Set(initialThreshold)

            lastSetThreshold = initialThreshold

            if ui.notifis:Get() then

                Notification({

                    duration = 3,

                    timer = 3,

                    primary_text = "Auto Threshold",

                    primary_image = "panorama/images/emoticons/dotakin_roshan_stars_png.vtex_c",

                    secondary_image = "\u{2b}",

                    secondary_text = "Limiar resetado para " .. initialThreshold,

                })

            end

        end

    end

end



return example

