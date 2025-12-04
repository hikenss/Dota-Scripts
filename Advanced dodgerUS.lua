-- Advanced Dodger Script
-- Menu: General -> Main -> Dodger

local Dodger = {}
local WriteLog = function(...) end

-- Menu configuration
local menudodger = Menu.Find("General", "Main", "Dodger")
if not menudodger then
    print("Advanced Dodger couldn't find original dodger. Script deactivated")
    return Dodger
end
local customfeatures = menudodger:Create("Custom Features 2.0")
customfeatures:Image("panorama/images/control_icons/star_filled_png.vtex_c")

-- Sections inside Custom Features
local menuMain = customfeatures:Create("Main Settings", Enum.GroupSide.Left)
local menuItems = customfeatures:Create("Items", Enum.GroupSide.Left)
local menuAbilities = customfeatures:Create("Abilities", Enum.GroupSide.Left)
local menuAllies = customfeatures:Create("Allies", Enum.GroupSide.Right)

local ui = {}

-- Main Section
ui.enabled = menuMain:Switch("Enable Dodger", true, "\u{f00c}")
ui.bypass_protection = menuMain:Switch("Use even when invisible", false, "\u{f05e}")
ui.deathward_dodge = menuMain:Switch("Dodge Death Ward", true, "panorama/images/spellicons/witch_doctor_death_ward_png.vtex_c")
ui.blink_dodge = menuMain:Switch("Anti-Blink Dodge", true, "panorama/images/items/blink_png.vtex_c")
ui.blink_dodge:ToolTip("Dodge when enemy blinks nearby")
ui.start_dodge = menuMain:Switch("Anti-Start Dodge", true, "\u{f135}")
ui.start_dodge:ToolTip("Use escape skills on enemy initiation")

-- Enemy Skills to Dodge Section
menuMain:Label("Enemy Skills to Escape")
ui.enemy_skills_dodge = menuMain:MultiSelect("", {
    { "modifier_mirana_leap", "panorama/images/spellicons/mirana_leap_png.vtex_c", true },
    { "modifier_slark_pounce", "panorama/images/spellicons/slark_pounce_png.vtex_c", true },
    { "modifier_phantom_assassin_phantom_strike", "panorama/images/spellicons/phantom_assassin_phantom_strike_png.vtex_c", true },
    { "modifier_riki_blink_strike", "panorama/images/spellicons/riki_blink_strike_png.vtex_c", true },
    { "modifier_magnataur_skewer_movement", "panorama/images/spellicons/magnataur_skewer_png.vtex_c", true },
    { "modifier_tusk_snowball_movement", "panorama/images/spellicons/tusk_snowball_png.vtex_c", true },
    { "modifier_huskar_life_break_charge", "panorama/images/spellicons/huskar_life_break_png.vtex_c", true },
    { "modifier_sandking_burrowstrike", "panorama/images/spellicons/sandking_burrowstrike_png.vtex_c", true },
    { "modifier_earth_spirit_rolling_boulder_caster", "panorama/images/spellicons/earth_spirit_rolling_boulder_png.vtex_c", true },
    { "modifier_antimage_blink", "panorama/images/spellicons/antimage_blink_png.vtex_c", true },
    { "modifier_queenofpain_blink", "panorama/images/spellicons/queenofpain_blink_png.vtex_c", true },
    { "modifier_item_blink_cooldown", "panorama/images/items/blink_png.vtex_c", true },
    { "modifier_marci_rebound", "panorama/images/spellicons/marci_companion_run_png.vtex_c", true },
    { "modifier_faceless_void_time_walk", "panorama/images/spellicons/faceless_void_time_walk_png.vtex_c", true },
    { "modifier_zuus_heavenly_jump", "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c", true },
    { "modifier_snapfire_gobble_up", "panorama/images/spellicons/snapfire_gobble_up_png.vtex_c", true },
    { "modifier_ember_spirit_fire_remnant", "panorama/images/spellicons/ember_spirit_fire_remnant_png.vtex_c", true },
}, true)


-- Items Section - Defensive items with icons
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

-- Abilities Section - Defensive abilities with icons
ui.defensive_abilities = menuAbilities:MultiSelect("Defensive Abilities", {
    { "nyx_assassin_vendetta", "panorama/images/spellicons/nyx_assassin_vendetta_png.vtex_c", true },
    { "puck_phase_shift", "panorama/images/spellicons/puck_phase_shift_png.vtex_c", true },
    { "ember_spirit_sleight_of_fist", "panorama/images/spellicons/ember_spirit_sleight_of_fist_png.vtex_c", true },
    { "dazzle_shallow_grave", "panorama/images/spellicons/dazzle_shallow_grave_png.vtex_c", true },
    { "mirana_leap", "panorama/images/spellicons/mirana_leap_png.vtex_c", true },
    { "slark_pounce", "panorama/images/spellicons/slark_pounce_png.vtex_c", true },
    { "slark_shadow_dance", "panorama/images/spellicons/slark_shadow_dance_png.vtex_c", true },
    { "weaver_shukuchi", "panorama/images/spellicons/weaver_shukuchi_png.vtex_c", true },
    { "invoker_ghost_walk", "panorama/images/spellicons/invoker_ghost_walk_png.vtex_c", true },
    { "phoenix_icarus_dive", "panorama/images/spellicons/phoenix_icarus_dive_png.vtex_c", true },
    { "antimage_blink", "panorama/images/spellicons/antimage_blink_png.vtex_c", true },
    { "queenofpain_blink", "panorama/images/spellicons/queenofpain_blink_png.vtex_c", true },
    { "morphling_waveform", "panorama/images/spellicons/morphling_waveform_png.vtex_c", true },
    { "faceless_void_time_walk", "panorama/images/spellicons/faceless_void_time_walk_png.vtex_c", true },
    { "storm_spirit_ball_lightning", "panorama/images/spellicons/storm_spirit_ball_lightning_png.vtex_c", true },
    { "earth_spirit_rolling_boulder", "panorama/images/spellicons/earth_spirit_rolling_boulder_png.vtex_c", true },
    { "shredder_timber_chain", "panorama/images/spellicons/shredder_timber_chain_png.vtex_c", true },
    { "juggernaut_blade_fury", "panorama/images/spellicons/juggernaut_blade_fury_png.vtex_c", true },
    { "lifestealer_rage", "panorama/images/spellicons/life_stealer_rage_png.vtex_c", true },
    { "omniknight_martyr", "panorama/images/spellicons/omniknight_martyr_png.vtex_c", true },
    { "templar_assassin_refraction", "panorama/images/spellicons/templar_assassin_refraction_png.vtex_c", true },
    { "riki_tricks_of_the_trade", "panorama/images/spellicons/riki_tricks_of_the_trade_png.vtex_c", true },
    { "clinkz_skeleton_walk", "panorama/images/spellicons/clinkz_wind_walk_png.vtex_c", true },
    { "bounty_hunter_wind_walk", "panorama/images/spellicons/bounty_hunter_wind_walk_png.vtex_c", true },
    { "sandking_sand_storm", "panorama/images/spellicons/sandking_sand_storm_png.vtex_c", true },
    { "naga_siren_mirror_image", "panorama/images/spellicons/naga_siren_mirror_image_png.vtex_c", true },
    { "phantom_lancer_doppelwalk", "panorama/images/spellicons/phantom_lancer_doppelwalk_png.vtex_c", true },
    { "furion_sprout", "panorama/images/spellicons/furion_sprout_png.vtex_c", true },
    { "void_spirit_dissimilate", "panorama/images/spellicons/void_spirit_dissimilate_png.vtex_c", true },
    { "void_spirit_astral_step", "panorama/images/spellicons/void_spirit_astral_step_png.vtex_c", true },
    { "pangolier_swashbuckle", "panorama/images/spellicons/pangolier_swashbuckle_png.vtex_c", true },

    { "monkey_king_tree_dance", "panorama/images/spellicons/monkey_king_tree_dance_png.vtex_c", true },
    { "tusk_ice_shards", "panorama/images/spellicons/tusk_ice_shards_png.vtex_c", true },
    { "marci_rebound", "panorama/images/spellicons/marci_companion_run_png.vtex_c", true },


    { "magnataur_skewer", "panorama/images/spellicons/magnataur_skewer_png.vtex_c", true },
    { "rattletrap_hookshot", "panorama/images/spellicons/rattletrap_hookshot_png.vtex_c", true },
    { "zuus_heavenly_jump", "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c", true },
    { "enchantress_bunny_hop", "panorama/images/spellicons/enchantress_bunny_hop_png.vtex_c", true },
    { "sniper_concussive_grenade", "panorama/images/spellicons/sniper_concussive_grenade_png.vtex_c", true },
    { "snapfire_gobble_up", "panorama/images/spellicons/snapfire_gobble_up_png.vtex_c", true },
    { "ember_spirit_fire_remnant", "panorama/images/spellicons/ember_spirit_fire_remnant_png.vtex_c", true },
    { "crystal_maiden_crystal_clone", "panorama/images/spellicons/crystal_maiden_crystal_clone_png.vtex_c", true },
    { "hoodwink_scurry", "panorama/images/spellicons/hoodwink_scurry_png.vtex_c", true }
}, true)

