local autofarm = {}

-- timers 

local protobuf = require('protobuf')
local JSON = require('assets.JSON')


--------
-- gui cache
local font = Render.LoadFont("Radiance",  Enum.FontCreate.FONTFLAG_ANTIALIAS, Enum.FontWeight.BOLD)
local map_img = Render.LoadImage('~/AutoFarm/menu4.jpg')

--local map_img = Render.LoadImage("panorama/images/textures/minimap_game_png.vtex_c")

local iconMenu = Render.LoadImage('~/MenuIcons/coins.png')

local my_ico_4 = Render.LoadImage("~/MenuIcons/target_alt.png")

local autoupgrade = require("modules/autoupgrade")
local autosearch = require("modules/autosearch")
-- menu 
local mainMenu = Menu.Create("Creeps", "Main")
local mainTab = mainMenu:Create("Auto Farm")
local mainSection = mainTab:Create("Main")
--autosearch --autosearch --autosearch --autosearch --autosearch --autosearch --autosearch --autosearch --autosearch --autosearch 
local autoSearchSelection = mainTab:Create("Auto Search Game")
local autoSearchTab = autoSearchSelection:Create("Auto Search")
autosearch.ui_init(autoSearchTab)

function autofarm.OnGCMessage( msg )
    if msg.binary_buffer_send then
        if msg.msg_type == 7033  then
            startgame_msg = JSON:decode(protobuf.decodeToJSON("CMsgStartFindingMatch", msg.binary_buffer_send, msg.size))
            autosearch.gcmessace(startgame_msg)
        end
    end
    
end

function autofarm.OnGameEnd()
    autosearch.OnGameEnd()
end 

function autofarm.OnFrame()
    autosearch.OnFrame()
end
----------------------------------------- auto search -   -- - - -----autosearch --autosearch --autosearch --autosearch --autosearch --autosearch --autosearch 
--dbg sections 
local debugSection = mainTab:Create("debug")
local debugTab = debugSection:Create("Debug")
local anothertask = debugTab:Switch("anothertask", false)

local callfarmproc = debugTab:Button("Call Farm Proc", function(this)
    autofarm.farming_proc_dbg()
end)
-- ----- 
local menuTab = mainSection:Create("Menu")
local switcher = menuTab:Switch("Script", false)
local until_end = menuTab:Switch("repeat", false)
local switch_CameraLock = menuTab:Switch("cameralock", false)
local switcher_autoupgrade = menuTab:Switch("autoupgrade", false)
local gui_swticher = menuTab:Switch("GUI", false)

local bind_ui = menuTab:Bind("UI", Enum.ButtonCode.BUTTON_CODE_INVALID)
--local minimap_scale = menuTab:Slider("Minimap Scale", 0.5, 1.5, 1.0, function(v) return string.format("%.2f", v) end)

local laneTab = mainSection:Create("Lane")
local farm_lane = laneTab:Switch("lane", false)
local lane_search_distance = laneTab:Slider("Lane Search Distance", 500, 3000, 2500, function(v) return string.format("%.0f", v) end)

-- -- Ally settings
-- local ally_avoid = laneTab:Switch("Avoid Lane if Ally Present", false)
-- local ally_distance = laneTab:Slider("Ally Check Distance", 500, 1500, 800, function(v) return string.format("%.0f", v) end)


-- -- Enemy settings  
-- local enemy_distance = laneTab:Slider("Enemy Danger Distance", 500, 2000, 1000, function(v) return string.format("%.0f", v) end)


-- cache 
local last_update_time = 0 

local base_vector = nil
local hero = nil
local my_ico = nil

local particle = nil
local particle_target = nil
local ui_state = false
autofarm.LastUpdateTime = 0
autofarm.LastSpellUse = 0

-- 123

local currentSegmentIndex = 1    
local offik = 0                
local step = 5                 
autofarm.LastUpdateTime = 0
autofarm.targetPosition = nil      
autofarm.lastEndPoint = nil       
autofarm.currentPath = nil         
autofarm.initialized = false       

local blink_abilities = {
    "antimage_blink",
    "queenofpain_blink",
    "phantom_assassin_phantom_strike",
    "faceless_void_time_walk",
    "morphling_waveform"
}



local abilities_notarget = {
    "necrolyte_death_pulse", 
    "bristleback_quill_spray",
    "doom_bringer_scorched_earth",
    "earthshaker_enchant_totem",
    "legion_commander_overwhelming_odds",
    "shredder_whirling_death",
    "tidehunter_anchor_smash",
    "ember_spirit_flame_guard",
    "gyrocopter_flak_cannon",
    "razor_plasma_field",
    "slark_dark_pact",
    "templar_assassin_refraction",
    "queenofpain_scream_of_pain",
    "mirana_starfall",
    "sandking_sand_storm",
    "alchemist_chemical_rage",
    "slardar_slithereen_crush",
    "sven_warcry", 
    "arc_warden_magnetic_field", 
    "batrider_firefly"

}

local abilities_target = {
    "phantom_assassin_stifling_dagger",
    "phantom_assassin_phantom_strike",
    "centaur_double_edge",
    "doom_bringer_devour",
    "doom_bringer_infernal_blade",
    "clinkz_death_pact",
    "ogre_magi_ignite",
    "morphling_adaptive_strike_agi",
    "medusa_mystic_snake",




}

local abilities_position = {
    "alchemist_acid_spray",
    "morphling_waveform",
    "arc_warden_spark_wraith"

}

-- spells with unique logic for list--------------------------------
local abilities_unique_logic = {
    "skeleton_king_bone_guard",


}
-- functions for unique logic
local ability_functions = {
    ["skeleton_king_bone_guard"] = function()
        autofarm.skeleton_king_bone_guard()
    end,
    --- add new abilities 
}

local function castAbility(abilityName)
    abilityName = Ability.GetName(abilityName)
    local func = ability_functions[abilityName]
    if func then
        func()
    else
        print("not found")
    end
end
-- unique logic for abilities


function autofarm.skeleton_king_bone_guard()
    print("Skeleton King Bone Guard logic executed")
    local hero = Heroes.GetLocal()
    if not hero then return end
    local ability = NPC.GetAbility(hero, "skeleton_king_bone_guard")
    if not ability or not Ability.IsCastable(ability, NPC.GetMana(hero)) then return end
    local max_charges =  Ability.GetLevelSpecialValueFor(ability, "max_skeleton_charges")
    local modifier = NPC.GetModifier(hero, "modifier_skeleton_king_bone_guard")
    if Modifier.GetStackCount(modifier) == max_charges then
        Ability.CastNoTarget(ability)
    end

end 
-- ----------------------------------------------------------


local items_notarget = {
    "item_mask_of_madness",
    "item_manta",
    "item_blade_mail",
    "item_shivas_guard",
    "item_boots_of_bearing",
    "item_veil_of_discord"

}
local items_target ={
    "item_dagon",
    "item_dagon_2",
    "item_dagon_3",
    "item_dagon_4",
    "item_dagon_5",
}

local hero_abilities = {} 


local blink_items = {
    "item_blink",
    "item_overwhelming_blink", 
    "item_swift_blink",
    "item_arcane_blink"
}



local gui = {
    main_x1 = 300,
    main_y1 = 100,
    main_x2 = 1600,
    main_y2 = 1000,

    rect_x1 = 780,
    rect_y1 = 160,
    rect_x2 = 1080,
    rect_y2 = 230

}

