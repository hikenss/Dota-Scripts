--[[
    @description: Axe Auto Call
    @autor: Rafz
]]

local axe_auto_call = {}
local UI, script_state = {}, {
    myHero = nil,
    castState = 0,
    stateTime = 0,
    stored_data = {},
    best_pos = nil,
    best_count = 0,
    last_debug_scan_time = 0,
    danger_zones = {}
}

local tab = Menu.Create("Heroes", "Hero List", "Axe", "Axe Auto Call")

local group_main = tab:Create("Main Settings")
UI.enable = group_main:Switch("Enable Script", true, "\u{f1e3}")
UI.mode = group_main:Combo("Activation Mode", {"Auto", "On Key"}, 1)
UI.combo_key = group_main:Bind("Combo Key", Enum.ButtonCode.KEY_SPACE)

local group_settings = tab:Create("Combo Settings")
UI.min_targets = group_settings:Slider("Min Heroes to Engage", 1, 5, 2)
UI.min_hp_pct = group_settings:Slider("Don't Combo if HP Below %", 0, 100, 30)
UI.search_radius_on_key = group_settings:Slider("Mouse Search Radius (On Key)", 500, 2000, 1200)

local group_items = tab:Create("Items & Safety")
UI.items_select = group_items:MultiSelect("Items to Use in Combo", { 
    {"Blink (Any)", "panorama/images/items/blink_png.vtex_c", true}, 
    {"Blade Mail", "panorama/images/items/blade_mail_png.vtex_c", true}, 
    {"Black King Bar", "panorama/images/items/black_king_bar_png.vtex_c", true}, 
    {"Shiva's Guard", "panorama/images/items/shivas_guard_png.vtex_c", false}
}, true)
UI.block_orders = group_items:Switch("Block Commands During Combo", true)
UI.block_duration = group_items:Slider("Max Block Duration (s)", 0.0, 1.0, 0.4, "%.2fs")

local group_debug = tab:Create("Debug")
UI.debug_enable = group_debug:Switch("Enable Visual Debug", true)
UI.debug_log_state = group_debug:Switch("Log Decisions to Console", true)
UI.debug_draw_target = group_debug:Switch("Draw Target Position", true)
UI.font = Render.LoadFont("Tahoma", 16, 0)

local function LogDebug(...) if UI.debug_log_state and UI.debug_log_state:Get() then print("[Axe Debug]", ...) end end
local function IsAxe() if not script_state.myHero then script_state.myHero = Heroes.GetLocal() end; return script_state.myHero and NPC.GetUnitName(script_state.myHero) == "npc_dota_hero_axe" end
local function IsHeroReady(hero) return hero and Entity.IsAlive(hero) end
local function HPPercent(hero) return (Entity.GetHealth(hero) / Entity.GetMaxHealth(hero)) * 100 end

-- Checa se o Axe está silenciado/stunado/incapacitado
local function IsIncapacitated(hero)
    if not hero then return false end
    if NPC.IsSilenced(hero) then return true end
    if NPC.IsStunned(hero) then return true end
    if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_HEXED) then return true end
    if NPC.HasState(hero, Enum.ModifierState.MODIFIER_STATE_ROOTED) then return true end
    return false
end

local function GetEnemies(radius, origin)
    local enemies = {}
    for _, h in ipairs(Heroes.GetAll()) do
        if h ~= script_state.myHero and Entity.IsAlive(h)
            and not Entity.IsSameTeam(h, script_state.myHero)
            and not NPC.IsIllusion(h) and NPC.IsVisible(h) then
            if not radius or (Entity.GetAbsOrigin(h) - origin):Length2D() <= radius then
                table.insert(enemies, h)
            end
        end
    end
    return enemies
end

