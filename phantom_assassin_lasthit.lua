local pa_lasthit = {}

-- Sistema de partículas para raios (de disruptor.lua)
local RadiusType = {DOTA=1,SOLID_GLOW=2,SOLID=3,DOTTED=4,FADE=5,DUST=6,FOG=7,PULSE=8,WAVES=9,LINK=10,INFINITY=11,ROUNDED=12,SLIDE=13}
local particle_names = {
    [RadiusType.DOTA]="materials/ui_mouseactions/range_display.vpcf",
    [RadiusType.SOLID_GLOW]="materials/radius_particle/glow_solid.vpcf",
    [RadiusType.SOLID]="materials/radius_particle/solid.vpcf",
    [RadiusType.DOTTED]="materials/radius_particle/dotted_finish.vpcf",
    [RadiusType.FADE]="materials/radius_particle/fade_finish.vpcf",
    [RadiusType.DUST]="materials/radius_particle/dust.vpcf",
    [RadiusType.FOG]="materials/radius_particle/fog.vpcf",
    [RadiusType.PULSE]="particles/new_particle_radius/new_particle_radius_1.vpcf",
    [RadiusType.WAVES]="particles/new_particle_radius/new_particle_radius_2.vpcf",
    [RadiusType.LINK]="particles/new_particle_radius/new_particle_radius_3.vpcf",
    [RadiusType.INFINITY]="particles/new_particle_radius/new_particle_radius_4.vpcf",
    [RadiusType.ROUNDED]="particles/new_particle_radius/new_particle_radius_5.vpcf",
    [RadiusType.SLIDE]="particles/new_particle_radius/new_particle_radius_6.vpcf"
}

-- Sistema de rastreamento de casts (similar ao mkdodge.lua)
local castData = {} -- Tabela para armazenar dados de castamento
local lastCastEntity = nil -- Última unidade castando
local ignoredCreeps = {} -- Tabela de creeps ignorados após cancelar cast

--#region UI
local tab = Menu.Create("Heroes", "Hero List", "Phantom Assassin", "PA Auto Lasthit")
local group = tab:Create("Principais")
local ui = {}
ui.enabled = group:Switch("Ativar Auto Lasthit", true, "\u{1F5E1}")
ui.hotkey = group:Bind("Tecla de Lasthit", Enum.ButtonCode.KEY_NONE)

-- Configurações de dano (simplificadas)
local damage_group = tab:Create("Configurações de Dano")
ui.enable_cast_monitoring = damage_group:Switch("Ativar Monitoramento de Cast", true)
ui.enable_cast_monitoring:ToolTip("Rastrear animação de cast e cancelar automaticamente se o alvo for morto")
ui.cast_start_threshold = damage_group:Slider("Limiar Inicial de HP (%)", 50, 200, 120)
ui.cast_start_threshold:ToolTip("Porcentagem do dano da adaga para verificar no início do cast")
ui.cast_end_threshold = damage_group:Slider("Limiar Final de HP (%)", 30, 150, 100)
ui.cast_end_threshold:ToolTip("Porcentagem do dano da adaga para verificar antes de completar o cast")
ui.tick_threshold = damage_group:Slider("Limiar de Ticks para Cancelar", 3, 20, 8)
ui.tick_threshold:ToolTip("Número de ticks antes de cancelar automaticamente o cast")
ui.use_max_damage = damage_group:Switch("Usar Dano Máximo", true)
ui.use_max_damage:ToolTip("Usar dano potencial máximo")

-- Configurações de alcance
local range_group = tab:Create("Configurações de Alcance")
ui.min_range = range_group:Slider("Alcance Mínimo", 0, 500, 300)
ui.min_range:ToolTip("Não usar adaga se o creep estiver mais perto que esta distância (0 = desativado)")
ui.max_range_override = range_group:Slider("Sobrescrever Alcance Máximo", 0, 1200, 0)
ui.max_range_override:ToolTip("Sobrescrever alcance da adaga (0 = usar alcance da habilidade)")

-- Configurações de creeps
local creep_group = tab:Create("Configurações de Creeps")
ui.target_enemy_creeps = creep_group:Switch("Atacar Creeps Inimigos", true)
ui.target_enemy_creeps:ToolTip("Atacar creeps inimigos da lane")
ui.target_neutral_creeps = creep_group:Switch("Atacar Creeps Neutros", false)
ui.target_neutral_creeps:ToolTip("Atacar creeps neutros")

-- Configurações de prioridades
local priority_group = tab:Create("Configurações de Prioridades")
ui.prioritize_flagbearer = priority_group:Switch("Priorizar Porta-Estandartes", true)
ui.prioritize_flagbearer:ToolTip("Porta-estandartes têm prioridade máxima (dão mais ouro)")
ui.prioritize_siege = priority_group:Switch("Priorizar Creeps de Cerco", true)
ui.prioritize_siege:ToolTip("Creeps de cerco (catapultas) têm alta prioridade")
ui.prioritize_ranged = priority_group:Switch("Priorizar Creeps Ranged", true)
ui.prioritize_ranged:ToolTip("Creeps ranged têm prioridade acima de creeps melee")
ui.flagbearer_priority = priority_group:Slider("Prioridade Porta-Estandartes", 1, 10, 10)
ui.flagbearer_priority:ToolTip("Valor de prioridade para porta-estandartes (maior = mais prioridade)")
ui.siege_priority = priority_group:Slider("Prioridade Cerco", 1, 10, 9)
ui.siege_priority:ToolTip("Valor de prioridade para creeps de cerco")
ui.ranged_priority = priority_group:Slider("Prioridade Ranged", 1, 10, 8)
ui.ranged_priority:ToolTip("Valor de prioridade para creeps ranged")
ui.melee_priority = priority_group:Slider("Prioridade Melee", 1, 10, 5)
ui.melee_priority:ToolTip("Valor de prioridade para creeps melee")
ui.neutral_priority = priority_group:Slider("Prioridade Neutros", 1, 10, 3)
ui.neutral_priority:ToolTip("Valor de prioridade para creeps neutros")

-- Configurações de debug
local debug_group = tab:Create("Debug")
ui.debug_mode = debug_group:Switch("Modo Debug", false)
ui.debug_mode:ToolTip("Mostrar informações de debug no console\nFUNCIONA apenas com a tecla de lasthit pressionada")

-- Configurações de visualização
local visual_group = tab:Create("Configurações de Visualização")

-- Criamos arrays para tipos de raios (como em disruptor.lua)
local radiusTypes = {}
local radiusTypeKeys = {}

