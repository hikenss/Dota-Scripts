---@diagnostic disable: undefined-global
--========================================================
-- AutoReaperAddons [优化版]
--========================================================
-- 特性:
-- - 自动精准释放 Reaper's Scythe
-- - 考虑技能增强、魔抗、各种吸收盾
-- - 检测莲花、林肯、敌法壳
-- - 考虑 Aegis / Reincarnation
-- - Debug 输出更清晰
--========================================================

local AutoReaper = {}

-- ========= MENU =========
local ui = {}
do
    local necroTab = Menu.Find("Heroes", "Hero List", "Necrophos")
    if necroTab then
        local thirdTab = necroTab:Create("Uso Automático")
        local group = thirdTab:Create("Foice do Ceifador Automática")

        ui.enable = group:Switch("⚡ Execução automática precisa", true)
        ui.debug  = group:Switch("🐞 Informações de Debug", false)
    end
end

-- ========= INTERNAL =========
local myHero = nil
local reaper = nil
local isCasting = false

-- ================= UTILS =================
-- Spell Amp
local function GetSpellAmp()
    local amp = 0.0
    if NPC.HasModifier(myHero, "modifier_item_kaya") then amp = amp + 0.08 end
    if NPC.HasModifier(myHero, "modifier_item_yasha_and_kaya") then amp = amp + 0.16 end
    if NPC.HasModifier(myHero, "modifier_item_kaya_and_sange") then amp = amp + 0.16 end
    if NPC.HasModifier(myHero, "modifier_special_bonus_spell_amp_8") then amp = amp + 0.08 end
    if NPC.HasModifier(myHero, "modifier_special_bonus_spell_amp_12") then amp = amp + 0.12 end
    if NPC.HasModifier(myHero, "modifier_item_fairys_trinket") then amp = amp + 0.05 end
    if NPC.HasModifier(myHero, "modifier_item_nether_shawl") then amp = amp + 0.08 end
    if NPC.HasModifier(myHero, "modifier_item_dagger_of_ristul") then amp = amp + 0.12 end
    if NPC.HasModifier(myHero, "modifier_item_witch_blade") then amp = amp + 0.12 end
    if NPC.HasModifier(myHero, "modifier_item_bloodthorn") then amp = amp + 0.30 end
    if NPC.HasModifier(myHero, "modifier_item_phylactery") then amp = amp + 0.20 end
    return amp
end

-- Cast Range Bonus
local function GetCastRangeBonus()
    local bonus = 0
    if NPC.HasModifier(myHero, "modifier_item_aether_lens") then bonus = bonus + 225 end
    if NPC.HasModifier(myHero, "modifier_item_telescope") then bonus = bonus + 125 end
    if NPC.HasModifier(myHero, "modifier_item_psychic_headband") then bonus = bonus + 100 end
    if NPC.HasModifier(myHero, "modifier_item_octarine_core") then bonus = bonus + 225 end
    return bonus
end

-- Checks
local function HasSpellBlock(target)
    -- Linken Sphere
    if NPC.IsLinkensProtected and NPC.IsLinkensProtected(target) then
        if ui.debug and ui.debug:Get() then
            print("[AutoReaper] ❌ Bloqueado por Esfera de Linken")
        end
        return true
    end

    -- Lotus Orb
    if NPC.HasModifier(target, "modifier_item_lotus_orb_active") then
        if ui.debug and ui.debug:Get() then
            print("[AutoReaper] ❌ Bloqueado por Lotus Orb")
        end
        return true
    end

    -- Antimage Counterspell
    if NPC.HasModifier(target, "modifier_antimage_counterspell") then
        if ui.debug and ui.debug:Get() then
            print("[AutoReaper] ❌ Bloqueado por Contra-Feitiço do Antimage")
        end
        return true
    end

    return false
end

local function IsImmune(target)
    return NPC.HasState(target, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE)
end

local function HasSecondLife(target)
    if NPC.HasItem(target, "item_aegis", true) then return true end
    if NPC.HasAbility(target, "skeleton_king_reincarnation") then
        local reinc = NPC.GetAbility(target, "skeleton_king_reincarnation")
        if reinc and Ability.IsReady(reinc) then return true end
    end
    return false
