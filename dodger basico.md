-- Advanced Dodger Script
-- Menu: General -> Main -> Dodger

local Dodger = {}

-- Menu configuration
local menudodger = Menu.Find("General", "Main", "Dodger")
if not menudodger then
    print("Advanced Dodger couldn't find original dodger. Script deactivated")
    return Dodger
end
local customfeatures = menudodger:Create("Custom Features")
customfeatures:Image("panorama/images/control_icons/star_filled_png.vtex_c")

-- Seções organizadas dentro de customfeatures
local menuMain = customfeatures:Create("Main Settings", Enum.GroupSide.Left)
local menuItems = customfeatures:Create("Items", Enum.GroupSide.Right)
local menuAbilities = customfeatures:Create("Abilities", Enum.GroupSide.Right)
local menuAllies = customfeatures:Create("Allies", Enum.GroupSide.Right)

local ui = {}

-- Main Section - Condições de dodge
ui.enabled = menuMain:Switch("Enable Dodger", true, "\u{f00c}")
ui.bypass_protection = menuMain:Switch("Use everything even invisible", false, "\u{f05e}")
ui.deathward_dodge = menuMain:Switch("Dodge Death Ward", true, "panorama/images/spellicons/witch_doctor_death_ward_png.vtex_c")
ui.blink_dodge = menuMain:Switch("Anti-Blink Dodge", true, "panorama/images/items/blink_png.vtex_c")
ui.blink_dodge:ToolTip("Dodge if enemy blinks closer, before he starts")


-- Items Section - Itens defensivos com ícones
ui.defensive_items = menuItems:MultiSelect("Defensive Items", {
    { "item_ghost", "panorama/images/items/ghost_png.vtex_c", true },
    { "item_wind_waker", "panorama/images/items/wind_waker_png.vtex_c", true },
    { "item_cyclone", "panorama/images/items/cyclone_png.vtex_c", true },
    { "item_glimmer_cape", "panorama/images/items/glimmer_cape_png.vtex_c", true },
    { "item_lotus_orb", "panorama/images/items/lotus_orb_png.vtex_c", true },
    { "item_ethereal_blade", "panorama/images/items/ethereal_blade_png.vtex_c", true },
    { "item_invis_sword", "panorama/images/items/invis_sword_png.vtex_c", true },
    { "item_silver_edge", "panorama/images/items/silver_edge_png.vtex_c", true },
    { "item_shadow_amulet", "panorama/images/items/shadow_amulet_png.vtex_c", true }
}, true)

-- Abilities Section - Habilidades defensivas com ícones
ui.defensive_abilities = menuAbilities:MultiSelect("Defensive Abilities", {
    { "nyx_assassin_vendetta", "panorama/images/spellicons/nyx_assassin_vendetta_png.vtex_c", true },
    { "puck_phase_shift", "panorama/images/spellicons/puck_phase_shift_png.vtex_c", true },
    { "ember_spirit_sleight_of_fist", "panorama/images/spellicons/ember_spirit_sleight_of_fist_png.vtex_c", true },
    --{ "invoker_ghost_walk", "panorama/images/spellicons/invoker_ghost_walk_png.vtex_c", true },
    --{ "oracle_fates_edict", "panorama/images/spellicons/oracle_fates_edict_png.vtex_c", true },
    { "dazzle_shallow_grave", "panorama/images/spellicons/dazzle_shallow_grave_png.vtex_c", true },
    --{ "omniknight_guardian_angel", "panorama/images/spellicons/omniknight_guardian_angel_png.vtex_c", true },
    --{ "winter_wyvern_cold_embrace", "panorama/images/spellicons/winter_wyvern_cold_embrace_png.vtex_c", true }
}, true)

-- Allies Section - Configurações de suporte
ui.allies_support = menuAllies:Switch("Use Items/Spells on Allies", false, "\u{f0c0}")
ui.allies_items = menuAllies:MultiSelect("Items for Allies", {
    { "item_wind_waker", "panorama/images/items/wind_waker_png.vtex_c", true },
    { "item_cyclone", "panorama/images/items/cyclone_png.vtex_c", true },
    { "item_glimmer_cape", "panorama/images/items/glimmer_cape_png.vtex_c", true },
    { "item_lotus_orb", "panorama/images/items/lotus_orb_png.vtex_c", true },
    { "item_ethereal_blade", "panorama/images/items/ethereal_blade_png.vtex_c", true },
    { "item_shadow_amulet", "panorama/images/items/shadow_amulet_png.vtex_c", true }
}, true)

