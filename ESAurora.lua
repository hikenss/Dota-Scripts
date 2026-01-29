--========================================================
-- ESAurora
--========================================================

local TargetLock = require("TargetLock")
local EuphoriaAddon2 = {}

-- ========= CONFIG PERSISTENCE NAMES =========
local CONFIG_NAME = "ESEuphoriaAddons2"

-- ========= MENU =========
local hero_tab = Menu.Find("Heroes", "Hero List", "Earth Spirit")
local euphor_tab = hero_tab:Create("ESAurora")

local main_group    = euphor_tab:Create("Main")
local items_group   = euphor_tab:Create("Items")
local delay_group   = euphor_tab:Create("Delays")
local save_group    = euphor_tab:Create("Simple Push")

local ui = {}
ui.enable   = main_group:Switch("Enable Script", true)
ui.hotkey   = main_group:Bind("Smash Key (hold)", Enum.ButtonCode.KEY_G)
ui.target_prio = main_group:Combo("Target Priority",
    {"Lowest HP%", "Closest", "DPS Score"}, 0)
ui.ally_mode = main_group:Combo("Ally Selection", {"Closest Ally", "Strongest Ally", "Ally with Lowest HP", "Ally on Cursor"}, 0)
ui.ally_lock = main_group:Switch("Lock Ally During Combo", true)
ui.min_dist = main_group:Slider("Min Distance for Smash", 150, 300, 200, "%d")
ui.ally_max_range = main_group:Slider("Max Ally Range", 300, 2500, 1200, "%d")
ui.use_move = main_group:Switch("Allow Manual Movement", true)
ui.retreat_after_smash = main_group:Switch("Retreat with Roll After Smash", true)
ui.prefer_roll = main_group:Switch("Prefer Start with Rolling", true)
ui.debug    = main_group:Switch("Debug Prints", false)
ui.file_logging = main_group:Switch("Save Log to File", false)

-- Simple push
ui.save_enable  = save_group:Switch("Enable Simple Push", true)
ui.save_hotkey  = save_group:Bind("Push + Roll (hold)", Enum.ButtonCode.KEY_H)
ui.save_cursor_range = save_group:Slider("Cursor Range", 200, 800, 400, "%d")
ui.save_target_mode = save_group:Combo("Push Target", {"Enemies Only", "Allies Only", "Any"}, 0)

-- Save ally
local grip_group = euphor_tab:Create("Save Ally (Grip)")
ui.grip_enable = grip_group:Switch("Enable Save Ally", true)
ui.grip_hotkey = grip_group:Bind("Pull Ally (hold)", Enum.ButtonCode.KEY_K)

ui.linken_breaker = items_group:Switch("Auto Linken Breaker", true)
ui.linken_breaker_items = items_group:MultiSelect("Items to Break Linken", {
    {"Force Staff", "panorama/images/items/force_staff_png.vtex_c", true},
    {"Heaven's Halberd", "panorama/images/items/heavens_halberd_png.vtex_c", true},
    {"Rod of Atos", "panorama/images/items/rod_of_atos_png.vtex_c", true},
    {"Orchid", "panorama/images/items/orchid_png.vtex_c", true},
    {"Bloodthorn", "panorama/images/items/bloodthorn_png.vtex_c", true},
    {"Eul's Scepter", "panorama/images/items/cyclone_png.vtex_c", true}
}, true)

-- ========= CONFIG PERSISTENCE FUNCTIONS =========
local function SaveConfig()
    if not Config then
        print("[ESEuphoriaAddons2] Config API not available!")
        return
    end
    
    -- Main settings
    pcall(function() Config.WriteInt(CONFIG_NAME, "enable", ui.enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "hotkey", ui.hotkey:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "debug", ui.debug:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "use_move", ui.use_move:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "min_dist", ui.min_dist:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "target_prio", ui.target_prio:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "retreat_after_smash", ui.retreat_after_smash:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "file_logging", ui.file_logging:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "prefer_roll", ui.prefer_roll:Get() and 1 or 0) end)
    
    -- Push simples
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_enable", ui.save_enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_hotkey", ui.save_hotkey:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_cursor_range", ui.save_cursor_range:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_target_mode", ui.save_target_mode:Get()) end)
    
    -- Grip
    pcall(function() Config.WriteInt(CONFIG_NAME, "grip_enable", ui.grip_enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "grip_hotkey", ui.grip_hotkey:Get()) end)
    
    -- Ally
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_mode", ui.ally_mode:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_lock", ui.ally_lock:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_max_range", ui.ally_max_range:Get()) end)
    

    
    -- Items
    pcall(function() Config.WriteInt(CONFIG_NAME, "linken_breaker", ui.linken_breaker:Get() and 1 or 0) end)
    
    -- Linken breaker items (MultiSelect - save as bitmask)
    pcall(function()
        local linken_breaker_mask = 0
        local linken_breaker_items_list = {"Urn of Shadows", "Spirit Vessel", "Force Staff", "Heaven's Halberd", "Rod of Atos", "Orchid", "Bloodthorn", "Eul's Scepter"}
        for i, name in ipairs(linken_breaker_items_list) do
            if ui.linken_breaker_items:Get(name) then
                linken_breaker_mask = linken_breaker_mask + (2 ^ (i - 1))
            end
        end
        Config.WriteInt(CONFIG_NAME, "linken_breaker_items", linken_breaker_mask)
    end)
    
    print("[ESEuphoriaAddons2] Config saved!")
end