local function UpdateDangerZones()
    script_state.danger_zones = {}
    for _, enemy in ipairs(Heroes.GetAll()) do
        if Entity.IsAlive(enemy) and not Entity.IsSameTeam(enemy, script_state.myHero) then
            local bh = NPC.GetAbility(enemy, "enigma_black_hole")
            if bh and Ability.IsChannelling(bh) then
                local aoe = Ability.GetLevelSpecialValueFor(bh, "radius")
                table.insert(script_state.danger_zones, {pos = Entity.GetAbsOrigin(enemy), radius = aoe, name = "enigma_black_hole", caster = enemy, type = "cancelable"})
            end
            if NPC.HasModifier(enemy, "modifier_crystal_maiden_freezing_field") then
                local aoe = 835
                table.insert(script_state.danger_zones, {pos = Entity.GetAbsOrigin(enemy), radius = aoe, name = "crystal_maiden_freezing_field", caster = enemy, type = "uncancelable"})
            end
            if NPC.HasModifier(enemy, "modifier_faceless_void_chronosphere_freeze")
                or NPC.HasModifier(enemy, "modifier_faceless_void_chronosphere_aura") then
                local aoe = 425
                table.insert(script_state.danger_zones, {pos = Entity.GetAbsOrigin(enemy), radius = aoe, name = "faceless_void_chronosphere", caster = enemy, type = "uncancelable"})
            end
        end
    end
end

local function IsSafePosition(pos, callRadius)
    for _, danger in ipairs(script_state.danger_zones) do
        local dist = (pos - danger.pos):Length2D()
        if dist <= danger.radius then
            if danger.type == "cancelable" then
                if (Entity.GetAbsOrigin(danger.caster) - pos):Length2D() <= callRadius then
                    return true
                else
                    return false
                end
            else
                return false
            end
        end
    end
    return true
end

local function FindBestCallPosition()
    local call = NPC.GetAbility(script_state.myHero, "axe_berserkers_call")
    if not call or Ability.GetLevel(call) < 1 then return nil, 0 end
    local radius = Ability.GetLevelSpecialValueFor(call, "radius")
    local minCount = UI.min_targets:Get()
    local search_origin = Entity.GetAbsOrigin(script_state.myHero)
    local search_radius = (UI.mode:Get() == 1) and UI.search_radius_on_key:Get() or nil
    if UI.mode:Get() == 1 then search_origin = Input.GetWorldCursorPos() end
    local enemies = GetEnemies(search_radius, search_origin)
    if #enemies < minCount then return nil, 0 end
    local positions = {}
    for _, h in ipairs(enemies) do table.insert(positions, Entity.GetAbsOrigin(h)) end
    for i = 1, #enemies - 1 do
        for j = i + 1, #enemies do
            table.insert(positions, (Entity.GetAbsOrigin(enemies[i]) + Entity.GetAbsOrigin(enemies[j])) * 0.5)
        end
    end
    local bestPos, bestCount = nil, 0
    for _, cand_pos in ipairs(positions) do
        local count = 0
        for _, h in ipairs(enemies) do
            if (Entity.GetAbsOrigin(h) - cand_pos):Length2D() <= radius then count = count + 1 end
        end
        if count >= minCount and count > bestCount and IsSafePosition(cand_pos, radius) then
            bestCount, bestPos = count, cand_pos
        end
    end
    return bestPos, bestCount
end

-- função auxiliar para pegar qualquer tipo de blink
local function GetBlinkItem(hero)
    return NPC.GetItem(hero, "item_blink", true)
        or NPC.GetItem(hero, "item_overwhelming_blink", true)
        or NPC.GetItem(hero, "item_swift_blink", true)
        or NPC.GetItem(hero, "item_arcane_blink", true)
end