local autofarm_data = {
    active_camps = {},
    farm_status = false,
    total_camps = 0,
    current_camp = 0,
    road_to_camp = false,
    farming = false,
    another_task = false,
    status = "IDLE",
    escaping = false,
    escape_target = nil,


    going_base = false, 
}

local camps_gui = {
}
local camp_states = {}


-- math 

function autofarm.getVectorCamp(camp)
    if #autofarm_data.active_camps == 0 then
        return nil
    end

    local first_camp_key = autofarm_data.active_camps[camp]
    local first_camp = camps_gui[first_camp_key]

    if first_camp and first_camp.camp_ingame then
        return first_camp.camp_ingame
    else
        return nil
    end
end


function autofarm.getCanFarm(camp)
    if #autofarm_data.active_camps == 0 then
        return nil
    end

    local first_camp_key = autofarm_data.active_camps[camp]
    local first_camp = camps_gui[first_camp_key]

    if first_camp and first_camp.can_farm then
        return first_camp.can_farm
    else
        return nil
    end
end



function autofarm.isHere_player(pos1, pos2, threshold)
    return math.abs(pos1.x - pos2.x) <= threshold and
           math.abs(pos1.y - pos2.y) <= threshold 
end



function  autofarm.OnPrepareUnitOrders( data )
--    print( data )
end
--- orders  


function autofarm.moveToCamp(vector)



    autofarm_data.road_to_camp = true
    particle_target = vector


    if ((os.clock() - autofarm.LastSpellUse) < 0.133) then return end
    autofarm.LastSpellUse = os.clock()

    local hero = Heroes.GetLocal()
    if not hero then return end

    step = NPC.GetMoveSpeed(hero) / 200
    -- disable humanizer
    if autofarm.targetPosition then
       -- NPC.MoveTo(hero, autofarm.targetPosition, false, false)
    end
    NPC.MoveTo(hero, vector, false, false)
    if NPC.HasItem(hero, "item_phase_boots") then 
        local phase_boots = NPC.GetItem(hero, "item_phase_boots")
        if Ability.IsCastable(phase_boots, NPC.GetMana(hero)) then
            Ability.CastNoTarget(phase_boots)
        end
    end


    local blink, blink_distance  = autofarm.getBlink() 
    if blink ~= nil then 

        if (Ability.GetBehavior(blink) & Enum.AbilityBehavior.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) ~= 0 then
            local target = autofarm.getTargetNear(vector, 600)
            
            if target ~= nil then 
                Ability.CastTarget(blink, target, false ,true)
                Ability.CastPosition(blink, target_point, false, true)


                
                -- TODO 
                -- TODO: after blink this logic behaves incorrectly (already in camp)
            end
        else 
            -- max range cast 
            local hero_position = Entity.GetAbsOrigin(hero)
            local direction_vector = (vector - hero_position):Normalized()
            local target_point = hero_position + direction_vector * blink_distance
    
            if (vector - hero_position):Length2D() <= blink_distance then
                target_point = vector
            end
    
            local trees = Trees.InRadius(target_point, 300, true)
    
            if #trees > 4 and next(trees) then
                print("trees detected")
    
                return 
            end
    
            Ability.CastPosition(blink, target_point, false ,true)
            
        end
    
    end
end    


function autofarm.castfarm_no_target()
    if hero == nil or #hero_abilities.hero_abilities_notarget == 0 then return end
    print(hero_abilities.hero_abilities_notarget)
    for _, ability in ipairs(hero_abilities.hero_abilities_notarget) do
        if Ability.IsCastable(ability, NPC.GetMana(hero)) then
            Ability.CastNoTarget(ability)
        end
    end
end

function autofarm.castfarm_target(npc)
    if hero == nil or #hero_abilities.hero_abilities_target == 0 then return end
    
    for _, ability in ipairs(hero_abilities.hero_abilities_target) do
        if Ability.IsCastable(ability, NPC.GetMana(hero)) then
            Ability.CastTarget(ability, npc)
        end
    end
end

function autofarm.castfarm_position(npc)
    if hero == nil or #hero_abilities.hero_abilities_position == 0 then return end
    
    for _, ability in ipairs(hero_abilities.hero_abilities_position) do
        if Ability.IsCastable(ability, NPC.GetMana(hero)) then
            Ability.CastPosition(ability, Entity.GetAbsOrigin(npc))
        end
    end
end

function autofarm.castfarm_unique()
    if hero == nil or #hero_abilities.hero_abilities_unique == 0 then return end
    
    for _, ability in ipairs(hero_abilities.hero_abilities_unique) do
        if Ability.IsCastable(ability, NPC.GetMana(hero)) then
            castAbility(ability)

        end
    end
end
----- get 
---






function autofarm.initializeHeroAbilities()
    if hero == nil then return end
    print("INIT skills")

    hero_abilities = {
        hero_abilities_notarget = {}, 
        hero_abilities_target = {},  
        hero_abilities_position = {},     
        hero_abilities_toggle = {},
        hero_abilities_unique = {}

    } 

    --- 
    for _, ability in ipairs(abilities_notarget) do
        if NPC.HasAbility(hero, ability) then
            table.insert(hero_abilities.hero_abilities_notarget, NPC.GetAbility(hero, ability))

        end
    end


    for _, ability in ipairs(abilities_target) do
        if NPC.HasAbility(hero, ability) then
            table.insert(hero_abilities.hero_abilities_target, NPC.GetAbility(hero, ability))

        end
    end

    for _, ability in ipairs(abilities_position) do
        if NPC.HasAbility(hero, ability) then
            table.insert(hero_abilities.hero_abilities_position, NPC.GetAbility(hero, ability))

        end
    end
    -- add to hero abilities unique abilities 

    for _, ability in ipairs(abilities_unique_logic) do
        if NPC.HasAbility(hero, ability) then
            table.insert(hero_abilities.hero_abilities_unique, NPC.GetAbility(hero, ability))

        end
    end

    

end

function autofarm.getCreepsAround(radius, vector)
    local creeps = {} 
    local hero = Heroes.GetLocal()

    if (hero == nil) then
        return creeps 
    end

    local heroVector = Entity.GetAbsOrigin(hero)
    local teamNum = Entity.GetTeamNum(hero) 
    local npcsInRadius = NPCs.InRadius(vector, radius, teamNum, Enum.TeamType.TEAM_ENEMY)

    for id, npc in pairs(npcsInRadius) do
        if NPC.IsCreep(npc) and not NPC.IsLaneCreep(npc) then
            creeps[id] = npc
        end
    end

    return creeps
end

function autofarm.getBlink()
    if hero == nil then return end 

    for _, ability in ipairs(blink_abilities) do
        if NPC.HasAbility(hero, ability) then
            local blink =  NPC.GetAbility(hero, ability) 
            if Ability.IsCastable(blink, NPC.GetMana(hero)) then 
                local blink_distance = Ability.GetLevelSpecialValueFor(blink, "AbilityCastRange")
                if blink_distance < 1 then 
                    blink_distance = 1200
                end 
                print(blink_distance)

                return blink, blink_distance
            end
        end
    end

    for _, ability in ipairs(blink_items) do
        if NPC.HasItem(hero, ability) then
            local blink =  NPC.GetItem(hero, ability) 
            if Ability.IsCastable(blink, NPC.GetMana(hero)) then 
                local blink_distance = Ability.GetLevelSpecialValueFor(blink, "blink_range")
                return blink, blink_distance
            end
        end
    end

    return nil