local function LoadConfig()
    if not Config then
        print("[ESEuphoriaAddons2] Config API not available, skipping load!")
        return
    end
    
    pcall(function()
        -- Main settings
        local enable = Config.ReadInt(CONFIG_NAME, "enable", 1)
        ui.enable:Set(enable == 1)
        
        local hotkey = Config.ReadInt(CONFIG_NAME, "hotkey", Enum.ButtonCode.KEY_G)
        if hotkey ~= 0 then ui.hotkey:Set(hotkey) end
        
        local debug_val = Config.ReadInt(CONFIG_NAME, "debug", 0)
        ui.debug:Set(debug_val == 1)
        
        local use_move = Config.ReadInt(CONFIG_NAME, "use_move", 1)
        ui.use_move:Set(use_move == 1)
        
        local min_dist = Config.ReadInt(CONFIG_NAME, "min_dist", 200)
        ui.min_dist:Set(min_dist)
        
        local target_prio = Config.ReadInt(CONFIG_NAME, "target_prio", 0)
        ui.target_prio:Set(target_prio)
        
        local retreat = Config.ReadInt(CONFIG_NAME, "retreat_after_smash", 1)
        ui.retreat_after_smash:Set(retreat == 1)
        
        local file_log = Config.ReadInt(CONFIG_NAME, "file_logging", 0)
        ui.file_logging:Set(file_log == 1)
        
        local prefer_roll = Config.ReadInt(CONFIG_NAME, "prefer_roll", 1)
        ui.prefer_roll:Set(prefer_roll == 1)
        
        -- Push simples
        local save_enable = Config.ReadInt(CONFIG_NAME, "save_enable", 1)
        ui.save_enable:Set(save_enable == 1)
        
        local save_hotkey = Config.ReadInt(CONFIG_NAME, "save_hotkey", Enum.ButtonCode.KEY_H)
        if save_hotkey ~= 0 then ui.save_hotkey:Set(save_hotkey) end
        
        local save_cursor_range = Config.ReadInt(CONFIG_NAME, "save_cursor_range", 400)
        ui.save_cursor_range:Set(save_cursor_range)
        
        local save_target_mode = Config.ReadInt(CONFIG_NAME, "save_target_mode", 0)
        ui.save_target_mode:Set(save_target_mode)
        
        -- Grip
        local grip_enable = Config.ReadInt(CONFIG_NAME, "grip_enable", 1)
        ui.grip_enable:Set(grip_enable == 1)
        
        local grip_hotkey = Config.ReadInt(CONFIG_NAME, "grip_hotkey", Enum.ButtonCode.KEY_K)
        if grip_hotkey ~= 0 then ui.grip_hotkey:Set(grip_hotkey) end
        
        -- Ally
        local ally_mode = Config.ReadInt(CONFIG_NAME, "ally_mode", 0)
        ui.ally_mode:Set(ally_mode)
        
        local ally_lock = Config.ReadInt(CONFIG_NAME, "ally_lock", 1)
        ui.ally_lock:Set(ally_lock == 1)
        
        local ally_max_range = Config.ReadInt(CONFIG_NAME, "ally_max_range", 1200)
        ui.ally_max_range:Set(ally_max_range)
        

        
        -- Items
        local linken_breaker = Config.ReadInt(CONFIG_NAME, "linken_breaker", 1)
        ui.linken_breaker:Set(linken_breaker == 1)
        
        -- Linken breaker items (MultiSelect - load from bitmask)
        local linken_breaker_mask = Config.ReadInt(CONFIG_NAME, "linken_breaker_items", 255) -- default: todos habilitados
        local linken_breaker_items_list = {"Urn of Shadows", "Spirit Vessel", "Force Staff", "Heaven's Halberd", "Rod of Atos", "Orchid", "Bloodthorn", "Eul's Scepter"}
        for i, name in ipairs(linken_breaker_items_list) do
            local bit = 2 ^ (i - 1)
            local enabled = (linken_breaker_mask % (bit * 2)) >= bit
            ui.linken_breaker_items:SetValue(name, enabled)
        end
        
        print("[ESEuphoriaAddons2] Config loaded!")
    end)
end

local function SetupConfigCallbacks()
    -- Main settings callbacks
    ui.enable:SetCallback(function() SaveConfig() end)
    ui.hotkey:SetCallback(function() SaveConfig() end)
    ui.debug:SetCallback(function() SaveConfig() end)
    ui.use_move:SetCallback(function() SaveConfig() end)
    ui.min_dist:SetCallback(function() SaveConfig() end)
    ui.target_prio:SetCallback(function() SaveConfig() end)
    ui.retreat_after_smash:SetCallback(function() SaveConfig() end)
    ui.file_logging:SetCallback(function() SaveConfig() end)
    ui.prefer_roll:SetCallback(function() SaveConfig() end)
    
    -- Push simples callbacks
    ui.save_enable:SetCallback(function() SaveConfig() end)
    ui.save_hotkey:SetCallback(function() SaveConfig() end)
    ui.save_cursor_range:SetCallback(function() SaveConfig() end)
    ui.save_target_mode:SetCallback(function() SaveConfig() end)
    
    -- Grip callbacks
    ui.grip_enable:SetCallback(function() SaveConfig() end)
    ui.grip_hotkey:SetCallback(function() SaveConfig() end)
    
    -- Ally callbacks
    ui.ally_mode:SetCallback(function() SaveConfig() end)
    ui.ally_lock:SetCallback(function() SaveConfig() end)
    ui.ally_max_range:SetCallback(function() SaveConfig() end)
    

    
    -- Items callbacks
    ui.linken_breaker:SetCallback(function() SaveConfig() end)
    ui.linken_breaker_items:SetCallback(function() SaveConfig() end)
end

-- ========= LOAD CONFIG AND SETUP CALLBACKS =========
LoadConfig()
SetupConfigCallbacks()

-- ========= DEBUG =========
local function DebugPrint(msg)
    if ui.debug:Get() then print("[EuphoriaAddon2] " .. msg) end
end
local function Log(msg)
    if ui.debug:Get() then print("[EuphoriaAddon2] " .. msg) end
end
local function FileLog(msg)
    if not ui.file_logging:Get() then return end
    local path = "c:\\Users\\edcfa\\Downloads\\Umbrela\\scripts\\earth_spirit_euphoria.log"
    local f = io.open(path, "a")
    if f then
        f:write(string.format("[%0.2f] %s\n", GameRules.GetGameTime(), msg))
        f:close()
    end
end

-- ========= INPUT TRACKER =========
local prevKeyState = false
local function IsKeyJustPressed(key)
    local now = Input.IsKeyDown(key)
    if now and not prevKeyState then
        prevKeyState = true
        return true
    elseif not now then
        prevKeyState = false
    end
    return false
end
local function IsKeyDown(key) return Input.IsKeyDown(key) end

-- ========= HELPERS =========
local function GetItem(hero, names)
    if type(names) == "string" then names = {names} end
    for i = 0, 14 do
        local item = NPC.GetItemByIndex(hero, i)
        if item then
            local n = Ability.GetName(item)
            for _, v in ipairs(names) do
                if n == v then return item end
            end
        end
    end
    return nil
end

-- Linken Breaker: find and return an enabled item that breaks Linken's Sphere
local linken_breaker_items_raw = {"item_urn_of_shadows", "item_spirit_vessel", "item_force_staff", 
                                   "item_heavens_halberd", "item_rod_of_atos", "item_orchid", "item_bloodthorn", "item_cyclone"}
local function FindLinkenBreakerItem(myHero)
    if not ui.linken_breaker:Get() or not ui.linken_breaker_items then return nil end
    
    -- Map of display names to internal item names
    local item_map = {
        ["Urn of Shadows"] = "item_urn_of_shadows",
        ["Spirit Vessel"] = "item_spirit_vessel",
        ["Force Staff"] = "item_force_staff",
        ["Heaven's Halberd"] = "item_heavens_halberd",
        ["Rod of Atos"] = "item_rod_of_atos",
        ["Orchid"] = "item_orchid",
        ["Bloodthorn"] = "item_bloodthorn",
        ["Eul's Scepter"] = "item_cyclone"
    }
    
    -- Check which items are enabled in the menu
    for display_name, item_name in pairs(item_map) do
        if ui.linken_breaker_items:Get(display_name) then
            local item = GetItem(myHero, item_name)
            if item and Ability.IsReady(item) then
                return item
            end
        end
    end
    return nil
end

