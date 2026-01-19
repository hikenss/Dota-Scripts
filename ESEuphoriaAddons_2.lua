--========================================================
-- ESEuphoriaAddons Pro v8.2 (Ally-Directed Smash 2.0)
--========================================================

local TargetLock = require("TargetLock")
local EuphoriaAddon2 = {}

-- ========= CONFIG PERSISTENCE NAMES =========
local CONFIG_NAME = "ESEuphoriaAddons2"

-- ========= MENU =========
local hero_tab = Menu.Find("Heroes", "Hero List", "Earth Spirit")
local euphor_tab = hero_tab:Create("EuphoriaAddon 2.0 ⚡")

local main_group    = euphor_tab:Create("Principal")
local ability_group = euphor_tab:Create("Habilidades")
local items_group   = euphor_tab:Create("Itens")
local delay_group   = euphor_tab:Create("Atrasos")
local save_group    = euphor_tab:Create("Push Simples")

local ui = {}
ui.enable   = main_group:Switch("Ativar Script", true, "\u{f013}")
ui.hotkey   = main_group:Bind("Tecla Smash (segurar)", Enum.ButtonCode.KEY_G, "\u{f11c}")
ui.mode     = main_group:Combo("Modo", {"Básico", "Avançado", "Pro"}, 1, "\u{f0ad}")
ui.debug    = main_group:Switch("Prints de Debug", false, "\u{f188}")
ui.use_move = main_group:Switch("Permitir Movimento Manual", true, "\u{f0b2}")
ui.min_dist = main_group:Slider("Distância Mínima para Smash", 150, 300, 200, "%d")
ui.target_prio = main_group:Combo("Prioridade de Alvo",
    {"Menor HP%", "Mais Próximo", "Score de DPS"}, 0, "\u{f140}")
ui.retreat_after_smash = main_group:Switch("Recuar com Roll Após Smash", true, "\u{f2f1}")
ui.file_logging = main_group:Switch("Gravar Log em Arquivo", false, "\u{f0f6}")
ui.prefer_roll = main_group:Switch("Preferir Início com Rolling", true, "\u{f1b2}")

-- Push simples
ui.save_enable  = save_group:Switch("Ativar Push Simples", true)
ui.save_hotkey  = save_group:Bind("Push + Roll (pressionar)", Enum.ButtonCode.KEY_H)
ui.save_cursor_range = save_group:Slider("Range do Cursor", 200, 800, 400, "%d")
ui.save_target_mode = save_group:Combo("Alvo do Push", {"Apenas Inimigos", "Apenas Aliados", "Qualquer"}, 0)

-- Salvar aliado
local grip_group = euphor_tab:Create("Salvar Aliado (Grip)")
ui.grip_enable = grip_group:Switch("Ativar Salvar Aliado", true)
ui.grip_hotkey = grip_group:Bind("Puxar Aliado (pressionar)", Enum.ButtonCode.KEY_K)
ui.grip_hp_threshold = grip_group:Slider("HP% Mínimo", 10, 50, 30, "%d%%")

-- Ally-directed preferences
local ally_group = euphor_tab:Create("Direção de Aliado")
ui.ally_mode = ally_group:Combo("Seleção de Aliado", {"Aliado Mais Próximo", "Aliado Mais Forte", "Aliado com Menor HP", "Aliado no Cursor"}, 0)
ui.ally_lock = ally_group:Switch("Travar Aliado Durante Combo", true)
ui.ally_max_range = ally_group:Slider("Alcance Máx do Aliado", 300, 2500, 1200, "%d")

ui.enchant  = ability_group:Switch("Usar Enchant Remnant (Aghanim)", true,
    "panorama/images/spellicons/earth_spirit_petrify_png.vtex_c")

ui.use_bkb   = items_group:Switch("Auto BKB", true, "panorama/images/items/black_king_bar_png.vtex_c")
ui.smart_bkb = items_group:Switch("Smart BKB (apenas vs disables)", true, "\u{f0e7}")
ui.chain_cc  = items_group:MultiSelect("Itens de Controle em Cadeia", {
    {"Rod of Atos", "panorama/images/items/rod_of_atos_png.vtex_c", true},
    {"Eul’s Scepter", "panorama/images/items/cyclone_png.vtex_c", true},
    {"Scythe of Vyse", "panorama/images/items/sheepstick_png.vtex_c", false},
    {"Orchid", "panorama/images/items/orchid_png.vtex_c", false},
    {"Nullifier", "panorama/images/items/nullifier_png.vtex_c", false}
}, true)

ui.delay_blink   = delay_group:Slider("Blink Delay", 100, 300, 150, "%d ms")
ui.delay_harpoon = delay_group:Slider("Harpoon Delay", 200, 400, 250, "%d ms")
ui.delay_smash   = delay_group:Slider("Smash Delay", 120, 300, 200, "%d ms")
ui.delay_enchant = delay_group:Slider("Enchant Delay", 150, 300, 200, "%d ms")
ui.delay_bkb     = delay_group:Slider("BKB Delay", 50, 150, 80, "%d ms")

-- ========= CONFIG PERSISTENCE FUNCTIONS =========
local function SaveConfig()
    if not Config then
        print("[ESEuphoriaAddons2] Config API not available!")
        return
    end
    
    -- Main settings
    pcall(function() Config.WriteInt(CONFIG_NAME, "enable", ui.enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "hotkey", ui.hotkey:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "mode", ui.mode:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "debug", ui.debug:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "use_move", ui.use_move:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "min_dist", ui.min_dist:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "target_prio", ui.target_prio:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "retreat_after_smash", ui.retreat_after_smash:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "file_logging", ui.file_logging:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "prefer_roll", ui.prefer_roll:Get() and 1 or 0) end)
    
    -- Push simples
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_enable", ui.save_enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_hotkey", ui.save_hotkey:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_cursor_range", ui.save_cursor_range:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "save_target_mode", ui.save_target_mode:Get()) end)
    
    -- Grip
    pcall(function() Config.WriteInt(CONFIG_NAME, "grip_enable", ui.grip_enable:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "grip_hotkey", ui.grip_hotkey:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "grip_hp_threshold", ui.grip_hp_threshold:Get()) end)
    
    -- Ally
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_mode", ui.ally_mode:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_lock", ui.ally_lock:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "ally_max_range", ui.ally_max_range:Get()) end)
    
    -- Abilities
    pcall(function() Config.WriteInt(CONFIG_NAME, "enchant", ui.enchant:Get() and 1 or 0) end)
    
    -- Items
    pcall(function() Config.WriteInt(CONFIG_NAME, "use_bkb", ui.use_bkb:Get() and 1 or 0) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "smart_bkb", ui.smart_bkb:Get() and 1 or 0) end)
    
    -- Chain CC items (MultiSelect - save as bitmask)
    pcall(function()
        local chain_cc_mask = 0
        local chain_cc_items = {"Rod of Atos", "Eul's Scepter", "Scythe of Vyse", "Orchid", "Nullifier"}
        for i, name in ipairs(chain_cc_items) do
            if ui.chain_cc:Get(name) then
                chain_cc_mask = chain_cc_mask + (2 ^ (i - 1))
            end
        end
        Config.WriteInt(CONFIG_NAME, "chain_cc", chain_cc_mask)
    end)
    
    -- Delays
    pcall(function() Config.WriteInt(CONFIG_NAME, "delay_blink", ui.delay_blink:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "delay_harpoon", ui.delay_harpoon:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "delay_smash", ui.delay_smash:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "delay_enchant", ui.delay_enchant:Get()) end)
    pcall(function() Config.WriteInt(CONFIG_NAME, "delay_bkb", ui.delay_bkb:Get()) end)
    
    print("[ESEuphoriaAddons2] Config saved!")