end


function autofarm.getTarget(radius)

    local creeps = NPCs.InRadius(Entity.GetAbsOrigin(hero), radius, Entity.GetTeamNum(hero) , Enum.TeamType.TEAM_ENEMY)
    for i, npc in ipairs(creeps) do
        print(NPC.GetUnitName(npc))
        if NPC.IsCreep(npc) then
            return npc
        end
    end
    return nil 
end


function autofarm.getTargetNear(vector, radius)

    local creeps = NPCs.InRadius(vector, radius, Entity.GetTeamNum(hero) , Enum.TeamType.TEAM_ENEMY)
    for i, npc in ipairs(creeps) do
        print(NPC.GetUnitName(npc))
        if NPC.IsCreep(npc) then
            return npc
        end
    end
    return nil
end
--- farm creeps logic 

function autofarm.farming_proc()
    local npc  = autofarm.getTarget(800)


    
    -- attack 
    Player.AttackTarget(Players.GetLocal(),hero, npc)
    
    particle_target = Entity.GetAbsOrigin(npc)
    --  cast farm speels no pos
    
    autofarm.castfarm_no_target()
    autofarm.castfarm_target(npc)
    autofarm.castfarm_position(npc)
    autofarm.castfarm_unique()
    autofarm.cast_items(hero, npc)

end

function autofarm.farming_proc_dbg()

    autofarm.castfarm_unique()
end

function autofarm.cast_items(hero, npc)
    autofarm.autoMidas(hero)
    for _, ability in ipairs(items_notarget) do
        if NPC.HasItem(hero, ability) then
            local item = NPC.GetItem(hero, ability, true)
            if Ability.IsCastable(item, NPC.GetMana(hero)) then Ability.CastNoTarget(item) end

        end
    end
    
      for _, ability in ipairs(items_target) do
        if NPC.HasItem(hero, ability) then
            local item = NPC.GetItem(hero, ability, true)
            if Ability.IsCastable(item, NPC.GetMana(hero)) then Ability.CastTarget(item, npc) end

        end
    end
end

function autofarm.farmfinish()
    
    autofarm_data.escaping = false
    autofarm_data.escape_target = nil
    autofarm_data.another_task = false

    if until_end:Get() then 
        autofarm_data.current_camp = 1 
        
        

        autofarm_data.farming = false 
        autofarm_data.road_to_camp = false 
        print("Farm finished, restarting")
    else 
        autofarm_data.farm_status = false
        autofarm_data.farming = false 
        autofarm_data.road_to_camp = false 
        autofarm.clear_active_camps( )
        particle_target = nil
        Engine.PlayVol("sounds/npc/courier/courier_acknowledge.vsnd_c", 0.1);

        -- 4to eto?
        --[[ 
        autofarm.update_active_camps_with_creeps()
        if #autofarm_data.active_camps > 0 then
            autofarm_data.current_camp = 1
            autofarm_data.farm_status = true
            autofarm_data.total_camps = #autofarm_data.active_camps
            autofarm_data.status = "Restarting farm with new camps"
        end
        ]]
    end 
end
-- ploho rabotayet
function autofarm.move_out_of_camp(camp_pos)
    local hero = Heroes.GetLocal() 
    if not hero then return end

    local game_time = GameRules.GetGameTime()
    local ingame_timer = game_time - GameRules.GetGameStartTime()
    local seconds = ingame_timer % 60
    if seconds >= 56 and seconds <= 58 then
        local hero_pos = Entity.GetAbsOrigin(hero)
        if not camp_pos then return end
        autofarm_data.another_task = true
        local move_out_pos = camp_pos + (hero_pos - camp_pos):Normalized() * 800

        Player.PrepareUnitOrders(Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            move_out_pos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
            hero)
    else 
        autofarm_data.another_task = false
    end
end


function autofarm.autoMidas(hero)
    local item = NPC.GetItem(hero, "item_hand_of_midas", true)
    if not item or not Ability.IsCastable(item, 0) then return end

    local range = Ability.GetCastRange(item) 
    local creeps = NPCs.InRadius(Entity.GetAbsOrigin(hero), range, Entity.GetTeamNum(hero), Enum.TeamType.TEAM_ENEMY)
    for i, npc in ipairs(creeps) do
        if NPC.IsCreep(npc) and not NPC.IsAncient(npc) then
            Ability.CastTarget(item, npc)
            return
        end
    end
end


function autofarm.OnGameRulesStateChange()
    
    
end
--- main logic 
function autofarm.OnUpdate()
    if ((os.clock() - autofarm.LastUpdateTime) < 0.133) then return end
    autofarm.LastUpdateTime = os.clock()

    if not switcher:Get( ) then return end 
    if not hero then return end
    if Entity.IsAlive(hero) == false then return end


