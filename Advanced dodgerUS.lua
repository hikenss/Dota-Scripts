--[[

    ╔═══════════════════════════════════════════════════════════════════════════╗

    ║                     ADVANCED DODGER SCRIPT v2.0                           ║

    ║                   Menu: General -> Main -> Dodger                         ║

    ╚═══════════════════════════════════════════════════════════════════════════╝

]]



local Dodger = {}



-- Menu configuration
local menudodger = Menu.Create("General", "Main", "Dodger+")
menudodger:Icon("\u{f0e7}") -- lightning bolt icon
if not menudodger then
    print("Advanced Dodger couldn't find original dodger. Script deactivated")
    return Dodger
end
local customfeatures = menudodger:Create("Custom Features 2.0")
customfeatures:Image("panorama/images/control_icons/star_filled_png.vtex_c")



--[[═══════════════════════════════════════════════════════════════════════════

    MENU LAYOUT

    Left Column:  Self-Defense (triggers and abilities)

    Right Column: Save Allies (top) + Items (self)

═══════════════════════════════════════════════════════════════════════════]]



-- Left Column: Self-Defense Settings

local menuMain = customfeatures:Create("Self-Defense", Enum.GroupSide.Left)

local menuEscapeAbilities = customfeatures:Create("Escape Abilities", Enum.GroupSide.Left)



-- Right Column: Save Allies (top) + Items

local menuSaveAlly = customfeatures:Create("Save Allies", Enum.GroupSide.Right)

local menuEscapeItems = customfeatures:Create("Escape Items", Enum.GroupSide.Right)



local ui = {}



--[[═══════════════════════════════════════════════════════════════════════════

    SELF-DEFENSE - Main toggles for your hero protection

═══════════════════════════════════════════════════════════════════════════]]

ui.enabled = menuMain:Switch("Enable Self-Defense", true, "\u{f00c}")

ui.enabled:ToolTip("Master toggle for all self-defense features")



ui.bypass_protection = menuMain:Switch("Bypass Invisibility Check", false, "\u{f05e}")

ui.bypass_protection:ToolTip("Use escape abilities even when you are invisible")



ui.deathward_dodge = menuMain:Switch("Dodge Death Ward", true, "panorama/images/spellicons/witch_doctor_death_ward_png.vtex_c")

ui.deathward_dodge:ToolTip("Automatically escape when targeted by Witch Doctor's Death Ward")



ui.blink_dodge = menuMain:Switch("React to Enemy Blinks", true, "panorama/images/items/blink_png.vtex_c")

ui.blink_dodge:ToolTip("Use escape when an enemy blinks aggressively towards you")

ui.escape_item_blink = menuMain:Switch("Use Blink Dagger to Escape", true, "panorama/images/items/blink_png.vtex_c")
ui.escape_item_blink:ToolTip("Usa Blink Dagger para pular para longe do inimigo mais pr?ximo (antes das habilidades)")

ui.start_dodge = menuMain:Switch("React to Enemy Initiations", true, "\u{f135}")

ui.start_dodge:ToolTip("Use escape when an enemy starts a gap-closing ability towards you")



ui.no_escape_near_allies = menuMain:Switch("Don't Escape Near Allies", false, "\u{f0c0}")

ui.no_escape_near_allies:ToolTip("Disable escape when allies are nearby to avoid leaving them alone in fights")



ui.no_escape_ally_range = menuMain:Slider("Ally Range Check", 200, 1500, 600, function(value) return value .. " range" end)

ui.no_escape_ally_range:ToolTip("Range to check for nearby allies (only used if 'Don't Escape Near Allies' is enabled)")



--[[═══════════════════════════════════════════════════════════════════════════

    ESCAPE ITEMS - Enemy skills that trigger ally-saving

═══════════════════════════════════════════════════════════════════════════]]

menuEscapeItems:Label("Enemy Skills to Counter")

ui.enemy_skills_save_allies = menuEscapeItems:MultiSelect("", {

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

    { "modifier_winter_wyvern_winters_curse", "panorama/images/spellicons/winter_wyvern_winters_curse_png.vtex_c", true },

}, true)

ui.enemy_skills_save_allies:ToolTip("Select enemy skills that will trigger ally-saving actions")



--[[═══════════════════════════════════════════════════════════════════════════

    ESCAPE ABILITIES - Hero abilities to use for self-protection

═══════════════════════════════════════════════════════════════════════════]]

menuEscapeAbilities:Label("Abilities to Use for Escape")

ui.defensive_abilities = menuEscapeAbilities:MultiSelect("", {

    -- A

    { "antimage_blink", "panorama/images/spellicons/antimage_blink_png.vtex_c", true },

    -- B

    { "bounty_hunter_wind_walk", "panorama/images/spellicons/bounty_hunter_wind_walk_png.vtex_c", true },

    -- C

    { "clinkz_skeleton_walk", "panorama/images/spellicons/clinkz_wind_walk_png.vtex_c", true },

    { "crystal_maiden_crystal_clone", "panorama/images/spellicons/crystal_maiden_crystal_clone_png.vtex_c", true },

    -- E

    { "earth_spirit_rolling_boulder", "panorama/images/spellicons/earth_spirit_rolling_boulder_png.vtex_c", true },

    { "ember_spirit_fire_remnant", "panorama/images/spellicons/ember_spirit_fire_remnant_png.vtex_c", true },

    { "enchantress_bunny_hop", "panorama/images/spellicons/enchantress_bunny_hop_png.vtex_c", true },

    -- F

    { "faceless_void_time_walk", "panorama/images/spellicons/faceless_void_time_walk_png.vtex_c", true },

    { "furion_sprout", "panorama/images/spellicons/furion_sprout_png.vtex_c", true },

    -- H

    -- { "hoodwink_scurry", "panorama/images/spellicons/hoodwink_scurry_png.vtex_c", true }, -- Removido: não é bom escape

    -- I

    { "invoker_ghost_walk", "panorama/images/spellicons/invoker_ghost_walk_png.vtex_c", true },

    -- J

    { "juggernaut_blade_fury", "panorama/images/spellicons/juggernaut_blade_fury_png.vtex_c", true },

    -- L

    { "lifestealer_rage", "panorama/images/spellicons/life_stealer_rage_png.vtex_c", true },

    -- M

    { "magnataur_skewer", "panorama/images/spellicons/magnataur_skewer_png.vtex_c", true },

    { "marci_rebound", "panorama/images/spellicons/marci_companion_run_png.vtex_c", true },

    { "mirana_leap", "panorama/images/spellicons/mirana_leap_png.vtex_c", true },

    { "monkey_king_tree_dance", "panorama/images/spellicons/monkey_king_tree_dance_png.vtex_c", true },

    { "morphling_waveform", "panorama/images/spellicons/morphling_waveform_png.vtex_c", true },

    -- N

    { "naga_siren_mirror_image", "panorama/images/spellicons/naga_siren_mirror_image_png.vtex_c", true },

    { "nyx_assassin_vendetta", "panorama/images/spellicons/nyx_assassin_vendetta_png.vtex_c", true },

    -- O

    { "omniknight_martyr", "panorama/images/spellicons/omniknight_martyr_png.vtex_c", true },

    -- P

    { "pangolier_swashbuckle", "panorama/images/spellicons/pangolier_swashbuckle_png.vtex_c", true },

    { "phantom_lancer_doppelwalk", "panorama/images/spellicons/phantom_lancer_doppelwalk_png.vtex_c", true },

    { "phoenix_icarus_dive", "panorama/images/spellicons/phoenix_icarus_dive_png.vtex_c", true },

    { "puck_phase_shift", "panorama/images/spellicons/puck_phase_shift_png.vtex_c", true },

    -- Q

    { "queenofpain_blink", "panorama/images/spellicons/queenofpain_blink_png.vtex_c", true },

    -- R

    { "rattletrap_power_cogs", "panorama/images/spellicons/rattletrap_power_cogs_png.vtex_c", true },

    { "rattletrap_hookshot", "panorama/images/spellicons/rattletrap_hookshot_png.vtex_c", true },

    { "riki_tricks_of_the_trade", "panorama/images/spellicons/riki_tricks_of_the_trade_png.vtex_c", true },

    -- S

    { "sandking_sand_storm", "panorama/images/spellicons/sandking_sand_storm_png.vtex_c", true },

    { "slark_pounce", "panorama/images/spellicons/slark_pounce_png.vtex_c", true },

    { "slark_shadow_dance", "panorama/images/spellicons/slark_shadow_dance_png.vtex_c", true },

    { "sniper_concussive_grenade", "panorama/images/spellicons/sniper_concussive_grenade_png.vtex_c", true },

    { "storm_spirit_ball_lightning", "panorama/images/spellicons/storm_spirit_ball_lightning_png.vtex_c", true },

    -- T

    { "templar_assassin_refraction", "panorama/images/spellicons/templar_assassin_refraction_png.vtex_c", true },

    { "shredder_timber_chain", "panorama/images/spellicons/shredder_timber_chain_png.vtex_c", true },

    { "tusk_ice_shards", "panorama/images/spellicons/tusk_ice_shards_png.vtex_c", true },

    -- V

    { "void_spirit_dissimilate", "panorama/images/spellicons/void_spirit_dissimilate_png.vtex_c", true },

    { "void_spirit_astral_step", "panorama/images/spellicons/void_spirit_astral_step_png.vtex_c", true },

    -- W

    { "weaver_shukuchi", "panorama/images/spellicons/weaver_shukuchi_png.vtex_c", true },

    -- Z

    { "zuus_heavenly_jump", "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c", true },

}, true)

ui.defensive_abilities:ToolTip("Select hero abilities to automatically use when escaping")



menuEscapeAbilities:Label("Enemy Initiations to React")

ui.enemy_skills_dodge = menuEscapeAbilities:MultiSelect("", {

    -- Blinks

    { "modifier_antimage_blink", "panorama/images/spellicons/antimage_blink_png.vtex_c", true },

    { "modifier_queenofpain_blink", "panorama/images/spellicons/queenofpain_blink_png.vtex_c", true },

    { "modifier_item_blink_cooldown", "panorama/images/items/blink_png.vtex_c", true },

    { "modifier_faceless_void_time_walk", "panorama/images/spellicons/faceless_void_time_walk_png.vtex_c", true },

    -- Mobility Skills

    { "modifier_mirana_leap", "panorama/images/spellicons/mirana_leap_png.vtex_c", true },

    { "modifier_slark_pounce", "panorama/images/spellicons/slark_pounce_png.vtex_c", true },

    { "modifier_phantom_assassin_phantom_strike", "panorama/images/spellicons/phantom_assassin_phantom_strike_png.vtex_c", true },

    { "modifier_riki_blink_strike", "panorama/images/spellicons/riki_blink_strike_png.vtex_c", true },

    { "modifier_zuus_heavenly_jump", "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c", true },

    -- Charge Skills

    { "modifier_magnataur_skewer_movement", "panorama/images/spellicons/magnataur_skewer_png.vtex_c", true },

    { "modifier_earth_spirit_rolling_boulder_caster", "panorama/images/spellicons/earth_spirit_rolling_boulder_png.vtex_c", true },

    { "modifier_storm_spirit_ball_lightning", "panorama/images/spellicons/storm_spirit_ball_lightning_png.vtex_c", true },

}, true)

ui.enemy_skills_dodge:ToolTip("Select which enemy gap-closers will trigger your escape")



--[[═══════════════════════════════════════════════════════════════════════════

    INTERNAL CONFIG - Optimized values based on Dota 2 mechanics

═══════════════════════════════════════════════════════════════════════════]]

