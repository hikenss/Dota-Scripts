local trollScript = {}
local TrollWarlord = {}

local myHero
local nextToggleTime = 0
local toggleCooldown = 0.4
local predictTime = 1.2

local trackedTarget = nil
local lastTargetTime = 0
local attacking = false

local baseMenu = Menu.Find("Heroes", "Hero List", "Troll Warlord", "Main Settings", "Hero Settings")
local stanceswitch = baseMenu:Switch("Troca Automática de Stance", true)

function trollScript.OnUpdate()
    if not stanceswitch:Get() then return end
    if not attacking then return end
    if GameRules.GetGameTime() < nextToggleTime then return end

    myHero = Heroes.GetLocal()
    if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_troll_warlord" then return end
    if not Entity.IsAlive(myHero) or NPC.IsStunned(myHero) then return end

    local target = trackedTarget
    if not target or not Entity.IsAlive(target) then
        attacking = false
        return
    end

    local attackRange = NPC.GetAttackRange(myHero) + NPC.GetAttackRangeBonus(myHero)
    local inMeleeForm = attackRange < 300

    local trollPos = Entity.GetAbsOrigin(myHero)
    local targetPos = Entity.GetAbsOrigin(target)
    local meleeReach = 150 + NPC.GetHullRadius(myHero) + NPC.GetHullRadius(target)
    local directDistance = (trollPos - targetPos):Length2D()

    if directDistance <= meleeReach + 10 and not inMeleeForm then
        TrollWarlord.SwitchToMelee(myHero)
        Log.Write("⚔ Switching to Melee (close range override)")
        nextToggleTime = GameRules.GetGameTime() + toggleCooldown
        return
    end

    local shouldSwitch, stance = TrollWarlord.ShouldSwitchStance(myHero, target, predictTime, inMeleeForm)
    if shouldSwitch then
        if stance == "melee" then
            TrollWarlord.SwitchToMelee(myHero)
            Log.Write("⚔ Switching to Melee")
        else
            TrollWarlord.SwitchToRanged(myHero)
            Log.Write("🏹 Switching to Ranged")
        end
        nextToggleTime = GameRules.GetGameTime() + toggleCooldown
    end
end

function trollScript.OnPrepareUnitOrders(data)
    if not stanceswitch:Get() then return true end
    if not data or not data.player then return true end

    local npc = Player.GetAssignedHero(data.player)
    if not npc or NPC.GetUnitName(npc) ~= "npc_dota_hero_troll_warlord" then return true end

    local order = data.order

    -- Start attack loop
    if order == Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET and data.target and Entity.IsHero(data.target) then
        trackedTarget = data.target
        lastTargetTime = GameRules.GetGameTime()
        attacking = true
    end

    -- Stop loop on cancel-type orders
    if order == Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION or
        order == Enum.UnitOrder.DOTA_UNIT_ORDER_HOLD_POSITION or
        order == Enum.UnitOrder.DOTA_UNIT_ORDER_CONTINUE then
        attacking = false
        trackedTarget = nil
    end

    return true
end

function TrollWarlord.ShouldSwitchStance(troll, target, time, currentlyMelee)
    local trollMS = NPC.GetMoveSpeed(troll)
    local targetMS = NPC.GetMoveSpeed(target)

    local trollPos = Entity.GetAbsOrigin(troll)
    local targetPos = Entity.GetAbsOrigin(target)
    local currentDistance = (trollPos - targetPos):Length2D()

    local meleeReach = 150
    local buffer = 30

    if currentDistance <= meleeReach + 10 then
        return (not currentlyMelee), "melee"
    end

    local netClosingDistance = trollMS * time

    if trollMS > targetMS and netClosingDistance + meleeReach + buffer >= currentDistance then
        return (not currentlyMelee), "melee"
    else
        return currentlyMelee, "ranged"
    end
end

function TrollWarlord.SwitchToMelee(npc)
    local rage = NPC.GetAbility(npc, "troll_warlord_switch_stance")
    if rage and Ability.IsReady(rage) then Ability.Toggle(rage) end
end

function TrollWarlord.SwitchToRanged(npc)
    local rage = NPC.GetAbility(npc, "troll_warlord_switch_stance")
    if rage and Ability.IsReady(rage) then Ability.Toggle(rage) end
end

return trollScript