--and Engine.GetLevelNameShort == "start"
    if not next( camps_gui )   then 
        print("autofarm")
        print(Engine.GetLevelNameShort())

        autofarm.init_camps_dynamic()
    else 
        autofarm.camps_creeps()
    end

    -- autofarm.move_out_of_camp(autofarm.getVectorCamp(autofarm_data.current_camp))  --------- needs debugging

    -- auto upgrade skill points 
    -- by builds in dota 




    if not autofarm_data.farm_status == true then return end 


    if autofarm.farm_lane() then return end

    if switcher_autoupgrade:Get() then
        autoupgrade.CallAutoUpgrade()
    end
    -- 4to eto? 
    --- ????????????
    --[[
    if not autofarm_data.camp_attempts then
        autofarm_data.camp_attempts = {}
    end
    local camp_id = autofarm_data.current_camp
    if not autofarm_data.camp_attempts[camp_id] then
        autofarm_data.camp_attempts[camp_id] = 0
    end
    ]]
    autofarm_data.another_task = anothertask:Get() 
    -- Move between camps
    local cur_hp = Entity.GetHealth(hero)
    local max_hp = Entity.GetMaxHealth(hero)
    if cur_hp < max_hp * 0.3 and not autofarm_data.another_task then
        autofarm_data.another_task = true
        autofarm_data.status = "Low health, go base"
        autofarm_data.going_base = true
        autofarm.moveToCamp(base_vector)
    end


    if autofarm_data.going_base then 
        print("going base")
        if NPC.HasModifier(hero, "modifier_fountain_aura_buff") and Entity.GetHealth(hero) == Entity.GetMaxHealth(hero) then 
            print("GOOD")
            if NPC.HasItem(hero, "item_tpscroll", false) then
                print("TP")
                local tp_item = NPC.GetItem(hero, "item_tpscroll", false)
                if Ability.IsCastable(tp_item, NPC.GetMana(hero)) then
                    Ability.CastPosition(tp_item, autofarm.getVectorCamp(autofarm_data.current_camp))
                end
            else 
                print("no tp")
            end 
            autofarm_data.going_base = false
            autofarm_data.another_task = false
        end  
    end 

    if autofarm_data.current_camp <= autofarm_data.total_camps then 
       

        local camp_vector = autofarm.getVectorCamp(autofarm_data.current_camp)
        local hero_pos = Entity.GetAbsOrigin(hero)
        local distance_to_camp = (hero_pos - camp_vector):Length2D()
        
        local creeps = autofarm.getCreepsAround(800, camp_vector)
        --[[
        local camp_key = autofarm_data.active_camps[autofarm_data.current_camp]
        local camp_state = nil
        for id, camp in pairs(camp_states) do
            if camps_gui[camp_key] and camp.position and (camps_gui[camp_key].camp_ingame - camp.position):Length2D() < 10 then
                camp_state = camp
                break
            end
        end

        ]]
        if distance_to_camp <= NPC.GetAttackRange(hero) and creeps and next(creeps) and autofarm_data.road_to_camp == true and not autofarm_data.another_task then
            print("close to camp, found creeps, start farming")
            autofarm_data.road_to_camp = false
            autofarm_data.farming = true
            autofarm.farming_proc() 
            autofarm_data.status = "Farming camp #" .. autofarm_data.current_camp
        -- think
        --[[
        elseif distance_to_camp <= 200 and creeps and not next(creeps) and autofarm_data.road_to_camp == true and not autofarm_data.another_task then
            print("camp is empty on arrival")
            autofarm_data.road_to_camp = false
            if camp_state and camp_state.farmed then
                autofarm_data.status = "Camp not farmed, waiting or retrying"
                return
            end
            if autofarm_data.current_camp == autofarm_data.total_camps then 
                print("last camp is empty, moving away")
                autofarm.moveAwayFromCamp(camp_vector)
                autofarm.farmfinish()
                -- Do not finish farming immediately, wait for exact minute
                
            else
                print("empty camp, moving to next")
                autofarm_data.current_camp = autofarm_data.current_camp + 1 
                autofarm_data.farming = false 
                autofarm_data.road_to_camp = false 
            end
            ]]

        elseif creeps and next(creeps) and autofarm_data.farming == true and not autofarm_data.another_task  then
            print("procces")         
            autofarm.farming_proc() 
            autofarm_data.status = "Farming camp #" .. autofarm_data.current_camp
        elseif creeps and not next(creeps) and autofarm_data.farming == true then
            print("next")

            if autofarm_data.current_camp == autofarm_data.total_camps then 
                print("last camp cleared, moving away before finish")
                autofarm.moveAwayFromCamp(camp_vector)

                autofarm.farmfinish()
            else
                autofarm_data.current_camp =  autofarm_data.current_camp + 1 

                autofarm_data.farming = false 
                autofarm_data.road_to_camp = false 
            end 
        end

        if autofarm.isHere_player(hero_pos, camp_vector, 100) and autofarm_data.road_to_camp == true and not autofarm_data.another_task then
            print("here at camp point")
            autofarm_data.road_to_camp = false
            autofarm_data.farming = true
        end

        if autofarm_data.farming == false and not autofarm_data.another_task and not autofarm_data.going_base then 
            print("move")
            autofarm_data.status = "Move to camp #" .. autofarm_data.current_camp
            --[[
            if distance_to_camp < 500 then
                autofarm_data.camp_attempts[camp_id] = autofarm_data.camp_attempts[camp_id] + 1
                if autofarm_data.camp_attempts[camp_id] > 10 then
                    print("Camp unreachable, skipping")
                    autofarm_data.current_camp = autofarm_data.current_camp + 1
                    autofarm_data.farming = false
                    autofarm_data.road_to_camp = false
                    autofarm_data.camp_attempts[camp_id] = nil
                    return
                end
            else
                autofarm_data.camp_attempts[camp_id] = 0
            end
            ]]
            if autofarm.getCanFarm(autofarm_data.current_camp) then 
                autofarm.moveToCamp(camp_vector)
            else 
                autofarm_data.farming = false 
                autofarm_data.road_to_camp = false 
                autofarm_data.data = "Skip camp"
                autofarm_data.current_camp =  autofarm_data.current_camp + 1 
                if autofarm_data.current_camp == autofarm_data.total_camps then 

                    print("finish")
                    autofarm.farmfinish()
                    return

                end 
            end
        end

    end

   -- print(autofarm_data.active_camps)


end

function autofarm.OnPrepareUnitOrders( data )
end

----  init --- 
function autofarm.OnScriptsLoaded()
    hero = Heroes.GetLocal()
    if hero == nil then return end 
    my_ico = Render.LoadImage('panorama/images/heroes/icons/' .. Entity.GetUnitName(hero) .. '_png.vtex_c')
    
    autofarm.initializeHeroAbilities()
    --autofarm.init_camps()




    if Entity.GetTeamNum(hero) == 3 then
        base_vector = Vector(6956.06, 6353.44, 392.0)
    elseif Entity.GetTeamNum(hero) == 2 then
        base_vector = Vector(-6911.23, -6389.58, 384.0)
    else
        print("Unknown team numberr")
    end 

end 


--------------------------------------- GUI -------------------------------------

-- camps -- 

-- Camp initialization
function autofarm.init_camps()
    local camps = Camps.GetAll()
    for id, npc in pairs(camps) do
        camp_states[id] = {
            position = Entity.GetAbsOrigin(npc), 
            creep_count = nil,                 
            farmed = false, -- new field
        }
    end
end

local function find_closest_camp(position, camps)
    local closest_id = nil
    local closest_distance = math.huge 
    for id, camp_data in pairs(camps) do
        local distance = (position - camp_data.position):Length2D() 
        if distance < closest_distance then
            closest_distance = distance
            closest_id = id
        end
    end
    return closest_id
end

local function spotPos(spot)
    if spot.pos then return spot.pos end
    local c = (spot.box.min + spot.box.max) * 0.5
    return Vector(c.x, c.y, c.z)
end

local function worldToMinimap(vector)
    local x_world, y_world = vector.x, vector.y
    local x_pixel = (x_world + 9024) * 800 / (9024 + 8896)
    local y_pixel = (8896 - y_world) * 800 / (8896 + 8896)

    x_pixel = math.max(0, math.min(800, x_pixel))
    y_pixel = math.max(0, math.min(800, y_pixel))

    return Vec2(gui.main_x1 - 10 + x_pixel, gui.main_y1 + 50 + y_pixel)
end

function autofarm.camps_creeps()
    if not (LIB_HEROES_DATA and LIB_HEROES_DATA.jungle_spots) then return end

    for _, spot in ipairs(LIB_HEROES_DATA.jungle_spots) do
        local idx = spot.index
        local gui   = camps_gui[idx]
        local state = camp_states[idx]

        if gui and state then
            gui.can_farm       = not spot.farmed
            state.creep_count  = #spot.alive_creeps
            state.farmed       = not spot.farmed
        end
    end
end