local CONFIG = {

    -- Escape Detection

    escape_detection_range = 900,

    escape_activation_range = 450,

    escape_ally_disadvantage = 1,

    -- Ally Items

    allies_items_hp = 35,

    allies_items_range = 700,

    allies_items_count = 1,

    -- Ally Abilities

    allies_abilities_hp = 25,

    allies_abilities_range = 800,

    allies_abilities_count = 1,

    -- Enemy Skills (Save Allies)

    enemy_skills_save_allies_hp = 100,

    enemy_skills_save_allies_range = 900,

    enemy_skills_save_allies_count = 1,

}



--[[═══════════════════════════════════════════════════════════════════════════

    SAVE ALLIES - Use items and abilities to protect teammates

═══════════════════════════════════════════════════════════════════════════]]

ui.allies_support = menuSaveAlly:Switch("Enable Save Allies", false, "\u{f0c0}")

ui.allies_support:ToolTip("Master toggle: Use items and abilities to save allies from dangerous situations")



ui.save_ally_on_initiation = menuSaveAlly:Switch("Save Allies on Enemy Initiation", true, "\u{f135}")

ui.save_ally_on_initiation:ToolTip("Use items on allies when enemies blink/jump towards them")



ui.use_euls_offensive = menuSaveAlly:Switch("Eul's on Enemy Caster", true, "panorama/images/items/cyclone_png.vtex_c")

ui.use_euls_offensive:ToolTip("Use Eul's Scepter on the enemy applying CC to interrupt and save your ally")



menuSaveAlly:Label("Items to Save Allies")

ui.allies_items = menuSaveAlly:MultiSelect("", {

    { "item_wind_waker", "panorama/images/items/wind_waker_png.vtex_c", true },

    { "item_glimmer_cape", "panorama/images/items/glimmer_cape_png.vtex_c", true },

    { "item_lotus_orb", "panorama/images/items/lotus_orb_png.vtex_c", true },

    { "item_ethereal_blade", "panorama/images/items/ethereal_blade_png.vtex_c", true },

    { "item_shadow_amulet", "panorama/images/items/shadow_amulet_png.vtex_c", true },

    { "item_force_staff", "panorama/images/items/force_staff_png.vtex_c", true },

    { "item_hurricane_pike", "panorama/images/items/hurricane_pike_png.vtex_c", true },

}, true)

ui.allies_items:ToolTip("Select items to use on allies when enemies initiate on them")



menuSaveAlly:Label("Abilities to Save Allies")

ui.allies_abilities = menuSaveAlly:MultiSelect("", {

    { "phoenix_supernova", "panorama/images/spellicons/phoenix_supernova_png.vtex_c", true },

    { "centaur_mount", "panorama/images/spellicons/centaur_mount_png.vtex_c", true },

    { "marci_rebound", "panorama/images/spellicons/marci_companion_run_png.vtex_c", true },

}, true)

ui.allies_abilities:ToolTip("Select abilities to use on allies affected by the skills above")



-- Tabela para rastrear posições anteriores dos inimigos

local enemyPositions = {}

local blinkCooldowns = {}

local lastEscapeTime = 0

local enemyFirstSeen = {} -- Rastreia quando inimigo foi visto pela primeira vez

-- Rastreamento do movimento recente do meu herói (evita falsos positivos quando eu mesmo blinko)
local lastMyPos = nil
local lastMyMove = 0
local lastMyMoveTime = 0


-- Ember Spirit: rastreia quando jogou remnant e precisa ativar

local emberPendingRemnant = {

    active = false,

    pos = nil,

    time = 0,

    attempts = 0

}



-- Phoenix: rastreia quando usou Icarus Dive e precisa cancelar

local phoenixDivePending = {

    active = false,

    time = 0,

    targetPos = nil

}



-- Marci: rastreia quando usou Rebound e precisa enviar direção

local marciReboundPending = {

    active = false,

    time = 0,

    escapePos = nil

}



-- Earth Spirit: rastreia quando colocou Remnant e precisa rolar

local earthSpiritPending = {

    active = false,

    time = 0,

    escapePos = nil

}



-- Puck: rastreia quando lançou Orb e precisa usar Phase Shift

local puckOrbPending = {

    active = false,

    time = 0

}



-- Mirana: rastreia quando virou e precisa pular

local miranaPending = {

    active = false,

    time = 0,

    escapePos = nil

}



-- Slark: rastreia quando virou e precisa pular

local slarkPending = {

    active = false,

    time = 0,

    escapePos = nil

}



-- Zeus: rastreia quando virou e precisa pular

local zeusPending = {

    active = false,

    time = 0,

    escapePos = nil

}



-- Tabela para rastrear animações detectadas

local animationDetected = {}



-- Mapeamento de animações para modifiers (apenas skills que estão nas tabelas de detecção)

local animationToModifier = {

    -- Blinks instantâneos

    ["blink_dagger"] = "modifier_item_blink_cooldown",

    ["time_walk"] = "modifier_faceless_void_time_walk",

    -- Targeted blinks

    ["strike"] = "modifier_phantom_assassin_phantom_strike",

    ["blink_strike"] = "modifier_riki_blink_strike",

    -- Movimentos agressivos

    ["leap"] = "modifier_mirana_leap",

    ["pounce"] = "modifier_slark_pounce",

    ["skewer"] = "modifier_magnataur_skewer_movement",

    ["rolling_boulder"] = "modifier_earth_spirit_rolling_boulder_caster",

    ["heavenly_jump"] = "modifier_zuus_heavenly_jump",

}



-- Skills que são teleportes instantâneos (blinks) - verificamos se apareceu perto

local instantBlinkMods = {

    ["modifier_item_blink_cooldown"] = true,

    ["modifier_antimage_blink"] = true,

    ["modifier_queenofpain_blink"] = true,

}



-- Blinks que são TARGETED em unidade - se o alvo for aliado, NUNCA reagir

-- Estes blinks só ativam se o inimigo blinkar EM MIM

local targetedBlinkMods = {

    ["modifier_phantom_assassin_phantom_strike"] = true,

    ["modifier_riki_blink_strike"] = true,

}



-- Skills de movimento contínuo que são SEMPRE agressivas quando próximo

-- Se o inimigo está perto e tem esse modifier, ele está vindo pra cima

local aggressiveMovementMods = {

    ["modifier_mirana_leap"] = true,

    ["modifier_slark_pounce"] = true,

    ["modifier_magnataur_skewer_movement"] = true,

    ["modifier_earth_spirit_rolling_boulder_caster"] = true,

    ["modifier_storm_spirit_ball_lightning"] = true,

    ["modifier_zuus_heavenly_jump"] = true,

}



-- Dash skills rápidos - precisam de lógica híbrida (blink + movimento)

-- Time Walk é muito rápido, precisa verificar se apareceu perto OU está se movendo

local fastDashMods = {

    ["modifier_faceless_void_time_walk"] = true,

}

-- Função para atualizar posições de todos os inimigos (deve ser chamada todo frame)

local function UpdateEnemyPositions(myHero)

    if not myHero then return end

    

    local enemies = Heroes.GetAll()

    local currentTime = GameRules.GetGameTime()

    local myPos = Entity.GetAbsOrigin(myHero)

    -- Track my recent movement so my own blink is not mistaken for an enemy blink
    if lastMyPos then
        lastMyMove = (myPos - lastMyPos):Length()
    else
        lastMyMove = 0
    end
    lastMyPos = myPos
    lastMyMoveTime = currentTime

    for _, enemy in pairs(enemies) do

        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

            local enemyID = Entity.GetIndex(enemy)

            local currentPos = Entity.GetAbsOrigin(enemy)

            local distanceToMe = (currentPos - myPos):Length()

            -- Guardar posi????o anterior antes de atualizar

            local prevData = enemyPositions[enemyID]

            -- Se estava fora de vis??o (dormant), apenas marca e n??o usa dados antigos
            if Entity.IsDormant(enemy) then
                enemyPositions[enemyID] = prevData or {}
                enemyPositions[enemyID].dormant = true
                enemyPositions[enemyID].lastSeen = prevData and prevData.lastSeen or currentTime
                enemyPositions[enemyID].lastVisibleDist = prevData and prevData.distToMe or enemyPositions[enemyID].lastVisibleDist or distanceToMe
                goto continue_enemy_loop
            end

            local wasDormant = prevData and prevData.dormant
            if wasDormant then
                -- Mantém hist?rico antigo para comparar movimento real ao sair do fog
                enemyPositions[enemyID].dormant = false
            end

            -- Hist??rico est??vel - atualiza a cada 0.15s

            local oldDist = prevData and prevData.oldDistToMe or distanceToMe

            local oldPos = prevData and prevData.oldPos or currentPos

            local oldTime = prevData and prevData.oldTime or currentTime

            local prevPos = prevData and prevData.pos or currentPos

            local prevDist = prevData and prevData.distToMe or distanceToMe

            local prevTime = prevData and prevData.time or currentTime

            -- Distância quando foi visto pela última vez antes do fog
            local lastVisibleDist = prevData and (prevData.lastVisibleDist or prevData.distToMe) or distanceToMe

            -- Quando sai do fog, avalia se houve salto grande (blink real) em vez de só caminhar
            local jumpFromFogBlink = false
            if wasDormant then
                enemyFirstSeen[enemyID] = currentTime
                prevPos = currentPos
                prevDist = distanceToMe
                prevTime = currentTime
                oldDist = distanceToMe
                oldPos = currentPos
                oldTime = currentTime
                -- Considera blink se antes estava muito longe e reapareceu bem perto
                if lastVisibleDist and lastVisibleDist > 1200 and distanceToMe < 400 and (lastVisibleDist - distanceToMe) > 800 then
                    jumpFromFogBlink = true
                end
                enemyPositions[enemyID].dormant = false
            end

            -- Atualiza hist??rico a cada 0.15 segundos

            if (not prevData or not wasDormant) and (currentTime - oldTime) > 0.15 then

                oldDist = prevData and prevData.distToMe or distanceToMe

                oldPos = prevData and prevData.pos or currentPos

                oldTime = currentTime

            end

            enemyPositions[enemyID] = {

                pos = currentPos,

                time = currentTime,

                distToMe = distanceToMe,

                prevPos = prevPos,

                prevDistToMe = prevDist,

                prevTime = prevTime,

                -- Hist??rico mais antigo (0.15s atr??s)

                oldDistToMe = oldDist,

                oldPos = oldPos,

                oldTime = oldTime,

                dormant = false,

                lastSeen = currentTime,

                lastVisibleDist = distanceToMe,

                jumpFromFogBlink = jumpFromFogBlink

            }

        end
        ::continue_enemy_loop::

    end

end


-- Helper: Verifica se inimigo está se aproximando (distância diminuindo)

local function IsEnemyApproaching(myHero, enemy)

    if not myHero or not enemy then return false end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    

    if not data or not data.prevDistToMe then

        return false

    end

    

    -- Distância está diminuindo? (inimigo ficando mais perto)

    return data.distToMe < data.prevDistToMe - 30

end



-- Helper: Verifica direção do movimento do inimigo

local function IsMovingTowardsMe(myHero, enemy)

    if not myHero or not enemy then return false end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    

    if not data or not data.prevPos then

        return false

    end

    

    local myPos = Entity.GetAbsOrigin(myHero)

    local currentPos = data.pos

    local prevPos = data.prevPos

    

    -- Vetor de movimento

    local movement = currentPos - prevPos

    local moveLen = movement:Length2D()

    

    -- Se não se moveu muito, verificar só distância

    if moveLen < 30 then

        return IsEnemyApproaching(myHero, enemy)

    end

    

    -- Vetor do inimigo para mim

    local toMe = myPos - currentPos

    

    -- Dot product: positivo = vindo na minha direção

    local moveDir = movement:Normalized()

    local toMeDir = toMe:Normalized()

    local dot = moveDir.x * toMeDir.x + moveDir.y * toMeDir.y

    

    return dot > 0.1

