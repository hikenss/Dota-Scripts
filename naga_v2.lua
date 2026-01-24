--[[
        ~ naga siren illusions auto-controller - HYESOSSEXXER
            Também um grande obrigado ao vetram pela base
]]

local NagaTools = {}

-- general check
local function IsNagaSiren()
    local myHero = Heroes.GetLocal()
    return myHero and NPC.GetUnitName(myHero) == "npc_dota_hero_naga_siren"
end

local Config = {
    UI = {
        TabName = "Heroes",
        ScriptName = "Hero List",
        ScriptID = "Naga Siren",
        Icons = {
            Main = "\u{f6b6}",
            Rush = "\u{f554}",
            Bait = "\u{f06a}"
        },
        Groups = {
            Main = "Main",
            Illusions = "Illusions",
            Settings = "Settings",
            AutoBait = "AutoBait",
            AutoFollow = "AutoFollow",
            AutoChase = "AutoChase",
            AutoSplit = "AutoSplit",
            RunAway = "RunAway",
            Surround = "Surround"
        }
    },
    Colors = {
        Text = {
            Primary = Color(255, 255, 255),
            Shadow = Color(0, 0, 0)
        }
    },
    Fonts = {
        Main = Render.LoadFont("SF Pro Text", Enum.FontCreate.FONTFLAG_ANTIALIAS)
    },
    Retreat = {
        MinTriggerDist = 310,
        MinRetreat = 120,
        MaxRetreat = 390
    },
    Bait = {
        HPThreshold = 0.5,
        MaxBaiting = 2,
        Interval = 3,
        MinIllusions = 2,
        WRadius = 750,
        WBaitCount = 1,
        WBaitInterval = 0.5
    },
    Follow = {
        Enabled = true,
        Count = 2,
        MinRadius = 200,
        MaxRadius = 400
    },
    Surround = {
        BlockDuration = 1.5,
        AttackDelay = 0.3,
        SurroundRadius = 100
    }
}

local function InitializeUI()
    local tab = Menu.Create(Config.UI.TabName, Config.UI.ScriptName, Config.UI.ScriptID)
    local mainSettings = tab:Create("Main Settings")
    local mainGroup = mainSettings:Create(Config.UI.Groups.Main)
    local illusionGroup = mainSettings:Create(Config.UI.Groups.Illusions)
    local settingsGroup = mainSettings:Create(Config.UI.Groups.Settings)
    local baitGroup = mainSettings:Create(Config.UI.Groups.AutoBait)
    local followGroup = mainSettings:Create(Config.UI.Groups.AutoFollow)
    local chaseGroup = mainSettings:Create(Config.UI.Groups.AutoChase)
    local splitGroup = mainSettings:Create(Config.UI.Groups.AutoSplit)
    local runAwayGroup = mainSettings:Create(Config.UI.Groups.RunAway)
    local surroundGroup = mainSettings:Create(Config.UI.Groups.Surround)
    return {
        AutoRush = {
            Enabled = mainGroup:Switch("Mirror Image automático para ilusões", true, Config.UI.Icons.Rush),
            DisableRushOnFarm = mainGroup:Switch("Desativar auto-ataque ao farmar creeps", false)
        },
        Visuals = {
            StatusText = illusionGroup:Switch("Mostrar status", true)
        },
        Settings = {
            MinTriggerDist = settingsGroup:Slider("Distância para acionar Rush", 300, 600, Config.Retreat.MinTriggerDist, "%d"),
            MinRetreat = settingsGroup:Slider("Retirada mínima", 50, 300, Config.Retreat.MinRetreat, "%d"),
            MaxRetreat = settingsGroup:Slider("Retirada máxima", 300, 900, Config.Retreat.MaxRetreat, "%d"),
            RushSpeedThreshold = settingsGroup:Slider("Limiar de velocidade para atacar", 250, 600, 300, "%d"),
            PlayerOverrideSec = settingsGroup:Slider("Pausa de controle após ordem do jogador (s)", 0.0, 5.0, 1.5, "%.1f"),
        },
        RunAway = {
            HoldKey = runAwayGroup:Bind("Tecla de bait", Enum.ButtonCode.KEY_NONE),
            KeepCount = runAwayGroup:Slider("Quantidade de ilusões ao redor da Naga real", 0, 6, 2, "%d"),
            Duration = runAwayGroup:Slider("Duração da fuga das ilusões (s)", 0.5, 5.0, 2.0, "%.1f")
        },
        AutoBait = {
            Enabled = baitGroup:Switch("Ativar auto-bait", true, Config.UI.Icons.Bait),
            HPThreshold = baitGroup:Slider("Limiar de HP da ilusão (%)", 10, 90, math.floor(Config.Bait.HPThreshold * 100), "%d%%"),
            MaxBaiting = baitGroup:Slider("Máx. ilusões fazendo bait", 1, 5, Config.Bait.MaxBaiting, "%d"),
            Interval = baitGroup:Slider("Intervalo entre baits (s)", 1, 10, Config.Bait.Interval, "%d"),
            MinIllusions = baitGroup:Slider("Mín. ilusões para bait", 2, 6, Config.Bait.MinIllusions, "%d"),
            WRadius = baitGroup:Slider("Raio do inimigo para W-bait", 400, 1200, Config.Bait.WRadius, "%d"),
            WBaitCount = baitGroup:Slider("Ilusões baitando após W", 1, 5, Config.Bait.WBaitCount, "%d"),
            WBaitInterval = baitGroup:Slider("Intervalo do W-bait (s)", 0, 2, Config.Bait.WBaitInterval, "%.1f")
        },
        AutoFollow = {
            Enabled = followGroup:Switch("Ativar auto-follow", true),
            Count = followGroup:Slider("Quantidade de ilusões para follow", 1, 3, Config.Follow.Count, "%d"),
            MinRadius = followGroup:Slider("Raio mín. de follow", 100, 350, Config.Follow.MinRadius, "%d"),
            MaxRadius = followGroup:Slider("Raio máx. de follow", 200, 600, Config.Follow.MaxRadius, "%d")
        },
        AutoChase = {
            Enabled = chaseGroup:Switch("Ativar auto-chase", true),
            Radius = chaseGroup:Slider("Raio do auto-chase", 1500, 6000, 1600, "%d")
        },
        AutoBodyblock = {
            Enabled = illusionGroup:Switch("Ativar auto-bodyblock", true),
            PingThreshold = illusionGroup:Slider("Limiar de ping para bodyblock", 50, 300, 150, "%d"),
            ForceBodyblockKey = illusionGroup:Bind("Tecla de bodyblock", Enum.ButtonCode.KEY_NONE)
        },
        AutoSplit = {
            Enabled = splitGroup:Switch("Ativar auto-split ataque", true),
            MaxIllusionsPerTarget = splitGroup:Slider("Máx. ilusões por alvo", 3, 12, 8, "%d"),
            SplitCount = splitGroup:Slider("Quantidade de ilusões para redirecionar", 1, 5, 2, "%d"),
            SearchRadius = splitGroup:Slider("Raio de busca de alvos", 800, 2000, 1200, "%d"),
            MinEnemies = splitGroup:Slider("Mín. inimigos para ativar", 2, 5, 2, "%d")
        },
        Surround = {
            Enabled = surroundGroup:Switch("Ativar cercar inimigo", true),
            TriggerKey = surroundGroup:Bind("Tecla de cercar", Enum.ButtonCode.KEY_NONE),
            BlockDuration = surroundGroup:Slider("Duração do bloqueio (s)", 0.5, 3.0, Config.Surround.BlockDuration, "%.1f"),
            AttackDelay = surroundGroup:Slider("Atraso de ataque (s)", 0.0, 1.0, Config.Surround.AttackDelay, "%.1f"),
            SurroundRadius = surroundGroup:Slider("Raio de cercar", 50, 300, Config.Surround.SurroundRadius, "%d")
        },

    }
end

local UI = InitializeUI()


if Config.Fonts.Main then
    Log.Write("[debug] sfproloaded")
else
    Log.Write("[debug] fallback font")
end

followRole = {}
followLastOrder = followLastOrder or {}

playerOverrideRole = playerOverrideRole or {}
playerOverrideUntil = playerOverrideUntil or {}
playerOverrideDuration = playerOverrideDuration or 1.5

function PlayerOverrideDuration(second)
    if type(second) == "number" and second >= 0 then
        playerOverrideDuration = second
    end
end

runawayRole = runawayRole or {}
runawayLastOrder = runawayLastOrder or {}
runawayActive = runawayActive or false
runawayBaseAngle = runawayBaseAngle or 0
runawayKeepRole = runawayKeepRole or {}
runawayUntil = runawayUntil or {}

surroundRole = surroundRole or {}
surroundState = surroundState or {}
surroundTarget = surroundTarget or nil
surroundStartTime = surroundStartTime or 0
surroundPhase = surroundPhase or "idle" -- idle, positioning, blocking, attacking

local function IsIllusionUnderPlayerOverride(illusion)
    local id = Entity.GetIndex(illusion)
    local untilTime = playerOverrideUntil[id]
    return untilTime and os.clock() < untilTime
end

local function GetControllableNagaIllusions()
    local illusions = GetAllNagaIllusions()
    local result = {}
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if not IsIllusionUnderPlayerOverride(illusion) and not (runawayRole and runawayRole[id]) and not (surroundRole and surroundRole[id]) then
            table.insert(result, illusion)
        end
    end
    return result
end

local function CleanupPlayerOverride()
    local now = os.clock()
    for id, t in pairs(playerOverrideUntil) do
        if now >= t then
            playerOverrideUntil[id] = nil
            playerOverrideRole[id] = nil
        end
    end
    local alive = {}
    for _, illu in ipairs(GetAllNagaIllusions()) do
        alive[Entity.GetIndex(illu)] = true
    end
    for id, _ in pairs(playerOverrideRole) do
        if not alive[id] then
            playerOverrideRole[id] = nil
            playerOverrideUntil[id] = nil
        end
    end
end