function autofarm.init_camps_dynamic()

    if not (LIB_HEROES_DATA and LIB_HEROES_DATA.jungle_spots) then
        print("LIB_HEROES_DATA or jungle_spots not found, skipping dynamic camp init")
        return
    end

    print("initializing dynamic camps...")
    for i, spot in ipairs(LIB_HEROES_DATA.jungle_spots) do
        local worldPos   = spot.pos          
        local minimapPos = worldToMinimap(worldPos)

        local camp_name
        if spot.team == 3 then
            camp_name = "dire_camp_" .. spot.index
        elseif spot.team ==2 then
            camp_name = "radiant_camp_" .. spot.index
        end
        camps_gui[spot.index] = {
            camp_id     = spot.index,
            camp_name   = camp_name,
            pos_x       = minimapPos.x,
            pos_y       = minimapPos.y,
            vector      = minimapPos,
            camp_ingame = worldPos,
            can_farm    = not spot.farmed,
            spot_data   = spot,
        }

        camp_states[spot.index] = {
            position    = worldPos,
            creep_count = #spot.alive_creeps,
            farmed      = spot.farmed ,
        }
    end

    print("Initialized " .. #LIB_HEROES_DATA.jungle_spots .. " camps ")
end

-- Update camp positions when scale changes

function autofarm.update_camp_positions()
    for camp_name, camp_data in pairs(camps_gui) do
        if camp_data.spot_data and camp_data.camp_ingame then
            local newMinimapPos = worldToMinimap(camp_data.camp_ingame)
            camp_data.pos_x = newMinimapPos.x
            camp_data.pos_y = newMinimapPos.y
            camp_data.vector = newMinimapPos
        end
    end
end
--[[

function autofarm.camps_update()
    autofarm.update_camp_positions()
    
    for camp_name, camp_data in pairs(camps_gui) do
        if camp_data.spot_data then

            local closest_id = find_closest_camp(camp_data.camp_ingame, camp_states)
            if closest_id then
                camp_data.creep_count = camp_states[closest_id].creep_count
                camp_data.can_farm = camp_states[closest_id].creep_count and camp_states[closest_id].creep_count > 0
            else
                camp_data.creep_count = 0
                camp_data.can_farm = false
            end
        end
    end

end
]]
  --  main_x1 = 300,
 --   main_y1 = 100,


----------- render additional ----------------
---- humanaizer ------------ OFF
function autofarm.render_path_move()
    local hero = Heroes.GetLocal()
    if not hero then return end
    if not autofarm_data.farm_status == true then return end 
    local startPos = Entity.GetAbsOrigin(hero)
    local currentEndPos = autofarm.getVectorCamp(autofarm_data.current_camp)
    
    -- Add nil check for currentEndPos
    if not currentEndPos then return end
    
    local overallDistance = (currentEndPos - startPos):Length2D()

    if overallDistance < 450 then
        autofarm.currentPath = nil
        autofarm.targetPosition = currentEndPos
        local tpos, vis = Render.WorldToScreen(currentEndPos)
        if vis then
            Render.Circle(tpos, 5, Color(0, 255, 0, 255))
        end
        return
    end

    if not autofarm.currentPath then
        local ignoreTrees = false
        local npc_map = GridNav.CreateNpcMap({hero})
        autofarm.currentPath = GridNav.BuildPath(startPos, currentEndPos, ignoreTrees, npc_map)
        GridNav.ReleaseNpcMap(npc_map)

        autofarm.lastEndPoint = currentEndPos
        currentSegmentIndex = 1
        offik = 0
        autofarm.initialized = false
    else
       
        local distanceFromLast = (autofarm.lastEndPoint - currentEndPos):Length2D()
        if currentSegmentIndex >= #autofarm.currentPath then
            if distanceFromLast > 50 then
                local ignoreTrees = false
                local npc_map = GridNav.CreateNpcMap({hero}, not ignoreTrees)
                local heroPos = Entity.GetAbsOrigin(hero)
                autofarm.currentPath = GridNav.BuildPath(heroPos, currentEndPos, ignoreTrees, npc_map)
                GridNav.ReleaseNpcMap(npc_map)

                autofarm.lastEndPoint = currentEndPos
                currentSegmentIndex = 1
                offik = 0
                autofarm.initialized = false
            end
        else
            if distanceFromLast > 50 then
                local ignoreTrees = false
                local npc_map = GridNav.CreateNpcMap({hero}, not ignoreTrees)
                local heroPos = Entity.GetAbsOrigin(hero)
                autofarm.currentPath = GridNav.BuildPath(heroPos, currentEndPos, ignoreTrees, npc_map)
                GridNav.ReleaseNpcMap(npc_map)

                autofarm.lastEndPoint = currentEndPos
                currentSegmentIndex = 1
                offik = 0
                autofarm.initialized = false
            end
        end
    end

    if not autofarm.currentPath or #autofarm.currentPath < 2 then
        return
    end

   
    if not autofarm.initialized then
        autofarm.initialized = true
        local segStart = autofarm.currentPath[1]
        local segEnd   = autofarm.currentPath[2]
        local segVector = segEnd - segStart
        local segLength = segVector:Length2D()
        offik = math.min(500, segLength)
    end

    if currentSegmentIndex < #autofarm.currentPath then
        local segStart = autofarm.currentPath[currentSegmentIndex]
        local segEnd   = autofarm.currentPath[currentSegmentIndex + 1]

        local segVector    = segEnd - segStart
        local segLength    = segVector:Length2D()
        local segDirection = segVector:Normalized()

        if offik < segLength then
            offik = offik + step
        else
            offik = 0
            currentSegmentIndex = currentSegmentIndex + 1
            if currentSegmentIndex >= #autofarm.currentPath then
                currentSegmentIndex = #autofarm.currentPath
            end
        end

        local new_position = segStart + segDirection * math.min(offik, segLength)

        ------------------------------------------------------------------------
        local heroPos = Entity.GetAbsOrigin(hero)
        local circleDist = (new_position - heroPos):Length2D()
        local minLead = 450  

        while circleDist < minLead and offik < segLength do
            offik = offik + step
            new_position = segStart + segDirection * math.min(offik, segLength)
            circleDist = (new_position - heroPos):Length2D()
        end
        ------------------------------------------------------------------------

        autofarm.targetPosition = new_position

        local screenPos, vis = Render.WorldToScreen(new_position)
        if vis then
            Render.Circle(screenPos, 5, Color(0, 255, 0, 255))
        end
    end

    local prev_screen_pos = nil
    for _, pos in ipairs(autofarm.currentPath) do
        local screen_pos, vis = Render.WorldToScreen(pos)
        if prev_screen_pos and vis then
            Render.Line(prev_screen_pos, screen_pos, Color(255, 0, 0, 150))
        end
        prev_screen_pos = screen_pos
    end
end


function autofarm.render_camps()
    autofarm.update_camp_positions()
    for camp_name, camp_data in pairs(camps_gui) do
        local x, y = camp_data.pos_x, camp_data.pos_y
        local rect_width, rect_height = 40, 30

        if y + rect_height > gui.main_y1 + 850 then
            y = gui.main_y1 + 850 - rect_height
        end
        if x < gui.main_x1 - 10 then
            x = gui.main_x1 - 10
        end

        local x2 = math.min(x + rect_width, gui.main_x1 + 820)
        local y2 = y + rect_height

        Render.FilledRect(
            Vec2(x, y),
            Vec2(x2, y2),
            Color(0, 0, 0, 175),
            5
        )

        rect_height = 5
        y2 = math.min(y + rect_height, gui.main_y1 + 850)
        Render.FilledRect(
            Vec2(x, y),
            Vec2(x2, y2),
            camp_data.farming and Color(0, 255, 0, 200) or Color(255, 0, 0, 200),
            5
        )

        --[[
        local circle_x = x
        local circle_y = y
        if circle_x < gui.main_x1 - 10 then
            circle_x = gui.main_x1 - 10 + 10 
        end
        if circle_y + 10 > gui.main_y1 + 850 then
            circle_y = gui.main_y1 + 850 - 10 
        end
        Render.FilledCircle(
            Vec2(circle_x, circle_y),
            10,
            camp_data.farming and Color(0, 255, 0, 150) or Color(255, 0, 0, 150)
        )
        ]]
    end
end

function autofarm.render_path()
    if #autofarm_data.active_camps < 2 then return end 

    for i = 1, #autofarm_data.active_camps - 1 do
        local camp1 = autofarm_data.active_camps[i]
        local camp2 = autofarm_data.active_camps[i + 1]

        local camp1_center_x = camps_gui[camp1].pos_x + 20
        local camp1_center_y = camps_gui[camp1].pos_y + 15
        local camp2_center_x = camps_gui[camp2].pos_x + 20
        local camp2_center_y = camps_gui[camp2].pos_y + 15

        local dx = camp2_center_x - camp1_center_x
        local dy = camp2_center_y - camp1_center_y


        local start_vector = autofarm.get_intersection(camp1_center_x, camp1_center_y, dx, dy, camps_gui[camp1].pos_x, camps_gui[camp1].pos_y, 40, 30)
        local end_vector = autofarm.get_intersection(camp2_center_x, camp2_center_y, -dx, -dy, camps_gui[camp2].pos_x, camps_gui[camp2].pos_y, 40, 30)

        Render.Line(start_vector, end_vector, Color(0, 255, 0, 150), 3)
        
    end
end


-- farm gui render 

function autofarm.ingame_gui()
    if not gui_swticher:Get() then return end
    if not autofarm_data.farm_status then return end

    Render.Blur(Vec2(gui.rect_x1, gui.rect_y1), Vec2(gui.rect_x2, gui.rect_y2),5,1)
    Render.Shadow(Vec2(gui.rect_x1, gui.rect_y1), Vec2(gui.rect_x2, gui.rect_y2), Color(255), 50, 5)

    blur_anim = 255
    r,g,b  = Menu.Style("main_background"):Unpack()

    Render.FilledRect(Vec2(gui.rect_x1, gui.rect_y1), Vec2(gui.rect_x2, gui.rect_y2), Color(r, g, b, blur_anim), 5)

    local r_text,g_text,b_text  = Menu.Style("primary_first_tab_text"):Unpack()

    Render.Image(my_ico, Vec2(gui.rect_x1 + 5, gui.rect_y1 + 30), Render.ImageSize(my_ico), Color(255,255,255,blur_anim))

    Render.Text(font, 18, "AutoFarm: " .. autofarm_data.status, Vec2(gui.rect_x1 + 40, gui.rect_y1 + 30), Color(r_text,g_text,b_text,blur_anim))
    r,g,b  = Menu.Style("primary_second_tab_text"):Unpack()
    
    Render.Image(my_ico_4, Vec2(gui.rect_x1+3, gui.rect_y1 + 3), Vec2(15,15), Color(255,0,0,blur_anim))
    Render.Text(font, 12, "AutoFarm GUI", Vec2(gui.rect_x1 + 23, gui.rect_y1 + 3), Color(r,g,b,blur_anim))
    r,g,b  = Menu.Style("separator"):Unpack()
    
    Render.Line(Vec2(gui.rect_x1, gui.rect_y1+20), Vec2(gui.rect_x1+300, gui.rect_y1+20), Color(r,g,b,blur_anim))

end

---- logic 

function autofarm.dragging() 
    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
        local cursor_x, cursor_y = Input.GetCursorPos()


        if not is_dragging and Input.IsCursorInRect(gui.main_x1, gui.main_y1, gui.main_x2 - gui.main_x1, gui.main_y2 - gui.main_y1) and not Input.IsCursorInRect(gui.main_x1 + 30, gui.main_y1+50,800,800 ) then

            is_dragging = true
            drag_offset_x = cursor_x - gui.main_x1
            drag_offset_y = cursor_y - gui.main_y1
        end

        if is_dragging then
            local width = gui.main_x2 - gui.main_x1
            local height = gui.main_y2 - gui.main_y1
            gui.main_x1 = cursor_x - drag_offset_x
            gui.main_y1 = cursor_y - drag_offset_y
            gui.main_x2 = gui.main_x1 + width
            gui.main_y2 = gui.main_y1 + height
        end

    else
        is_dragging = false
    end


end

function autofarm.get_intersection(cx, cy, dx, dy, rect_x, rect_y, rect_w, rect_h)
    local t_min = math.huge
    local ix, iy

    local t1 = (rect_x - cx) / dx
    local y1 = cy + t1 * dy
    if t1 >= 0 and y1 >= rect_y and y1 <= rect_y + rect_h then
        t_min = t1
        ix, iy = rect_x, y1
    end

    local t2 = ((rect_x + rect_w) - cx) / dx
    local y2 = cy + t2 * dy
    if t2 >= 0 and y2 >= rect_y and y2 <= rect_y + rect_h and t2 < t_min then
        t_min = t2
        ix, iy = rect_x + rect_w, y2
    end

    local t3 = (rect_y - cy) / dy
    local x3 = cx + t3 * dx
    if t3 >= 0 and x3 >= rect_x and x3 <= rect_x + rect_w and t3 < t_min then
        t_min = t3
        ix, iy = x3, rect_y
    end

    local t4 = ((rect_y + rect_h) - cy) / dy
    local x4 = cx + t4 * dx
    if t4 >= 0 and x4 >= rect_x and x4 <= rect_x + rect_w and t4 < t_min then
        t_min = t4
        ix, iy = x4, rect_y + rect_h
    end

    return Vec2(ix, iy)
end


function autofarm.clear_active_camps()
    for _, camp_name in pairs(autofarm_data.active_camps) do
        camps_gui[camp_name].farming = false
    end
    autofarm_data.active_camps = {}
end


-- keys events for gui --  

function autofarm.OnKeyEvent(key_event)
    if not switcher:Get() then return end
    if bind_ui:IsPressed() then
        ui_state = not ui_state
    end


    if not ui_state then return end

    if Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
        for camp_name, camp_data in pairs(camps_gui) do
            if Input.IsCursorInRect(camp_data.pos_x, camp_data.pos_y, 40, 30) then
                camps_gui[camp_name].farming = not camp_data.farming
                print(camp_name .. " farming status is now: " .. tostring(camps_gui[camp_name].farming))

                if camps_gui[camp_name].farming then
                    table.insert(autofarm_data.active_camps, camp_name)
                else
                    for i, name in ipairs(autofarm_data.active_camps) do
                        if name == camp_name then
                            table.remove(autofarm_data.active_camps, i)
                            break
                        end
                    end
                end

                return false
            end
        end
    end


    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) and Input.IsCursorInRect(gui.main_x1 + 1000, gui.main_y1 + 800, 250, 50) then 
        until_end:Set(false)
        autofarm.farmfinish()
        return false
    end 

    if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) and Input.IsCursorInRect(gui.main_x1 + 1000, gui.main_y1 + 740, 250, 50) then 
        if #autofarm_data.active_camps > 0 and hero ~= nil then 
            autofarm_data.current_camp = 1 
            autofarm_data.farm_status = true
            autofarm_data.total_camps = #autofarm_data.active_camps
            print(#autofarm_data.active_camps)
            Notification {
                id = "farm",
                duration = 3,
                timer = 3,
                hero = Entity.GetUnitName(hero),
                primary_text = "Farm",
                -- primary_image = Render.LoadImage("panorama/images/spellicons/invoker_sun_strike_png.vtex_c"),
                secondary_text = "\aDEFAULTFarm \a00FF00255 start",
                -- active = false,
                position = Vector(1, 0, 0),
                sound = "sounds/ui/yoink"
              }

              

        end
        return false
    end 



    
    if key_event.key == 314 and Input.IsCursorInRect(gui.main_x1, gui.main_y1, gui.main_x2 - gui.main_x1, gui.main_y2 - gui.main_y1) then
        return false
    end

    return true
end



-- main render 
function autofarm.debug_render()
    for _, camp in pairs(camps_gui) do
        local screenPos, visible = Render.WorldToScreen(camp.camp_ingame)
        if visible then
            local camp_id = camp.camp_id
            local name = camp.camp_name
            local state = camp_states[camp_id]

            local creep_count = state and state.creep_count or 0
            local farmed = state and state.farmed or false

            local color = (creep_count > 0 or farmed)
                          and Color(0, 255, 0, 255)
                          or Color(255, 60, 60, 255)
            local offsetY = screenPos.y

            Render.Text(font, 18, name, Vec2(screenPos.x, offsetY), Color())
            offsetY = offsetY - 12

            Render.Text(font, 18, "farmed: " .. tostring(state.farmed), Vec2(screenPos.x, offsetY), color)
            offsetY = offsetY + 24

            Render.Text(font, 18, "alive: " .. tostring(creep_count), Vec2(screenPos.x, offsetY), color)
            offsetY = offsetY + 24

            if camp.farming then
                Render.Text(font, 18, "shouldFarm", Vec2(screenPos.x, offsetY), Color(0, 255, 0, 255))
            end
        end
    end
end



function autofarm.OnDraw()


    if not switcher:Get() then return end
    autofarm.render_path_move()

   -- autofarm.debug_render()
    autofarm.ingame_gui()
   
    if switch_CameraLock:Get() and autofarm_data.farm_status then
        local abs = Entity.GetAbsOrigin(Heroes.GetLocal())
        Engine.LookAt(abs.x, abs.y)
    end 

    if particle_target ~= nil then 
        if not particle then 
            particle = Particle.Create("materials/ensage_ui/particles/target.vpcf", Enum.ParticleAttachment.PATTACH_POINT_FOLLOW)
            Particle.SetControlPoint(particle, 5, Vector(150, 160, 255)) 
            Particle.SetControlPoint(particle, 6, Vector(1,0,0))
        end
        Particle.SetControlPoint(particle, 2, Entity.GetAbsOrigin(hero)) 
        Particle.SetControlPoint(particle, 7, particle_target) 
    else
        Particle.Destroy(particle)
        particle = nil

    end


    --- menu 
    if not ui_state then return end 
    autofarm.dragging()

    local x,y = Input.GetCursorPos()

    Render.Blur(Vec2(gui.main_x1 ,gui.main_y1), Vec2(gui.main_x2,gui.main_y2), 1, 5)

    Render.FilledRect(Vec2(gui.main_x1,gui.main_y1), Vec2(gui.main_x2,gui.main_y2), Color(0,0,0, 100), 5)


    
    Render.Image(map_img, Vec2(gui.main_x1 + 30, gui.main_y1+50), Vec2(800,800), Color() )
    Render.Text(font, 18, "AutoFarm Menu", Vec2(gui.main_x1 + 68, gui.main_y1 + 20), Color(255,255,255))

    Render.Text(font, 18, "X: "..x, Vec2(x+50, y), Color(255, 255, 255))
    Render.Text(font, 18, "Y: "..y, Vec2(x + 100, y), Color(255, 255, 255))
    
    -- Display current minimap scale
    local current_scale = 1;
   --Render.Text(font, 14, "Minimap Scale X: " .. string.format("%.2f", current_scale * 1.1) .. " Y: " .. string.format("%.2f", current_scale), Vec2(gui.main_x1 + 850, gui.main_y1 + 20), Color(255, 255, 100))

    autofarm.render_camps()
    autofarm.render_path()

    Render.FilledRect(Vec2(gui.main_x1 + 1000, gui.main_y1 + 800), Vec2(gui.main_x1 + 1250, gui.main_y1 + 850), Color(144,0,0, 150), 10)

    Render.FilledRect(Vec2(gui.main_x1 + 1000, gui.main_y1 + 740), Vec2(gui.main_x1 + 1250, gui.main_y1 + 790), Color(0,255,0, 150), 10)


    Render.Text(font, 24 , "Clear", Vec2(gui.main_x1 + 1075, gui.main_y1 + 805), Color())
    Render.Text(font, 24 , "Start", Vec2(gui.main_x1 + 1075, gui.main_y1 + 745), Color())
    Render.Image(iconMenu, Vec2(gui.main_x1+30, gui.main_y1+15), Vec2(30,30), Color()) 
   -- Render.FilledRect(Vec2(gui.main_x1+30, gui.main_y1+10), Vec2(gui.main_x1 + 35, gui.main_y1 + 30), Color(255,0,0, 150), 5)


end
--#region


--[[
function autofarm.OnDraw()
    for id, camp in pairs(camp_states) do
        local screenPos, isVisible = Render.WorldToScreen(camp.position)

        if isVisible then
            local text = (camp.creep_count and camp.creep_count > 0) and "FARM" or "NOT FARM"
            local color = (camp.creep_count and camp.creep_count > 0) and Color(0, 255, 0) or Color(255, 0, 0)
            Render.Text(font, 18, text.. " "..camp.creep_count.. "case ".. camp.case, Vec2(screenPos.x, screenPos.y), color)
        end
    end
end
]]



autofarm.timer_1 = 0 
function autofarm.stack_camp(camp_pos)
    local game_time = GameRules.GetGameTime()
    local ingame_timer = game_time - GameRules.GetGameStartTime()
    local seconds = ingame_timer % 60

    if seconds >= 53 and seconds <= 55 then
        local hero = Heroes.GetLocal() 
        if not hero then return end

        if not camp_pos then return end

        local stack_pos = camp_pos + (camp_pos - Entity.GetAbsOrigin(hero)):Normalized() * 800

        local creeps = {}
        for _, npc in pairs(NPCs.GetAll(Enum.UnitTypeFlags.TYPE_CREEP)) do
            if IsNPCInCamp(npc, camp) then
                table.insert(creeps, npc)
            end
        end
        autofarm_data.status = "Stack"
        if #creeps > 0 then
            Player.AttackTarget(Players.GetLocal(), hero, creeps[1]) 
            
            
            Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION, 
                nil, stack_pos, nil, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY, hero)
        end
    end