menuAbilities:Label("Escape Settings")
ui.escape_detection_range = menuAbilities:Slider("Detection Range", 400, 1500, 1000, 50, "\u{f192}")
ui.escape_detection_range:ToolTip("Range to count enemies/allies and check disadvantage")
ui.escape_activation_range = menuAbilities:Slider("Activation Range", 200, 800, 500, 50, "\u{f05b}")
ui.escape_activation_range:ToolTip("When an enemy enters this range, trigger escape if disadvantaged")
ui.escape_ally_disadvantage = menuAbilities:Slider("Ally Disadvantage", 0, 5, 1, 1, "\u{f0c0}")
ui.escape_ally_disadvantage:ToolTip("Minimum difference (enemies - allies) to use escape")

-- Allies Section - Support settings
ui.allies_support = menuAllies:Switch("Use Items/Spells on Allies", false, "\u{f0c0}")
ui.allies_items = menuAllies:MultiSelect("Items for Allies", {
    { "item_wind_waker", "panorama/images/items/wind_waker_png.vtex_c", true },
    { "item_glimmer_cape", "panorama/images/items/glimmer_cape_png.vtex_c", true },
    { "item_lotus_orb", "panorama/images/items/lotus_orb_png.vtex_c", true },
    { "item_ethereal_blade", "panorama/images/items/ethereal_blade_png.vtex_c", true },
    { "item_shadow_amulet", "panorama/images/items/shadow_amulet_png.vtex_c", true }
}, true)
-- Offensive toggle: use Eul's on enemy to save allies
ui.use_euls_offensive = menuAllies:Switch("Use Eul's on Enemy", true, "\u{f140}")
ui.use_euls_offensive:ToolTip("Cyclone the enemy applying CC near your ally (Duel, Call, Black Hole, Chrono, Grip, etc)")
ui.allies_items_hp = menuAllies:Slider("HP% for Items on Allies", 0, 100, 40, 5, "\u{f004}")
ui.allies_items_range = menuAllies:Slider("Enemy Range (Items)", 200, 1200, 600, 50, "\u{f192}")
ui.allies_items_count = menuAllies:Slider("Minimum Enemies (Items)", 1, 5, 1, 1, "\u{f0c0}")

-- Title above icon, like other boxes
menuAllies:Label("Abilities for Allies")
ui.allies_abilities = menuAllies:MultiSelect("", {
    { "phoenix_supernova", "panorama/images/spellicons/phoenix_supernova_png.vtex_c", true },
    { "centaur_mount", "panorama/images/spellicons/centaur_mount_png.vtex_c", true },
    { "marci_rebound", "panorama/images/spellicons/marci_companion_run_png.vtex_c", true }
}, true)
ui.allies_abilities_hp = menuAllies:Slider("HP% for Abilities on Allies", 0, 100, 30, 5, "\u{f004}")
ui.allies_abilities_range = menuAllies:Slider("Enemy Range (Abilities)", 200, 1200, 700, 50, "\u{f192}")
ui.allies_abilities_count = menuAllies:Slider("Minimum Enemies (Abilities)", 1, 5, 1, 1, "\u{f0c0}")

menuAllies:Label("Enemy Skills to Save Allies")
ui.enemy_skills_save_allies = menuAllies:MultiSelect("", {
    { "modifier_legion_commander_duel", "panorama/images/spellicons/legion_commander_duel_png.vtex_c", true },
    { "modifier_axe_berserkers_call", "panorama/images/spellicons/axe_berserkers_call_png.vtex_c", true },
    { "modifier_enigma_black_hole_pull", "panorama/images/spellicons/enigma_black_hole_png.vtex_c", true },
    { "modifier_faceless_void_chronosphere_freeze", "panorama/images/spellicons/faceless_void_chronosphere_png.vtex_c", true },
    { "modifier_bane_fiends_grip", "panorama/images/spellicons/bane_fiends_grip_png.vtex_c", true },
    { "modifier_pudge_dismember", "panorama/images/spellicons/pudge_dismember_png.vtex_c", true },
    { "modifier_necrolyte_reapers_scythe", "panorama/images/spellicons/necrolyte_reapers_scythe_png.vtex_c", true },
    { "modifier_windrunner_shackle_shot", "panorama/images/spellicons/windrunner_shackleshot_png.vtex_c", true },
    { "modifier_treant_overgrowth", "panorama/images/spellicons/treant_overgrowth_png.vtex_c", true },
    { "modifier_doom_bringer_doom", "panorama/images/spellicons/doom_bringer_doom_png.vtex_c", true },
    { "modifier_juggernaut_omnislash", "panorama/images/spellicons/juggernaut_omni_slash_png.vtex_c", true },
    { "modifier_winter_wyvern_winters_curse", "panorama/images/spellicons/winter_wyvern_winters_curse_png.vtex_c", true }
}, true)
ui.enemy_skills_save_allies_hp = menuAllies:Slider("HP% for Enemy Skills", 0, 100, 50, 5, "\u{f004}")
ui.enemy_skills_save_allies_range = menuAllies:Slider("Enemy Range (Skills)", 200, 1200, 800, 50, "\u{f192}")
ui.enemy_skills_save_allies_count = menuAllies:Slider("Minimum Enemies (Skills)", 1, 5, 1, 1, "\u{f0c0}")

-- Tabela para rastrear posições anteriores dos inimigos
local enemyPositions = {}
local blinkCooldowns = {}
local lastEscapeTime = 0
local invokerInvokeTime = 0

-- Tabela para rastrear animações detectadas
local animationDetected = {}