function AutoFollowIllusions()
    if not UI.AutoFollow.Enabled:Get() then return end
    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero or #illusions == 0 then return end
    local now = os.clock()
    local enemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
    if #enemies > 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            followRole[id] = nil
        end
        return
    end
    local freeIllusions = {}
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if priorityRole and priorityRole[id] then
            followRole[id] = nil
        elseif not (IsIllusionBaiting and IsIllusionBaiting(id)) and not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and not (farmRole and farmRole[id]) and not (chaseRole and chaseRole[id]) and not (splitRole and splitRole[id]) and not (surroundRole and surroundRole[id]) then
            table.insert(freeIllusions, illusion)
        else
            followRole[id] = nil
        end
    end
    local count = UI.AutoFollow.Count:Get()
    if #freeIllusions < count then count = #freeIllusions end
    local selected = {}
    while #selected < count and #freeIllusions > 0 do
        local idx = math.random(1, #freeIllusions)
        local illusion = freeIllusions[idx]
        local id = Entity.GetIndex(illusion)
        followRole[id] = true
        table.insert(selected, illusion)
        table.remove(freeIllusions, idx)
    end
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        local found = false
        for _, sel in ipairs(selected) do
            if Entity.GetIndex(sel) == id then found = true break end
        end
        if not found then
            followRole[id] = nil
        end
    end
    for _, illusion in ipairs(selected) do
        local id = Entity.GetIndex(illusion)
        if not followLastOrder[id] or (now - followLastOrder[id] > math.random(7,12)/10) then
            local heroPos = Entity.GetAbsOrigin(myHero)
            local minR = UI.AutoFollow.MinRadius:Get()
            local maxR = UI.AutoFollow.MaxRadius:Get()
            local angle = math.rad(math.random(0,359))
            local dist = math.random(minR, maxR)
            local offset = Vector(math.cos(angle), math.sin(angle), 0) * dist
            local targetPos = heroPos + offset
            Player.PrepareUnitOrders(
                Players.GetLocal(),
                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                nil,
                targetPos,
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                illusion,
                false,
                false,
                false,
                false,
                "naga_illusion_follow"
            )
            followLastOrder[id] = now
        end
    end
end

local function IsNagaIllusion(npc)
    return NPC.IsIllusion(npc) and NPC.GetUnitName(npc) == "npc_dota_hero_naga_siren"
end

function GetAllNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero then return {} end
    local playerId = Hero.GetPlayerID(myHero)
    local allNPCs = NPCs.GetAll()
    local result = {}
    for _, npc in ipairs(allNPCs) do
        if IsNagaIllusion(npc) and Entity.IsControllableByPlayer(npc, playerId) and Entity.IsAlive(npc) then
            table.insert(result, npc)
        end
    end
    return result
end

local function FindNearestEnemy(npc, radius)
    local enemies = Entity.GetHeroesInRadius(npc, radius or 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
    local minDist, nearest = math.huge, nil
    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) then
            local dist = (Entity.GetAbsOrigin(npc) - Entity.GetAbsOrigin(enemy)):Length()
            if dist < minDist then
                minDist = dist
                nearest = enemy
            end
        end
    end
    return nearest
end

local function GetAttackRange(npc)
    return (NPC.GetAttackRange and NPC.GetAttackRange(npc) or 150) + (NPC.GetAttackRangeBonus and NPC.GetAttackRangeBonus(npc) or 0)
end

-- retreat distance aka retirada
local function CalcRD(startDist, minTriggerDist, minRetreat, maxRetreat)
    if startDist >= minTriggerDist then
        return minRetreat
    else
        local need = minTriggerDist - startDist + minRetreat
        if need > maxRetreat then
            return maxRetreat
        end
        return need
    end
end

local function FindRD(illusion, enemy, distance)
    local illuPos = Entity.GetAbsOrigin(illusion)
    local enemyPos = Entity.GetAbsOrigin(enemy)
    local dir = (illuPos - enemyPos):Normalized()
    local pos = illuPos + dir * distance
    return pos, (pos - illuPos):Length(), "ok"
end

local illusionOrderTimestamps = {}

local function HasMirrorImageModifier(npc)
    return false -- Naga illusions don't have special modifiers like PL
end

local illusionStates = {}

local function FindNearestCreep(npc, radius)
    local myHero = Heroes.GetLocal()
    local allNPCs = NPCs.GetAll()
    local illuPos = Entity.GetAbsOrigin(npc)
    local minDist, nearest = math.huge, nil
    for _, creep in ipairs(allNPCs) do
        if Entity.IsAlive(creep) and not Entity.IsDormant(creep) and Entity.GetTeamNum(creep) ~= Entity.GetTeamNum(myHero) then
            local name = NPC.GetUnitName(creep)
            if name and (string.find(name, "creep") or string.find(name, "neutral") or string.find(name, "siege") or string.find(name, "mega") or NPC.IsRoshan(creep)) then
                local dist = (illuPos - Entity.GetAbsOrigin(creep)):Length()
                if dist < minDist and dist < (radius or 1200) then
                    minDist = dist
                    nearest = creep
                end
            end
        end
    end
    return nearest
end

function AutoMirrorImageForIllusions()
    if not UI.AutoRush.Enabled:Get() then return end
    local illusions = GetControllableNagaIllusions()
    local player = Players.GetLocal and Players.GetLocal() or nil
    local now = GameRules.GetGameTime()
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if (IsIllusionBaiting and IsIllusionBaiting(id)) or (IsIllusionWbaiting and IsIllusionWbaiting(id)) or (splitRole and splitRole[id]) or (surroundRole and surroundRole[id]) or (UI.AutoRush.DisableRushOnFarm:Get() and farmRole and farmRole[id]) then
            goto continue
        end
        local state = illusionStates[id] and illusionStates[id].state or nil
        if HasMirrorImageModifier(illusion) then
            illusionStates[id] = {state = "done"}
            goto continue
        end
        if not illusionStates[id] then
            local target = FindNearestEnemy(illusion, 1200)

            if myHero then
                local heroTarget = Entity.GetAttackTarget and Entity.GetAttackTarget(myHero)
                if heroTarget and Entity.IsAlive(heroTarget) and not NPC.IsRunning(heroTarget) then
                    target = heroTarget
                end
            end
            if not target and farmRole and farmRole[id] and not UI.AutoRush.DisableRushOnFarm:Get() then
                target = FindNearestCreep(illusion, 1200)
            end

            local speedThreshold = UI.Settings.RushSpeedThreshold:Get()
            if target and NPC.GetMoveSpeed and NPC.GetMoveSpeed(illusion) < speedThreshold then
                target = nil
            end
            if target then
                if NPC.IsRunning and NPC.IsRunning(target) then
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        target,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_autoattack_moving"
                    )
                    illusionStates[id] = {state = "attacking", time = now, target = target}
                else
                    local illuPos = Entity.GetAbsOrigin(illusion)
                    local enemyPos = Entity.GetAbsOrigin(target)
                    local startDist = (illuPos - enemyPos):Length()
                    local minTriggerDist = UI.Settings.MinTriggerDist:Get()
                    local minRetreat = UI.Settings.MinRetreat:Get()
                    local maxRetreat = UI.Settings.MaxRetreat:Get()
                    local maxFinalDist = 350
                    local retreatDist = CalcRD(startDist, minTriggerDist, minRetreat, maxRetreat)
                    if startDist + retreatDist > maxFinalDist then
                        retreatDist = maxFinalDist - startDist
                        if retreatDist < minRetreat then
                            retreatDist = minRetreat
                        end
                    end
                    local retreatPos, pathLen, status = FindRD(illusion, target, retreatDist)
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        nil,
                        retreatPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_retreat_once"
                    )
                    illusionStates[id] = {
                        state = "retreating",
                        time = now,
                        retreatPos = retreatPos,
                        target = target,
                        pathLen = pathLen,
                        status = status,
                        startDist = startDist,
                        retreatDist = retreatDist,
                        retreatTries = 1
                    }
                end
            end
        elseif state == "retreating" then
            local illuPos = Entity.GetAbsOrigin(illusion)
            local retreatPos = illusionStates[id].retreatPos
            local dist = (illuPos - retreatPos):Length()
            local minTriggerDist = UI.Settings.MinTriggerDist:Get()
            local maxTries = 2
            if dist < 50 or (now - illusionStates[id].time) > 1.2 then
                local target = illusionStates[id].target
                if target and Entity.IsAlive(target) then
                    local enemyPos = Entity.GetAbsOrigin(target)
                    local distToEnemy = (illuPos - enemyPos):Length()
                    if distToEnemy < minTriggerDist and (illusionStates[id].retreatTries or 1) < maxTries then
                        local minRetreat = UI.Settings.MinRetreat:Get()
                        local maxRetreat = UI.Settings.MaxRetreat:Get()
                        local maxFinalDist = 450
                        local retreatDist = CalcRD(distToEnemy, minTriggerDist, minRetreat, maxRetreat)
                        if distToEnemy + retreatDist > maxFinalDist then
                            retreatDist = maxFinalDist - distToEnemy
                            if retreatDist < minRetreat then
                                retreatDist = minRetreat
                            end
                        end
                        local retreatPos2, pathLen2, status2 = FindRD(illusion, target, retreatDist)
                        Player.PrepareUnitOrders(
                            player,
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            nil,
                            retreatPos2,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            illusion,
                            false,
                            false,
                            false,
                            false,
                            "naga_illusion_retreat_retry"
                        )
                        illusionStates[id].retreatPos = retreatPos2
                        illusionStates[id].pathLen = pathLen2
                        illusionStates[id].status = status2
                        illusionStates[id].time = now
                        illusionStates[id].retreatTries = (illusionStates[id].retreatTries or 1) + 1
                        illusionStates[id].retreatDist = retreatDist
                    else
                        Player.PrepareUnitOrders(
                            player,
                            Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                            target,
                            Vector(),
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            illusion,
                            false,
                            false,
                            false,
                            false,
                            "naga_illusion_attack_once"
                        )
                        illusionStates[id].state = "attacking"
                        illusionStates[id].time = now
                        illusionStates[id].distToEnemy = distToEnemy
                    end
                else
                    illusionStates[id].state = "done"
                end
            end
        elseif state == "attacking" then
            local target = illusionStates[id] and illusionStates[id].target
            if not target or not Entity.IsAlive(target) then

                local newTarget = FindNearestEnemy(illusion, 1200)
                if not newTarget and farmRole and farmRole[id] and not UI.AutoRush.DisableRushOnFarm:Get() then
                    newTarget = FindNearestCreep(illusion, 1200)
                end
                if newTarget then
                    Player.PrepareUnitOrders(
                        Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        newTarget,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_autoattack_idle"
                    )
                    illusionStates[id] = {state = "attacking", time = now, target = newTarget}
                else
                    illusionStates[id].state = "done"
                    illusionStates[id].target = nil
                end
            elseif now - illusionStates[id].time > 0.5 then
                illusionStates[id].state = "done"
            end
        else
            -- Ilusão sem estado - atacar o inimigo mais próximo se não estiver ocupada por outros papéis
            if not (IsIllusionBaiting and IsIllusionBaiting(id)) and 
               not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and 
               not (bodyblockRole and bodyblockRole[id]) and 
               not (priorityRole and priorityRole[id]) and 
               not (splitRole and splitRole[id]) and 
               not (chaseRole and chaseRole[id]) and 
               not (farmRole and farmRole[id]) and 
               not (followRole and followRole[id]) and 
               not (surroundRole and surroundRole[id]) then
                local target = FindNearestEnemy(illusion, 1200)
                if target then
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        target,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_autoattack_idle"
                    )
                    illusionStates[id] = {state = "attacking", time = now, target = target}
                end
            end
        end
        ::continue::
    end
    for id, _ in pairs(illusionStates) do
        local found = false
        for _, illusion in ipairs(illusions) do
            if Entity.GetIndex(illusion) == id then found = true break end
        end
        if not found then
            illusionStates[id] = nil
        end
    end
end

local baitState = {
    lastBaitTime = 0,
    baitingIllusions = {},
    lastWBaitTime = 0,
}

local wbaitRole = {}
local baitRole = {}

local function IsIllusionWbaiting(id)
    return wbaitRole[id] == true
end
local function IsIllusionBaiting(id)
    return baitRole[id] == true
end

local function HasMirrorImageFade(hero)
    return NPC.HasModifier(hero, "modifier_naga_siren_mirror_image")
end

local lastMirrorCastTime = 0

-- Na verdade isso pode ser verificado diretamente na função; eu extraí porque é mais conveniente para mim
local function IsMirrorImageCasting()
    local myHero = Heroes.GetLocal()
    if not myHero then return false end
    for i = 0, 15 do
        local ability = NPC.GetAbilityByIndex(myHero, i)
        if ability and Ability.GetName(ability) == "naga_siren_mirror_image" then
            return Ability.IsInAbilityPhase(ability)
        end
    end
    return false
end

