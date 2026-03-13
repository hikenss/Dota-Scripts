local marci_dlc = {}

-- Log file para debug
local log_file = nil
local function LogToFile(message)
    if not log_file then
        -- Tenta criar na pasta do script
        log_file = io.open("marci_rebound_log.txt", "a")
        if not log_file then
            log_file = io.open("c:\\UB\\scripts\\marci_rebound_log.txt", "a")
        end
    end
    if log_file then
        log_file:write(os.date("%H:%M:%S") .. " " .. message .. "\n")
        log_file:flush()
    end
end

-- Teste inicial
LogToFile("===== Script Marci carregado =====")

local menu = Menu.Create("Heroes", "Hero List", "Marci", "Marci Helper")
local main_group = menu:Create("Main")

-- Rebound Cursor submenu
local rebound_group = menu:Create("Rebound Cursor")

local ui = {}
ui.enabled = main_group:Switch("Ativar Script", true, "\u{f0e7}")
ui.force_staff = main_group:Switch("Interceptar Force Staff", true, "panorama/images/items/force_staff_png.vtex_c")
ui.phoenix_dive = main_group:Switch("Phoenix Icarus Dive", true, "panorama/images/spellicons/phoenix_icarus_dive_png.vtex_c")
ui.techies_blast = main_group:Switch("Techies Blast Off", true, "panorama/images/spellicons/techies_suicide_png.vtex_c")
ui.slark_pounce = main_group:Switch("Slark Pounce", true, "panorama/images/spellicons/slark_pounce_png.vtex_c")
ui.zeus_jump = main_group:Switch("Zeus Heavenly Jump", true, "panorama/images/spellicons/zuus_heavenly_jump_png.vtex_c")
ui.timber_chain = main_group:Switch("Timber Chain", true, "panorama/images/spellicons/shredder_timber_chain_png.vtex_c")
ui.earthshaker_totem = main_group:Switch("ES Enchant Totem (Aghs)", true, "panorama/images/spellicons/earthshaker_enchant_totem_png.vtex_c")
ui.spirit_breaker_charge = main_group:Switch("SB Charge of Darkness", true, "panorama/images/spellicons/spirit_breaker_charge_of_darkness_png.vtex_c")
ui.dispose_range = main_group:Slider("Alcance Máximo de Dispose", 150, 400, 300, function(value) return tostring(value) end)
ui.reaction_time = main_group:Slider("Tempo de Reação (ms)", 0, 300, 50, function(value) return tostring(value) .. "ms" end)
ui.auto_face_target = main_group:Switch("Virar Auto para Alvo", true, "\u{f01e}")
ui.debug_enabled = main_group:Switch("Modo Debug", false, "\u{f188}")
ui.show_notifications = main_group:Switch("Mostrar Notificações", true, "\u{f0f3}")

-- Rebound Cursor UI
ui.rebound_enabled = rebound_group:Switch("Enable Rebound", true, "\u{f00c}")
ui.rebound_enabled:ToolTip("Master toggle for Rebound cursor direction targeting")

ui.rebound_skill = rebound_group:Switch("Rebound (ally jump)", true, "panorama/images/spellicons/marci_companion_run_png.vtex_c")
ui.rebound_skill:ToolTip("Use Rebound skill to jump to nearby allies")

ui.companion_skill = rebound_group:Switch("Companion Run (ally boost)", false, "panorama/images/spellicons/marci_companion_run_png.vtex_c")
ui.companion_skill:ToolTip("Use Companion Run instead of Rebound (if available)")

ui.target_low_hp = rebound_group:Switch("Prioritize Low HP Allies", false, "\u{f1f2}")
ui.target_low_hp:ToolTip("Jump to allies with lower HP first")

ui.cursor_direction = rebound_group:Switch("Cast Direction: Cursor", true, "\u{f1b1}")
ui.cursor_direction:ToolTip("Send second cast towards cursor direction")

-- Modo: Somente Hotkey (desativa auto)
ui.rebound_hotkey_only = rebound_group:Switch("Somente Hotkey", true, "\u{f11c}")
ui.rebound_hotkey_only:ToolTip("Pular apenas quando pressionar a tecla de pulo. Desativa o auto-rebound ao ver aliado.")

-- Hotkey to trigger jump toward cursor
ui.rebound_hotkey = rebound_group:Bind("Tecla de Pulo (Rebound)", Enum.ButtonCode.KEY_V, "\u{f11c}")
ui.rebound_hotkey:ToolTip("Pressione a tecla para pular na direção do cursor usando Rebound")