-- Tabela para rastrear posições anteriores dos inimigos
local enemyPositions = {}
local blinkCooldowns = {}

-- Função para verificar se um item está disponível
local function IsItemAvailable(itemName, hero)
    for i = 0, 15 do
        local item = NPC.GetItemByIndex(hero, i)
        if item and Ability.GetName(item) == itemName then
            if Ability.IsCastable(item, NPC.GetMana(hero)) then
                return item
            end
        end
    end
    return nil
end

-- Função para verificar se uma habilidade está disponível
local function IsAbilityAvailable(abilityName, hero)
    for i = 0, 15 do
        local ability = NPC.GetAbilityByIndex(hero, i)
        if ability and Ability.GetName(ability) == abilityName then
            if Ability.IsCastable(ability, NPC.GetMana(hero)) then
                return ability
            end
        end
    end
    return nil
end

-- Função para verificar se já está sob efeito de proteção
-- Função para verificar se já está sob efeito de proteção
local function IsAlreadyProtected(hero)
    local modifiers = NPC.GetModifiers(hero)
    if modifiers then
        for _, mod in pairs(modifiers) do
            local modName = Modifier.GetName(mod)
            if modName == "modifier_item_ghost_ethereal" or 
               modName == "modifier_item_ethereal_blade_ethereal" or
               modName == "modifier_item_glimmer_cape_fade" or
               modName == "modifier_item_lotus_orb_active" or
               modName == "modifier_nyx_assassin_vendetta" or
               modName == "modifier_eul_cyclone" or
               modName == "modifier_wind_waker_cyclone" or
               modName == "modifier_item_invisibility_edge_windwalk" or
               modName == "modifier_item_silver_edge_windwalk" or
               modName == "modifier_item_shadow_amulet_fade" then
                return true
            end
        end
    end
    return false
end

-- Função unificada para usar itens/feitiços defensivos
local function UseDefensiveItems(myHero)
    -- Verifica proteção apenas se o bypass não estiver ativado
    if not ui.bypass_protection:Get() and IsAlreadyProtected(myHero) then
        return false
    end
    
    -- Obter lista de itens habilitados
    local enabledItems = ui.defensive_items:ListEnabled()
    local enabledAbilities = ui.defensive_abilities:ListEnabled()
    
    -- Lista de itens defensivos em ordem de prioridade
    local defensiveItems = {
        {name = "item_ghost", castType = "noTarget", priority = 1},
        {name = "item_wind_waker", castType = "target", priority = 2},
        {name = "item_cyclone", castType = "target", priority = 3},
        {name = "item_glimmer_cape", castType = "target", priority = 4},
        {name = "item_lotus_orb", castType = "target", priority = 5},
        {name = "item_ethereal_blade", castType = "target", priority = 6},
        {name = "item_invis_sword", castType = "noTarget", priority = 7},
        {name = "item_silver_edge", castType = "noTarget", priority = 8},
        {name = "item_shadow_amulet", castType = "target", priority = 9}
    }
    
    -- Função para verificar se item está na lista habilitada
    local function IsItemEnabled(itemName)
        for _, name in ipairs(enabledItems) do
            if name == itemName then return true end
        end
        return false
    end
    
    -- Função para verificar se habilidade está na lista habilitada
    local function IsAbilityEnabled(abilityName)
        for _, name in ipairs(enabledAbilities) do
            if name == abilityName then return true end
        end
        return false
    end
    
    -- Tenta usar itens em ordem de prioridade
    for _, itemData in ipairs(defensiveItems) do
        if IsItemEnabled(itemData.name) then
            local item = IsItemAvailable(itemData.name, myHero)
            if item then
                if itemData.castType == "noTarget" then
                    Ability.CastNoTarget(item)
                    return true
                elseif itemData.castType == "target" then
                    Ability.CastTarget(item, myHero)
                    return true
                end
            end
        end
    end
    
    -- Habilidades defensivas específicas por herói
    local heroName = NPC.GetUnitName(myHero)
    
    -- Nyx Assassin - Vendetta
    if heroName == "npc_dota_hero_nyx_assassin" and IsAbilityEnabled("nyx_assassin_vendetta") then
        local vendetta = IsAbilityAvailable("nyx_assassin_vendetta", myHero)
        if vendetta then
            Ability.CastNoTarget(vendetta)
            return true
        end
    end
    
    -- Puck - Phase Shift
    if heroName == "npc_dota_hero_puck" and IsAbilityEnabled("puck_phase_shift") then
        local phaseShift = IsAbilityAvailable("puck_phase_shift", myHero)
        if phaseShift then
            Ability.CastNoTarget(phaseShift)
            return true
        end
    end
    
    -- Ember Spirit - Sleight of Fist
    if heroName == "npc_dota_hero_ember_spirit" and IsAbilityEnabled("ember_spirit_sleight_of_fist") then
        local sleight = IsAbilityAvailable("ember_spirit_sleight_of_fist", myHero)
        if sleight then
            local creeps = NPCs.GetAll()
            for _, creep in pairs(creeps) do
                if creep and Entity.IsAlive(creep) and not Entity.IsSameTeam(myHero, creep) then
                    local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(creep)):Length()
                    if distance <= 700 then
                        Ability.CastPosition(sleight, Entity.GetAbsOrigin(creep))
                        return true
                    end
                end
            end
        end
    end
    
    -- Invoker - Ghost Walk
    if heroName == "npc_dota_hero_invoker" and IsAbilityEnabled("invoker_ghost_walk") then
        local ghostWalk = IsAbilityAvailable("invoker_ghost_walk", myHero)
        if ghostWalk then
            Ability.CastNoTarget(ghostWalk)
            return true
        end
    end
    
    return false