end

local function LoadConfig()
    if not Config then
        print("[ESEuphoriaAddons2] Config API not available, skipping load!")
        return
    end
    
    pcall(function()
        -- Main settings
        local enable = Config.ReadInt(CONFIG_NAME, "enable", 1)
        ui.enable:Set(enable == 1)
        
        local hotkey = Config.ReadInt(CONFIG_NAME, "hotkey", Enum.ButtonCode.KEY_G)
        if hotkey ~= 0 then ui.hotkey:Set(hotkey) end
        
        local mode = Config.ReadInt(CONFIG_NAME, "mode", 1)
        ui.mode:Set(mode)
        
        local debug_val = Config.ReadInt(CONFIG_NAME, "debug", 0)
        ui.debug:Set(debug_val == 1)
        
        local use_move = Config.ReadInt(CONFIG_NAME, "use_move", 1)
        ui.use_move:Set(use_move == 1)
        
        local min_dist = Config.ReadInt(CONFIG_NAME, "min_dist", 200)
        ui.min_dist:Set(min_dist)
        
        local target_prio = Config.ReadInt(CONFIG_NAME, "target_prio", 0)
        ui.target_prio:Set(target_prio)
        
        local retreat = Config.ReadInt(CONFIG_NAME, "retreat_after_smash", 1)
        ui.retreat_after_smash:Set(retreat == 1)
        
        local file_log = Config.ReadInt(CONFIG_NAME, "file_logging", 0)
        ui.file_logging:Set(file_log == 1)
        
        local prefer_roll = Config.ReadInt(CONFIG_NAME, "prefer_roll", 1)
        ui.prefer_roll:Set(prefer_roll == 1)
        
        -- Push simples
        local save_enable = Config.ReadInt(CONFIG_NAME, "save_enable", 1)
        ui.save_enable:Set(save_enable == 1)
        
        local save_hotkey = Config.ReadInt(CONFIG_NAME, "save_hotkey", Enum.ButtonCode.KEY_H)
        if save_hotkey ~= 0 then ui.save_hotkey:Set(save_hotkey) end
        
        local save_cursor_range = Config.ReadInt(CONFIG_NAME, "save_cursor_range", 400)
        ui.save_cursor_range:Set(save_cursor_range)
        
        local save_target_mode = Config.ReadInt(CONFIG_NAME, "save_target_mode", 0)
        ui.save_target_mode:Set(save_target_mode)
        
        -- Grip
        local grip_enable = Config.ReadInt(CONFIG_NAME, "grip_enable", 1)
        ui.grip_enable:Set(grip_enable == 1)
        
        local grip_hotkey = Config.ReadInt(CONFIG_NAME, "grip_hotkey", Enum.ButtonCode.KEY_K)
        if grip_hotkey ~= 0 then ui.grip_hotkey:Set(grip_hotkey) end
        
        local grip_hp = Config.ReadInt(CONFIG_NAME, "grip_hp_threshold", 30)
        ui.grip_hp_threshold:Set(grip_hp)
        
        -- Ally
        local ally_mode = Config.ReadInt(CONFIG_NAME, "ally_mode", 0)
        ui.ally_mode:Set(ally_mode)
        
        local ally_lock = Config.ReadInt(CONFIG_NAME, "ally_lock", 1)
        ui.ally_lock:Set(ally_lock == 1)
        
        local ally_max_range = Config.ReadInt(CONFIG_NAME, "ally_max_range", 1200)
        ui.ally_max_range:Set(ally_max_range)
        
        -- Abilities
        local enchant = Config.ReadInt(CONFIG_NAME, "enchant", 1)
        ui.enchant:Set(enchant == 1)
        
        -- Items
        local use_bkb = Config.ReadInt(CONFIG_NAME, "use_bkb", 1)
        ui.use_bkb:Set(use_bkb == 1)
        
        local smart_bkb = Config.ReadInt(CONFIG_NAME, "smart_bkb", 1)
        ui.smart_bkb:Set(smart_bkb == 1)
        
        -- Chain CC items (MultiSelect - load from bitmask)
        local chain_cc_mask = Config.ReadInt(CONFIG_NAME, "chain_cc", 3) -- default: Atos + Euls
        local chain_cc_items = {"Rod of Atos", "Eul's Scepter", "Scythe of Vyse", "Orchid", "Nullifier"}
        for i, name in ipairs(chain_cc_items) do
            local bit = 2 ^ (i - 1)
            local enabled = (chain_cc_mask % (bit * 2)) >= bit
            ui.chain_cc:Set(name, enabled)
        end
        
        -- Delays
        local delay_blink = Config.ReadInt(CONFIG_NAME, "delay_blink", 150)
        ui.delay_blink:Set(delay_blink)
        
        local delay_harpoon = Config.ReadInt(CONFIG_NAME, "delay_harpoon", 250)
        ui.delay_harpoon:Set(delay_harpoon)
        
        local delay_smash = Config.ReadInt(CONFIG_NAME, "delay_smash", 200)
        ui.delay_smash:Set(delay_smash)
        
        local delay_enchant = Config.ReadInt(CONFIG_NAME, "delay_enchant", 200)
        ui.delay_enchant:Set(delay_enchant)
        
        local delay_bkb = Config.ReadInt(CONFIG_NAME, "delay_bkb", 80)
        ui.delay_bkb:Set(delay_bkb)
        
        print("[ESEuphoriaAddons2] Config loaded!")
    end)
end