end



-- Helper: Calcula o dot product de direção do inimigo para um alvo

local function GetDirectionDotProduct(enemy, targetPos)

    if not enemy then return -1 end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    

    if not data or not data.prevPos then

        return 0

    end

    

    local currentPos = data.pos

    local prevPos = data.prevPos

    

    local movement = currentPos - prevPos

    local moveLen = movement:Length2D()

    

    if moveLen < 30 then

        return 0

    end

    

    local toTarget = targetPos - currentPos

    local moveDir = movement:Normalized()

    local toTargetDir = toTarget:Normalized()

    

    return moveDir.x * toTargetDir.x + moveDir.y * toTargetDir.y

end



-- Helper: Verifica se o inimigo está mais focado em um aliado do que em mim

-- Considera tanto a distância quanto a DIREÇÃO do movimento

-- Retorna true SOMENTE se temos certeza que o aliado é o alvo

local function IsEnemyTargetingAllyInsteadOfMe(myHero, enemy)

    if not myHero or not enemy then return false end

    

    local myPos = Entity.GetAbsOrigin(myHero)

    local enemyPos = Entity.GetAbsOrigin(enemy)

    local distToMe = (enemyPos - myPos):Length()

    

    -- Se estou perto, sou eu o alvo com certeza

    if distToMe < 400 then

        return false

    end

    

    local dotToMe = GetDirectionDotProduct(enemy, myPos)

    

    -- Se o inimigo está claramente vindo na minha direção (dot > 0.6), sou eu o alvo

    if dotToMe > 0.6 then

        return false

    end

    

    -- Procurar aliados

    local allies = Heroes.GetAll()

    for _, ally in pairs(allies) do

        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

            local allyPos = Entity.GetAbsOrigin(ally)

            local distToAlly = (enemyPos - allyPos):Length()

            local dotToAlly = GetDirectionDotProduct(enemy, allyPos)

            

            -- CRITÉRIO RIGOROSO: Só dizer que é no aliado se:

            -- 1. Aliado está MUITO mais perto (>300 unidades de diferença) E perto do inimigo (<500)

            -- 2. OU: Inimigo está claramente indo pro aliado (dot > 0.7) E aliado está perto (<600) E mais perto que eu

            

            -- Caso 1: Aliado muito mais perto

            if distToAlly < 500 and distToAlly < distToMe - 300 then

                return true

            end

            

            -- Caso 2: Direção muito clara para o aliado E não pra mim

            if distToAlly < 600 and dotToAlly > 0.7 and dotToMe < 0.3 and distToAlly < distToMe then

                return true

            end

        end

        ::continue_enemy::
    end

    

    return false

end



-- Helper: Verifica se um blink foi feito PARA PERTO de mim (blinks não-targeted como Blink Dagger, AM, QoP)

local function IsBlinkTowardsMe(myHero, enemy)

    if not myHero or not enemy then return false end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    local myPos = Entity.GetAbsOrigin(myHero)

    local currentPos = Entity.GetAbsOrigin(enemy)

    local currentDist = (currentPos - myPos):Length()

    local enemyMove = 0
    if data and data.prevPos then
        enemyMove = (currentPos - data.prevPos):Length()
    end

    local myMove = lastMyMove or 0
    -- If the enemy barely moved and I moved a lot (my blink), don't treat it as a threat
    if enemyMove < 120 and myMove > 350 then
        return false
    end

    

    -- MUITO PERTO (<200): sempre reage, é definitivamente uma ameaça

    if currentDist < 200 then

        -- Só ignora se aliado está MAIS perto ainda

        local allies = Heroes.GetAll()

        for _, ally in pairs(allies) do

            if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                local allyPos = Entity.GetAbsOrigin(ally)

                local distToAlly = (currentPos - allyPos):Length()

                if distToAlly < currentDist - 50 then

                    return false

                end

            end

        end

        return true  -- Muito perto, reage!

    end

    

    if not data or not data.prevDistToMe then

        -- Sem dados anteriores, verificar só se está perto

        return currentDist < 400

    end

    

    local prevDist = data.prevDistToMe

    

    -- Blink agressivo: estava longe e agora está perto

    -- OU ficou significativamente mais perto

    local blinkDetected = false

    

    if prevDist > 800 and currentDist < 700 then

        blinkDetected = true

    elseif (prevDist - currentDist) > 400 then

        blinkDetected = true

    end

    

    -- Se não detectou blink mas está perto, pode ter sido blink instantâneo

    if not blinkDetected and currentDist < 350 then

        blinkDetected = true

    end

    

    -- Se detectou blink, verificar se foi para perto de mim ou de um aliado

    if blinkDetected then

        -- Verificar se algum aliado está mais perto do inimigo

        local allies = Heroes.GetAll()

        for _, ally in pairs(allies) do

            if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                local allyPos = Entity.GetAbsOrigin(ally)

                local distToAlly = (currentPos - allyPos):Length()

                

                -- Se aliado está mais perto ou quase igual, foi no aliado

                if distToAlly < currentDist - 100 and distToAlly < 500 then

                    return false -- Blink foi no aliado, não em mim

                end

                

                -- Se estamos muito próximos um do outro e aliado está igualmente perto, não triggar

                if distToAlly < 400 and currentDist > 350 then

                    return false

                end

            end

        end

        return true

    end

    

    return false

end



-- Helper: Verifica se um targeted blink (PA/Riki) foi em MIM e não em um aliado

local function IsTargetedBlinkOnMe(myHero, enemy)

    if not myHero or not enemy then return false end

    

    local myPos = Entity.GetAbsOrigin(myHero)

    local enemyPos = Entity.GetAbsOrigin(enemy)

    local distToMe = (enemyPos - myPos):Length()

    

    -- MUITO PERTO (<150): sempre reage, é definitivamente uma ameaça direta

    if distToMe < 150 then

        -- Só ignora se aliado está MAIS perto ainda

        local allies = Heroes.GetAll()

        for _, ally in pairs(allies) do

            if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                local allyPos = Entity.GetAbsOrigin(ally)

                local distToAlly = (enemyPos - allyPos):Length()

                if distToAlly < distToMe - 30 then

                    return false

                end

            end

        end

        return true  -- Muito perto, reage!

    end

    

    -- Targeted blinks tem range curto (~300 para PA, ~550 para Riki após blink)

    if distToMe > 350 then

        return false -- Muito longe para ter sido targeted em mim

    end

    

    -- Verificar se algum aliado está mais perto - se sim, foi no aliado

    local allies = Heroes.GetAll()

    for _, ally in pairs(allies) do

        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

            local allyPos = Entity.GetAbsOrigin(ally)

            local distToAlly = (enemyPos - allyPos):Length()

            

            -- Se aliado está mais perto ou igual, foi no aliado (independente da distância do aliado pra mim)

            if distToAlly <= distToMe then

                return false

            end

        end

        ::continue_enemy::
    end

    

    return true -- Eu sou o mais perto, foi em mim

end



-- Helper principal: Determina se devemos reagir a um modifier

local function ShouldReactToMod(myHero, enemy, modName)

    if not myHero or not enemy or not modName then return false end

    

    local myPos = Entity.GetAbsOrigin(myHero)

    local enemyPos = Entity.GetAbsOrigin(enemy)

    local dist = (enemyPos - myPos):Length()

    

    -- Para TARGETED blinks (PA/Riki): só reagir se foi EM MIM

    -- Estes são blinks que precisam de um alvo, então verificamos quem foi o alvo

    if targetedBlinkMods[modName] then

        return IsTargetedBlinkOnMe(myHero, enemy)

    end

    

    -- Para blinks instantâneos normais: verificar se blinkaram PARA perto de mim

    if instantBlinkMods[modName] then

        return IsBlinkTowardsMe(myHero, enemy)

    end

    

    -- Para dash skills rápidos (Time Walk): só dispara se VEIO na minha direção

    -- Precisa verificar que o inimigo realmente se moveu E veio na minha direção

    if fastDashMods[modName] then

        -- Se está perto o suficiente para ser ameaça (aumentado range para pegar blinks colados)

        if dist < 400 then

            local enemyID = Entity.GetIndex(enemy)

            local data = enemyPositions[enemyID]

            

            -- Se está MUITO perto (<200), sempre reage - é definitivamente uma ameaça

            if dist < 200 then

                -- Só ignora se aliado está mais perto

                local allies = Heroes.GetAll()

                for _, ally in pairs(allies) do

                    if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                        local allyPos = Entity.GetAbsOrigin(ally)

                        local distToAlly = (enemyPos - allyPos):Length()

                        if distToAlly < dist - 50 then

                            return false

                        end

                    end

                end

                return true  -- Muito perto, reage!

            end

            

            if data then

                local oldDist = data.oldDistToMe or dist

                local oldPos = data.oldPos or enemyPos

                

                -- Calcular distância que o inimigo REALMENTE se moveu

                local actualMovement = (enemyPos - oldPos):Length()

                

                -- Só dispara se:

                -- 1. O inimigo se moveu significativamente (>200 unidades) - confirma que usou dash

                -- 2. E estava mais longe antes (veio na minha direção)

                -- 3. E a diferença de distância é significativa (>100)

                local movedSignificantly = actualMovement > 200

                local cameCloser = (oldDist - dist) > 100

                

                if not (movedSignificantly and cameCloser) then

                    return false  -- Não se moveu o suficiente ou não veio na minha direção

                end

            else

                return false  -- Sem dados, não reagir

            end

            

            -- Só ignora se aliado está MUITO mais perto do inimigo (>200 de diferença)

            -- E o aliado está bem perto do inimigo (<300)

            local allies = Heroes.GetAll()

            for _, ally in pairs(allies) do

                if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                    local allyPos = Entity.GetAbsOrigin(ally)

                    local distToAlly = (enemyPos - allyPos):Length()

                    -- Só ignora se aliado está MUITO mais perto que eu (>200 de diferença)

                    if distToAlly < 300 and distToAlly < dist - 200 then

                        return false

                    end

                end

            end

            return true

        end

        return false

    end

    

    -- Para skills de movimento agressivo: 

    -- Primeiro verificar se o inimigo está direcionado para um aliado

    if IsEnemyTargetingAllyInsteadOfMe(myHero, enemy) then

        return false

    end

    

    -- Se está perto (<800) E tem o modifier E está se aproximando = perigo

    if aggressiveMovementMods[modName] then

        if dist < 800 then

            -- Verificar se está vindo na minha direção OU se aproximando

            local approaching = IsEnemyApproaching(myHero, enemy)

            local movingToMe = IsMovingTowardsMe(myHero, enemy)

            return approaching or movingToMe

        end

        return false

    end

    

    -- Para outros: verificar se está se aproximando

    return IsEnemyApproaching(myHero, enemy)

end



-- Helper: Verifica se um blink foi feito PARA PERTO de um aliado específico

local function IsBlinkTowardsAlly(ally, enemy)

    if not ally or not enemy then return false end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    local allyPos = Entity.GetAbsOrigin(ally)

    local currentPos = Entity.GetAbsOrigin(enemy)

    local currentDistToAlly = (currentPos - allyPos):Length()

    

    if not data or not data.prevPos then

        -- Sem dados anteriores, verificar só se está perto do aliado

        return currentDistToAlly < 500

    end

    

    local prevPos = data.prevPos

    local prevDistToAlly = (prevPos - allyPos):Length()

    

    -- Blink agressivo no aliado: estava longe do aliado e agora está perto

    if prevDistToAlly > 800 and currentDistToAlly < 500 then

        return true

    end

    

    -- Ficou significativamente mais perto do aliado

    if (prevDistToAlly - currentDistToAlly) > 350 then

        return true

    end

    

    return false

