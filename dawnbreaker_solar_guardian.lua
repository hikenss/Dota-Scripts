local Dawnbreaker = {}

-- Menu Setup
local hero_tab = Menu.Create("Heroes", "Hero List", "Dawnbreaker")
local main_settings = hero_tab:Create("Main Settings")
local root = main_settings:Create("Auto Solar Guardian")

local Toggle = root:Switch("Enable", false, "\u{f205}")
local AllyToSave = root:Combo("Ally to Save", {"None"}, 0)
local MinAttackers = root:Slider("Min Attackers", 2, 5, 3)
local CheckRadius = root:Slider("Check Radius", 400, 1200, 800)
local DebugMode = root:Switch("Debug", false)

-- Script Variables
local alliesPopulated = false
local allyList = {"None"}

-- Helper Functions
local function populateAllyList(hero)
    if alliesPopulated then return end

    allyList = {"None"}
    local myTeam = Entity.GetTeamNum(hero)
    local allHeroes = Heroes.GetAll()

    for _, ally in pairs(allHeroes) do
        if ally and Entity.GetTeamNum(ally) == myTeam and ally ~= hero then
            table.insert(allyList, NPC.GetUnitName(ally))
        end
    end

    local currentSelection = AllyToSave:Get()
    AllyToSave:Update(allyList, currentSelection)
    alliesPopulated = true
end

-- Main Logic
function Dawnbreaker.OnUpdate()
    if not Toggle:Get() then
        return
    end

    local MyHero = Heroes.GetLocal()
    if not MyHero or NPC.GetUnitName(MyHero) ~= "npc_dota_hero_dawnbreaker" then
        return
    end
    if not Entity.IsAlive(MyHero) then
        return
    end

    populateAllyList(MyHero)

    local solarGuardian = NPC.GetAbility(MyHero, "dawnbreaker_solar_guardian")
    if not solarGuardian or not Ability.IsReady(solarGuardian) then
        return
    end

    local selectedAllyIndex = AllyToSave:Get()
    if selectedAllyIndex == 0 then
        return
    end

    local selectedAllyName = allyList[selectedAllyIndex + 1]
    if not selectedAllyName then return end

    local minAttackers = MinAttackers:Get()
    local checkRadius = CheckRadius:Get()

    local allyHero = nil
    local allHeroes = Heroes.GetAll()
    for _, h in pairs(allHeroes) do
        if h and NPC.GetUnitName(h) == selectedAllyName then
            allyHero = h
            break
        end
    end

    if not allyHero or not Entity.IsAlive(allyHero) then
        return
    end

    local enemiesNear = Entity.GetHeroesInRadius(allyHero, checkRadius, Enum.TeamType.TEAM_ENEMY, true, true)

    if #enemiesNear >= minAttackers then
        if DebugMode:Get() then 
            Log.Write("Casting Solar Guardian on " .. selectedAllyName .. " with " .. #enemiesNear .. " enemies nearby")
        end
        Ability.CastPosition(solarGuardian, Entity.GetAbsOrigin(allyHero))
    end
end

return Dawnbreaker