local function SetupConfigCallbacks()
    -- Main settings callbacks
    ui.enable:SetCallback(function() SaveConfig() end)
    ui.hotkey:SetCallback(function() SaveConfig() end)
    ui.mode:SetCallback(function() SaveConfig() end)
    ui.debug:SetCallback(function() SaveConfig() end)
    ui.use_move:SetCallback(function() SaveConfig() end)
    ui.min_dist:SetCallback(function() SaveConfig() end)
    ui.target_prio:SetCallback(function() SaveConfig() end)
    ui.retreat_after_smash:SetCallback(function() SaveConfig() end)
    ui.file_logging:SetCallback(function() SaveConfig() end)
    ui.prefer_roll:SetCallback(function() SaveConfig() end)
    
    -- Push simples callbacks
    ui.save_enable:SetCallback(function() SaveConfig() end)
    ui.save_hotkey:SetCallback(function() SaveConfig() end)
    ui.save_cursor_range:SetCallback(function() SaveConfig() end)
    ui.save_target_mode:SetCallback(function() SaveConfig() end)
    
    -- Grip callbacks
    ui.grip_enable:SetCallback(function() SaveConfig() end)
    ui.grip_hotkey:SetCallback(function() SaveConfig() end)
    ui.grip_hp_threshold:SetCallback(function() SaveConfig() end)
    
    -- Ally callbacks
    ui.ally_mode:SetCallback(function() SaveConfig() end)
    ui.ally_lock:SetCallback(function() SaveConfig() end)
    ui.ally_max_range:SetCallback(function() SaveConfig() end)
    
    -- Abilities callbacks
    ui.enchant:SetCallback(function() SaveConfig() end)
    
    -- Items callbacks
    ui.use_bkb:SetCallback(function() SaveConfig() end)
    ui.smart_bkb:SetCallback(function() SaveConfig() end)
    ui.chain_cc:SetCallback(function() SaveConfig() end)
    
    -- Delays callbacks
    ui.delay_blink:SetCallback(function() SaveConfig() end)
    ui.delay_harpoon:SetCallback(function() SaveConfig() end)
    ui.delay_smash:SetCallback(function() SaveConfig() end)
    ui.delay_enchant:SetCallback(function() SaveConfig() end)
    ui.delay_bkb:SetCallback(function() SaveConfig() end)
end

-- ========= LOAD CONFIG AND SETUP CALLBACKS =========
LoadConfig()
SetupConfigCallbacks()

-- ========= DEBUG =========
local function DebugPrint(msg)
    if ui.debug:Get() then print("[EuphoriaAddon2] " .. msg) end
end
local function Log(msg)
    if ui.debug:Get() then print("[EuphoriaAddon2] " .. msg) end
end
local function FileLog(msg)
    if not ui.file_logging:Get() then return end
    local path = "earth_spirit_euphoria.log"
    local f = io.open(path, "a")
    if f then
        f:write(string.format("[%0.2f] %s\n", GameRules.GetGameTime(), msg))
        f:close()
    end
end

-- ========= INPUT TRACKER =========
local prevKeyState = false
local function IsKeyJustPressed(key)
    local now = Input.IsKeyDown(key)
    if now and not prevKeyState then
        prevKeyState = true
        return true
    elseif not now then
        prevKeyState = false
    end
    return false
end
local function IsKeyDown(key) return Input.IsKeyDown(key) end

-- ========= HELPERS =========
local function GetItem(hero, names)
    if type(names) == "string" then names = {names} end
    for i = 0, 14 do
        local item = NPC.GetItemByIndex(hero, i)
        if item then
            local n = Ability.GetName(item)
            for _, v in ipairs(names) do
                if n == v then return item end
            end
        end
    end
    return nil
end

local function GetAbility(hero, name)
    for i = 0, 23 do
        local ab = NPC.GetAbilityByIndex(hero, i)
        if ab and Ability.GetName(ab) == name then
            return ab
        end
    end
    return nil
end

local function CanCast(myHero, ability)
    return ability and Ability.IsReady(ability) and Ability.IsCastable(ability, NPC.GetMana(myHero))
end

-- Hero validity (ignore illusions & invulnerable heroes)
local function IsValidHero(h)
    -- Dota applies 'modifier_invulnerable' while a unit is invulnerable.
    return h and Entity.IsAlive(h) and not NPC.IsIllusion(h) and not NPC.HasModifier(h, "modifier_invulnerable")
end

local castTimers = {}
local function TryCast(key, delay, func)
    local now = GameRules.GetGameTime()
    if not castTimers[key] or castTimers[key] < now then
        func()
        castTimers[key] = now + (delay / 1000.0)
        return true
    end
    return false
end

-- ========= TARGET SELECTOR =========
local locked_target = nil
local function FindEnemyTarget(myHero, force_new)
    -- Não busca target durante push mode
    if pushModeActive then return nil end
    
    if combo_active and locked_target and Entity.IsAlive(locked_target) then
        return locked_target
    end
    if force_new then locked_target = nil end
    
    -- Usa método simples e eficiente
    local target = TargetLock.GetBestTarget()
    
    -- Fallback para método manual se necessário
    if not target then
        target = TargetLock.FindTarget(1200)
    end
    
    -- Valida se alvo é atacável
    if target and not TargetLock.IsValidTarget(target) then
        target = nil
    end
    
    locked_target = target
    return target
end

-- ========= ALLY SELECTOR =========
local locked_ally = nil
local last_dir = nil
local retreat_dir = nil
local retreat_pending = false
local debug_last = ""
local roll_travel = 0
local roll_started_at = 0

-- Earth Spirit: rastreia quando colocou Remnant e precisa rolar
local earthSpiritPending = {
    active = false,
    time = 0,
    escapePos = nil
}
local roll_target_point = nil
local approach_roll_active = false
local action_cd_until = 0
local gate_deadline = 0

-- Estado simplificado não precisa de máquina de estados
local first_update_done = false
local function CountEnemiesNear(pos, radius, myHero)
    local c = 0
    for _, e in pairs(Heroes.GetAll()) do
        if IsValidHero(e) and not Entity.IsSameTeam(myHero, e) then
            if (Entity.GetAbsOrigin(e) - pos):Length2D() <= radius then c = c + 1 end
        end
    end
    return c
end
local function GetFountainPos(team)
    return team == 2 and Vector(-7000,-7000,512) or Vector(7000,7000,512)
end

-- Estado do push para escape
local pushEscapeState = {active = false, pushTime = 0, pushDir = nil, target = nil}
local pushModeActive = false
local shouldRollEscape = false
local prevPushKeyState = false

-- IA: Detecta se aliado está em perigo
local function IsAllyInDanger(ally, myHero)
    local dangerScore = 0
    local allyPos = Entity.GetAbsOrigin(ally)
    local hpPercent = (Entity.GetHealth(ally) / Entity.GetMaxHealth(ally)) * 100
    
    -- 1. HP baixo (peso alto)
    if hpPercent <= ui.grip_hp_threshold:Get() then
        dangerScore = dangerScore + 50
    end
    
    -- 2. Cercado por inimigos
    local enemiesNear = 0
    local alliesNear = 0
    for _, hero in pairs(Heroes.GetAll()) do
        if Entity.IsAlive(hero) and hero ~= ally then
            local dist = (Entity.GetAbsOrigin(hero) - allyPos):Length2D()
            if dist <= 800 then
                if Entity.IsSameTeam(ally, hero) then
                    alliesNear = alliesNear + 1
                else
                    enemiesNear = enemiesNear + 1
                end
            end
        end
    end
    if enemiesNear > alliesNear + 1 then
        dangerScore = dangerScore + 30
    end
    
    -- 3. Stunado/Silenciado
    if NPC.IsStunned(ally) or NPC.IsSilenced(ally) then
        dangerScore = dangerScore + 40
    end
    
    -- 4. Longe da fonte (mais perigoso)
    local fountain = GetFountainPos(Entity.GetTeamNum(ally))
    local distToFountain = (allyPos - fountain):Length2D()
    if distToFountain > 5000 then
        dangerScore = dangerScore + 20
    end
    
    return dangerScore, hpPercent, enemiesNear, alliesNear