end

-- Função para detectar se está sendo atacado pelo Death Ward
local function IsTargetedByDeathWard(myHero)
    local enemies = Heroes.GetAll()
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            -- Verifica se é Witch Doctor
            if NPC.GetUnitName(enemy) == "npc_dota_hero_witch_doctor" then
                -- Verifica se tem o modifier do Death Ward ativo
                local modifiers = NPC.GetModifiers(enemy)
                if modifiers then
                    for _, mod in pairs(modifiers) do
                        if Modifier.GetName(mod) == "modifier_witch_doctor_death_ward" then
                            -- Verifica se estamos no range do Death Ward (700 units)
                            local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length()
                            if distance <= 700 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Também verifica se existe uma Death Ward unit próxima
    local entities = NPCs.GetAll()
    for _, entity in pairs(entities) do
        if entity and Entity.IsAlive(entity) and not Entity.IsSameTeam(myHero, entity) then
            if NPC.GetUnitName(entity) == "npc_dota_witch_doctor_death_ward" then
                local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(entity)):Length()
                if distance <= 700 then -- Range do Death Ward
                    return true
                end
            end
        end
    end
    
    return false
end

-- Função para detectar blinks inimigos
local function DetectEnemyBlink(myHero)
    local enemies = Heroes.GetAll()
    local currentTime = GameRules.GetGameTime()
    
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyID = Entity.GetIndex(enemy)
            local currentPos = Entity.GetAbsOrigin(enemy)
            
            -- Verifica se temos posição anterior registrada
            if enemyPositions[enemyID] then
                local lastPos = enemyPositions[enemyID].pos
                local lastTime = enemyPositions[enemyID].time
                
                -- Calcula distância e tempo decorrido
                local distance = (currentPos - lastPos):Length()
                local timeDiff = currentTime - lastTime
                
                -- Detecta blink: movimento > 400 units em < 0.1 segundos
                if distance > 400 and timeDiff < 0.1 and timeDiff > 0 then
                    -- Verifica se o inimigo está próximo após o blink
                    local distanceToMe = (currentPos - Entity.GetAbsOrigin(myHero)):Length()
                    
                    -- Se o inimigo blinknou para perto (< 600 units) e não está em cooldown
                    if distanceToMe < 600 then
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 2.0 then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end
            end
            
            -- Atualiza posição do inimigo
            enemyPositions[enemyID] = {
                pos = currentPos,
                time = currentTime
            }
        end
    end
    
    return false
end