local function AutoBaitIllusions()
    if not UI.AutoBait.Enabled:Get() then return end
    local illusions = GetControllableNagaIllusions()
    local now = os.clock()
    if not baitState._hpBaitLastOrder then baitState._hpBaitLastOrder = {} end
    if not baitState._wbaitLastOrder then baitState._wbaitLastOrder = {} end
    local minIllusions = UI.AutoBait.MinIllusions:Get()
    local hpThreshold = UI.AutoBait.HPThreshold:Get() / 100
    local maxBaiting = UI.AutoBait.MaxBaiting:Get()
    local interval = UI.AutoBait.Interval:Get()
    local myHero = Heroes.GetLocal()
    local heroHP = Entity.GetHealth(myHero)
    local heroMaxHP = Entity.GetMaxHealth(myHero)
    local heroHPFrac = heroHP / heroMaxHP

    local baitHP = heroHP * hpThreshold

    if IsMirrorImageCasting() then
        lastMirrorCastTime = os.clock()
    end

    local wRadius = UI.AutoBait.WRadius:Get()
    local wBaitCount = UI.AutoBait.WBaitCount:Get()
    local wBaitInterval = UI.AutoBait.WBaitInterval:Get()

    if (os.clock() - lastMirrorCastTime < 0.5) and (now - baitState.lastWBaitTime > wBaitInterval) then
        local enemies = Entity.GetHeroesInRadius(myHero, wRadius, Enum.TeamType.TEAM_ENEMY, true) or {}
        if #enemies > 0 then
            local illuList = {}

            local currentWbait = 0
            for _, illusion in ipairs(illusions) do
                local id = Entity.GetIndex(illusion)
                if IsIllusionWbaiting(id) then
                    currentWbait = currentWbait + 1
                end
            end
            for _, illusion in ipairs(illusions) do
                local id = Entity.GetIndex(illusion)
                if not IsIllusionBaiting(id) and not IsIllusionWbaiting(id) and not (splitRole and splitRole[id]) and not (farmRole and farmRole[id]) then
                    local illuHP = Entity.GetHealth(illusion)
                    local illuMaxHP = Entity.GetMaxHealth(illusion)
                    table.insert(illuList, {npc=illusion, id=id, frac=illuHP/illuMaxHP})
                end
            end
            table.sort(illuList, function(a, b) return a.frac < b.frac end)
            for i = 1, math.min(wBaitCount - currentWbait, #illuList) do
                local illusion = illuList[i].npc
                local id = illuList[i].id
                local enemy = FindNearestEnemy(illusion, 1200)
                local illuPos = Entity.GetAbsOrigin(illusion)
                local baitPos
                if enemy then
                    local baseDir = (illuPos - Entity.GetAbsOrigin(enemy)):Normalized()
                    local angleOffset = math.rad(math.random(-60, 60))
                    local dir = Vector(
                        baseDir.x * math.cos(angleOffset) - baseDir.y * math.sin(angleOffset),
                        baseDir.x * math.sin(angleOffset) + baseDir.y * math.cos(angleOffset),
                        0
                    )
                    local dist = math.random(300, 600)
                    baitPos = illuPos + dir * dist
                else
                    local angle = math.rad(math.random(0, 359))
                    local dist = math.random(300, 600)
                    baitPos = illuPos + Vector(math.cos(angle), math.sin(angle), 0) * dist
                end
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    baitPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    illusion,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_bait_w"
                )
                baitState._wbaitLastOrder[id] = now
                wbaitRole[id] = true
            end
            baitState.lastWBaitTime = now
        end
    end

    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if IsIllusionBaiting(id) and not IsIllusionWbaiting(id) then
            if not baitState._hpBaitLastOrder[id] or (now - baitState._hpBaitLastOrder[id] > math.random(7,12)/10) then
                local enemy = FindNearestEnemy(illusion, 1200)
                local illuPos = Entity.GetAbsOrigin(illusion)
                local baitPos
                if enemy then
                    local baseDir = (illuPos - Entity.GetAbsOrigin(enemy)):Normalized()
                    local angleOffset = math.rad(math.random(-90, 90))
                    local dir = Vector(
                        baseDir.x * math.cos(angleOffset) - baseDir.y * math.sin(angleOffset),
                        baseDir.x * math.sin(angleOffset) + baseDir.y * math.cos(angleOffset),
                        0
                    )
                    local dist = math.random(400, 700)
                    baitPos = illuPos + dir * dist
                else
                    local angle = math.rad(math.random(0, 359))
                    local dist = math.random(400, 700)
                    baitPos = illuPos + Vector(math.cos(angle), math.sin(angle), 0) * dist
                end
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    baitPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    illusion,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_bait_hp"
                )
                baitState._hpBaitLastOrder[id] = now
            end
        end
    end

    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if IsIllusionWbaiting(id) then
            if not baitState._wbaitLastOrder[id] or (now - baitState._wbaitLastOrder[id] > 0.7) then
                local enemy = FindNearestEnemy(illusion, 1200)
                local illuPos = Entity.GetAbsOrigin(illusion)
                local baitPos
                if enemy then
                    local baseDir = (illuPos - Entity.GetAbsOrigin(enemy)):Normalized()
                    local angleOffset = math.rad(math.random(-60, 60))
                    local dir = Vector(
                        baseDir.x * math.cos(angleOffset) - baseDir.y * math.sin(angleOffset),
                        baseDir.x * math.sin(angleOffset) + baseDir.y * math.cos(angleOffset),
                        0
                    )
                    local dist = math.random(300, 600)
                    baitPos = illuPos + dir * dist
                else
                    local angle = math.rad(math.random(0, 359))
                    local dist = math.random(300, 600)
                    baitPos = illuPos + Vector(math.cos(angle), math.sin(angle), 0) * dist
                end
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    baitPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    illusion,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_bait_w"
                )
                baitState._wbaitLastOrder[id] = now
            end
        end
    end

    -- Verificamos quantas já estão fazendo bait
    local currentBaiting = 0
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if IsIllusionBaiting(id) then
            currentBaiting = currentBaiting + 1
        end
    end
    
    -- Designamos bait apenas se estiver abaixo do máximo
    if currentBaiting < maxBaiting then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            if not IsIllusionBaiting(id) and not IsIllusionWbaiting(id) and not (bodyblockRole and bodyblockRole[id]) and not (surroundRole and surroundRole[id]) then
                local illuHP = Entity.GetHealth(illusion)
                local illuMaxHP = Entity.GetMaxHealth(illusion)
                local illuHPPercent = illuHP / illuMaxHP
                
                if illuHPPercent < hpThreshold then
                    baitRole[id] = true
                    break
                end
            end
        end
    end

    if #illusions < minIllusions then return end

    local aliveIds = {}
    for _, illusion in ipairs(illusions) do
        aliveIds[Entity.GetIndex(illusion)] = true
    end
    for id, _ in pairs(wbaitRole) do
        if not aliveIds[id] then
            wbaitRole[id] = nil
        end
    end
    for id, _ in pairs(baitRole) do
        if not aliveIds[id] then
            baitRole[id] = nil
        end
    end

    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if not IsIllusionBaiting(id) and not IsIllusionWbaiting(id) and not (splitRole and splitRole[id]) then
            local state = illusionStates[id] and illusionStates[id].state or nil
            if state == "done" or not state then
                local target = FindNearestEnemy(illusion, 1200)
                if target then
                    Player.PrepareUnitOrders(
                        player,
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        target,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_autoattack_idle"
                    )
                end
            end
        end
    end
end

farmRole = farmRole or {}
farmLastOrder = farmLastOrder or {}

surroundLastOrder = surroundLastOrder or {}
surroundActive = surroundActive or false

function AutoSurroundEnemy()
    if not UI.Surround.Enabled:Get() then return end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    
    local triggerKey = UI.Surround.TriggerKey:Get()
    if not triggerKey or triggerKey == Enum.ButtonCode.BUTTON_CODE_INVALID or triggerKey == Enum.ButtonCode.KEY_NONE then return end
    
    local now = os.clock()
    
    if Input.IsKeyDown(triggerKey) then
        local target = FindNearestEnemy(myHero, 800)
        if target then
            local illusions = GetAllNagaIllusions()
            if #illusions >= 3 then
                local targetPos = Entity.GetAbsOrigin(target)
                local targetSpeed = NPC.GetMoveSpeed(target) or 300
                
                -- Inicialização
                if surroundPhase == "idle" then
                    surroundTarget = target
                    surroundStartTime = now
                    surroundLastTargetPos = targetPos
                    surroundTargetStoppedTime = 0
                    
                    -- Limpando roles
                    for i = 1, 3 do
                        local illusion = illusions[i]
                        local id = Entity.GetIndex(illusion)
                        if priorityRole then priorityRole[id] = nil end
                        if splitRole then splitRole[id] = nil end
                        if chaseRole then chaseRole[id] = nil end
                        if farmRole then farmRole[id] = nil end
                        if followRole then followRole[id] = nil end
                        if bodyblockRole then bodyblockRole[id] = nil end
                        if baitRole then baitRole[id] = nil end
                        if wbaitRole then wbaitRole[id] = nil end
                        if illusionStates then illusionStates[id] = {state = "done"} end
                        surroundRole[id] = true
                    end
                    
                    -- Sempre começamos com bloqueio
                    surroundPhase = "blocking"
                    surroundBlockerId = Entity.GetIndex(illusions[1])
                end
                
                -- Verificar se o inimigo parou
                local targetMoved = false
                local isTargetMoving = targetSpeed > 250 and NPC.IsRunning(target)
                if surroundLastTargetPos then
                    local moveDist = (targetPos - surroundLastTargetPos):Length()
                    if moveDist > 80 or isTargetMoving then
                        targetMoved = true
                        surroundTargetStoppedTime = 0
                    else
                        if surroundTargetStoppedTime == 0 then
                            surroundTargetStoppedTime = now
                        end
                    end
                end
                surroundLastTargetPos = targetPos
                
                -- Fase de bloqueio
                if surroundPhase == "blocking" then
                    -- Bloqueador
                    local blockerIllusion = nil
                    for _, illusion in ipairs(illusions) do
                        if Entity.GetIndex(illusion) == surroundBlockerId then
                            blockerIllusion = illusion
                            break
                        end
                    end
                    
                    if blockerIllusion and (not surroundLastOrder[surroundBlockerId] or (now - surroundLastOrder[surroundBlockerId] > 0.1)) then
                        local illuPos = Entity.GetAbsOrigin(blockerIllusion)
                        local targetDir = Entity.GetRotation(target):GetForward()
                        local toIllu = (illuPos - targetPos):Normalized()
                        local targetSpeed = NPC.GetMoveSpeed(target) or 300
                        
                        local dynamicDistance = (targetSpeed < 250) and 76.5 or 80
                        local predictTime = 0.18
                        local predictPos = targetPos + targetDir * targetSpeed * predictTime
                        
                        local angleToIllu = math.atan2(toIllu.y, toIllu.x) - math.atan2(targetDir.y, targetDir.x)
                        if angleToIllu > math.pi then angleToIllu = angleToIllu - 2*math.pi end
                        if angleToIllu < -math.pi then angleToIllu = angleToIllu + 2*math.pi end
                        
                        local blockPos
                        if math.abs(angleToIllu) > math.pi/2 then
                            local sideAngle = angleToIllu > 0 and math.pi/2 or -math.pi/2
                            local sideDir = Vector(
                                targetDir.x * math.cos(sideAngle) - targetDir.y * math.sin(sideAngle),
                                targetDir.x * math.sin(sideAngle) + targetDir.y * math.cos(sideAngle),
                                0
                            )
                            blockPos = targetPos + sideDir * dynamicDistance * 1.5 + targetDir * dynamicDistance
                        else
                            blockPos = predictPos + targetDir * dynamicDistance
                        end
                        
                        Player.PrepareUnitOrders(
                            Players.GetLocal(),
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            nil,
                            blockPos,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            blockerIllusion,
                            false,
                            false,
                            false,
                            false,
                            "naga_surround_block"
                        )
                        surroundLastOrder[surroundBlockerId] = now
                    end
                    
                    -- Os demais cercam
                    local radius = UI.Surround.SurroundRadius:Get()
                    for i = 2, 3 do
                        if i <= #illusions then
                            local illusion = illusions[i]
                            local id = Entity.GetIndex(illusion)
                            
                            if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.3) then
                                local angle = math.rad((i - 2) * 180)
                                local pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                                
                                Player.PrepareUnitOrders(
                                    Players.GetLocal(),
                                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                                    nil,
                                    pos,
                                    nil,
                                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                    illusion,
                                    false,
                                    false,
                                    false,
                                    false,
                                    "naga_surround_pos"
                                )
                                surroundLastOrder[id] = now
                            end
                        end
                    end
                    
                    -- Transição para cercar se o inimigo parou
                    if surroundTargetStoppedTime > 0 and (now - surroundTargetStoppedTime > 0.5) then
                        surroundPhase = "surrounding"
                    end
                end
                
                -- Fase de cercar
                if surroundPhase == "surrounding" then
                    local radius = UI.Surround.SurroundRadius:Get()
                    for i = 1, 3 do
                        local illusion = illusions[i]
                        local id = Entity.GetIndex(illusion)
                        
                        if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.3) then
                            local angle = math.rad((i - 1) * 120)
                            local pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                            
                            Player.PrepareUnitOrders(
                                Players.GetLocal(),
                                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                                nil,
                                pos,
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                illusion,
                                false,
                                false,
                                false,
                                false,
                                "naga_surround_pos"
                            )
                            surroundLastOrder[id] = now
                        end
                    end
                    
                    -- Transição para ataque se o inimigo ficar parado por muito tempo
                    if surroundTargetStoppedTime > 0 and (now - surroundTargetStoppedTime > 1.5) then
                        surroundPhase = "attacking"
                    end
                    
                    -- Retorna ao bloqueio se o inimigo correr novamente
                    if targetMoved and isTargetMoving then
                        surroundPhase = "blocking"
                        surroundBlockerId = Entity.GetIndex(illusions[1])
                    end
                end
                
                -- Fase de ataque
                if surroundPhase == "attacking" then
                    for _, illusion in ipairs(illusions) do
                        local id = Entity.GetIndex(illusion)
                        if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.5) then
                            Player.PrepareUnitOrders(
                                Players.GetLocal(),
                                Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                                target,
                                Vector(),
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                illusion,
                                false,
                                false,
                                false,
                                false,
                                "naga_surround_attack"
                            )
                            surroundLastOrder[id] = now
                        end
                    end
                    
                    -- if targetMoved and isTargetMoving then
