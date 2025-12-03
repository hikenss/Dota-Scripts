local script = {}


-- Adiciona o switch de Threshold de IA para Oracle
local oracleAIThresholdSwitch = Menu.Find("Heróis", "Lista de Heróis", "Oracle", "Uso Automático", "False Promise")
if oracleAIThresholdSwitch then
    local switch = oracleAIThresholdSwitch:Switch("Threshold IA", false)
    switch:Icon("\u{f72b}") 
end

-- Adiciona o switch de Threshold de IA para Dazzle
local dazzleAIThresholdSwitch = Menu.Find("Heróis", "Lista de Heróis", "Dazzle", "Configurações Principais", "Shallow Grave")
if dazzleAIThresholdSwitch then
    local switch = dazzleAIThresholdSwitch:Switch("Threshold IA", false)
    switch:Icon("\u{f72b}")
end

-- Obtém o nível atual do herói local
local function ObterNivelHeroi()
    local hero = Heroes.GetLocal()
    if not hero then return 1 end
    return NPC.GetCurrentLevel(hero)
end

-- Define o valor do threshold de HP% de acordo com o herói
local function DefinirThreshold(nomeHeroi, valor)
    if nomeHeroi == "npc_dota_hero_oracle" then
        local threshold = Menu.Find("Heróis", "Lista de Heróis", "Oracle", "Uso Automático", "False Promise", "HP% Threshold")
        if threshold then threshold:Set(valor) end
    elseif nomeHeroi == "npc_dota_hero_dazzle" then
        local threshold = Menu.Find("Heróis", "Lista de Heróis", "Dazzle", "Configurações Principais", "Shallow Grave", "HP Threshold")
        if threshold then threshold:Set(valor) end
    end
end

-- Verifica se o Threshold IA está ativado para o herói
local function ThresholdIAAtivo(nomeHeroi)
    if nomeHeroi == "npc_dota_hero_oracle" then
        local toggle = Menu.Find("Heróis", "Lista de Heróis", "Oracle", "Uso Automático", "False Promise", "Threshold IA")
        return toggle and toggle:Get()
    elseif nomeHeroi == "npc_dota_hero_dazzle" then
        local toggle = Menu.Find("Heróis", "Lista de Heróis", "Dazzle", "Configurações Principais", "Shallow Grave", "Threshold IA")
        return toggle and toggle:Get()
    end
    return false
end

-- Calcula o valor do HP% baseado no nível do herói
local function CalcularHPThreshold(nivel)
    local nivelMin, nivelMax = 1, 18
    local valorMin, valorMax = 20, 30

    nivel = math.max(nivelMin, math.min(nivelMax, nivel))
    local resultado = math.floor(valorMin + ((valorMax - valorMin) * (nivel - nivelMin)) / (nivelMax - nivelMin))
    return resultado
end

-- Lógica principal de atualização
script.OnUpdate = function()
    local hero = Heroes.GetLocal()
    if not hero then return end

    local nomeHeroi = NPC.GetUnitName(hero)
    if nomeHeroi ~= "npc_dota_hero_oracle" and nomeHeroi ~= "npc_dota_hero_dazzle" then return end
    if not ThresholdIAAtivo(nomeHeroi) then return end

    local nivel = ObterNivelHeroi()
    local threshold = CalcularHPThreshold(nivel)

    DefinirThreshold(nomeHeroi, threshold)
end

-- Carregamento do script
script.OnLoad = function()
    print("Script de Threshold Automático carregado!")
end

return script