-- Preenchemos as chaves
for k, v in pairs(RadiusType) do
    radiusTypeKeys[#radiusTypeKeys + 1] = k
end

-- Ordenamos as chaves
table.sort(radiusTypeKeys)

-- Criamos nomes legíveis (como em disruptor.lua com capitalize)
for i = 1, #radiusTypeKeys do
    local k = radiusTypeKeys[i]
    radiusTypes[#radiusTypes + 1] = string.capitalize((string.gsub(k, "_", " ")), true)
end

ui.particle_type = visual_group:Combo("Tipo de Partícula", radiusTypes, 0)
ui.particle_type:ToolTip("Estilo visual para círculos de alcance")
ui.range_color = visual_group:ColorPicker("Cor do Alcance", Color(0, 255, 0, 255))
ui.range_color:ToolTip("Cor para os círculos de alcance da adaga")
ui.draw_range = visual_group:Switch("Mostrar Alcance da Adaga", false)
ui.draw_range:ToolTip("Mostrar alcance de cast da adaga")
ui.draw_targets = visual_group:Switch("Mostrar Alvos Válidos", false)
ui.draw_targets:ToolTip("Destacar alvos válidos para lasthit\nCores: Vermelho=Porta-Estandartes, Dourado=Cerco, Verde=Ranged, Azul=Melee, Laranja=Neutros\nAnel branco externo = Alta prioridade (8+)")

-- MENU SEPARADO PARA AUTO KRIT DAGGER
local krit_tab = Menu.Create("Heroes", "Hero List", "Phantom Assassin", "Auto Krit Dagger")
local krit_main_group = krit_tab:Create("Configurações Principais")
ui.mark_enabled = krit_main_group:Switch("Auto-cast em Mark of Death", true, "\u{1F527}")
ui.mark_enabled:ToolTip("Jogar adaga automaticamente no inimigo com menor HP quando aparecer Mark of Death")
ui.mark_min_mana = krit_main_group:Slider("Mana Mínima (%)", 10, 90, 30)
ui.mark_min_mana:ToolTip("Porcentagem mínima de mana para funcionamento do auto-cast")

local krit_target_group = krit_tab:Create("Configurações de Alvos")
ui.mark_only_heroes = krit_target_group:Switch("Apenas Heróis", true)
ui.mark_only_heroes:ToolTip("Jogar adaga apenas em heróis quando Mark of Death estiver ativo")

local krit_debug_group = krit_tab:Create("Debug")
ui.mark_debug = krit_debug_group:Switch("Debug Mark of Death", false)
ui.mark_debug:ToolTip("Mostrar informações de debug para auto-cast Mark of Death")

-- Variáveis para partículas
local range_particles = {}
local target_particles = {}
local last_particle_update = 0
local last_dagger_range = 0
local last_min_range = 0

-- Variáveis locais
local last_cast_time = 0
local CAST_DELAY = 0.1 -- Delay mínimo entre casts

-- Variáveis para painel de UI animado do Mark of Death
local currentYOffset = 0
local targetYOffset = 0
local animationSpeed = 1
local colorAnimSpeed = 5
local colorAnimSpeed1 = 15
local rectCurrColor = Color(255, 0, 0, 0)
local letterCurrColor = Color(175, 175, 175, 0)
local currentRectX = nil
local currentRectW = nil
local interpSpeedX = 0.1
local initialized = false
local centerBg = nil
local abilityBevel = nil
local abilityButton = nil

-- Obter herói
local function GetMyHero()
    return Heroes.GetLocal()
end

-- Verificar se é Phantom Assassin
local function IsPhantomAssassin(hero)
    return hero and NPC.GetUnitName(hero) == "npc_dota_hero_phantom_assassin"
end

-- Obter habilidade Stifling Dagger
local function GetStiflingDagger(hero)
    return NPC.GetAbility(hero, "phantom_assassin_stifling_dagger")
end

-- Funções auxiliares para painel de UI animado
local function Initialize()
    if initialized then
        return
    end
    centerBg = Panorama.GetPanelByName("center_bg")
    if not centerBg then
        return
    end
    -- Para adaga usamos Ability0 (primeira habilidade da PA)
    local abilityPanel = Panorama.GetPanelByName("Ability0")
    if abilityPanel then
        abilityBevel = abilityPanel:FindChildTraverse("AbilityBevel")
        abilityButton = abilityPanel:FindChildTraverse("AbilityButton")
    end
    initialized = true
end

local function Approach(current, target, step)
    if (current < target) then
        return math.min(current + step, target)
    elseif (current > target) then
        return math.max(current - step, target)
    end
    return current
end

local function GetAbsolutePosition(panel)
    local x, y = 0, 0
    local cur = panel
    while cur do
        x = x + cur:GetXOffset()
        y = y + cur:GetYOffset()
        cur = cur:GetParent()
    end
    return x, y
end

local function GetAbsoluteBounds(panel)
    local x, y = GetAbsolutePosition(panel)
    local b = panel:GetBounds()
    local w = tonumber(b.w) or 0
    local h = tonumber(b.h) or 0
    return x, y, w, h
end

-- Determinar tipo de creep pelo nome
local function GetCreepType(creep)
    local unit_name = NPC.GetUnitName(creep) or ""
    unit_name = string.lower(unit_name)
    
    -- Verificar porta-estandartes (prioridade máxima)
    if string.find(unit_name, "flagbearer") then
        return "flagbearer"
    end
    
    -- Verificar creeps de cerco (catapultas)
    if string.find(unit_name, "siege") or string.find(unit_name, "catapult") then
        return "siege"
    end
    
    -- Verificar creeps ranged
    if string.find(unit_name, "ranged") then
        return "ranged"
    end
    
    -- Verificar creeps melee
    if string.find(unit_name, "melee") then
        return "melee"
    end
    
    -- Verificar creeps de lane (se não caiu nas categorias anteriores)
    if NPC.IsLaneCreep(creep) then
        return "melee" -- Por padrão consideramos melee se não conseguimos determinar
    end
    
    -- Todos os outros consideramos neutros
    return "neutral"
end

-- Obter prioridade do creep
local function GetCreepPriority(creep)
    local creep_type = GetCreepType(creep)
    
    if creep_type == "flagbearer" then
        return ui.prioritize_flagbearer:Get() and ui.flagbearer_priority:Get() or ui.melee_priority:Get()
    elseif creep_type == "siege" then
        return ui.prioritize_siege:Get() and ui.siege_priority:Get() or ui.melee_priority:Get()
    elseif creep_type == "ranged" then
        return ui.prioritize_ranged:Get() and ui.ranged_priority:Get() or ui.melee_priority:Get()
    elseif creep_type == "melee" then
        return ui.melee_priority:Get()
    elseif creep_type == "neutral" then
        return ui.neutral_priority:Get()
    end
    
    return 1 -- Prioridade padrão
end

-- Verificar presença do modificador Mark of Death
local function HasMarkOfDeath(hero)
    return NPC.HasModifier(hero, "modifier_phantom_assassin_mark_of_death")
end

-- Obter todos os alvos inimigos no raio
local function GetEnemyTargets(hero, max_range)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local all_entities = Entities.GetAll()
    local valid_enemies = {}
    
    for _, entity in pairs(all_entities) do
        if Entity.IsAlive(entity) and Entity.IsNPC(entity) then
            local npc = entity
            
            -- Verificar se é inimigo
            if not Entity.IsSameTeam(hero, npc) then
                local is_hero = NPC.IsHero(npc)
                local is_valid_target = false
                
                -- Se configuração "apenas heróis" estiver ativada, verificar apenas heróis
                if ui.mark_only_heroes:Get() then
                    if is_hero then
                        is_valid_target = true
                    end
                else
                    -- Aceitar heróis, creeps e outras unidades
                    if is_hero or NPC.IsCreep(npc) or Entity.IsNPC(npc) then
                        is_valid_target = true
                    end
                end
                
                if is_valid_target then
                    local enemy_pos = Entity.GetAbsOrigin(npc)
                    local distance = (enemy_pos - hero_pos):Length2D()
                    
                    -- Verificar alcance
                    if distance <= max_range then
                        table.insert(valid_enemies, npc)
                    end
                end
            end
        end
    end
    
    return valid_enemies
end

-- Procurar inimigo com menor HP
local function FindLowestHPEnemy(hero, dagger_range)
    local enemies = GetEnemyTargets(hero, dagger_range)
    local lowest_enemy = nil
    local lowest_hp = math.huge
    
    local debug_active = ui.mark_debug:Get()
    
    if debug_active then
        print("=== MARK OF DEATH PROCURA DE ALVOS ===")
        print("Inimigos encontrados no raio: " .. #enemies)
    end
    
    for _, enemy in pairs(enemies) do
        local enemy_hp = Entity.GetHealth(enemy)
        local enemy_name = NPC.GetUnitName(enemy) or "неизвестный"
        local is_hero = NPC.IsHero(enemy)
        
        if debug_active then
            print("Inimigo: " .. enemy_name .. " | HP: " .. enemy_hp .. " | Herói: " .. tostring(is_hero))
        end
        
        if enemy_hp < lowest_hp then
            lowest_hp = enemy_hp
            lowest_enemy = enemy
            
            if debug_active then
                print("  -> NOVO ALVO COM MENOR HP: " .. enemy_name .. " (" .. enemy_hp .. " HP)")
            end
        end
    end
    
    if debug_active then
        if lowest_enemy then
            local final_name = NPC.GetUnitName(lowest_enemy) or "desconhecido"
            print("ALVO FINAL: " .. final_name .. " com " .. lowest_hp .. " HP")
        else
            print("NENHUM INIMIGO VÁLIDO ENCONTRADO")
        end
        print("================================")
    end
    
    return lowest_enemy
end

-- Cálculo de dano da Stifling Dagger (simplificado)
local function CalculateDaggerDamage(hero, dagger, target)
    local dagger_level = Ability.GetLevel(dagger)
    if dagger_level == 0 then return 0 end
    
    -- Dano base por níveis: 65/70/75/80
    local base_damage_table = {65, 70, 75, 80}
    local base_damage = base_damage_table[dagger_level]
    
    -- Dano de ataque por níveis: 30%/45%/60%/75%
    local attack_factor_table = {30, 45, 60, 75}
    local attack_factor = attack_factor_table[dagger_level]
    
    -- Obter dano de ataque do herói
    local hero_damage
    if ui.use_max_damage:Get() then
        hero_damage = NPC.GetTrueMaximumDamage(hero)
    else
        hero_damage = NPC.GetTrueDamage(hero)
    end
    
    -- Dano total = dano base + (dano de ataque * fator / 100)
    local total_damage = base_damage + (hero_damage * attack_factor / 100)
    
    -- Verificar se alvo é catapulta (creep de cerco recebe apenas 50% de dano)
    if target then
        local target_type = GetCreepType(target)
        if target_type == "siege" then
            total_damage = total_damage * 0.5 -- 50% de dano para catapultas
        end
    end
    
    return math.floor(total_damage)
end

-- Obter alcance da Stifling Dagger
local function GetDaggerRange(dagger)
    local dagger_level = Ability.GetLevel(dagger)
    if dagger_level == 0 then return 0 end
    
    -- Alcance por níveis: 700/850/1000/1150
    local ranges = {700, 850, 1000, 1150}
    local base_range = ranges[dagger_level]
    
    -- Se override estiver definido, usá-lo
    local range_override = ui.max_range_override:Get()
    if range_override > 0 then
        return range_override
    end
    
    return base_range
end

-- Obter todos os creeps apropriados
local function GetValidCreeps(hero)
    local all_entities = Entities.GetAll()
    local valid_creeps = {}
    
    for _, entity in pairs(all_entities) do
        if Entity.IsAlive(entity) and Entity.IsNPC(entity) then
            local npc = entity
            
            -- Verificar se é creep
            if NPC.IsCreep(npc) then
                local is_enemy = not Entity.IsSameTeam(hero, npc)
                local is_lane_creep = NPC.IsLaneCreep(npc)
                local is_neutral = not is_lane_creep
                
                -- Verificar configurações de tipos de creeps
                local should_target = false
                if is_enemy and is_lane_creep and ui.target_enemy_creeps:Get() then
                    should_target = true
                elseif is_neutral and ui.target_neutral_creeps:Get() then
                    should_target = true
                end
                
                if should_target then
                    table.insert(valid_creeps, npc)
                end
            end
        end
    end
    
    return valid_creeps
end

-- Verificar se pode dar lasthit no creep (simplificado)
local function CanLastHitCreep(creep, hero, dagger)
    local creep_hp = Entity.GetHealth(creep)
    if creep_hp <= 0 then return false end
    
    -- Calcular dano
    local dagger_damage = CalculateDaggerDamage(hero, dagger, creep)
    
    -- Usar limiar inicial para verificação
    local threshold_percent = ui.cast_start_threshold:Get() / 100
    local effective_damage_threshold = dagger_damage * threshold_percent
    
    return creep_hp <= effective_damage_threshold, dagger_damage
end

-- Função para adicionar creep à lista de ignorados
local function AddIgnoredCreep(creep)
    if creep and Entity.IsAlive(creep) then
        local creep_hp = Entity.GetHealth(creep)
        ignoredCreeps[creep] = {
            hp = creep_hp,
            time = GameRules.GetGameTime()
        }
        
        local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
        if debug_active then
            local creep_name = NPC.GetUnitName(creep) or "desconhecido"
            print("ADICIONANDO A IGNORADOS: " .. creep_name .. " com HP: " .. creep_hp)
        end
    end
end

-- Função para verificar se creep está ignorado
local function IsCreepIgnored(creep)
    if not creep or not Entity.IsAlive(creep) then
        return false
    end
    
    local ignore_data = ignoredCreeps[creep]
    if not ignore_data then
        return false
    end
    
    local current_hp = Entity.GetHealth(creep)
    local stored_hp = ignore_data.hp
    
    -- Remover da lista de ignorados apenas se HP ficou MENOR que o armazenado (considerando regeneração)
    if current_hp < stored_hp then
        ignoredCreeps[creep] = nil
        
        local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
        if debug_active then
            local creep_name = NPC.GetUnitName(creep) or "desconhecido"
            print("REMOVENDO DE IGNORADOS: " .. creep_name .. " (HP diminuiu: " .. stored_hp .. " -> " .. current_hp .. ")")
        end
        
        return false
    end
    
    -- Também remover da lista se passou muito tempo (10 segundos)
    local current_time = GameRules.GetGameTime()
    if current_time - ignore_data.time > 10 then
        ignoredCreeps[creep] = nil
        
        local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
        if debug_active then
            local creep_name = NPC.GetUnitName(creep) or "desconhecido"
            print("REMOVENDO DE IGNORADOS: " .. creep_name .. " (passou muito tempo)")
        end
        
        return false
    end
    
    return true
end

-- Função para limpar creeps mortos da lista de ignorados
local function CleanupIgnoredCreeps()
    for creep, _ in pairs(ignoredCreeps) do
        if not creep or not Entity.IsAlive(creep) then
            ignoredCreeps[creep] = nil
        end
    end
end

-- Поиск лучшей цели для ластхита
local function FindBestLastHitTarget(hero, dagger, dagger_damage, dagger_range)
    local hero_pos = Entity.GetAbsOrigin(hero)
    local valid_creeps = GetValidCreeps(hero)
    local min_range = ui.min_range:Get()
    
    local best_creep = nil
    local best_priority = -1
    local best_distance = math.huge
    
    -- Debug apenas com hotkey pressionada
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    
    if debug_active then
        print("=== PA LASTHIT DEBUG ===")
        print("Posição do herói: " .. tostring(hero_pos))
        print("Alcance da adaga: " .. dagger_range)
        print("Alcance mínimo: " .. min_range)
        print("Creeps válidos encontrados: " .. #valid_creeps)
        print("Considerar 50% de dano em catapultas: SIM")
    end
    
    for _, creep in pairs(valid_creeps) do
        local creep_pos = Entity.GetAbsOrigin(creep)
        local distance = (creep_pos - hero_pos):Length2D()
        local creep_hp = Entity.GetHealth(creep)
        local creep_type = GetCreepType(creep)
        local creep_priority = GetCreepPriority(creep)
        
        -- Проверяем, не игнорируется ли этот крип
        if IsCreepIgnored(creep) then
            if debug_active then
                local creep_name = NPC.GetUnitName(creep) or "desconhecido"
                print("IGNORANDO CREEP: " .. creep_name .. " (na lista de ignorados)")
            end
            goto continue
        end
        
        -- Calcular dano para creep específico
        local can_kill, actual_dagger_damage = CanLastHitCreep(creep, hero, dagger)
        local threshold = math.floor(actual_dagger_damage * ui.cast_start_threshold:Get() / 100)
        
        if debug_active then
            local creep_name = NPC.GetUnitName(creep) or "desconhecido"
            local damage_note = ""
            if creep_type == "siege" then
                damage_note = " (50% de dano)"
            end
            print("Creep: " .. creep_name .. " | Tipo: " .. creep_type .. " | Prioridade: " .. creep_priority .. " | HP: " .. creep_hp .. " | Dano: " .. actual_dagger_damage .. damage_note .. " | Distância: " .. string.format("%.0f", distance) .. " | Pode matar: " .. tostring(can_kill) .. " (limiar: " .. threshold .. ")")
        end
        
        -- Verificar alcance: maior que mínimo (se não for 0), mas menor que máximo
        local min_range_check = (ui.min_range:Get() == 0) or (distance > min_range)
        if min_range_check and distance <= dagger_range then
            -- Verificar se pode dar lasthit
            if can_kill then
                -- Selecionar por prioridade, depois por distância
                local should_select = false
                
                if creep_priority > best_priority then
                    -- Maior prioridade
                    should_select = true
                elseif creep_priority == best_priority and distance < best_distance then
                    -- Mesma prioridade, mas mais perto
                    should_select = true
                end
                
                if should_select then
                    best_priority = creep_priority
                    best_distance = distance
                    best_creep = creep
                    
                    if debug_active then
                        print("  -> NOVO MELHOR ALVO: " .. (NPC.GetUnitName(creep) or "desconhecido") .. " (prioridade: " .. creep_priority .. ", distância: " .. string.format("%.0f", distance) .. ")")
                    end
                end
            end
        elseif debug_active then
            if not min_range_check and ui.min_range:Get() > 0 then
                print("  -> MUITO PERTO (distância: " .. string.format("%.0f", distance) .. ", mín: " .. min_range .. ")")
            elseif distance > dagger_range then
                print("  -> MUITO LONGE (distância: " .. string.format("%.0f", distance) .. ")")
            end
        end
        
        ::continue::
    end
    
    if debug_active then
        if best_creep then
            local final_damage = CalculateDaggerDamage(hero, dagger, best_creep)
            print("ALVO FINAL: " .. (NPC.GetUnitName(best_creep) or "desconhecido") .. " (prioridade: " .. best_priority .. ", distância: " .. string.format("%.0f", best_distance) .. ", dano: " .. final_damage .. ")")
        else
            print("NENHUM ALVO VÁLIDO ENCONTRADO")
        end
        print("========================")
    end
    
    return best_creep
end

-- Verificar configurações globais
local function CheckGlobalSettings()
    -- Verificar configurações principais se existirem
    if CreepsMain and not CreepsMain:Get() then
        return false
    end
    
    if LastHitHelper and not LastHitHelper:Get() then
        return false
    end
    
    if GlobalSettings and not GlobalSettings:Get() then
        return false
    end
    
    return true
end

-- Função para verificar animação de cast da Stifling Dagger
local function IsStiflingDaggerCast(unit, sequenceName, activity)
    if not unit or not IsPhantomAssassin(unit) then
        return false
    end
    
    -- Verificar pelo nome da sequência
    if sequenceName and string.find(string.lower(sequenceName), "stiflingdagger") then
        return true
    end
    
    -- Verificar por activity (1510 segundo exemplo)
    if activity == 1510 then
        return true
    end
    
    return false
end

-- Função para cancelar cast via HoldPosition (modificada)
local function CancelCast(hero, target)
    local player = Players.GetLocal()
    if player and hero then
        Player.HoldPosition(player, hero, false, false, true)
        
        -- Adicionar alvo à lista de ignorados
        if target then
            AddIgnoredCreep(target)
        end
        
        local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
        if debug_active then
            local target_name = target and NPC.GetUnitName(target) or "desconhecido"
            print("CANCELANDO CAST DA ADAGA - alvo não está mais disponível: " .. target_name)
        end
    end
end

-- Verificar HP do alvo em diferentes estágios do cast
local function CheckTargetHP(target, hero, dagger, stage)
    if not target or not Entity.IsAlive(target) then
        return false
    end
    
    local target_hp = Entity.GetHealth(target)
    if target_hp <= 0 then
        return false
    end
    
    local dagger_damage = CalculateDaggerDamage(hero, dagger, target)
    local threshold_percent
    
    if stage == "start" then
        threshold_percent = ui.cast_start_threshold:Get() / 100
    else -- "end"
        threshold_percent = ui.cast_end_threshold:Get() / 100
    end
    
    local effective_threshold = dagger_damage * threshold_percent
    
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    if debug_active then
        local target_name = NPC.GetUnitName(target) or "desconhecido"
        print("VERIFICAÇÃO HP [" .. stage .. "]: " .. target_name .. " | HP: " .. target_hp .. " | Limiar: " .. math.floor(effective_threshold) .. " | Dano: " .. dagger_damage)
    end
    
    return target_hp <= effective_threshold
end

-- Função principal de lasthit (modificada)
local function PerformLastHit()
    if not ui.enabled:Get() then return end
    
    local hero = GetMyHero()
    if not IsPhantomAssassin(hero) or not Entity.IsAlive(hero) then
        return
    end
    
    -- Debug apenas com hotkey pressionada
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    
    -- Verificar pressão de tecla
    if not ui.hotkey:IsDown() then
        return
    end
    
    -- Verificar configurações globais
    if not CheckGlobalSettings() then
        return
    end
    
    -- Obter habilidade
    local dagger = GetStiflingDagger(hero)
    if not dagger then
        if debug_active then
            print("Adaga não encontrada!")
        end
        return
    end
    
    -- Verificar se habilidade está pronta
    if not Ability.IsReady(dagger) then
        if debug_active then
            print("Adaga não está pronta!")
        end
        return
    end
    
    -- Verificar mana
    local mana_cost = Ability.GetManaCost(dagger)
    local current_mana = NPC.GetMana(hero)
    if current_mana < mana_cost then
        if debug_active then
            print("Mana insuficiente! Necessário: " .. mana_cost .. ", disponível: " .. current_mana)
        end
        return
    end
    
    -- Verificar delay entre casts
    local current_time = GameRules.GetGameTime()
    if current_time - last_cast_time < CAST_DELAY then
        return
    end
    
    -- Calcular dano e alcance
    local dagger_range = GetDaggerRange(dagger)
    
    if dagger_range == 0 then
        if debug_active then
            print("Alcance da adaga = 0 (habilidade não aprendida)")
        end
        return
    end
    
    -- Procurar alvo
    local target = FindBestLastHitTarget(hero, dagger, nil, dagger_range)
    
    if target then
        -- Verificar limiar inicial de HP
        if ui.enable_cast_monitoring:Get() then
            if not CheckTargetHP(target, hero, dagger, "start") then
                if debug_active then
                    local target_name = NPC.GetUnitName(target) or "desconhecido"
                    print("ALVO " .. target_name .. " NÃO ATENDE LIMIAR INICIAL DE HP")
                end
                return
            end
        end
        
        -- Castar dagger
        Ability.CastTarget(dagger, target)
        last_cast_time = current_time
        
        if debug_active then
            local target_name = NPC.GetUnitName(target) or "desconhecido"
            local final_damage = CalculateDaggerDamage(hero, dagger, target)
            print("CASTANDO ADAGA em " .. target_name .. " por " .. final_damage .. " de dano!")
        end
    end
end

-- Função principal de auto-cast em Mark of Death
local function PerformMarkOfDeathCast()
    if not ui.mark_enabled:Get() then return end
    
    local hero = GetMyHero()
    if not IsPhantomAssassin(hero) or not Entity.IsAlive(hero) then
        return
    end
    
    -- Verificar presença do modificador Mark of Death
    if not HasMarkOfDeath(hero) then
        return
    end
    
    local debug_active = ui.mark_debug:Get()
    
    if debug_active then
        print("=== MARK OF DEATH ATIVO ===")
    end
    
    -- Obter habilidade
    local dagger = GetStiflingDagger(hero)
    if not dagger then
        if debug_active then
            print("Adaga não encontrada!")
        end
        return
    end
    
    -- Verificar se habilidade está pronta
    if not Ability.IsReady(dagger) then
        if debug_active then
            print("Adaga não está pronta!")
        end
        return
    end
    
    -- Verificar mana
    local mana_cost = Ability.GetManaCost(dagger)
    local current_mana = NPC.GetMana(hero)
    local max_mana = NPC.GetMaxMana(hero)
    local mana_percent = (current_mana / max_mana) * 100
    local required_mana_percent = ui.mark_min_mana:Get()
    
    if mana_percent < required_mana_percent then
        if debug_active then
            print("Mana insuficiente! Necessário: " .. required_mana_percent .. "%, disponível: " .. string.format("%.1f", mana_percent) .. "%")
        end
        return
    end
    
    if current_mana < mana_cost then
        if debug_active then
            print("Mana insuficiente para cast! Necessário: " .. mana_cost .. ", disponível: " .. current_mana)
        end
        return
    end
    
    -- Verificar delay entre casts
    local current_time = GameRules.GetGameTime()
    if current_time - last_cast_time < CAST_DELAY then
        return
    end
    
    -- Obter alcance da adaga
    local dagger_range = GetDaggerRange(dagger)
    
    if dagger_range == 0 then
        if debug_active then
            print("Alcance da adaga = 0 (habilidade não aprendida)")
        end
        return
    end
    
    -- Procurar inimigo com menor HP
    local target = FindLowestHPEnemy(hero, dagger_range)
    
    if target then
        -- Castar dagger
        Ability.CastTarget(dagger, target)
        last_cast_time = current_time
        
        if debug_active then
            local target_name = NPC.GetUnitName(target) or "desconhecido"
            local target_hp = Entity.GetHealth(target)
            print("CASTANDO ADAGA COM MARK OF DEATH em " .. target_name .. " com " .. target_hp .. " HP!")
        end
    else
        if debug_active then
            print("Nenhum alvo válido no raio!")
        end
    end
end

-- Limpar todas as partículas
local function ClearAllParticles()
    -- Limpar partículas de raios
    for _, particle in pairs(range_particles) do
        if particle then
            Particle.Destroy(particle)
        end
    end
    range_particles = {}
    
    -- Очистка партиклей целей
    for _, particle in pairs(target_particles) do
        if particle then
            Particle.Destroy(particle)
        end
    end
    target_particles = {}
end

-- Criar partícula de raio
local function CreateRangeParticle(position, radius, color, key)
    local selIdx = ui.particle_type:Get() + 1
    local selectedKey = radiusTypeKeys[selIdx]
    local radiusType = RadiusType[selectedKey]
    local particleName = particle_names[radiusType]
    
    -- Debug apenas com hotkey pressionada
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    
    if debug_active then
        print("Criando partícula de raio: " .. key .. " | Tipo: " .. selectedKey .. " | Arquivo: " .. particleName)
        print("Posição: " .. tostring(position) .. " | Raio: " .. radius .. " | Cor: " .. tostring(color))
    end
    
    local particle = Particle.Create(particleName, Enum.ParticleAttachment.PATTACH_WORLDORIGIN, nil)
    if particle then
        Particle.SetControlPoint(particle, 0, position)
        Particle.SetControlPoint(particle, 1, Vector(color.r, color.g, color.b))
        Particle.SetControlPoint(particle, 2, Vector(radius, color.a, 0))
        Particle.SetControlPoint(particle, 3, Vector(1, 0, 0))
        
        if debug_active then
            print("Партикль радиуса успешно создан: " .. key)
        end
    else
        if debug_active then
            print("ОШИБКА создания партикля радиуса: " .. key)
        end
    end
    
    return particle
end

-- Criar partícula para alvo
local function CreateTargetParticle(position, radius, color, key)
    local particleName = particle_names[RadiusType.SOLID_GLOW] -- Usar SOLID_GLOW para alvos
    
    -- Debug apenas com hotkey pressionada
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    
    if debug_active then
        print("Criando partícula de alvo: " .. key .. " | Arquivo: " .. particleName)
    end
    
    local particle = Particle.Create(particleName, Enum.ParticleAttachment.PATTACH_WORLDORIGIN, nil)
    if particle then
        Particle.SetControlPoint(particle, 0, position)
        Particle.SetControlPoint(particle, 1, Vector(color.r, color.g, color.b))
        Particle.SetControlPoint(particle, 2, Vector(radius, color.a, 0))
        Particle.SetControlPoint(particle, 3, Vector(1, 0, 0))
        
        if debug_active then
            print("Партикль цели успешно создан: " .. key)
        end
    else
        if debug_active then
            print("ОШИБКА создания партикля цели: " .. key)
        end
    end
    
    return particle
end

-- Desenhar informações de debug e painel animado
local function DrawDebugInfo()
    if not ui.enabled:Get() then 
        ClearAllParticles()
        return 
    end
    
    -- Получаем героя в начале функции
    local hero = GetMyHero()
    if not IsPhantomAssassin(hero) or not Entity.IsAlive(hero) then
        ClearAllParticles()
        return
    end
    
    -- Визуализация работает только при зажатом бинде
    local show_visuals = ui.hotkey:IsDown()
    if show_visuals then
        local dagger = GetStiflingDagger(hero)
        if dagger then 
            local hero_pos = Entity.GetAbsOrigin(hero)
            local dagger_range = GetDaggerRange(dagger)
            local min_range = ui.min_range:Get()
            local current_time = GameRules.GetGameTime()
            
            -- Обновляем партикли радиусов только при изменении настроек или значений
            local range_settings_changed = (dagger_range ~= last_dagger_range) or (min_range ~= last_min_range)
            
            if ui.draw_range:Get() then
                if range_settings_changed or not range_particles["max_range"] then
                    -- Очищаем старые партикли радиусов
                    for key, particle in pairs(range_particles) do
                        if particle then
                            Particle.Destroy(particle)
                        end
                    end
                    range_particles = {}
                    
                    local range_color = ui.range_color:Get()
                    
                    -- Создаем новые партикли радиусов
                    local max_range_particle = CreateRangeParticle(hero_pos, dagger_range, range_color, "max_range")
                    if max_range_particle then
                        range_particles["max_range"] = max_range_particle
                    end
                    
                    -- Создаем партикль минимальной дальности только если она > 0
                    if min_range > 0 then
                        local min_range_color = Color(255, 100, 100, range_color.a)
                        local min_range_particle = CreateRangeParticle(hero_pos, min_range, min_range_color, "min_range")
                        if min_range_particle then
                            range_particles["min_range"] = min_range_particle
                        end
                    end
                    
                    last_dagger_range = dagger_range
                    last_min_range = min_range
                else
                    -- Обновляем позицию существующих партиклей радиусов
                    for key, particle in pairs(range_particles) do
                        if particle then
                            Particle.SetControlPoint(particle, 0, hero_pos)
                        end
                    end
                end
            else
                -- Очищаем партикли радиусов если отключена настройка
                for key, particle in pairs(range_particles) do
                    if particle then
                        Particle.Destroy(particle)
                    end
                end
                range_particles = {}
            end
            
            -- Обновляем партикли целей каждые 0.1 секунды
            if ui.draw_targets:Get() and (current_time - last_particle_update) > 0.1 then
                -- Очищаем старые партикли целей
                for key, particle in pairs(target_particles) do
                    if particle then
                        Particle.Destroy(particle)
                    end
                end
                target_particles = {}
                
                local valid_creeps = GetValidCreeps(hero)
                
                for i, creep in pairs(valid_creeps) do
                    local creep_pos = Entity.GetAbsOrigin(creep)
                    local distance = (creep_pos - hero_pos):Length2D()
                    
                    local min_range_check = (min_range == 0) or (distance > min_range)
                    if min_range_check and distance <= dagger_range then
                        local creep_type = GetCreepType(creep)
                        local creep_priority = GetCreepPriority(creep)
                        
                        local can_kill = CanLastHitCreep(creep, hero, dagger)
                        
                        if can_kill then
                            -- Цвет зависит от типа крипа
                            local circle_color
                            if creep_type == "flagbearer" then
                                circle_color = Color(255, 0, 0, 255) -- Красный для знаменосцев
                            elseif creep_type == "siege" then
                                circle_color = Color(255, 215, 0, 255) -- Золотой для осадных
                            elseif creep_type == "ranged" then
                                circle_color = Color(0, 255, 0, 255) -- Зеленый для рейнж
                            elseif creep_type == "melee" then
                                circle_color = Color(0, 200, 255, 255) -- Синий для мили
                            else -- neutral
                                circle_color = Color(255, 165, 0, 255) -- Оранжевый для нейтралов
                            end
                            
                            -- Основной круг для цели
                            local target_key = "target_" .. tostring(i)
                            local target_particle = CreateTargetParticle(creep_pos, 50, circle_color, target_key)
                            if target_particle then
                                target_particles[target_key] = target_particle
                            end
                            
                            -- Дополнительный круг для высокого приоритета
                            if creep_priority >= 8 then
                                local priority_key = "priority_" .. tostring(i)
                                local priority_particle = CreateTargetParticle(creep_pos, 70, Color(255, 255, 255, 150), priority_key)
                                if priority_particle then
                                    target_particles[priority_key] = priority_particle
                                end
                            end
                        else
                            -- Желтый круг для целей в радиусе но которых нельзя добить
                            local invalid_key = "invalid_" .. tostring(i)
                            local invalid_particle = CreateTargetParticle(creep_pos, 50, Color(255, 255, 0, 100), invalid_key)
                            if invalid_particle then
                                target_particles[invalid_key] = invalid_particle
                            end
                        end
                    end
                end
                
                last_particle_update = current_time
            end
        else
            ClearAllParticles()
        end
    else
        ClearAllParticles()
    end
    
    -- АНИМИРОВАННАЯ ПАНЕЛЬКА ДЛЯ MARK OF DEATH (всегда работает)
    local selectedUnits = Player.GetSelectedUnits(Players.GetLocal())
    if not selectedUnits then return end

    local isSelectedMain = false
    for _, u in ipairs(selectedUnits) do
        if u == hero then
            isSelectedMain = true
            break
        end
    end
    if not isSelectedMain then return end

    if not initialized then
        Initialize()
    end
    if not (initialized and centerBg and abilityBevel and abilityButton) then
        return
    end

    local isEnabled = ui.mark_enabled:Get()
    
    local x_cb, y_cb, w_cb, h_cb = GetAbsoluteBounds(centerBg)
    local x_bevel, y_bevel, w_bevel, h_bevel = GetAbsoluteBounds(abilityBevel)
    local x_btn, y_btn, w_btn, h_btn = GetAbsoluteBounds(abilityButton)

    if (currentRectX == nil) then
        currentRectX = x_bevel
    end
    if (currentRectW == nil) then
        currentRectW = w_bevel
    end

    local halfRectH = 5
    local actualYBot = y_cb
    local actualYTop = actualYBot - 3

    local blackRectX = currentRectX
    local blackRectY = actualYTop + currentYOffset
    local blackRectW = currentRectW
    local blackRectH = actualYBot - blackRectY

    local isTextVisible = Input.IsCursorInRect(blackRectX, blackRectY, blackRectW, blackRectH)
    local targetRectAlpha = 135

    -- Проверяем, полностью ли растянута панель
    local eps = 0.1
    local isFullyExpanded = (math.abs(currentRectX - x_btn) < eps) and (math.abs(currentRectW - w_btn) < eps)
    
    -- Текст появляется только если панель полностью растянута
    local targetLetterAlpha = (isTextVisible and isFullyExpanded) and 255 or 0

    rectCurrColor.a = Approach(rectCurrColor.a, targetRectAlpha, colorAnimSpeed)
    letterCurrColor.a = Approach(letterCurrColor.a, targetLetterAlpha, colorAnimSpeed1)

    if rectCurrColor.a == 0 then
        return
    end

    local desiredRectRGB = isEnabled and {r=0,g=255,b=0} or {r=255,g=0,b=0}
    rectCurrColor.r = Approach(rectCurrColor.r, desiredRectRGB.r, colorAnimSpeed)
    rectCurrColor.g = Approach(rectCurrColor.g, desiredRectRGB.g, colorAnimSpeed)
    rectCurrColor.b = Approach(rectCurrColor.b, desiredRectRGB.b, colorAnimSpeed)

    local colorRectX = currentRectX
    local colorRectY = (actualYTop - halfRectH) + currentYOffset
    local colorRectW = currentRectW
    local colorRectH = halfRectH

    -- Логика раскрытия всегда работает при enabled
    local isHoverAnyRect = false
    if (Input.IsCursorInRect(blackRectX, blackRectY, blackRectW, blackRectH) or 
        Input.IsCursorInRect(colorRectX, colorRectY, colorRectW, colorRectH)) then
        isHoverAnyRect = true
    end

    local vertDone = math.abs(currentYOffset - 0) < eps

    if (isHoverAnyRect and isFullyExpanded) then
        targetYOffset = -20
    else
        targetYOffset = 0
    end

    local targetRectX, targetRectW
    if isHoverAnyRect then
        targetRectX = x_btn
        targetRectW = w_btn
    elseif (not isHoverAnyRect and not vertDone) then
        targetRectX = x_btn
        targetRectW = w_btn
    else
        targetRectX = x_bevel
        targetRectW = w_bevel
    end

    currentRectX = currentRectX + ((targetRectX - currentRectX) * interpSpeedX)
    currentRectW = currentRectW + ((targetRectW - currentRectW) * interpSpeedX)

    if (currentYOffset > targetYOffset) then
        currentYOffset = math.max(currentYOffset - animationSpeed, targetYOffset)
    elseif (currentYOffset < targetYOffset) then
        currentYOffset = math.min(currentYOffset + animationSpeed, targetYOffset)
    end

    local lineColor = Color(0, 0, 0, math.min(125, math.floor(rectCurrColor.a)))
    local lineStart = Vec2(currentRectX, actualYTop + currentYOffset)
    local lineEnd = Vec2(currentRectX + currentRectW, actualYBot)
    Render.FilledRect(lineStart, lineEnd, lineColor, 0, Enum.DrawFlags.None)

    local fullX = currentRectX
    local fullY = (actualYTop - halfRectH) + currentYOffset
    local fullW = currentRectW
    local fullH = halfRectH

    Render.FilledRect(Vec2(fullX, fullY), Vec2(fullX + fullW, fullY + fullH), rectCurrColor, 3, Enum.DrawFlags.RoundCornersTop)
    Render.Shadow(Vec2(fullX + 1, fullY + 1), Vec2(fullX + fullW - 3, fullY + fullH), rectCurrColor, 20)
    
    -- Показываем текст всегда, но с анимированной альфой
    if letterCurrColor.a > 0 then
        local topY = actualYTop + currentYOffset
        local bottomY = actualYBot
        local midY = (topY + bottomY) * 0.5

        local statusText = isEnabled and "ON" or "OFF"
        local size = Render.TextSize(1, 20, statusText)
        local textX = (currentRectX + (currentRectW * 0.5)) - (size.x * 0.5)
        local textY = midY - (size.y * 0.5)

        Render.Text(1, 20, statusText, Vec2(textX, textY), letterCurrColor)
    end

    -- Обработка клика на черный прямоугольник для переключения Mark of Death
    if Input.IsCursorInRect(blackRectX, blackRectY, blackRectW, blackRectH) and Input.IsKeyDownOnce(Enum.ButtonCode.KEY_MOUSE1) then
        ui.mark_enabled:Set(not isEnabled)
    end
end

-- Atualização (modificado para adicionar monitoramento de casts)
function pa_lasthit.OnUpdate()
    -- Limpar creeps mortos da lista de ignorados
    CleanupIgnoredCreeps()
    
    PerformLastHit()
    PerformMarkOfDeathCast()
    
    -- Monitoramento de casts ativos (similar ao mkdodge.lua)
    if ui.enable_cast_monitoring:Get() then
        local hero = GetMyHero()
        if hero and IsPhantomAssassin(hero) and Entity.IsAlive(hero) then
            local dagger = GetStiflingDagger(hero)
            
            if dagger and Ability.IsInAbilityPhase(dagger) then
                if not castData[hero] then
                    castData[hero] = { tickCount = 0, target = nil, shouldCancel = false }
                end
                
                castData[hero].tickCount = castData[hero].tickCount + 1
                
                local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
                if debug_active then
                    print("Tick de cast da adaga: " .. castData[hero].tickCount)
                end
                
                -- Verificar alvo em diferentes estágios do cast
                if castData[hero].target then
                    local target = castData[hero].target
                    
                    -- Verificar se alvo ainda está vivo
                    if not Entity.IsAlive(target) then
                        if debug_active then
                            print("ALVO MORTO - cancelando cast")
                        end
                        CancelCast(hero, target)
                        castData[hero] = nil
                        return
                    end
                    
                    -- Verificar limiar final de HP antes de completar cast
                    if castData[hero].tickCount >= ui.tick_threshold:Get() then
                        if not CheckTargetHP(target, hero, dagger, "end") then
                            if debug_active then
                                local target_name = NPC.GetUnitName(target) or "desconhecido"
                                print("ALVO " .. target_name .. " NÃO ATENDE LIMIAR FINAL DE HP - cancelando cast")
                            end
                            CancelCast(hero, target)
                            castData[hero] = nil
                            return
                        end
                    end
                end
            else
                -- Habilidade não está mais em fase de cast
                castData[hero] = nil
            end
        end
    end
end

-- Desenho
function pa_lasthit.OnDraw()
    DrawDebugInfo()
end

-- Limpeza ao finalizar
function pa_lasthit.OnGameEnd()
    ClearAllParticles()
    -- Limpar todos os dados ao finalizar jogo
    castData = {}
    ignoredCreeps = {}
end

-- Callbacks para UI
ui.enabled:SetCallback(function(enabled)
    if not enabled then
        ClearAllParticles()
        -- Limpar dados de casts ao desativar
        castData = {}
        -- Limpar lista de creeps ignorados ao desativar
        ignoredCreeps = {}
    end
end)

ui.draw_range:SetCallback(function(enabled)
    if not enabled then
        -- Limpar apenas partículas de raios
        for _, particle in pairs(range_particles) do
            if particle then
                Particle.Destroy(particle)
            end
        end
        range_particles = {}
    end
end)

ui.draw_targets:SetCallback(function(enabled)
    if not enabled then
        -- Limpar apenas partículas de alvos
        for _, particle in pairs(target_particles) do
            if particle then
                Particle.Destroy(particle)
            end
        end
        target_particles = {}
    end
end)

-- Callback para mudança de tipo de partícula
ui.particle_type:SetCallback(function()
    -- Recriar todas as partículas de raios ao mudar tipo
    for _, particle in pairs(range_particles) do
        if particle then
            Particle.Destroy(particle)
        end
    end
    range_particles = {}
    last_dagger_range = -1 -- Принудительно обновляем
end)

-- Callback para mudança de cor
ui.range_color:SetCallback(function()
    -- Recriar partículas de raios ao mudar cor
    for _, particle in pairs(range_particles) do
        if particle then
            Particle.Destroy(particle)
        end
    end
    range_particles = {}
    last_dagger_range = -1 -- Принудительно обновляем
end)

-- Callbacks para configurações Mark of Death
ui.mark_enabled:SetCallback(function(enabled)
    if not enabled then
        print("Auto-cast Mark of Death desativado")
    else
        print("Auto-cast Mark of Death ativado")
    end
end)

-- Callbacks para monitoramento de casts
ui.enable_cast_monitoring:SetCallback(function(enabled)
    if not enabled then
        -- Limpar dados de casts ao desativar monitoramento
        castData = {}
        -- Limpar lista de creeps ignorados ao desativar monitoramento
        ignoredCreeps = {}
        print("Monitoramento de cast da adaga desativado")
    else
        print("Monitoramento de cast da adaga ativado")
    end
end)

-- Procurar configurações principais (se existirem)
local CreepsMain = Menu.Find("Heroes", "Hero List", "Settings", "Creeps", "Main")
local LastHitHelper = Menu.Find("Heroes", "Hero List", "Settings", "Last Hit Helper", "Enabled") 
local GlobalSettings = Menu.Find("Heroes", "Hero List", "Settings", "Global Settings", "Enabled")
--#endregion UI

-- Handler de animação de unidades (similar ao mkdodge.lua)
function pa_lasthit.OnUnitAnimation(animation)
    if not ui.enable_cast_monitoring:Get() then
        return
    end
    
    local unit = animation.unit
    if not unit then return end
    
    local hero = GetMyHero()
    if not hero or unit ~= hero then return end
    
    local sequenceName = animation.sequenceName
    local activity = animation.activity
    
    local debug_active = ui.debug_mode:Get() and ui.hotkey:IsDown()
    
    -- Verificar se é cast da Stifling Dagger
    if IsStiflingDaggerCast(unit, sequenceName, activity) then
        if debug_active then
            print("=== DETECTADO CAST DA STIFLING DAGGER ===")
            print("Sequence: " .. tostring(sequenceName))
            print("Activity: " .. tostring(activity))
            print("Castpoint: " .. tostring(animation.castpoint))
        end
        
        -- Inicializar dados do cast
        if not castData[unit] then
            castData[unit] = {
                tickCount = 0,
                target = nil,
                startTime = GameRules.GetGameTime(),
                shouldCancel = false
            }
            
            -- Tentar encontrar alvo do cast (último alvo selecionado)
            local dagger = GetStiflingDagger(hero)
            if dagger then
                local dagger_range = GetDaggerRange(dagger)
                local potential_target = FindBestLastHitTarget(hero, dagger, nil, dagger_range)
                if potential_target then
                    castData[unit].target = potential_target
                    
                    if debug_active then
                        local target_name = NPC.GetUnitName(potential_target) or "desconhecido"
                        print("ALVO DO CAST: " .. target_name)
                    end
                end
            end
        end
        
        lastCastEntity = unit
    end
end

return pa_lasthit 