end



-- Helper: Verifica se inimigo está se movendo em direção a um aliado

local function IsMovingTowardsAlly(ally, enemy)

    if not ally or not enemy then return false end

    

    local enemyID = Entity.GetIndex(enemy)

    local data = enemyPositions[enemyID]

    

    if not data or not data.prevPos then

        return false

    end

    

    local allyPos = Entity.GetAbsOrigin(ally)

    local currentPos = data.pos

    local prevPos = data.prevPos

    

    -- Vetor de movimento

    local movement = currentPos - prevPos

    local moveLen = movement:Length2D()

    

    if moveLen < 30 then

        return false

    end

    

    -- Vetor do inimigo para o aliado

    local toAlly = allyPos - currentPos

    

    -- Dot product: positivo = indo na direção do aliado

    local moveDir = movement:Normalized()

    local toAllyDir = toAlly:Normalized()

    local dot = moveDir.x * toAllyDir.x + moveDir.y * toAllyDir.y

    

    return dot > 0.3

end



-- Helper: Determina se devemos salvar um aliado específico de um inimigo

local function ShouldSaveAllyFromEnemy(ally, enemy, modName)

    if not ally or not enemy or not modName then return false end

    

    local allyPos = Entity.GetAbsOrigin(ally)

    local enemyPos = Entity.GetAbsOrigin(enemy)

    local dist = (enemyPos - allyPos):Length()

    

    -- Para blinks instantâneos: verificar se blinkaram PARA perto do aliado

    if instantBlinkMods[modName] then

        return IsBlinkTowardsAlly(ally, enemy)

    end

    

    -- Para skills de movimento agressivo: 

    if aggressiveMovementMods[modName] then

        if dist < 700 then

            return IsMovingTowardsAlly(ally, enemy)

        end

        return false

    end

    

    return false

end



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



-- Função unificada para usar habilidades defensivas

local function UseDefensiveItems(myHero)

    local heroName = NPC.GetUnitName(myHero)

    

    -- Verifica proteção apenas se o bypass não estiver ativado

    if not ui.bypass_protection:Get() and IsAlreadyProtected(myHero) then

        return false

    end

    -- Obter lista de habilidades habilitadas

    local enabledAbilities = ui.defensive_abilities:ListEnabled()

    

    -- Função para verificar se habilidade está na lista habilitada

    local function IsAbilityEnabled(abilityName)

        for _, name in ipairs(enabledAbilities) do

            if name == abilityName then return true end

        end

        return false

    end

    

    -- Habilidades defensivas específicas por herói

    -- Nyx Assassin - Vendetta

    if heroName == "npc_dota_hero_nyx_assassin" and IsAbilityEnabled("nyx_assassin_vendetta") then

        local vendetta = IsAbilityAvailable("nyx_assassin_vendetta", myHero)

        if vendetta then

            Ability.CastNoTarget(vendetta)

            return true

        end

    end

    

    -- Puck - Illusory Orb + Phase Shift combo (Orb primeiro para criar ponto de fuga)

    if heroName == "npc_dota_hero_puck" and IsAbilityEnabled("puck_phase_shift") then

        local illusoryOrb = NPC.GetAbility(myHero, "puck_illusory_orb")

        local phaseShift = NPC.GetAbility(myHero, "puck_phase_shift")

        

        -- Primeiro lança o Orb na direção de escape (se disponível)

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

                

                -- Marca pendente para usar Phase Shift após o Orb

                puckOrbPending = {

                    active = true,

                    time = GameRules.GetGameTime()

                }

                return true

            end

        end

        

        -- Se não tem Orb mas tem Phase Shift, usa Phase Shift sozinho

        if phaseShift and Ability.IsCastable(phaseShift, 0) then

            Ability.CastNoTarget(phaseShift)

            return true

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



-- Função para detectar blinks inimigos (movimento instantâneo sem modifier)

local function DetectEnemyBlink(myHero)

    local enemies = Heroes.GetAll()

    local currentTime = GameRules.GetGameTime()

    local myPos = Entity.GetAbsOrigin(myHero)

    for _, enemy in pairs(enemies) do

        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

            local enemyID = Entity.GetIndex(enemy)
            -- Se est鈋 dormente (fog), n緌 reprocessa para evitar falsos positivos ao aproximar
            if Entity.IsDormant(enemy) then
                goto continue
            end
            local data = enemyPositions[enemyID]

            -- Rastrear quando o inimigo foi visto pela primeira vez
            if not enemyFirstSeen[enemyID] then
                enemyFirstSeen[enemyID] = currentTime
            end

            if data and data.pos and data.oldPos then
                local currentPos = data.pos
                local distanceToMe = data.distToMe
                local oldPos = data.oldPos
                local oldDist = data.oldDistToMe or distanceToMe

                -- Reapareceu do fog e deu salto grande (blink)? reage, sen?o ignora
                if data.jumpFromFogBlink and distanceToMe < 450 then
                    enemyPositions[enemyID].jumpFromFogBlink = nil

                    -- Evita falso positivo quando eu blinkei e o inimigo quase n?o se moveu
                    local enemyMove = data.prevPos and (currentPos - data.prevPos):Length() or 0
                    if lastMyMove > 350 and enemyMove < 250 then
                        goto continue
                    end

                    local iAmClosest = true
                    for _, ally in pairs(enemies) do
                        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then
                            local allyPos = Entity.GetAbsOrigin(ally)
                            local distToAlly = (currentPos - allyPos):Length()
                            if distToAlly + 200 < distanceToMe then
                                iAmClosest = false
                                break
                            end
                        end
                    end

                    if iAmClosest then
                        local cooldown = 0.4
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > cooldown then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end

                -- Calcular dist?ncia que o inimigo REALMENTE se moveu
                local actualMovement = (currentPos - oldPos):Length()

                -- Ignora inimigos que acabaram de sair do fog, a menos que estejam colados ou tenham teleportado para perto
                local timeSinceFirstSeen = currentTime - enemyFirstSeen[enemyID]
                if timeSinceFirstSeen < 0.5 then
                    if distanceToMe > 350 and actualMovement < 250 then
                        goto continue
                    end
                end

                -- Se eu que me movi muito (meu blink) e o inimigo quase n?o se moveu, n?o conta
                if actualMovement < 150 and lastMyMove > 350 and (oldDist - distanceToMe) > 300 then
                    goto continue
                end

                -- S? dispara se:
                -- 1. O inimigo se moveu muito (>300 unidades) - confirma blink/dash
                -- 2. E veio na minha dire??o (ficou mais perto)
                -- 3. E est? perto agora
                local movedFast = actualMovement > 350
                local cameCloser = (oldDist - distanceToMe) > 180
                local isClose = distanceToMe < 700

                -- Evita acionar se ele j? estava vis?vel e apenas caminhou para frente (sem salto)
                if oldDist <= 900 then
                    goto continue
                end

                if movedFast and cameCloser and isClose then
                    -- S? ignora se aliado est? MUITO mais perto (>200 de diferen?a)
                    local iAmClosest = true
                    local allies = Heroes.GetAll()
                    for _, ally in pairs(allies) do
                        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then
                            local allyPos = Entity.GetAbsOrigin(ally)
                            local distToAlly = (currentPos - allyPos):Length()
                            -- S? ignora se aliado est? MUITO mais perto que eu
                            if distToAlly < 300 and distToAlly < distanceToMe - 200 then
                                iAmClosest = false
                                break
                            end
                        end
                    end

                    if iAmClosest then
                        local cooldown = 0.4
                        if not blinkCooldowns[enemyID] or (currentTime - blinkCooldowns[enemyID]) > cooldown then
                            blinkCooldowns[enemyID] = currentTime
                            return true
                        end
                    end
                end
            end
            ::continue::
        end
    end

    return false
end

local function DetectBlinkAbilities(myHero)

    local enemies = Heroes.GetAll()

    local currentTime = GameRules.GetGameTime()

    local myPos = Entity.GetAbsOrigin(myHero)

    

    -- Obter lista de skills habilitadas no menu

    local enabledEnemySkills = ui.enemy_skills_dodge:ListEnabled()

    local function IsEnemySkillEnabled(modName)

        for _, name in ipairs(enabledEnemySkills) do

            if name == modName then return true end

        end

        return false

    end

    

    -- Verifica se o modifier está em alguma das tabelas principais

    local function IsKnownDangerMod(modName)

        return instantBlinkMods[modName] or targetedBlinkMods[modName] or aggressiveMovementMods[modName] or fastDashMods[modName]

    end

    

    for _, enemy in pairs(enemies) do

        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

            local enemyID = Entity.GetIndex(enemy)
            if Entity.IsDormant(enemy) then
                goto continue_enemy_mod
            end

            local enemyPos = Entity.GetAbsOrigin(enemy)

            local distanceToMe = (enemyPos - myPos):Length()

            local data = enemyPositions[enemyID]
            local enemyMove = 0
            if data and data.prevPos then
                enemyMove = (enemyPos - data.prevPos):Length()
            end
            local myMove = lastMyMove or 0

            

            -- Se apenas eu me movi muito (meu blink) e o inimigo mal se moveu, ignora
            if myMove > 350 and enemyMove < 200 then
                local prevDist = data and data.prevDistToMe
                if prevDist and (prevDist - distanceToMe) > 300 then
                    goto continue_enemy_mod
                end
            end

            

            -- Verifica se está próximo

            if distanceToMe < 900 then

                -- Verifica se o inimigo acabou de aparecer perto (teleporte/blink instantâneo)

                local data = enemyPositions[enemyID]

                if data and data.prevDistToMe then

                    -- Se estava longe (>1000) e agora está perto (<700) = blink agressivo

                    if data.prevDistToMe > 1000 and distanceToMe < 700 then

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

                        

                        -- Só detecta se está habilitado no menu E é um modifier conhecido

                        if IsEnemySkillEnabled(modName) and IsKnownDangerMod(modName) then

                            if ShouldReactToMod(myHero, enemy, modName) then

                                -- Cooldown menor para Time Walk

                                local cooldown = (modName == "modifier_faceless_void_time_walk") and 0.3 or 1.0

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
        ::continue_enemy_mod::

    end

    

    return false

end



-- Função para detectar skills de initiation/start

-- Only triggers when enemy is genuinely moving towards you

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

                            -- Cooldown menor para skills rápidas

                            local cooldown = 1.5

                            if modName == "modifier_magnataur_skewer_movement" or modName == "modifier_slark_pounce" then

                                cooldown = 0.5

                            elseif modName == "modifier_faceless_void_time_walk" then

                                cooldown = 0.3  -- Time Walk é muito rápido

                            end

                            

                            -- ONLY trigger if enemy is genuinely coming towards me

                            -- This prevents false triggers when enemy uses skill to escape

                            if ShouldReactToMod(myHero, enemy, modName) then

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

    end

    return false

end



-- Função para detectar inimigos através de animações recentes

-- Only triggers when enemy is genuinely moving towards you

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

                    -- Get the modifier name from the animation data if available

                    local modName = data.modName or animationToModifier[data.animation] or nil

                    

                    -- ONLY trigger if enemy is genuinely moving towards me

                    if modName then

                        if ShouldReactToMod(myHero, enemy, modName) then

                            return true

                        end

                    else

                        -- No specific modifier mapped, check if moving towards me

                        if IsMovingTowardsMe(myHero, enemy) then

                            return true

                        end

                    end

                end

            end

        end

    end

    

    return false

