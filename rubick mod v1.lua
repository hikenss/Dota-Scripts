-- Rubick Auto-Ult Script with Improved Blink Logic for Cast-to-Position Spells
--Error1: Rubick al robar un poder piensa que el poder no tiene cd y blinkea(porque no se guarda que rubick tiene ese poder en cd)
--Error2: Rubick prioriza poderes que necesita acercarce aun cuando tiene un poder con mas rango de casteo
--Error3: Refresher no usar, puede usar mal el refresh por blinkear mal(se puede arreglar con codigo ó usar un offset en el blink de  -200)
--Error4: Si tienes como prioridad Black Hole > Reverse Polarity luego de usar Black Hole usará Reverse Polarity en el lugar(fuera de rango)

local script = {}

-- Log file
local log_file = nil
local function LogToFile(message)
    if not log_file then
        log_file = io.open("c:\\UB\\scripts\\rubick_log.txt", "a")
    end
    if log_file then
        log_file:write(os.date("%H:%M:%S") .. " " .. message .. "\n")
        log_file:flush()
    end
    print("[RubickUlt] " .. message)
end

-- Список украденных способностей для комбинации
local stolen_spells = {
    "axe_berserkers_call",
    "earthshaker_echo_slam",
    "tidehunter_ravage",
    "treant_overgrowth",
    "obsidian_destroyer_sanity_eclipse",
    "puck_dream_coil",
    "storm_spirit_electric_vortex",
    "enigma_black_hole",
    "magnataur_reverse_polarity",
    "faceless_void_chronosphere",
    "disruptor_static_storm",
    "elder_titan_earth_splitter",
    "invoker_chaos_meteor",
    "leshrac_diabolic_edict",
    "phoenix_supernova",
    "sand_king_epicenter",
    "warlock_rain_of_chaos",
    "witch_doctor_death_ward",
    "winter_wyvern_winters_curse",
    "mars_arena_of_blood",
    "medusa_stone_gaze",
    "death_prophet_exorcism",
    "dawnbreaker_solar_guardian",
    "silencer_global_silence",
    "zuus_thundergods_wrath",
    "crystal_maiden_freezing_field",
    "dark_willow_terrorize",
}

-- Сопоставление технических имен и дружественных имен спеллов
local spell_friendly_names = {
    ["axe_berserkers_call"] = "Berserker's Call",
    ["earthshaker_echo_slam"] = "Echo Slam",
    ["tidehunter_ravage"] = "Ravage",
    ["treant_overgrowth"] = "Overgrowth",
    ["obsidian_destroyer_sanity_eclipse"] = "Sanity's Eclipse",
    ["puck_dream_coil"] = "Dream Coil",
    ["storm_spirit_electric_vortex"] = "Electric Vortex",
    ["enigma_black_hole"] = "Black Hole",
    ["magnataur_reverse_polarity"] = "Reverse Polarity",
    ["faceless_void_chronosphere"] = "Chronosphere",
    ["disruptor_static_storm"] = "Static Storm",
    ["elder_titan_earth_splitter"] = "Earth Splitter",
    ["invoker_chaos_meteor"] = "Chaos Meteor",
    ["leshrac_diabolic_edict"] = "Diabolic Edict",
    ["phoenix_supernova"] = "Supernova",
    ["sand_king_epicenter"] = "Epicenter",
    ["warlock_rain_of_chaos"] = "Rain of Chaos",
    ["witch_doctor_death_ward"] = "Death Ward",
    ["winter_wyvern_winters_curse"] = "Winter's Curse",
    ["mars_arena_of_blood"] = "Arena of Blood",
    ["medusa_stone_gaze"] = "Stone Gaze",
    ["death_prophet_exorcism"] = "Exorcism",
    ["dawnbreaker_solar_guardian"] = "Solar Guardian",
    ["silencer_global_silence"] = "Global Silence",
    ["zuus_thundergods_wrath"] = "Thundergod's Wrath",
    ["crystal_maiden_freezing_field"] = "Freezing Field",
    ["dark_willow_terrorize"] = "Terrorize",
}

-- Специальные ключи радиуса для некоторых способностей
local radius_keys = {
    magnataur_reverse_polarity = "pull_radius",
    puck_dream_coil            = "coil_radius",    -- <<< добавлено для Dream Coil
}

-- UI
local tab = Menu.Create("Heroes", "Hero List", "Rubick", "Usar Ultis Automaticamente")
local group = tab:Create("Principal")
local ui = {}
ui.enable        = group:Switch("Ativar Script", false, "\u{f0e7}")
ui.mode          = group:Combo("Modo de Uso", {"Alternar Manual", "Sempre Automático"}, 0)
ui.cast_key      = group:Bind("Tecla de Alternância", Enum.ButtonCode.KEY_T)
ui.min_targets   = group:Slider("Mín Alvos", 1, 5, 1, function(v) return tostring(v) end)
ui.blink_offset  = group:Slider("Deslocamento do Blink", -200, 200, 0, function(v) return tostring(v) .. " unidades" end)
ui.min_allies    = group:Slider("Mín Aliados Próximos", 0, 4, 0, function(v) return v == 0 and "Desativado" or tostring(v) end)
ui.ally_range    = group:Slider("Range de Aliados", 500, 2000, 1000, function(v) return tostring(v) .. " unidades" end)
ui.min_diff      = group:Slider("Diferença Mín (Inimigos - Aliados)", 0, 5, 0, function(v) return v == 0 and "Desativado" or tostring(v) end)
ui.auto_status   = group:Label("Modo Auto: DESLIGADO", "\u{f204}")
ui.radius_color  = group:ColorPicker("Cor Dentro do Alcance", Color(0,255,0), "\u{f53f}")
ui.out_of_range_color = group:ColorPicker("Cor Fora do Alcance", Color(255,0,0), "\u{f53f}")
ui.use_refresher = group:Switch("Usar Refresher Orb", false, "\u{f021}")
ui.visual_debug  = group:Switch("Debug Visual", false, "\u{f075}")