end



function autofarm.farm_lane()
    if autofarm_data.escaping then return false end
    
    if farm_lane:Get() then
        local hero_pos = Entity.GetAbsOrigin(hero)
        local search_distance = lane_search_distance:Get()
        
      
        
        local creeps = NPCs.InRadius(hero_pos, search_distance, Entity.GetTeamNum(hero), Enum.TeamType.TEAM_ENEMY)
        
        local closest_creep = nil
        local closest_distance = math.huge 

        for i, npc in ipairs(creeps) do
            if NPC.IsLaneCreep(npc) then
                local creep_pos = Entity.GetAbsOrigin(npc)
                local distance = (hero_pos - creep_pos):Length2D()
                
                local dangerous_enemy_found = false
                

                
                if not dangerous_enemy_found and distance < closest_distance then
                    closest_distance = distance
                    closest_creep = npc
                end
            end
        end

        if closest_creep then
            local vec, is = Render.WorldToScreen(Entity.GetAbsOrigin(closest_creep))
            Render.Text(font, 18, "Closest creep", vec, Color())
            Player.AttackTarget(Players.GetLocal(), hero, closest_creep)
            autofarm_data.another_task = true
            particle_target = Entity.GetAbsOrigin(closest_creep)
            autofarm_data.status = "Farm lane creeps"

            autofarm.castfarm_no_target()
            autofarm.castfarm_target(closest_creep)
            autofarm.castfarm_position(closest_creep)
            return true
        else
            autofarm_data.another_task = false
            local any_creeps = false
            for i, npc in ipairs(creeps) do
                if NPC.IsLaneCreep(npc) then
                    any_creeps = true
                    break
                end
            end
            if any_creeps then
                autofarm_data.status = "Lane creeps found but enemies nearby"
            end
        end
    end
    return false