end



local function SaveAllyWithGrip(myHero, grip)
    local myPos = Entity.GetAbsOrigin(myHero)
    
    -- Encontra aliado em MAIOR perigo no range
    local bestAlly, bestDanger = nil, 0
    for _, ally in pairs(Heroes.GetAll()) do
        if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
            local allyPos = Entity.GetAbsOrigin(ally)
            local distToMe = (allyPos - myPos):Length2D()
            
            -- Só considera se estiver no range do Grip (1100)
            if distToMe <= 1100 then
                local danger, hp, enemies, allies = IsAllyInDanger(ally, myHero)
                -- Pega o aliado com MAIOR score de perigo
                if danger > bestDanger then
                    bestAlly = ally
                    bestDanger = danger
                end
            end
        end
    end
    
    if not bestAlly then 
        FileLog("GRIP: nenhum aliado em perigo no range")
        return 
    end
    
    local allyPos = Entity.GetAbsOrigin(bestAlly)
    local distToMe = (allyPos - myPos):Length2D()
    local danger, hp, enemies, allies = IsAllyInDanger(bestAlly, myHero)
    
    if grip and CanCast(myHero, grip) then
        Ability.CastTarget(grip, bestAlly)
        FileLog(string.format("GRIP: salvando %s (HP=%.0f%% perigo=%d enemies=%d dist=%.1f)", 
            Entity.GetUnitName(bestAlly), hp, bestDanger, enemies, distToMe))
    else
        FileLog("GRIP: habilidade indisponível")
    end
end

-- Conta inimigos e aliados próximos
local function CountNearbyHeroes(pos, radius)
    local enemies, allies = 0, 0
    local myHero = Heroes.GetLocal()
    for _, hero in pairs(Heroes.GetAll()) do
        if Entity.IsAlive(hero) and hero ~= myHero then
            local dist = (Entity.GetAbsOrigin(hero) - pos):Length2D()
            if dist <= radius then
                if Entity.IsSameTeam(myHero, hero) then
                    allies = allies + 1
                else
                    enemies = enemies + 1
                end
            end
        end
    end
    return enemies, allies
end

-- Push inteligente: executa smash direto no cursor
local function SimpleCursorPush(myHero, smash)
    local cursorPos = Input.GetWorldCursorPos()
    if not cursorPos then 
        FileLog("PUSH: cursor pos nil")
        return 
    end
    
    local now = GameRules.GetGameTime()
    
    if not smash then
        FileLog("PUSH: smash ability nil")
        return
    end
    
    if not CanCast(myHero, smash) then
        FileLog(string.format("PUSH: smash NOT ready - CD=%.1f Mana=%d/%d", 
            Ability.GetCooldown(smash), NPC.GetMana(myHero), Ability.GetManaCost(smash)))
        return
    end
    
    if castTimers["push_smash"] and now < castTimers["push_smash"] then
        return
    end
    
    -- Direção: do cursor para a fonte inimiga
    local pushDir = (cursorPos - Entity.GetAbsOrigin(myHero)):Normalized()
    
    Ability.CastPosition(smash, cursorPos)
    
    -- STOP para não atacar depois
    Player.PrepareUnitOrders(Players.GetLocal(),
        Enum.UnitOrder.DOTA_UNIT_ORDER_STOP,
        0,
        Vector(0, 0, 0),
        nil,
        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
        myHero,
        false,
        false
    )
    
    if shouldRollEscape then
        pushEscapeState.active = true
        pushEscapeState.pushTime = GameRules.GetGameTime()
        pushEscapeState.pushDir = pushDir
    end
    castTimers["push_smash"] = now + 0.3
end

local function IsRolling(unit)
    return NPC.HasModifier(unit, "modifier_earth_spirit_rolling_boulder")
end
-- Predição usando TargetLock
local function PredictEnemyPos(enemy, now)
    if not enemy then return nil end
    return TargetLock.PredictPosition(enemy, 0.5, nil)
end
local function AllyScore(myHero, ally)
    local myPos = Entity.GetAbsOrigin(myHero)
    local pos   = Entity.GetAbsOrigin(ally)
    local dist  = (pos - myPos):Length2D()
    if dist > ui.ally_max_range:Get() then return 1e9 end
    local mode = ui.ally_mode:Get()
    if mode == 0 then -- Closest
        return dist
    elseif mode == 1 then -- Strongest (damage + level)
        return - (NPC.GetBaseDamage(ally) + NPC.GetCurrentLevel(ally) * 6)
    elseif mode == 2 then -- Lowest HP
        return (Entity.GetHealth(ally) / math.max(Entity.GetMaxHealth(ally),1)) * 100
    elseif mode == 3 then -- Cursor Ally
        local cpos = Input.GetWorldCursorPos()
        return (pos - cpos):Length2D()
    end
    return dist
end
local function FindPreferredAlly(myHero, force_new)
    if ui.ally_lock:Get() and combo_active and locked_ally and Entity.IsAlive(locked_ally) then
        return locked_ally
    end
    if force_new then locked_ally = nil end
    local best, bestScore = nil, 1e9
    for _, ally in pairs(Heroes.GetAll()) do
        if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
            local score = AllyScore(myHero, ally)
            if score < bestScore then
                best, bestScore = ally, score
            end
        end
    end
    locked_ally = best
    return best
end

-- ========= DIRECTION HELPERS =========
local function DirectionTowardsAlly(enemy, ally)
    if not enemy or not ally then return nil end
    local epos = Entity.GetAbsOrigin(enemy)
    local apos = Entity.GetAbsOrigin(ally)
    local v = (apos - epos)
    local len = v:Length2D()
    if len < 1 then return nil end
    return v:Normalized()
end

-- ========= SMOOTH CHASE =========
local lastMoveTime = 0
local function SmoothChase(myHero, enemy, minDist)
    if not myHero or not enemy then return end
    if not Entity.IsAlive(enemy) then return end
    if Input.IsKeyDown(Enum.ButtonCode.MOUSE_RIGHT) then return end

    local now = GameRules.GetGameTime()
    if now < lastMoveTime then return end

    local myPos = Entity.GetAbsOrigin(myHero)
    local enemyPos = Entity.GetAbsOrigin(enemy)
    local dist = (myPos - enemyPos):Length2D()

    if dist > minDist then
        Player.PrepareUnitOrders(Players.GetLocal(),
            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
            0,
            enemyPos,
            nil,
            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
            myHero,
            false,
            true
        )
        lastMoveTime = now + 0.25
    end
