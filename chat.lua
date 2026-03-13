local script = {}

-- [[ 1. MENU ]]
local tab = Menu.Create("Scripts", "Utility", "Auto Chat")
tab:Icon("\u{f075}")
local group = tab:Create("Main"):Create("Settings")

local ui_enable = group:Switch("Ativar script", true)

-- Text input fields. In your API this is called :Input (file 6Menu-CMenuGroup.txt)
local ui_kill_msg = group:Input("Mensagem ao matar", "Senta aí")
local ui_kill_all = group:Switch("Matar: no chat geral", true)

local ui_death_msg = group:Input("Mensagem ao morrer", "Lag")
local ui_death_all = group:Switch("Morte: no chat geral", true)

-- [[ 2. LOGIC ]]
local lastKillTime = 0
local lastDeathTime = 0
local cooldown = 1.0 -- Cooldown de 1 segundo entre mensagens

function script.OnEntityKilled(data)
    if not ui_enable:Get() or not Engine.IsInGame() then return end

    local me = Heroes.GetLocal()
    if not me then return end

    local currentTime = os.clock()

    -- [[ LOGICA DE KILL ]]
    if data.source and data.source == me and data.target then
        if Entity.IsHero(data.target) and not Entity.IsSameTeam(me, data.target) then
            if (currentTime - lastKillTime) >= cooldown then
                local msg = ui_kill_msg:Get()
                if msg and msg ~= "" then
                    local prefix = ui_kill_all:Get() and "say " or "say_team "
                    Engine.ExecuteCommand(prefix .. msg)
                    lastKillTime = currentTime
                end
            end
        end
    end

    -- [[ LOGICA DE MORTE ]]
    if data.target and data.target == me then
        if (currentTime - lastDeathTime) >= cooldown then
            local msg = ui_death_msg:Get()
            if msg and msg ~= "" then
                local prefix = ui_death_all:Get() and "say " or "say_team "
                Engine.ExecuteCommand(prefix .. msg)
                lastDeathTime = currentTime
            end
        end
    end
end

return script