end



-- Função para usar itens em aliados quando inimigo iniciar neles

local function UseItemsToSaveAlly(myHero, ally)

    if not myHero or not ally then return false end

    if IsAlreadyProtected(ally) then return false end

    

    local enabledItems = ui.allies_items:ListEnabled()

    local myPos = Entity.GetAbsOrigin(myHero)

    local allyPos = Entity.GetAbsOrigin(ally)

    local distToAlly = (allyPos - myPos):Length()

    

    -- Lista de itens para salvar aliados (em ordem de prioridade)

    local allyItems = {

        {name = "item_glimmer_cape", castType = "target", range = 550, priority = 1},

        {name = "item_lotus_orb", castType = "target", range = 900, priority = 2},

        {name = "item_wind_waker", castType = "target", range = 550, priority = 3},

        {name = "item_force_staff", castType = "target", range = 550, priority = 4},

        {name = "item_hurricane_pike", castType = "target", range = 550, priority = 5},

        {name = "item_ethereal_blade", castType = "target", range = 800, priority = 6},

        {name = "item_shadow_amulet", castType = "target", range = 600, priority = 7},

    }

    

    local function IsItemEnabled(itemName)

        for _, name in ipairs(enabledItems) do

            if name == itemName then return true end

        end

        return false

    end

    

    for _, itemData in ipairs(allyItems) do

        if IsItemEnabled(itemData.name) and distToAlly <= itemData.range then

            local item = IsItemAvailable(itemData.name, myHero)

            if item then

                Ability.CastTarget(item, ally)

                return true

            end

        end

    end

    

    return false

end



-- Função para detectar quando inimigo está iniciando em um aliado próximo