local function CanBreakLinkenAtDistance(myHero, enemy)
    local breakerItem = FindLinkenBreakerItem(myHero)
    if not breakerItem then return false end
    
    local dist = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length2D()
    local itemRange = Ability.GetCastRange(breakerItem)
    
    return dist <= itemRange
end

local function GetAbility(hero, name)
    for i = 0, 23 do
        local ab = NPC.GetAbilityByIndex(hero, i)
        if ab and Ability.GetName(ab) == name then
            return ab
        end
    end
    return nil
end

local function CanCast(myHero, ability)
    return ability and Ability.IsReady(ability) and Ability.IsCastable(ability, NPC.GetMana(myHero))
end

-- Hero validity (ignore illusions & invulnerable heroes)
local function IsValidHero(h)
    -- Dota applies 'modifier_invulnerable' while a unit is invulnerable.
    return h and Entity.IsAlive(h) and not NPC.IsIllusion(h) and not NPC.HasModifier(h, "modifier_invulnerable")
end

local castTimers = {}
local function TryCast(key, delay, func)
    local now = GameRules.GetGameTime()
    if not castTimers[key] or castTimers[key] < now then
        func()
        castTimers[key] = now + (delay / 1000.0)
        return true
    end
    return false
end

-- ========= TARGET SELECTOR =========
local locked_target = nil
local function FindEnemyTarget(myHero, force_new)
    -- Don't search for target during push mode
    if pushModeActive then return nil end
    
    if combo_active and locked_target and Entity.IsAlive(locked_target) then
        return locked_target
    end
    if force_new then locked_target = nil end
    
    -- Use simple and efficient method
    local target = TargetLock.GetBestTarget()
    
    -- Fallback to manual method if necessary
    if not target then
        target = TargetLock.FindTarget(1200)
    end
    
    -- Validate if target is attackable
    if target and not TargetLock.IsValidTarget(target) then
        target = nil
    end
    
    locked_target = target
    return target
end

-- ========= ALLY SELECTOR =========
local locked_ally = nil
local last_dir = nil
local retreat_dir = nil
local retreat_pending = false
local debug_last = ""
local roll_travel = 0
local roll_started_at = 0

-- Earth Spirit: track when Remnant was placed and needs to roll
local earthSpiritPending = {
    active = false,
    time = 0,
    escapePos = nil
}
local roll_target_point = nil
local approach_roll_active = false
local action_cd_until = 0
local gate_deadline = 0
local last_roll_remnant_time = 0  -- Track when remnant was created for rolling approach

-- Simplified state doesn't need state machine
local first_update_done = false
local function CountEnemiesNear(pos, radius, myHero)
    local c = 0
    for _, e in pairs(Heroes.GetAll()) do
        if IsValidHero(e) and not Entity.IsSameTeam(myHero, e) then
            if (Entity.GetAbsOrigin(e) - pos):Length2D() <= radius then c = c + 1 end
        end
    end
    return c
end
local function GetFountainPos(team)
    return team == 2 and Vector(-7000,-7000,512) or Vector(7000,7000,512)
end

-- Push state for escape
local pushEscapeState = {active = false, pushTime = 0, pushDir = nil, target = nil}
local pushModeActive = false
local shouldRollEscape = false
local prevPushKeyState = false
local lastPushSmashTime = 0
local pushSmashDir = nil
local prevGripKeyState = false

-- AI: Detect if ally is in danger
local function IsAllyInDanger(ally, myHero)
    local dangerScore = 0
    local allyPos = Entity.GetAbsOrigin(ally)
    local hpPercent = (Entity.GetHealth(ally) / Entity.GetMaxHealth(ally)) * 100
    
    -- 1. Low HP (high weight)
    if hpPercent <= 30 then
        dangerScore = dangerScore + 50
    end
    
    -- 2. Surrounded by enemies
    local enemiesNear = 0
    local alliesNear = 0
    for _, hero in pairs(Heroes.GetAll()) do
        if Entity.IsAlive(hero) and hero ~= ally then
            local dist = (Entity.GetAbsOrigin(hero) - allyPos):Length2D()
            if dist <= 800 then
                if Entity.IsSameTeam(ally, hero) then
                    alliesNear = alliesNear + 1
                else
                    enemiesNear = enemiesNear + 1
                end
            end
        end
    end
    if enemiesNear > alliesNear + 1 then
        dangerScore = dangerScore + 30
    end
    
    -- 3. Stunned/Silenced
    if NPC.IsStunned(ally) or NPC.IsSilenced(ally) then
        dangerScore = dangerScore + 40
    end
    
    -- 4. Far from fountain (more dangerous)
    local fountain = GetFountainPos(Entity.GetTeamNum(ally))
    local distToFountain = (allyPos - fountain):Length2D()
    if distToFountain > 5000 then
        dangerScore = dangerScore + 20
    end
    
    return dangerScore, hpPercent, enemiesNear, alliesNear
end



local lastGripMoveTime = 0

local function SaveAllyWithGrip(myHero, grip)
    local myPos = Entity.GetAbsOrigin(myHero)
    local cursorPos = Input.GetWorldCursorPos()
    local GRIP_RANGE = 1100  -- Max Grip range
    local now = GameRules.GetGameTime()
    
    if not cursorPos then
        FileLog("GRIP: cursor pos nil")
        return
    end
    
    -- If no locked ally, search for a new one based on cursor
    if not locked_ally or not Entity.IsAlive(locked_ally) then
        local bestAlly, minDistToCursor = nil, 9999
        for _, ally in pairs(Heroes.GetAll()) do
            if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
                local allyPos = Entity.GetAbsOrigin(ally)
                local distToCursor = (allyPos - cursorPos):Length2D()
                -- Get the closest ally to cursor
                if distToCursor < minDistToCursor then
                    bestAlly = ally
                    minDistToCursor = distToCursor
                end
            end
        end
        locked_ally = bestAlly
    end
    
    if not locked_ally then 
        FileLog("GRIP: no ally found")
        return 
    end
    
    local allyPos = Entity.GetAbsOrigin(locked_ally)
    local distToMe = (allyPos - myPos):Length2D()
    
    -- If ally is OUT of range, move closer to them
    if distToMe > GRIP_RANGE then
        if ui.use_move:Get() and now >= lastGripMoveTime then
            -- Move to ally using PrepareUnitOrders (same mechanic as combo)
            Player.PrepareUnitOrders(Players.GetLocal(),
                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                0,
                allyPos,
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                myHero,
                false,
                true
            )
            lastGripMoveTime = now + 0.15
            FileLog(string.format("GRIP: chasing ally (dist=%.1f range=%.1f)", distToMe, GRIP_RANGE))
        end
        return
    end
    
    -- Ally is in range, try to pull
    if grip and CanCast(myHero, grip) then
        Ability.CastTarget(grip, locked_ally)
        FileLog(string.format("GRIP: saving %s (dist=%.1f)", 
            Entity.GetUnitName(locked_ally), distToMe))
    else
        if not grip then
            FileLog("GRIP: ability nil")
        else
            FileLog("GRIP: ability unavailable (CD/Mana)")
        end
    end
