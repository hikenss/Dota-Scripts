local TargetLock = {}

-- State
local lockedTarget = nil

-- Find Target Near Cursor (Simple - Uses Engine Function)
function TargetLock.FindTargetSimple()
    local localHero = Heroes.GetLocal()
    if not localHero then return nil end
    
    return Input.GetNearestHeroToCursor(Entity.GetTeamNum(localHero), Enum.TeamType.TEAM_ENEMY)
end

-- Find Targets in Radius
function TargetLock.FindTargetsInRadius(pos, radius)
    local localHero = Heroes.GetLocal()
    if not localHero then return {} end
    
    return Heroes.InRadius(pos, radius, Entity.GetTeamNum(localHero), Enum.TeamType.TEAM_ENEMY) or {}
end

-- Find Target Near Cursor (Advanced - Manual)
function TargetLock.FindTarget(customRange)
    local cursorPos = Input.GetWorldCursorPos()
    local localHero = Heroes.GetLocal()
    
    if not localHero then
        return nil
    end

    local searchRangeMenu = Menu.Find("Heroes", "Hero List", "Settings", "Settings", "Target Selection", "Search Range")
    local searchRange = customRange or (searchRangeMenu and searchRangeMenu:Get()) or 1000
    
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

    lockedTarget = bestTarget
    return bestTarget
end

-- Predict Enemy Position
function TargetLock.PredictPosition(enemy, castDelay, projectileSpeed)
    if not enemy then
        return nil
    end

    local enemyPos = Entity.GetAbsOrigin(enemy)
    
    if not NPC.IsRunning(enemy) then
        return enemyPos
    end

    local forward = Entity.GetAbsRotation(enemy):GetForward():Normalized()
    local moveSpeed = NPC.GetMoveSpeed(enemy)
    
    local localHero = Heroes.GetLocal()
    if not localHero then
        return enemyPos
    end

    local distance = (enemyPos - Entity.GetAbsOrigin(localHero)):Length2D()
    
    local adjustedDelay = castDelay or 0
    
    if projectileSpeed and projectileSpeed > 0 then
        adjustedDelay = adjustedDelay + (distance / projectileSpeed)
    end
    
    adjustedDelay = adjustedDelay * 0.5
    
    return enemyPos + (forward * moveSpeed * adjustedDelay)
end

-- Check Linken's Sphere and Protections
function TargetLock.HasLinken(target)
    if not target then return false end
    
    -- Linken's Sphere
    if NPC.IsLinkensProtected(target) then
        return true
    end
    
    -- Lotus Orb
    if NPC.HasModifier(target, "modifier_item_lotus_orb_active") then
        return true
    end
    
    -- Antimage Spell Shield with Aghs
    local spell_shield = NPC.GetAbility(target, "antimage_spell_shield")
    if spell_shield and Ability.IsReady(spell_shield) then
        if not NPC.HasModifier(target, "modifier_silver_edge_debuff") then
            if NPC.HasModifier(target, "modifier_item_ultimate_scepter") 
                or NPC.HasModifier(target, "modifier_item_ultimate_scepter_consumed") then
                return true
            end
        end
    end
    
    return false
end

-- Check if target is valid (not immune, not invulnerable)
function TargetLock.IsValidTarget(target)
    if not target or not Entity.IsAlive(target) then
        return false
    end
    
    if NPC.IsIllusion(target) then
        return false
    end
    
    if NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
        return false
    end
    
    if NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) then
        return false
    end
    
    if NPC.HasModifier(target, "modifier_invulnerable") then
        return false
    end
    
    return true
end

-- Get Locked Target
function TargetLock.GetLockedTarget()
    return lockedTarget
end

-- Clear Lock
function TargetLock.ClearLock()
    lockedTarget = nil
end

-- Get Best Target (combines simple + validation)
function TargetLock.GetBestTarget()
    local target = TargetLock.FindTargetSimple()
    
    if target and TargetLock.IsValidTarget(target) then
        lockedTarget = target
        return target
    end
    
    return nil
end

-- Draw Target Lock Visual
function TargetLock.DrawTargetLock(target)
    if not target or not Entity.IsAlive(target) then
        return
    end
    
    local localHero = Heroes.GetLocal()
    if not localHero then return end
    
    local heroPos = Entity.GetAbsOrigin(localHero)
    local targetPos = Entity.GetAbsOrigin(target)
    
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
        local targetName = NPC.GetUnitName(target):gsub("npc_dota_hero_", "")
        local hp = Entity.GetHealth(target)
        local maxHp = Entity.GetMaxHealth(target)
        local hpPercent = math.floor((hp / maxHp) * 100)
        
        Renderer.DrawText(screenPos.x, screenPos.y - 30, targetName, 255, 255, 255, 255, 14, true)
        Renderer.DrawText(screenPos.x, screenPos.y - 15, string.format("HP: %d%%", hpPercent), 255, 100, 100, 255, 12, true)
    end
end

return TargetLock