local function DetectEnemyInitiationOnAlly(myHero)

    if not myHero then return nil end

    if not ui.allies_support:Get() or not ui.save_ally_on_initiation:Get() then return nil end

    

    local myPos = Entity.GetAbsOrigin(myHero)

    local allies = Heroes.GetAll()

    local enemies = Heroes.GetAll()

    local enabledMods = ui.enemy_skills_dodge:ListEnabled()

    

    -- Função auxiliar para verificar se modifier está habilitado

    local function IsModEnabled(modName)

        for _, name in ipairs(enabledMods) do

            if name == modName then return true end

        end

        return false

    end

    

    -- Verificar cada aliado próximo

    for _, ally in pairs(allies) do

        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

            local allyPos = Entity.GetAbsOrigin(ally)

            local distToAlly = (allyPos - myPos):Length()

            

            -- Só verificar aliados próximos o suficiente para usar itens (max 1000)

            if distToAlly <= 1000 then

                -- Verificar cada inimigo

                for _, enemy in pairs(enemies) do

                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                        local modifiers = NPC.GetModifiers(enemy)

                        if modifiers then

                            for _, mod in pairs(modifiers) do

                                local modName = Modifier.GetName(mod)

                                if IsModEnabled(modName) then

                                    -- Verificar se inimigo está iniciando NO ALIADO (não em mim)

                                    if ShouldSaveAllyFromEnemy(ally, enemy, modName) then

                                        return ally

                                    end

                                end

                            end

                        end

                    end

                end

            end

        end

    end

    

    return nil

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

    local heroName = NPC.GetUnitName(myHero)

    

    local enabledSkills = ui.defensive_abilities:ListEnabled()

    local function IsSkillEnabled(skillName)

        for _, name in ipairs(enabledSkills) do

            if name == skillName then return true end

        end

        return false

    end

    

    -- Função auxiliar para encontrar inimigo mais próximo e calcular posição de escape

    local function GetEscapePosition(range)

        local allEnemies = Heroes.GetAll()

        local nearestEnemy = nil

        local minDist = 9999

        for _, enemy in pairs(allEnemies) do

            if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

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

        

        -- Fallback: se não achou inimigo, escapa na direção oposta ao facing

        local forward = Entity.GetRotation(myHero):GetForward()

        return myPos - forward * range

    end

    

    -- Mirana - Leap (vira para direção oposta ao inimigo ANTES de pular)

    if heroName == "npc_dota_hero_mirana" and IsSkillEnabled("mirana_leap") then

        local leap = NPC.GetAbility(myHero, "mirana_leap")

        if leap and Ability.IsCastable(leap, NPC.GetMana(myHero)) then

            -- Calcula direção de escape (oposta ao inimigo mais próximo)

            local escapePos = GetEscapePosition(800)

            if escapePos then

                -- Primeiro manda o herói andar na direção de escape (isso faz ele virar)

                Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                -- Marca pending para usar Leap no próximo frame

                miranaPending = {

                    active = true,

                    time = currentTime,

                    escapePos = escapePos

                }

                lastEscapeTime = currentTime

                return true

            end

        end

    end

    

    -- Slark - Pounce (vira para direção oposta ANTES de pular) ou Shadow Dance

    if heroName == "npc_dota_hero_slark" then

        if IsSkillEnabled("slark_pounce") then

            local pounce = NPC.GetAbility(myHero, "slark_pounce")

            if pounce and Ability.IsCastable(pounce, NPC.GetMana(myHero)) then

                -- Calcula direção de escape (oposta ao inimigo mais próximo)

                local escapePos = GetEscapePosition(700)

                if escapePos then

                    -- Primeiro manda o herói andar na direção de escape (isso faz ele virar)

                    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                    -- Marca pending para usar Pounce no próximo frame

                    slarkPending = {

                        active = true,

                        time = currentTime,

                        escapePos = escapePos

                    }

                    lastEscapeTime = currentTime

                    return true

                end

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

    

    -- Phoenix - Icarus Dive (precisa cancelar no ponto de destino senão volta)

    -- Colocado cedo na lista por ser prioritário

    if heroName == "npc_dota_hero_phoenix" and IsSkillEnabled("phoenix_icarus_dive") then

        local dive = NPC.GetAbility(myHero, "phoenix_icarus_dive")

        if dive and Ability.IsCastable(dive, NPC.GetMana(myHero)) then

            -- Calcula posição de escape

            local allEnemies = Heroes.GetAll()

            local nearestEnemy = nil

            local minDist = 9999

            for _, enemy in pairs(allEnemies) do

                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                    local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()

                    if dist < minDist then

                        minDist = dist

                        nearestEnemy = enemy

                    end

                end

            end

            

            local escapePos

            if nearestEnemy then

                local enemyPos = Entity.GetAbsOrigin(nearestEnemy)

                local escapeDir = (myPos - enemyPos):Normalized()

                escapePos = myPos + escapeDir * 1400

            else

                local forward = Entity.GetRotation(myHero):GetForward()

                escapePos = myPos - forward * 1400

            end

            

            Ability.CastPosition(dive, escapePos)

            -- Marca para cancelar o dive após delay (quando chegar no destino)

            phoenixDivePending = {

                active = true,

                time = currentTime,

                targetPos = escapePos

            }

            lastEscapeTime = currentTime

            return true

        end

    end

    

    -- Marci - Rebound (Escape usando aliados, creeps ou unidades controladas)

    -- Colocado cedo na lista por ser prioritário

    if heroName == "npc_dota_hero_marci" and IsSkillEnabled("marci_rebound") then

        local companionRun = NPC.GetAbility(myHero, "marci_companion_run")

        local rebound = NPC.GetAbility(myHero, "marci_rebound")

        local activeSkill = nil

        

        -- Determina qual skill usar (rebound ou companion_run)

        if rebound and not Ability.IsHidden(rebound) and Ability.IsCastable(rebound, NPC.GetMana(myHero)) then

            activeSkill = rebound

        elseif companionRun and not Ability.IsHidden(companionRun) and Ability.IsCastable(companionRun, NPC.GetMana(myHero)) then

            activeSkill = companionRun

        end

        

        if activeSkill then

            -- Encontra a unidade aliada mais próxima (heróis, creeps lane, unidades controladas)

            local bestTarget = nil

            local minDist = 700  -- Range do Rebound

            

            -- 1. Procura heróis aliados

            local allHeroes = Heroes.GetAll()

            for _, ally in pairs(allHeroes) do

                if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                    if not NPC.IsIllusion(ally) then

                        local dist = (Entity.GetAbsOrigin(ally) - myPos):Length()

                        if dist < minDist then

                            minDist = dist

                            bestTarget = ally

                        end

                    end

                end

            end

            

            -- 2. Procura creeps e unidades controladas

            local allNPCs = NPCs.GetAll()

            for _, npc in pairs(allNPCs) do

                if npc and Entity.IsAlive(npc) and Entity.IsSameTeam(myHero, npc) and npc ~= myHero then

                    local npcName = NPC.GetUnitName(npc) or ""

                    local isValidTarget = false

                    

                    -- Lane creeps (melee e ranged)

                    if string.find(npcName, "creep_goodguys") or string.find(npcName, "creep_badguys") then

                        isValidTarget = true

                    end

                    

                    -- Catapultas

                    if string.find(npcName, "siege") then

                        isValidTarget = true

                    end

                    

                    -- Unidades controladas (verifica se tem o mesmo controlador)

                    local npcOwner = Entity.GetOwner(npc)

                    local myOwner = Entity.GetOwner(myHero)

                    if npcOwner and myOwner and npcOwner == myOwner then

                        isValidTarget = true

                    end

                    

                    -- Unidades dominadas (Helm of Dominator)

                    if NPC.HasModifier(npc, "modifier_dominated") then

                        isValidTarget = true

                    end

                    

                    if isValidTarget then

                        local dist = (Entity.GetAbsOrigin(npc) - myPos):Length()

                        if dist < minDist then

                            minDist = dist

                            bestTarget = npc

                        end

                    end

                end

            end

            

            -- Se encontrou um alvo válido, usa o Rebound

            if bestTarget then

                -- Calcula a direção de escape (oposta ao inimigo mais próximo)

                local allEnemies = Heroes.GetAll()

                local nearestEnemy = nil

                local minEnemyDist = 9999

                for _, enemy in pairs(allEnemies) do

                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                        local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()

                        if dist < minEnemyDist then

                            minEnemyDist = dist

                            nearestEnemy = enemy

                        end

                    end

                end

                

                -- Calcula posição de escape (800 unidades na direção oposta ao inimigo)

                local escapePos

                local targetPos = Entity.GetAbsOrigin(bestTarget)

                if nearestEnemy then

                    local enemyPos = Entity.GetAbsOrigin(nearestEnemy)

                    local escapeDir = (myPos - enemyPos):Normalized()

                    escapePos = targetPos + escapeDir * 800

                else

                    -- Se não há inimigo, pula na direção oposta ao facing

                    local forward = Entity.GetRotation(myHero):GetForward()

                    escapePos = targetPos - forward * 800

                end

                

                -- Primeiro faz o cast no alvo

                Ability.CastTarget(activeSkill, bestTarget)

                

                -- Marca pendente para enviar a direção no próximo frame

                marciReboundPending = {

                    active = true,

                    time = currentTime,

                    escapePos = escapePos

                }

                

                lastEscapeTime = currentTime

                return true

            end

        end

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

    

    -- Earth Spirit - Rolling Boulder (coloca Stone Remnant antes de rolar para maior distância)
    if heroName == "npc_dota_hero_earth_spirit" and IsSkillEnabled("earth_spirit_rolling_boulder") then
        local rollingBoulder = NPC.GetAbility(myHero, "earth_spirit_rolling_boulder")
        local stoneRemnant = NPC.GetAbility(myHero, "earth_spirit_stone_caller")
        
        -- Verifica se Rolling Boulder está disponível ANTES de tentar qualquer coisa
        if rollingBoulder and Ability.IsCastable(rollingBoulder, NPC.GetMana(myHero)) then
            local escapePos = GetEscapePosition(800)
            if escapePos then
                -- Verifica se tem Stone Remnant disponível e mana para ambos
                local hasRemnant = false
                local canUseRemnant = false
                
                if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                    local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                    local myMana = NPC.GetMana(myHero)
                    local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                    local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rollingBoulder) or 0
                    
                    -- Só usa remnant se tiver charges E mana suficiente para AMBAS as skills
                    if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                        hasRemnant = true
                        canUseRemnant = true
                    end
                end
                
                if hasRemnant and canUseRemnant then
                    -- ESTRATÉGIA COM REMNANT: Coloca remnant à frente e rola por ele
                    local myPos = Entity.GetAbsOrigin(myHero)
                    local dirToEscape = (escapePos - myPos):Normalized()
                    local remnantPos = myPos + dirToEscape * 200
                    
                    Ability.CastPosition(stoneRemnant, remnantPos)
                    
                    -- Marca pending para usar Rolling Boulder após o remnant spawnar
                    earthSpiritPending = {
                        active = true,
                        time = currentTime,
                        escapePos = escapePos
                    }
                    
                    lastEscapeTime = currentTime
                    return true
                else
                    -- SEM REMNANT: Usa Rolling Boulder direto (menor distância, mas funciona)
                    Ability.CastPosition(rollingBoulder, escapePos)
                    lastEscapeTime = currentTime
                    return true
                end
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

    

    -- Tusk - Ice Shards

    if heroName == "npc_dota_hero_tusk" and IsSkillEnabled("tusk_ice_shards") then

        local iceShards = NPC.GetAbility(myHero, "tusk_ice_shards")

        if iceShards and Ability.IsCastable(iceShards, NPC.GetMana(myHero)) then

            local nearestEnemy = nil

            local minDist = 9999

            local allHeroes = Heroes.GetAll()

            for _, enemy in pairs(allHeroes) do

                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

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

    

    -- Clockwerk - Power Cogs ou Hookshot baseado no tipo de initiation

    -- Cogs: para skills de dash/movimento que BATEM na cog (Leap, Skewer, Pounce, Rolling Boulder, Zeus Jump)

    -- Hook: para blinks instantâneos que NÃO batem na cog (PA, Riki, AM, QoP, Blink Dagger, Time Walk, Storm)

    if heroName == "npc_dota_hero_rattletrap" then

        local cogs = NPC.GetAbility(myHero, "rattletrap_power_cogs")

        local hookshot = NPC.GetAbility(myHero, "rattletrap_hookshot")

        local cogsEnabled = IsSkillEnabled("rattletrap_power_cogs")

        local hookEnabled = IsSkillEnabled("rattletrap_hookshot")

        

        -- Skills de dash/movimento que BATEM na cog (são interrompidas)

        local cogInitiations = {

            ["modifier_mirana_leap"] = true,

            ["modifier_magnataur_skewer_movement"] = true,

            ["modifier_slark_pounce"] = true,

            ["modifier_earth_spirit_rolling_boulder_caster"] = true,

            ["modifier_zuus_heavenly_jump"] = true,

        }

        

        -- Skills de blink instantâneo que NÃO batem na cog (passam direto)

        local hookInitiations = {

            ["modifier_phantom_assassin_phantom_strike"] = true,

            ["modifier_riki_blink_strike"] = true,

            ["modifier_faceless_void_time_walk"] = true,

            ["modifier_antimage_blink"] = true,

            ["modifier_queenofpain_blink"] = true,

            ["modifier_item_blink_cooldown"] = true,

            ["modifier_storm_spirit_ball_lightning"] = true,

        }

        

        -- Verifica qual modifier triggou o escape

        local useCogs = false

        local useHook = false

        

        local allEnemies = Heroes.GetAll()

        for _, enemy in pairs(allEnemies) do

            if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                local modifiers = NPC.GetModifiers(enemy)

                if modifiers then

                    for _, mod in pairs(modifiers) do

                        local modName = Modifier.GetName(mod)

                        if cogInitiations[modName] then

                            useCogs = true

                            break

                        elseif hookInitiations[modName] then

                            useHook = true

                            break

                        end

                    end

                end

                if useCogs or useHook then break end

            end

        end

        

        -- Verifica se tem aliado para hook

        local farthestAlly = nil

        local maxAllyDist = 0

        local hookRange = 3000

        

        local allHeroes = Heroes.GetAll()

        for _, ally in pairs(allHeroes) do

            if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

                if not NPC.IsIllusion(ally) then

                    local dist = (Entity.GetAbsOrigin(ally) - myPos):Length()

                    if dist > maxAllyDist and dist <= hookRange then

                        maxAllyDist = dist

                        farthestAlly = ally

                    end

                end

            end

        end

        

        -- Se detectou skill que bate na cog, usa cogs

        if useCogs and cogsEnabled and cogs and Ability.IsCastable(cogs, NPC.GetMana(myHero)) then

            Ability.CastNoTarget(cogs)

            lastEscapeTime = currentTime

            return true

        end

        

        -- Se detectou skill que NÃO bate na cog, usa hook (se tiver aliado)

        if useHook and hookEnabled and hookshot and Ability.IsCastable(hookshot, NPC.GetMana(myHero)) then

            if farthestAlly then

                Ability.CastPosition(hookshot, Entity.GetAbsOrigin(farthestAlly))

                lastEscapeTime = currentTime

                return true

            else

                -- Não tem aliado para hook, usa cogs como fallback

                if cogsEnabled and cogs and Ability.IsCastable(cogs, NPC.GetMana(myHero)) then

                    Ability.CastNoTarget(cogs)

                    lastEscapeTime = currentTime

                    return true

                end

            end

        end

        

        -- Fallback genérico: tenta hook primeiro (se tiver aliado), senão cogs

        if hookEnabled and hookshot and Ability.IsCastable(hookshot, NPC.GetMana(myHero)) and farthestAlly then

            Ability.CastPosition(hookshot, Entity.GetAbsOrigin(farthestAlly))

            lastEscapeTime = currentTime

            return true

        end

        

        if cogsEnabled and cogs and Ability.IsCastable(cogs, NPC.GetMana(myHero)) then

            Ability.CastNoTarget(cogs)

            lastEscapeTime = currentTime

            return true

        end

    end

    

    -- Zeus - Heavenly Jump (vira para direção oposta ANTES de pular)

    if heroName == "npc_dota_hero_zuus" and IsSkillEnabled("zuus_heavenly_jump") then

        local jump = NPC.GetAbility(myHero, "zuus_heavenly_jump")

        if jump and Ability.IsCastable(jump, NPC.GetMana(myHero)) then

            local escapePos = GetEscapePosition(500)

            if escapePos then

                -- Primeiro manda o herói andar na direção de escape (isso faz ele virar)

                Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                -- Marca pending para usar Jump no próximo frame

                zeusPending = {

                    active = true,

                    time = currentTime,

                    escapePos = escapePos

                }

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

    

    -- Sniper - Concussive Grenade (joga BEM na frente dele, entre ele e o inimigo)

    if heroName == "npc_dota_hero_sniper" and IsSkillEnabled("sniper_concussive_grenade") then

        local grenade = NPC.GetAbility(myHero, "sniper_concussive_grenade")

        if grenade and Ability.IsCastable(grenade, NPC.GetMana(myHero)) then

            local nearestEnemy = nil

            local minDist = 9999

            local allHeroes = Heroes.GetAll()

            for _, enemy in pairs(allHeroes) do

                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                    local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()

                    if dist < minDist then

                        minDist = dist

                        nearestEnemy = enemy

                    end

                end

            end

            if nearestEnemy then

                -- Calcula ponto MUITO perto do Sniper (25 unidades na direção do inimigo)

                -- Isso empurra o inimigo pra LONGE do Sniper

                local enemyPos = Entity.GetAbsOrigin(nearestEnemy)

                local dirToEnemy = (enemyPos - myPos):Normalized()

                local grenadePos = myPos + dirToEnemy * 25  -- Praticamente nos pés dele

                Ability.CastPosition(grenade, grenadePos)

                lastEscapeTime = currentTime

                return true

            end

        end

    end

    

    -- Ember Spirit - Fire Remnant (ativa remnant existente ou cria um novo para fugir)

    if heroName == "npc_dota_hero_ember_spirit" and IsSkillEnabled("ember_spirit_fire_remnant") then

        local remnantSkill = NPC.GetAbility(myHero, "ember_spirit_fire_remnant")

        local activate = NPC.GetAbility(myHero, "ember_spirit_activate_fire_remnant")

        local myPos = Entity.GetAbsOrigin(myHero)

        

        -- Procura remnants existentes no mapa

        local bestRemnant = nil

        local maxDist = 0

        

        local npcs = NPCs.GetAll()

        for _, npc in pairs(npcs) do

            if npc and Entity.IsAlive(npc) and Entity.IsSameTeam(npc, myHero) then

                local npcName = NPC.GetUnitName(npc)

                if npcName == "npc_dota_ember_spirit_remnant" then

                    local remnantPos = Entity.GetAbsOrigin(npc)

                    local dist = (remnantPos - myPos):Length()

                    -- Só considera remnants que estão longe (>200)

                    if dist > 200 and dist > maxDist then

                        maxDist = dist

                        bestRemnant = npc

                    end

                end

            end

        end

        

        -- PRIORIDADE 1: Se tem remnant existente, ativa ele

        if bestRemnant and activate and Ability.IsCastable(activate, NPC.GetMana(myHero)) then

            local remnantPos = Entity.GetAbsOrigin(bestRemnant)

            Ability.CastPosition(activate, remnantPos)

            lastEscapeTime = currentTime

            return true

        end

        

        -- PRIORIDADE 2: Se não tem remnant mas pode criar, joga e ativa depois

        if not bestRemnant and remnantSkill and activate then

            local remnantCharges = Ability.GetCurrentCharges(remnantSkill)

            if remnantCharges and remnantCharges > 0 and Ability.IsCastable(remnantSkill, NPC.GetMana(myHero)) then

                -- Calcula posição de escape

                local escapePos

                local enemies = Heroes.GetAll()

                local nearestEnemy = nil

                local minDist = 9999

                for _, enemy in pairs(enemies) do

                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

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

                    escapePos = myPos + escapeDir * 1000

                else

                    local forward = Entity.GetRotation(myHero):GetForward()

                    escapePos = myPos - forward * 1000

                end

                

                -- Joga o remnant

                Ability.CastPosition(remnantSkill, escapePos)

                

                -- Marca pendente para ativar no próximo frame

                emberPendingRemnant.active = true

                emberPendingRemnant.pos = escapePos

                emberPendingRemnant.time = currentTime

                emberPendingRemnant.attempts = 0

                

                lastEscapeTime = currentTime

                return true

            end

        end

    end

    

    -- Crystal Maiden - Crystal Clone (precisa de direção)

    if heroName == "npc_dota_hero_crystal_maiden" and IsSkillEnabled("crystal_maiden_crystal_clone") then

        local clone = NPC.GetAbility(myHero, "crystal_maiden_crystal_clone")

        if clone and Ability.IsCastable(clone, NPC.GetMana(myHero)) then

            -- Encontra o inimigo mais próximo para calcular direção de fuga

            local myPos = Entity.GetAbsOrigin(myHero)

            local enemies = Heroes.GetAll()

            local nearestEnemy = nil

            local minDist = 9999

            for _, enemy in pairs(enemies) do

                if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                    local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()

                    if dist < minDist then

                        minDist = dist

                        nearestEnemy = enemy

                    end

                end

            end

            

            -- Calcula direção oposta ao inimigo (fuga)

            local escapePos

            if nearestEnemy then

                local enemyPos = Entity.GetAbsOrigin(nearestEnemy)

                local escapeDir = (myPos - enemyPos):Normalized()

                escapePos = myPos + escapeDir * 300

            else

                -- Se não há inimigo, usa a direção que o herói está olhando (inversa)

                local forward = Entity.GetRotation(myHero):GetForward()

                escapePos = myPos - forward * 300

            end

            

            Ability.CastPosition(clone, escapePos)

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