end

local function IsSaved(target)
    return NPC.HasModifier(target, "modifier_eul")
        or NPC.HasModifier(target, "modifier_obsidian_destroyer_astral_imprisonment_prison")
        or NPC.HasModifier(target, "modifier_oracle_fates_edict")
        or NPC.HasModifier(target, "modifier_dazzle_shallow_grave")
        or NPC.HasModifier(target, "modifier_item_aeon_disk_buff")
end

-- ================= DAMAGE =================
local function GetReaperDamage(target)
    local hp = Entity.GetHealth(target)
    local maxhp = Entity.GetMaxHealth(target)
    local level = Ability.GetLevel(reaper)
    if level == 0 then return 0 end

    local damage_per_hp = {0.6, 0.75, 0.9}
    local raw_dmg = (maxhp - hp) * damage_per_hp[level]

    local dmg = raw_dmg * (1 + GetSpellAmp())
    local magic_resist = NPC.GetMagicalArmorValue(target) or 0
    dmg = dmg * (1 - magic_resist)

    if NPC.HasModifier(target, "modifier_item_pipe_barrier") then dmg = dmg - 400 end
    if NPC.HasModifier(target, "modifier_item_hood_of_defiance_barrier") then dmg = dmg - 325 end
    if NPC.HasModifier(target, "modifier_item_infused_raindrop") then dmg = dmg - 120 end
    if NPC.HasModifier(target, "modifier_item_cloak") then dmg = dmg * 0.85 end
    if NPC.HasModifier(target, "modifier_item_eternal_shroud") then dmg = dmg * 0.75 end

    return math.max(dmg, 0)
end

-- ================= LOGIC =================
local function IsKillable(target)
    if not target or not Entity.IsAlive(target) then return false end
    if not reaper or not Ability.IsCastable(reaper, NPC.GetMana(myHero)) then return false end
    if HasSpellBlock(target) or IsImmune(target) then return false end
    if HasSecondLife(target) or IsSaved(target) then return false end

    local castRange = Ability.GetCastRange(reaper) + GetCastRangeBonus()
    if not NPC.IsEntityInRange(myHero, target, castRange) then return false end

    local hp = Entity.GetHealth(target)
    local dmg = GetReaperDamage(target)
    local incoming = Hero.GetHurtAmount(target) or 0

    if ui.debug and ui.debug:Get() then
        print(string.format(
            "[AutoReaper] 🎯 %s | HP: %.0f | Dano Recebido: %.0f | Dano: %.0f | Alcance: %d | HP Final: %.0f",
            Entity.GetUnitName(target), hp, incoming, dmg, castRange, hp - incoming - dmg
        ))
    end

    return (hp - incoming) <= dmg
end

-- ================= CAST =================
local function CastReaper()
    local enemies = Heroes.GetAll()
    for _, enemy in pairs(enemies) do
        if enemy and Entity.IsHero(enemy) and not Entity.IsSameTeam(myHero, enemy) then
            if IsKillable(enemy) then
                Player.PrepareUnitOrders(
                    Players.GetLocal(),
                    Enum.UnitOrder.DOTA_UNIT_ORDER_CAST_TARGET,
                    enemy, nil, reaper,
                    Enum.PlayerOrderIssuer.DOTA_ORDER_ISSUER_HERO_ONLY,
                    myHero, false, true
                )
                isCasting = true
                return
            end
        end
    end
end

-- ========= CALLBACKS =========
function AutoReaper.OnUpdate()
    if not ui.enable or not ui.enable:Get() then return end
    if not myHero then myHero = Heroes.GetLocal() end
    if not myHero or not Entity.IsAlive(myHero) then return end

    if not reaper then
        reaper = NPC.GetAbility(myHero, "necrolyte_reapers_scythe")
    end

    if reaper and Ability.IsReady(reaper) then
        CastReaper()
    end

    if isCasting then
        if Ability.IsInAbilityPhase(reaper) or not Ability.IsReady(reaper) then
            isCasting = false
        else
            CastReaper()
        end
    end
end

return AutoReaper
