--------------------------------------------------------------------------------
-- THREAT DETECTOR — Enemy team analysis, threat profiling, item scoring
-- Merges HERO_TAGS, HERO_ROLES, COUNTER_RULES from the original scripts.
--------------------------------------------------------------------------------
local M = {}

--------------------------------------------------------------------------------
-- HERO TAGS  (source: item_helper.lua — complete table)
-- Each hero maps to a set of tags describing its capabilities.
--------------------------------------------------------------------------------
M.HERO_TAGS = {
    -- Carry / Physical DPS
    npc_dota_hero_antimage           = {"carry","magic_resist","mobility","mana_burn"},
    npc_dota_hero_phantom_assassin   = {"carry","phys_burst","crit","evasion"},
    npc_dota_hero_juggernaut         = {"carry","phys_dps","magic_immune","heal"},
    npc_dota_hero_faceless_void      = {"carry","chrono","phys_dps","evasion","mobility"},
    npc_dota_hero_terrorblade        = {"carry","phys_dps","illusions","push"},
    npc_dota_hero_spectre            = {"carry","global","phys_dps","tanky"},
    npc_dota_hero_phantom_lancer     = {"carry","illusions","phys_dps","mana_burn"},
    npc_dota_hero_medusa             = {"carry","phys_dps","tanky","split_shot"},
    npc_dota_hero_troll_warlord      = {"carry","phys_dps","bash","attack_speed"},
    npc_dota_hero_ursa               = {"carry","phys_burst","tanky"},
    npc_dota_hero_sven               = {"carry","phys_burst","stun","cleave"},
    npc_dota_hero_life_stealer       = {"carry","phys_dps","magic_immune","heal","slow"},
    npc_dota_hero_slark              = {"carry","phys_dps","purge","invis","mobility"},
    npc_dota_hero_monkey_king        = {"carry","phys_burst","stun","mobility"},
    npc_dota_hero_chaos_knight       = {"carry","phys_burst","illusions","stun"},
    npc_dota_hero_luna               = {"carry","phys_dps","push","magic_burst"},
    npc_dota_hero_drow_ranger        = {"carry","phys_dps","slow","ranged"},
    npc_dota_hero_morphling          = {"carry","phys_burst","magic_burst","mobility"},
    npc_dota_hero_naga_siren         = {"carry","illusions","push","disable"},
    npc_dota_hero_weaver             = {"carry","phys_dps","invis","mobility"},
    npc_dota_hero_riki               = {"carry","phys_dps","invis","silence"},
    npc_dota_hero_clinkz             = {"carry","phys_dps","invis","push"},
    npc_dota_hero_sniper             = {"carry","phys_dps","ranged","siege"},
    npc_dota_hero_templar_assassin   = {"carry","phys_burst","armor_reduce","invis"},
    npc_dota_hero_bloodseeker        = {"carry","phys_dps","heal","silence","rupture"},
    npc_dota_hero_lycan              = {"carry","phys_dps","push","summons"},
    npc_dota_hero_huskar             = {"carry","magic_resist","phys_dps","heal"},
    npc_dota_hero_alchemist          = {"carry","phys_dps","stun","tanky","farm"},
    npc_dota_hero_skeleton_king      = {"carry","phys_dps","stun","reincarnation"},
    npc_dota_hero_arc_warden         = {"carry","phys_dps","push","summons","ranged"},
    npc_dota_hero_lone_druid         = {"carry","phys_dps","push","summons"},
    npc_dota_hero_ember_spirit       = {"carry","magic_burst","mobility","cleave"},
    npc_dota_hero_gyrocopter         = {"carry","magic_burst","phys_dps","ranged"},
    npc_dota_hero_nevermore          = {"carry","phys_dps","magic_burst","armor_reduce"},
    npc_dota_hero_razor              = {"carry","phys_dps","tanky","armor_reduce","drain"},
    npc_dota_hero_viper              = {"carry","slow","magic_burst","break","tanky"},
    npc_dota_hero_kez                = {"carry","phys_burst","mobility","invis"},
    -- Magic Burst / Nukers
    npc_dota_hero_invoker            = {"magic_burst","disable","global","versatile"},
    npc_dota_hero_storm_spirit       = {"magic_burst","mobility","disable"},
    npc_dota_hero_lina               = {"magic_burst","stun","phys_dps"},
    npc_dota_hero_zuus               = {"magic_burst","global","vision"},
    npc_dota_hero_tinker             = {"magic_burst","push","rearm"},
    npc_dota_hero_queenofpain        = {"magic_burst","mobility","silence"},
    npc_dota_hero_puck               = {"magic_burst","mobility","disable","silence"},
    npc_dota_hero_void_spirit        = {"magic_burst","mobility","disable"},
    npc_dota_hero_leshrac            = {"magic_burst","push","stun"},
    npc_dota_hero_death_prophet      = {"magic_burst","push","heal","silence"},
    npc_dota_hero_necrolyte          = {"magic_burst","heal","tanky","anti_heal"},
    npc_dota_hero_skywrath_mage      = {"magic_burst","silence","slow"},
    npc_dota_hero_pugna              = {"magic_burst","push","ward"},
    npc_dota_hero_dark_willow        = {"magic_burst","disable","fear"},
    npc_dota_hero_hoodwink           = {"magic_burst","disable","invis"},
    npc_dota_hero_muerta             = {"magic_burst","phys_dps","silence","invis"},
    npc_dota_hero_obsidian_destroyer = {"magic_burst","mana_burn","disable","int"},
    npc_dota_hero_phoenix            = {"magic_burst","heal","disable","slow"},
    npc_dota_hero_shredder           = {"magic_burst","tanky","pure_dmg"},
    npc_dota_hero_venomancer         = {"magic_burst","slow","push","summons"},
    -- Disable / Control
    npc_dota_hero_lion               = {"disable","stun","hex","magic_burst","mana_burn"},
    npc_dota_hero_shadow_shaman      = {"disable","push","hex","stun"},
    npc_dota_hero_bane               = {"disable","pure_dmg","nightmare"},
    npc_dota_hero_enigma             = {"disable","black_hole","push","summons"},
    npc_dota_hero_tidehunter         = {"disable","tanky","armor_reduce"},
    npc_dota_hero_magnataur          = {"disable","empower","mobility"},
    npc_dota_hero_earthshaker        = {"disable","stun","magic_burst"},
    npc_dota_hero_sand_king          = {"disable","stun","magic_burst"},
    npc_dota_hero_elder_titan        = {"disable","armor_reduce","magic_resist_reduce"},
    npc_dota_hero_primal_beast       = {"disable","tanky","phys_dps","magic_burst"},
    npc_dota_hero_spirit_breaker     = {"disable","bash","global","mobility"},
    npc_dota_hero_axe                = {"disable","tanky","call"},
    npc_dota_hero_legion_commander   = {"disable","phys_dps","duel"},
    npc_dota_hero_doom_bringer       = {"disable","doom","tanky"},
    npc_dota_hero_batrider           = {"disable","mobility","magic_burst"},
    npc_dota_hero_mars               = {"disable","tanky","phys_burst"},
    npc_dota_hero_centaur            = {"disable","tanky","stun","global"},
    npc_dota_hero_slardar            = {"disable","armor_reduce","bash","phys_dps"},
    npc_dota_hero_brewmaster         = {"disable","tanky","evasion","summons"},
    npc_dota_hero_rattletrap         = {"disable","tanky","vision"},
    npc_dota_hero_nyx_assassin       = {"disable","invis","mana_burn","magic_burst"},
    npc_dota_hero_tusk               = {"disable","phys_burst","mobility","save"},
    npc_dota_hero_ringmaster         = {"disable","magic_burst","fear"},
    npc_dota_hero_beastmaster        = {"disable","push","summons","vision"},
    -- Support / Utility
    npc_dota_hero_crystal_maiden     = {"magic_burst","disable","slow","mana"},
    npc_dota_hero_dazzle             = {"heal","save","armor"},
    npc_dota_hero_oracle             = {"heal","save","purge","magic_burst"},
    npc_dota_hero_omniknight         = {"heal","save","magic_immune","tanky"},
    npc_dota_hero_abaddon            = {"heal","save","purge","tanky"},
    npc_dota_hero_chen               = {"heal","push","summons","global"},
    npc_dota_hero_enchantress        = {"heal","slow","summons","pure_dmg"},
    npc_dota_hero_wisp               = {"heal","save","global","tether"},
    npc_dota_hero_witch_doctor       = {"heal","stun","magic_burst"},
    npc_dota_hero_warlock            = {"heal","disable","summons","magic_burst"},
    npc_dota_hero_jakiro             = {"magic_burst","push","slow","disable"},
    npc_dota_hero_disruptor          = {"disable","silence","magic_burst"},
    npc_dota_hero_winter_wyvern      = {"disable","save","magic_burst","slow"},
    npc_dota_hero_shadow_demon       = {"disable","purge","save","illusions"},
    npc_dota_hero_grimstroke         = {"disable","magic_burst","silence"},
    npc_dota_hero_snapfire           = {"disable","magic_burst","stun"},
    npc_dota_hero_marci              = {"disable","phys_burst","mobility","save"},
    npc_dota_hero_bounty_hunter      = {"invis","track","phys_burst","slow"},
    npc_dota_hero_keeper_of_the_light = {"magic_burst","heal","mana","push"},
    npc_dota_hero_dawnbreaker        = {"heal","stun","global","phys_dps"},
    -- Tanky / Initiators
    npc_dota_hero_bristleback        = {"tanky","phys_dps","slow"},
    npc_dota_hero_dragon_knight      = {"tanky","stun","push"},
    npc_dota_hero_abyssal_underlord  = {"tanky","magic_burst","global","aura"},
    npc_dota_hero_night_stalker      = {"tanky","silence","phys_dps","vision"},
    npc_dota_hero_undying            = {"tanky","heal","slow","summons"},
    npc_dota_hero_ogre_magi          = {"tanky","stun","buff","magic_burst"},
    npc_dota_hero_treant             = {"tanky","heal","invis","global"},
    npc_dota_hero_pudge              = {"tanky","pure_dmg","disable"},
    -- Misc / Multi-role
    npc_dota_hero_meepo              = {"carry","disable","magic_burst","summons"},
    npc_dota_hero_broodmother        = {"carry","push","summons","invis"},
    npc_dota_hero_visage             = {"magic_burst","summons","phys_dps"},
    npc_dota_hero_techies            = {"magic_burst","disable","mines"},
    npc_dota_hero_furion             = {"push","global","summons","phys_dps"},
    npc_dota_hero_vengefulspirit     = {"stun","save","armor_reduce","phys_dps"},
    npc_dota_hero_rubick             = {"disable","magic_burst","steal"},
    npc_dota_hero_silencer           = {"silence","magic_burst","global","mana_burn"},
    npc_dota_hero_ancient_apparition = {"magic_burst","global","anti_heal"},
    npc_dota_hero_lich               = {"magic_burst","slow","save"},
    npc_dota_hero_windrunner         = {"phys_dps","disable","evasion","magic_burst"},
    npc_dota_hero_mirana             = {"magic_burst","stun","invis","mobility"},
    npc_dota_hero_pangolier          = {"disable","phys_dps","mobility","evasion"},
    npc_dota_hero_dark_seer          = {"tanky","illusions","mobility","aura"},
    npc_dota_hero_earth_spirit       = {"disable","silence","magic_burst","mobility"},
    npc_dota_hero_kunkka             = {"phys_burst","disable","cleave"},
    npc_dota_hero_tiny               = {"phys_burst","stun","push","tanky"},
    npc_dota_hero_largo              = {"disable","magic_burst","tanky"},
}