-- Função para detectar blink dagger/abilities específicas
local function DetectBlinkAbilities(myHero)
    local enemies = Heroes.GetAll()
    local currentTime = GameRules.GetGameTime()
    
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyID = Entity.GetIndex(enemy)
            local distanceToMe = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length()
            
            -- Verifica se está próximo após usar blink
            if distanceToMe < 500 then
                local modifiers = NPC.GetModifiers(enemy)
                if modifiers then
                    for _, mod in pairs(modifiers) do
                        local modName = Modifier.GetName(mod)
                        
                        -- Detecta modifiers de blink recentes
                        if modName == "modifier_item_blink_cooldown" or
                           modName == "modifier_antimage_blink" or
                           modName == "modifier_queenofpain_blink" or
                           modName == "modifier_phantom_assassin_phantom_strike" or
                           modName == "modifier_riki_blink_strike" or
                           -- Faceless Void Timewalk
                           modName == "modifier_faceless_void_time_walk" or
                           -- Spirit Breaker Charge
                           modName == "modifier_spirit_breaker_charge_of_darkness" or
                           -- Pudge Hook (movimento forçado)
                           modName == "modifier_pudge_meat_hook" or
                           -- Puck Illusory Orb
                           modName == "modifier_puck_illusory_orb" or
                           -- Ember Spirit Sleight of Fist
                           modName == "modifier_ember_spirit_sleight_of_fist_caster" or
                           -- Storm Spirit Ball Lightning
                           modName == "modifier_storm_spirit_ball_lightning" or
                           -- Void Spirit Dissimilate
                           modName == "modifier_void_spirit_dissimilate" or
                           -- Mirana Leap
                           modName == "modifier_mirana_leap" or
                           -- Slark Pounce
                           modName == "modifier_slark_pounce" or
                           -- Magnus Skewer
                           modName == "modifier_magnataur_skewer_movement" or
                           -- Invoker Ghost Walk
                           modName == "modifier_invoker_ghost_walk" or
                           -- Nature's Prophet Teleportation
                           modName == "modifier_furion_teleportation" or
                           -- Spectre Haunt
                           modName == "modifier_spectre_haunt" or
                           -- Vengeful Spirit Nether Swap
                           modName == "modifier_vengefulspirit_nether_swap" or
                           -- Morphling Waveform
                           modName == "modifier_morphling_waveform" or
                           -- Pangolier Rolling Thunder
                           modName == "modifier_pangolier_gyroshell" or
                           -- Tusk Snowball
                           modName == "modifier_tusk_snowball_movement" or
                           -- Earth Spirit Boulder Smash/Rolling Boulder
                           modName == "modifier_earth_spirit_rolling_boulder_caster" or
                           modName == "modifier_earth_spirit_boulder_smash" or
                           -- Monkey King Tree Dance
                           modName == "modifier_monkey_king_tree_dance" or
                           -- Weaver Time Lapse (movimento de retorno)
                           modName == "modifier_weaver_time_lapse" or
                           -- Lifestealer Infest
                           modName == "modifier_life_stealer_infest" or
                           -- Phoenix Icarus Dive
                           modName == "modifier_phoenix_icarus_dive" or
                           -- Clockwerk Hookshot
                           modName == "modifier_rattletrap_hookshot" or
                           -- Batrider Flaming Lasso (movimento forçado)
                           modName == "modifier_batrider_flaming_lasso" or
                           -- Huskar Life Break
                           modName == "modifier_huskar_life_break_charge" or
                           -- Sand King Burrowstrike
                           modName == "modifier_sandking_burrowstrike" or
                           -- Centaur Stampede
                           modName == "modifier_centaur_stampede" then
                            if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 1.5 then
                                blinkCooldowns[enemyID] = currentTime
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    return false
end