end

-- Count nearby enemies and allies
local function CountNearbyHeroes(pos, radius)
    local enemies, allies = 0, 0
    local myHero = Heroes.GetLocal()
    for _, hero in pairs(Heroes.GetAll()) do
        if Entity.IsAlive(hero) and hero ~= myHero then
            local dist = (Entity.GetAbsOrigin(hero) - pos):Length2D()
            if dist <= radius then
                if Entity.IsSameTeam(myHero, hero) then
                    allies = allies + 1
                else
                    enemies = enemies + 1
                end
            end
        end
    end
    return enemies, allies
end

-- Smart push: execute smash directly on cursor
local function SimpleCursorPush(myHero, smash)
    local cursorPos = Input.GetWorldCursorPos()
    if not cursorPos then 
        FileLog("PUSH: cursor pos nil")
        return 
    end
    
    local now = GameRules.GetGameTime()
    
    if not smash then
        FileLog("PUSH: smash ability nil")
        return
    end
    
    if not CanCast(myHero, smash) then
        FileLog(string.format("PUSH: smash NOT ready - CD=%.1f Mana=%d/%d", 
            Ability.GetCooldown(smash), NPC.GetMana(myHero), Ability.GetManaCost(smash)))
        return
    end
    
    if castTimers["push_smash"] and now < castTimers["push_smash"] then
        return
    end
    
    -- Direction: from cursor to enemy fountain
    local pushDir = (cursorPos - Entity.GetAbsOrigin(myHero)):Normalized()
    
    Ability.CastPosition(smash, cursorPos)
    
    -- STOP to not attack after
    Player.PrepareUnitOrders(Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_STOP,
        0,
        Vector(0, 0, 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        myHero,
        false,
        false
    )
    
    if shouldRollEscape then
        pushEscapeState.active = true
        pushEscapeState.pushTime = GameRules.GetGameTime()
        pushEscapeState.pushDir = pushDir
    end
    castTimers["push_smash"] = now + 0.3
end

local function IsRolling(unit)
    return NPC.HasModifier(unit, "modifier_earth_spirit_rolling_boulder")
end
-- Prediction using TargetLock
local function PredictEnemyPos(enemy, now)
    if not enemy then return nil end
    return TargetLock.PredictPosition(enemy, 0.5, nil)
end
local function AllyScore(myHero, ally)
    local myPos = Entity.GetAbsOrigin(myHero)
    local pos   = Entity.GetAbsOrigin(ally)
    local dist  = (pos - myPos):Length2D()
    if dist > ui.ally_max_range:Get() then return 1e9 end
    local mode = ui.ally_mode:Get()
    if mode == 0 then -- Closest
        return dist
    elseif mode == 1 then -- Strongest (damage + level)
        return - (NPC.GetBaseDamage(ally) + NPC.GetCurrentLevel(ally) * 6)
    elseif mode == 2 then -- Lowest HP
        return (Entity.GetHealth(ally) / math.max(Entity.GetMaxHealth(ally),1)) * 100
    elseif mode == 3 then -- Cursor Ally
        local cpos = Input.GetWorldCursorPos()
        return (pos - cpos):Length2D()
    end
    return dist
end
local function FindPreferredAlly(myHero, force_new)
    if ui.ally_lock:Get() and combo_active and locked_ally and Entity.IsAlive(locked_ally) then
        return locked_ally
    end
    if force_new then locked_ally = nil end
    local best, bestScore = nil, 1e9
    for _, ally in pairs(Heroes.GetAll()) do
        if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
            local score = AllyScore(myHero, ally)
            if score < bestScore then
                best, bestScore = ally, score
            end
        end
    end
    locked_ally = best
    return best
end

-- ========= DIRECTION HELPERS =========
local function DirectionTowardsAlly(enemy, ally)
    if not enemy or not ally then return nil end
    local epos = Entity.GetAbsOrigin(enemy)
    local apos = Entity.GetAbsOrigin(ally)
    local v = (apos - epos)
    local len = v:Length2D()
    if len < 1 then return nil end
    return v:Normalized()
end

-- ========= SMOOTH CHASE =========
local lastMoveTime = 0
local function SmoothChase(myHero, enemy, minDist)
    if not myHero or not enemy then return end
    if not Entity.IsAlive(enemy) then return end
    if Input.IsKeyDown(Enum.ButtonCode.MOUSE_RIGHT) then return end

    local now = GameRules.GetGameTime()
    if now < lastMoveTime then return end

    local myPos = Entity.GetAbsOrigin(myHero)
    local enemyPos = Entity.GetAbsOrigin(enemy)
    local dist = (myPos - enemyPos):Length2D()

    if dist > minDist then
        Player.PrepareUnitOrders(Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            0,
            enemyPos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
            myHero,
            false,
            true
        )
        lastMoveTime = now + 0.25
    end
end

-- ========= COMBO =========
local combo_active, combo_state, combo_time = false, 0, 0
local last_remnant_time = 0  -- Control to avoid creating multiple remnants
local last_blink_time = 0  -- Control to avoid blink loop
local last_linken_break_time = 0  -- Control to ensure Linken break before smash
local last_grip_time = 0  -- Control to use Grip after smash
local smash_executed = false  -- Flag to indicate smash was executed
local smash_enemy = nil
local lastAutoSaveTime = 0

function EuphoriaAddon2.OnUpdate()
    if not ui.enable:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_earth_spirit" then return end
    local now = GameRules.GetGameTime()
    if not first_update_done then
        first_update_done = true
        FileLog("SCRIPT INIT OK")
        DebugPrint("Init OK")
    end
    
    -- Auto-save config a cada 30 segundos
    if now - lastAutoSaveTime >= 30 then
        SaveConfig()
        lastAutoSaveTime = now
    end

    local blink   = GetItem(myHero, {"item_blink","item_overwhelming_blink"})
    local harpoon = GetItem(myHero, "item_harpoon")
    local smash   = GetAbility(myHero, "earth_spirit_boulder_smash")
    local enchant = GetAbility(myHero, "earth_spirit_petrify")
    local rolling = GetAbility(myHero, "earth_spirit_rolling_boulder")
    local stoneRemnant = GetAbility(myHero, "earth_spirit_stone_caller")
    local grip    = GetAbility(myHero, "earth_spirit_geomagnetic_grip")
    local has_aghs = enchant and Ability.GetLevel(enchant) > 0
    
    -- Save ally with Grip (hold key)
    if ui.grip_enable:Get() and IsKeyDown(ui.grip_hotkey:Get()) then
        if grip and (not castTimers["grip_cooldown"] or now >= castTimers["grip_cooldown"]) then
            SaveAllyWithGrip(myHero, grip)
            castTimers["grip_cooldown"] = now + 0.5
            FileLog("GRIP: activated (hold)")
        end
    else
        -- Clear locked ally when releasing key
        if locked_ally then
            locked_ally = nil
            FileLog("GRIP: ally unlocked")
        end
    end

    -- Simple push by cursor (key press)
    local pushKeyDown = IsKeyDown(ui.save_hotkey:Get())
    
    -- H = hold to move to target, try smash continuously, roll only if smash on CD
    if ui.save_enable:Get() and pushKeyDown then
        local cursorPos = Input.GetWorldCursorPos()
        if cursorPos then
            -- Search for hero closest to Earth Spirit based on mode
            local myPos = Entity.GetAbsOrigin(myHero)
            local targetMode = ui.save_target_mode:Get()
            local nearestTarget = nil
            local minDist = ui.save_cursor_range:Get()
            
            for _, h in pairs(Heroes.GetAll()) do
                if h ~= myHero and IsValidHero(h) then
                    local isEnemy = not Entity.IsSameTeam(myHero, h)
                    local isAlly = Entity.IsSameTeam(myHero, h)
                    local validTarget = false
                    
                    if targetMode == 0 and isEnemy then -- Enemies Only
                        validTarget = true
                    elseif targetMode == 1 and isAlly then -- Allies Only
                        validTarget = true
                    elseif targetMode == 2 then -- Any
                        validTarget = true
                    end
                    
                    if validTarget then
                        local d = (Entity.GetAbsOrigin(h) - myPos):Length2D()
                        if d < minDist then
                            minDist = d
                            nearestTarget = h
                        end
                    end
                end
            end
            
            -- If has target
            if nearestTarget then
                local targetPos = Entity.GetAbsOrigin(nearestTarget)
                local distToTarget = (targetPos - myPos):Length2D()
                
                -- If close (<=100), try to smash
                if distToTarget <= 100 and smash then
                    -- Try smash continuously while close
                    if CanCast(myHero, smash) and (now - lastPushSmashTime) >= 0.5 then
                        -- Direction: always from target to cursor (push towards cursor)
                        local pushDir = (cursorPos - targetPos):Normalized()
                        -- Position smash ahead of target towards cursor
                        local smashPos = targetPos + pushDir * 150
                        Ability.CastPosition(smash, smashPos)
                        lastPushSmashTime = now
                        pushSmashDir = pushDir
                        FileLog("PUSH: Boulder Smash executed")
                        
                        -- Schedule retreat with remnant after 0.3s
                        if ui.retreat_after_smash:Get() and rolling and CanCast(myHero, rolling) then
                            pushEscapeState.active = true
                            pushEscapeState.pushTime = now + 0.3
                            pushEscapeState.pushDir = pushDir
                            FileLog("PUSH: Retreat scheduled after smash")
                        end
                    elseif not CanCast(myHero, smash) then
                        -- Smash on CD = roll to escape ONLY if no retreat pending
                        if not pushEscapeState.active and rolling and CanCast(myHero, rolling) and (now - lastPushSmashTime) >= 0.5 then
                            local rollPos
                            
                            -- If mode is ally (1) OR any (2) AND has nearby ally, roll on top of ally
                            if (targetMode == 1 or targetMode == 2) and nearestTarget and Entity.IsSameTeam(myHero, nearestTarget) then
                                local allyPos = Entity.GetAbsOrigin(nearestTarget)
                                rollPos = allyPos
                            -- Otherwise, escape in opposite direction from nearest enemy
                            else
                                local nearestEnemy = nil
                                local minDistEnemy = 9999
                                for _, enemy in pairs(Heroes.GetAll()) do
                                    if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                                        local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length2D()
                                        if dist < minDistEnemy then
                                            minDistEnemy = dist
                                            nearestEnemy = enemy
                                        end
                                    end
                                end
                                
                                if nearestEnemy then
                                    local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
                                    local escapeDir = (myPos - enemyPos):Normalized()
                                    rollPos = myPos + escapeDir * 800
                                end
                            end
                            
                            if rollPos then
                                Ability.CastPosition(rolling, rollPos)
                                lastPushSmashTime = now
                                FileLog("PUSH: Roll executed (smash on CD)")
                            end
                        end
                    end
                -- If far (>100), approach first
                elseif distToTarget > 100 then
                    Player.PrepareUnitOrders(Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        0,
                        targetPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                        myHero,
                        false,
                        true
                    )
                    FileLog("PUSH: Approaching target")
                end
            end
        end
    end
    prevPushKeyState = pushKeyDown

    -- Push Escape: Execute retreat with remnant after smash
    if pushEscapeState.active and now >= pushEscapeState.pushTime then
        if rolling and CanCast(myHero, rolling) and pushEscapeState.pushDir then
            local myPos2 = Entity.GetAbsOrigin(myHero)
            local retreat_point = myPos2 + pushEscapeState.pushDir * 700
            
            -- Use remnant before rolling if has charge and mana for both casts
            local hasRemnant = false
            if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                local myMana = NPC.GetMana(myHero)
                local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                    hasRemnant = true
                end
            end
            
            if hasRemnant then
                local remnantPos = myPos2 + pushEscapeState.pushDir * 200
                Ability.CastPosition(stoneRemnant, remnantPos)
                earthSpiritPending = { active = true, time = now, escapePos = retreat_point }
                FileLog(string.format("PUSH RETREAT: remnant created -> roll pending to (%.0f,%.0f)", retreat_point.x, retreat_point.y))
            else
                Ability.CastPosition(rolling, retreat_point)
                FileLog(string.format("PUSH RETREAT: direct roll -> (%.0f,%.0f)", retreat_point.x, retreat_point.y))
            end
        end
        pushEscapeState.active = false
    end


    -- EARTH SPIRIT: Use Rolling Boulder after placing Stone Remnant
    if earthSpiritPending.active then
        local heroName = NPC.GetUnitName(myHero)
        if heroName == "npc_dota_hero_earth_spirit" then
            local elapsed = now - earthSpiritPending.time
            -- Timeout after 1.0 seconds
            if elapsed >= 1.0 then
                earthSpiritPending.active = false
            -- Try from 0.05s until success (or up to 0.5s fallback)
            elseif elapsed >= 0.05 then
                if rolling and Ability.IsCastable(rolling, NPC.GetMana(myHero)) then
                    Ability.CastPosition(rolling, earthSpiritPending.escapePos)
                    earthSpiritPending.active = false
                end
                if elapsed >= 0.5 then
                    earthSpiritPending.active = false
                end
            end
        else
            earthSpiritPending.active = false
        end
    end
    

    -- Combo hold logic (blocked during push escape)
    local holding = IsKeyDown(ui.hotkey:Get())
    if holding and not combo_active and not pushModeActive then
        combo_active, combo_state = true, 0
        smash_enemy = FindEnemyTarget(myHero, true)
        FindPreferredAlly(myHero, true)
        DebugPrint("Combo start")
        debug_last = "start"
        retreat_pending = false
        retreat_dir = nil
        approach_roll_active = false
        -- DON'T clear earthSpiritPending here - let the system execute roll after remnant
        FileLog("Combo START target="..(smash_enemy and Entity.GetUnitName(smash_enemy) or "nil"))
        local allyStart = FindPreferredAlly(myHero, false)
        FileLog("Ally SELECT="..(allyStart and Entity.GetUnitName(allyStart) or "auto"))
    elseif (not holding) and combo_active then
        combo_active, combo_state, smash_enemy = false, 0, nil
        locked_target = nil
        locked_ally = nil
        TargetLock.ClearLock()
        DebugPrint("Combo stop")
        return  -- Para a execução quando solta a tecla
    end
    
    -- Bloqueia combo se push mode está ativo
    if pushModeActive then
        return
    end

    -- Se não está ativo OU não tem alvo válido, para aqui
    if not combo_active then return end
    if not smash_enemy or not Entity.IsAlive(smash_enemy) then 
        FileLog("Combo stopped: no valid target")
        return 
    end
    local myPos, enemyPos = Entity.GetAbsOrigin(myHero), Entity.GetAbsOrigin(smash_enemy)
    local dist = (myPos - enemyPos):Length2D()

    local pref_ally = FindPreferredAlly(myHero, false)

    if combo_state == 0 then
        FileLog(string.format("STATE0: dist=%.1f rolling=%s canRoll=%s blink=%s preferRoll=%s holding=%s", 
            dist, tostring(rolling~=nil), tostring(rolling and CanCast(myHero, rolling)), 
            tostring(blink~=nil), tostring(ui.prefer_roll:Get()), tostring(holding)))
        
        -- If VERY FAR (>1600), just approach walking - NEVER try abilities
        if dist > 1600 then
            if ui.use_move:Get() and not IsRolling(myHero) then
                SmoothChase(myHero, smash_enemy, ui.min_dist:Get())
                action_cd_until = now + 0.05
            end
            FileLog(string.format("STATE0: TOO FAR dist=%.1f - WALKING", dist))
        -- First check if close enough to do smash directly
        elseif dist <= ui.min_dist:Get() + 40 and smash and CanCast(myHero, smash) then
            local pref_ally0 = FindPreferredAlly(myHero, false)
            local dir0 = pref_ally0 and DirectionTowardsAlly(smash_enemy, pref_ally0) or nil
            if not dir0 then
                local bestScore, bestDir = -9999, nil
                for i = 0, 15 do
                    local angle = (math.pi * 2 / 16) * i
                    local d    = Vector(math.cos(angle), math.sin(angle), 0)
                    local startPos = Entity.GetAbsOrigin(smash_enemy)
                    local endPos   = startPos + d * 600
                    local score = 0
                    local myPos2 = Entity.GetAbsOrigin(myHero)
                    if (endPos - myPos2):Length2D() < (startPos - myPos2):Length2D() then score = score + 30 end
                    if score > bestScore then bestScore, bestDir = score, d end
                end
                dir0 = bestDir
            end
            if dir0 and smash and CanCast(myHero, smash) then
                local fastOk = TryCast("smash_fast", 0, function() Ability.CastPosition(smash, Entity.GetAbsOrigin(smash_enemy) + dir0 * 300) end)
                if fastOk then
                    FileLog(string.format("STATE0 FAST_SMASH dir=(%.2f,%.2f) dist=%.1f", dir0.x, dir0.y, dist))
                    combo_state, combo_time = 2, now + 0.15
                else
                    FileLog("STATE0 FAST_SMASH TryCast locked")
                    combo_state = 1
                end
            else
                combo_state = 1
                FileLog("STATE0 FAST_SMASH dir_nil_or_unavailable -> state=1")
            end
        -- Se preferir rolling E dist 1200-1600: usa rolling COM remnant para alcance máximo
        elseif ui.prefer_roll:Get() and rolling and CanCast(myHero, rolling) and dist > 1200 and dist <= 1600 then
            local myPosIn = Entity.GetAbsOrigin(myHero)
            local predicted = PredictEnemyPos(smash_enemy, now)
            local lenIn = (predicted - myPosIn):Length2D()
            
            -- Usa remnant antes de rolar se tiver mana
            local hasRemnant = false
            if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                local myMana = NPC.GetMana(myHero)
                local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                local timeSinceLastRemnant = now - last_remnant_time
                if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) and timeSinceLastRemnant >= 0.8 then
                    hasRemnant = true
                end
            end
            
            if hasRemnant then
                local myPosInCast = Entity.GetAbsOrigin(myHero)
                local dirToRoll = (predicted - myPosInCast):Normalized()
                local remnantPos = myPosInCast + dirToRoll * 200
                Ability.CastPosition(stoneRemnant, remnantPos)
                earthSpiritPending = { active = true, time = now, escapePos = predicted }
                last_remnant_time = now + 3.5  -- Longer cooldown to prevent kicking remnant after roll
                last_roll_remnant_time = now  -- Track this remnant was for rolling
                FileLog(string.format("REMNANT PLACED for LONG roll dist=%.1f", dist))
            else
                Ability.CastPosition(rolling, predicted)
                FileLog(string.format("ROLLING (no remnant) dist=%.1f", dist))
            end
            
            -- SEMPRE seta estado 1 imediatamente, igual ao blink
            combo_time, combo_state = now + 0.08, 1
            approach_roll_active = true
            action_cd_until = now + 0.05
            DebugPrint(string.format("STATE0: LONG ROLL dist=%.1f -> predicted(%.1f,%.1f)", dist, predicted.x, predicted.y))
            FileLog(string.format("STATE0 LONG ROLL target=(%.0f,%.0f) travel=%.0f", predicted.x, predicted.y, lenIn))
        -- Se preferir rolling E dist 300-1200: usa rolling SEM remnant
        elseif ui.prefer_roll:Get() and rolling and CanCast(myHero, rolling) and dist >= 300 and dist <= 1200 then
            local myPosIn = Entity.GetAbsOrigin(myHero)
            local predicted = PredictEnemyPos(smash_enemy, now)
            local lenIn = (predicted - myPosIn):Length2D()
            
            -- Usa remnant antes de rolar se tiver mana
            local hasRemnant = false
            if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                local myMana = NPC.GetMana(myHero)
                local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                local timeSinceLastRemnant = now - last_remnant_time
                if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) and timeSinceLastRemnant >= 0.8 then
                    hasRemnant = true
                end
            end
            
            if hasRemnant then
                local myPosInCast = Entity.GetAbsOrigin(myHero)
                local dirToRoll = (predicted - myPosInCast):Normalized()
                local remnantPos = myPosInCast + dirToRoll * 200
                Ability.CastPosition(stoneRemnant, remnantPos)
                earthSpiritPending = { active = true, time = now, escapePos = predicted }
                last_remnant_time = now + 3.5  -- Longer cooldown to prevent kicking remnant after roll
                last_roll_remnant_time = now  -- Track this remnant was for rolling
            else
                Ability.CastPosition(rolling, predicted)
            end
            
            -- SEMPRE seta estado 1 imediatamente, igual ao blink
            combo_time, combo_state = now + 0.08, 1
            approach_roll_active = true
            action_cd_until = now + 0.05
            DebugPrint(string.format("STATE0: ROLL prefer -> predicted(%.1f,%.1f) dist=%.1f", predicted.x, predicted.y, dist))
            FileLog(string.format("STATE0 ROLL prefer target=(%.0f,%.0f) travel=%.0f", predicted.x, predicted.y, lenIn))
        -- If NOT prefer rolling: try blink before rolling
        elseif (not ui.prefer_roll:Get()) and blink and Ability.IsReady(blink) and dist > 250 and dist < 1200 and (now - last_blink_time) >= 1.0 then
            TryCast("blink", 100, function() 
                Ability.CastPosition(blink, enemyPos)
            end)
            last_blink_time = now
            combo_time, combo_state = now+0.08,1
            DebugPrint(string.format("STATE0: BLINK -> state=1 t=%.2f dist=%.1f", combo_time, dist))
            FileLog(string.format("STATE0 BLINK dist=%.1f", dist))
            
            -- Marca que usou blink (não precisa criar remnant depois)
            approach_roll_active = false
            earthSpiritPending.active = false  -- Cancela qualquer roll pendente
            action_cd_until = now + 0.05
        elseif harpoon and Ability.IsReady(harpoon) and dist > 300 and dist < 1300 then
            TryCast("harpoon", 200, function() Ability.CastTarget(harpoon,smash_enemy) end)
            combo_time, combo_state = now+0.3,1
            DebugPrint("STATE0: harpoon -> state=1")
            FileLog("STATE0 HARPOON")
            action_cd_until = now + 0.05
        -- If no ability can be used but is far, approach
        elseif ui.use_move:Get() then
            if not IsRolling(myHero) then
                SmoothChase(myHero, smash_enemy, ui.min_dist:Get())
                action_cd_until = now + 0.05
            end
            DebugPrint("STATE0: chase")
            FileLog("STATE0 CHASE (no abilities in range)")
        else
            -- Se não pode mover, vai para state 1 (espera)
            combo_state = 1
            DebugPrint("STATE0: no move allowed -> state=1")
            FileLog("STATE0 NO MOVE -> 1")
        end

    elseif combo_state == 1 and now >= combo_time then
        FileLog(string.format("STATE1 ENTER (now=%.2f combo_time=%.2f)", now, combo_time))
        combo_state, combo_time = 2, now+0.12
        DebugPrint("STATE1: -> state=2")
        FileLog(string.format("STATE1 -> 2 (next at %.2f)", combo_time))

    elseif combo_state == 2 and now >= combo_time then
        FileLog(string.format("STATE2 ENTER (now=%.2f combo_time=%.2f)", now, combo_time))
        -- Garantir que a rolagem terminou e estamos de frente ao inimigo (com timeout)
        if approach_roll_active and roll_started_at > 0 then
            local myPosCheck = Entity.GetAbsOrigin(myHero)
            local toRollTarget = roll_target_point and (roll_target_point - myPosCheck):Length2D() or 0
            local enemyPosCheck = Entity.GetAbsOrigin(smash_enemy)
            local facingDir = (enemyPosCheck - myPosCheck)
            local lenF = facingDir:Length2D()
            if lenF > 1 then
                local dirN = facingDir:Normalized()
                local forward = Entity.GetForwardVector(myHero) or dirN
                local dot = forward.x*dirN.x + forward.y*dirN.y
                local rollingNow = IsRolling(myHero)
                local enemyDist = (enemyPosCheck - myPosCheck):Length2D()
                DebugPrint(string.format("STATE2: rem=%.1f enemyDist=%.1f dot=%.2f roll=%s deadline=%.2f now=%.2f",
                    toRollTarget, enemyDist, dot, tostring(rollingNow), gate_deadline, now))
                FileLog(string.format("ROLL CHECK rem=%.1f enemyDist=%.1f dot=%.2f roll=%s deadline=%.2f now=%.2f",
                    toRollTarget, enemyDist, dot, tostring(rollingNow), gate_deadline, now))
                local pass = false
                if rollingNow then
                    pass = (toRollTarget <= 300 and dot >= 0.65) or (now >= gate_deadline)
                else
                    pass = (enemyDist <= 350 and dot >= 0.50) or (now >= gate_deadline)
                end
                if not pass then
                    if dot < 0.65 and toRollTarget <= 300 then
                        Player.PrepareUnitOrders(Players.GetLocal(),
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            0,
                            enemyPosCheck,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                            myHero,
                            false,
                            true
                        )
                        DebugPrint("STATE2: face correction before Smash")
                        FileLog("FACE CORRECTION issued")
                    end
                    combo_time = now + 0.08
                    FileLog("ROLL WAIT")
                    return
                end
            end
            -- reset markers após validação
            roll_started_at = 0
            roll_travel = 0
            roll_target_point = nil
            approach_roll_active = false
            gate_deadline = 0
            FileLog("ROLL COMPLETE")
        end
        if not smash then
            FileLog("STATE2 smash ability nil")
        elseif not CanCast(myHero, smash) then
            FileLog("STATE2 smash not castable (cd/mana)")
        else
            local dir = pref_ally and DirectionTowardsAlly(smash_enemy, pref_ally) or nil
            if not dir then
                local bestScore, bestDir = -9999, nil
                for i = 0, 15 do
                    local angle = (math.pi * 2 / 16) * i
                    local d    = Vector(math.cos(angle), math.sin(angle), 0)
                    local startPos = Entity.GetAbsOrigin(smash_enemy)
                    local endPos   = startPos + d * 600
                    local score = 0
                    local myPos2 = Entity.GetAbsOrigin(myHero)
                    if (endPos - myPos2):Length2D() < (startPos - myPos2):Length2D() then score = score + 30 end
                    if score > bestScore then bestScore, bestDir = score, d end
                end
                dir = bestDir
                DebugPrint("Fallback radial dir")
            else
                DebugPrint("Ally-directed dir towards "..Entity.GetUnitName(pref_ally))
            end
            if dir then
                local enemyPos = Entity.GetAbsOrigin(smash_enemy)
                
                -- Check and break Linken's Sphere if enemy is protected
                if NPC.IsLinkensProtected(smash_enemy) then
                    local breakerItem = FindLinkenBreakerItem(myHero)
                    if breakerItem then
                        local castOk = TryCast("linken_breaker", 0, function()
                            Ability.CastTarget(breakerItem, smash_enemy)
                        end)
                        if castOk then
                            FileLog("STATE2 LINKEN BREAKER cast no inimigo")
                            last_linken_break_time = now
                            combo_time = now + 0.4  -- Aguarda quebra de Linken completar
                            smash_executed = false  -- Reset flag
                            return
                        end
                    end
                end
                
                -- Check if there's an ally near smash_enemy position (avoid pushing ally)
                local hasAllyNear = false
                for _, ally in pairs(Heroes.GetAll()) do
                    if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
                        local distToEnemy = (Entity.GetAbsOrigin(ally) - enemyPos):Length2D()
                        if distToEnemy <= 200 then
                            hasAllyNear = true
                            FileLog("STATE2 smash BLOCKED: aliado próximo ao inimigo")
                            break
                        end
                    end
                end
                
                -- Check if there's a remnant near enemy (avoid kicking remnant instead of hero)
                local hasRemnantNear = false
                if not hasAllyNear then
                    for i = 1, NPCs.Count() do
                        local npc = NPCs.Get(i)
                        if npc and Entity.IsAlive(npc) then
                            local npcName = NPC.GetUnitName(npc)
                            if npcName == "npc_dota_earth_spirit_stone" then
                                local distToEnemy = (Entity.GetAbsOrigin(npc) - enemyPos):Length2D()
                                local npcPos = Entity.GetAbsOrigin(npc)
                                local distToHero = (npcPos - Entity.GetAbsOrigin(myHero)):Length2D()
                                
                                -- Block if remnant was created for rolling within last 4 seconds
                                local recentRollRemnant = last_roll_remnant_time > 0 and (now - last_roll_remnant_time) < 4.0
                                
                                if distToEnemy <= 150 or (recentRollRemnant and distToHero <= 600) then
                                    hasRemnantNear = true
                                    FileLog(string.format("STATE2 smash BLOCKED: remnant dist_enemy=%.1f dist_hero=%.1f rollRemnant=%s age=%.2f", 
                                        distToEnemy, distToHero, tostring(recentRollRemnant), now - last_roll_remnant_time))
                                    break
                                end
                            end
                        end
                    end
                end
                
                if not hasAllyNear and not hasRemnantNear then
                    last_dir = dir
                    local castOk = TryCast("smash", 120, function()
                        Ability.CastPosition(smash, Entity.GetAbsOrigin(smash_enemy) + dir * 300)
                    end)
                    if castOk then
                        Log(string.format("Smash dir=(%.2f,%.2f) enemy=%s ally=%s", dir.x, dir.y, Entity.GetUnitName(smash_enemy), pref_ally and Entity.GetUnitName(pref_ally) or "nil"))
                        FileLog(string.format("SMASH cast dir=(%.2f,%.2f) enemy=%s ally=%s", dir.x, dir.y, Entity.GetUnitName(smash_enemy), pref_ally and Entity.GetUnitName(pref_ally) or "nil"))
                        smash_executed = true  -- Mark that smash was executed
                        -- ONLY set retreat if smash was actually executed
                        if ui.retreat_after_smash:Get() and rolling and CanCast(myHero, rolling) then
                            retreat_dir = dir
                            retreat_pending = true
                            DebugPrint("STATE2: retreat pending (smash executed successfully)")
                            FileLog("RETREAT queued (smash OK)")
                        end
                        -- Aguarda próximo frame para executar Grip
                        combo_time = now + 0.05
                        return
                    else
                        FileLog("STATE2 smash TryCast locked (delay timer) - SEM RETREAT")
                    end
                end
            else
                FileLog("STATE2 dir nil (no ally/fallback)")
            end
        end
        -- Reset smash_executed
        smash_executed = false
        if retreat_pending and ui.retreat_after_smash:Get() then
            combo_state, combo_time = 3, now+0.25
            DebugPrint("STATE2: -> state=3 (retreat)")
            FileLog("STATE2 -> 3")
        else
            combo_state, combo_time = 0, now+0.2
            DebugPrint("STATE2: -> state=0")
            FileLog("STATE2 -> 0")
        end
    elseif combo_state == 3 and now >= combo_time then
        if rolling and CanCast(myHero, rolling) and retreat_dir then
            local myPos2 = Entity.GetAbsOrigin(myHero)
            local retreat_point = myPos2 + retreat_dir * 700
            
            -- Usa remnant antes de rolar se tiver charge e mana para os dois casts
            local hasRemnant = false
            if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                local myMana = NPC.GetMana(myHero)
                local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                    hasRemnant = true
                end
            end
            
            if hasRemnant then
                local dirToRoll = retreat_dir
                local remnantPos = myPos2 + dirToRoll * 200
                Ability.CastPosition(stoneRemnant, remnantPos)
                earthSpiritPending = { active = true, time = now, escapePos = retreat_point }
                FileLog(string.format("RETREAT remnant created -> roll pending to (%.0f,%.0f)", retreat_point.x, retreat_point.y))
            else
                TryCast("roll_out", 0, function() Ability.CastPosition(rolling, retreat_point) end)
                FileLog(string.format("RETREAT direct roll -> (%.0f,%.0f)", retreat_point.x, retreat_point.y))
            end
            DebugPrint("Rolling Boulder retreat -> ally")
        end
        retreat_pending = false
        retreat_dir = nil
        combo_state, combo_time = 0, now+0.4
        DebugPrint("STATE3: done -> state=0")
        FileLog("STATE3 done -> 0")
    end