local spell_group = tab:Create("Seleção de Spells e Alvos")

-- Seletor de inimigos alvo
local ui_enemy_selector = nil
local enemy_selector_created = false

local function populate_enemy_selector()
    local enemies = {}
    local seen = {}
    for _, h in pairs(Heroes.GetAll()) do
        if h ~= myHero and not Entity.IsSameTeam(h, myHero) then
            local name = NPC.GetUnitName(h)
            if not seen[name] then
                seen[name] = true
                local heroName = string.gsub(name, "npc_dota_hero_", "")
                heroName = heroName:gsub("^%l", string.upper):gsub("_(%l)", function(c) return " " .. c:upper() end)
                table.insert(enemies, {heroName, "panorama/images/heroes/icons/" .. name .. "_png.vtex_c", true})
            end
        end
    end
    return enemies
end

ui.enable_custom_heroes = spell_group:Switch("Usar Seleção de Inimigos Alvo", false, "\u{f05b}")
ui.enable_custom_heroes:ToolTip("Ativa o sistema de prioridade de inimigos. Quando ativado, só atacará os heróis selecionados abaixo.")
ui.custom_min_targets = spell_group:Slider("Mín Alvos (Inimigos Selecionados)", 1, 5, 1, function(v) return tostring(v) end)
ui.custom_min_targets:Visible(false)

ui.enable_custom_heroes:SetCallback(function(enabled)
    ui.custom_min_targets:Visible(enabled)
end)

ui.spell_select = spell_group:MultiSelect(
    "Spells para Usar (Auto)", {
        {"Berserker's Call", "panorama/images/spellicons/axe_berserkers_call_png.vtex_c", true},
        {"Echo Slam", "panorama/images/spellicons/earthshaker_echo_slam_png.vtex_c", true},
        {"Ravage", "panorama/images/spellicons/tidehunter_ravage_png.vtex_c", true},
        {"Overgrowth", "panorama/images/spellicons/treant_overgrowth_png.vtex_c", true},
        {"Sanity's Eclipse", "panorama/images/spellicons/obsidian_destroyer_sanity_eclipse_png.vtex_c", true},
        {"Dream Coil", "panorama/images/spellicons/puck_dream_coil_png.vtex_c", true},
        {"Electric Vortex", "panorama/images/spellicons/storm_spirit_electric_vortex_png.vtex_c", true},
        {"Black Hole", "panorama/images/spellicons/enigma_black_hole_png.vtex_c", true},
        {"Reverse Polarity", "panorama/images/spellicons/magnataur_reverse_polarity_png.vtex_c", true},
        {"Chronosphere", "panorama/images/spellicons/faceless_void_chronosphere_png.vtex_c", true},
        {"Static Storm", "panorama/images/spellicons/disruptor_static_storm_png.vtex_c", true},
        {"Earth Splitter", "panorama/images/spellicons/elder_titan_earth_splitter_png.vtex_c", true},
        {"Chaos Meteor", "panorama/images/spellicons/invoker_chaos_meteor_png.vtex_c", true},
        {"Diabolic Edict", "panorama/images/spellicons/leshrac_diabolic_edict_png.vtex_c", true},
        {"Supernova", "panorama/images/spellicons/phoenix_supernova_png.vtex_c", true},
        {"Epicenter", "panorama/images/spellicons/sandking_epicenter_png.vtex_c", true},
        {"Rain of Chaos", "panorama/images/spellicons/warlock_rain_of_chaos_png.vtex_c", true},
        {"Death Ward", "panorama/images/spellicons/witch_doctor_death_ward_png.vtex_c", true},
        {"Winter's Curse", "panorama/images/spellicons/winter_wyvern_winters_curse_png.vtex_c", true},
        {"Arena of Blood", "panorama/images/spellicons/mars_arena_of_blood_png.vtex_c", true},
        {"Stone Gaze", "panorama/images/spellicons/medusa_stone_gaze_png.vtex_c", true},
        {"Exorcism", "panorama/images/spellicons/death_prophet_exorcism_png.vtex_c", true},
        {"Solar Guardian", "panorama/images/spellicons/dawnbreaker_solar_guardian_png.vtex_c", true},
        {"Global Silence", "panorama/images/spellicons/silencer_global_silence_png.vtex_c", true},
        {"Thundergod's Wrath", "panorama/images/spellicons/zuus_thundergods_wrath_png.vtex_c", true},
        {"Freezing Field", "panorama/images/spellicons/crystal_maiden_freezing_field_png.vtex_c", true},
        {"Terrorize", "panorama/images/spellicons/dark_willow_terrorize_png.vtex_c", true},
    },
    true
)

-- Tecla para cast manual de outras habilidades roubadas
ui.manual_cast_key = spell_group:Bind("Tecla de Cast Manual (Outras Skills)", Enum.ButtonCode.KEY_G)
ui.manual_cast_key:ToolTip("Usa qualquer habilidade roubada que NÃO esteja na lista do Auto Use. Cast no alvo/cursor.")
ui.auto_cast_manual = spell_group:Switch("Auto-Cast de Skills Manuais", false, "\u{f0e7}")
ui.auto_cast_manual:ToolTip("Usa automaticamente as habilidades roubadas (não listadas no Auto Use) quando inimigo estiver no range.")