axe_auto_call.OnUpdate = function()
    if not IsAxe() or not IsHeroReady(script_state.myHero) or not UI.enable:Get() then return end
    if HPPercent(script_state.myHero) < UI.min_hp_pct:Get() then return end
    if IsIncapacitated(script_state.myHero) then return end

    UpdateDangerZones()
    script_state.best_pos, script_state.best_count = FindBestCallPosition()

    local shouldExecute = (UI.mode:Get() == 0) or (UI.mode:Get() == 1 and UI.combo_key:IsDown())
    if not shouldExecute then return end
    if not script_state.best_pos then return end

    local myHero = script_state.myHero
    local call = NPC.GetAbility(myHero, "axe_berserkers_call")
    local blink = GetBlinkItem(myHero) -- agora pega qualquer blink
    local mePos = Entity.GetAbsOrigin(myHero)
    local dist = (script_state.best_pos - mePos):Length2D()

    if script_state.castState == 0 then
        if blink and Ability.IsReady(blink) and UI.items_select:Get("Blink (Any)") and dist <= Ability.GetCastRange(blink) then
            script_state.stored_data.bestPos = script_state.best_pos
            script_state.castState = 1
            script_state.stateTime = os.clock()
        elseif dist <= Ability.GetLevelSpecialValueFor(call, "radius") then
            local enemiesInRange = GetEnemies(Ability.GetLevelSpecialValueFor(call, "radius"), mePos)
            if #enemiesInRange >= UI.min_targets:Get() then
                script_state.castState = 2
                script_state.stateTime = os.clock()
            end
        end
    elseif script_state.castState == 1 then
        local blink = GetBlinkItem(myHero)
        if blink then Ability.CastPosition(blink, script_state.stored_data.bestPos) end
        script_state.castState = 2
        script_state.stateTime = os.clock()
    elseif script_state.castState == 2 then
        if os.clock() - script_state.stateTime < 0.1 then return end
        if IsIncapacitated(myHero) then return end
        local bkb = NPC.GetItem(myHero, "item_black_king_bar")
        if UI.items_select:Get("Black King Bar") and bkb and Ability.IsReady(bkb) then Ability.CastNoTarget(bkb) end
        local call = NPC.GetAbility(myHero, "axe_berserkers_call")
        if call and Ability.IsReady(call) then
            local enemiesInRange = GetEnemies(Ability.GetLevelSpecialValueFor(call, "radius"), Entity.GetAbsOrigin(myHero))
            if #enemiesInRange >= UI.min_targets:Get() then
                Ability.CastNoTarget(call)
            end
        end
        local bm = NPC.GetItem(myHero, "item_blade_mail")
        if UI.items_select:Get("Blade Mail") and bm and Ability.IsReady(bm) then Ability.CastNoTarget(bm) end
        local shivas = NPC.GetItem(myHero, "item_shivas_guard")
        if UI.items_select:Get("Shiva's Guard") and shivas and Ability.IsReady(shivas) then Ability.CastNoTarget(shivas) end
        script_state.castState = 0
    end
end

axe_auto_call.OnDraw = function()
    if not script_state.myHero or not UI.enable:Get() or not UI.debug_enable:Get() then return end
    if script_state.best_pos then
        local screenPos, onScreen = Render.WorldToScreen(script_state.best_pos)
        if onScreen then
            Render.Circle(screenPos, 15, Color(0, 255, 0, 200), 3)
            Render.Text(UI.font, 12, "Alvos: " .. script_state.best_count, screenPos + Vector(20, -6), Color(255, 255, 255, 220))
        end
    end
    for _, danger in ipairs(script_state.danger_zones) do
        local dangerPos, onScreen = Render.WorldToScreen(danger.pos)
        if onScreen then
            Render.Circle(dangerPos, danger.radius / 10, Color(255, 0, 0, 150), 2)
            Render.Text(UI.font, 12, "Ult: " .. danger.name, dangerPos + Vector(20, -6), Color(255, 80, 80, 220))
        end
    end
end

axe_auto_call.OnPrepareUnitOrders = function(data)
    if not UI.enable:Get() or not UI.block_orders:Get() then return true end
    if script_state.castState ~= 0 and os.clock() - script_state.stateTime < UI.block_duration:Get() then
        if data.orderIssuer == Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY then return false end
    end
    return true
end

return axe_auto_call