end


-- logic creep counter 
-- old logic 
--[[ 
function autofarm.camps_creeps()
    local game_time = GameRules.GetGameTime()
    local ingame_timer = game_time - GameRules.GetGameStartTime()

    if math.floor(ingame_timer / 60) > last_update_time then
        print("MINUTA")
        last_update_time = math.floor(ingame_timer / 60)  
        for id, camp in pairs(camp_states) do
            if camp.creep_count == nil or camp.creep_count == 0 then
                camp.creep_count = 1
            end
            camp.farmed = false -- reset farming state
        end
    end



    for id, camp in pairs(camp_states) do
        local creeps = NPCs.InRadius(camp.position, 500, Entity.GetTeamNum(hero), Enum.TeamType.TEAM_ENEMY)
        if next(creeps) == nil and camp.creep_count ~= 0 then 

        elseif next(creeps) and camp.creep_count == nil then 
            local actual_count = 0
            for _, creep in ipairs(creeps) do
                if NPC.IsCreep(creep) then
                    actual_count = actual_count + 1
                end
            end
            camp.creep_count = actual_count
        

        elseif next(creeps) ~= nil and camp.creep_count ~= nil then 
            local actual_count = 0
            for _, creep in ipairs(creeps) do
                if NPC.IsCreep(creep) then
                    actual_count = actual_count + 1
                end
            end
            if actual_count >= camp.creep_count then 
                camp.creep_count = actual_count

            end
        else 
        end
    end
end

-- logic creep counter 
function autofarm.OnNpcDying(npc)
    if not NPC.IsCreep(npc) then return end

    local npc_position = Entity.GetAbsOrigin(npc)
    for id, camp in pairs(camp_states) do
        if (npc_position - camp.position):Length2D() <= 800 then
            if camp.creep_count ~= nil then
                camp.creep_count = camp.creep_count - 1

                if camp.creep_count == 0 then
                    camp.last_cleared_time = GameRules.GetGameTime()
                end
            end
            break
        end
    end
end
]]
-- Mark camp as farmed when attacking a creep
function mark_camp_farmed(npc)
    local npc_pos = Entity.GetAbsOrigin(npc)
    for id, camp in pairs(camp_states) do
        if (npc_pos - camp.position):Length2D() <= 800 then
            camp.farmed = true
            break
        end
    end