-- Pending rebound tracker (similar to advanced dodger)
local reboundPending = {
    active = false,
    time = 0,
    castPos = nil
}

-- Track last hotkey state
local lastReboundKeyState = false

local INTERCEPT_CONFIGS = {
    ["modifier_item_forcestaff_active"] = {
        name = "Force Staff",
        ui_key = "force_staff",
        predict_distance = 800,
        cast_delay = 0.1,
        priority = 1
    },
    ["modifier_phoenix_icarus_dive"] = {
        name = "Phoenix Dive",
        ui_key = "phoenix_dive",
        predict_distance = 600,
        cast_delay = 0.05,
        priority = 2
    },
    ["modifier_techies_suicide_leap"] = {
        name = "Techies Blast Off",
        ui_key = "techies_blast",
        predict_distance = 600,
        cast_delay = 0,
        priority = 3,
        intercept_trajectory = true
    },
    ["modifier_slark_pounce"] = {
        name = "Slark Pounce",
        ui_key = "slark_pounce",
        predict_distance = 700,
        cast_delay = 0,
        priority = 3
    },
    ["modifier_zuus_heavenly_jump"] = {
        name = "Zeus Heavenly Jump",
        ui_key = "zeus_jump",
        predict_distance = 800,
        cast_delay = 0.4,
        priority = 3
    },
    ["modifier_shredder_timber_chain"] = {
        name = "Timber Chain",
        ui_key = "timber_chain",
        predict_distance = 1200,
        cast_delay = 0.05,
        priority = 2,
        intercept_trajectory = true
    },
    ["modifier_spirit_breaker_charge_of_darkness"] = {
        name = "SB Charge",
        ui_key = "spirit_breaker_charge",
        predict_distance = 1500,
        cast_delay = 0.1,
        priority = 2,
        intercept_trajectory = true
    }
}

local my_hero = nil
local dispose_ability = nil
local last_dispose_time = 0
local active_targets = {}

local function get_local_hero()
    return Heroes.GetLocal()
end

local function initialize_marci()
    my_hero = get_local_hero()
    if not my_hero or NPC.GetUnitName(my_hero) ~= "npc_dota_hero_marci" then
        return false
    end
    dispose_ability = NPC.GetAbility(my_hero, "marci_grapple")
    -- dispose_ability pode ser nil; Rebound não depende disso
    return true
end

local function check_earthshaker_aghs_totem(entity)
    if not entity or NPC.GetUnitName(entity) ~= "npc_dota_hero_earthshaker" then
        return false
    end
    local aghs_item = NPC.GetItem(entity, "item_ultimate_scepter")
    if not aghs_item then
        if not NPC.HasModifier(entity, "modifier_item_ultimate_scepter_consumed") then
            return false
        end
    end
    return true
end

local function quick_predict_position(target, config)
    if not target or not Entity.IsAlive(target) then
        return nil
    end
    local current_pos = Entity.GetAbsOrigin(target)
    if not NPC.IsRunning(target) then
        return current_pos
    end
    local rotation = Entity.GetAbsRotation(target)
    local forward = rotation:GetForward():Normalized()
    local velocity = Entity.GetVelocity(target)
    if string.find(config.name, "Phoenix") then
        return current_pos + (forward * 600)
    end
    if string.find(config.name, "Spirit Breaker") or string.find(config.name, "SB Charge") then
        return current_pos + (forward * config.predict_distance * 0.6) + (velocity * 0.2)
    end
    if string.find(config.name, "Timber Chain") then
        return current_pos + (forward * config.predict_distance * 0.5) + (velocity * 0.15)
    end
    if string.find(config.name, "Force Staff") then
        return current_pos + (forward * config.predict_distance * 0.4) + (velocity * 0.1)
    end
    if string.find(config.name, "Zeus") then
        return current_pos + (forward * config.predict_distance * 0.5)
    end
    return current_pos + (forward * config.predict_distance * 0.3)
end

local function can_use_dispose()
    if not dispose_ability or not my_hero then
        return false
    end
    if not Ability.IsCastable(dispose_ability, NPC.GetMana(my_hero)) then
        return false
    end
    local current_time = GameRules.GetGameTime()
    local reaction_delay = ui.reaction_time:Get() / 1000.0
    if current_time - last_dispose_time < reaction_delay then
        return false
    end
    return true
