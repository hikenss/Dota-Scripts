-- Script de Combo Black Hole do Enigma - Lógica Completa de Refresher
local EnigmaCombo = {}

local ui = {}

-- Create menu
local firstTab = Menu.Create("Heroes", "Hero List", "Enigma")
local comboGroup = firstTab:Create("Black Hole Combo"):Create("Settings")
local itemsGroup = firstTab:Create("Black Hole Combo"):Create("Items")

-- Configurações principais
ui.comboKey = comboGroup:Bind("Tecla Combo", Enum.ButtonCode.KEY_MOUSE3)
ui.comboKey:Icon("\u{26A1}")

ui.minEnemies = comboGroup:Slider("Mínimo de Inimigos", 1, 5, 2)
ui.minEnemies:Icon("\u{E068}")

ui.blinkRange = comboGroup:Slider("Alcance do Blink", 800, 1600, 1200)
ui.blinkRange:Icon("\u{E105}")

ui.debugMode = comboGroup:Switch("Modo Debug", false)
ui.debugMode:Icon("\u{1F41B}")

-- Habilidades
ui.useMidnight = itemsGroup:Switch("Pulso da Meia-Noite", true)
ui.useMidnight:Image("panorama/images/spellicons/enigma_midnight_pulse_png.vtex_c")

-- Mobilidade
ui.useBlink = itemsGroup:Switch("Adaga de Salto", true)
ui.useBlink:Image("panorama/images/items/blink_png.vtex_c")

-- Proteção
ui.useBKB = itemsGroup:Switch("Barra do Rei Negro", true)
ui.useBKB:Image("panorama/images/items/black_king_bar_png.vtex_c")

ui.useGlimmer = itemsGroup:Switch("Capa Cintilante", true)
ui.useGlimmer:Image("panorama/images/items/glimmer_cape_png.vtex_c")

ui.usePipe = itemsGroup:Switch("Cachimbo da Perspicácia", true)
ui.usePipe:Image("panorama/images/items/pipe_png.vtex_c")

-- Dano/Debuffs
ui.useShivas = itemsGroup:Switch("Guarda de Shiva", true)
ui.useShivas:Image("panorama/images/items/shivas_guard_png.vtex_c")

ui.useVeil = itemsGroup:Switch("Véu da Discórdia", true)
ui.useVeil:Image("panorama/images/items/veil_of_discord_png.vtex_c")

ui.useOrchid = itemsGroup:Switch("Orquídea/Espinho Sangrento", true)
ui.useOrchid:Image("panorama/images/items/orchid_png.vtex_c")

ui.useRod = itemsGroup:Switch("Cetro de Atos", true)
ui.useRod:Image("panorama/images/items/rod_of_atos_png.vtex_c")

ui.useScythe = itemsGroup:Switch("Foice de Vyse", true)
ui.useScythe:Image("panorama/images/items/sheepstick_png.vtex_c")

-- Invisibilidade/Ataque (depois do Black Hole)
ui.useShadowBlade = itemsGroup:Switch("Lâmina Sombria (Depois)", true)
ui.useShadowBlade:Image("panorama/images/items/invis_sword_png.vtex_c")

ui.useSilverEdge = itemsGroup:Switch("Gume Prateado (Depois)", true)
ui.useSilverEdge:Image("panorama/images/items/silver_edge_png.vtex_c")

ui.useEthereal = itemsGroup:Switch("Lâmina Etérea (Depois)", true)
ui.useEthereal:Image("panorama/images/items/ethereal_blade_png.vtex_c")

-- Itens de Refresh (1=Fragmento, 2=Orbe, 3=Roshan, 4=Inteligente)
ui.useRefresher = itemsGroup:Switch("Refresher Automático", true)
ui.useRefresher:Image("panorama/images/items/refresher_png.vtex_c")

ui.refresherPriority = itemsGroup:Slider("Prioridade (1-4)", 1, 4, 4)
ui.refresherPriority:Icon("\u{2692}")