--------------------------------------------------------------------------------
-- HERO ROLES  (determines score penalties for role-inappropriate items)
--------------------------------------------------------------------------------
M.HERO_ROLES = {
    npc_dota_hero_antimage           = {role="carry",  style="phys"},
    npc_dota_hero_phantom_assassin   = {role="carry",  style="phys"},
    npc_dota_hero_juggernaut         = {role="carry",  style="phys"},
    npc_dota_hero_faceless_void      = {role="carry",  style="phys"},
    npc_dota_hero_terrorblade        = {role="carry",  style="phys"},
    npc_dota_hero_spectre            = {role="carry",  style="phys"},
    npc_dota_hero_phantom_lancer     = {role="carry",  style="phys"},
    npc_dota_hero_medusa             = {role="carry",  style="phys"},
    npc_dota_hero_troll_warlord      = {role="carry",  style="phys"},
    npc_dota_hero_ursa               = {role="carry",  style="phys"},
    npc_dota_hero_sven               = {role="carry",  style="phys"},
    npc_dota_hero_life_stealer       = {role="carry",  style="phys"},
    npc_dota_hero_slark              = {role="carry",  style="phys"},
    npc_dota_hero_monkey_king        = {role="carry",  style="phys"},
    npc_dota_hero_chaos_knight       = {role="carry",  style="phys"},
    npc_dota_hero_luna               = {role="carry",  style="phys"},
    npc_dota_hero_drow_ranger        = {role="carry",  style="phys"},
    npc_dota_hero_morphling          = {role="carry",  style="hybrid"},
    npc_dota_hero_naga_siren         = {role="carry",  style="phys"},
    npc_dota_hero_weaver             = {role="carry",  style="phys"},
    npc_dota_hero_riki               = {role="carry",  style="phys"},
    npc_dota_hero_clinkz             = {role="carry",  style="phys"},
    npc_dota_hero_sniper             = {role="carry",  style="phys"},
    npc_dota_hero_templar_assassin   = {role="carry",  style="phys"},
    npc_dota_hero_bloodseeker        = {role="carry",  style="phys"},
    npc_dota_hero_lycan              = {role="carry",  style="phys"},
    npc_dota_hero_huskar             = {role="carry",  style="phys"},
    npc_dota_hero_alchemist          = {role="carry",  style="phys"},
    npc_dota_hero_skeleton_king      = {role="carry",  style="phys"},
    npc_dota_hero_arc_warden         = {role="carry",  style="phys"},
    npc_dota_hero_lone_druid         = {role="carry",  style="phys"},
    npc_dota_hero_gyrocopter         = {role="carry",  style="hybrid"},
    npc_dota_hero_nevermore          = {role="carry",  style="hybrid"},
    npc_dota_hero_razor              = {role="carry",  style="hybrid"},
    npc_dota_hero_viper              = {role="carry",  style="hybrid"},
    npc_dota_hero_meepo              = {role="carry",  style="hybrid"},
    npc_dota_hero_broodmother        = {role="carry",  style="phys"},
    npc_dota_hero_kez                = {role="carry",  style="phys"},
    -- Mid
    npc_dota_hero_invoker            = {role="mid",    style="magic"},
    npc_dota_hero_storm_spirit       = {role="mid",    style="magic"},
    npc_dota_hero_ember_spirit       = {role="mid",    style="magic"},
    npc_dota_hero_lina               = {role="mid",    style="magic"},
    npc_dota_hero_zuus               = {role="mid",    style="magic"},
    npc_dota_hero_tinker             = {role="mid",    style="magic"},
    npc_dota_hero_queenofpain        = {role="mid",    style="magic"},
    npc_dota_hero_puck               = {role="mid",    style="magic"},
    npc_dota_hero_void_spirit        = {role="mid",    style="magic"},
    npc_dota_hero_leshrac            = {role="mid",    style="magic"},
    npc_dota_hero_death_prophet      = {role="mid",    style="magic"},
    npc_dota_hero_obsidian_destroyer = {role="mid",    style="magic"},
    npc_dota_hero_muerta             = {role="mid",    style="hybrid"},
    npc_dota_hero_windrunner         = {role="mid",    style="hybrid"},
    -- Offlane
    npc_dota_hero_axe                = {role="offlane",style="utility"},
    npc_dota_hero_tidehunter         = {role="offlane",style="utility"},
    npc_dota_hero_bristleback        = {role="offlane",style="phys"},
    npc_dota_hero_centaur            = {role="offlane",style="utility"},
    npc_dota_hero_mars               = {role="offlane",style="utility"},
    npc_dota_hero_legion_commander   = {role="offlane",style="phys"},
    npc_dota_hero_doom_bringer       = {role="offlane",style="utility"},
    npc_dota_hero_sand_king          = {role="offlane",style="magic"},
    npc_dota_hero_slardar            = {role="offlane",style="utility"},
    npc_dota_hero_magnataur          = {role="offlane",style="utility"},
    npc_dota_hero_night_stalker      = {role="offlane",style="phys"},
    npc_dota_hero_primal_beast       = {role="offlane",style="utility"},
    npc_dota_hero_dragon_knight      = {role="offlane",style="hybrid"},
    npc_dota_hero_abyssal_underlord  = {role="offlane",style="utility"},
    npc_dota_hero_batrider           = {role="offlane",style="magic"},
    npc_dota_hero_spirit_breaker     = {role="offlane",style="utility"},
    npc_dota_hero_dark_seer          = {role="offlane",style="utility"},
    npc_dota_hero_necrolyte          = {role="offlane",style="magic"},
    npc_dota_hero_pudge              = {role="offlane",style="utility"},
    npc_dota_hero_shredder           = {role="offlane",style="magic"},
    npc_dota_hero_phoenix            = {role="offlane",style="magic"},
    npc_dota_hero_kunkka             = {role="offlane",style="hybrid"},
    npc_dota_hero_tiny               = {role="offlane",style="hybrid"},
    -- Support (Pos 4)
    npc_dota_hero_earthshaker        = {role="support",style="utility"},
    npc_dota_hero_tusk               = {role="support",style="utility"},
    npc_dota_hero_bounty_hunter      = {role="support",style="utility"},
    npc_dota_hero_nyx_assassin       = {role="support",style="utility"},
    npc_dota_hero_rubick             = {role="support",style="magic"},
    npc_dota_hero_mirana             = {role="support",style="magic"},
    npc_dota_hero_dark_willow        = {role="support",style="magic"},
    npc_dota_hero_hoodwink           = {role="support",style="magic"},
    npc_dota_hero_grimstroke         = {role="support",style="magic"},
    npc_dota_hero_snapfire           = {role="support",style="utility"},
    npc_dota_hero_marci              = {role="support",style="utility"},
    npc_dota_hero_pugna              = {role="support",style="magic"},
    npc_dota_hero_disruptor          = {role="support",style="magic"},
    npc_dota_hero_jakiro             = {role="support",style="magic"},
    npc_dota_hero_silencer           = {role="support",style="magic"},
    -- Hard Support (Pos 5)
    npc_dota_hero_crystal_maiden     = {role="hardsupport",style="magic"},
    npc_dota_hero_dazzle             = {role="hardsupport",style="utility"},
    npc_dota_hero_oracle             = {role="hardsupport",style="utility"},
    npc_dota_hero_omniknight         = {role="hardsupport",style="utility"},
    npc_dota_hero_abaddon            = {role="hardsupport",style="utility"},
    npc_dota_hero_chen               = {role="hardsupport",style="utility"},
    npc_dota_hero_enchantress        = {role="hardsupport",style="utility"},
    npc_dota_hero_wisp               = {role="hardsupport",style="utility"},
    npc_dota_hero_witch_doctor       = {role="hardsupport",style="magic"},
    npc_dota_hero_warlock            = {role="hardsupport",style="magic"},
    npc_dota_hero_winter_wyvern      = {role="hardsupport",style="magic"},
    npc_dota_hero_lich               = {role="hardsupport",style="magic"},
    npc_dota_hero_lion               = {role="hardsupport",style="magic"},
    npc_dota_hero_shadow_shaman      = {role="hardsupport",style="magic"},
    npc_dota_hero_bane               = {role="hardsupport",style="utility"},
    npc_dota_hero_enigma             = {role="hardsupport",style="utility"},
    npc_dota_hero_keeper_of_the_light = {role="hardsupport",style="magic"},
    npc_dota_hero_ogre_magi          = {role="hardsupport",style="utility"},
    npc_dota_hero_treant             = {role="hardsupport",style="utility"},
    npc_dota_hero_dawnbreaker        = {role="hardsupport",style="utility"},
    npc_dota_hero_ancient_apparition = {role="hardsupport",style="magic"},
}