-- Função para verificar se um inimigo pode receber Eul's

local function CanUseEulsOnEnemy(enemy)

    if not enemy or not Entity.IsAlive(enemy) then

        return false

    end

    

    -- Já está em cyclone

    if NPC.HasModifier(enemy, "modifier_eul_cyclone") or NPC.HasModifier(enemy, "modifier_wind_waker_cyclone") then

        return false

    end

    

    -- Imunidade mágica (BKB, Rage, Repel, etc.)

    if NPC.IsMagicImmune and NPC.IsMagicImmune(enemy) then

        return false

    end

    

    -- Verificação adicional de modifiers de imunidade mágica e invulnerabilidade

    local immunityModifiers = {

        "modifier_black_king_bar_immune",

        "modifier_life_stealer_rage",

        "modifier_juggernaut_blade_fury",

        "modifier_omniknight_repel",

        "modifier_oracle_fates_edict",

        -- Invulneráveis / Não podem ser alvos

        "modifier_juggernaut_omnislash",           -- Omnislash - invulnerável, pulando entre alvos

        "modifier_juggernaut_omnislash_invulnerability",

        "modifier_phoenix_supernova_hiding",       -- Dentro do ovo

        "modifier_faceless_void_time_walk",        -- Durante Time Walk

        "modifier_puck_phase_shift",               -- Phase Shift

        "modifier_ember_spirit_sleight_of_fist_caster", -- Sleight of Fist

        "modifier_storm_spirit_ball_lightning",    -- Ball Lightning

        "modifier_slark_shadow_dance",             -- Shadow Dance (invisível, difícil acertar)

        "modifier_riki_tricks_of_the_trade_phase", -- Tricks of the Trade

    }

    for _, modName in ipairs(immunityModifiers) do

        if NPC.HasModifier(enemy, modName) then

            return false

        end

    end

    

    -- Linken's Sphere

    if NPC.IsLinkensProtected and NPC.IsLinkensProtected(enemy) then

        return false

    end

    if NPC.HasModifier(enemy, "modifier_item_sphere_target") then

        return false

    end

    

    -- Lotus Orb (reflexão) - não usar Eul's pois vai refletir em você

    if NPC.HasModifier(enemy, "modifier_item_lotus_orb_active") then

        return false

    end

    

    -- Legion Commander com Aghanim's Scepter (imune durante Duel)

    if NPC.GetUnitName(enemy) == "npc_dota_hero_legion_commander" then

        if NPC.HasModifier(enemy, "modifier_legion_commander_duel") then

            if NPC.HasScepter and NPC.HasScepter(enemy) then

                return false

            end

        end

    end

    

    return true

end



-- Skills que NÃO devem usar Eul's no inimigo (não canalizam ou não faz sentido interromper)

-- Essas skills aplicam o efeito instantaneamente, Eul's não cancela nada

local skillsNotWorthEuls = {

    "modifier_winter_wyvern_winters_curse",    -- WW não canaliza, curse já aplicado

    "modifier_necrolyte_reapers_scythe",       -- Necro não canaliza, dano vem no final

    "modifier_doom_bringer_doom",              -- Doom já aplicou, não canaliza

    "modifier_treant_overgrowth",              -- Treant não canaliza

    "modifier_windrunner_shackle_shot",        -- WR não canaliza, shackle já aplicado

    "modifier_juggernaut_omnislash",           -- Jugg invulnerável, não pode ser alvo

}



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

                                if CanUseEulsOnEnemy(enemy) then

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

                                if CanUseEulsOnEnemy(enemy) then

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

                                if CanUseEulsOnEnemy(enemy) then

                                    Ability.CastTarget(item, enemy)

                                    return true

                                end

                            end

                        end

                    end

                end

            end

            

            -- Se aliado tem Black Hole, procura Enigma próximo

            if modName == "modifier_enigma_black_hole_pull" then

                local enemies = Heroes.GetAll()

                for _, enemy in pairs(enemies) do

                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                        if NPC.GetUnitName(enemy) == "npc_dota_hero_enigma" then

                            local enemyPos = Entity.GetAbsOrigin(enemy)

                            local distanceToEnemy = (enemyPos - myPos):Length()

                            local distanceEnemyToAlly = (enemyPos - allyPos):Length()

                            

                            -- Enigma deve estar perto do aliado (range do Black Hole = 420 radius)

                            if distanceToEnemy <= castRange and distanceEnemyToAlly <= 600 then

                                if CanUseEulsOnEnemy(enemy) then

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

                                if CanUseEulsOnEnemy(enemy) then

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

                                if CanUseEulsOnEnemy(enemy) then

                                    Ability.CastTarget(item, enemy)

                                    return true

                                end

                            end

                        end

                    end

                end

            end

            

            -- NOTA: Não usamos Eul's em skills que não canalizam ou não faz sentido interromper:

            -- - Shackleshot (WR não canaliza, shackle já aplicado)

            -- - Winter's Curse (WW não canaliza, curse já aplicado)

            -- - Reaper's Scythe (Necro não canaliza, dano vem no final)

            -- - Doom (já aplicou, não canaliza)

            -- - Overgrowth (Treant não canaliza)

            -- - Omnislash (Jugg invulnerável, não pode ser alvo)

        end

    end

    

    -- MÉTODO 2: Verifica outras skills pelo modifier no inimigo (método antigo)

    -- Apenas para skills canalizadas que fazem sentido interromper

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

                        

                        -- Verifica se é uma skill que não vale a pena usar Eul's

                        local skipThisSkill = false

                        for _, notWorthSkill in ipairs(skillsNotWorthEuls) do

                            if modName == notWorthSkill then

                                skipThisSkill = true

                                break

                            end

                        end

                        

                        if not skipThisSkill then

                            for _, enabledSkill in ipairs(enabledEnemySkills) do

                                if modName == enabledSkill then

                                    local distanceEnemyToAlly = (enemyPos - allyPos):Length()

                                    

                                    if distanceEnemyToAlly <= 900 then

                                        if CanUseEulsOnEnemy(enemy) then

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

            local abilityEnemyRange = CONFIG.allies_abilities_range

            local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)

            local abilityMinEnemies = CONFIG.allies_abilities_count

            local abilityHPThreshold = CONFIG.allies_abilities_hp

            

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

        local abilityEnemyRange = CONFIG.allies_abilities_range

        local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)

        local abilityMinEnemies = CONFIG.allies_abilities_count

        local abilityHPThreshold = CONFIG.allies_abilities_hp

        

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

        

        local abilityEnemyRange = CONFIG.allies_abilities_range

        local abilityEnemyCount = CountEnemiesNearAlly(targetHero, abilityEnemyRange)

        local abilityMinEnemies = CONFIG.allies_abilities_count

        local abilityHPThreshold = CONFIG.allies_abilities_hp

        

        if allyHPPercent <= abilityHPThreshold and abilityEnemyCount >= abilityMinEnemies then

            local companionRun = NPC.GetAbility(myHero, "marci_companion_run")

            local rebound = NPC.GetAbility(myHero, "marci_rebound")

            local myMana = NPC.GetMana(myHero)

            local myPos = Entity.GetAbsOrigin(myHero)

            local allyPos = Entity.GetAbsOrigin(targetHero)

            local distance = (myPos - allyPos):Length()

            

            local activeSkill = nil

            

            -- Tenta usar companion_run primeiro

            if companionRun and not Ability.IsHidden(companionRun) and Ability.IsCastable(companionRun, myMana) and distance <= 1050 then

                activeSkill = companionRun

            -- Se não tiver companion_run, tenta rebound

            elseif rebound and not Ability.IsHidden(rebound) and Ability.IsCastable(rebound, myMana) and distance <= 1050 then

                activeSkill = rebound

            end

            

            if activeSkill then

                -- Calcula a direção de escape (do aliado para longe dos inimigos)

                local allEnemies = Heroes.GetAll()

                local nearestEnemy = nil

                local minEnemyDist = 9999

                for _, enemy in pairs(allEnemies) do

                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then

                        local dist = (Entity.GetAbsOrigin(enemy) - allyPos):Length()

                        if dist < minEnemyDist then

                            minEnemyDist = dist

                            nearestEnemy = enemy

                        end

                    end

                end

                

                -- Calcula posição de escape (longe do inimigo, a partir do aliado)

                local escapePos

                if nearestEnemy then

                    local enemyPos = Entity.GetAbsOrigin(nearestEnemy)

                    local escapeDir = (allyPos - enemyPos):Normalized()

                    escapePos = allyPos + escapeDir * 800

                else

                    -- Se não há inimigo, pula na direção da Marci para o aliado

                    local dirToAlly = (allyPos - myPos):Normalized()

                    escapePos = allyPos + dirToAlly * 800

                end

                

                -- Faz o cast no aliado

                Ability.CastTarget(activeSkill, targetHero)

                

                -- Marca pendente para enviar a direção no próximo frame

                marciReboundPending = {

                    active = true,

                    time = GameRules.GetGameTime(),

                    escapePos = escapePos

                }

                

                return true

            end

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



-- Helper: Verifica se há aliados próximos (para evitar fugir e deixá-los sozinhos)

local function HasNearbyAllies(myHero)

    if not ui.no_escape_near_allies:Get() then

        return false  -- Opção desabilitada, pode escapar normalmente

    end

    

    local range = ui.no_escape_ally_range:Get()

    local myPos = Entity.GetAbsOrigin(myHero)

    local allies = Heroes.GetAll()

    

    for _, ally in pairs(allies) do

        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then

            if not NPC.IsIllusion(ally) then

                local allyPos = Entity.GetAbsOrigin(ally)

                local dist = (allyPos - myPos):Length()

                if dist <= range then

                    return true  -- Há aliado próximo, não escapar

                end

            end

        end

    end

    

    return false  -- Sem aliados próximos, pode escapar

end

-- Blink Dagger (item) como escape prioritário antes das habilidades
local function TryBlinkItemEscape(myHero)
    if not ui.escape_item_blink or not ui.escape_item_blink:Get() then
        return false
    end

    local currentTime = GameRules.GetGameTime()
    if currentTime - lastEscapeTime < 0.2 then
        return false
    end

    local blink = NPC.GetItem(myHero, "item_blink", true)
    if not blink or not Ability.IsCastable(blink, NPC.GetMana(myHero)) then
        return false
    end

    local myPos = Entity.GetAbsOrigin(myHero)
    local enemies = Heroes.GetAll()
    local nearestEnemy = nil
    local minDist = 9999

    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length()
            if dist < minDist then
                minDist = dist
                nearestEnemy = enemy
            end
        end
    end

    local escapePos
    if nearestEnemy then
        local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
        local escapeDir = (myPos - enemyPos):Normalized()
        escapePos = myPos + escapeDir * 1200
    else
        local forward = Entity.GetRotation(myHero):GetForward()
        escapePos = myPos - forward * 1200
    end

    if escapePos then
        Ability.CastPosition(blink, escapePos)
        lastEscapeTime = currentTime
        return true
    end

    return false
end



-- Main dodger logic