-- Nova função para usar itens defensivos em aliados
local function UseDefensiveItemsOnAllies(myHero, targetHero)
    if IsAlreadyProtected(targetHero) then
        return false
    end
    
    -- Obter lista de itens habilitados para aliados
    local enabledAllyItems = ui.allies_items:ListEnabled()
    local enabledAbilities = ui.defensive_abilities:ListEnabled()
    
    -- Função para verificar se item está na lista habilitada
    local function IsItemEnabled(itemName)
        for _, name in ipairs(enabledAllyItems) do
            if name == itemName then return true end
        end
        return false
    end
    
    -- Função para verificar se habilidade está na lista habilitada
    local function IsAbilityEnabled(abilityName)
        for _, name in ipairs(enabledAbilities) do
            if name == abilityName then return true end
        end
        return false
    end
    
    -- Lista de itens defensivos que podem ser usados em aliados
    local defensiveItems = {
        {name = "item_wind_waker", castType = "target", priority = 1},
        {name = "item_cyclone", castType = "target", priority = 2},
        {name = "item_glimmer_cape", castType = "target", priority = 3},
        {name = "item_lotus_orb", castType = "target", priority = 4},
        {name = "item_ethereal_blade", castType = "target", priority = 5}
    }
    
    -- Tenta usar itens em ordem de prioridade
    for _, itemData in ipairs(defensiveItems) do
        if IsItemEnabled(itemData.name) then
            local item = IsItemAvailable(itemData.name, myHero)
            if item then
                if itemData.castType == "target" then
                    Ability.CastTarget(item, targetHero)
                    return true
                end
            end
        end
    end
    
    -- Habilidades defensivas específicas por herói que podem ser usadas em aliados
    local heroName = NPC.GetUnitName(myHero)
    
    -- Dazzle - Shallow Grave
    if heroName == "npc_dota_hero_dazzle" and IsAbilityEnabled("dazzle_shallow_grave") then
        local shallowGrave = IsAbilityAvailable("dazzle_shallow_grave", myHero)
        if shallowGrave then
            Ability.CastTarget(shallowGrave, targetHero)
            return true
        end
    end
    
    return false
end

-- Nova função para verificar se um aliado está em perigo
local function IsAllyInDanger(ally)
    -- Verifica Death Ward
    local enemies = Heroes.GetAll()
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(ally, enemy) then
            if NPC.GetUnitName(enemy) == "npc_dota_hero_witch_doctor" then
                local modifiers = NPC.GetModifiers(enemy)
                if modifiers then
                    for _, mod in pairs(modifiers) do
                        if Modifier.GetName(mod) == "modifier_witch_doctor_death_ward" then
                            local distance = (Entity.GetAbsOrigin(ally) - Entity.GetAbsOrigin(enemy)):Length()
                            if distance <= 700 then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Verifica Death Ward units
    local entities = NPCs.GetAll()
    for _, entity in pairs(entities) do
        if entity and Entity.IsAlive(entity) and not Entity.IsSameTeam(ally, entity) then
            if NPC.GetUnitName(entity) == "npc_dota_witch_doctor_death_ward" then
                local distance = (Entity.GetAbsOrigin(ally) - Entity.GetAbsOrigin(entity)):Length()
                if distance <= 700 then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Main dodger logic
function Dodger.OnUpdate()
    local myHero = Heroes.GetLocal()
    if not myHero or not Entity.IsAlive(myHero) or not ui.enabled:Get() then
        return
    end
    
    -- Verifica se a opção Anti-Blink está ativada e detecta blinks
    if ui.blink_dodge:Get() and (DetectEnemyBlink(myHero) or DetectBlinkAbilities(myHero)) then
        UseDefensiveItems(myHero)
    end
    
    -- Verifica se a opção Death Ward está ativada e detecta Death Ward
    if ui.deathward_dodge:Get() and IsTargetedByDeathWard(myHero) then
        UseDefensiveItems(myHero)
    end
    
    -- Lógica para suporte a aliados
    if ui.allies_support:Get() then
        local alliesInRadius = Entity.GetHeroesInRadius(myHero, 2000, Enum.TeamType.TEAM_FRIEND, false)
        
        for _, ally in pairs(alliesInRadius) do
            if ally and Entity.IsAlive(ally) and ally ~= myHero then
                local allyInDanger = false
                
                -- Verifica Death Ward no aliado
                if ui.deathward_dodge:Get() and IsTargetedByDeathWard(ally) then
                    allyInDanger = true
                end
                
                -- Verifica outras ameaças
                if IsAllyInDanger(ally) then
                    allyInDanger = true
                end
                
                -- Se o aliado está em perigo, tenta usar itens/habilidades defensivas
                if allyInDanger then
                    UseDefensiveItemsOnAllies(myHero, ally)
                end
            end
        end
    end
end

return Dodger