--     surroundPhase = "blocking"
--     surroundBlockerId = Entity.GetIndex(illusions[1])
-- end

                end
            end
        end
    else
        surroundPhase = "idle"
        surroundTarget = nil
        surroundBlockerId = nil
        surroundLastTargetPos = nil
        surroundTargetStoppedTime = 0
        for id, _ in pairs(surroundRole) do
            surroundRole[id] = nil
        end
    end
end



function AutoFarmCreepsForIllusions()
    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero or #illusions == 0 then return end
    
    local enemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
    if #enemies > 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            farmRole[id] = nil
        end
        return
    end
    
    if priorityRole then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            if priorityRole[id] then
                farmRole[id] = nil
            end
        end
    end
    
    local allNPCs = NPCs.GetAll()

    local availableCreeps = {}
    for _, npc in ipairs(allNPCs) do
        if Entity.IsAlive(npc) and not Entity.IsDormant(npc) and Entity.GetTeamNum(npc) ~= Entity.GetTeamNum(myHero) then
            local name = NPC.GetUnitName(npc)
            if name and (string.find(name, "creep") or string.find(name, "neutral") or string.find(name, "siege") or string.find(name, "mega") or NPC.IsRoshan(npc)) then
                table.insert(availableCreeps, npc)
            end
        end
    end

    
    
    -- Nossa, que bagunça; quem conhece iswaiting sabe
    local i = 1
    while i <= #availableCreeps do
        local creep = availableCreeps[i]
        if NPC.IsWaitingToSpawn(creep) then
            table.remove(availableCreeps, i)
        else
            i = i + 1
        end
    end
    
    if #availableCreeps == 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            farmRole[id] = nil
        end
        return
    end
    
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        
        if (IsIllusionBaiting and IsIllusionBaiting(id)) or 
           (IsIllusionWbaiting and IsIllusionWbaiting(id)) or 
           (splitRole and splitRole[id]) or 
           (surroundRole and surroundRole[id]) then
            farmRole[id] = nil
            goto continue
        end
        
        local illuPos = Entity.GetAbsOrigin(illusion)
        local nearestCreep = nil
        local minDist = math.huge
        
        local creepsNearby = 0
        for _, creep in ipairs(availableCreeps) do
            local creepPos = Entity.GetAbsOrigin(creep)
            local dist = (illuPos - creepPos):Length()
            if dist < 1200 then
                creepsNearby = creepsNearby + 1
            end
            if dist < minDist and dist < 1200 then
                minDist = dist
                nearestCreep = creep
            end
        end
        
        
        if nearestCreep then
            local now = os.clock()
            if not farmLastOrder[id] or (now - farmLastOrder[id] > math.random(7,12)/10) then

                -- Sobre o auto-lasthit: não sou especialista nisso, então pode estar incorreto.
                local creepHP = Entity.GetHealth(nearestCreep)
                local creepMaxHP = Entity.GetMaxHealth(nearestCreep)
                local hpPercent = creepHP / creepMaxHP
                
                local illusionDamage = NPC.GetTrueDamage(illusion)
                local armorValue = NPC.GetPhysicalArmorValue(nearestCreep) or 0
                local armorReduction = 1 - (armorValue / (armorValue + 20)) -- redução aproximada
                local actualDamage = illusionDamage * armorReduction
                
                local otherIllusionsDamage = 0
                for _, otherIllusion in ipairs(illusions) do
                    if otherIllusion ~= illusion and Entity.IsAlive(otherIllusion) then
                        local otherPos = Entity.GetAbsOrigin(otherIllusion)
                        local creepPos = Entity.GetAbsOrigin(nearestCreep)
                        local dist = (otherPos - creepPos):Length()
                        if dist <= 150 then 
                            local otherDamage = NPC.GetTrueDamage(otherIllusion)
                            otherIllusionsDamage = otherIllusionsDamage + (otherDamage * armorReduction)
                        end
                    end
                end
                
                local heroDamage = 0
                local heroPos = Entity.GetAbsOrigin(myHero)
                local creepPos = Entity.GetAbsOrigin(nearestCreep)
                local heroDist = (heroPos - creepPos):Length()
                if heroDist <= 150 then 
                    heroDamage = NPC.GetTrueDamage(myHero) * armorReduction
                end
                
                local tid = actualDamage + otherIllusionsDamage + heroDamage
                
                local dmgDiff = tid - creepHP
                local wait4LastHit = dmgDiff > 0 and dmgDiff <= 20
                
                if hpPercent < 0.3 and not wait4LastHit then
                    Log.Write(string.format("[dbg] trying to lasthit | creep hp: %d, il dmg: %d, all dmg: %d, dif: %d", 
                        math.floor(creepHP), math.floor(actualDamage), math.floor(tid), math.floor(dmgDiff)))
                    Player.PrepareUnitOrders(
                        Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        nearestCreep,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_farm_lasthit"
                    )
                    farmLastOrder[id] = now
                    farmRole[id] = true
                    followRole[id] = nil
                elseif wait4LastHit then
                    Log.Write(string.format("[dbg] waiting best moment4hit | creep hp: %d, alldmg: %d, er: %d", 
                        math.floor(creepHP), math.floor(tid), math.floor(dmgDiff)))
                else
                    Player.PrepareUnitOrders(
                        Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        nearestCreep,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_farm"
                    )
                    farmLastOrder[id] = now
                    farmRole[id] = true
                    followRole[id] = nil
                end
            end
        else
            farmRole[id] = nil
        end
        
        ::continue::
    end
    
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if farmRole and farmRole[id] then
            local currentTarget = Entity.GetAttackTarget and Entity.GetAttackTarget(illusion)
            local isAttackingCreep = false
            
            if currentTarget and Entity.IsAlive(currentTarget) and not Entity.IsDormant(currentTarget) then
                local targetName = NPC.GetUnitName(currentTarget)
                if targetName and (string.find(targetName, "creep") or string.find(targetName, "neutral") or string.find(targetName, "siege") or string.find(targetName, "mega")) then
                    isAttackingCreep = true
                end
            end
            
            local illuPos = Entity.GetAbsOrigin(illusion)
            local hasCreepsNearby = false
            
            for _, creep in ipairs(availableCreeps) do
                local creepPos = Entity.GetAbsOrigin(creep)
                local dist = (illuPos - creepPos):Length()
                if dist < 1200 then
                    hasCreepsNearby = true
                    break
                end
            end
            
            if not isAttackingCreep and not hasCreepsNearby then
                farmRole[id] = nil
            end
        end
    end
end

chaseRole = chaseRole or {}
chaseLastOrder = chaseLastOrder or {}

-- FIXME: na verdade esta função é bem bugada e sua implementação não está totalmente correta
function AutoChaseEnemyForIllusions()
    if not UI.AutoChase.Enabled:Get() then
        for _, illusion in ipairs(GetAllNagaIllusions()) do
            local id = Entity.GetIndex(illusion)
            chaseRole[id] = nil
        end
        return
    end
    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero or #illusions == 0 then return end
    local closeEnemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
    if #closeEnemies > 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            chaseRole[id] = nil
        end
        return
    end
    local chaseRadius = UI.AutoChase.Radius:Get()
    local farEnemies = Entity.GetHeroesInRadius(myHero, chaseRadius, Enum.TeamType.TEAM_ENEMY, true) or {}
    if #farEnemies == 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            chaseRole[id] = nil
        end
        return
    end
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if priorityRole and priorityRole[id] then
            chaseRole[id] = nil
            goto continue
        end
        if not (IsIllusionBaiting and IsIllusionBaiting(id)) and not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and not (farmRole and farmRole[id]) and not (followRole and followRole[id]) and not (splitRole and splitRole[id]) then
            local illuPos = Entity.GetAbsOrigin(illusion)
            local minDist, nearestEnemy = math.huge, nil
            for _, enemy in ipairs(farEnemies) do
                if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) then
                    local dist = (illuPos - Entity.GetAbsOrigin(enemy)):Length()
                    if dist < minDist then
                        minDist = dist
                        nearestEnemy = enemy
                    end
                end
            end
            if nearestEnemy then
                local now = os.clock()
                if not chaseLastOrder[id] or (now - chaseLastOrder[id] > math.random(7,12)/10) then
                    Player.PrepareUnitOrders(
                        Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                        nearestEnemy,
                        Vector(),
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_chase"
                    )
                    chaseLastOrder[id] = now
                    chaseRole[id] = true
                end
            else
                chaseRole[id] = nil
            end
        else
            chaseRole[id] = nil
        end
        ::continue::
    end
end

bodyblockRole = bodyblockRole or {}
bodyblockLastOrder = bodyblockLastOrder or {}
bodyblockActiveId = bodyblockActiveId or nil
bodyblockActiveTime = bodyblockActiveTime or 0