-- Mapeamento de animações para modifiers
local animationToModifier = {
    ["leap"] = "modifier_mirana_leap",
    ["pounce"] = "modifier_slark_pounce",
    ["strike"] = "modifier_phantom_assassin_phantom_strike",
    ["blink_strike"] = "modifier_riki_blink_strike",
    ["skewer"] = "modifier_magnataur_skewer_movement",
    ["snowball"] = "modifier_tusk_snowball_movement",
    ["life_break"] = "modifier_huskar_life_break_charge",
    ["burrowstrike"] = "modifier_sandking_burrowstrike",
    ["rolling_boulder"] = "modifier_earth_spirit_rolling_boulder_caster",
    ["blink_dagger"] = "modifier_item_blink_cooldown",
    ["rebound"] = "modifier_marci_rebound",
    ["time_walk"] = "modifier_faceless_void_time_walk",
    ["heavenly_jump"] = "modifier_zuus_heavenly_jump",
    ["gobble"] = "modifier_snapfire_gobble_up",
    ["fire_remnant"] = "modifier_ember_spirit_fire_remnant"
}

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
    local heroName = NPC.GetUnitName(myHero)
    
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
    
    -- Puck - Phase Shift + Illusory Orb combo
    if heroName == "npc_dota_hero_puck" and IsAbilityEnabled("puck_phase_shift") then
        local phaseShift = IsAbilityAvailable("puck_phase_shift", myHero)
        if phaseShift then
            local illusoryOrb = NPC.GetAbility(myHero, "puck_illusory_orb")
            if illusoryOrb and Ability.IsCastable(illusoryOrb, NPC.GetMana(myHero)) then
                local enemies = Heroes.GetAll()
                local nearestEnemy = nil
                local minDist = 9999
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        local dist = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length()
                        if dist < minDist then
                            minDist = dist
                            nearestEnemy = enemy
                        end
                    end
                end
                if nearestEnemy then
                    local myPos = Entity.GetAbsOrigin(myHero)
                    local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
                    local escapeDir = (myPos - enemyPos):Normalized()
                    local orbPos = myPos + escapeDir * 1950
                    Ability.CastPosition(illusoryOrb, orbPos)
                end
            end
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
    
    -- Juggernaut - Blade Fury
    if heroName == "npc_dota_hero_juggernaut" and IsAbilityEnabled("juggernaut_blade_fury") then
        local bladeFury = IsAbilityAvailable("juggernaut_blade_fury", myHero)
        if bladeFury then
            Ability.CastNoTarget(bladeFury)
            return true
        end
    end
    
    -- Lifestealer - Rage
    if heroName == "npc_dota_hero_life_stealer" and IsAbilityEnabled("lifestealer_rage") then
        local rage = IsAbilityAvailable("life_stealer_rage", myHero)
        if rage then
            Ability.CastNoTarget(rage)
            return true
        end
    end
    
    -- Omniknight - Martyr
    if heroName == "npc_dota_hero_omniknight" and IsAbilityEnabled("omniknight_martyr") then
        local martyr = IsAbilityAvailable("omniknight_martyr", myHero)
        if martyr then
            Ability.CastTarget(martyr, myHero)
            return true
        end
    end
    
    -- Templar Assassin - Refraction
    if heroName == "npc_dota_hero_templar_assassin" and IsAbilityEnabled("templar_assassin_refraction") then
        local refraction = IsAbilityAvailable("templar_assassin_refraction", myHero)
        if refraction then
            Ability.CastNoTarget(refraction)
            return true
        end
    end
    
    -- Riki - Tricks of the Trade
    if heroName == "npc_dota_hero_riki" and IsAbilityEnabled("riki_tricks_of_the_trade") then
        local tricks = IsAbilityAvailable("riki_tricks_of_the_trade", myHero)
        if tricks then
            local enemies = Heroes.GetAll()
            local nearestEnemy = nil
            local minDist = 9999
            for _, enemy in pairs(enemies) do
                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                    local dist = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length()
                    if dist < minDist then
                        minDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            
            if nearestEnemy and minDist <= 500 then
                local myPos = Entity.GetAbsOrigin(myHero)
                local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
                local escapeDir = (myPos - enemyPos):Normalized()
                local tricksPos = myPos + escapeDir * 100
                Ability.CastPosition(tricks, tricksPos)
                return true
            end
        end
    end
    
    -- Clinkz - Skeleton Walk
    if heroName == "npc_dota_hero_clinkz" and IsAbilityEnabled("clinkz_skeleton_walk") then
        local skeletonWalk = IsAbilityAvailable("clinkz_wind_walk", myHero)
        if skeletonWalk then
            Ability.CastNoTarget(skeletonWalk)
            return true
        end
    end
    
    -- Bounty Hunter - Shadow Walk
    if heroName == "npc_dota_hero_bounty_hunter" and IsAbilityEnabled("bounty_hunter_wind_walk") then
        local shadowWalk = IsAbilityAvailable("bounty_hunter_wind_walk", myHero)
        if shadowWalk then
            Ability.CastNoTarget(shadowWalk)
            return true
        end
    end
    
    -- Sand King - Sand Storm
    if heroName == "npc_dota_hero_sand_king" and IsAbilityEnabled("sandking_sand_storm") then
        local sandStorm = IsAbilityAvailable("sandking_sand_storm", myHero)
        if sandStorm then
            Ability.CastNoTarget(sandStorm)
            return true
        end
    end
    
    -- Naga Siren - Mirror Image
    if heroName == "npc_dota_hero_naga_siren" and IsAbilityEnabled("naga_siren_mirror_image") then
        local mirrorImage = IsAbilityAvailable("naga_siren_mirror_image", myHero)
        if mirrorImage then
            Ability.CastNoTarget(mirrorImage)
            return true
        end
    end
    
    -- Phantom Lancer - Doppelganger
    if heroName == "npc_dota_hero_phantom_lancer" and IsAbilityEnabled("phantom_lancer_doppelwalk") then
        local doppel = IsAbilityAvailable("phantom_lancer_doppelwalk", myHero)
        if doppel then
            local enemies = Heroes.GetAll()
            local nearestEnemy = nil
            local minDist = 9999
            for _, enemy in pairs(enemies) do
                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                    local dist = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length()
                    if dist < minDist then
                        minDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            
            if nearestEnemy and minDist <= 600 then
                local myPos = Entity.GetAbsOrigin(myHero)
                local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
                local escapeDir = (myPos - enemyPos):Normalized()
                local doppelPos = myPos + escapeDir * 600
                Ability.CastPosition(doppel, doppelPos)
                return true
            end
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

-- Função para detectar blinks inimigos (melhorada)
local function DetectEnemyBlink(myHero)
    local enemies = Heroes.GetAll()
    local currentTime = GameRules.GetGameTime()
    local myPos = Entity.GetAbsOrigin(myHero)
    
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyID = Entity.GetIndex(enemy)
            local currentPos = Entity.GetAbsOrigin(enemy)
            local distanceToMe = (currentPos - myPos):Length()
            local unitName = NPC.GetUnitName(enemy)
            
            -- Verifica se temos posição anterior registrada
            if enemyPositions[enemyID] then
                local lastPos = enemyPositions[enemyID].pos
                local lastTime = enemyPositions[enemyID].time
                local lastDistToMe = enemyPositions[enemyID].distToMe or 9999
                
                -- Calcula distância e tempo decorrido
                local distance = (currentPos - lastPos):Length()
                local timeDiff = currentTime - lastTime
                
                -- Detecta blink: movimento rápido em curto tempo e aproximou
                if distance > 280 and timeDiff < 0.20 and timeDiff > 0 then
                    -- Se o inimigo blinkou para perto (< 900 units) e ficou mais próximo que antes
                    if distanceToMe < 900 and distanceToMe < lastDistToMe then
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 1.0 then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end

                -- Aggressive blink detection (AM/Queen/Blink Dagger)
                if distance > 500 and timeDiff < 0.25 then
                    if distanceToMe < 1200 then
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 0.8 then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end
            end
            
            -- Atualiza posição do inimigo
            enemyPositions[enemyID] = {
                pos = currentPos,
                time = currentTime,
                distToMe = distanceToMe
            }
        end
    end
    
    return false
end

-- Função para detectar blink dagger/abilities específicas (melhorada)
local function DetectBlinkAbilities(myHero)
    local enemies = Heroes.GetAll()
    local currentTime = GameRules.GetGameTime()
    local myPos = Entity.GetAbsOrigin(myHero)
    
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyID = Entity.GetIndex(enemy)
            local enemyPos = Entity.GetAbsOrigin(enemy)
            local distanceToMe = (enemyPos - myPos):Length()
            
            -- Verifica se está próximo (range maior para cobrir mais casos)
            if distanceToMe < 900 then
                -- Verifica se o inimigo acabou de aparecer perto (teleporte/blink)
                if enemyPositions[enemyID] then
                    local lastDist = enemyPositions[enemyID].distToMe or 9999
                    -- Se estava longe e agora está perto = blink
                    if lastDist > 900 and distanceToMe < 900 then
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 1.0 then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end
                
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
                           modName == "modifier_faceless_void_time_walk_phase" or
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
                            if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > 1.0 then
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

-- Função para detectar skills de initiation/start
local function DetectStartAbilities(myHero)
    local enemies = Heroes.GetAll()
    local currentTime = GameRules.GetGameTime()
    local enabledEnemySkills = ui.enemy_skills_dodge:ListEnabled()
    local function IsEnemySkillEnabled(modName)
        for _, name in ipairs(enabledEnemySkills) do
            if name == modName then return true end
        end
        return false
    end
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local distanceToMe = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(myHero)):Length()
            if distanceToMe < 1000 then
                local modifiers = NPC.GetModifiers(enemy)
                if modifiers then
                    for _, mod in pairs(modifiers) do
                        local modName = Modifier.GetName(mod)
                        if IsEnemySkillEnabled(modName) then
                            local enemyID = Entity.GetIndex(enemy)
                            local cooldown = (modName == "modifier_magnataur_skewer_movement" or modName == "modifier_slark_pounce") and 0.5 or 1.5
                            if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > cooldown then
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

-- Função para detectar inimigos através de animações recentes
local function DetectEnemyAnimations(myHero)
    if not myHero then
        return false
    end
    
    local myPos = Entity.GetAbsOrigin(myHero)
    local currentTime = GameRules.GetGameTime()
    
    for enemyID, data in pairs(animationDetected) do
        if currentTime - data.time < 0.4 then
            local enemy = Heroes.Get(enemyID)
            if enemy and Entity.IsAlive(enemy) then
                local enemyPos = Entity.GetAbsOrigin(enemy)
                local distance = (myPos - enemyPos):Length2D()
                if distance < 1400 then
                    return true
                end
            end
        end
    end
    
    return false
end

-- Função para detectar aproximação de inimigo (para escape)
local function DetectEnemyApproach(myHero)
    local enemies = Heroes.GetAll()
    local myPos = Entity.GetAbsOrigin(myHero)
    local activationRange = ui.escape_activation_range:Get()
    
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyPos = Entity.GetAbsOrigin(enemy)
            local distanceToMe = (enemyPos - myPos):Length()
            
            if distanceToMe <= activationRange then
                return true
            end
        end
    end
    return false
end