end

local function execute_dispose_on_target(target, config, custom_pos)
    if not can_use_dispose() then
        return false
    end
    local my_pos = Entity.GetAbsOrigin(my_hero)
    local target_pos = custom_pos or quick_predict_position(target, config) or Entity.GetAbsOrigin(target)
    local distance = (target_pos - my_pos):Length2D()
    local max_range = ui.dispose_range:Get()
    if ui.debug_enabled:Get() then
        print(string.format("Dispose attempt: %s, distance: %d, max: %d", config.name, math.floor(distance), max_range))
    end
    if distance > max_range then
        if ui.debug_enabled:Get() then
            print("Target too far for Dispose")
        end
        return false
    end
    if ui.auto_face_target:Get() then
        Player.PrepareUnitOrders(
            Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            nil,
            target_pos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
            my_hero
        )
    end
    Ability.CastTarget(dispose_ability, target)
    last_dispose_time = GameRules.GetGameTime()
    if ui.show_notifications:Get() then
        print(string.format("Dispose used on %s (%s) - %dm", NPC.GetUnitName(target), config.name, math.floor(distance)))
    end
    return true
end

local function is_target_in_dispose_range(target)
    if not target or not Entity.IsAlive(target) or not my_hero then
        return false
    end
    local my_pos = Entity.GetAbsOrigin(my_hero)
    local target_pos = Entity.GetAbsOrigin(target)
    local distance = (target_pos - my_pos):Length2D()
    return distance <= ui.dispose_range:Get()
end

-- Rebound Cursor Functions
local function FindNearestAllyHero(myHero, myPos, range, cursorPos, cursorInfluence)
    local bestAlly = nil
    local bestScore = math.huge
    local bestHPPercent = 1.0
    
    local allHeroes = Heroes.GetAll()
    for _, ally in pairs(allHeroes) do
        if ally and Entity.IsAlive(ally) and Entity.IsSameTeam(myHero, ally) and ally ~= myHero then
            if not NPC.IsIllusion(ally) then
                local allyPos = Entity.GetAbsOrigin(ally)
                local distToAlly = (allyPos - myPos):Length()
                
                -- Check range
                if distToAlly <= range then
                    local hpPercent = Entity.GetHealth(ally) / Entity.GetMaxHealth(ally)
                    
                    -- If targeting low HP: prioritize by HP first, then by distance
                    if ui.target_low_hp:Get() then
                        -- First priority: lowest HP percentage
                        if hpPercent < bestHPPercent then
                            bestHPPercent = hpPercent
                            bestScore = distToAlly
                            bestAlly = ally
                        -- If HP similar, use distance as tiebreaker
                        elseif math.abs(hpPercent - bestHPPercent) < 0.05 and distToAlly < bestScore then
                            bestScore = distToAlly
                            bestAlly = ally
                        end
                    else
                        -- Normal mode: distance only (with cursor influence)
                        local score = distToAlly
                        
                        -- Apply cursor influence
                        if cursorPos and cursorInfluence > 0 then
                            local distToCursor = (allyPos - cursorPos):Length()
                            score = (distToAlly * (100 - cursorInfluence) + distToCursor * cursorInfluence) / 100
                        end
                        
                        if score < bestScore then
                            bestScore = score
                            bestAlly = ally
                            bestHPPercent = hpPercent
                        end
                    end
                end
            end
        end
    end
    
    return bestAlly
end

function marci_dlc.OnModifierCreate(entity, modifier)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    local mod_name = Modifier.GetName(modifier)
    local config = INTERCEPT_CONFIGS[mod_name]
    if not config or not ui[config.ui_key]:Get() then
        return
    end
    if ui.debug_enabled:Get() then
        print("Modifier detected: " .. mod_name .. " on " .. NPC.GetUnitName(entity))
    end
    if config.name == "Force Staff" then
        if not entity or Entity.IsSameTeam(entity, my_hero) then
            return
        end
    end
    if not entity or not Entity.IsAlive(entity) or Entity.IsSameTeam(entity, my_hero) then
        return
    end
    if config.name == "Techies Blast Off" and NPC.GetUnitName(entity) == "npc_dota_hero_techies" then
        local entity_id = Entity.GetIndex(entity)
        active_targets[entity_id] = {
            entity = entity,
            config = config,
            start_time = GameRules.GetGameTime(),
            modifier = modifier
        }
        if ui.debug_enabled:Get() then
            print("Techies added to active tracking: " .. entity_id)
        end
        return
    end
    execute_dispose_on_target(entity, config)
