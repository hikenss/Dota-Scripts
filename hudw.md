local Module = {}

-- Menu Creation
local mainMenu = Menu.Create("Heroes", "Hero List", "Hoodwink", "Hoodwink Combo DLC")
local principalMenu = mainMenu:Create("Principal")

-- Settings
local settings = {}
settings.enabled = principalMenu:Switch("Ativar Script", true, "⚡")
settings.hotkey = principalMenu:Bind("Tecla Combo", Enum.ButtonCode.KEY_NONE)

-- Menu References
local comboKeyMenu = Menu.Find("Heroes", "Hero List", "Hoodwink", "Main Settings", "Hero Settings", "Combo Key")
local searchRangeMenu = Menu.Find("Heroes", "Hero List", "Settings", "Settings", "Target Selection", "Search Range")

-- Constants
local Q_CAST_DELAY = 0.2 + 1.07
local PREDICTION_SPEED = 1300
local W_CAST_DELAY = 0.2 + 1.37
local COMBO_RANGE = 400
local W_OFFSET_DISTANCE = 220

-- State Variables
local savedComboKey = nil
local lastCastTime = 0
local castCooldown = 0.3
local qCastDelay = 0.5
local currentTarget = nil

local comboState = {
    scurry_casted = false,
    w_casted = false,
    q_casted = false,
    combo_activated = false,
    q_cast_start_time = 0,
    qw_conditions_checked = false,
    should_use_main_combo = false
}

-- Get Local Hero
local function GetLocalHero()
    return Heroes.GetLocal()
end

-- Predict Enemy Position
local function PredictPosition(enemy, castDelay)
    if not enemy then
        return nil
    end

    local enemyPos = Entity.GetAbsOrigin(enemy)
    
    if not NPC.IsRunning(enemy) then
        return enemyPos
    end

    local forward = Entity.GetAbsRotation(enemy):GetForward():Normalized()
    local moveSpeed = NPC.GetMoveSpeed(enemy)
    
    local localHero = GetLocalHero()
    if not localHero then
        return enemyPos
    end

    local distance = (enemyPos - Entity.GetAbsOrigin(localHero)):Length2D()
    
    local adjustedDelay = castDelay
    if castDelay == Q_CAST_DELAY then
        adjustedDelay = adjustedDelay + (distance / PREDICTION_SPEED)
    end
    
    adjustedDelay = adjustedDelay * 0.5
    
    return enemyPos + (forward * moveSpeed * adjustedDelay)
end

-- Find Target Near Cursor
local function FindTarget()
    local cursorPos = Input.GetWorldCursorPos()
    local localHero = GetLocalHero()
    
    if not localHero then
        return nil
    end

    local searchRange = (searchRangeMenu and searchRangeMenu:Get()) or 1000
    local bestTarget, bestDistance = nil, searchRange

    for _, hero in pairs(Heroes.GetAll()) do
        if not Entity.IsSameTeam(hero, localHero) 
            and Entity.IsAlive(hero) 
            and not NPC.IsIllusion(hero) then
            
            local distance = (Entity.GetAbsOrigin(hero) - cursorPos):Length2D()
            
            if distance < bestDistance then
                bestDistance = distance
                bestTarget = hero
            end
        end
    end

    return bestTarget
end

-- Check if should use main combo (Q+W not ready or not enough mana)
local function ShouldUseMainCombo(hero)
    local acornShot = NPC.GetAbility(hero, "hoodwink_acorn_shot")
    local bushwhack = NPC.GetAbility(hero, "hoodwink_bushwhack")
    
    if not acornShot or not bushwhack then
        return false
    end

    local currentMana = NPC.GetMana(hero)
    local qManaCost = Ability.GetManaCost(acornShot)
    local wManaCost = Ability.GetManaCost(bushwhack)
    local totalManaCost = qManaCost + wManaCost
    
    local qNotReady = not Ability.IsReady(acornShot)
    local wNotReady = not Ability.IsReady(bushwhack)
    
    return qNotReady or wNotReady or (currentMana < totalManaCost)
end