-- Variables
local myHero = nil
local lastActionTime = 0
local lastBlinkTime = 0
local lastBlackHoleTime = 0
local blackHoleCasted = false
local refreshersUsed = {}
local comboCount = 0

-- Debug
local function Debug(msg)
    if ui.debugMode:Get() then
        Log.Write("[Enigma] " .. tostring(msg))
    end
end

-- Get ability
local function GetAbility(hero, name)
    for i = 0, 25 do
        local ability = NPC.GetAbilityByIndex(hero, i)
        if ability and Ability.GetName(ability) == name then
            return ability
        end
    end
    return nil
end

-- Check ability readiness
local function IsReady(ability)
    if not ability then return false end
    if not Ability.IsReady(ability) then return false end
    if not Ability.IsCastable(ability, NPC.GetMana(myHero)) then return false end
    return true
end

-- Get valid enemies
local function GetValidEnemies()
    local myPos = Entity.GetAbsOrigin(myHero)
    local enemies = Heroes.InRadius(myPos, ui.blinkRange:Get(), Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_TYPE_ENEMY_TEAM)
    local valid = {}
    
    for _, enemy in ipairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) and NPC.IsVisible(enemy) then
            if not NPC.HasModifier(enemy, "modifier_black_king_bar_immune") and
               not NPC.HasState(enemy, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) then
                table.insert(valid, enemy)
            end
        end
    end
    
    return valid
end

-- Count enemies in radius
local function CountAt(pos, enemies, radius)
    local count = 0
    for _, enemy in ipairs(enemies) do
        local dist = (Entity.GetAbsOrigin(enemy) - pos):Length2D()
        if dist <= radius then
            count = count + 1
        end
    end
    return count
end

