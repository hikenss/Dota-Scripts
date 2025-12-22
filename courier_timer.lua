local CourierTimer = {}

local State = { 
    deadCouriers = {},
    x = 50,
    y = 50
}

local font = Render.LoadFont("MuseoSansEx", Enum.FontCreate.FONTFLAG_ANTIALIAS)

local tab = Menu.Create("Scripts", "Utility", "Courier Timer")
tab:Icon("\u{f21e}")
local group = tab:Create("Main"):Create("Settings")

local ui = {}
ui.enabled = group:Switch("Ativar Timer", true, "\u{f017}")
ui.test = group:Button("Teste 60s", function()
    local time = GameRules.GetGameTime()
    State.deadCouriers[3] = {
        deathTime = time,
        respawnTime = time + 60
    }
end)

local function getCourierRespawnTime()
    local gameTime = GameRules.GetDOTATime()
    if gameTime < 180 then return 50
    elseif gameTime < 600 then return 90
    elseif gameTime < 1200 then return 120
    elseif gameTime < 1800 then return 140
    else return 160 end
end

function CourierTimer.OnDraw()
    if not ui.enabled:Get() then 
        return 
    end
    
    local time = GameRules.GetGameTime()
    local hasTimers = false
    
    -- Limpa expirados
    for team, data in pairs(State.deadCouriers) do
        local timeLeft = data.respawnTime - time
        if timeLeft <= 0 then
            State.deadCouriers[team] = nil
        else
            hasTimers = true
        end
    end
    
    -- Mostra timer se houver
    if hasTimers then
        local x, y = 50, 50
        local width, height = 100, 40
        
        -- Fundo simples
        Render.FilledRect(Vec2(x, y), Vec2(x + width, y + height), Color(15, 15, 20, 180), 6)
        
        local yOffset = 8
        for team, data in pairs(State.deadCouriers) do
            local timeLeft = data.respawnTime - time
            if timeLeft > 0 then
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft % 60)
                local timerText = string.format("%d:%02d", minutes, seconds)
                local color = team == 2 and Color(120, 255, 120, 255) or Color(255, 120, 120, 255)
                
                -- Ícone do courier
                Render.Text(font, 12, "\u{f21e}", Vec2(x + 8, y + yOffset), color)
                
                -- Tempo
                Render.Text(font, 12, timerText, Vec2(x + 28, y + yOffset), color)
                yOffset = yOffset + 18
            end
        end
    end
end

local trackedCouriers = {}

function CourierTimer.OnUpdate()
    if not ui.enabled:Get() then return end
    
    local myHero = Heroes.GetLocal()
    if not myHero then return end
    local myTeam = Entity.GetTeamNum(myHero)
    
    local allNPCs = NPCs.GetAll()
    local currentCouriers = {}
    
    -- Encontra couriers vivos
    for _, npc in pairs(allNPCs) do
        if npc and Entity.IsAlive(npc) then
            local unitName = NPC.GetUnitName(npc) or ""
            if unitName == "npc_dota_courier" or unitName == "npc_dota_courier_flying" or string.find(unitName:lower(), "courier") then
                local team = Entity.GetTeamNum(npc)
                local id = Entity.GetIndex(npc)
                
                currentCouriers[id] = {team = team, name = unitName}
                
                if not trackedCouriers[id] then
                    trackedCouriers[id] = {team = team, name = unitName, lastSeen = GameRules.GetGameTime()}
                end
                
                trackedCouriers[id].lastSeen = GameRules.GetGameTime()
            end
        end
    end
    
    -- Verifica se algum courier desapareceu (morreu)
    local currentTime = GameRules.GetGameTime()
    for id, data in pairs(trackedCouriers) do
        if not currentCouriers[id] and (currentTime - data.lastSeen) > 1 then
            if data.team ~= myTeam then
                local respawn = getCourierRespawnTime()
                State.deadCouriers[data.team] = {
                    deathTime = currentTime,
                    respawnTime = currentTime + respawn
                }
            end
            trackedCouriers[id] = nil
        end
    end
end

return CourierTimer