end

-- ========= OVERLAY =========
function EuphoriaAddon2.OnDraw()
    if not ui.enable:Get() then return end
    
    -- Draw target lock quando combo está ativo
    if combo_active and smash_enemy and Entity.IsAlive(smash_enemy) then
        TargetLock.DrawTargetLock(smash_enemy)
    end
    
    -- Draw cursor range para push mode
    if ui.save_enable:Get() and IsKeyDown(ui.save_hotkey:Get()) then
        local cursorPos = Input.GetWorldCursorPos()
        if cursorPos then
            local range = ui.save_cursor_range:Get()
            local segments = 32
            for i = 0, segments do
                local angle1 = (math.pi * 2 / segments) * i
                local angle2 = (math.pi * 2 / segments) * (i + 1)
                local p1 = cursorPos + Vector(math.cos(angle1) * range, math.sin(angle1) * range, 0)
                local p2 = cursorPos + Vector(math.cos(angle2) * range, math.sin(angle2) * range, 0)
                Renderer.DrawLine3D(p1, p2, 100, 200, 255, 200, 2)
            end
        end
    end
    
    -- Draw ally lock quando combo está ativo
    if combo_active and locked_ally and Entity.IsAlive(locked_ally) then
        local allyPos = Entity.GetAbsOrigin(locked_ally)
        local radius = 120
        local segments = 32
        for i = 0, segments do
            local angle1 = (math.pi * 2 / segments) * i
            local angle2 = (math.pi * 2 / segments) * (i + 1)
            local p1 = allyPos + Vector(math.cos(angle1) * radius, math.sin(angle1) * radius, 0)
            local p2 = allyPos + Vector(math.cos(angle2) * radius, math.sin(angle2) * radius, 0)
            Renderer.DrawLine3D(p1, p2, 0, 255, 0, 200, 2)
        end
        local screenPos = Renderer.WorldToScreen(allyPos)
        if screenPos then
            Renderer.DrawText(screenPos.x, screenPos.y - 40, "ALLY TARGET", 0, 255, 0, 255, 12, true)
        end
    end
    

    
end

-- ========= ON GAME END =========
function EuphoriaAddon2.OnGameEnd()
    SaveConfig()
    FileLog("Config saved on game end")
end

return EuphoriaAddon2