end

function marci_dlc.OnModifierDestroy(entity, modifier)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    local mod_name = Modifier.GetName(modifier)
    if mod_name == "modifier_techies_suicide_leap" then
        local entity_id = Entity.GetIndex(entity)
        if active_targets[entity_id] then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Techies removed from tracking: " .. entity_id)
            end
        end
    end
end

function marci_dlc.OnPrepareUnitOrders(order)
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    if not ui.earthshaker_totem:Get() then
        return
    end
    if order.ability and Ability.GetName(order.ability) == "earthshaker_enchant_totem" then
        local caster = order.npc
        if not caster or not Entity.IsAlive(caster) or Entity.IsSameTeam(caster, my_hero) then
            return
        end
        if not check_earthshaker_aghs_totem(caster) then
            if ui.debug_enabled:Get() then
                print("Earthshaker without Aghanim's Scepter - skipping")
            end
            return
        end
        if ui.debug_enabled:Get() then
            print("Earthshaker Enchant Totem with Aghs detected!")
        end
        local es_pos = Entity.GetAbsOrigin(caster)
        local my_pos = Entity.GetAbsOrigin(my_hero)
        local distance = (es_pos - my_pos):Length2D()
        if distance <= 900 then
            execute_dispose_on_target(caster, {
                name = "Earthshaker Aghs Totem",
                predict_distance = 200,
                priority = 3
            })
        end
    end
end