end

-- ========= COMBO =========
local combo_active, combo_state, combo_time = false, 0, 0
local smash_enemy = nil

function EuphoriaAddon2.OnUpdate()
    if not ui.enable:Get() then return end
    local myHero = Heroes.GetLocal()
    if not myHero or NPC.GetUnitName(myHero) ~= "npc_dota_hero_earth_spirit" then return end
    local now = GameRules.GetGameTime()
    if not first_update_done then
        first_update_done = true
        FileLog("SCRIPT INIT OK")
        DebugPrint("Init OK")
    end

    local blink   = GetItem(myHero, {"item_blink","item_overwhelming_blink"})
    local harpoon = GetItem(myHero, "item_harpoon")
    local smash   = GetAbility(myHero, "earth_spirit_boulder_smash")
    local enchant = GetAbility(myHero, "earth_spirit_petrify")
    local rolling = GetAbility(myHero, "earth_spirit_rolling_boulder")
    local stoneRemnant = GetAbility(myHero, "earth_spirit_stone_caller")
    local grip    = GetAbility(myHero, "earth_spirit_geomagnetic_grip")
    local has_aghs = enchant and Ability.GetLevel(enchant) > 0
    
    -- Salvar aliado com Grip (hold key)
    if ui.grip_enable:Get() and IsKeyDown(ui.grip_hotkey:Get()) then
        if grip and not castTimers["grip_cooldown"] or now >= castTimers["grip_cooldown"] then
            SaveAllyWithGrip(myHero, grip)
            castTimers["grip_cooldown"] = now + 0.5
        end
    end

    -- Push simples pelo cursor (key press)
    local pushKeyDown = IsKeyDown(ui.save_hotkey:Get())
    
    -- H = smash se tiver alvo, roll se não tiver ou smash em CD (press)
    if ui.save_enable:Get() and pushKeyDown and not prevPushKeyState then
        local cursorPos = Input.GetWorldCursorPos()
        if cursorPos then
            -- Busca herói mais próximo do Earth Spirit baseado no modo
            local myPos = Entity.GetAbsOrigin(myHero)
            local targetMode = ui.save_target_mode:Get()
            local nearestTarget = nil
            local minDist = ui.save_cursor_range:Get()
            
            for _, h in pairs(Heroes.GetAll()) do
                if h ~= myHero and IsValidHero(h) then
                    local isEnemy = not Entity.IsSameTeam(myHero, h)
                    local isAlly = Entity.IsSameTeam(myHero, h)
                    local validTarget = false
                    
                    if targetMode == 0 and isEnemy then -- Apenas Inimigos
                        validTarget = true
                    elseif targetMode == 1 and isAlly then -- Apenas Aliados
                        validTarget = true
                    elseif targetMode == 2 then -- Qualquer
                        validTarget = true
                    end
                    
                    if validTarget then
                        local d = (Entity.GetAbsOrigin(h) - myPos):Length2D()
                        if d < minDist then
                            minDist = d
                            nearestTarget = h
                        end
                    end
                end
            end
            
            -- Se tem alvo E smash disponível = usa smash na direção do cursor
            if nearestTarget and smash and CanCast(myHero, smash) then
                local targetPos = Entity.GetAbsOrigin(nearestTarget)
                local distToTarget = (targetPos - myPos):Length2D()
                
                -- Se está longe (>100), aproxima primeiro
                if distToTarget > 100 then
                    Player.PrepareUnitOrders(Players.GetLocal(),
                        Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                        0,
                        targetPos,
                        nil,
                        Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                        myHero,
                        false,
                        false
                    )
                -- Se está perto (<=100), executa o smash
                else
                    -- Direção: sempre do alvo para o cursor (empurra na direção do cursor)
                    local pushDir = (cursorPos - targetPos):Normalized()
                    -- Posiciona o smash à frente do alvo na direção do cursor
                    local smashPos = targetPos + pushDir * 150
                    Ability.CastPosition(smash, smashPos)
                end
            -- Se smash em CD = usa roll para escapar
            elseif rolling and CanCast(myHero, rolling) then
                local targetMode = ui.save_target_mode:Get()
                local rollPos
                
                -- Se modo é aliado (1) OU qualquer (2) E tem aliado próximo, rola em cima do aliado
                if (targetMode == 1 or targetMode == 2) and nearestTarget and Entity.IsSameTeam(myHero, nearestTarget) then
                    local allyPos = Entity.GetAbsOrigin(nearestTarget)
                    rollPos = allyPos
                -- Senão, escapa na direção oposta ao inimigo mais próximo
                else
                    local nearestEnemy = nil
                    local minDist = 9999
                    for _, enemy in pairs(Heroes.GetAll()) do
                        if enemy and Entity.IsAlive(enemy) and not Entity.IsSameTeam(myHero, enemy) then
                            local dist = (Entity.GetAbsOrigin(enemy) - myPos):Length2D()
                            if dist < minDist then
                                minDist = dist
                                nearestEnemy = enemy
                            end
                        end
                    end
                    
                    if nearestEnemy then
                        local enemyPos = Entity.GetAbsOrigin(nearestEnemy)
                        local escapeDir = (myPos - enemyPos):Normalized()
                        rollPos = myPos + escapeDir * 800
                    end
                end
                
                if rollPos then
                    -- Usa remnant antes de rolar se tiver charge e mana para os dois casts
                    local hasRemnant = false
                    if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                        local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                        local myMana = NPC.GetMana(myHero)
                        local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                        local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                        if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                            hasRemnant = true
                        end
                    end
                    
                    if hasRemnant then
                        local myPos = Entity.GetAbsOrigin(myHero)
                        local dirToRoll = (rollPos - myPos):Normalized()
                        local remnantPos = myPos + dirToRoll * 200
                        
                        Ability.CastPosition(stoneRemnant, remnantPos)
                        earthSpiritPending = {
                            active = true,
                            time = now,
                            escapePos = rollPos
                        }
                    else
                        Ability.CastPosition(rolling, rollPos)
                    end
                end
            end
        end
    end
    prevPushKeyState = pushKeyDown


    -- EARTH SPIRIT: Usa Rolling Boulder apos colocar Stone Remnant
    if earthSpiritPending.active then
        local heroName = NPC.GetUnitName(myHero)
        if heroName == "npc_dota_hero_earth_spirit" then
            local elapsed = now - earthSpiritPending.time
            -- Timeout apos 1.0 segundos
            if elapsed >= 1.0 then
                earthSpiritPending.active = false
            -- Tenta a partir de 0.05s ate conseguir (ou ate 0.5s fallback)
            elseif elapsed >= 0.05 then
                if rolling and Ability.IsCastable(rolling, NPC.GetMana(myHero)) then
                    Ability.CastPosition(rolling, earthSpiritPending.escapePos)
                    earthSpiritPending.active = false
                end
                if elapsed >= 0.5 then
                    earthSpiritPending.active = false
                end
            end
        else
            earthSpiritPending.active = false
        end
    end
    

    -- Combo hold logic (bloqueado durante push escape)
    local holding = IsKeyDown(ui.hotkey:Get())
    if holding and not combo_active and not pushModeActive then
        combo_active, combo_state = true, 0
        smash_enemy = FindEnemyTarget(myHero, true)
        FindPreferredAlly(myHero, true)
        DebugPrint("Combo start")
        debug_last = "start"
        retreat_pending = false
        retreat_dir = nil
        approach_roll_active = false
        earthSpiritPending.active = false  -- Limpa qualquer roll pendente ao iniciar combo
        FileLog("Combo START alvo="..(smash_enemy and Entity.GetUnitName(smash_enemy) or "nil"))
        local allyStart = FindPreferredAlly(myHero, false)
        FileLog("Ally SELECT="..(allyStart and Entity.GetUnitName(allyStart) or "auto"))
    elseif (not holding) and combo_active then
        combo_active, combo_state, smash_enemy = false, 0, nil
        locked_target = nil
        locked_ally = nil
        TargetLock.ClearLock()
        DebugPrint("Combo stop")
    end
    
    -- Bloqueia combo se push mode está ativo
    if pushModeActive then
        return
    end

    if (not combo_active) then return end
    if (not smash_enemy) or (not Entity.IsAlive(smash_enemy)) then return end
    local myPos, enemyPos = Entity.GetAbsOrigin(myHero), Entity.GetAbsOrigin(smash_enemy)
    local dist = (myPos - enemyPos):Length2D()

    local pref_ally = FindPreferredAlly(myHero, false)

    if combo_state == 0 then
        -- Preferir Rolling se configurado e disponível
        if ui.prefer_roll:Get() and rolling and dist > ui.min_dist:Get() and dist < 1200 then
            if not CanCast(myHero, rolling) then FileLog("STATE0 ROLL prefer blocked: cooldown/mana") end
            if not CanCast(myHero, rolling) then
                -- fall through to other options
            elseif CanCast(myHero, rolling) then
            local myPosIn = Entity.GetAbsOrigin(myHero)
            local predicted = PredictEnemyPos(smash_enemy, now)
            local dirIn = (predicted - myPosIn)
            local lenIn = dirIn:Length2D()
            if lenIn > 1 then
                TryCast("roll_in", 0, function()
                    -- Usa remnant antes de rolar se tiver charge e mana para os dois casts
                    local hasRemnant = false
                    if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                        local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                        local myMana = NPC.GetMana(myHero)
                        local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                        local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                        if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                            hasRemnant = true
                        end
                    end
                    
                    if hasRemnant then
                        local myPosInCast = Entity.GetAbsOrigin(myHero)
                        local dirToRoll = (predicted - myPosInCast):Normalized()
                        local remnantPos = myPosInCast + dirToRoll * 200
                        Ability.CastPosition(stoneRemnant, remnantPos)
                        earthSpiritPending = { active = true, time = now, escapePos = predicted }
                    else
                        Ability.CastPosition(rolling, predicted)
                    end
                end)
                DebugPrint(string.format("STATE0: ROLL prefer -> predicted(%.1f,%.1f) len=%.1f", predicted.x, predicted.y, lenIn))
                FileLog(string.format("STATE0 ROLL prefer target=(%.0f,%.0f) travel=%.0f", predicted.x, predicted.y, lenIn))
                roll_travel = lenIn
                roll_started_at = now
                roll_target_point = predicted
                local roll_time = math.max(0.6, lenIn / 600.0 + 0.35)
                combo_time, combo_state = now + roll_time, 1
                approach_roll_active = true
                action_cd_until = now + 0.05
                gate_deadline = now + math.min(1.6, roll_time + 0.9)
            else
                combo_state = 1
                FileLog("STATE0 ROLL prefer skipped: lenIn<=1")
            end
            end
        elseif blink and Ability.IsReady(blink) and dist > 250 and dist < 1200 then
            TryCast("blink", ui.delay_blink:Get(), function() Ability.CastPosition(blink, enemyPos) end)
            combo_time, combo_state = now+0.15,1
            DebugPrint(string.format("STATE0: blink -> state=1 t=%.2f dist=%.1f", combo_time, dist))
            FileLog(string.format("STATE0 BLINK dist=%.1f", dist))
            
            -- Marca que usou blink (não precisa criar remnant depois)
            approach_roll_active = false
            earthSpiritPending.active = false  -- Cancela qualquer roll pendente
            action_cd_until = now + 0.05
        elseif rolling and CanCast(myHero, rolling) and dist > ui.min_dist:Get() and dist < 1200 then
            -- Inicia com Rolling Boulder para aproximar com direção precisa ao alvo
            local myPosIn = Entity.GetAbsOrigin(myHero)
            local predicted = PredictEnemyPos(smash_enemy, now)
            local dirIn   = (predicted - myPosIn)
            local lenIn   = dirIn:Length2D()
            if lenIn > 1 then
                TryCast("roll_in", 0, function()
                    -- Usa remnant antes de rolar se tiver charge e mana para os dois casts
                    local hasRemnant = false
                    if stoneRemnant and Ability.GetLevel(stoneRemnant) > 0 then
                        local remnantCharges = Ability.GetCurrentCharges and Ability.GetCurrentCharges(stoneRemnant) or 0
                        local myMana = NPC.GetMana(myHero)
                        local remnantCost = Ability.GetManaCost and Ability.GetManaCost(stoneRemnant) or 0
                        local boulderCost = Ability.GetManaCost and Ability.GetManaCost(rolling) or 0
                        if remnantCharges > 0 and myMana >= (remnantCost + boulderCost) and Ability.IsCastable(stoneRemnant, myMana) then
                            hasRemnant = true
                        end
                    end
                    
                    if hasRemnant then
                        local myPosInCast = Entity.GetAbsOrigin(myHero)
                        local dirToRoll = (predicted - myPosInCast):Normalized()
                        local remnantPos = myPosInCast + dirToRoll * 200
                        Ability.CastPosition(stoneRemnant, remnantPos)
                        earthSpiritPending = { active = true, time = now, escapePos = predicted }
                    else
                        Ability.CastPosition(rolling, predicted)
                    end
                end)
                DebugPrint(string.format("Rolling IN predicted: len=%.1f -> (%.1f,%.1f)", lenIn, predicted.x, predicted.y))
                debug_last = string.format("roll_in predicted (%.1f,%.1f)", predicted.x, predicted.y)
                FileLog(string.format("ROLL IN travel=%.1f target=(%.0f,%.0f)", lenIn, predicted.x, predicted.y))
                roll_travel = lenIn
                roll_started_at = now
                roll_target_point = predicted
                local roll_time = math.max(0.6, lenIn / 600.0 + 0.35) -- tempo dinamico: velocidade ~600 + margem
                combo_time, combo_state = now + roll_time, 1 -- espera tempo suficiente
                DebugPrint(string.format("Rolling IN ETA=%.2fs start=%.2f", roll_time, roll_started_at))
                FileLog(string.format("ROLL ETA=%.2f", roll_time))
                approach_roll_active = true
                action_cd_until = now + 0.05
                gate_deadline = now + math.min(1.6, roll_time + 0.9)
            else
                combo_state = 1
                DebugPrint("Rolling IN: len too small -> state=1")
                FileLog("ROLL IN skipped: too close")
            end
        elseif harpoon and Ability.IsReady(harpoon) and dist > 300 and dist < 1300 then
            TryCast("harpoon", ui.delay_harpoon:Get(), function() Ability.CastTarget(harpoon,smash_enemy) end)
            combo_time, combo_state = now+0.3,1
            DebugPrint("STATE0: harpoon -> state=1")
            FileLog("STATE0 HARPOON")
            action_cd_until = now + 0.05
        elseif ui.use_move:Get() and dist > ui.min_dist:Get() then
            if not IsRolling(myHero) then
                SmoothChase(myHero, smash_enemy, ui.min_dist:Get())
                action_cd_until = now + 0.05
            end
            DebugPrint("STATE0: chase")
            FileLog("STATE0 CHASE")
        else
            if dist <= ui.min_dist:Get() + 40 and smash and CanCast(myHero, smash) then
                -- Tentativa imediata de Smash se já está perto
                local pref_ally0 = FindPreferredAlly(myHero, false)
                local dir0 = pref_ally0 and DirectionTowardsAlly(smash_enemy, pref_ally0) or nil
                if not dir0 then
                    local bestScore, bestDir = -9999, nil
                    for i = 0, 15 do
                        local angle = (math.pi * 2 / 16) * i
                        local d    = Vector(math.cos(angle), math.sin(angle), 0)
                        local startPos = Entity.GetAbsOrigin(smash_enemy)
                        local endPos   = startPos + d * 600
                        local score = 0
                        local myPos2 = Entity.GetAbsOrigin(myHero)
                        if (endPos - myPos2):Length2D() < (startPos - myPos2):Length2D() then score = score + 30 end
                        if score > bestScore then bestScore, bestDir = score, d end
                    end
                    dir0 = bestDir
                end
                if not smash then FileLog("STATE0 FAST_SMASH smash nil") end
                if smash and not CanCast(myHero, smash) then FileLog("STATE0 FAST_SMASH not castable (cd/mana)") end
                if dir0 and smash and CanCast(myHero, smash) then
                    local fastOk = TryCast("smash_fast", 0, function() Ability.CastPosition(smash, Entity.GetAbsOrigin(smash_enemy) + dir0 * 300) end)
                    if fastOk then
                        FileLog(string.format("STATE0 FAST_SMASH dir=(%.2f,%.2f) dist=%.1f", dir0.x, dir0.y, dist))
                        combo_state, combo_time = 2, now + 0.15
                    else
                        FileLog("STATE0 FAST_SMASH TryCast locked")
                        combo_state = 1
                    end
                else
                    combo_state = 1
                    FileLog("STATE0 FAST_SMASH dir_nil_or_unavailable -> state=1")
                end
            else
                combo_state = 1
                DebugPrint("STATE0: ready -> state=1")
                FileLog("STATE0 READY -> 1")
            end
        end

    elseif combo_state == 1 and now >= combo_time then
        FileLog("STATE1 ENTER")
        if ui.enchant:Get() and has_aghs and enchant then
            TryCast("enchant", ui.delay_enchant:Get(), function() Ability.CastTarget(enchant, smash_enemy) end)
            DebugPrint("STATE1: enchant")
            FileLog("STATE1 ENCHANT")
        end
        combo_state, combo_time = 2, now+0.12
        DebugPrint("STATE1: -> state=2")
        FileLog("STATE1 -> 2")

    elseif combo_state == 2 and now >= combo_time then
        -- Garantir que a rolagem terminou e estamos de frente ao inimigo (com timeout)
        if approach_roll_active and roll_started_at > 0 then
            local myPosCheck = Entity.GetAbsOrigin(myHero)
            local toRollTarget = roll_target_point and (roll_target_point - myPosCheck):Length2D() or 0
            local enemyPosCheck = Entity.GetAbsOrigin(smash_enemy)
            local facingDir = (enemyPosCheck - myPosCheck)
            local lenF = facingDir:Length2D()
            if lenF > 1 then
                local dirN = facingDir:Normalized()
                local forward = Entity.GetForwardVector(myHero) or dirN
                local dot = forward.x*dirN.x + forward.y*dirN.y
                local rollingNow = IsRolling(myHero)
                local enemyDist = (enemyPosCheck - myPosCheck):Length2D()
                DebugPrint(string.format("STATE2: rem=%.1f enemyDist=%.1f dot=%.2f roll=%s deadline=%.2f now=%.2f",
                    toRollTarget, enemyDist, dot, tostring(rollingNow), gate_deadline, now))
                FileLog(string.format("ROLL CHECK rem=%.1f enemyDist=%.1f dot=%.2f roll=%s deadline=%.2f now=%.2f",
                    toRollTarget, enemyDist, dot, tostring(rollingNow), gate_deadline, now))
                local pass = false
                if rollingNow then
                    pass = (toRollTarget <= 200 and dot >= 0.75) or (now >= gate_deadline)
                else
                    pass = (enemyDist <= 275 and dot >= 0.65) or (now >= gate_deadline)
                end
                if not pass then
                    if dot < 0.75 and toRollTarget <= 250 then
                        Player.PrepareUnitOrders(Players.GetLocal(),
                            Enum.UnitOrder.DOTA_UNIT_ORDER_MOVE_TO_POSITION,
                            0,
                            enemyPosCheck,
                            nil,
                            Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                            myHero,
                            false,
                            true
                        )
                        DebugPrint("STATE2: face correction before Smash")
                        FileLog("FACE CORRECTION issued")
                    end
                    combo_time = now + 0.08
                    FileLog("ROLL WAIT")
                    return
                end
            end
            -- reset markers após validação
            roll_started_at = 0
            roll_travel = 0
            roll_target_point = nil
            approach_roll_active = false
            gate_deadline = 0
            FileLog("ROLL COMPLETE")
        end
        if not smash then
            FileLog("STATE2 smash ability nil")
        elseif not CanCast(myHero, smash) then
            FileLog("STATE2 smash not castable (cd/mana)")
        else
            local dir = pref_ally and DirectionTowardsAlly(smash_enemy, pref_ally) or nil
            if not dir then
                local bestScore, bestDir = -9999, nil
                for i = 0, 15 do
                    local angle = (math.pi * 2 / 16) * i
                    local d    = Vector(math.cos(angle), math.sin(angle), 0)
                    local startPos = Entity.GetAbsOrigin(smash_enemy)
                    local endPos   = startPos + d * 600
                    local score = 0
                    local myPos2 = Entity.GetAbsOrigin(myHero)
                    if (endPos - myPos2):Length2D() < (startPos - myPos2):Length2D() then score = score + 30 end
                    if score > bestScore then bestScore, bestDir = score, d end
                end
                dir = bestDir
                DebugPrint("Fallback radial dir")
            else
                DebugPrint("Ally-directed dir towards "..Entity.GetUnitName(pref_ally))
            end
            if dir then
                -- Verifica se há aliado próximo na posição do smash_enemy (evita empurrar aliado)
                local enemyPos = Entity.GetAbsOrigin(smash_enemy)
                local hasAllyNear = false
                for _, ally in pairs(Heroes.GetAll()) do
                    if ally ~= myHero and IsValidHero(ally) and Entity.IsSameTeam(myHero, ally) then
                        local distToEnemy = (Entity.GetAbsOrigin(ally) - enemyPos):Length2D()
                        if distToEnemy <= 200 then
                            hasAllyNear = true
                            FileLog("STATE2 smash BLOCKED: aliado próximo ao inimigo")
                            break
                        end
                    end
                end
                
                -- Verifica se há remnant próximo ao inimigo (evita chutar remnant em vez do herói)
                local hasRemnantNear = false
                if not hasAllyNear then
                    for i = 1, NPCs.Count() do
                        local npc = NPCs.Get(i)
                        if npc and Entity.IsAlive(npc) then
                            local npcName = NPC.GetUnitName(npc)
                            if npcName == "npc_dota_earth_spirit_stone" then
                                local distToEnemy = (Entity.GetAbsOrigin(npc) - enemyPos):Length2D()
                                if distToEnemy <= 150 then
                                    hasRemnantNear = true
                                    FileLog(string.format("STATE2 smash BLOCKED: remnant próximo ao inimigo (dist=%.1f)", distToEnemy))
                                    break
                                end
                            end
                        end
                    end
                end
                
                if not hasAllyNear and not hasRemnantNear then
                    last_dir = dir
                    local castOk = TryCast("smash", ui.delay_smash:Get(), function()
                        Ability.CastPosition(smash, Entity.GetAbsOrigin(smash_enemy) + dir * 300)
                    end)
                    if castOk then
                        Log(string.format("Smash dir=(%.2f,%.2f) enemy=%s ally=%s", dir.x, dir.y, Entity.GetUnitName(smash_enemy), pref_ally and Entity.GetUnitName(pref_ally) or "nil"))
                        FileLog(string.format("SMASH cast dir=(%.2f,%.2f) enemy=%s ally=%s", dir.x, dir.y, Entity.GetUnitName(smash_enemy), pref_ally and Entity.GetUnitName(pref_ally) or "nil"))
                    else
                        FileLog("STATE2 smash TryCast locked (delay timer)")
                    end
                end
                if ui.retreat_after_smash:Get() and rolling and CanCast(myHero, rolling) then
                    retreat_dir = dir
                    retreat_pending = true
                    DebugPrint("STATE2: retreat pending")
                    FileLog("RETREAT queued")
                end
            else
                FileLog("STATE2 dir nil (no ally/fallback)")
            end
        end
        if retreat_pending and ui.retreat_after_smash:Get() then
            combo_state, combo_time = 3, now+0.25
            DebugPrint("STATE2: -> state=3 (retreat)")
            FileLog("STATE2 -> 3")
        else
            combo_state, combo_time = 0, now+0.2
            DebugPrint("STATE2: -> state=0")
            FileLog("STATE2 -> 0")
        end
    elseif combo_state == 3 and now >= combo_time then
        if rolling and CanCast(myHero, rolling) and retreat_dir then
            local myPos2 = Entity.GetAbsOrigin(myHero)
            local retreat_point = myPos2 + retreat_dir * 700
            TryCast("roll_out", 0, function() Ability.CastPosition(rolling, retreat_point) end)
            DebugPrint("Rolling Boulder retirada -> aliado")
            FileLog(string.format("RETREAT roll -> (%.0f,%.0f)", retreat_point.x, retreat_point.y))
        end
        retreat_pending = false
        retreat_dir = nil
        combo_state, combo_time = 0, now+0.4
        DebugPrint("STATE3: done -> state=0")
        FileLog("STATE3 done -> 0")
    end
