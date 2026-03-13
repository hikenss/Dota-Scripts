---@diagnostic disable: undefined-global
local np_script = {}

--#region UI
local hero_tab = Menu.Create("Heroes", "Hero List", "Nature's Prophet")
local main_settings = hero_tab:Create("Main Settings")
local tab = main_settings:Create("Auto Sprout->Call")

local ui = {}
ui.enabled = tab:Switch("Enable Auto Nature's Call", false, "\u{f00c}")
ui.time_before = tab:Slider("Cast Time Before Trees Disappear", 0, 2000, 1000, function(value)
    return string.format("%.1fs", value / 1000)
end)
ui.time_before:Icon("\u{f017}")

ui.min_mana = tab:Slider("Min Mana % to Cast", 0, 100, 30, function(value)
    return tostring(value) .. "%"
end)

ui.debug = tab:Switch("Debug Mode", false, "\u{f188}")
ui.debug_all_modifiers = tab:Switch("Log ALL Modifiers (for testing)", false, "\u{f188}")
--#endregion

--#region Variables
local my_hero = nil
local sprout_casts = {} -- Table to track sprout positions and timers
local last_sprout_check_time = 0
local last_sprout_cooldown = 0
local temp_trees_before_cast = {} -- Track temp trees before Sprout cast

-- Sprout durations by level (updated for current Dota 2 patch)
local SPROUT_DURATIONS = {
    [1] = 2.5,
    [2] = 3.0,
    [3] = 3.5,
    [4] = 4.0
}
--#endregion

--#region Helper Functions
local function DebugLog(...)
    if ui.debug:Get() then
        print("[NP DEBUG]", ...)
    end
end

local function GetAbilityByName(unit, ability_name)
    for i = 0, 23 do
        local ability = NPC.GetAbilityByIndex(unit, i)
        if ability and Ability.GetName(ability) == ability_name then
            return ability
        end
    end
    return nil
end

local function CanCastAbility(ability)
    if not ability then return false end
    if not Ability.IsReady(ability) then return false end
    if not Ability.IsCastable(ability, NPC.GetMana(my_hero)) then return false end
    return true
end

local function GetManaPercent(unit)
    local max_mana = NPC.GetMaxMana(unit)
    if max_mana == 0 then return 0 end
    return (NPC.GetMana(unit) / max_mana) * 100
end

local function IsHeroSilenced()
    return NPC.IsSilenced(my_hero)
end

-- Log all abilities for debugging
local function LogAllAbilities()
    if not my_hero then return end
    print("========== ALL ABILITIES ==========")
    for i = 0, 23 do
        local ab = NPC.GetAbilityByIndex(my_hero, i)
        if ab then
            local name = Ability.GetName(ab)
            local lvl = Ability.GetLevel(ab) or 0
            if lvl > 0 then
                print(string.format("Slot %d: %s (Level %d)", i, name, lvl))
            end
        end
    end
    print("===================================")
end