function AutoBodyblockForIllusions()
    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    local now = os.clock()
    
    local forceBodyblockKey = UI.AutoBodyblock.ForceBodyblockKey:Get()
    local isForceBodyblockPressed = forceBodyblockKey ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(forceBodyblockKey)
    
    if isForceBodyblockPressed then
        local forceBodyblockIllu = nil
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            if not (IsIllusionBaiting and IsIllusionBaiting(id)) and not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and not (farmRole and farmRole[id]) and not (chaseRole and chaseRole[id]) and not (followRole and followRole[id]) and not (priorityRole and priorityRole[id]) and not (splitRole and splitRole[id]) then
                forceBodyblockIllu = illusion
                break
            end
        end
        
        if forceBodyblockIllu then
            local enemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
            if #enemies > 0 then
                local bestEnemy, minDist = nil, math.huge
                for _, enemy in ipairs(enemies) do
                    if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) then
                        local dist = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length()
                        if dist < minDist then
                            minDist = dist
                            bestEnemy = enemy
                        end
                    end
                end
                
                if bestEnemy then
                    local id = Entity.GetIndex(forceBodyblockIllu)
                    bodyblockRole[id] = true
                    
                    local enemy = bestEnemy
                    local enemyPos = Entity.GetAbsOrigin(enemy)
                    local enemyDir = Entity.GetRotation(enemy):GetForward()
                    local illuPos = Entity.GetAbsOrigin(forceBodyblockIllu)
                    local toIllu = (illuPos - enemyPos):Normalized()
                    local enemySpeed = NPC.GetMoveSpeed(enemy)

                    local dynamicDistance = (enemySpeed < 250) and 76.5 or 80
                    local predictTime = 0.18
                    local predictPos = enemyPos + enemyDir * enemySpeed * predictTime

                    local angleToIllu = math.atan2(toIllu.y, toIllu.x) - math.atan2(enemyDir.y, enemyDir.x)
                    if angleToIllu > math.pi then angleToIllu = angleToIllu - 2*math.pi end
                    if angleToIllu < -math.pi then angleToIllu = angleToIllu + 2*math.pi end

                    local blockPos
                    if math.abs(angleToIllu) > math.pi/2 then
                        local sideAngle = angleToIllu > 0 and math.pi/2 or -math.pi/2
                        local sideDir = Vector(
                            enemyDir.x * math.cos(sideAngle) - enemyDir.y * math.sin(sideAngle),
                            enemyDir.x * math.sin(sideAngle) + enemyDir.y * math.cos(sideAngle),
                            0
                        )
                        local sideOffset = sideDir * dynamicDistance * 1.5
                        local forwardOffset = enemyDir * dynamicDistance
                        blockPos = enemyPos + sideOffset + forwardOffset
                    else
                        blockPos = predictPos + enemyDir * dynamicDistance
                    end
                    
                    if not bodyblockLastOrder[id] or (now - bodyblockLastOrder[id] > math.random(1,2)/10) then
                        Player.PrepareUnitOrders(
                            Players.GetLocal(),
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            nil,
                            blockPos,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            forceBodyblockIllu,
                            false,
                            false,
                            false,
                            false,
                            "naga_illusion_force_bodyblock"
                        )
                        bodyblockLastOrder[id] = now
                    end
                end
            end
        end
        return
    end
    
    if not UI.AutoBodyblock.Enabled:Get() then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            bodyblockRole[id] = nil
        end
        bodyblockActiveId = nil
        bodyblockActiveTime = 0
        return
    end
    
    if NetChannel and NetChannel.GetAvgLatency then
        local ping = NetChannel.GetAvgLatency(Enum.Flow.FLOW_OUTGOING) * 1000
        if ping > UI.AutoBodyblock.PingThreshold:Get() then
            for _, illusion in ipairs(illusions) do
                local id = Entity.GetIndex(illusion)
                bodyblockRole[id] = nil
            end
            bodyblockActiveId = nil
            bodyblockActiveTime = 0
            return
        end
    end
    
    if #illusions < 2 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            bodyblockRole[id] = nil
        end
        bodyblockActiveId = nil
        bodyblockActiveTime = 0
        return
    end
    
    local enemies = Entity.GetHeroesInRadius(myHero, 1200, Enum.TeamType.TEAM_ENEMY, true) or {}
    if #enemies == 0 then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            bodyblockRole[id] = nil
        end
        bodyblockActiveId = nil
        bodyblockActiveTime = 0
        return
    end

    local bodyblockIllu = nil
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if not (IsIllusionBaiting and IsIllusionBaiting(id)) and not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and not (farmRole and farmRole[id]) and not (chaseRole and chaseRole[id]) and not (followRole and followRole[id]) and not (priorityRole and priorityRole[id]) and not (splitRole and splitRole[id]) then
            bodyblockIllu = illusion
            break
        end
    end

    local bestEnemy, minDist = nil, math.huge
    for _, enemy in ipairs(enemies) do
        if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) then
            local dist = (Entity.GetAbsOrigin(myHero) - Entity.GetAbsOrigin(enemy)):Length()
            if dist < minDist then
                minDist = dist
                bestEnemy = enemy
            end
        end
    end
    
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if illusion == bodyblockIllu then
            bodyblockRole[id] = true
        else
            bodyblockRole[id] = nil
        end
    end
    
    if bodyblockIllu and bestEnemy then
        local id = Entity.GetIndex(bodyblockIllu)
        local enemy = bestEnemy
        local enemyPos = Entity.GetAbsOrigin(enemy)
        local enemyDir = Entity.GetRotation(enemy):GetForward()
        local illuPos = Entity.GetAbsOrigin(bodyblockIllu)
        local toIllu = (illuPos - enemyPos):Normalized()
        local enemySpeed = NPC.GetMoveSpeed(enemy)

        local dynamicDistance = (enemySpeed < 250) and 76.5 or 80
        local predictTime = 0.18
        local predictPos = enemyPos + enemyDir * enemySpeed * predictTime

        local angleToIllu = math.atan2(toIllu.y, toIllu.x) - math.atan2(enemyDir.y, enemyDir.x)
        if angleToIllu > math.pi then angleToIllu = angleToIllu - 2*math.pi end
        if angleToIllu < -math.pi then angleToIllu = angleToIllu + 2*math.pi end

        local blockPos
        if math.abs(angleToIllu) > math.pi/2 then
            local sideAngle = angleToIllu > 0 and math.pi/2 or -math.pi/2
            local sideDir = Vector(
                enemyDir.x * math.cos(sideAngle) - enemyDir.y * math.sin(sideAngle),
                enemyDir.x * math.sin(sideAngle) + enemyDir.y * math.cos(sideAngle),
                0
            )
            local sideOffset = sideDir * dynamicDistance * 1.5
            local forwardOffset = enemyDir * dynamicDistance
            blockPos = enemyPos + sideOffset + forwardOffset
        else
            blockPos = predictPos + enemyDir * dynamicDistance
        end
        
        if not bodyblockLastOrder[id] or (now - bodyblockLastOrder[id] > math.random(1,2)/10) then
            Player.PrepareUnitOrders(
                Players.GetLocal(),
                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                nil,
                blockPos,
                nil,
                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                bodyblockIllu,
                false,
                false,
                false,
                false,
                "naga_illusion_bodyblock"
            )
            bodyblockLastOrder[id] = now
        end
    end
end

priorityRole = priorityRole or {}
priorityTarget = priorityTarget or {}
priorityLastOrder = priorityLastOrder or {}

local importantNames = {
    ["npc_dota_healing_ward"] = true,
    ["npc_dota_weaver_swarm"] = true,
    ["npc_dota_shadow_shaman_serpent_ward"] = true,
    ["npc_dota_rattletrap_cog"] = true,
    ["npc_dota_ward_base"] = true,
    ["npc_dota_phoenix_sun"] = true,
    ["npc_dota_tombstone"] = true,
    ["npc_dota_unit_tombstone4"] = true,

}

local function IsImportantName(name)
    if importantNames[name] then return true end
    if string.find(name, "npc_dota_shadow_shaman_ward_") then return true end
    if string.find(name, "npc_dota_unit_tombstone%d*$") then return true end
    return false
end

function AutoPriorityAttackForIllusions()
    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero or #illusions == 0 then return end
    local allNPCs = NPCs.GetAll()
    local important = {}
    for _, npc in ipairs(allNPCs) do
        local name = tostring(NPC.GetUnitName(npc))
        local id = Entity.GetIndex(npc)
        local alive = tostring(Entity.IsAlive(npc))
        local dormant = tostring(Entity.IsDormant(npc))
        local pos = Entity.GetAbsOrigin(npc)
        local dist = (Entity.GetAbsOrigin(myHero) - pos):Length()
        if IsImportantName(name) and Entity.IsAlive(npc) and not Entity.IsDormant(npc) and dist < 1200 then
            table.insert(important, npc)
        end
        if Entity.IsHero(npc) and NPC.HasModifier(npc, "modifier_healing_salve") and Entity.IsAlive(npc) and not Entity.IsDormant(npc) and dist < 1200 then
            table.insert(important, npc)
        end
    end
    local assigned = {}
    local assignedIllusions = {}
    local maxIllusionsPerTarget = UI.AutoSplit.MaxIllusionsPerTarget:Get()
    for _, npc in ipairs(important) do
        local npcId = Entity.GetIndex(npc)
        assignedIllusions[npcId] = 0
    end
    for _, npc in ipairs(important) do
        local npcId = Entity.GetIndex(npc)
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            if not (IsIllusionBaiting and IsIllusionBaiting(id)) and not (IsIllusionWbaiting and IsIllusionWbaiting(id)) and not (bodyblockRole and bodyblockRole[id]) and not (splitRole and splitRole[id]) and not assigned[id] and assignedIllusions[npcId] < maxIllusionsPerTarget then
                local now = os.clock()
                if not priorityLastOrder[id] or (now - priorityLastOrder[id] > math.random(7,12)/10) then
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                    npc,
                    Vector(),
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    illusion,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_priority"
                )
                priorityRole[id] = true
                priorityTarget[id] = npc
                assigned[id] = true
                assignedIllusions[npcId] = assignedIllusions[npcId] + 1
                priorityLastOrder[id] = now
                end
            end
        end
    end
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if not assigned[id] then
            priorityRole[id] = nil
            priorityTarget[id] = nil
        end
        if priorityRole[id] then
            splitRole[id] = nil
            chaseRole[id] = nil
            farmRole[id] = nil
            followRole[id] = nil
            bodyblockRole[id] = nil
        end
    end
end

splitRole = splitRole or {}
splitTarget = splitTarget or {}
splitLastOrder = splitLastOrder or {}

-- Escrevi esta função após uma longa pausa e após corrigir outras funções. A implementação não é das minhas favoritas, mas funciona.
-- FIXME: Na teoria ela deveria separar exatamente a quantidade de ilusões indicada no elemento da UI. Atualmente, se houver mais ilusões
-- do que o máximo configurado, ela tende a redirecionar o excedente.
function AutoSplitAttackForIllusions()
    if not UI.AutoSplit.Enabled:Get() then
        for _, illusion in ipairs(GetAllNagaIllusions()) do
            local id = Entity.GetIndex(illusion)
            splitRole[id] = nil
            splitTarget[id] = nil
        end
        return
    end

    local illusions = GetControllableNagaIllusions()
    local myHero = Heroes.GetLocal()
    if not myHero or #illusions == 0 then return end

    local searchRadius = UI.AutoSplit.SearchRadius:Get()
    local minEnemies = UI.AutoSplit.MinEnemies:Get()
    local enemies = Entity.GetHeroesInRadius(myHero, searchRadius, Enum.TeamType.TEAM_ENEMY, true) or {}

    if #enemies < minEnemies then
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            splitRole[id] = nil
            splitTarget[id] = nil
        end
        return
    end

    local now = os.clock()
    local targetCount = {}
    local illusionTarget = {}
    local freeIllusions = {}

    local skippedIllusions = 0
    local attackingIllusions = 0
    local freeIllusionsCount = 0

    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        splitRole[id] = nil
        splitTarget[id] = nil

        if priorityRole and priorityRole[id] then goto continue end
        if IsIllusionBaiting and IsIllusionBaiting(id) then goto continue end
        if IsIllusionWbaiting and IsIllusionWbaiting(id) then goto continue end
        if bodyblockRole and bodyblockRole[id] then goto continue end
        if chaseRole and chaseRole[id] then goto continue end
        if farmRole and farmRole[id] then goto continue end
        if followRole and followRole[id] then goto continue end

        local target = Entity.GetAttackTarget and Entity.GetAttackTarget(illusion)
        local isAttackingHero = false

        if target and Entity.IsHero(target) and Entity.IsAlive(target) and not Entity.IsDormant(target) then
            local tid = Entity.GetIndex(target)
            targetCount[tid] = (targetCount[tid] or 0) + 1
            illusionTarget[id] = tid
            attackingIllusions = attackingIllusions + 1
            isAttackingHero = true
        else

            local illuPos = Entity.GetAbsOrigin(illusion)
            local nearestEnemy = nil
            local nearestDist = math.huge

            for _, enemy in ipairs(enemies) do
                if Entity.IsAlive(enemy) and not Entity.IsDormant(enemy) then
                    local dist = (illuPos - Entity.GetAbsOrigin(enemy)):Length()
                    local attackRange = GetAttackRange(illusion)

                    if dist <= attackRange * 1.5 then
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestEnemy = enemy
                        end
                    end
                end
            end

            if nearestEnemy then
                local tid = Entity.GetIndex(nearestEnemy)
                targetCount[tid] = (targetCount[tid] or 0) + 1
                illusionTarget[id] = tid
                attackingIllusions = attackingIllusions + 1
                isAttackingHero = true
            end
        end

        if not isAttackingHero then

            table.insert(freeIllusions, illusion)
            freeIllusionsCount = freeIllusionsCount + 1
        end
        ::continue::
    end

    local maxIllusionsPerTarget = UI.AutoSplit.MaxIllusionsPerTarget:Get()
    local splitCount = UI.AutoSplit.SplitCount:Get()

    local overloadedTargets = {}
    for enemyId, count in pairs(targetCount) do
        if count > maxIllusionsPerTarget then
            table.insert(overloadedTargets, {
                enemyId = enemyId,
                excess = count - maxIllusionsPerTarget,
                count = count
            })
        end
    end

    table.sort(overloadedTargets, function(a, b) return a.excess > b.excess end)

    for _, overloaded in ipairs(overloadedTargets) do
        local enemyId = overloaded.enemyId
        local excess = overloaded.excess
        local redirectCount = math.min(excess, splitCount)

        local attackingIllusions = {}
        for _, illusion in ipairs(illusions) do
            local id = Entity.GetIndex(illusion)
            if illusionTarget[id] == enemyId then
                table.insert(attackingIllusions, illusion)
            end
        end

        if #attackingIllusions == 0 then
            for _, illusion in ipairs(illusions) do
                local id = Entity.GetIndex(illusion)

                if priorityRole and priorityRole[id] then goto continue_search end
                if IsIllusionBaiting and IsIllusionBaiting(id) then goto continue_search end
                if IsIllusionWbaiting and IsIllusionWbaiting(id) then goto continue_search end
                if bodyblockRole and bodyblockRole[id] then goto continue_search end
                if chaseRole and chaseRole[id] then goto continue_search end
                if farmRole and farmRole[id] then goto continue_search end
                if followRole and followRole[id] then goto continue_search end

                local illuPos = Entity.GetAbsOrigin(illusion)
                local enemyPos = Entity.GetAbsOrigin(enemy)
                local dist = (illuPos - enemyPos):Length()
                local attackRange = GetAttackRange(illusion)

                if dist <= attackRange * 1.5 then
                    table.insert(attackingIllusions, illusion)
                end
                ::continue_search::
            end
        end

        local enemy = nil
        for _, e in ipairs(enemies) do
            if Entity.GetIndex(e) == enemyId then
                enemy = e
                break
            end
        end

        if enemy then
            table.sort(attackingIllusions, function(a, b)
                local distA = (Entity.GetAbsOrigin(a) - Entity.GetAbsOrigin(enemy)):Length()
                local distB = (Entity.GetAbsOrigin(b) - Entity.GetAbsOrigin(enemy)):Length()
                return distA < distB
            end)

            local alternativeTarget = nil
            local bestScore = -1

            for _, potentialTarget in ipairs(enemies) do
                local targetId = Entity.GetIndex(potentialTarget)
                if targetId ~= enemyId and Entity.IsAlive(potentialTarget) and not Entity.IsDormant(potentialTarget) then
                    local currentCount = targetCount[targetId] or 0
                    -- rsrs, imitando um sistema inteligente =))
                    local distance = (Entity.GetAbsOrigin(enemy) - Entity.GetAbsOrigin(potentialTarget)):Length()

                    local score = 1000 - currentCount * 100 - distance * 0.1

                    if score > bestScore then
                        bestScore = score
                        alternativeTarget = potentialTarget
                    end
                end
            end

            if alternativeTarget then

                for i = 1, redirectCount do
                    if i <= #attackingIllusions then
                        local illusion = attackingIllusions[i]
                        local id = Entity.GetIndex(illusion)

                        if not splitLastOrder[id] or (now - splitLastOrder[id] > math.random(7,12)/10) then
                            Player.PrepareUnitOrders(
                                Players.GetLocal(),
                                Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                                alternativeTarget,
                                Vector(),
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                illusion,
                                false,
                                false,
                                false,
                                false,
                                "naga_illusion_split"
                            )
                            splitRole[id] = true
                            splitTarget[id] = alternativeTarget
                            splitLastOrder[id] = now

                            targetCount[enemyId] = targetCount[enemyId] - 1
                            targetCount[Entity.GetIndex(alternativeTarget)] = (targetCount[Entity.GetIndex(alternativeTarget)] or 0) + 1
                        end
                    end
                end
            end
        end
    end

    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        if splitRole[id] then
            local target = splitTarget[id]
            if target and Entity.IsAlive(target) then
                local targetId = Entity.GetIndex(target)
                local currentCount = 0
                for _, otherIllusion in ipairs(illusions) do
                    local otherId = Entity.GetIndex(otherIllusion)

                    if Entity.GetAttackTarget and Entity.GetAttackTarget(otherIllusion) == target then
                        currentCount = currentCount + 1
                    end
                end

                local targetPos = Entity.GetAbsOrigin(target)
                for _, otherIllusion in ipairs(illusions) do
                    local otherId = Entity.GetIndex(otherIllusion)
                    local otherPos = Entity.GetAbsOrigin(otherIllusion)
                    local dist = (otherPos - targetPos):Length()
                    local attackRange = GetAttackRange(otherIllusion)

                    if dist <= attackRange * 1.5 then
                        if not (priorityRole and priorityRole[otherId]) and 
                           not (IsIllusionBaiting and IsIllusionBaiting(otherId)) and 
                           not (IsIllusionWbaiting and IsIllusionWbaiting(otherId)) and 
                           not (bodyblockRole and bodyblockRole[otherId]) and 
                           not (chaseRole and chaseRole[otherId]) and 
                           not (farmRole and farmRole[otherId]) and 
                           not (followRole and followRole[otherId]) then
                            currentCount = currentCount + 1
                        end
                    end
                end

                if currentCount <= maxIllusionsPerTarget then
                    splitRole[id] = nil
                    splitTarget[id] = nil
                end
            else
                splitRole[id] = nil
                splitTarget[id] = nil
            end
        end
    end
