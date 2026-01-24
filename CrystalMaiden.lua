local CrystalMaiden = {}

local hero_tab = Menu.Create("Heroes", "Hero List", "Crystal Maiden")
local main_settings = hero_tab:Create("Main Settings")
local root = main_settings:Create("Combo")

local Toggle = root:Switch("Enable", false, "\u{f205}")
local ComboKey = root:Bind("Ult Key", Enum.ButtonCode.KEY_1, "\u{f0e7}")
local EscapeGlimmer = root:Switch("Auto Escape Glimmer", false)
local AddBKB = root:Switch("Use BKB", false)
local AddGlimmer = root:Switch("Use Glimmer", false)
local AddShiva = root:Switch("Use Shiva", false)
local DebugMode = root:Switch("Debug", false)

-- Backwards compatibility
CrystalMaiden.AddBKB = AddBKB
CrystalMaiden.AddGlimmer = AddGlimmer
CrystalMaiden.AddShiva = AddShiva

local last_cast_time = 0

function CrystalMaiden.OnUpdate()
    if not Toggle:Get() then
        return
    end

    local MyHero = Heroes.GetLocal()
    if not MyHero or NPC.GetUnitName(MyHero) ~= "npc_dota_hero_crystal_maiden" then
        return
    end
    if not Entity.IsAlive(MyHero) or NPC.IsStunned(MyHero) or NPC.IsSilenced(MyHero) then
        return
    end

    if EscapeGlimmer:Get() then
        if (os.clock() - last_cast_time) <= (10 + 3) then
            local manaCount = NPC.GetMana(MyHero)
            if not manaCount then
                return
            end

            local glimmer = NPC.GetItem(MyHero, "item_glimmer_cape")
            if not glimmer then
                return
            end

            local glimmerManaCost = Ability.GetManaCost(glimmer)
            if not glimmerManaCost then
                return
            end

            if Ability.IsCastable(glimmer, manaCount) and Ability.IsReady(glimmer) then
                Ability.CastTarget(glimmer, MyHero, true)
                return
            end
        end
    end

    if Input.IsKeyDown(ComboKey:Get()) then
        CrystalMaiden.Combo(MyHero)
    end
end

function CrystalMaiden.Combo(MyHero)
    local freezingField = NPC.GetAbility(MyHero, "crystal_maiden_freezing_field")
    local bkb = NPC.GetItem(MyHero, "item_black_king_bar")
    local glimmer = NPC.GetItem(MyHero, "item_glimmer_cape")
    local shiva = NPC.GetItem(MyHero, "item_shivas_guard")

    if not freezingField then
        return
    end

    CrystalMaiden.manaCount = NPC.GetMana(MyHero)
    CrystalMaiden.realManaCount = CrystalMaiden.manaCount
    if not CrystalMaiden.manaCount then
        return
    end

    freezingFieldManaCost = Ability.GetManaCost(freezingField)
    if not freezingFieldManaCost then
        return
    end

    CrystalMaiden.manaCount = CrystalMaiden.manaCount - freezingFieldManaCost
    CrystalMaiden.ManaNeed = CrystalMaiden.GetManaNeed(MyHero, bkb, glimmer, shiva)

    if CrystalMaiden.manaCount >= CrystalMaiden.ManaNeed then
        if bkb and AddBKB:Get() and Ability.IsCastable(bkb, CrystalMaiden.manaCount) and Ability.IsReady(bkb) then
            if DebugMode:Get() then Log.Write("Use BKB") end
            Ability.CastNoTarget(bkb, true)
        end

        if glimmer and AddGlimmer:Get() and Ability.IsCastable(glimmer, CrystalMaiden.manaCount) and Ability.IsReady(glimmer) then
            if DebugMode:Get() then Log.Write("Use Glimmer cape") end
            Ability.CastTarget(glimmer, MyHero, true)
        end

        if shiva and AddShiva:Get() and Ability.IsCastable(shiva, CrystalMaiden.manaCount) and Ability.IsReady(shiva) then
            if DebugMode:Get() then Log.Write("Use Shiva's guard") end
            Ability.CastNoTarget(shiva, true)
        end
    end

    if DebugMode:Get() then Log.Write("Cast Ult") end
    if freezingField and Ability.IsCastable(freezingField, CrystalMaiden.realManaCount) and Ability.IsReady(freezingField) then
        Ability.CastNoTarget(freezingField, true)
        last_cast_time = os.clock()
    end
end

function CrystalMaiden.GetManaNeed(MyHero, bkb, glimmer, shiva)
    local mana = 0

    if bkb and AddBKB:Get() then
        mana = mana + Ability.GetManaCost(bkb)
    end

    if glimmer and AddGlimmer:Get() then
        mana = mana + Ability.GetManaCost(glimmer)
    end

    if shiva and AddShiva:Get() then
        mana = mana + Ability.GetManaCost(shiva)
    end

    return mana
end

return CrystalMaiden