-- Find best position
local function FindBestPosition()
    local myPos = Entity.GetAbsOrigin(myHero)
    local enemies = GetValidEnemies()
    
    if #enemies == 0 then return nil, 0 end
    
    local bestPos = nil
    local maxCount = 0
    local radius = 420
    
    for _, enemy in ipairs(enemies) do
        local pos = Entity.GetAbsOrigin(enemy)
        local count = CountAt(pos, enemies, radius)
        if count > maxCount then
            maxCount = count
            bestPos = pos
        end
    end
    
    if #enemies >= 2 then
        local cx, cy = 0, 0
        for _, enemy in ipairs(enemies) do
            local pos = Entity.GetAbsOrigin(enemy)
            cx = cx + pos.x
            cy = cy + pos.y
        end
        local center = Vector(cx / #enemies, cy / #enemies, myPos.z)
        local count = CountAt(center, enemies, radius)
        if count > maxCount then
            maxCount = count
            bestPos = center
        end
    end
    
    return bestPos, maxCount
end

-- Find priority target
local function FindPriorityTarget()
    local myPos = Entity.GetAbsOrigin(myHero)
    local enemies = Heroes.InRadius(myPos, 800, Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_TYPE_ENEMY_TEAM)
    
    for _, enemy in ipairs(enemies) do
        if enemy and Entity.IsAlive(enemy) and not NPC.IsIllusion(enemy) then
            return enemy
        end
    end
    return nil
end

-- Get blink
local function GetBlink()
    return NPC.GetItem(myHero, "item_blink", true) or 
           NPC.GetItem(myHero, "item_overwhelming_blink", true) or 
           NPC.GetItem(myHero, "item_swift_blink", true) or 
           NPC.GetItem(myHero, "item_arcane_blink", true)
end

-- Check channeling
local function IsChannelingBlackHole()
    return NPC.IsChannellingAbility(myHero)
end

-- Get all available refreshers
local function GetAllRefreshers()
    local refreshers = {}
    
    local shard = NPC.GetItem(myHero, "item_refresher_shard", true)
    if shard and Ability.IsReady(shard) and not refreshersUsed["shard"] then
        table.insert(refreshers, {item = shard, name = "Shard", priority = 1})
    end
    
    local orb = NPC.GetItem(myHero, "item_refresher", true)
    if orb and Ability.IsReady(orb) and not refreshersUsed["orb"] then
        table.insert(refreshers, {item = orb, name = "Orb", priority = 2})
    end
    
    local roshan = NPC.GetItem(myHero, "item_ultimate_scepter_2", true)
    if roshan and Ability.IsReady(roshan) and not refreshersUsed["roshan"] then
        table.insert(refreshers, {item = roshan, name = "Roshan", priority = 3})
    end
    
    return refreshers
end

-- Select best refresher
local function SelectBestRefresher(refreshers)
    if #refreshers == 0 then return nil end
    
    local priority = ui.refresherPriority:Get()
    
    -- Smart mode (4)
    if priority == 4 then
        table.sort(refreshers, function(a, b)
            local aConsumable = (a.name == "Shard" or a.name == "Roshan")
            local bConsumable = (b.name == "Shard" or b.name == "Roshan")
            
            if aConsumable ~= bConsumable then
                return aConsumable
            end
            
            return a.priority < b.priority
        end)
        
        Debug("Smart: " .. refreshers[1].name)
        return refreshers[1]
    end
    
    -- Manual priority
    for _, ref in ipairs(refreshers) do
        if ref.priority == priority then
            return ref
        end
    end
    
    return refreshers[1]
end

-- Use refresher
local function UseRefresher()
    local refreshers = GetAllRefreshers()
    
    if #refreshers == 0 then
        Debug("No refreshers")
        return false
    end
    
    local selected = SelectBestRefresher(refreshers)
    
    if selected then
        Debug("Using " .. selected.name .. " (#" .. (comboCount + 1) .. ")")
        Ability.CastNoTarget(selected.item)
        
        if selected.name == "Shard" then
            refreshersUsed["shard"] = true
        elseif selected.name == "Orb" then
            refreshersUsed["orb"] = true
        elseif selected.name == "Roshan" then
            refreshersUsed["roshan"] = true
        end
        
        return true
    end
    
    return false
end

-- Use items AFTER Black Hole
local function UsePostBlackHoleItems()
    local time = GameRules.GetGameTime()
    
    if time - lastBlackHoleTime < 0.5 then
        return
    end
    
    if not IsChannelingBlackHole() then
        return
    end
    
    local shadowBlade = NPC.GetItem(myHero, "item_invis_sword", true)
    local silverEdge = NPC.GetItem(myHero, "item_silver_edge", true)
    local ethereal = NPC.GetItem(myHero, "item_ethereal_blade", true)
    local target = FindPriorityTarget()
    
    if ui.useSilverEdge:Get() and silverEdge and Ability.IsReady(silverEdge) then
        Debug("Silver Edge")
        Ability.CastNoTarget(silverEdge)
        return
    end
    
    if ui.useShadowBlade:Get() and shadowBlade and Ability.IsReady(shadowBlade) then
        Debug("Shadow Blade")
        Ability.CastNoTarget(shadowBlade)
        return
    end
    
    if ui.useEthereal:Get() and ethereal and Ability.IsReady(ethereal) and target then
        Debug("Ethereal")
        Ability.CastTarget(ethereal, target)
        return
    end
end

-- Main combo
local function DoCombo()
    local time = GameRules.GetGameTime()
    
    if time - lastActionTime < 0.1 then
        return
    end
    
    Debug("=== COMBO #" .. comboCount .. " ===")
    
    if not myHero or not Entity.IsAlive(myHero) then
        return
    end
    
    local blackHole = GetAbility(myHero, "enigma_black_hole")
    local midnight = GetAbility(myHero, "enigma_midnight_pulse")
    
    -- Refresher
    if not IsReady(blackHole) then
        local timeSince = time - lastBlackHoleTime
        
        if ui.useRefresher:Get() and timeSince > 4.0 then
            if UseRefresher() then
                lastActionTime = time
                blackHoleCasted = false
                return
            end
        end
        
        Debug("BH not ready")
        return
    end
    
    -- Position
    local bestPos, enemyCount = FindBestPosition()
    
    Debug("Enemies: " .. enemyCount)
    
    if not bestPos or enemyCount < ui.minEnemies:Get() then
        return
    end
    
    local myPos = Entity.GetAbsOrigin(myHero)
    local dist = (bestPos - myPos):Length2D()
    
    -- Items
    local blink = GetBlink()
    local bkb = NPC.GetItem(myHero, "item_black_king_bar", true)
    local glimmer = NPC.GetItem(myHero, "item_glimmer_cape", true)
    local pipe = NPC.GetItem(myHero, "item_pipe", true)
    local shivas = NPC.GetItem(myHero, "item_shivas_guard", true)
    local veil = NPC.GetItem(myHero, "item_veil_of_discord", true)
    local orchid = NPC.GetItem(myHero, "item_orchid", true) or NPC.GetItem(myHero, "item_bloodthorn", true)
    local atos = NPC.GetItem(myHero, "item_rod_of_atos", true)
    local scythe = NPC.GetItem(myHero, "item_sheepstick", true)
    
    -- Blink
    if ui.useBlink:Get() and dist > 300 then
        if blink and Ability.IsReady(blink) and (time - lastBlinkTime) > 0.5 then
            if dist > 1200 then
                local dir = (bestPos - myPos):Normalized()
                bestPos = myPos + dir:Scaled(1200)
            end
            
            Ability.CastPosition(blink, bestPos)
            lastBlinkTime = time
            lastActionTime = time
            return
        end
        return
    end
    
    if dist > 450 then
        return
    end
    
    -- Debuffs
    local target = FindPriorityTarget()
    if target then
        if ui.useScythe:Get() and scythe and Ability.IsReady(scythe) then
            Ability.CastTarget(scythe, target)
        end
        if ui.useOrchid:Get() and orchid and Ability.IsReady(orchid) then
            Ability.CastTarget(orchid, target)
        end
        if ui.useRod:Get() and atos and Ability.IsReady(atos) then
            Ability.CastTarget(atos, target)
        end
    end
    
    -- Defense
    if ui.useBKB:Get() and bkb and Ability.IsReady(bkb) then
        Ability.CastNoTarget(bkb)
    end
    if ui.useGlimmer:Get() and glimmer and Ability.IsReady(glimmer) then
        Ability.CastTarget(glimmer, myHero)
    end
    if ui.usePipe:Get() and pipe and Ability.IsReady(pipe) then
        Ability.CastNoTarget(pipe)
    end
    
    -- Damage
    if ui.useVeil:Get() and veil and Ability.IsReady(veil) then
        Ability.CastPosition(veil, bestPos)
    end
    if ui.useShivas:Get() and shivas and Ability.IsReady(shivas) then
        Ability.CastNoTarget(shivas)
    end
    if ui.useMidnight:Get() and midnight and IsReady(midnight) then
        Ability.CastPosition(midnight, bestPos)
    end
    
    -- Black Hole
    if IsReady(blackHole) then
        Debug("BLACK HOLE")
        Ability.CastPosition(blackHole, bestPos)
        lastBlackHoleTime = time
        blackHoleCasted = true
        comboCount = comboCount + 1
        lastActionTime = time
    end
end

-- Update
function EnigmaCombo.OnUpdate()
    if not Engine.IsInGame() then return end
    
    if not myHero then
        myHero = Heroes.GetLocal()
        if not myHero then return end
    end
    
    if NPC.GetUnitName(myHero) ~= "npc_dota_hero_enigma" then return end
    
    if blackHoleCasted then
        UsePostBlackHoleItems()
    end
    
    if blackHoleCasted and not IsChannelingBlackHole() then
        local time = GameRules.GetGameTime()
        if time - lastBlackHoleTime > 4.5 then
            blackHoleCasted = false
        end
    end
    
    local time = GameRules.GetGameTime()
    if time - lastBlackHoleTime > 15.0 and comboCount > 0 then
        Debug("Reset (Total: " .. comboCount .. ")")
        comboCount = 0
        refreshersUsed = {}
    end
    
    if ui.comboKey:IsDown() then
        DoCombo()
    end
end

return EnigmaCombo