--------------------------------------------------------------------------------
-- ITEM ROLE PENALTIES (items that are BAD for certain roles/styles)
--------------------------------------------------------------------------------
local ROLE_PENALTY = {
    -- Support items bad for phys carries
    item_pavise          = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_mekansm         = {bad_roles={"carry","mid"}},
    item_guardian_greaves = {bad_roles={"carry","mid"}},
    item_holy_locket     = {bad_roles={"carry","mid"}},
    item_glimmer_cape    = {bad_roles={"carry"}},
    item_force_staff     = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_pipe            = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_spirit_vessel   = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_cyclone         = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_arcane_boots    = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_refresher       = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_dagon           = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_bloodstone      = {bad_roles={"carry"}, bad_styles={"phys"}},
    item_octarine_core   = {bad_roles={"carry"}, bad_styles={"phys"}},
    -- Expensive DPS items bad for supports
    item_daedalus        = {bad_roles={"hardsupport","support"}},
    item_butterfly       = {bad_roles={"hardsupport","support"}},
    item_satanic         = {bad_roles={"hardsupport","support"}},
    item_battlefury      = {bad_roles={"hardsupport","support"}, bad_styles={"magic"}},
    item_desolator       = {bad_roles={"hardsupport","support"}},
    item_abyssal_blade   = {bad_roles={"hardsupport","support"}},
    item_nullifier       = {bad_roles={"hardsupport","support"}},
    item_radiance        = {bad_roles={"hardsupport","support"}},
    item_monkey_king_bar = {bad_roles={"hardsupport","support"}},
    item_heart           = {bad_roles={"hardsupport","support"}},
    item_hand_of_midas   = {bad_roles={"hardsupport","support"}},
}