end

local function DrawIllusionStatus()
    if not UI.Visuals.StatusText:Get() then return end
    local illusions = GetAllNagaIllusions()
    for _, illusion in ipairs(illusions) do
        local pos = Entity.GetAbsOrigin(illusion) + Vector(0, 0, NPC.GetHealthBarOffset(illusion))
        local screenPos, isVisible = Render.WorldToScreen(pos)
        if isVisible then
            local id = Entity.GetIndex(illusion)
            local state = illusionStates[id] and illusionStates[id].state or "?"
            local text = ""
            if playerOverrideUntil and playerOverrideUntil[id] and os.clock() < playerOverrideUntil[id] then
                local remain = math.max(0, playerOverrideUntil[id] - os.clock())
                text = string.format("Override: %.1fs", remain)
            elseif IsIllusionWbaiting(id) then
                text = "W-Isca"
            elseif IsIllusionBaiting(id) then
                text = "Isca"
            elseif surroundRole and surroundRole[id] then
                if surroundPhase == "blocking" and surroundBlockerId == id then
                    text = "Cercar: bloqueio"
                elseif surroundPhase == "blocking" then
                    text = "Cercar: cercando"
                elseif surroundPhase == "surrounding" then
                    text = "Cercar: posição"
                elseif surroundPhase == "attacking" then
                    text = "Cercar: ataque"
                else
                    text = "Cercar"
                end
            elseif runawayRole and runawayRole[id] then
                text = "RunAway"
            elseif bodyblockRole and bodyblockRole[id] then
                -- Verificar se o bodyblock forçado está ativo
                local forceBodyblockKey = UI.AutoBodyblock.ForceBodyblockKey:Get()
                local isForceBodyblockPressed = forceBodyblockKey ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(forceBodyblockKey)
                if isForceBodyblockPressed then
                    text = "Force Bodyblock"
                else
                    text = "Bodyblock"
                end
            elseif priorityRole and priorityRole[id] then
                text = "Priority"
            elseif splitRole and splitRole[id] then
                text = "Split"
            elseif chaseRole and chaseRole[id] then
                text = "Chase"
            elseif farmRole and farmRole[id] then
                text = "Farmando creeps"
            elseif state == "retreating" then
                text = string.format(
                    "Ilusão: recua (início: %d, recuo: %d, caminho: %d, tentativas: %d)",
                    math.floor(illusionStates[id].startDist or 0),
                    math.floor(illusionStates[id].retreatDist or 0),
                    math.floor(illusionStates[id].pathLen or 0),
                    illusionStates[id].retreatTries or 1
                )
            elseif state == "attacking" then
                local distToEnemy = illusionStates[id].distToEnemy or 0
                if distToEnemy > 450 then distToEnemy = 450 end
                text = string.format("Ilusão: atacando inimigo (dist: %d)", math.floor(distToEnemy))
            elseif state == "done" then
                text = "Ilusão: pronta"
            else
                text = "Ilusão: aguardando inimigo"
            end

            if illusionStates[id] and illusionStates[id].status then
                text = text .. string.format(" [%s]", illusionStates[id].status)
            end
            local textSize = Render.TextSize(Config.Fonts.Main, 16, text)
            local x = screenPos.x - textSize.x / 2
            local y = screenPos.y - 60
            -- Eu sei sobre a flag DROPSHADOW, mas prefiro assim. shoutout a niksvarpi =)
            Render.Text(Config.Fonts.Main, 16, text, Vec2(x + 1, y + 1), Config.Colors.Text.Shadow)
            Render.Text(Config.Fonts.Main, 16, text, Vec2(x, y), Config.Colors.Text.Primary)
        end
    end
end

local PanelDrag = {
    IsDragging = false,
    StartX = 0,
    StartY = 0,
    OffsetX = 0,
    OffsetY = 0
}

local PanelConfig = {
    X = 50,
    Y = 100,
    Width = 200,
    Height = 50,
    HeaderHeight = 26,
    CellSize = 26,
    CellSpacing = 5,
    BorderRadius = 8,
    ShadowOffset = 2,
    BlurStrength = 15,
    BlurStrengthHeader = 10
}

local panelPosX = 50
local panelPosY = 100

local function GetConfigPath()
    return "pl_panel.ini"
end

local function LoadPanelPosition()
    local configPath = GetConfigPath()
    local file = io.open(configPath, "r")
    if file then
        for line in file:lines() do
            local x = line:match("pos_x=(%d+)")
            local y = line:match("pos_y=(%d+)")
            if x then panelPosX = tonumber(x) end
            if y then panelPosY = tonumber(y) end
        end
        file:close()
    end

    PanelConfig.X = panelPosX
    PanelConfig.Y = panelPosY
end

local function SavePanelPosition()
    local configPath = GetConfigPath()
    local file = io.open(configPath, "w")
    if file then
        file:write(string.format("pos_x=%d\n", PanelConfig.X))
        file:write(string.format("pos_y=%d\n", PanelConfig.Y))
        file:close()
    end
end

local PanelColors = {
    Background = Color(20, 20, 25, 220),
    BackgroundHover = Color(25, 25, 30, 230),
    Border = Color(60, 60, 70, 180),
    BorderHover = Color(80, 120, 255, 200),
    Header = Color(10, 10, 10, 200),
    HeaderText = Color(255, 255, 255, 255),
    Shadow = Color(0, 0, 0, 100),
    StatusColors = {
        ["W-Isca"] = Color(255, 220, 0, 255),
        ["Isca"] = Color(255, 140, 0, 255),
        ["Bodyblock"] = Color(80, 120, 255, 255),
        ["Force Bodyblock"] = Color(255, 80, 80, 255),
        ["Priority"] = Color(255, 255, 120, 255),
        ["Split"] = Color(120, 255, 255, 255),
        ["Chase"] = Color(255, 120, 255, 255),
        ["Farmando creeps"] = Color(120, 200, 255, 255),
        ["Follow"] = Color(120, 255, 120, 255),
        ["Retreating"] = Color(80, 180, 255, 255),
        ["Attacking"] = Color(255, 80, 80, 255),
        ["Done"] = Color(180, 180, 180, 255),
        ["Idle"] = Color(150, 150, 150, 255),
        ["RunAway"] = Color(255, 200, 120, 255),
        ["Cercar"] = Color(255, 100, 200, 255)
    }
}

local function GetIllusionStatus(id)
    if surroundRole and surroundRole[id] then
        return "SR", "Cercar"
    elseif IsIllusionWbaiting(id) then
        return "W", "W-Isca"
    elseif IsIllusionBaiting(id) then
        return "B", "Isca"
    elseif bodyblockRole and bodyblockRole[id] then
    -- Verificar se o bodyblock forçado está ativo
        local forceBodyblockKey = UI.AutoBodyblock.ForceBodyblockKey:Get()
        local isForceBodyblockPressed = forceBodyblockKey ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(forceBodyblockKey)
        if isForceBodyblockPressed then
            return "FB", "Force Bodyblock"
        else
            return "BB", "Bodyblock"
        end
    elseif priorityRole and priorityRole[id] then
        return "P", "Priority"
    elseif splitRole and splitRole[id] then
        return "S", "Split"
    elseif chaseRole and chaseRole[id] then
        return "C", "Chase"
    elseif farmRole and farmRole[id] then
        return "F", "Farmando creeps"
    elseif followRole[id] then
        return "FL", "Follow"
    elseif illusionStates[id] then
        if illusionStates[id].state == "retreating" then
            return "R", "Retreating"
        elseif illusionStates[id].state == "attacking" then
            return "A", "Attacking"
        elseif illusionStates[id].state == "done" then
            return "D", "Done"
        end
    elseif runawayRole and runawayRole[id] then
        return "RA", "RunAway"
    end
    -- não é obrigatório, Idle de qualquer forma não é renderizado.
    return "I", "Idle"
end