function Dodger.OnUpdate()

    local myHero = Heroes.GetLocal()

    if not myHero or not Entity.IsAlive(myHero) or not ui.enabled:Get() then

        return

    end

    

    local currentTime = GameRules.GetGameTime()

    

    -- EMBER SPIRIT: Processa remnant pendente (ativa após jogar)

    if emberPendingRemnant.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_ember_spirit" then

            -- Timeout após 1.5 segundos (desiste)

            if currentTime >= emberPendingRemnant.time + 1.5 then

                emberPendingRemnant.active = false

            -- Começa a tentar após 0.1s (dá tempo do remnant spawnar), tenta a cada frame

            elseif currentTime >= emberPendingRemnant.time + 0.1 then

                local activate = NPC.GetAbility(myHero, "ember_spirit_activate_fire_remnant")

                if activate and Ability.IsCastable(activate, NPC.GetMana(myHero)) then

                    -- Procura o remnant que acabou de criar

                    local myPos = Entity.GetAbsOrigin(myHero)

                    local bestRemnant = nil

                    local maxDist = 0

                    

                    local npcs = NPCs.GetAll()

                    for _, npc in pairs(npcs) do

                        if npc and Entity.IsAlive(npc) and Entity.IsSameTeam(npc, myHero) then

                            local npcName = NPC.GetUnitName(npc)

                            if npcName == "npc_dota_ember_spirit_remnant" then

                                local remnantPos = Entity.GetAbsOrigin(npc)

                                local dist = (remnantPos - myPos):Length()

                                if dist > maxDist then

                                    maxDist = dist

                                    bestRemnant = npc

                                end

                            end

                        end

                    end

                    

                    if bestRemnant then

                        local remnantPos = Entity.GetAbsOrigin(bestRemnant)

                        Ability.CastPosition(activate, remnantPos)

                        emberPendingRemnant.active = false  -- Sucesso!

                    else

                        -- Ainda não encontrou, incrementa tentativas

                        emberPendingRemnant.attempts = emberPendingRemnant.attempts + 1

                    end

                else

                    -- Não pode ativar (sem mana ou em cooldown)

                    emberPendingRemnant.active = false

                end

            end

        else

            emberPendingRemnant.active = false

        end

    end

    

    -- PHOENIX: Cancela Icarus Dive quando chegar no ponto mais distante (senão volta pro lugar original)

    -- O dive é um arco que vai e volta - precisamos cancelar no ponto máximo

    if phoenixDivePending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_phoenix" then

            local elapsed = currentTime - phoenixDivePending.time

            -- Timeout após 3 segundos

            if elapsed >= 3.0 then

                phoenixDivePending.active = false

            -- Icarus Dive leva ~1.5s para chegar no ponto máximo, começar a verificar após 1.0s

            elseif elapsed >= 1.0 then

                local myPos = Entity.GetAbsOrigin(myHero)

                local distToTarget = (myPos - phoenixDivePending.targetPos):Length()

                

                -- Se está perto do destino (<400) ou passou tempo suficiente (1.5s), cancela o dive

                if distToTarget < 400 or elapsed >= 1.5 then

                    local diveStop = NPC.GetAbility(myHero, "phoenix_icarus_dive_stop")

                    if diveStop and Ability.IsCastable(diveStop, 0) then

                        Ability.CastNoTarget(diveStop)

                    end

                    phoenixDivePending.active = false

                end

            end

        else

            phoenixDivePending.active = false

        end

    end

    

    -- MARCI: Envia a direção do Rebound após o cast inicial

    if marciReboundPending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_marci" then

            local elapsed = currentTime - marciReboundPending.time

            -- Timeout após 0.5 segundos

            if elapsed >= 0.5 then

                marciReboundPending.active = false

            -- Envia a posição de direção após pequeno delay

            elseif elapsed >= 0.03 then

                Player.PrepareUnitOrders(

                    Players.GetLocal(),

                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,

                    nil,

                    marciReboundPending.escapePos,

                    nil,

                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,

                    myHero

                )

                marciReboundPending.active = false

            end

        else

            marciReboundPending.active = false

        end

    end


    -- EARTH SPIRIT: Usa Rolling Boulder apos colocar Stone Remnant
    if earthSpiritPending.active then
        local heroName = NPC.GetUnitName(myHero)
        if heroName == "npc_dota_hero_earth_spirit" then
            local elapsed = currentTime - earthSpiritPending.time
            -- Timeout apos 1.0 segundos (mais tempo para o remnant nascer)
            if elapsed >= 1.0 then
                earthSpiritPending.active = false
            -- Tenta a partir de 0.05s e segue tentando ate conseguir ou dar timeout
            elseif elapsed >= 0.05 then
                local rollingBoulder = NPC.GetAbility(myHero, "earth_spirit_rolling_boulder")
                if rollingBoulder and Ability.IsCastable(rollingBoulder, NPC.GetMana(myHero)) then
                    Ability.CastPosition(rollingBoulder, earthSpiritPending.escapePos)
                    earthSpiritPending.active = false -- Desativa somente apos usar
                end
                -- Fallback: se nao conseguiu em 0.5s, desativa para nao travar
                if elapsed >= 0.5 then
                    earthSpiritPending.active = false
                end
            end
        else
            earthSpiritPending.active = false
        end
    end

    -- PUCK: Usa Phase Shift após lançar o Orb

    if puckOrbPending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_puck" then

            local elapsed = currentTime - puckOrbPending.time

            -- Timeout após 0.5 segundos

            if elapsed >= 0.5 then

                puckOrbPending.active = false

            -- Usa Phase Shift após pequeno delay (0.05s) para o Orb sair

            elseif elapsed >= 0.05 then

                local phaseShift = NPC.GetAbility(myHero, "puck_phase_shift")

                if phaseShift and Ability.IsCastable(phaseShift, 0) then

                    Ability.CastNoTarget(phaseShift)

                end

                puckOrbPending.active = false

            end

        else

            puckOrbPending.active = false

        end

    end

    

    -- MIRANA: Verifica ângulo e usa Leap quando estiver olhando na direção certa

    if miranaPending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_mirana" then

            local elapsed = currentTime - miranaPending.time

            -- Timeout após 0.5 segundos

            if elapsed >= 0.5 then

                miranaPending.active = false

            else

                -- Continua mandando andar na direção de escape

                if miranaPending.escapePos then

                    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, miranaPending.escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                end

                

                -- Verifica se o herói já está olhando na direção certa

                local myPos = Entity.GetAbsOrigin(myHero)

                local forward = Entity.GetRotation(myHero):GetForward()

                local toEscape = (miranaPending.escapePos - myPos):Normalized()

                local dot = forward.x * toEscape.x + forward.y * toEscape.y

                

                -- Se ângulo < ~45° (dot > 0.7), usa a skill

                if dot > 0.7 then

                    local leap = NPC.GetAbility(myHero, "mirana_leap")

                    if leap and Ability.IsCastable(leap, NPC.GetMana(myHero)) then

                        Ability.CastNoTarget(leap)

                    end

                    miranaPending.active = false

                end

            end

        else

            miranaPending.active = false

        end

    end

    

    -- SLARK: Verifica ângulo e usa Pounce quando estiver olhando na direção certa

    if slarkPending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_slark" then

            local elapsed = currentTime - slarkPending.time

            -- Timeout após 0.5 segundos

            if elapsed >= 0.5 then

                slarkPending.active = false

            else

                -- Continua mandando andar na direção de escape

                if slarkPending.escapePos then

                    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, slarkPending.escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                end

                

                -- Verifica se o herói já está olhando na direção certa

                local myPos = Entity.GetAbsOrigin(myHero)

                local forward = Entity.GetRotation(myHero):GetForward()

                local toEscape = (slarkPending.escapePos - myPos):Normalized()

                local dot = forward.x * toEscape.x + forward.y * toEscape.y

                

                -- Se ângulo < ~45° (dot > 0.7), usa a skill

                if dot > 0.7 then

                    local pounce = NPC.GetAbility(myHero, "slark_pounce")

                    if pounce and Ability.IsCastable(pounce, NPC.GetMana(myHero)) then

                        Ability.CastNoTarget(pounce)

                    end

                    slarkPending.active = false

                end

            end

        else

            slarkPending.active = false

        end

    end

    

    -- ZEUS: Verifica ângulo e usa Heavenly Jump quando estiver olhando na direção certa

    if zeusPending.active then

        local heroName = NPC.GetUnitName(myHero)

        if heroName == "npc_dota_hero_zuus" then

            local elapsed = currentTime - zeusPending.time

            -- Timeout após 0.5 segundos

            if elapsed >= 0.5 then

                zeusPending.active = false

            else

                -- Continua mandando andar na direção de escape

                if zeusPending.escapePos then

                    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, zeusPending.escapePos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)

                end

                

                -- Verifica se o herói já está olhando na direção certa

                local myPos = Entity.GetAbsOrigin(myHero)

                local forward = Entity.GetRotation(myHero):GetForward()

                local toEscape = (zeusPending.escapePos - myPos):Normalized()

                local dot = forward.x * toEscape.x + forward.y * toEscape.y

                

                -- Se ângulo < ~45° (dot > 0.7), usa a skill

                if dot > 0.7 then

                    local jump = NPC.GetAbility(myHero, "zuus_heavenly_jump")

                    if jump and Ability.IsCastable(jump, NPC.GetMana(myHero)) then

                        Ability.CastNoTarget(jump)

                    end

                    zeusPending.active = false

                end

            end

        else

            zeusPending.active = false

        end

    end

    

    -- IMPORTANTE: Atualizar posições dos inimigos PRIMEIRO (antes de qualquer detecção)

    UpdateEnemyPositions(myHero)

    

    -- Verificar se deve bloquear escape por ter aliados próximos

    local blockEscape = HasNearbyAllies(myHero)

    

    -- Verifica se a opção Anti-Blink está ativada e detecta blinks

    if ui.blink_dodge:Get() and (DetectEnemyBlink(myHero) or DetectBlinkAbilities(myHero)) then

        if not blockEscape then

            if not TryBlinkItemEscape(myHero) and not UseEscapeAbilities(myHero) then

                UseDefensiveItems(myHero)

            end

        end

    end

    

    -- Verifica se a opção Anti-Start está ativada e detecta skills de initiation

    if ui.start_dodge:Get() then

        -- Primeiro verifica animações (mais rápido), depois modifiers

        local animDetected = DetectEnemyAnimations(myHero)

        local modDetected = DetectStartAbilities(myHero)

        

        if animDetected or modDetected then

            if not blockEscape then

                if not TryBlinkItemEscape(myHero) and not UseEscapeAbilities(myHero) then

                    UseDefensiveItems(myHero)

                end

            end

        end

    end

    

    -- Verifica se a opção Death Ward está ativada e detecta Death Ward

    if ui.deathward_dodge:Get() and IsTargetedByDeathWard(myHero) then

        if not blockEscape then

            UseDefensiveItems(myHero)

        end

    end

    

    -- Detectar quando inimigo está iniciando em aliado próximo (PA blink, etc)

    if ui.allies_support:Get() and ui.save_ally_on_initiation:Get() then

        local allyInDanger = DetectEnemyInitiationOnAlly(myHero)

        if allyInDanger then

            UseItemsToSaveAlly(myHero, allyInDanger)

        end

    end

    

    -- Lógica para suporte a aliados (CCs e debuffs)

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

                    if allyHPPercent <= CONFIG.allies_abilities_hp or allyHPPercent <= CONFIG.allies_items_hp then

                        -- Verifica se tem inimigos próximos

                        local enemyCount = CountEnemiesNearAlly(ally, math.max(CONFIG.allies_abilities_range, CONFIG.allies_items_range))

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

            animationDetected[enemyID] = {time = currentTime, modName = detectedModifier, animation = animName}

        end

    end

end



return Dodger