--------------------------------------------------------------------------------
-- COUNTER RULES — when enemy has these tags, suggest items with these tags
--------------------------------------------------------------------------------
M.COUNTER_RULES = {
    {tags={"phys_dps","carry"},   weight=3, suggest={"vs_phys","armor","block"}},
    {tags={"phys_burst"},         weight=4, suggest={"vs_phys","vs_burst","save","armor"}},
    {tags={"attack_speed"},       weight=2, suggest={"vs_phys","armor","slow"}},
    {tags={"magic_burst"},        weight=4, suggest={"vs_magic","magic_resist","barrier"}},
    {tags={"disable","stun"},     weight=3, suggest={"vs_disable","magic_immune","dispel"}},
    {tags={"silence"},            weight=2, suggest={"dispel","vs_disable","magic_immune"}},
    {tags={"hex"},                weight=3, suggest={"vs_disable","magic_immune","save"}},
    {tags={"heal"},               weight=3, suggest={"anti_heal"}},
    {tags={"invis"},              weight=3, suggest={"vs_invis","detection"}},
    {tags={"evasion"},            weight=3, suggest={"vs_evasion"}},
    {tags={"illusions"},          weight=3, suggest={"vs_illusions","cleave"}},
    {tags={"summons"},            weight=2, suggest={"vs_illusions","cleave"}},
    {tags={"mobility"},           weight=2, suggest={"root","slow","disable"}},
    {tags={"tanky"},              weight=1, suggest={"armor_reduce","phys_dps"}},
    {tags={"doom"},               weight=4, suggest={"save","vs_disable"}},
    {tags={"black_hole"},         weight=4, suggest={"save","vs_disable"}},
    {tags={"chrono"},             weight=3, suggest={"save","vs_burst"}},
    {tags={"save"},               weight=2, suggest={"vs_save","dispel"}},
    {tags={"mana_burn"},          weight=2, suggest={"mana","sustain"}},
}