local function HandlePanelInput()
    local cursorX, cursorY = Input.GetCursorPos()
    local isInHeader = cursorX >= PanelConfig.X and cursorX <= PanelConfig.X + PanelConfig.Width and
                      cursorY >= PanelConfig.Y and cursorY <= PanelConfig.Y + PanelConfig.HeaderHeight

    local isInPanel = cursorX >= PanelConfig.X and cursorX <= PanelConfig.X + PanelConfig.Width and
                     cursorY >= PanelConfig.Y and cursorY <= PanelConfig.Y + PanelConfig.Height

    if isInHeader and Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) and not PanelDrag.IsDragging then
        PanelDrag.IsDragging = true
        PanelDrag.StartX = cursorX
        PanelDrag.StartY = cursorY
        PanelDrag.OffsetX = cursorX - PanelConfig.X
        PanelDrag.OffsetY = cursorY - PanelConfig.Y
    end

    if PanelDrag.IsDragging then
        if Input.IsKeyDown(Enum.ButtonCode.KEY_MOUSE1) then
            PanelConfig.X = cursorX - PanelDrag.OffsetX
            PanelConfig.Y = cursorY - PanelDrag.OffsetY

            local screenSize = Render.ScreenSize()
            PanelConfig.X = math.max(0, math.min(PanelConfig.X, screenSize.x - PanelConfig.Width))
            PanelConfig.Y = math.max(0, math.min(PanelConfig.Y, screenSize.y - PanelConfig.Height))
        else

            SavePanelPosition()
            PanelDrag.IsDragging = false
        end
    end

    return isInPanel
end

local function DrawBlurredBackground(x, y, width, height, radius, blurStrength, alpha)

    Render.Blur(
        Vec2(x, y),
        Vec2(x + width, y + height),
        blurStrength,
        alpha,
        radius,
        Enum.DrawFlags.None
    )
end

-- Imitação de painel, como no script do arka, mas mais estiloso
local function DrawModernPanel()
    local illusions = GetAllNagaIllusions()

    local isHovered = HandlePanelInput()

    local bgColor = isHovered and PanelColors.BackgroundHover or PanelColors.Background
    local borderColor = isHovered and PanelColors.BorderHover or PanelColors.Border

    DrawBlurredBackground(PanelConfig.X, PanelConfig.Y, PanelConfig.Width, PanelConfig.HeaderHeight, PanelConfig.BorderRadius, PanelConfig.BlurStrengthHeader, 0.91)

    Render.Shadow(
        Vec2(PanelConfig.X, PanelConfig.Y ),
        Vec2(PanelConfig.X + PanelConfig.Width, PanelConfig.Y + PanelConfig.HeaderHeight),
        Color(0, 0, 0, 255),
        24,
        PanelConfig.BorderRadius,
        Enum.DrawFlags.ShadowCutOutShapeBackground,
        Vec2(1, 1)
    )

    Render.FilledRect(
        Vec2(PanelConfig.X, PanelConfig.Y),
        Vec2(PanelConfig.X + PanelConfig.Width, PanelConfig.Y + PanelConfig.HeaderHeight),
        PanelColors.Header,
        PanelConfig.BorderRadius
    )

    local starsIcon = "⋆｡°✩"
    local starsSize = Render.TextSize(Config.Fonts.Main, 14, starsIcon)
    local starsX = PanelConfig.X + 8
    local starsY = PanelConfig.Y + (PanelConfig.HeaderHeight - starsSize.y) / 2

    Render.Text(Config.Fonts.Main, 14, starsIcon, Vec2(starsX + 1, starsY), Color(0, 0, 0, 80))
    Render.Text(Config.Fonts.Main, 14, starsIcon, Vec2(starsX, starsY - 1), Color(170, 170, 170, 255))

    local separatorX = starsX + starsSize.x + 8
    local separatorY = PanelConfig.Y + 4
    local separatorHeight = PanelConfig.HeaderHeight - 8

    Render.FilledRect(
        Vec2(separatorX, separatorY-4),
        Vec2(separatorX + 2, separatorY + separatorHeight + 4),
        Color(15, 15, 15, 70)
    )

    local maintext = "@illusions"
    local maintextSize = Render.TextSize(Config.Fonts.Main, 12, maintext)
    local maintextX = separatorX + 8
    local maintextY = PanelConfig.Y + (PanelConfig.HeaderHeight - maintextSize.y) / 2

    Render.Text(Config.Fonts.Main, 12, maintext, Vec2(maintextX + 1, maintextY + 1), Color(0, 0, 0, 80))
    Render.Text(Config.Fonts.Main, 12, maintext, Vec2(maintextX, maintextY), Color(170, 170, 170, 255))

    local contentY = PanelConfig.Y + PanelConfig.HeaderHeight + 5

    local activeIllusions = {}
    for _, illusion in ipairs(illusions) do
        local id = Entity.GetIndex(illusion)
        local statusCode, statusName = GetIllusionStatus(id)
        if statusName ~= "Done" and statusName ~= "Idle" then
            table.insert(activeIllusions, illusion)
        end
    end

    local maxCells = 6
    local cellStartX = PanelConfig.X + 8
    local cellY = contentY

    for i = 1, maxCells do
        local cellX = cellStartX + (i - 1) * (PanelConfig.CellSize + PanelConfig.CellSpacing)

        DrawBlurredBackground(cellX, cellY, PanelConfig.CellSize, PanelConfig.CellSize, 6, 8, 0.97)

        Render.Shadow(
            Vec2(cellX, cellY),
            Vec2(cellX + PanelConfig.CellSize, cellY + PanelConfig.CellSize),
            Color(0, 0, 0, 255),
            24,
            6,
            Enum.DrawFlags.ShadowCutOutShapeBackground,
            Vec2(1, 1)
        )

        Render.FilledRect(
            Vec2(cellX, cellY),
            Vec2(cellX + PanelConfig.CellSize, cellY + PanelConfig.CellSize),
            Color(0, 0, 0, 140),
            6
        )

        if i <= #activeIllusions then
            local illusion = activeIllusions[i]
            local id = Entity.GetIndex(illusion)
            local statusCode, statusName = GetIllusionStatus(id)
            local statusColor = PanelColors.StatusColors[statusName] or PanelColors.StatusColors["Idle"]

            local statusText = statusCode
            local statusTextSize = Render.TextSize(Config.Fonts.Main, 12, statusText)
            local textX = cellX + (PanelConfig.CellSize - statusTextSize.x) / 2
            local textY = cellY + (PanelConfig.CellSize - statusTextSize.y) / 2

            Render.Text(Config.Fonts.Main, 12, statusText, Vec2(textX + 1, textY + 1), Color(0, 0, 0, 100))
            Render.Text(Config.Fonts.Main, 12, statusText, Vec2(textX, textY), statusColor)
        end

    end

end

local function AutoRunAwayIllusionsV2()
    if not UI or not UI.RunAway then return end
    local myHero = Heroes.GetLocal()
    if not myHero then return end

    local bind = UI.RunAway.HoldKey
    local isHeld = false
    if bind then
        if bind.IsDown and bind:IsDown() then isHeld = true end
        if bind.IsPressed and bind:IsPressed() then isHeld = true end
        if bind.Buttons then
            local k1, k2 = bind:Buttons()
            if k1 and k1 ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k1 ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k1) then isHeld = true end
            if k2 and k2 ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k2 ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k2) then isHeld = true end
        end
        if not isHeld and bind.Get then
            local k = bind:Get()
            if k and k ~= Enum.ButtonCode.BUTTON_CODE_INVALID and k ~= Enum.ButtonCode.KEY_NONE and Input.IsKeyDown(k) then isHeld = true end
        end
    end

    local now = os.clock()

    if isHeld then
        if not runawayActive then
            runawayActive = true
            runawayBaseAngle = math.random(0, 359)
        end

        local illusions = GetAllNagaIllusions()
        if #illusions == 0 then return end

        local heroPos = Entity.GetAbsOrigin(myHero)
        local keepCount = UI.RunAway.KeepCount:Get()
        local duration = UI.RunAway.Duration:Get()

        local list = {}
        for _, illusion in ipairs(illusions) do
            table.insert(list, { npc = illusion, id = Entity.GetIndex(illusion), dist = (Entity.GetAbsOrigin(illusion) - heroPos):Length() })
        end
        table.sort(list, function(a, b) return a.dist < b.dist end)

        local keepSet = {}
        for i = 1, math.min(keepCount, #list) do
            local id = list[i].id
            keepSet[id] = true
            runawayRole[id] = true
            runawayKeepRole[id] = true
            runawayUntil[id] = nil

            local minR = (UI.AutoFollow and UI.AutoFollow.MinRadius and UI.AutoFollow.MinRadius:Get()) or 200
            local maxR = (UI.AutoFollow and UI.AutoFollow.MaxRadius and UI.AutoFollow.MaxRadius:Get()) or 400
            local angle = math.rad(math.random(0, 359))
            local dist = math.random(minR, maxR)
            local offset = Vector(math.cos(angle), math.sin(angle), 0) * dist
            local targetPos = heroPos + offset
            if not runawayLastOrder[id] or (now - runawayLastOrder[id] > math.random(7,12)/10) then
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    targetPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    list[i].npc,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_runaway"
                )
                runawayLastOrder[id] = now
            end
        end

        local count = math.max(0, #list - keepCount)
        for idx = keepCount + 1, #list do
            local it = list[idx]
            local illusion = it.npc
            local id = it.id
            runawayRole[id] = true
            runawayKeepRole[id] = nil
            runawayUntil[id] = nil

            local angleDeg = runawayBaseAngle + (idx - keepCount - 1) * (count > 0 and (360 / count) or 0)
            local angle = math.rad(angleDeg)
            local dir = Vector(math.cos(angle), math.sin(angle), 0)
            local speed = (NPC.GetMoveSpeed and NPC.GetMoveSpeed(illusion)) or 350
            local dist = math.max(400, math.floor(speed * duration))
            local targetPos = heroPos + dir * dist
            if not runawayLastOrder[id] or (now - runawayLastOrder[id] > math.random(7,12)/10) then
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                    nil,
                    targetPos,
                    nil,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                    illusion,
                    false,
                    false,
                    false,
                    false,
                    "naga_illusion_runaway"
                )
                runawayLastOrder[id] = now
            end

            if priorityRole then priorityRole[id] = nil end
            if splitRole then splitRole[id] = nil end
            if chaseRole then chaseRole[id] = nil end
            if farmRole then farmRole[id] = nil end
            if followRole then followRole[id] = nil end
            if bodyblockRole then bodyblockRole[id] = nil end
            if baitRole then baitRole[id] = nil end
            if wbaitRole then wbaitRole[id] = nil end
        end
        return
    end

    if runawayActive then
        local duration = UI.RunAway.Duration:Get()
        for _, illusion in ipairs(GetAllNagaIllusions()) do
            local id = Entity.GetIndex(illusion)
            if runawayRole[id] then
                if runawayKeepRole[id] then
                    runawayRole[id] = nil
                    runawayKeepRole[id] = nil
                    runawayUntil[id] = nil
                else
                    runawayUntil[id] = now + duration
                end
            end
        end
        runawayActive = false
    end

    local heroPos = Entity.GetAbsOrigin(myHero)
    for _, illusion in ipairs(GetAllNagaIllusions()) do
        local id = Entity.GetIndex(illusion)
        if runawayUntil[id] then
            if now >= runawayUntil[id] then
                runawayUntil[id] = nil
                runawayRole[id] = nil
            else
                local illuPos = Entity.GetAbsOrigin(illusion)
                local dir = illuPos - heroPos
                if dir:Length() > 0 then dir = dir:Normalized() else dir = Vector(1, 0, 0) end
                local speed = (NPC.GetMoveSpeed and NPC.GetMoveSpeed(illusion)) or 350
                local remain = runawayUntil[id] - now
                local dist = math.max(300, math.floor(speed * math.min(remain, UI.RunAway.Duration:Get())))
                local targetPos = heroPos + dir * dist
                if not runawayLastOrder[id] or (now - runawayLastOrder[id] > math.random(7,12)/10) then
                    Player.PrepareUnitOrders(
                        Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        nil,
                        targetPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                        illusion,
                        false,
                        false,
                        false,
                        false,
                        "naga_illusion_runaway"
                    )
                    runawayLastOrder[id] = now
                end
            end
        end
    end
end

local isInitialized = false

surroundLastOrder = surroundLastOrder or {}
surroundRole = surroundRole or {}