end

-- ========= OVERLAY =========
function EuphoriaAddon2.OnDraw()
    if not ui.enable:Get() then return end
    
    -- Draw target lock quando combo está ativo
    if combo_active and smash_enemy and Entity.IsAlive(smash_enemy) then
        TargetLock.DrawTargetLock(smash_enemy)
    end
    
    -- Draw cursor range para push mode
    if ui.save_enable:Get() and IsKeyDown(ui.save_hotkey:Get()) then
        local cursorPos = Input.GetWorldCursorPos()
        if cursorPos then
            local range = ui.save_cursor_range:Get()
            local segments = 32
            for i = 0, segments do
                local angle1 = (math.pi * 2 / segments) * i
                local angle2 = (math.pi * 2 / segments) * (i + 1)
                local p1 = cursorPos + Vector(math.cos(angle1) * range, math.sin(angle1) * range, 0)
                local p2 = cursorPos + Vector(math.cos(angle2) * range, math.sin(angle2) * range, 0)
                Renderer.DrawLine3D(p1, p2, 100, 200, 255, 200, 2)
            end
        end
    end
    
    -- Draw ally lock quando combo está ativo
    if combo_active and locked_ally and Entity.IsAlive(locked_ally) then
        local allyPos = Entity.GetAbsOrigin(locked_ally)
        local radius = 120
        local segments = 32
        for i = 0, segments do
            local angle1 = (math.pi * 2 / segments) * i
            local angle2 = (math.pi * 2 / segments) * (i + 1)
            local p1 = allyPos + Vector(math.cos(angle1) * radius, math.sin(angle1) * radius, 0)
            local p2 = allyPos + Vector(math.cos(angle2) * radius, math.sin(angle2) * radius, 0)
            Renderer.DrawLine3D(p1, p2, 0, 255, 0, 200, 2)
        end
        local screenPos = Renderer.WorldToScreen(allyPos)
        if screenPos then
            Renderer.DrawText(screenPos.x, screenPos.y - 40, "ALLY TARGET", 0, 255, 0, 255, 12, true)
        end
    end
    

    
end

return EuphoriaAddon2
