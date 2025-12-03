local ForceStaffEscape = {}

local MenuPath = { "Utility", "ForceStaffEscape" }

ForceStaffEscape.Enable = Menu.AddOptionBool(MenuPath, "Enabled", false)
ForceStaffEscape.ForceStaff = Menu.AddOptionCombo(MenuPath, "Force Staff", { "Use for yourself", "Use to the enemy" }, 0)
ForceStaffEscape.HurricanePike = Menu.AddOptionCombo(MenuPath, "Hurricane Pike", { "Use for yourself", "Use to the enemy" }, 1)

function ForceStaffEscape.OnUnitAnimation(Animation)
    if not Engine.IsInGame() or not Menu.IsEnabled(ForceStaffEscape.Enable) then
        return
    end

    local MyHero = Heroes.GetLocal()
    if not MyHero or not Entity.IsAlive(MyHero) or NPC.IsStunned(MyHero) or NPC.IsSilenced(MyHero) then
        return
    end

    if Animation.unit == nil or Animation.unit == 0 then
        return
    end

    if not NPCs.Contains(Animation.unit) or Entity.IsSameTeam(Animation.unit, myHero) then
        return
    end

    if not Entity.IsHero(Animation.unit) or NPC.IsIllusion(Animation.unit) then
        return
    end

    local MyHero = Heroes.GetLocal()
    if not MyHero then
        return
    end

--    Log.Write(Animation.sequenceName)
    if Animation.sequenceName == "chronosphere_anim" then
        local ForceStaff = NPC.GetItem(MyHero, "item_force_staff", true)
        local HurricanePike = NPC.GetItem(MyHero, "item_hurricane_pike", true)

        if ForceStaff then
            if ForceStaffEscape.UseForceStaff(MyHero, Animation.unit, ForceStaff) then
                return
            end
        end

        if HurricanePike then
            if ForceStaffEscape.UseHurricanePike(MyHero, Animation.unit, HurricanePike) then
                return
            end
        end
    end
end

function ForceStaffEscape.CheckStaffWithTarget(MyHero, Target, Staff)
    local Staff_catsRange = Ability.GetCastRange(Staff)
    if not Staff_catsRange then
        return false
    end

    local Staff_inRange = NPC.IsEntityInRange(MyHero, Target, Staff_catsRange)
    if not Staff_inRange then
        return false
    end

    local Staff_isCastable = Ability.IsCastable(Staff, NPC.GetMana(MyHero))
    if not Staff_isCastable then
        return false
    end

    if Ability.IsReady(Staff) and Staff_inRange and Staff_isCastable then
        return true
    else
        return false
    end
end

function ForceStaffEscape.CheckStaffWithoutTarget(MyHero, Staff)
    local Staff_isCastable = Ability.IsCastable(Staff, NPC.GetMana(MyHero))
    if not Staff_isCastable then
        return false
    end

    if Ability.IsReady(Staff) and Staff_isCastable then
        return true
    else
        return false
    end
end

function ForceStaffEscape.UseForceStaff(MyHero, Target, Staff)
    if Menu.GetValue(ForceStaffEscape.ForceStaff) == 0 then
        if not ForceStaffEscape.CheckStaffWithoutTarget(MyHero, Staff) then
            return false
        end

        Ability.CastNoTarget(Staff)
        Player.HoldPosition(Players.GetLocal(), MyHero)
        return true
    elseif Menu.GetValue(ForceStaffEscape.ForceStaff) == 1 then
        if not ForceStaffEscape.CheckStaffWithTarget(MyHero, Target, Staff) then
            return false
        end

        Ability.CastTarget(Staff, Target)
        Player.HoldPosition(Players.GetLocal(), MyHero)
        return true
    end
end

function ForceStaffEscape.UseHurricanePike(MyHero, Target, Staff)
    if Menu.GetValue(ForceStaffEscape.HurricanePike) == 0 then
        if not ForceStaffEscape.CheckStaffWithoutTarget(MyHero, Staff) then
            return false
        end

        Ability.CastNoTarget(Staff)
        Player.HoldPosition(Players.GetLocal(), MyHero)
        return true
    elseif Menu.GetValue(ForceStaffEscape.HurricanePike) == 1 then
        if not ForceStaffEscape.CheckStaffWithTarget(MyHero, Target, Staff) then
            return false
        end

        Ability.CastTarget(Staff, Target)
        Player.HoldPosition(Players.GetLocal(), MyHero)
        return true
    end
end

return ForceStaffEscape