-- Переменные состояния и частица
local particle, need_update_particle, need_update_color = nil, false, false
local currentAOE = 0
local blinkDelay   = 0.03   -- задержка после блинка перед кастом
local spellDelay   = 0.5   -- задержка между кастами заклинаний
local castState    = 0      -- 0: начальное состояние, 1: после блинка, 2: после первых скиллов, 3: после рефрешера, 4: после повторных скиллов
local stateTime    = 0
local stored       = {}     -- хранит данные между шагами
local myHero       = nil
local inBlinkRange = false  -- флаг для отслеживания, в рендже ли точка для блинка
local ordersExecuted = false -- флаг для контроля отправки ордеров
local castDelay = 0.5       -- задержка перед переходом к следующему состоянию (в секундах)
local executionMode = 0     -- 0: нет активного выполнения, 1: выполняем близкую логику, 2: выполняем логику блинка
local secondaryTimer = 0    -- таймер для каста второго заклинания
local lastManualKeyState = false
lastManualCast = ""
lastManualCastTime = 0
lastManualSpellCheck = ""
-- Função para obter habilidades roubadas que NÃO estão na lista do auto use
local function GetManualCastableSpells()
    if not myHero then 
        LogToFile("GetManualCastableSpells: myHero é nil")
        return {} 
    end
    
    local manual_spells = {}
    local debug_info = "Abilities: "
    local friendly_to_technical = {}
    for tech, friendly in pairs(spell_friendly_names) do
        friendly_to_technical[friendly] = tech
    end
    
    -- Cria set das habilidades do auto use (apenas as selecionadas)
    local auto_use_spells = {}
    if ui.spell_select then
        local selected_auto = ui.spell_select:ListEnabled()
        LogToFile("GetManualCastableSpells: " .. #selected_auto .. " habilidades no auto use")
        for _, friendly in ipairs(selected_auto) do
            local tech = friendly_to_technical[friendly]
            if tech then
                auto_use_spells[tech] = true
            end
        end
    end
    
    LogToFile("GetManualCastableSpells: Procurando habilidades roubadas...")
    for i = 0, 23 do
        local ability = NPC.GetAbilityByIndex(myHero, i)
        if ability then
            local abilityName = Ability.GetName(ability)
            local level = Ability.GetLevel(ability)
            
            -- Ignora APENAS as 4 habilidades BASE do Rubick (as outras são roubadas mesmo tendo "rubick_" no nome)
            local is_rubick_base = (abilityName == "rubick_telekinesis" 
               or abilityName == "rubick_fade_bolt" 
               or abilityName == "rubick_arcane_supremacy"
               or abilityName == "rubick_spell_steal"
               or abilityName == "rubick_hidden1"
               or abilityName == "rubick_hidden2"
               or abilityName == "rubick_hidden3"
               or abilityName == "rubick_empty1"
               or abilityName == "rubick_empty2"
               or abilityName == "ability_lamp_use"
               or abilityName == "attribute_bonus"
               or string.match(abilityName, "special_bonus")
               or abilityName == "")
            
            if not is_rubick_base and level and level > 0 then
                LogToFile("GetManualCastableSpells: Encontrada " .. abilityName .. " (Lv" .. level .. ")")
                debug_info = debug_info .. abilityName .. "(Lv" .. level .. ") "
                local is_in_auto_list = auto_use_spells[abilityName]
                LogToFile("GetManualCastableSpells: Está na lista auto? " .. tostring(is_in_auto_list))
                
                if not is_in_auto_list then
                    local isCastable = Ability.IsCastable(ability, NPC.GetMana(myHero))
                    LogToFile("GetManualCastableSpells: IsCastable? " .. tostring(isCastable))
                    if isCastable then
                        table.insert(manual_spells, {ability = ability, name = abilityName})
                        debug_info = debug_info .. "[OK] "
                        LogToFile("GetManualCastableSpells: Adicionada à lista manual")
                    else
                        debug_info = debug_info .. "[CD/Mana] "
                        LogToFile("GetManualCastableSpells: Não castable (CD ou mana)")
                    end
                else
                    debug_info = debug_info .. "[Auto] "
                    LogToFile("GetManualCastableSpells: Ignorada (está no auto use)")
                end
            end
        end
    end
    
    LogToFile("GetManualCastableSpells: Total de habilidades manuais: " .. #manual_spells)
    lastManualSpellCheck = debug_info
    return manual_spells
end



-- Función auxiliar para encontrar la mejor posición 
local function findBestPositionForEnemies(enemies, radius, minCount)
    local positions = {}

    for _, h in ipairs(enemies) do
        table.insert(positions, {pos = Entity.GetAbsOrigin(h)})
    end
    for i = 1, #enemies - 1 do
        for j = i + 1, #enemies do
            local p1 = Entity.GetAbsOrigin(enemies[i])
            local p2 = Entity.GetAbsOrigin(enemies[j])
            local mid = Vector((p1.x + p2.x) / 2, (p1.y + p2.y) / 2, (p1.z + p2.z) / 2)
            table.insert(positions, {pos = mid})
        end
    end
    
    local bestPos, bestCount = nil, 0
    for _, cand in ipairs(positions) do
        local cnt = 0
        for _, h in ipairs(enemies) do
            local p = Entity.GetAbsOrigin(h)
            if (Vector(cand.pos.x, cand.pos.y, 0) - Vector(p.x, p.y, 0)):Length2D() <= radius then
                cnt = cnt + 1
            end
        end
        if cnt >= minCount and cnt > bestCount then
            bestCount, bestPos = cnt, cand.pos
        end
    end
    
    return bestPos, bestCount
end

-- Función auxiliar para encontrar el héroe más cercano a una posición
local function findNearestHero(heroes, position)
    local bestHero, bestDist = nil, math.huge
    for _, h in ipairs(heroes) do
        local p = Entity.GetAbsOrigin(h)
        local d = (Vector(p.x, p.y, 0) - Vector(position.x, position.y, 0)):Length2D()
        if d < bestDist then
            bestDist, bestHero = d, h
        end
    end
    return bestHero
end

-- Função para obter inimigos selecionados
local function getSelectedEnemies()
    if not ui.enable_custom_heroes:Get() or not ui_enemy_selector then
        return nil
    end
    
    local selected = ui_enemy_selector:ListEnabled()
    local enemies = {}
    
    for _, heroName in ipairs(selected) do
        local techName = "npc_dota_hero_" .. heroName:lower():gsub(" ", "_")
        for _, h in pairs(Heroes.GetAll()) do
            if NPC.GetUnitName(h) == techName and Entity.IsAlive(h) and not Entity.IsSameTeam(h, myHero) then
                table.insert(enemies, h)
                break
            end
        end
    end
    
    return #enemies > 0 and enemies or nil
end
local function countNearbyAllies(position, range)
    local count = 0
    for _, h in pairs(Heroes.GetAll()) do
        if h ~= myHero and Entity.IsAlive(h) and Entity.IsSameTeam(h, myHero) and not NPC.IsIllusion(h) then
            local pos = Entity.GetAbsOrigin(h)
            local dist = (Vector(pos.x, pos.y, 0) - Vector(position.x, position.y, 0)):Length2D()
            if dist <= range then
                count = count + 1
            end
        end
    end
    return count
end

-- Variables para toggle mode
local auto_mode_active = false  
local last_key_state = false   

-- Panel visual config
local PanelConfig = {
    X = 50,
    Y = 100,
    Width = 120,
    Height = 30,
    BorderRadius = 8
}

local PanelColors = {
    Header = Color(10, 10, 10, 200),
    TextAuto = Color(46, 204, 113, 255),   
    TextOn = Color(52, 152, 219, 255),       
    TextOff = Color(231, 76, 60, 255),     
    Shadow = Color(0, 0, 0, 100)
}
-- UI callbacks
ui.enable:SetCallback(function(enabled)
    if enabled then
        print("[RubickUlt] СКРИПТ АКТИВИРОВАН")
    else
        print("[RubickUlt] СКРИПТ ДЕАКТИВИРОВАН")
    end
end)
-- Función para actualizar el estado visual
local function UpdateAutoModeUI()
    if ui.auto_status then
        local status_text = auto_mode_active and "Auto Mode: ON" or "Auto Mode: OFF"
        ui.auto_status:ForceLocalization(status_text)
    end
end
-- Función para dibujar el panel visual
local function DrawModePanel()
    if not ui.enable:Get() then return end
    if not myHero or not Entity.IsAlive(myHero) or NPC.GetUnitName(myHero) ~= "npc_dota_hero_rubick" then return end
    local font = Render.LoadFont("Tahoma", Enum.FontCreate.FONTFLAG_ANTIALIAS)
    
    local mode = ui.mode:Get()
    local status_text = ""
    local text_color = PanelColors.TextOff
    
    if mode == 1 then  
        status_text = "Rubick: Auto"
        text_color = PanelColors.TextAuto
    else 
        if auto_mode_active then
            status_text = "Rubick: On"
            text_color = PanelColors.TextOn
        else
            status_text = "Rubick: Off"
            text_color = PanelColors.TextOff
        end
    end
    
    Render.Blur(
        Vec2(PanelConfig.X, PanelConfig.Y),
        Vec2(PanelConfig.X + PanelConfig.Width, PanelConfig.Y + PanelConfig.Height),
        8, 0.9, PanelConfig.BorderRadius
    )
    
    Render.FilledRect(
        Vec2(PanelConfig.X, PanelConfig.Y),
        Vec2(PanelConfig.X + PanelConfig.Width, PanelConfig.Y + PanelConfig.Height),
        PanelColors.Header,
        PanelConfig.BorderRadius
    )
    
    local textSize = Render.TextSize(font, 14, status_text)
    local textX = PanelConfig.X + (PanelConfig.Width - textSize.x) / 2
    local textY = PanelConfig.Y + (PanelConfig.Height - textSize.y) / 2
    
    Render.Text(font, 14, status_text, Vec2(textX + 1, textY + 1), PanelColors.Shadow)
    Render.Text(font, 14, status_text, Vec2(textX, textY), text_color)
end
ui.visual_debug:SetCallback(function() need_update_particle = true end)
ui.radius_color:SetCallback(function() need_update_color = true end)
ui.out_of_range_color:SetCallback(function() need_update_color = true end)
ui.mode:SetCallback(function(mode) 
    print("[RubickUlt] РЕЖИМ ИЗМЕНЕН: " .. (mode == 0 and "Ручной" or "Автоматический"))
end)
ui.min_targets:SetCallback(function(val)
    print("[RubickUlt] НАСТРОЙКА: Минимальное количество целей = " .. val)
end)
ui.use_refresher:SetCallback(function(enabled)
    print("[RubickUlt] НАСТРОЙКА: Использование Refresher Orb " .. (enabled and "включено" or "выключено"))
end)
-- Проверка типов спеллов
local function isNoTargetSpell(name)
    return name == "axe_berserkers_call"
        or name == "earthshaker_echo_slam"
        or name == "treant_overgrowth"
        or name == "tidehunter_ravage"
        or name == "magnataur_reverse_polarity"
        or name == "storm_spirit_electric_vortex"
        or name == "phoenix_supernova"
        or name == "sand_king_epicenter"
        or name == "death_prophet_exorcism"
        or name == "medusa_stone_gaze"
        or name == "silencer_global_silence"
        or name == "zuus_thundergods_wrath"
        or name == "crystal_maiden_freezing_field"
        or name == "leshrac_diabolic_edict"
end

local function isChannelSpell(name)
    return name == "enigma_black_hole"
        or name == "witch_doctor_death_ward"
end

local function isChannelPrepSpell(name)
    return name == "sand_king_epicenter"
end

local function isGlobalSpell(name)
    return name == "silencer_global_silence"
        or name == "zuus_thundergods_wrath"
end

-- Поиск оптимальной точки AOE
local function FindBestAOEPoint(radius, minCount)
    local me = myHero
    local enemies = {}
    
    -- Recopilar enemigos según la configuración
    local selectedEnemies = getSelectedEnemies()
    if selectedEnemies then
        enemies = selectedEnemies
        minCount = ui.custom_min_targets:Get()
    else
        for _, h in pairs(Heroes.GetAll()) do
            if h ~= me and Entity.IsAlive(h) and not Entity.IsSameTeam(h, me) and not NPC.IsIllusion(h) then
                table.insert(enemies, h)
            end
        end
    end
    
    if #enemies == 0 then return nil, nil, 0 end
    
    local bestPos, bestCount = findBestPositionForEnemies(enemies, radius, minCount)

    if bestPos and bestCount >= minCount then
        local minAllies = ui.min_allies:Get()
        if minAllies > 0 then
            local allyRange = ui.ally_range:Get()
            local nearbyAllies = countNearbyAllies(bestPos, allyRange)
            if nearbyAllies < minAllies then
                return nil, nil, 0
            end
        end
        
        local minDiff = ui.min_diff:Get()
        if minDiff > 0 then
            local allyRange = ui.ally_range:Get()
            local nearbyAllies = countNearbyAllies(bestPos, allyRange)
            if (bestCount - nearbyAllies) < minDiff then
                return nil, nil, 0
            end
        end
        
        local bestHero = findNearestHero(enemies, bestPos)
        return bestHero, bestPos, bestCount
    end
    
    return nil, nil, 0
end


-- Отрисовка радиуса (не меняется)
local function custom_radius_point(origin, radius, inRange)
    if not ui.visual_debug:Get() or radius <= 0 or not origin then
        if particle then
            Particle.Destroy(particle)
            particle = nil
        end
        return
    end
    local color = inRange and ui.radius_color:Get() or ui.out_of_range_color:Get()
    if not particle or need_update_particle then
        if particle then Particle.Destroy(particle) end
        particle = Particle.Create("particles/ui_mouseactions/drag_selected_ring.vpcf", Enum.ParticleAttachment.PATTACH_CUSTOMORIGIN)
        Particle.SetControlPoint(particle, 1, Vector(color.r, color.g, color.b))
        need_update_particle = false
    end
    Particle.SetControlPoint(particle, 0, Vector(origin.x, origin.y, origin.z))
    Particle.SetControlPoint(particle, 7, Vector(radius, 255, 255))
    if need_update_color or inBlinkRange ~= inRange then
        Particle.SetControlPoint(particle, 1, Vector(color.r, color.g, color.b))
        need_update_color = false
        inBlinkRange = inRange
    end
end

-- Сброс состояния (не меняется)
local function resetAll()
    if castState > 0 or executionMode > 0 then
        print("[RubickUlt] RESET: Сброс состояния из castState=" .. castState .. ", executionMode=" .. executionMode)
    end
    castState = 0
    stored = {}
    custom_radius_point(nil, 0, true)
    currentAOE = 0
    inBlinkRange = false
    ordersExecuted = false
    executionMode = 0
end

-- Основная логика OnUpdate с улучшенным блинком и разделением логик
function script.OnUpdate()
    if not myHero then myHero = Heroes.GetLocal() end
    if not ui.enable:Get() or not Entity.IsAlive(myHero) or NPC.GetUnitName(myHero) ~= "npc_dota_hero_rubick" then
        resetAll()
        return
    end
    
    if ui.enable_custom_heroes:Get() and not enemy_selector_created then
        local enemies = populate_enemy_selector()
        if #enemies > 0 then
            ui_enemy_selector = spell_group:MultiSelect("Inimigos Alvo", enemies, true)
            enemy_selector_created = true
        end
    end

    -- MODO MANUAL: Cast de habilidades não listadas no auto use
    local manual_key_pressed = ui.manual_cast_key:IsDown()
    
    if manual_key_pressed and not lastManualKeyState then
        local manual_spells = GetManualCastableSpells()
        
        if #manual_spells > 0 then
            -- Usa apenas a PRIMEIRA habilidade disponível
            local spell_data = manual_spells[1]
            local ability = spell_data.ability
            local abilityName = spell_data.name
            
            lastManualCast = abilityName
            lastManualCastTime = GameRules.GetGameTime()
            
            -- Pega cursor e inimigo mais próximo
            local cursor_pos = Input.GetWorldCursorPos()
            local best_target = nil
            local best_dist = 300  -- Range para considerar "em cima" do inimigo
            
            if cursor_pos then
                for _, enemy in ipairs(Heroes.GetAll()) do
                    if Entity.GetTeamNum(enemy) ~= Entity.GetTeamNum(myHero) and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
                        local enemy_pos = Entity.GetAbsOrigin(enemy)
                        local dist = (enemy_pos - cursor_pos):Length2D()
                        if dist < best_dist then
                            best_dist = dist
                            best_target = enemy
                        end
                    end
                end
                
                print("[Rubick Manual] Dist: " .. (best_target and math.floor(best_dist) or "SEM INIMIGO"))
                
                -- Tenta CastPosition (Kinetic Field, Hook, Spear)
                print("[Rubick Manual] Tentando CastPosition")
                pcall(Ability.CastPosition, ability, cursor_pos, false)
                
                -- Tenta CastTarget se tem inimigo perto (Hex, Stun)
                if best_target then
                    print("[Rubick Manual] Tentando CastTarget em " .. NPC.GetUnitName(best_target))
                    pcall(Ability.CastTarget, ability, best_target, false)
                end
                
                lastManualCast = lastManualCast .. " [Both]"
            end
        end
    end
    
    lastManualKeyState = manual_key_pressed

    ui.cast_key:Visible(ui.mode:Get() == 0)
    local mode = ui.mode:Get()
    local keyDown = ui.cast_key:IsDown()

    -- Manejar toggle en modo manual
    if mode == 0 then  -- Manual Toggle mode
        if keyDown and not last_key_state then
            -- Tecla presionada (toggle)
            auto_mode_active = not auto_mode_active
            UpdateAutoModeUI()
            print("[RubickUlt] MODO AUTO " .. (auto_mode_active and "ACTIVADO" or "DESACTIVADO"))
        end
        last_key_state = keyDown
        
        -- Si no está en modo auto y hay secuencia activa, resetear
        if not auto_mode_active and castState ~= 0 then
            resetAll()
            return
        end
    end

    -- Determinar si debe ejecutar el combo
    local should_execute = false
    if mode == 0 then  -- Manual Toggle
        should_execute = auto_mode_active
    elseif mode == 1 then  -- Always Auto
        should_execute = true
    end
    
    -- Проверка для каста второго спелла в режиме прямого каста
    if executionMode == 1 and stored.secondary and os.clock() - secondaryTimer >= spellDelay then
        local s2, name2 = stored.secondary.ability, stored.secondary.name
        if isNoTargetSpell(name2) or isGlobalSpell(name2) then
            print("[RubickUlt] КАСТ 2/ПРЯМОЙ: " .. spell_friendly_names[name2] .. " (NoTarget)")
            Ability.CastNoTarget(s2, false)
        else
            print("[RubickUlt] КАСТ 2/ПРЯМОЙ: " .. spell_friendly_names[name2] .. " (CastPosition)")
            Ability.CastPosition(s2, stored.castPt, false)
        end
        resetAll()
        return
    end

    -- Собираем доступные украденные спеллы
    -- Reverse mapping friendly -> technical names for priority lookup
    local friendly_to_technical = {} 
    for tech, friendly in pairs(spell_friendly_names) do 
        friendly_to_technical[friendly] = tech 
    end 

    -- Сбор доступных спеллов в порядке приоритета UI
    local castable = {}
    local selected = ui.spell_select:ListEnabled()
    for _, friendly in ipairs(selected) do
        local tech = friendly_to_technical[friendly]
        if tech then
            local ab = NPC.GetAbility(myHero, tech)
            if ab and Ability.IsCastable(ab, NPC.GetMana(myHero)) then
                if tech == "storm_spirit_electric_vortex" then
                    -- проверка Aghs/Shard para Electric Vortex
                    local aghs       = NPC.GetItem(myHero, "item_ultimate_scepter", true)
                    local aghs_bless = NPC.HasModifier(myHero, "modifier_item_ultimate_scepter_consumed")
                    local shard      = NPC.GetItem(myHero, "item_aghanims_shard", true)
                    if aghs or aghs_bless or (shard and NPC.HasModifier(myHero, "modifier_item_aghanims_shard")) then
                        table.insert(castable, {ability=ab, name=tech})
                    end
                elseif tech == "phoenix_supernova" then
                    -- Phoenix Supernova sempre pode ser usado (com ou sem Aghs)
                    table.insert(castable, {ability=ab, name=tech})
                else
                    table.insert(castable, {ability=ab, name=tech})
                end
            end
        end
    end

    if #castable == 0 then resetAll(); return end

    local primary, secondary = castable[1], castable[2]
    local spell, spellName  = primary.ability, primary.name

    -- Проверяем Blink
    local blink = NPC.GetItem(myHero, "item_blink", true)
    local blinkAvailable = blink and Ability.IsCastable(blink, NPC.GetMana(myHero))
    local blinkRange = 0
    
    if blinkAvailable then
        blinkRange = Ability.GetLevelSpecialValueFor(blink, "blink_range")
        if not blinkRange or blinkRange == 0 then blinkRange = Ability.GetCastRange(blink) end
    end

    -- Вычисляем AOE радиус спелла
    local key = radius_keys[spellName] or "radius"
    local aoe = Ability.GetLevelSpecialValueFor(spell, key)
    if aoe == 0 then aoe = Ability.GetLevelSpecialValueFor(spell, "area_of_effect") end
    if not aoe or aoe == 0 then aoe = Ability.GetCastRange(spell) end
    if not aoe or aoe == 0 then aoe = 300 end
    -- Global spells don't need positioning
    if isGlobalSpell(spellName) then
        aoe = 0
        castRange = 99999
    end
    if aoe ~= currentAOE then currentAOE = aoe; need_update_particle = true end

    -- Ищем оптимальную точку и считаем расстояние
    local originalMinTargets = ui.min_targets:Get()
    local targetHero, pt, count = FindBestAOEPoint(currentAOE, originalMinTargets)
    if not pt then resetAll(); return end

    local mePos = Entity.GetAbsOrigin(myHero)
    local dx, dy = pt.x - mePos.x, pt.y - mePos.y
    local dist    = math.sqrt(dx*dx + dy*dy)
    local castRange = isNoTargetSpell(spellName) and 0 or Ability.GetCastRange(spell)
    
    -- Подсчет эффективной дистанции в зависимости от типа спелла
    local effectiveRange = isNoTargetSpell(spellName) and currentAOE or castRange
    local inBlink = blinkAvailable and dist <= blinkRange + effectiveRange
    custom_radius_point(pt, currentAOE, inBlink)

    -- Определение пороговой дистанции в зависимости от типа спелла
    local directCastThreshold
    if isNoTargetSpell(spellName) then
        directCastThreshold = currentAOE - 150
        directCastThreshold = directCastThreshold > 0 and directCastThreshold or currentAOE/2
    else
        directCastThreshold = (castRange or 0) + 150
    end
    
    -- ОСНОВНАЯ ЛОГИКА ВЫПОЛНЕНИЯ КОМБО
    -- Проверяем, начата ли уже последовательность логики блинка
    if castState > 0 then
        -- Если начали логику блинка, продолжаем её выполнять
        
        -- После Blink: кастуем в ORIGINAL оптимальную точку stored.castPt
        if castState == 1 and os.clock() - stateTime >= blinkDelay then
            if not ordersExecuted then
                ordersExecuted = true
                
                print("[RubickUlt] БЛИНК ПОСЛЕДОВАТЕЛЬНОСТЬ: Шаг 1 - каст заклинаний после блинка")
                
                -- primary (skip if it's a channel prep spell - already cast before blink)
                if not isChannelPrepSpell(stored.primaryName) then
                    if isNoTargetSpell(stored.primaryName) or isGlobalSpell(stored.primaryName) then
                        print("[RubickUlt] КАСТ 1/ПОСЛЕ БЛИНКА: " .. spell_friendly_names[stored.primaryName] .. " (NoTarget)")
                        Ability.CastNoTarget(stored.primary, false)
                    else
                        print("[RubickUlt] КАСТ 1/ПОСЛЕ БЛИНКА: " .. spell_friendly_names[stored.primaryName] .. " (CastPosition)")
                        Ability.CastPosition(stored.primary, stored.castPt, false)
                    end
                else
                    print("[RubickUlt] EPICENTER: Já foi castado antes do blink, pulando")
                end
                
                -- Запоминаем время для каста второго спелла с задержкой
                secondaryTimer = os.clock()
                stateTime = os.clock()
                return
            end
            
            -- Проверяем, пора ли кастовать второй спелл
            if stored.secondary and os.clock() - secondaryTimer >= spellDelay and not stored.secondaryCasted then
                local s2, name2 = stored.secondary.ability, stored.secondary.name
                if isNoTargetSpell(name2) or isToggleSpell(name2) or isGlobalSpell(name2) then
                    print("[RubickUlt] КАСТ 2/ПОСЛЕ БЛИНКА: " .. spell_friendly_names[name2] .. " (NoTarget)")
                    Ability.CastNoTarget(s2, false)
                else
                    print("[RubickUlt] КАСТ 2/ПОСЛЕ БЛИНКА: " .. spell_friendly_names[name2] .. " (CastPosition)")
                    Ability.CastPosition(s2, stored.castPt, false)
                end
                stored.secondaryCasted = true
            end
            
            -- Проверяем, пора ли переходить к следующему состоянию
            if os.clock() - stateTime >= castDelay then
                ordersExecuted = false
                stored.secondaryCasted = false -- сбрасываем флаг для следующего состояния
                stateTime = os.clock()
                if stored.useRef then
                    castState = 2
                else
                    resetAll()
                end
            end
            return
        end

        -- каст Refresher Orb
        if castState == 2 and os.clock() - stateTime >= blinkDelay then
            -- Проверяем, не каналит ли герой в данный момент (например, Black Hole)
            if NPC.IsChannellingAbility(myHero) then
                -- Если уже каналим, не используем refresher - это прервет канал
                print("[RubickUlt] ПРОПУСК REFRESHER: Герой каналит " .. spell_friendly_names[stored.primaryName] .. ". Пропускаем Refresher Orb.")
                resetAll()
                return
            end
            
            if not ordersExecuted then
                ordersExecuted = true
                
                print("[RubickUlt] БЛИНК ПОСЛЕДОВАТЕЛЬНОСТЬ: Шаг 2 - использование Refresher Orb")
                
                local refresher = NPC.GetItem(myHero, "item_refresher", true)
                if refresher and Ability.IsCastable(refresher, NPC.GetMana(myHero)) then
                    print("[RubickUlt] КАСТ REFRESHER: Использую Refresher Orb")
                    Ability.CastNoTarget(refresher, false) -- Рефрешер без очереди
                    stateTime = os.clock()
                    return
                else
                    print("[RubickUlt] ОШИБКА REFRESHER: Refresher недоступен или нет маны")
                    resetAll()
                    return
                end
            end
            
            -- Простая задержка перед переходом к следующему состоянию
            if os.clock() - stateTime >= castDelay then
                ordersExecuted = false
                stateTime = os.clock()
                castState = 3
            end
            return
        end

        -- вторая волна после Refresher
        if castState == 3 and os.clock() - stateTime >= blinkDelay then
            -- Для Black Hole и других каналящихся заклинаний - не пытаемся повторно кастовать
            -- пока не закончится первый канал
            if isChannelSpell(stored.primaryName) and NPC.IsChannellingAbility(myHero) then
                -- Герой всё ещё каналирует спелл после Refresher, не прерываем его
                print("[RubickUlt] ОЖИДАНИЕ КАНАЛА: Герой продолжает каналить " .. spell_friendly_names[stored.primaryName] .. " после Refresher")
                return -- Просто выходим без сброса состояния, чтобы продолжить каналирование
            end
            
            if not ordersExecuted then
                ordersExecuted = true
                
                print("[RubickUlt] БЛИНК ПОСЛЕДОВАТЕЛЬНОСТЬ: Шаг 3 - повторный каст заклинаний после Refresher")
                
                -- primary
                if isNoTargetSpell(stored.primaryName) or isToggleSpell(stored.primaryName) or isGlobalSpell(stored.primaryName) then
                    print("[RubickUlt] КАСТ 1/ПОСЛЕ REFRESHER: " .. spell_friendly_names[stored.primaryName] .. " (NoTarget)")
                    Ability.CastNoTarget(stored.primary, false)
                else
                    print("[RubickUlt] КАСТ 1/ПОСЛЕ REFRESHER: " .. spell_friendly_names[stored.primaryName] .. " (CastPosition)")
                    Ability.CastPosition(stored.primary, stored.castPt, false)
                end
                
                -- Запоминаем время для каста второго спелла с задержкой
                secondaryTimer = os.clock()
                stateTime = os.clock()
                return
            end
            
            -- Проверяем, пора ли кастовать второй спелл
            if stored.secondary and os.clock() - secondaryTimer >= spellDelay and not stored.secondaryCasted then
                local s2, name2 = stored.secondary.ability, stored.secondary.name
                if isNoTargetSpell(name2) or isToggleSpell(name2) or isGlobalSpell(name2) then
                    print("[RubickUlt] КАСТ 2/ПОСЛЕ REFRESHER: " .. spell_friendly_names[name2] .. " (NoTarget)")
                    Ability.CastNoTarget(s2, false)
                else
                    print("[RubickUlt] КАСТ 2/ПОСЛЕ REFRESHER: " .. spell_friendly_names[name2] .. " (CastPosition)")
                    Ability.CastPosition(s2, stored.castPt, false)
                end
                stored.secondaryCasted = true
            end
            
            -- Проверяем, пора ли завершать комбо
            if os.clock() - stateTime >= castDelay then
                resetAll()
            end
            
            return
        end
    else
        -- Если еще не начали выполнение, определяем какую логику использовать
        -- Проверяем условия запуска (клавиша или авто режим)
        if should_execute and not ordersExecuted then
            -- ВЫБОР РЕЖИМА ВЫПОЛНЕНИЯ - если castState == 0, выбираем логику:
            
            -- Приоритет 1: Прямое применение заклинания если враги близко
            if dist <= directCastThreshold then
                -- Указываем, что используем режим прямого каста
                executionMode = 1
                ordersExecuted = true
                
                print("[RubickUlt] БЛИЗКАЯ ДИСТАНЦИЯ: Расстояние " .. math.floor(dist) .. " <= " .. math.floor(directCastThreshold) .. " (порог). Прямой каст без блинка.")
                
                -- Сохраняем информацию для второго скилла
                stored.secondary = secondary
                stored.castPt = pt
                secondaryTimer = os.clock()
                
                -- Применяем первый спелл напрямую
                if isNoTargetSpell(spellName) or isGlobalSpell(spellName) then
                    print("[RubickUlt] КАСТ 1/ПРЯМОЙ: " .. spell_friendly_names[spellName] .. " (NoTarget)")
                    Ability.CastNoTarget(spell, false)
                else
                    print("[RubickUlt] КАСТ 1/ПРЯМОЙ: " .. spell_friendly_names[spellName] .. " (CastPosition)")
                    Ability.CastPosition(spell, pt, false)
                end
                
                -- Второй скилл будет кастоваться в OnUpdate с задержкой
                if not secondary then
                    -- Если второго скилла нет, сразу сбрасываем
                    resetAll()
                end
                
                return
            
            -- Приоритет 2: Используем блинк если доступен и враги в пределах блинк+спелл
            elseif blinkAvailable and inBlink then
                -- Указываем, что используем режим блинка
                executionMode = 2
                
                print("[RubickUlt] БЛИНК ЛОГИКА: Расстояние " .. math.floor(dist) .. " > " .. math.floor(directCastThreshold) .. " (порог). Используем блинк.")
                
                -- Определяем точку блинка
                local blinkTarget = pt
                if not isNoTargetSpell(spellName) and castRange and dist > castRange then
                    local dirX, dirY = dx/dist, dy/dist
                    local closerDistance = castRange - 100
                    local adjustedRange = castRange + ui.blink_offset:Get()
                    blinkTarget = Vector(pt.x - dirX * adjustedRange,
                                        pt.y - dirY * adjustedRange,
                                        pt.z)
                end
                -- Для no-target спеллов блинкуем прямо в оптимальную точку
                if isNoTargetSpell(spellName) then
                    blinkTarget = pt
                end
                
                -- Сохраняем данные и начинаем последовательность
                stored.blinkPt   = blinkTarget
                stored.castPt    = pt
                stored.primary     = spell
                stored.primaryName = spellName
                stored.secondary   = secondary
                stored.useRef      = ui.use_refresher:Get()
                castState = 1
                stateTime = os.clock()
                
                -- Sand King Epicenter precisa ser castado ANTES do blink
                if isChannelPrepSpell(spellName) then
                    print("[RubickUlt] EPICENTER: Castando antes do blink")
                    Ability.CastNoTarget(spell, false)
                    -- Aguarda um pouco antes de blinkar
                    stateTime = os.clock() + 0.5
                end
                
                print("[RubickUlt] БЛИНК: Прыжок на дистанцию " .. math.floor((blinkTarget - mePos):Length2D()))
                Ability.CastPosition(blink, blinkTarget, false)
                return
            end
        end
    end
end

-- Отрисовка линий для визуализации
function script.OnDraw()
    DrawModePanel()
    
    -- Debug de habilidades manuais (agora só exibe se o Debug Visual estiver ligado)
    if ui.visual_debug:Get() and ui.enable:Get() and myHero and NPC.GetUnitName(myHero) == "npc_dota_hero_rubick" then
        local font = Render.LoadFont("Tahoma", Enum.FontCreate.FONTFLAG_ANTIALIAS)
        
        local key_status = ui.manual_cast_key:IsDown() and "TECLA G PRESSIONADA!" or "Tecla G solta"
        Render.Text(font, 14, key_status, Vec2(10, 170), ui.manual_cast_key:IsDown() and Color(0, 255, 0, 255) or Color(255, 255, 255, 150))
        Render.Text(font, 11, lastManualSpellCheck, Vec2(10, 190), Color(255, 255, 0, 255))
        if lastManualCast ~= "" and (GameRules.GetGameTime() - lastManualCastTime) < 3 then
            Render.Text(font, 16, "USOU: " .. lastManualCast, Vec2(10, 210), Color(0, 255, 0, 255))
        end
    end
    if not ui.enable:Get() or not ui.visual_debug:Get() or currentAOE <= 0 then return end
    local _, optimalPos = FindBestAOEPoint(currentAOE, ui.min_targets:Get())
    if not optimalPos then return end
    
    -- Проверяем, находится ли оптимальная позиция в пределах радиуса блинка
    local mePos = Entity.GetAbsOrigin(myHero)
    local dist = (Vector(optimalPos.x, optimalPos.y,0) - Vector(mePos.x, mePos.y,0)):Length2D()
    local blink = NPC.GetItem(myHero, "item_blink", true)
    local blinkRange = blink and (Ability.GetLevelSpecialValueFor(blink, "blink_range") or Ability.GetCastRange(blink)) or 0
    local inRange = dist <= blinkRange
    
    -- Выбираем цвет линий в зависимости от доступности блинка
    local lineColor = inRange and Color(0,255,0) or Color(255,0,0)
    
    for _, h in pairs(Heroes.GetAll()) do
        if h~=myHero and Entity.IsAlive(h) and not NPC.IsIllusion(h) and not Entity.IsSameTeam(h, myHero) then
            local pos = Entity.GetAbsOrigin(h)
            if (Vector(pos.x,pos.y,0) - Vector(optimalPos.x,optimalPos.y,0)):Length2D() <= currentAOE then
                local sp,on = Render.WorldToScreen(pos)
                local cp,con = Render.WorldToScreen(optimalPos)
                if on and con then
                    Render.Line(sp, cp, 2, lineColor)
                end
            end
        end
    end
end

return script