surroundPhase = surroundPhase or "idle"
surroundStartTime = surroundStartTime or 0
surroundTarget = surroundTarget or nil
surroundBlockerId = surroundBlockerId or nil
surroundLastTargetPos = surroundLastTargetPos or nil
surroundTargetStoppedTime = surroundTargetStoppedTime or 0

function AutoSurroundEnemy()
    if not UI.Surround.Enabled:Get() then return end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    
    local triggerKey = UI.Surround.TriggerKey:Get()
    if not triggerKey or triggerKey == Enum.ButtonCode.BUTTON_CODE_INVALID or triggerKey == Enum.ButtonCode.KEY_NONE then return end
    
    local now = os.clock()
    
    if Input.IsKeyDown(triggerKey) then
        local target = FindNearestEnemy(myHero, 800)
        if target then
            local illusions = GetAllNagaIllusions()
            if #illusions >= 3 then
                local targetPos = Entity.GetAbsOrigin(target)
                local targetSpeed = NPC.GetMoveSpeed(target) or 300
                
                -- Inicialização
                if surroundPhase == "idle" then
                    surroundTarget = target
                    surroundStartTime = now
                    surroundLastTargetPos = targetPos
                    surroundTargetStoppedTime = 0
                    
                    -- Limpando roles
                    for i = 1, 3 do
                        local illusion = illusions[i]
                        local id = Entity.GetIndex(illusion)
                        if priorityRole then priorityRole[id] = nil end
                        if splitRole then splitRole[id] = nil end
                        if chaseRole then chaseRole[id] = nil end
                        if farmRole then farmRole[id] = nil end
                        if followRole then followRole[id] = nil end
                        if bodyblockRole then bodyblockRole[id] = nil end
                        if baitRole then baitRole[id] = nil end
                        if wbaitRole then wbaitRole[id] = nil end
                        if illusionStates then illusionStates[id] = {state = "done"} end
                        surroundRole[id] = true
                    end
                    
                    -- Sempre começamos com bloqueio
                    surroundPhase = "blocking"
                    surroundBlockerId = Entity.GetIndex(illusions[1])
                end
                
                -- Verificar se o inimigo parou
                local targetMoved = false
                local isTargetMoving = targetSpeed > 250 and NPC.IsRunning(target)
                if surroundLastTargetPos then
                    local moveDist = (targetPos - surroundLastTargetPos):Length()
                    if moveDist > 80 or isTargetMoving then
                        targetMoved = true
                        surroundTargetStoppedTime = 0
                    else
                        if surroundTargetStoppedTime == 0 then
                            surroundTargetStoppedTime = now
                        end
                    end
                end
                surroundLastTargetPos = targetPos
                
                -- Fase de bloqueio
                if surroundPhase == "blocking" then
                    -- Bloqueador
                    local blockerIllusion = nil
                    for _, illusion in ipairs(illusions) do
                        if Entity.GetIndex(illusion) == surroundBlockerId then
                            blockerIllusion = illusion
                            break
                        end
                    end
                    
                    if blockerIllusion and (not surroundLastOrder[surroundBlockerId] or (now - surroundLastOrder[surroundBlockerId] > 0.1)) then
                        local illuPos = Entity.GetAbsOrigin(blockerIllusion)
                        local targetDir = Entity.GetRotation(target):GetForward()
                        local toIllu = (illuPos - targetPos):Normalized()
                        local targetSpeed = NPC.GetMoveSpeed(target) or 300
                        
                        local dynamicDistance = (targetSpeed < 250) and 76.5 or 80
                        local predictTime = 0.18
                        local predictPos = targetPos + targetDir * targetSpeed * predictTime
                        
                        local angleToIllu = math.atan2(toIllu.y, toIllu.x) - math.atan2(targetDir.y, targetDir.x)
                        if angleToIllu > math.pi then angleToIllu = angleToIllu - 2*math.pi end
                        if angleToIllu < -math.pi then angleToIllu = angleToIllu + 2*math.pi end
                        
                        local blockPos
                        if math.abs(angleToIllu) > math.pi/2 then
                            local sideAngle = angleToIllu > 0 and math.pi/2 or -math.pi/2
                            local sideDir = Vector(
                                targetDir.x * math.cos(sideAngle) - targetDir.y * math.sin(sideAngle),
                                targetDir.x * math.sin(sideAngle) + targetDir.y * math.cos(sideAngle),
                                0
                            )
                            blockPos = targetPos + sideDir * dynamicDistance * 1.5 + targetDir * dynamicDistance
                        else
                            blockPos = predictPos + targetDir * dynamicDistance
                        end
                        
                        Player.PrepareUnitOrders(
                            Players.GetLocal(),
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            nil,
                            blockPos,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                            blockerIllusion,
                            false,
                            false,
                            false,
                            false,
                            "naga_surround_block"
                        )
                        surroundLastOrder[surroundBlockerId] = now
                    end
                    
                    -- Os demais cercam
                    local radius = UI.Surround.SurroundRadius:Get()
                    for i = 2, 3 do
                        if i <= #illusions then
                            local illusion = illusions[i]
                            local id = Entity.GetIndex(illusion)
                            
                            if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.3) then
                                local angle = math.rad((i - 2) * 180)
                                local pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                                
                                Player.PrepareUnitOrders(
                                    Players.GetLocal(),
                                    Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                                    nil,
                                    pos,
                                    nil,
                                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                    illusion,
                                    false,
                                    false,
                                    false,
                                    false,
                                    "naga_surround_pos"
                                )
                                surroundLastOrder[id] = now
                            end
                        end
                    end
                    
                    -- Transição para cercar se o inimigo parou
                    if surroundTargetStoppedTime > 0 and (now - surroundTargetStoppedTime > 0.5) then
                        surroundPhase = "surrounding"
                    end
                end
                
                -- Fase de cercar
                if surroundPhase == "surrounding" then
                    local radius = UI.Surround.SurroundRadius:Get()
                    for i = 1, 3 do
                        local illusion = illusions[i]
                        local id = Entity.GetIndex(illusion)
                        
                        if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.3) then
                            local angle = math.rad((i - 1) * 120)
                            local pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                            
                            Player.PrepareUnitOrders(
                                Players.GetLocal(),
                                Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                                nil,
                                pos,
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                illusion,
                                false,
                                false,
                                false,
                                false,
                                "naga_surround_pos"
                            )
                            surroundLastOrder[id] = now
                        end
                    end
                    
                    -- Transição para ataque se o inimigo ficar parado por muito tempo
                    if surroundTargetStoppedTime > 0 and (now - surroundTargetStoppedTime > 1.5) then
                        surroundPhase = "attacking"
                    end
                    
                 -- if targetMoved and isTargetMoving then
--     surroundPhase = "blocking"
--     surroundBlockerId = Entity.GetIndex(illusions[1])
-- end

                end
                
                -- Fase de ataque
                if surroundPhase == "attacking" then
                    for _, illusion in ipairs(illusions) do
                        local id = Entity.GetIndex(illusion)
                        if not surroundLastOrder[id] or (now - surroundLastOrder[id] > 0.5) then
                            Player.PrepareUnitOrders(
                                Players.GetLocal(),
                                Enum.UnitOrder.DOTA_UNIT_ORDER_ATTACK_TARGET,
                                target,
                                Vector(),
                                nil,
                                Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_PASSED_UNIT_ONLY,
                                illusion,
                                false,
                                false,
                                false,
                                false,
                                "naga_surround_attack"
                            )
                            surroundLastOrder[id] = now
                        end
                    end
                    
                 -- if targetMoved and isTargetMoving then
--     surroundPhase = "blocking"
--     surroundBlockerId = Entity.GetIndex(illusions[1])
-- end

                end
            end
        end
    else
        surroundPhase = "idle"
        surroundTarget = nil
        surroundBlockerId = nil
        surroundLastTargetPos = nil
        surroundTargetStoppedTime = 0
        for id, _ in pairs(surroundRole) do
            surroundRole[id] = nil
        end
    end
end

NagaTools.OnUpdate = function()

    if not IsNagaSiren() then return end

    if not isInitialized then
        LoadPanelPosition()
        isInitialized = true
    end

    CleanupPlayerOverride()
    AutoRunAwayIllusionsV2()

    AutoMirrorImageForIllusions()
    AutoBaitIllusions()
    AutoBodyblockForIllusions()
    AutoSplitAttackForIllusions()
    AutoPriorityAttackForIllusions()
    AutoChaseEnemyForIllusions()
    AutoFarmCreepsForIllusions()
    AutoFollowIllusions()
    AutoSurroundEnemy()
end

NagaTools.OnDraw = function()

    if not IsNagaSiren() then return end

    DrawIllusionStatus()
    DrawModernPanel()
    
    if surroundPhase ~= "idle" and surroundTarget then
        local targetPos = Entity.GetAbsOrigin(surroundTarget)
        local targetScreenPos, targetVisible = Render.WorldToScreen(targetPos)
        
        if targetVisible then
            local radius = UI.Surround.SurroundRadius:Get()
            
            if surroundPhase == "blocking" then
                for i = 1, 3 do
                    local pos, color
                    if i == 1 then
                        local illusions = GetAllNagaIllusions()
                        if illusions[1] then
                            local targetDir = Entity.GetRotation(surroundTarget):GetForward()
                            local targetSpeed = NPC.GetMoveSpeed(surroundTarget) or 300
                            local dynamicDistance = (targetSpeed < 250) and 76.5 or 80
                            local predictTime = 0.18
                            local predictPos = targetPos + targetDir * targetSpeed * predictTime
                            pos = predictPos + targetDir * dynamicDistance
                            color = Color(255, 0, 0, 255)
                        end
                    else
                        local angle = math.rad((i - 2) * 180)
                        pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                        color = Color(0, 255, 0, 255)
                    end
                    
                    if pos then
                        local screenPos, visible = Render.WorldToScreen(pos)
                        if visible then
                            Render.Line(targetScreenPos, screenPos, color)
                            Render.Circle(screenPos, 10, color)
                        end
                    end
                end
            elseif surroundPhase == "surrounding" or surroundPhase == "attacking" then
                for i = 1, 3 do
                    local angle = math.rad((i - 1) * 120)
                    local pos = targetPos + Vector(math.cos(angle), math.sin(angle), 0) * radius
                    local screenPos, visible = Render.WorldToScreen(pos)
                    
                    if visible then
                        local color = surroundPhase == "attacking" and Color(255, 255, 0, 255) or Color(0, 0, 255, 255)
                        Render.Line(targetScreenPos, screenPos, color)
                        Render.Circle(screenPos, 10, color)
                    end
                end
            end
            
            Render.Circle(targetScreenPos, 15, Color(255, 255, 255, 255))
        end
    end
end

NagaTools.OnPrepareUnitOrders = function(data)
    if not IsNagaSiren() then return true end
    if not data then return true end

    local localPlayer = Players.GetLocal and Players.GetLocal() or nil
    local lpId = localPlayer and Player.GetPlayerID(localPlayer) or -1
    local issuerPlayerId = data.player and Player.GetPlayerID(data.player) or -2
    if issuerPlayerId ~= lpId then return true end

    if data.identifier and type(data.identifier) == "string" and data.identifier:find("^pl_") then
        return true
    end

    local function applyOverride(npc)
        if npc and IsNagaIllusion(npc) then
            local id = Entity.GetIndex(npc)
            playerOverrideRole[id] = true
            local duration = playerOverrideDuration or 1.5
            if UI and UI.Settings and UI.Settings.PlayerOverrideSec then
                duration = UI.Settings.PlayerOverrideSec:Get()
            end
            playerOverrideUntil[id] = os.clock() + duration

            if priorityRole then priorityRole[id] = nil end
            if splitRole then splitRole[id] = nil end
            if chaseRole then chaseRole[id] = nil end
            if farmRole then farmRole[id] = nil end
            if followRole then followRole[id] = nil end
            if bodyblockRole then bodyblockRole[id] = nil end
            if baitRole then baitRole[id] = nil end
            if wbaitRole then wbaitRole[id] = nil end
            if surroundRole then surroundRole[id] = nil end
            if surroundState then surroundState[id] = nil end
        end
    end
    
    if data.orderIssuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_SELECTED_UNITS then
        local selected = Player.GetSelectedUnits and Player.GetSelectedUnits(localPlayer) or {}
        for _, unit in ipairs(selected) do
            applyOverride(unit)
        end
    else
        applyOverride(data.npc)
    end
    return true
end

return NagaTools