--------------------------------------------------------------------------------
-- THREAT THRESHOLDS — high-level threat categories
--------------------------------------------------------------------------------
local THREAT_DEFS = {
    heavy_magic    = { tags = {"magic_burst"},                           min = 2 },
    heavy_phys     = { tags = {"phys_dps","phys_burst","carry"},         min = 2 },
    invis_threat   = { tags = {"invis"},                                 min = 1 },
    heavy_disable  = { tags = {"disable","stun","hex","silence"},        min = 3 },
    heal_threat    = { tags = {"heal","save"},                           min = 2 },
    illusion_threat= { tags = {"illusions","summons"},                   min = 2 },
}

--------------------------------------------------------------------------------
-- ANALYZE: build a threat profile from a list of enemies
-- enemies: list of { name=string, items=list, ... } from match_collector
-- Returns: {
--   tagCounts    = {tag -> count},
--   sortedTags   = {{tag,count}, ...},
--   threats      = {threatName -> count},
--   warnings     = {string, ...},
-- }
--------------------------------------------------------------------------------
function M.analyze(enemies)
    local tagCounts = {}
    for _, enemy in ipairs(enemies) do
        local tags = M.HERO_TAGS[enemy.name] or {}
        for _, tag in ipairs(tags) do
            tagCounts[tag] = (tagCounts[tag] or 0) + 1
        end
    end

    -- Sorted tags (for UI display)
    local sortedTags = {}
    for tag, count in pairs(tagCounts) do
        sortedTags[#sortedTags + 1] = { tag = tag, count = count }
    end
    table.sort(sortedTags, function(a, b)
        if a.count ~= b.count then return a.count > b.count end
        return a.tag < b.tag
    end)

    -- High-level threat flags
    local threats = {}
    for name, def in pairs(THREAT_DEFS) do
        local total = 0
        for _, tag in ipairs(def.tags) do
            total = total + (tagCounts[tag] or 0)
        end
        if total >= def.min then threats[name] = total end
    end

    -- Human-readable warnings
    local warnings = {}
    if threats.heavy_magic   then warnings[#warnings+1] = "Heavy magic damage — consider Pipe / BKB"    end
    if threats.invis_threat  then warnings[#warnings+1] = "Invisible heroes — buy Dust / Sentries"      end
    if threats.heavy_phys    then warnings[#warnings+1] = "Heavy physical damage — consider AC / Halberd"end
    if threats.heavy_disable then warnings[#warnings+1] = "Heavy disables — consider BKB / Lotus Orb"   end
    if threats.heal_threat   then warnings[#warnings+1] = "Healing / saves — consider Spirit Vessel"     end
    if threats.illusion_threat then warnings[#warnings+1] = "Illusions / summons — Mjollnir / BF"        end

    return {
        tagCounts  = tagCounts,
        sortedTags = sortedTags,
        threats    = threats,
        warnings   = warnings,
    }
end

--------------------------------------------------------------------------------
-- SCORE ITEM: given an item definition (from build_engine.ITEM_DB),
-- a threat profile, the game phase, owned items, and hero role —
-- produce a numeric relevance score.  Negative means "skip".
--------------------------------------------------------------------------------
function M.scoreItem(itemDef, profile, phase, ownedItems, heroName, enemyItemAnalysis, teamAxes)
    -- Already owned → skip
    if ownedItems and ownedItems[itemDef.name] then return -1 end

    -- Phase relevance
    local phaseOk = false
    if itemDef.phase then
        for _, p in ipairs(itemDef.phase) do
            if p == phase then phaseOk = true; break end
        end
    end
    if not phaseOk then return 0 end

    local score = 0

    -- 1) Trigger-based (enemy tags that directly trigger this item)
    if itemDef.triggers then
        for _, trigger in ipairs(itemDef.triggers) do
            local cnt = profile.tagCounts[trigger] or 0
            if cnt > 0 then score = score + cnt * 3 end
        end
    end

    -- 2) Counter-rule matching (broader pattern-based)
    for _, rule in ipairs(M.COUNTER_RULES) do
        local ruleHits = 0
        for _, rTag in ipairs(rule.tags) do
            if (profile.tagCounts[rTag] or 0) > 0 then ruleHits = ruleHits + 1 end
        end
        if ruleHits >= #rule.tags and itemDef.tags then
            local itemHits = 0
            for _, sTag in ipairs(rule.suggest) do
                for _, iTag in ipairs(itemDef.tags) do
                    if sTag == iTag then itemHits = itemHits + 1 end
                end
            end
            if itemHits > 0 then score = score + itemHits * rule.weight end
        end
    end

    -- 3) Enemy item counter scoring
    if enemyItemAnalysis and enemyItemAnalysis.counterSuggestions then
        local bonus = enemyItemAnalysis.counterSuggestions[itemDef.name]
        if bonus and bonus > 0 then
            score = score + bonus * 4
        end
    end

    -- 4) 5-axis threat-based defensive item priority
    if teamAxes and itemDef.tags then
        score = score + M.computeAxisBonus(itemDef.tags, teamAxes)
    end

    -- 5) Role/style penalty
    if heroName then
        local info = M.HERO_ROLES[heroName]
        if info then
            local penalty = ROLE_PENALTY[itemDef.name]
            if penalty then
                local penalized = false
                if penalty.bad_roles and info.role then
                    for _, br in ipairs(penalty.bad_roles) do
                        if br == info.role then penalized = true; break end
                    end
                end
                if not penalized and penalty.bad_styles and info.style then
                    for _, bs in ipairs(penalty.bad_styles) do
                        if bs == info.style then penalized = true; break end
                    end
                end
                if penalized then
                    score = math.max(0, math.floor(score * 0.25))
                end
            end
        end
    end

    return score
end

--------------------------------------------------------------------------------
-- ENEMY ITEM THREAT MAP  (what enemy items mean for us)
-- weight: how dangerous this item is (1-8 scale)
-- tags: threat tags this item introduces
--------------------------------------------------------------------------------
M.ENEMY_ITEM_THREATS = {
    item_black_king_bar  = {weight=8, tags={"magic_immune"},    note="BKB active — disables won't work"},
    item_abyssal_blade   = {weight=8, tags={"vs_bkb","stun"},   note="Abyssal — BKB-piercing stun"},
    item_sheepstick      = {weight=7, tags={"hex","disable"},    note="Hex — instant hard disable"},
    item_bloodthorn      = {weight=7, tags={"silence","crit"},   note="Bloodthorn — silence + true strike"},
    item_nullifier       = {weight=7, tags={"mute","vs_save"},   note="Nullifier — your items disabled"},
    item_satanic         = {weight=6, tags={"lifesteal"},        note="Satanic — massive lifesteal burst"},
    item_butterfly       = {weight=6, tags={"evasion"},          note="Butterfly — your attacks miss"},
    item_silver_edge     = {weight=6, tags={"break","invis"},    note="Silver Edge — your passives broken"},
    item_heavens_halberd = {weight=6, tags={"disarm"},           note="Halberd — you can't attack"},
    item_assault         = {weight=5, tags={"armor","aura"},     note="AC — armor reduction on your team"},
    item_monkey_king_bar = {weight=5, tags={"vs_evasion"},       note="MKB — your evasion is useless"},
    item_orchid          = {weight=5, tags={"silence"},          note="Orchid — instant silence on you"},
    item_spirit_vessel   = {weight=5, tags={"anti_heal"},        note="Vessel — your healing reduced 45%"},
    item_lotus_orb       = {weight=5, tags={"reflect_spell"},    note="Lotus — targeted spells reflected"},
    item_aeon_disk       = {weight=5, tags={"save"},             note="Aeon — can't be bursted down"},
    item_wind_waker      = {weight=5, tags={"save"},             note="Wind Waker — tornado save"},
    item_radiance        = {weight=4, tags={"burn","miss"},      note="Radiance — miss chance + burn"},
    item_shivas_guard    = {weight=4, tags={"slow","armor"},     note="Shiva — attack slow aura"},
    item_skadi           = {weight=4, tags={"slow","anti_heal"}, note="Skadi — slow + heal reduction"},
    item_desolator       = {weight=4, tags={"armor_reduce"},     note="Deso — armor reduced by 6"},
    item_diffusal_blade  = {weight=4, tags={"mana_burn","slow"}, note="Diffusal — mana drain"},
    item_pipe            = {weight=4, tags={"magic_resist"},     note="Pipe — team magic barrier"},
    item_crimson_guard   = {weight=4, tags={"block"},            note="Crimson — team phys block"},
    item_blade_mail      = {weight=4, tags={"reflect"},          note="Blade Mail — damage reflected"},
    item_manta           = {weight=4, tags={"dispel"},           note="Manta — debuffs dispelled"},
    item_disperser       = {weight=4, tags={"dispel","slow"},    note="Disperser — dispel + slow"},
    item_sphere          = {weight=4, tags={"spell_block"},      note="Linken — one spell blocked"},
    item_ghost           = {weight=3, tags={"ethereal"},         note="Ghost — phys immune temporarily"},
    item_glimmer_cape    = {weight=3, tags={"invis","save"},     note="Glimmer — invis + magic resist"},
    item_heart           = {weight=3, tags={"tanky","regen"},    note="Heart — massive HP regen"},
    item_hurricane_pike  = {weight=3, tags={"save","ranged"},    note="Pike — push-back escape"},
}

--------------------------------------------------------------------------------
-- ITEM-VS-ITEM COUNTERS  (enemy has X → you should buy Y)
--------------------------------------------------------------------------------
M.ITEM_VS_ITEM = {
    item_black_king_bar  = {"item_abyssal_blade","item_rod_of_atos","item_gungir"},
    item_butterfly       = {"item_monkey_king_bar","item_bloodthorn"},
    item_manta           = {"item_orchid","item_sheepstick","item_bloodthorn"},
    item_satanic         = {"item_spirit_vessel","item_skadi"},
    item_heart           = {"item_spirit_vessel","item_skadi"},
    item_ghost           = {"item_nullifier","item_diffusal_blade"},
    item_glimmer_cape    = {"item_nullifier","item_dust"},
    item_aeon_disk       = {"item_nullifier"},
    item_sphere          = {"item_abyssal_blade","item_rod_of_atos"},
    item_pipe            = {"item_desolator","item_assault"},
    item_silver_edge     = {"item_manta","item_lotus_orb"},
    item_orchid          = {"item_manta","item_lotus_orb","item_cyclone"},
    item_bloodthorn      = {"item_manta","item_lotus_orb","item_cyclone"},
    item_sheepstick      = {"item_sphere","item_aeon_disk","item_black_king_bar"},
    item_nullifier       = {"item_black_king_bar","item_lotus_orb"},
    item_radiance        = {"item_monkey_king_bar","item_bloodthorn"},
    item_heavens_halberd = {"item_black_king_bar","item_manta"},
    item_desolator       = {"item_assault","item_solar_crest"},
    item_diffusal_blade  = {"item_manta","item_lotus_orb"},
    item_spirit_vessel   = {"item_manta","item_lotus_orb"},
    item_wind_waker      = {"item_nullifier","item_abyssal_blade"},
    item_hurricane_pike  = {"item_blink","item_abyssal_blade"},
    item_blade_mail      = {"item_nullifier","item_silver_edge"},
    item_crimson_guard   = {"item_desolator","item_mjollnir"},
    item_assault         = {"item_shivas_guard","item_crimson_guard"},
}

--------------------------------------------------------------------------------
-- ANALYZE ENEMY ITEMS: scans all enemy inventories and returns:
--   allItems           = set of all enemy items
--   alerts             = sorted list of dangerous purchases with notes
--   counterSuggestions = {itemName -> count} of counter-items to consider
--------------------------------------------------------------------------------
function M.analyzeEnemyItems(enemies)
    local allItems = {}
    local alerts = {}
    local counterSuggestions = {}

    for _, enemy in ipairs(enemies) do
        for _, item in ipairs(enemy.items or {}) do
            allItems[item] = true
            local threat = M.ENEMY_ITEM_THREATS[item]
            if threat then
                alerts[#alerts + 1] = {
                    hero   = enemy.displayName or enemy.name,
                    item   = item,
                    note   = threat.note,
                    weight = threat.weight,
                }
            end
            local counters = M.ITEM_VS_ITEM[item]
            if counters then
                for _, c in ipairs(counters) do
                    counterSuggestions[c] = (counterSuggestions[c] or 0) + 1
                end
            end
        end
    end

    table.sort(alerts, function(a, b) return (a.weight or 0) > (b.weight or 0) end)

    return {
        allItems           = allItems,
        alerts             = alerts,
        counterSuggestions = counterSuggestions,
    }
end

--------------------------------------------------------------------------------
-- COMPUTE THREAT SCORE: numerical score per enemy hero (higher = more dangerous)
-- Combines hero tags, level, items, and game-time scaling.
--------------------------------------------------------------------------------
local TAG_WEIGHTS = {
    carry = 15, phys_burst = 12, magic_burst = 12, phys_dps = 10,
    disable = 8, stun = 6, hex = 8, silence = 6, invis = 7,
    heal = 5, push = 3, tanky = 4, mobility = 4, summons = 3,
    illusions = 5, global = 6, save = 4, evasion = 5, slow = 3,
}

function M.computeThreatScore(enemy, gameTime)
    local score = 0
    local tags = M.HERO_TAGS[enemy.name] or {}

    for _, tag in ipairs(tags) do
        score = score + (TAG_WEIGHTS[tag] or 2)
    end

    -- Level scaling: each level adds 2 threat
    score = score + (enemy.level or 1) * 2

    -- Item-based threat: each significant item adds its weight
    for _, item in ipairs(enemy.items or {}) do
        local threat = M.ENEMY_ITEM_THREATS[item]
        if threat then
            score = score + threat.weight
        end
    end

    -- Late-game carries scale superlinearly (>30 min)
    if gameTime and gameTime > 1800 then
        for _, tag in ipairs(tags) do
            if tag == "carry" then
                score = math.floor(score * 1.3)
                break
            end
        end
    end

    return score
end

--------------------------------------------------------------------------------
-- 5-AXIS THREAT SCORING SYSTEM
-- Each enemy hero contributes to 5 threat axes:
--   magic     = magical damage potential
--   physical  = physical damage potential
--   disables  = crowd control / lockdown ability
--   invis     = invisibility / detection evasion
--   push      = wave clear / structure damage / summons
--
-- Hero tags map to axes with specific weights.
-- Items owned by the enemy boost the relevant axis.
-- Level and game-time scaling applied.
--------------------------------------------------------------------------------
local TAG_TO_AXIS = {
    -- Magic axis
    magic_burst       = {magic = 12},
    pure_dmg          = {magic = 8},
    mana_burn         = {magic = 4},
    -- Physical axis
    carry             = {physical = 10},
    phys_dps          = {physical = 10},
    phys_burst        = {physical = 12},
    crit              = {physical = 6},
    attack_speed      = {physical = 4},
    cleave            = {physical = 5},
    armor_reduce      = {physical = 6},
    bash              = {physical = 4},
    -- Disables axis
    disable           = {disables = 8},
    stun              = {disables = 7},
    hex               = {disables = 9},
    silence           = {disables = 6},
    doom              = {disables = 12},
    chrono            = {disables = 10},
    black_hole        = {disables = 10},
    root              = {disables = 5},
    fear              = {disables = 6},
    nightmare         = {disables = 5},
    slow              = {disables = 3},
    duel              = {disables = 8},
    -- Invisibility axis
    invis             = {invis = 12},
    track             = {invis = 4},
    -- Push axis
    push              = {push = 10},
    summons           = {push = 8},
    illusions         = {push = 7},
    siege             = {push = 6},
    rearm             = {push = 6},
    -- Cross-axis tags
    global            = {magic = 2, disables = 2},
    mobility          = {physical = 2},
    versatile         = {magic = 3, physical = 3},
    tanky             = {},
    heal              = {},
    save              = {},
    evasion           = {},
    magic_immune      = {},
    magic_resist      = {},
    drain             = {magic = 3},
    break_            = {},
    rupture           = {physical = 4},
    vision            = {},
    steal             = {},
    ward              = {},
    tether            = {},
    reincarnation     = {},
    call              = {disables = 6},
    empower           = {physical = 4},
    split_shot        = {physical = 3},
    farm              = {},
    ranged            = {},
    aura              = {},
    buff              = {},
    int               = {},
    mines             = {magic = 4},
    purge             = {},
    anti_heal         = {},
    magic_resist_reduce = {magic = 5},
}

-- Items that boost an enemy's axis scores when they own them
local ITEM_AXIS_BOOST = {
    -- Physical boosters
    item_desolator       = {physical = 6},
    item_daedalus        = {physical = 8},
    item_butterfly       = {physical = 7},
    item_satanic         = {physical = 5},
    item_monkey_king_bar = {physical = 6},
    item_battlefury      = {physical = 4, push = 3},
    item_assault         = {physical = 5},
    item_silver_edge     = {physical = 4, invis = 4},
    item_diffusal_blade  = {physical = 3},
    item_bloodthorn      = {physical = 6, disables = 5},
    item_abyssal_blade   = {physical = 5, disables = 7},
    item_harpoon         = {physical = 3},
    item_skadi           = {physical = 3},
    item_nullifier       = {physical = 4},
    item_disperser       = {physical = 3},
    item_maelstrom       = {physical = 3},
    item_mjollnir        = {physical = 4},
    -- Magic boosters
    item_dagon           = {magic = 6},
    item_ethereal_blade  = {magic = 6},
    item_veil_of_discord = {magic = 4},
    item_kaya            = {magic = 3},
    item_bloodstone      = {magic = 5},
    item_octarine_core   = {magic = 4},
    item_radiance        = {magic = 4},
    item_shivas_guard    = {magic = 3},
    -- Disable boosters
    item_sheepstick      = {disables = 9},
    item_orchid          = {disables = 5},
    item_rod_of_atos     = {disables = 4},
    item_gungir          = {disables = 5},
    item_heavens_halberd = {disables = 5},
    item_black_king_bar  = {},
    -- Invis boosters
    item_shadow_blade    = {invis = 8},
    item_invis_sword     = {invis = 8},
    item_glimmer_cape    = {invis = 5},
    -- Push boosters
    item_manta           = {push = 4},
    item_helm_of_the_overlord = {push = 5},
    item_helm_of_the_dominator = {push = 3},
    item_necronomicon    = {push = 6},
}

--- Compute per-hero 5-axis threat breakdown.
--- Returns { magic=N, physical=N, disables=N, invis=N, push=N, total=N }
function M.computeThreatAxes(enemy, gameTime)
    local axes = { magic = 0, physical = 0, disables = 0, invis = 0, push = 0 }
    local tags = M.HERO_TAGS[enemy.name] or {}

    -- 1. Hero tags → axis scores
    for _, tag in ipairs(tags) do
        local mapping = TAG_TO_AXIS[tag]
        if mapping then
            for axis, val in pairs(mapping) do
                axes[axis] = axes[axis] + val
            end
        end
    end

    -- 2. Level scaling: higher level = more dangerous across all axes
    local lvl = enemy.level or 1
    local lvlMult = 1.0 + (lvl - 1) * 0.04  -- +4% per level, up to ~1.96 at 25

    -- 3. Item-based axis boosts
    for _, item in ipairs(enemy.items or {}) do
        local boost = ITEM_AXIS_BOOST[item]
        if boost then
            for axis, val in pairs(boost) do
                axes[axis] = axes[axis] + val
            end
        end
    end

    -- 4. Apply level multiplier
    for axis in pairs(axes) do
        axes[axis] = math.floor(axes[axis] * lvlMult)
    end

    -- 5. Late-game carry scaling (>30 min)
    if gameTime and gameTime > 1800 then
        for _, tag in ipairs(tags) do
            if tag == "carry" then
                axes.physical = math.floor(axes.physical * 1.3)
                break
            end
        end
    end

    -- Total (for sorting / overall danger)
    axes.total = axes.magic + axes.physical + axes.disables + axes.invis + axes.push

    return axes
end

--- Compute aggregated 5-axis threat across all enemies.
--- Returns { magic=N, physical=N, disables=N, invis=N, push=N,
---           perHero={[heroName]=axes}, dominant=string }
function M.computeTeamThreatAxes(enemies, gameTime)
    local team = { magic = 0, physical = 0, disables = 0, invis = 0, push = 0 }
    local perHero = {}

    for _, enemy in ipairs(enemies) do
        local heroAxes = M.computeThreatAxes(enemy, gameTime)
        perHero[enemy.name] = heroAxes
        team.magic    = team.magic    + heroAxes.magic
        team.physical = team.physical + heroAxes.physical
        team.disables = team.disables + heroAxes.disables
        team.invis    = team.invis    + heroAxes.invis
        team.push     = team.push     + heroAxes.push
    end

    team.total   = team.magic + team.physical + team.disables + team.invis + team.push
    team.perHero = perHero

    -- Determine dominant axis
    local maxVal, dominant = 0, "physical"
    for _, axis in ipairs({"magic", "physical", "disables", "invis", "push"}) do
        if team[axis] > maxVal then
            maxVal  = team[axis]
            dominant = axis
        end
    end
    team.dominant = dominant

    return team
end

--------------------------------------------------------------------------------
-- AXIS → DEFENSIVE ITEM PRIORITY
-- Maps each threat axis to item tags that should be boosted when that axis
-- is high. The multiplier scales how much extra score items with those tags get.
--------------------------------------------------------------------------------
M.AXIS_DEFENSE_MAP = {
    magic = {
        tags = {"vs_magic", "magic_resist", "barrier", "magic_immune", "vs_disable", "hp"},
        multiplier = 1.0,
    },
    physical = {
        tags = {"vs_phys", "armor", "block", "evasion", "vs_burst", "disarm"},
        multiplier = 1.0,
    },
    disables = {
        tags = {"vs_disable", "magic_immune", "dispel", "save", "block_spell"},
        multiplier = 0.8,
    },
    invis = {
        tags = {"vs_invis", "detection"},
        multiplier = 1.2,
    },
    push = {
        tags = {"vs_illusions", "cleave", "burn"},
        multiplier = 0.7,
    },
}

--- Given team threat axes and an item's tags, compute an axis-based bonus.
--- Items whose tags match the dominant threat axes get significant boosts.
function M.computeAxisBonus(itemTags, teamAxes)
    if not itemTags or not teamAxes then return 0 end

    local bonus = 0
    local tagSet = {}
    for _, t in ipairs(itemTags) do tagSet[t] = true end

    for axis, def in pairs(M.AXIS_DEFENSE_MAP) do
        local axisVal = teamAxes[axis] or 0
        if axisVal > 0 then
            local hits = 0
            for _, tag in ipairs(def.tags) do
                if tagSet[tag] then hits = hits + 1 end
            end
            if hits > 0 then
                -- Scale: each matching tag × axis strength × multiplier
                -- Normalize axis value to 0-1 range (cap at 80 for normalization)
                local norm = math.min(axisVal / 80, 1.0)
                bonus = bonus + hits * norm * 10 * def.multiplier
            end
        end
    end

    return bonus
end

--------------------------------------------------------------------------------
-- PREDICTIVE ENEMY ITEM SYSTEM (backward-compatible wrapper)
-- Full prediction logic has been extracted to enemy_item_predictor.lua.
-- This wrapper delegates to the predictor module when available, otherwise
-- provides a minimal fallback.
--------------------------------------------------------------------------------
local predictor = nil
pcall(function() predictor = require("enemy_item_predictor") end)

function M.predictEnemyItems(enemies, apiCache, gameTime)
    if predictor then
        return predictor.predict(enemies, apiCache, gameTime)
    end
    -- Minimal fallback: no predictions
    return { predictions = {}, anticipatedItems = {} }
end

return M