-- Função para usar skills de escape
local function UseEscapeAbilities(myHero)
    local currentTime = GameRules.GetGameTime()
    if currentTime - lastEscapeTime < 0.5 then
        return false
    end
    
    if IsAlreadyProtected(myHero) then 
        return false 
    end
    
    local myPos = Entity.GetAbsOrigin(myHero)
    local detectionRange = ui.escape_detection_range:Get()
    local disadvantageThreshold = ui.escape_ally_disadvantage:Get()
    
    local enemyCount = 0
    local allyCount = 0
    
    local enemies = Entity.GetHeroesInRadius(myHero, detectionRange, Enum.TeamType.TEAM_ENEMY, false)
    if enemies then
        for _, enemy in pairs(enemies) do
            if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
                enemyCount = enemyCount + 1
            end
        end
    end
    
    local allies = Entity.GetHeroesInRadius(myHero, detectionRange, Enum.TeamType.TEAM_FRIEND, false)
    if allies then
        for _, ally in pairs(allies) do
            if ally and Entity.IsAlive(ally) and ally ~= myHero and not NPC.IsIllusion(ally) then
                allyCount = allyCount + 1
            end
        end
    end
    
    local disadvantage = enemyCount - allyCount
    
    if disadvantage < disadvantageThreshold then
        return false
    end
    
    local heroName = NPC.GetUnitName(myHero)
    
    local enabledSkills = ui.defensive_abilities:ListEnabled()
    local function IsSkillEnabled(skillName)
        for _, name in ipairs(enabledSkills) do
            if name == skillName then return true end
        end
        return false
    end
    
    -- Mirana - Leap
    if heroName == "npc_dota_hero_mirana" and IsSkillEnabled("mirana_leap") then
        local leap = NPC.GetAbility(myHero, "mirana_leap")
        if leap and Ability.IsCastable(leap, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(leap)
            lastEscapeTime = currentTime
            return true
        end
    end
    
    -- Slark - Tenta Pounce primeiro, depois Shadow Dance
    if heroName == "npc_dota_hero_slark" then
        if IsSkillEnabled("slark_pounce") then
            local pounce = NPC.GetAbility(myHero, "slark_pounce")
            if pounce and Ability.IsCastable(pounce, NPC.GetMana(myHero)) then
                Ability.CastNoTarget(pounce)
                lastEscapeTime = currentTime
                return true
            end
        end
        if IsSkillEnabled("slark_shadow_dance") then
            local shadowDance = NPC.GetAbility(myHero, "slark_shadow_dance")
            if shadowDance and Ability.IsCastable(shadowDance, NPC.GetMana(myHero)) then
                Ability.CastNoTarget(shadowDance)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Weaver - Shukuchi
    if heroName == "npc_dota_hero_weaver" and IsSkillEnabled("weaver_shukuchi") then
        local shukuchi = NPC.GetAbility(myHero, "weaver_shukuchi")
        if shukuchi and Ability.IsCastable(shukuchi, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(shukuchi)
            lastEscapeTime = currentTime
            return true
        end
    end
    
    -- Função auxiliar para encontrar inimigo mais próximo e calcular posição de escape
    local function GetEscapePosition(range)
        local nearestEnemy = nil
        local minDist = 9999
        for _, enemy in pairs(enemies) do
            if enemy and Entity.IsAlive(enemy) then
                local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
                if dist < minDist then
                    minDist = dist
                    nearestEnemy = enemy
                end
            end
        end
        
        if nearestEnemy then
            local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
            local escapeDir = (myPos - enemyPos):Normalized()
            return myPos + escapeDir * range
        end
        return nil
    end
    
    -- Anti-Mage - Blink
    if heroName == "npc_dota_hero_antimage" and IsSkillEnabled("antimage_blink") then
        local blink = NPC.GetAbility(myHero, "antimage_blink")
        if blink and Ability.IsCastable(blink, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1200)
            if escapePos then
                Ability.CastPosition(blink, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Queen of Pain - Blink
    if heroName == "npc_dota_hero_queenofpain" and IsSkillEnabled("queenofpain_blink") then
        local blink = NPC.GetAbility(myHero, "queenofpain_blink")
        if blink and Ability.IsCastable(blink, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1300)
            if escapePos then
                Ability.CastPosition(blink, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Morphling - Waveform
    if heroName == "npc_dota_hero_morphling" and IsSkillEnabled("morphling_waveform") then
        local waveform = NPC.GetAbility(myHero, "morphling_waveform")
        if waveform and Ability.IsCastable(waveform, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1000)
            if escapePos then
                Ability.CastPosition(waveform, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Faceless Void - Time Walk
    if heroName == "npc_dota_hero_faceless_void" and IsSkillEnabled("faceless_void_time_walk") then
        local timeWalk = NPC.GetAbility(myHero, "faceless_void_time_walk")
        if timeWalk and Ability.IsCastable(timeWalk, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(700)
            if escapePos then
                Ability.CastPosition(timeWalk, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Phoenix - Icarus Dive
    if heroName == "npc_dota_hero_phoenix" and IsSkillEnabled("phoenix_icarus_dive") then
        local dive = NPC.GetAbility(myHero, "phoenix_icarus_dive")
        if dive and Ability.IsCastable(dive, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1400)
            if escapePos then
                Ability.CastPosition(dive, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Storm Spirit - Ball Lightning
    if heroName == "npc_dota_hero_storm_spirit" and IsSkillEnabled("storm_spirit_ball_lightning") then
        local ballLightning = NPC.GetAbility(myHero, "storm_spirit_ball_lightning")
        if ballLightning and Ability.IsCastable(ballLightning, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1200)
            if escapePos then
                Ability.CastPosition(ballLightning, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Earth Spirit - Rolling Boulder
    if heroName == "npc_dota_hero_earth_spirit" and IsSkillEnabled("earth_spirit_rolling_boulder") then
        local rollingBoulder = NPC.GetAbility(myHero, "earth_spirit_rolling_boulder")
        if rollingBoulder and Ability.IsCastable(rollingBoulder, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(800)
            if escapePos then
                Ability.CastPosition(rollingBoulder, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Timbersaw - Timber Chain
    if heroName == "npc_dota_hero_shredder" and IsSkillEnabled("shredder_timber_chain") then
        local timberChain = NPC.GetAbility(myHero, "shredder_timber_chain")
        if timberChain and Ability.IsCastable(timberChain, NPC.GetMana(myHero)) then
            local chainRange = Ability.GetCastRange(timberChain)
            local trees = Trees.InRadius(myPos, chainRange)
            if trees and #trees > 0 then
                local escapePos = GetEscapePosition(chainRange)
                if escapePos then
                    local bestTree = nil
                    local bestDist = 9999
                    for _, tree in ipairs(trees) do
                        local treePos = Entity.GetAbsOrigin(tree)
                        local distToEscape = (treePos - escapePos):Length2D()
                        local distToMe = (treePos - myPos):Length2D()
                        if distToMe >= 200 and distToMe <= chainRange and distToEscape < bestDist then
                            bestTree = treePos
                            bestDist = distToEscape
                        end
                    end
                    if bestTree then
                        Ability.CastPosition(timberChain, bestTree)
                        lastEscapeTime = currentTime
                        return true
                    end
                end
            end
        end
    end
    
    -- Invoker - Ghost Walk
    if heroName == "npc_dota_hero_invoker" and IsSkillEnabled("invoker_ghost_walk") then
        local quas = NPC.GetAbility(myHero, "invoker_quas")
        local wex = NPC.GetAbility(myHero, "invoker_wex")
        local invoke = NPC.GetAbility(myHero, "invoker_invoke")
        
        -- Verifica slots invocados (D e F)
        local slot1 = NPC.GetAbilityByIndex(myHero, 3) -- Slot D
        local slot2 = NPC.GetAbilityByIndex(myHero, 4) -- Slot F
        
        -- Verifica se Ghost Walk já está invocado
        if slot1 and Ability.GetName(slot1) == "invoker_ghost_walk" and Ability.IsCastable(slot1, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(slot1)
            lastEscapeTime = currentTime
            return true
        elseif slot2 and Ability.GetName(slot2) == "invoker_ghost_walk" and Ability.IsCastable(slot2, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(slot2)
            lastEscapeTime = currentTime
            return true
        elseif quas and wex and invoke and Ability.IsCastable(invoke, NPC.GetMana(myHero)) then
            -- Invoca Ghost Walk: QQW
            Ability.CastNoTarget(quas)
            Ability.CastNoTarget(quas)
            Ability.CastNoTarget(wex)
            Ability.CastNoTarget(invoke)
            return false
        end
    end
    
    -- Nature's Prophet - Sprout + Teleportation
    if heroName == "npc_dota_hero_furion" and IsSkillEnabled("furion_sprout") then
        local sprout = NPC.GetAbility(myHero, "furion_sprout")
        local teleport = NPC.GetAbility(myHero, "furion_teleportation")
        if sprout and Ability.IsCastable(sprout, NPC.GetMana(myHero)) then
            Ability.CastTarget(sprout, myHero)
            if teleport and Ability.IsCastable(teleport, NPC.GetMana(myHero)) then
                local fountain = Entity.GetAbsOrigin(Heroes.GetLocal())
                local teamID = Entity.GetTeamNum(myHero)
                local fountainPos = teamID == 2 and Vector(-7174, -6671, 512) or Vector(7023, 6450, 512)
                Ability.CastPosition(teleport, fountainPos)
            end
            lastEscapeTime = currentTime
            return true
        end
    end
    
    -- Pangolier - Swashbuckle
    if heroName == "npc_dota_hero_pangolier" and IsSkillEnabled("pangolier_swashbuckle") then
        local swashbuckle = NPC.GetAbility(myHero, "pangolier_swashbuckle")
        if swashbuckle and Ability.IsCastable(swashbuckle, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(600)
            if escapePos then
                Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_POSITION, nil, escapePos, swashbuckle, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Void Spirit - Tenta Dissimilate primeiro, depois Astral Step
    if heroName == "npc_dota_hero_void_spirit" then
        if IsSkillEnabled("void_spirit_dissimilate") then
            local dissimilate = NPC.GetAbility(myHero, "void_spirit_dissimilate")
            if dissimilate and Ability.IsCastable(dissimilate, NPC.GetMana(myHero)) then
                Ability.CastNoTarget(dissimilate)
                lastEscapeTime = currentTime
                return true
            end
        end
        if IsSkillEnabled("void_spirit_astral_step") then
            local astralStep = NPC.GetAbility(myHero, "void_spirit_astral_step")
            if astralStep and Ability.IsCastable(astralStep, NPC.GetMana(myHero)) then
                local escapePos = GetEscapePosition(1200)
                if escapePos then
                    Ability.CastPosition(astralStep, escapePos)
                    lastEscapeTime = currentTime
                    return true
                end
            end
        end
    end
    
    
    -- Monkey King - Tree Dance
    if heroName == "npc_dota_hero_monkey_king" and IsSkillEnabled("monkey_king_tree_dance") then
        local treeDance = NPC.GetAbility(myHero, "monkey_king_tree_dance")
        if treeDance and Ability.IsCastable(treeDance, NPC.GetMana(myHero)) then
            local castRange = Ability.GetCastRange(treeDance)
            local allTrees = {}
            for _, tree in ipairs(Entity.GetTreesInRadius(myHero, castRange, true)) do
                table.insert(allTrees, tree)
            end
            for _, tree in ipairs(Entity.GetTempTreesInRadius(myHero, castRange)) do
                table.insert(allTrees, tree)
            end
            if #allTrees > 0 then
                local escapePos = GetEscapePosition(castRange)
                if escapePos then
                    local bestTree = nil
                    local bestDist = 9999
                    for _, tree in ipairs(allTrees) do
                        local treePos = Entity.GetAbsOrigin(tree)
                        local distToEscape = (treePos - escapePos):Length2D()
                        if distToEscape < bestDist then
                            bestTree = tree
                            bestDist = distToEscape
                        end
                    end
                    if bestTree then
                        Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET_TREE, bestTree, nil, treeDance, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, myHero)
                        lastEscapeTime = currentTime
                        return true
                    end
                end
            end
        end
    end
    
    
    -- Marci - Companion Run (Escape - Solo Mode)
    if heroName == "npc_dota_hero_marci" and IsSkillEnabled("marci_rebound") then
        local companionRun = NPC.GetAbility(myHero, "marci_companion_run")
        local rebound = NPC.GetAbility(myHero, "marci_rebound")
        
        -- Se rebound está escondida, precisa trocar
        if companionRun and rebound and Ability.IsHidden(rebound) then
            Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_TRAIN_ABILITY, nil, Vector(0, 0, 0), companionRun, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, myHero)
            return false
        end
        
        -- Verifica qual variante está disponível
        local useRebound = rebound and not Ability.IsHidden(rebound) and Ability.IsCastable(rebound, NPC.GetMana(myHero))
        local useCompanion = companionRun and not Ability.IsHidden(companionRun) and Ability.IsCastable(companionRun, NPC.GetMana(myHero))
        
        if useRebound or useCompanion then
            local nearestAlly = nil
            local minDist = 9999
            if allies then
                for _, ally in pairs(allies) do
                    if ally and Entity.IsAlive(ally) and ally ~= myHero then
                        local dist = (Entity.GetAbsOrigin(ally) - myPos):Length()
                        if dist < minDist and dist <= 1000 then
                            minDist = dist
                            nearestAlly = ally
                        end
                    end
                end
            end
            if nearestAlly then
                local nearestEnemy = nil
                local minDist = 9999
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) then
                        local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
                        if dist < minDist then
                            minDist = dist
                            nearestEnemy = enemy
                        end
                    end
                end
                
                if useRebound then
                    Ability.CastTarget(rebound, nearestAlly)
                else
                    Ability.CastTarget(companionRun, nearestAlly)
                end
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Tusk - Ice Shards
    if heroName == "npc_dota_hero_tusk" and IsSkillEnabled("tusk_ice_shards") then
        local iceShards = NPC.GetAbility(myHero, "tusk_ice_shards")
        if iceShards and Ability.IsCastable(iceShards, NPC.GetMana(myHero)) then
            local nearestEnemy = nil
            local minDist = 9999
            for _, enemy in pairs(enemies) do
                if enemy and Entity.IsAlive(enemy) then
                    local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
                    if dist < minDist then
                        minDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            if nearestEnemy then
                Ability.CastPosition(iceShards, Entity.GetAbsOrigin(nearestEnemy))
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    
    -- Magnus - Skewer
    if heroName == "npc_dota_hero_magnataur" and IsSkillEnabled("magnataur_skewer") then
        local skewer = NPC.GetAbility(myHero, "magnataur_skewer")
        if skewer and Ability.IsCastable(skewer, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(900)
            if escapePos then
                Ability.CastPosition(skewer, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Clockwerk - Hookshot or Power Cogs
    if heroName == "npc_dota_hero_rattletrap" and IsSkillEnabled("rattletrap_hookshot") then
        local nearestEnemy = nil
        local minDist = 9999
        for _, enemy in pairs(enemies) do
            if enemy and Entity.IsAlive(enemy) then
                local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
                if dist < minDist then
                    minDist = dist
                    nearestEnemy = enemy
                end
            end
        end
        
        if nearestEnemy and minDist <= 400 then
            local cogs = NPC.GetAbility(myHero, "rattletrap_power_cogs")
            if cogs and Ability.IsCastable(cogs, NPC.GetMana(myHero)) then
                Ability.CastNoTarget(cogs)
                lastEscapeTime = currentTime
                return true
            end
        else
            local hookshot = NPC.GetAbility(myHero, "rattletrap_hookshot")
            if hookshot and Ability.IsCastable(hookshot, NPC.GetMana(myHero)) then
                local nearestAlly = nil
                local minAllyDist = 9999
                if allies then
                    for _, ally in pairs(allies) do
                        if ally and Entity.IsAlive(ally) and ally ~= myHero then
                            local dist = (Entity.GetAbsOrigin(ally) - myPos):Length()
                            if dist < minAllyDist and dist <= 3000 then
                                minAllyDist = dist
                                nearestAlly = ally
                            end
                        end
                    end
                end
                if nearestAlly then
                    Ability.CastPosition(hookshot, Entity.GetAbsOrigin(nearestAlly))
                    lastEscapeTime = currentTime
                    return true
                end
            end
        end
    end
    
    -- Zeus - Heavenly Jump
    if heroName == "npc_dota_hero_zuus" and IsSkillEnabled("zuus_heavenly_jump") then
        local jump = NPC.GetAbility(myHero, "zuus_heavenly_jump")
        if jump and Ability.IsCastable(jump, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(600)
            if escapePos then
                Ability.CastPosition(jump, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Enchantress - Bunny Hop
    if heroName == "npc_dota_hero_enchantress" and IsSkillEnabled("enchantress_bunny_hop") then
        local bunnyHop = NPC.GetAbility(myHero, "enchantress_bunny_hop")
        if bunnyHop and Ability.IsCastable(bunnyHop, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(bunnyHop)
            lastEscapeTime = currentTime
            return true
        end
    end
    
    -- Sniper - Concussive Grenade
    if heroName == "npc_dota_hero_sniper" and IsSkillEnabled("sniper_concussive_grenade") then
        local grenade = NPC.GetAbility(myHero, "sniper_concussive_grenade")
        if grenade and Ability.IsCastable(grenade, NPC.GetMana(myHero)) then
            local nearestEnemy = nil
            local minDist = 9999
            for _, enemy in pairs(enemies) do
                if enemy and Entity.IsAlive(enemy) then
                    local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
                    if dist < minDist then
                        minDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            if nearestEnemy then
                Ability.CastPosition(grenade, Entity.GetAbsOrigin(nearestEnemy))
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Snapfire - Gobble Up
    if heroName == "npc_dota_hero_snapfire" and IsSkillEnabled("snapfire_gobble_up") then
        local gobble = NPC.GetAbility(myHero, "snapfire_gobble_up")
        if gobble and Ability.IsCastable(gobble, NPC.GetMana(myHero)) then
            local nearestAlly = nil
            local minDist = 9999
            if allies then
                for _, ally in pairs(allies) do
                    if ally and Entity.IsAlive(ally) and ally ~= myHero then
                        local dist = (Entity.GetAbsOrigin(ally) - myPos):Length()
                        if dist < minDist and dist <= 300 then
                            minDist = dist
                            nearestAlly = ally
                        end
                    end
                end
            end
            if nearestAlly then
                Ability.CastTarget(gobble, nearestAlly)
                lastEscapeTime = currentTime
                return true
            else
                Ability.CastTarget(gobble, myHero)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Ember Spirit - Fire Remnant
    if heroName == "npc_dota_hero_ember_spirit" and IsSkillEnabled("ember_spirit_fire_remnant") then
        local remnant = NPC.GetAbility(myHero, "ember_spirit_fire_remnant")
        local activate = NPC.GetAbility(myHero, "ember_spirit_activate_fire_remnant")
        if remnant and Ability.IsCastable(remnant, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1500)
            if escapePos then
                Ability.CastPosition(remnant, escapePos)
                if activate and Ability.IsCastable(activate, NPC.GetMana(myHero)) then
                    Ability.CastPosition(activate, escapePos)
                end
                lastEscapeTime = currentTime
                return true
            end
        elseif activate and Ability.IsCastable(activate, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(1500)
            if escapePos then
                Ability.CastPosition(activate, escapePos)
                lastEscapeTime = currentTime
                return true
            end
        end
    end
    
    -- Crystal Maiden - Crystal Clone
    if heroName == "npc_dota_hero_crystal_maiden" and IsSkillEnabled("crystal_maiden_crystal_clone") then
        local clone = NPC.GetAbility(myHero, "crystal_maiden_crystal_clone")
        if clone and Ability.IsCastable(clone, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(clone)
            lastEscapeTime = currentTime
            return true
        end
    end
    
    -- Hoodwink - Scurry
    if heroName == "npc_dota_hero_hoodwink" and IsSkillEnabled("hoodwink_scurry") then
        local scurry = NPC.GetAbility(myHero, "hoodwink_scurry")
        if scurry and Ability.IsCastable(scurry, NPC.GetMana(myHero)) then
            Ability.CastNoTarget(scurry)
            lastEscapeTime = currentTime
            return true
        end
    end
    
    return false
end

-- Função para contar inimigos em range do aliado
local function CountEnemiesNearAlly(ally, range)
    local count = 0
    local enemies = Entity.GetHeroesInRadius(ally, range, Enum.TeamType.TEAM_ENEMY, false)
    if enemies then
        for _, enemy in pairs(enemies) do
            if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
                count = count + 1
            end
        end
    end
    return count
end

-- Nova função para usar Eul's/Wind Waker no inimigo que está aplicando CC no aliado
local function UseEulsOnEnemy(myHero, ally)
    -- ESTRITO: Eul's sempre no inimigo; Wind Waker nunca ofensivo
    local item = NPC.GetItem(myHero, "item_cyclone", true)
    if not item or not Ability.IsCastable(item, NPC.GetMana(myHero)) then
        return false
    end
    
    local castRange = Ability.GetCastRange(item) + NPC.GetCastRangeBonus(myHero)
    local myPos = Entity.GetAbsOrigin(myHero)
    local allyPos = Entity.GetAbsOrigin(ally)
    
    -- MÉTODO 1: Detecta Berserker's Call ou Duel no ALIADO, procura o inimigo perto dele
    local allyModifiers = NPC.GetModifiers(ally)
    if allyModifiers then
        for _, mod in pairs(allyModifiers) do
            local modName = Modifier.GetName(mod)
            
            -- Se aliado tem Berserker's Call, procura Axe próximo
            if modName == "modifier_axe_berserkers_call" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        if NPC.GetUnitName(enemy) == "npc_dota_hero_axe" then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            -- Axe deve estar perto do aliado (range do Call = 300)
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 500 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Duel, procura Legion próxima
            if modName == "modifier_legion_commander_duel" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        if NPC.GetUnitName(enemy) == "npc_dota_hero_legion_commander" then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            -- Legion deve estar perto do aliado (range do Duel = 150)
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 300 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                local legionAghsImmune = NPC.HasModifier(enemy, "modifier_legion_commander_duel") and NPC.HasScepter and NPC.HasScepter(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken and not legionAghsImmune then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Chronosphere, procura Void próximo
            if string.find(modName, "chronosphere") then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        if NPC.GetUnitName(enemy) == "npc_dota_hero_faceless_void" then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            -- Void deve estar perto do aliado (range do Chrono = 600 radius)
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 700 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Fiend's Grip, procura Bane próximo
            if modName == "modifier_bane_fiends_grip" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        if NPC.GetUnitName(enemy) == "npc_dota_hero_bane" then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            -- Bane deve estar perto do aliado (range do Grip = 625)
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 700 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Dismember, procura Pudge próximo (busca por QUALQUER Pudge perto)
            if modName == "modifier_pudge_dismember" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        local enemyName = NPC.GetUnitName(enemy)
                        -- Tenta diferentes nomes possíveis do Pudge
                        if enemyName == "npc_dota_hero_pudge" or string.find(enemyName, "pudge") then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 400 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Shackleshot, procura Windrunner próxima
            if modName == "modifier_windrunner_shackle_shot" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        local enemyName = NPC.GetUnitName(enemy)
                        if enemyName == "npc_dota_hero_windrunner" or string.find(enemyName, "wind") then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 800 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Omnislash do Juggernaut: Não usa Eul's (ele pula muito e é difícil acertar)
            -- Wind Waker será usado no aliado pela lógica de CC crítico
            
            -- Se aliado tem Winter's Curse, procura Winter Wyvern próxima
            if string.find(modName, "winters_curse") then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        if NPC.GetUnitName(enemy) == "npc_dota_hero_winter_wyvern" then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 800 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
            
            -- Se aliado tem Reaper's Scythe, procura Necrophos próximo
            if modName == "modifier_necrolyte_reapers_scythe" then
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        local enemyName = NPC.GetUnitName(enemy)
                        if enemyName == "npc_dota_hero_necrolyte" or string.find(enemyName, "necro") then
                            local enemyPos = Entity.GetAbsOrigin(enemy)
                            local distanceToEnemy = (enemyPos - myPos):Length()
                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                            
                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 700 then
                                local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)
                                
                                if not isCycloned and not isMagicImmune and not hasLinken then
                                    Ability.CastTarget(item, enemy)
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- MÉTODO 2: Verifica outras skills pelo modifier no inimigo (método antigo)
    local enabledEnemySkills = ui.enemy_skills_save_allies:ListEnabled()
    local enemies = Heroes.GetAll()
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local enemyPos = Entity.GetAbsOrigin(enemy)
            local distanceToEnemy = (enemyPos - myPos):Length()
            
            if distanceToEnemy <= castRange then
                local modifiers = NPC.GetModifiers(enemy)
                if modifiers then
                    for _, mod in pairs(modifiers) do
                        local modName = Modifier.GetName(mod)
                        
                        for _, enabledSkill in ipairs(enabledEnemySkills) do
                            if modName == enabledSkill then
                                local distanceEnemyToAlly = (enemyPos - allyPos):Length()
                                
                                if distanceEnemyToAlly <= 900 then
                                    local isCycloned = NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone")
                                    local isMagicImmune = NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) or NPC.HasModifier(enemy, "modifier_black_king_bar")
                                    local hasLinken = NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy)

                                    if not isCycloned and not isMagicImmune and not hasLinken then
                                        Ability.CastTarget(item, enemy)
                                        return true
                                    end
                                end
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
    
    -- Primeiro tenta usar Eul's no inimigo que está aplicando CC (se habilitado)
    if ui.use_euls_offensive:Get() then
        UseEulsOnEnemy(myHero, targetHero)
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
    -- Observação: Eul's (Cyclone) NÃO pode alvejar aliados; Wind Waker pode
    local defensiveItems = {
        {name = "item_wind_waker", castType = "target", priority = 1},
        {name = "item_glimmer_cape", castType = "target", priority = 2},
        {name = "item_lotus_orb", castType = "target", priority = 3},
        {name = "item_ethereal_blade", castType = "target", priority = 4}
    }
    
    -- Tenta usar itens em ordem de prioridade
    for _, itemData in ipairs(defensiveItems) do
        if IsItemEnabled(itemData.name) then
            local item = IsItemAvailable(itemData.name, myHero)
            if item then
                if itemData.castType == "target" then
                    -- Garante que o item pode alvejar aliados
                    if Ability.CanCastOnTarget and Ability.CanCastOnTarget(item, targetHero) then
                        Ability.CastTarget(item, targetHero)
                        return true
                    end
                    -- Se não pode castar neste alvo, tenta próximo item
                end
            end
        end
    end
    
    -- Habilidades defensivas específicas por herói que podem ser usadas em aliados
    local heroName = NPC.GetUnitName(myHero)
    
    -- Função para verificar se habilidade de aliado está na lista habilitada
    local enabledAllyAbilities = ui.allies_abilities:ListEnabled()
    local function IsAllyAbilityEnabled(abilityName)
        for _, name in ipairs(enabledAllyAbilities) do
            if name == abilityName then return true end
        end
        return false
    end
    
    -- Phoenix - Supernova com Aghanim's Scepter
    if heroName == "npc_dota_hero_phoenix" and IsAllyAbilityEnabled("phoenix_supernova") then
        -- Verifica se tem Aghanim's Scepter
        if NPC.HasScepter(myHero) then
            -- Verificar HP% do aliado para habilidades
            local allyHP = Entity.GetHealth(targetHero)
            local allyMaxHP = Entity.GetMaxHealth(targetHero)
            local allyHPPercent = (allyHP / allyMaxHP) * 100
            
            -- Verificar quantidade de inimigos próximos para habilidades
            local abilityEnemyRange = ui.allies_abilities_range:Get()
            local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)
            local abilityMinEnemies = ui.allies_abilities_count:Get()
            local abilityHPThreshold = ui.allies_abilities_hp:Get()
            
            -- Só usa ability se HP estiver abaixo do threshold E tiver inimigos suficientes
            if allyHPPercent <= abilityHPThreshold and abilityEnemyCount >= abilityMinEnemies then
                local supernova = NPC.GetAbility(myHero, "phoenix_supernova")
                if supernova and Ability.IsReady(supernova) then
                    local mana = NPC.GetMana(myHero) or 0
                    local cost = Ability.GetManaCost and Ability.GetManaCost(supernova) or 0
                    if mana >= cost then
                        -- Verifica range usando o cast range da habilidade quando disponível
                        local castRange = (Ability.GetCastRange and Ability.GetCastRange(supernova)) or 500
                        local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(targetHero)):Length()
                        if distance <= castRange + 25 then
                            -- Com Aghanim's, a Supernova pode ser castada diretamente no aliado
                            Ability.CastTarget(supernova, targetHero)
                            return true
                        end
                    end
                end
            end
        end
    end

    -- Centaur - Hitch a Ride (Aghanim's Scepter)
    if heroName == "npc_dota_hero_centaur" and IsAllyAbilityEnabled("centaur_mount") then
        -- Verificar HP% do aliado para habilidades
        local allyHP = Entity.GetHealth(targetHero)
        local allyMaxHP = Entity.GetMaxHealth(targetHero)
        local allyHPPercent = (allyHP / allyMaxHP) * 100
        
        -- Verificar quantidade de inimigos próximos para habilidades
        local abilityEnemyRange = ui.allies_abilities_range:Get()
        local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)
        local abilityMinEnemies = ui.allies_abilities_count:Get()
        local abilityHPThreshold = ui.allies_abilities_hp:Get()
        
        -- Só usa ability se HP estiver abaixo do threshold E tiver inimigos suficientes
        if allyHPPercent <= abilityHPThreshold and abilityEnemyCount >= abilityMinEnemies then
            local workHorse = NPC.GetAbility(myHero, "centaur_work_horse")
            local mount = NPC.GetAbility(myHero, "centaur_mount")
            local myMana = NPC.GetMana(myHero)
            
            -- 1. Tenta usar Hitch a Ride (Puxar) se já estiver disponível
            if mount and Ability.IsCastable(mount, myMana) and not Ability.IsHidden(mount) then
                local castRange = (Ability.GetCastRange and Ability.GetCastRange(mount)) or 300
                local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(targetHero)):Length()
                if distance <= castRange + 50 then
                    Ability.CastTarget(mount, targetHero)
                    return true
                end
            end
            
            -- 2. Se não der pra puxar, tenta ativar Work Horse (Carroça)
            if workHorse and Ability.IsCastable(workHorse, myMana) then
                 -- Verifica se estamos perto o suficiente para valer a pena ativar (Range do mount é curto)
                 local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(targetHero)):Length()
                 if distance <= 450 then 
                     Ability.CastNoTarget(workHorse)
                     return true
                 end
            end
        end
    end
    
    -- Marci - Companion Run / Rebound (Save Allies)
    if heroName == "npc_dota_hero_marci" and (IsAllyAbilityEnabled("marci_companion_run") or IsAllyAbilityEnabled("marci_rebound")) then
        local allyHP = Entity.GetHealth(targetHero)
        local allyMaxHP = Entity.GetMaxHealth(targetHero)
        local allyHPPercent = (allyHP / allyMaxHP) * 100
        
        local abilityEnemyRange = ui.allies_abilities_range:Get()
        local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)
        local abilityMinEnemies = ui.allies_abilities_count:Get()
        local abilityHPThreshold = ui.allies_abilities_hp:Get()
        
        if allyHPPercent <= abilityHPThreshold and abilityEnemyCount >= abilityMinEnemies then
            local companionRun = NPC.GetAbility(myHero, "marci_companion_run")
            local rebound = NPC.GetAbility(myHero, "marci_rebound")
            local myMana = NPC.GetMana(myHero)
            local distance = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(targetHero)):Length()
            
            -- Tenta usar companion_run primeiro
            if companionRun and Ability.IsCastable(companionRun, myMana) and distance <= 1050 then
                Ability.CastTarget(companionRun, targetHero)
                return true
            end
            
            -- Se não tiver companion_run, tenta rebound
            if rebound and not Ability.IsHidden(rebound) and Ability.IsCastable(rebound, myMana) and distance <= 1050 then
                Ability.CastTarget(rebound, targetHero)
                return true
            end
        end
    end
    
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
    -- Verifica CC críticos no aliado (Duel, Call, Black Hole, Chrono, etc)
    local modifiers = NPC.GetModifiers(ally)
    if modifiers then
        for _, mod in pairs(modifiers) do
            local modName = Modifier.GetName(mod)
            -- Verifica modifiers de CC crítico
            if string.find(modName, "duel") or
               string.find(modName, "berserkers_call") or
               string.find(modName, "black_hole") or
               string.find(modName, "chronosphere") or
               string.find(modName, "fiends_grip") or
               string.find(modName, "dismember") or
               string.find(modName, "winters_curse") or
               string.find(modName, "flaming_lasso") then
                return true
            end
        end
    end
    
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

local lastAllyCheckTime = 0

-- Main dodger logic
function Dodger.OnUpdate()
    local myHero = Heroes.GetLocal()
    if not myHero or not Entity.IsAlive(myHero) or not ui.enabled:Get() then
        return
    end
    
    -- Verifica se a opção Anti-Blink está ativada e detecta blinks
    if ui.blink_dodge:Get() and (DetectEnemyBlink(myHero) or DetectBlinkAbilities(myHero)) then
        if not UseEscapeAbilities(myHero) then
            UseDefensiveItems(myHero)
        end
    end
    
    -- Verifica se a opção Anti-Start está ativada e detecta skills de initiation
    if ui.start_dodge:Get() then
        -- Primeiro verifica animações (mais rápido), depois modifiers
        local animDetected = DetectEnemyAnimations(myHero)
        local modDetected = DetectStartAbilities(myHero)
        
        if animDetected or modDetected then
            if not UseEscapeAbilities(myHero) then
                UseDefensiveItems(myHero)
            end
        end
    end
    
    -- Verifica se a opção Death Ward está ativada e detecta Death Ward
    if ui.deathward_dodge:Get() and IsTargetedByDeathWard(myHero) then
        UseDefensiveItems(myHero)
    end
    
    -- Lógica para suporte a aliados
    if ui.allies_support:Get() then
        local currentTime = GameRules.GetGameTime()
        if currentTime < lastAllyCheckTime + 0.1 then
            return
        end
        lastAllyCheckTime = currentTime
        
        local alliesInRadius = Entity.GetHeroesInRadius(myHero, 2000, Enum.TeamType.TEAM_FRIEND, false)
        
        for _, ally in pairs(alliesInRadius) do
            if ally and Entity.IsAlive(ally) and ally ~= myHero then
                -- PRIORIDADE 1: CCs críticos - USA ITENS IMEDIATAMENTE (Shadow Amulet no final)
                local modifiers = NPC.GetModifiers(ally)
                local hasUrgentCC = false
                local ccModifier = nil
                local ccName = ""
                
                -- CASO ESPECIAL: Juggernaut Omnislash - verifica se tem Jugg inimigo próximo com Omnislash ativo
                local enemies = Heroes.GetAll()
                for _, enemy in pairs(enemies) do
                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                        local enemyName = NPC.GetUnitName(enemy)
                        if enemyName == "npc_dota_hero_juggernaut" or string.find(enemyName, "jugg") then
                            local enemyModifiers = NPC.GetModifiers(enemy)
                            if enemyModifiers then
                                for _, eMod in pairs(enemyModifiers) do
                                    if string.find(Modifier.GetName(eMod), "omnislash") then
                                        local distanceEnemyToAlly = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(ally)):Length()
                                        if distanceEnemyToAlly <= 500 then
                                            hasUrgentCC = true
                                            ccModifier = eMod
                                            ccName = "omnislash"
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if hasUrgentCC then break end
                end
                
                -- Verifica modifiers no aliado para outros CCs
                if not hasUrgentCC and modifiers then
                    for _, mod in pairs(modifiers) do
                        local modName = Modifier.GetName(mod)
                        -- Lista de CCs críticos que ativam proteção
                        if modName == "modifier_legion_commander_duel" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "duel"
                            break
                        elseif modName == "modifier_axe_berserkers_call" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "call"
                            break
                        elseif string.find(modName, "black_hole") then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "black_hole"
                            break
                        elseif string.find(modName, "chronosphere") then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "chrono"
                            break
                        elseif modName == "modifier_bane_fiends_grip" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "grip"
                            break
                        elseif modName == "modifier_pudge_dismember" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "dismember"
                            break
                        elseif string.find(modName, "winters_curse") then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "curse"
                            break
                        elseif modName == "modifier_batrider_flaming_lasso" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "lasso"
                            break
                        elseif modName == "modifier_treant_overgrowth" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "overgrowth"
                            break
                        elseif modName == "modifier_necrolyte_reapers_scythe" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "scythe"
                            break
                        elseif modName == "modifier_windrunner_shackle_shot" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "shackle"
                            break
                        elseif modName == "modifier_doom_bringer_doom" then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "doom"
                            break
                        elseif string.find(modName, "omnislash") then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "omnislash"
                            break
                        elseif string.find(modName, "winters_curse") then
                            hasUrgentCC = true
                            ccModifier = mod
                            ccName = "winters_curse"
                            break
                        end
                    end
                end
                
                if hasUrgentCC then
                    -- Tenta Eul's no inimigo primeiro (se habilitado)
                    if ui.use_euls_offensive:Get() then
                        UseEulsOnEnemy(myHero, ally)
                    end
                    -- Tenta usar itens defensivos no aliado em ordem de prioridade
                    if not IsAlreadyProtected(ally) then
                        local enabledAllyItems = ui.allies_items:ListEnabled()
                        
                        -- Função helper para verificar se item está habilitado
                        local function IsItemEnabledInMenu(itemName)
                            for _, name in ipairs(enabledAllyItems) do
                                if name == itemName then return true end
                            end
                            return false
                        end
                        
                        -- Tenta Wind Waker primeiro
                        if IsItemEnabledInMenu("item_wind_waker") then
                            local windWaker = NPC.GetItem(myHero, "item_wind_waker", true)
                            if windWaker and Ability.IsCastable(windWaker, NPC.GetMana(myHero)) then
                                Ability.CastTarget(windWaker, ally)
                            end
                        end
                        
                        -- Se não tem Wind Waker ou falhou, tenta Glimmer
                        if IsItemEnabledInMenu("item_glimmer_cape") then
                            local glimmer = NPC.GetItem(myHero, "item_glimmer_cape", true)
                            if glimmer and Ability.IsCastable(glimmer, NPC.GetMana(myHero)) then
                                Ability.CastTarget(glimmer, ally)
                            end
                        end
                        
                        -- Tenta Lotus (BLOQUEADO contra Juggernaut - não reflete Omnislash)
                        if IsItemEnabledInMenu("item_lotus_orb") and ccName ~= "omnislash" then
                            local lotus = NPC.GetItem(myHero, "item_lotus_orb", true)
                            if lotus and Ability.IsCastable(lotus, NPC.GetMana(myHero)) then
                                Ability.CastTarget(lotus, ally)
                            end
                        end
                        
                        -- Tenta Ethereal (BLOQUEADO contra heróis que ficam imunes durante ults)
                        -- Bane (Grip), Pudge (Dismember), Necro (Scythe), Doom, Treant (Overgrowth)
                        if IsItemEnabledInMenu("item_ethereal_blade") and 
                           ccName ~= "grip" and ccName ~= "dismember" and 
                           ccName ~= "scythe" and ccName ~= "doom" and ccName ~= "overgrowth" then
                            local ethereal = NPC.GetItem(myHero, "item_ethereal_blade", true)
                            if ethereal and Ability.IsCastable(ethereal, NPC.GetMana(myHero)) then
                                Ability.CastTarget(ethereal, ally)
                            end
                        end
                        
                        -- Shadow Amulet - Regras especiais por tipo de CC
                        if IsItemEnabledInMenu("item_shadow_amulet") and ccModifier then
                            local remainingTime = Modifier.GetDieTime(ccModifier) - GameRules.GetGameTime()
                            
                            -- Shadow Amulet precisa de 1.5s para ativar, mas damos 2.0s de margem
                            -- para garantir que o timing funcione bem
                            if remainingTime <= 2.0 and remainingTime > 0.5 then
                                local shadowAmulet = NPC.GetItem(myHero, "item_shadow_amulet", true)
                                if shadowAmulet and Ability.IsCastable(shadowAmulet, NPC.GetMana(myHero)) then
                                    Ability.CastTarget(shadowAmulet, ally)
                                end
                            end
                        end
                    end
                else
                    -- PRIORIDADE 2: Outras situações de perigo (Death Ward, HP baixo, etc)
                    local allyInDanger = false
                    
                    -- Verifica Death Ward no aliado
                    if ui.deathward_dodge:Get() and IsTargetedByDeathWard(ally) then
                        allyInDanger = true
                    end
                    
                    -- Verifica outras ameaças
                    if IsAllyInDanger(ally) then
                        allyInDanger = true
                    end
                    
                    -- Verifica HP% do aliado - considera em perigo se HP estiver baixo
                    local allyHP = Entity.GetHealth(ally)
                    local allyMaxHP = Entity.GetMaxHealth(ally)
                    local allyHPPercent = (allyHP / allyMaxHP) * 100
                    
                    -- Considera em perigo se HP estiver abaixo do threshold de abilities OU items
                    if allyHPPercent <= ui.allies_abilities_hp:Get() or allyHPPercent <= ui.allies_items_hp:Get() then
                        -- Verifica se tem inimigos próximos
                        local enemyCount = CountEnemiesNearAlly(ally, math.max(ui.allies_abilities_range:Get(), ui.allies_items_range:Get()))
                        if enemyCount >= 1 then
                            allyInDanger = true
                        end
                    end
                    
                    -- Se o aliado está em perigo, tenta usar itens/habilidades defensivas
                    if allyInDanger then
                        UseDefensiveItemsOnAllies(myHero, ally)
                    end
                end
            end
        end
    end
end

-- Callback para detecção de animações
function Dodger.OnUnitAnimation(animation)
    if not animation or not animation.unit or animation.unit == 0 then
        return
    end
    
    if not NPCs.Contains(animation.unit) then
        return
    end
    
    local myHero = Heroes.GetLocal()
    if not myHero or not Entity.IsAlive(myHero) or not ui.enabled:Get() then
        return
    end
    
    if Entity.IsSameTeam(animation.unit, myHero) then
        return
    end
    
    if not Entity.IsHero(animation.unit) or NPC.IsIllusion(animation.unit) then
        return
    end
    
    local animName = animation.sequenceName
    if not animName then
        return
    end
    
    -- Detecta animações específicas
    local detectedModifier = nil
    for animKey, modName in pairs(animationToModifier) do
        if string.find(string.lower(animName), animKey) then
            detectedModifier = modName
            break
        end
    end

    -- Tratamento adicional: blinks específicos por herói
    if not detectedModifier then
        local animLower = string.lower(animName)
        local unitName = NPC.GetUnitName(animation.unit)
        -- Se a sequência contém 'blink', decide pelo herói
        if animLower and string.find(animLower, "blink") then
            if unitName == "npc_dota_hero_antimage" then
                detectedModifier = "modifier_antimage_blink"
            elseif unitName == "npc_dota_hero_queenofpain" then
                detectedModifier = "modifier_queenofpain_blink"
            end
        end
        -- Garantia extra para Time Walk caso a sequência contenha texto genérico
        if not detectedModifier and animLower and string.find(animLower, "time_walk") then
            detectedModifier = "modifier_faceless_void_time_walk"
        end
    end
    
    if detectedModifier then
        local enabledEnemySkills = ui.enemy_skills_dodge:ListEnabled()
        local isEnabled = false
        for _, name in ipairs(enabledEnemySkills) do
            if name == detectedModifier then
                isEnabled = true
                break
            end
        end
        
        if isEnabled then
            local enemyID = Entity.GetIndex(animation.unit)
            local currentTime = GameRules.GetGameTime()
            animationDetected[enemyID] = {time = currentTime, modifier = detectedModifier}
        end
    end
end

return Dodger