end
--- tier token (not actual)

function autofarm.OnEntityCreate( ent )
    if not switcher:Get() then return end
    if Entity.GetClassName(ent) == "C_DOTA_Item_Physical" then
        autofarm.PickUpItem(hero, ent)
        for i = 0, 16 do
            local item = NPC.GetItemByIndex(hero, i)
            if item then
                local itemName = Ability.GetName(item)
                if string.sub(itemName, 1, 9) == "item_tier" then
                    autofarm.moveItemToSlot(hero, item, 16)

                end
            end
        end
    end
end

function autofarm.moveItemToSlot(myHero, item, slot_index)
    Player.PrepareUnitOrders(Players.GetLocal(), Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_ITEM, slot_index, Vector(0, 0, 0), item, Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY, myHero)
end

function autofarm.PickUpItem(player, item)
    Player.PrepareUnitOrders(
        Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_PICKUP_ITEM,
        item,
        Vector(0, 0, 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
        player
    )
end
---

function autofarm.moveAwayFromCamp(camp_vector)
    local hero = Heroes.GetLocal()
    if not hero then return end
    
    autofarm_data.escaping = true
    autofarm_data.another_task = true
    autofarm_data.status = "Moving away from empty camp until next minute"
    
    if not autofarm_data.escape_target then
        local random_angle = math.random() * 2 * math.pi
        local hero_pos = Entity.GetAbsOrigin(hero)
        
        autofarm_data.escape_target = Vector(
            camp_vector.x + math.cos(random_angle) * 800,
            camp_vector.y + math.sin(random_angle) * 800,
            camp_vector.z
        )
        
        print("Generated escape point: " .. tostring(autofarm_data.escape_target))
    end
    
    particle_target = autofarm_data.escape_target
    
    if ((os.clock() - autofarm.LastSpellUse) < 0.133) then return end
    autofarm.LastSpellUse = os.clock()
    
    NPC.MoveTo(hero, autofarm_data.escape_target, false, false)
    
    print("Moving away from camp to: " .. tostring(autofarm_data.escape_target))
end

function autofarm.checkEscapeTime()
    if not autofarm_data.escaping then return false end
    
    local game_time = GameRules.GetGameTime()
    local ingame_timer = game_time - GameRules.GetGameStartTime()
    local seconds = ingame_timer % 60
    
    if seconds >= 0 and seconds <= 1 then
        print("Reached even minute, stopping escape")
        autofarm_data.escaping = false
        autofarm_data.another_task = false
        autofarm_data.escape_target = nil
        particle_target = nil
        autofarm_data.status = "Escape complete"
        local current_camp_name = autofarm_data.active_camps[autofarm_data.current_camp]
        autofarm.reorder_active_camps_from(current_camp_name)
        autofarm_data.current_camp = 1
        autofarm.update_active_camps_with_creeps()
        if #autofarm_data.active_camps > 0 then
            autofarm_data.current_camp = 1
            autofarm_data.farm_status = true
            autofarm_data.total_camps = #autofarm_data.active_camps
            autofarm_data.status = "Restarting farm with new camps"
        end
        return true
    end
    
    return false
end

function autofarm.reorder_active_camps_from(camp_name)
    if not camp_name or #autofarm_data.active_camps < 2 then return end
    local new_order = {camp_name}
    local used = {[camp_name] = true}
    local last_pos = camps_gui[camp_name] and camps_gui[camp_name].camp_ingame
    
    for i = 2, #autofarm_data.active_camps do
        local min_dist = math.huge
        local min_camp = nil
        for _, cname in ipairs(autofarm_data.active_camps) do
            if not used[cname] and camps_gui[cname] and last_pos then
                local dist = (camps_gui[cname].camp_ingame - last_pos):Length2D()
                if dist < min_dist then
                    min_dist = dist
                    min_camp = cname
                end
            end
        end
        if min_camp then
            table.insert(new_order, min_camp)
            used[min_camp] = true
            last_pos = camps_gui[min_camp].camp_ingame
        end
    end
    autofarm_data.active_camps = new_order
end

function autofarm.update_active_camps_with_creeps()
    autofarm_data.active_camps = {}
    for camp_name, camp in pairs(camps_gui) do
        if camp.can_farm then
            table.insert(autofarm_data.active_camps, camp_name)
        end
    end
end

return autofarm