function marci_dlc.OnUpdate()
    if not ui.enabled:Get() or not initialize_marci() then
        return
    end
    
    local currentTime = GameRules.GetGameTime()
    local myPos = Entity.GetAbsOrigin(my_hero)
    local myMana = NPC.GetMana(my_hero)
    local cursorPos = Input.GetWorldCursorPos()

    -- Hotkey-triggered Rebound toward cursor (prioritize allies only)
    local keyPressed = ui.rebound_hotkey:IsDown()
    
    if keyPressed and not lastReboundKeyState then
        local status = "INICIO"
        
        -- Tenta pegar companion_run primeiro, depois rebound
        local companionRun = NPC.GetAbility(my_hero, "marci_companion_run")
        local rebound = NPC.GetAbility(my_hero, "marci_rebound")
        
        local activeSkill = nil
        if companionRun and not Ability.IsHidden(companionRun) then
            activeSkill = companionRun
        elseif rebound and not Ability.IsHidden(rebound) then
            activeSkill = rebound
        end
        
        if not activeSkill then
            status = "SEM_SKILL"
        elseif not Ability.IsCastable(activeSkill, myMana) then
            status = "NAO_CASTAVEL"
        else
            local range = 700
            local cursorInfluence = 70
            local targetAlly = FindNearestAllyHero(my_hero, myPos, range, cursorPos, cursorInfluence)
            
            if targetAlly then
                status = "OK"
                Ability.CastTarget(activeSkill, targetAlly)
                if ui.cursor_direction:Get() then
                    local targetPos = Entity.GetAbsOrigin(targetAlly)
                    local myTeam = Entity.GetTeamNum(my_hero)
                    local fountainPos
                    
                    -- Radiant (team 2) ou Dire (team 3)
                    if myTeam == 2 then
                        fountainPos = Vector(-7000, -6500, 384)  -- Fonte Radiant
                    else
                        fountainPos = Vector(7000, 6500, 384)    -- Fonte Dire
                    end
                    
                    -- Direção do alvo para a fonte
                    local dirToFountain = (fountainPos - targetPos):Normalized()
                    local castPos = targetPos + dirToFountain * 800
                    
                    reboundPending = { active = true, time = currentTime, castPos = castPos }
                end
            else
                status = "SEM_ALIADO"
            end
        end
        
        lastReboundKeyState = keyPressed
    end
    
    lastReboundKeyState = keyPressed
    
    -- Handle pending rebound direction cast
    if reboundPending.active then
        local elapsed = currentTime - reboundPending.time
        
        -- Timeout after 0.5 seconds
        if elapsed >= 0.5 then
            reboundPending.active = false
        -- Send direction after delay
        elseif elapsed >= 0.08 then
            if reboundPending.castPos then
                local rebound = NPC.GetAbility(my_hero, "marci_rebound")
                local companionRun = NPC.GetAbility(my_hero, "marci_companion_run")
                
                local activeSkill = nil
                if companionRun and not Ability.IsHidden(companionRun) then
                    activeSkill = companionRun
                elseif rebound and not Ability.IsHidden(rebound) then
                    activeSkill = rebound
                end
                
                if activeSkill then
                    Ability.CastPosition(activeSkill, reboundPending.castPos)
                end
            end
            
            reboundPending.active = false
        end
        return
    end
    
    -- Rebound Cursor Logic (auto) - só roda se Somente Hotkey estiver DESLIGADO
    if ui.rebound_enabled:Get() and not ui.rebound_hotkey_only:Get() then
        -- myPos, myMana, cursorPos already computed above
        
        -- Try to cast Rebound
        if ui.rebound_skill:Get() then
            local rebound = NPC.GetAbility(my_hero, "marci_rebound")
            
            if rebound and not Ability.IsHidden(rebound) and Ability.IsCastable(rebound, myMana) then
                local range = 700  -- Fixo
                local cursorInfluence = 70  -- Fixo
                
                -- Find nearest ally
                local targetAlly = FindNearestAllyHero(my_hero, myPos, range, cursorPos, cursorInfluence)
                
                if targetAlly then
                    -- Cast on ally
                    Ability.CastTarget(rebound, targetAlly)
                    
                    -- Calculate direction for second cast (towards cursor)
                    if ui.cursor_direction:Get() then
                        local targetPos = Entity.GetAbsOrigin(targetAlly)
                        local safeDistance = 600  -- Fixo
                        
                        -- Direction from target towards cursor
                        local dirToCursor = (cursorPos - targetPos):Normalized()
                        local castPos = targetPos + dirToCursor * safeDistance
                        
                        -- Mark pending for direction cast
                        reboundPending = {
                            active = true,
                            time = currentTime,
                            castPos = castPos
                        }
                    end
                    
                    return
                end
            end
        end
        
        -- Try to cast Companion Run
        if ui.companion_skill:Get() then
            local companionRun = NPC.GetAbility(my_hero, "marci_companion_run")
            
            if companionRun and not Ability.IsHidden(companionRun) and Ability.IsCastable(companionRun, myMana) then
                local range = 1050  -- Fixo
                local cursorInfluence = 70  -- Fixo
                
                -- Find nearest ally
                local targetAlly = FindNearestAllyHero(my_hero, myPos, range, cursorPos, cursorInfluence)
                
                if targetAlly then
                    -- Cast on ally
                    Ability.CastTarget(companionRun, targetAlly)
                    
                    -- Calculate direction for second cast (towards cursor)
                    if ui.cursor_direction:Get() then
                        local targetPos = Entity.GetAbsOrigin(targetAlly)
                        local safeDistance = 600  -- Fixo
                        
                        -- Direction from target towards cursor
                        local dirToCursor = (cursorPos - targetPos):Normalized()
                        local castPos = targetPos + dirToCursor * safeDistance
                        
                        -- Mark pending for direction cast
                        reboundPending = {
                            active = true,
                            time = currentTime,
                            castPos = castPos
                        }
                    end
                    
                    return
                end
            end
        end
    end
    
    local current_time = GameRules.GetGameTime()
    for entity_id, target_data in pairs(active_targets) do
        local entity = target_data.entity
        if not entity or not Entity.IsAlive(entity) then
            active_targets[entity_id] = nil
            goto continue
        end
        if not NPC.HasModifier(entity, "modifier_techies_suicide_leap") then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Techies modifier disappeared, removing from tracking")
            end
            goto continue
        end
        if is_target_in_dispose_range(entity) then
            if ui.debug_enabled:Get() then
                print("Techies in Dispose range! Executing intercept")
            end
            if execute_dispose_on_target(entity, target_data.config) then
                active_targets[entity_id] = nil
            end
        else
            if ui.debug_enabled:Get() then
                local my_pos = Entity.GetAbsOrigin(my_hero)
                local target_pos = Entity.GetAbsOrigin(entity)
                local distance = (target_pos - my_pos):Length2D()
                print(string.format("Techies tracked: distance %d, need %d", math.floor(distance), ui.dispose_range:Get()))
            end
        end
        if current_time - target_data.start_time > 10.0 then
            active_targets[entity_id] = nil
            if ui.debug_enabled:Get() then
                print("Removing outdated target from tracking")
            end
        end
        ::continue::
    end
end

return marci_dlc