-- Check for new temp trees (created by Sprout)
local function CheckForNewSproutTrees()
    local all_trees = TempTrees.GetAll()
    local new_trees = {}
    
    -- Find trees that weren't there before
    for _, tree in ipairs(all_trees) do
        local is_new = true
        for _, old_tree in ipairs(temp_trees_before_cast) do
            if tree == old_tree then
                is_new = false
                break
            end
        end
        if is_new then
            table.insert(new_trees, tree)
        end
    end
    
    -- Update the list
    temp_trees_before_cast = all_trees
    
    -- If we found new trees (sprout creates ~8 trees), calculate center position
    if #new_trees >= 4 then
        local sum_x, sum_y, sum_z = 0, 0, 0
        for _, tree in ipairs(new_trees) do
            local pos = Entity.GetAbsOrigin(tree)
            sum_x = sum_x + pos.x
            sum_y = sum_y + pos.y
            sum_z = sum_z + pos.z
        end
        
        local center = Vector(
            sum_x / #new_trees,
            sum_y / #new_trees,
            sum_z / #new_trees
        )
        
        --DebugLog(string.format("Found %d new temp trees, center: (%.0f, %.0f, %.0f)", 
        --    #new_trees, center.x, center.y, center.z))
        
        return center
    end
    
    return nil
end
--#endregion

--#region Callbacks

-- Track when Sprout ability goes on cooldown (means it was cast)
function np_script.OnUpdate()
    if not ui.enabled:Get() then return end
    
    -- Get local hero
    if not my_hero then 
        my_hero = Heroes.GetLocal()
        if my_hero then
            DebugLog("Hero found:", NPC.GetUnitName(my_hero))
            LogAllAbilities()
        end
        return 
    end
    
    -- Check if hero is Nature's Prophet
    if NPC.GetUnitName(my_hero) ~= "npc_dota_hero_furion" then 
        return 
    end
    
    -- Check if hero is alive
    if not Entity.IsAlive(my_hero) then return end
    
    local current_time = GameRules.GetGameTime()
    
    -- Detect Sprout cast using cooldown + TempTrees (works with all facets, 100% accurate)
    local sprout_ability = GetAbilityByName(my_hero, "furion_sprout")
    if sprout_ability then
        local current_cooldown = Ability.GetCooldown(sprout_ability)
        local level = Ability.GetLevel(sprout_ability)
        
        -- Detect when Sprout just went on cooldown (was cast)
        if level > 0 and current_cooldown > 0 and last_sprout_cooldown == 0 then
            -- Sprout was just cast! Wait a tiny bit for trees to spawn
           DebugLog ("Sprout cooldown detected, checking for new temp trees...")
        end
        
        -- Check for new temp trees after Sprout cast
        if level > 0 and current_cooldown > 0 and last_sprout_cooldown == 0 then
            -- Give it a frame to spawn trees
            local target_pos = CheckForNewSproutTrees()
            
            if target_pos then
                local duration = SPROUT_DURATIONS[level] or 2.5
                
                local cast_data = {
                    position = target_pos,
                    cast_time = current_time,
                    duration = duration,
                    used = false
                }
                
                table.insert(sprout_casts, cast_data)
                
                --DebugLog(string.format("✓ SPROUT CAST DETECTED via TempTrees! Pos: (%.0f, %.0f, %.0f), Duration: %.1fs", 
                --    target_pos.x, target_pos.y, target_pos.z, duration))
            else
                -- Fallback: trees might spawn next frame
                DebugLog("Waiting for temp trees to spawn...")
            end
        end
        
        last_sprout_cooldown = current_cooldown
    end
    
    -- Also check for delayed tree spawning (in case trees spawn 1 frame late)
    if #sprout_casts == 0 or (current_time - sprout_casts[#sprout_casts].cast_time) > 0.5 then
        local tree_pos = CheckForNewSproutTrees()
        if tree_pos and sprout_ability then
            local level = Ability.GetLevel(sprout_ability)
            if level > 0 then
                local duration = SPROUT_DURATIONS[level] or 2.5
                
                local cast_data = {
                    position = tree_pos,
                    cast_time = current_time,
                    duration = duration,
                    used = false
                }
                
                table.insert(sprout_casts, cast_data)
                
                DebugLog(string.format("✓ SPROUT DETECTED via delayed TempTrees! Pos: (%.0f, %.0f, %.0f), Duration: %.1fs", 
                    tree_pos.x, tree_pos.y, tree_pos.z, duration))
            end
        end
    end
    
    local time_before = ui.time_before:Get() / 1000.0
    
    -- Get Nature's Call ability for casting later
    local natures_call = GetAbilityByName(my_hero, "furion_force_of_nature")
    local can_cast_natures_call = false
    
    if natures_call then
        local mana_percent = GetManaPercent(my_hero)
        if mana_percent >= ui.min_mana:Get() and CanCastAbility(natures_call) then
            can_cast_natures_call = true
        else
            if mana_percent < ui.min_mana:Get() then
                --DebugLog(string.format("Not enough mana: %.1f%% < %d%%", mana_percent, ui.min_mana:Get()))
            elseif not CanCastAbility(natures_call) then
                local cd = Ability.GetCooldown(natures_call)
                if cd > 0 then
                    --DebugLog(string.format("Nature's Call on cooldown: %.1fs", cd))
                end
            end
        end
    end
    
    -- Check all tracked sprout casts (ALWAYS run this, even if Nature's Call not ready!)
    for i = #sprout_casts, 1, -1 do
        local cast = sprout_casts[i]
        local elapsed_time = current_time - cast.cast_time
        local time_remaining = cast.duration - elapsed_time
        
        -- Check if trees still exist at this position (more reliable than duration)
        local trees_still_exist = false
        local trees_in_range = TempTrees.InRadius(cast.position, 250)
        if #trees_in_range >= 3 then
            trees_still_exist = true
        end
        
        -- Only log sprouts that are still active
        if trees_still_exist then
           -- DebugLog(string.format("Tracking sprout #%d: elapsed=%.1fs, remaining=%.1fs, trees=%d, used=%s", 
           --     i, elapsed_time, time_remaining, #trees_in_range, tostring(cast.used)))
        elseif time_remaining > -1.0 then
            DebugLog(string.format("⚠️ Sprout #%d: TREES DA BIEN MAT (elapsed=%.1fs), will remove soon...", i, elapsed_time))
        end
        
        -- Remove sprouts when trees are gone OR time remaining is very negative (backup)
        if (not trees_still_exist and elapsed_time > 0.5) or time_remaining < -0.5 then
            local reason = (not trees_still_exist) and "TREES DA BIEN MAT" or "TIME DA AM"
            table.remove(sprout_casts, i)
            DebugLog(string.format("✓ Removed sprout #%d - %s!", i, reason))
        -- Cast Nature's Call right before trees disappear (and trees still exist!)
        elseif not cast.used and trees_still_exist and time_remaining <= time_before and time_remaining > 0 then
            -- Double check conditions before casting
            if IsHeroSilenced() then
                --DebugLog("!!! CANNOT CAST - HERO IS SILENCED !!!")
                cast.used = true -- Mark as used to avoid retrying
            elseif not can_cast_natures_call then
                --DebugLog("!!! CANNOT CAST - ABILITY NOT READY OR NOT ENOUGH MANA !!!")
                -- Don't mark as used, maybe next frame it will be ready
            else
                DebugLog(string.format(">>> CASTING NATURE'S CALL NOW! Time remaining: %.2fs <<<", time_remaining))
                
                Ability.CastPosition(natures_call, cast.position)
                cast.used = true
                
                print(string.format("========================================"))
                print(string.format("[NP AUTO] ✓ NATURE'S CALL CAST THANH CONG!"))
                print(string.format("[NP AUTO] Position: (%.0f, %.0f, %.0f)", 
                    cast.position.x, cast.position.y, cast.position.z))
                print(string.format("[NP AUTO] Time remaining: %.2fs", time_remaining))
                print(string.format("========================================"))
            end
        end
    end
end



function np_script.OnDraw()
    if not ui.enabled:Get() then return end
    if not ui.debug:Get() then return end
    if not my_hero then return end
    
    local current_time = GameRules.GetGameTime()
    local font = Render.LoadFont("Arial", 0, 500)
    
    -- Draw debug info on screen
    local y_offset = 300
    Render.Text(font, 16, string.format("Tracked Sprouts: %d", #sprout_casts), 
        Vec2(10, y_offset), Color(255, 255, 0))
    
    -- Draw debug circles for tracked sprout positions
    for i, cast in ipairs(sprout_casts) do
        local elapsed_time = current_time - cast.cast_time
        local time_remaining = cast.duration - elapsed_time
        
        -- Check if trees still exist at this position
        local trees_in_range = TempTrees.InRadius(cast.position, 250)
        local trees_exist = #trees_in_range >= 3
        
        if trees_exist then
            local color = cast.used and Color(0, 255, 0, 100) or Color(255, 255, 0, 100)
            
            -- Draw circle at sprout position
            local screen_pos, is_visible = Render.WorldToScreen(cast.position)
            if is_visible then
                Render.Circle(screen_pos, 50, color)
                local text = string.format("%.1fs", time_remaining)
                Render.Text(font, 16, text, screen_pos, Color(255, 255, 255))
            end
        end
        
        -- Show info on HUD
        y_offset = y_offset + 20
        local status = cast.used and "USED" or "WAITING"
        local color = trees_exist and Color(255, 255, 255) or Color(255, 100, 100)
        Render.Text(font, 14, string.format("  #%d: %.1fs remaining, trees=%d, %s", 
            i, time_remaining, #trees_in_range, status), 
            Vec2(10, y_offset), color)
    end
end

function np_script.OnGameStart()
    sprout_casts = {}
    my_hero = nil
    last_sprout_check_time = 0
    last_sprout_cooldown = 0
    temp_trees_before_cast = {}
    print("[NP Auto] Script loaded - OnGameStart")
end

function np_script.OnGameEnd()
    sprout_casts = {}
    my_hero = nil
    last_sprout_check_time = 0
    last_sprout_cooldown = 0
    temp_trees_before_cast = {}
    print("[NP Auto] OnGameEnd")
end
--#endregion

return np_script