-- Main Update Function
Module.OnUpdate = function()
    if not settings.enabled:Get() then
        return
    end

    local localHero = GetLocalHero()
    if not localHero 
        or NPC.GetUnitName(localHero) ~= "npc_dota_hero_hoodwink" 
        or not Entity.IsAlive(localHero) then
        return
    end

    -- Get Abilities
    local scurry = NPC.GetAbility(localHero, "hoodwink_scurry")
    local bushwhack = NPC.GetAbility(localHero, "hoodwink_bushwhack")
    local acornShot = NPC.GetAbility(localHero, "hoodwink_acorn_shot")
    
    if not scurry or not bushwhack or not acornShot then
        return
    end

    -- Save original combo key when hotkey is pressed
    if settings.hotkey:IsDown() and not savedComboKey and comboKeyMenu then
        savedComboKey = comboKeyMenu:Get()
    end

    -- Reset state when hotkey is released
    if not settings.hotkey:IsDown() then
        if savedComboKey and comboKeyMenu then
            comboKeyMenu:Set(savedComboKey)
            savedComboKey = nil
        end
        
        currentTarget = nil
        comboState = {
            scurry_casted = false,
            w_casted = false,
            q_casted = false,
            combo_activated = false,
            q_cast_start_time = 0,
            qw_conditions_checked = false,
            should_use_main_combo = false
        }
        return
    end

    -- Check if should use main combo (fallback)
    if not comboState.qw_conditions_checked then
        comboState.should_use_main_combo = ShouldUseMainCombo(localHero)
        comboState.qw_conditions_checked = true
        
        if comboState.should_use_main_combo then
            if comboKeyMenu and not comboState.combo_activated then
                comboKeyMenu:Set(settings.hotkey:Get())
                comboState.combo_activated = true
            end
            return
        end
    end

    -- Cast cooldown check
    local currentTime = GameRules.GetGameTime()
    if (currentTime - lastCastTime) < castCooldown then
        return
    end

    -- Find and process target
    local target = FindTarget()
    currentTarget = target
    if target then
        local predictedPos = PredictPosition(target, Q_CAST_DELAY)
        
        if predictedPos then
            local distanceToTarget = (predictedPos - Entity.GetAbsOrigin(localHero)):Length2D()
            
            -- If target is very close, activate main combo
            if distanceToTarget <= COMBO_RANGE then
                if comboKeyMenu and not comboState.combo_activated then
                    comboKeyMenu:Set(settings.hotkey:Get())
                    comboState.combo_activated = true
                    lastCastTime = currentTime
                end
                return
            end

            local currentDistance = distanceToTarget
            local qCastRange = Ability.GetCastRange(acornShot)

            -- Cast Scurry (E) first
            if not comboState.scurry_casted and Ability.IsCastable(scurry, NPC.GetMana(localHero)) then
                Ability.CastNoTarget(scurry)
                comboState.scurry_casted = true
                lastCastTime = currentTime
                return
            end

            -- If in range, execute combo
            if currentDistance <= qCastRange then
                local wCastPos = predictedPos + ((predictedPos - Entity.GetAbsOrigin(localHero)):Normalized() * W_OFFSET_DISTANCE)

                -- Cast Bushwhack (W)
                if comboState.scurry_casted 
                    and not comboState.w_casted 
                    and Ability.IsCastable(bushwhack, NPC.GetMana(localHero)) then
                    
                    Ability.CastPosition(bushwhack, wCastPos)
                    comboState.w_casted = true
                    lastCastTime = currentTime
                    return
                end

                -- Cast Acorn Shot (Q) with delay
                if comboState.w_casted and not comboState.q_casted then
                    if (currentTime - comboState.q_cast_start_time) > qCastDelay then
                        Ability.CastPosition(acornShot, predictedPos)
                        comboState.q_cast_start_time = currentTime
                        lastCastTime = currentTime
                        comboState.q_cast_started = true
                    end
                end

                -- Activate main combo after Q+W
                if not Ability.IsReady(bushwhack) 
                    and not Ability.IsReady(acornShot) 
                    and comboState.w_casted 
                    and not comboState.q_casted 
                    and comboState.q_cast_started then
                    
                    if not Ability.IsInAbilityPhase(acornShot) then
                        comboState.q_casted = true
                        
                        if comboKeyMenu and not comboState.combo_activated then
                            comboKeyMenu:Set(settings.hotkey:Get())
                            comboState.combo_activated = true
                        end
                    end
                end
            else
                -- Out of range, activate main combo
                if comboKeyMenu and not comboState.combo_activated then
                    comboKeyMenu:Set(settings.hotkey:Get())
                    comboState.combo_activated = true
                    lastCastTime = currentTime
                end
            end
        end
    end
end

-- Draw Function
Module.OnDraw = function()
    if not settings.enabled:Get() or not settings.hotkey:IsDown() then
        return
    end
    
    if not currentTarget or not Entity.IsAlive(currentTarget) then
        return
    end
    
    local localHero = GetLocalHero()
    if not localHero then return end
    
    local heroPos = Entity.GetAbsOrigin(localHero)
    local targetPos = Entity.GetAbsOrigin(currentTarget)
    
    -- Draw line from hero to target
    Renderer.DrawLine3D(heroPos, targetPos, 255, 0, 0, 255, 3)
    
    -- Draw circle around target
    local radius = 150
    local segments = 32
    for i = 0, segments do
        local angle1 = (math.pi * 2 / segments) * i
        local angle2 = (math.pi * 2 / segments) * (i + 1)
        
        local p1 = targetPos + Vector(math.cos(angle1) * radius, math.sin(angle1) * radius, 0)
        local p2 = targetPos + Vector(math.cos(angle2) * radius, math.sin(angle2) * radius, 0)
        
        Renderer.DrawLine3D(p1, p2, 255, 0, 0, 255, 2)
    end
    
    -- Draw target info
    local screenPos = Renderer.WorldToScreen(targetPos)
    if screenPos then
        local targetName = NPC.GetUnitName(currentTarget):gsub("npc_dota_hero_", "")
        local hp = Entity.GetHealth(currentTarget)
        local maxHp = Entity.GetMaxHealth(currentTarget)
        local hpPercent = math.floor((hp / maxHp) * 100)
        
        Renderer.DrawText(screenPos.x, screenPos.y - 30, targetName, 255, 255, 255, 255, 14, true)
        Renderer.DrawText(screenPos.x, screenPos.y - 15, string.format("HP: %d%%", hpPercent), 255, 100, 100, 255, 12, true)
    end
end

return Module
