# Melhores Práticas de Scripts Dota 2

## Target Selection

### 1. Input.GetNearestHeroToCursor() - MELHOR MÉTODO
```lua
-- Tinker v2 usa este método (mais simples e eficiente)
local target = Input.GetNearestHeroToCursor(Entity.GetTeamNum(myHero), Enum.TeamType.TEAM_ENEMY)
```

### 2. Heroes.InRadius() - Para área específica
```lua
-- Disruptor usa para buscar em raio do cursor
local targets = Heroes.InRadius(
    Input.GetWorldCursorPos(),
    searchRange,
    Entity.GetTeamNum(myHero),
    Enum.TeamType.TEAM_ENEMY
)
```

### 3. Manual Loop - Mais controle
```lua
-- Hoodwink/Earth Spirit usam loop manual
for _, hero in pairs(Heroes.GetAll()) do
    if not Entity.IsSameTeam(hero, localHero) 
        and Entity.IsAlive(hero) 
        and not NPC.IsIllusion(hero) then
        -- processar
    end
end
```

## Linken's Sphere Detection

```lua
-- Disruptor tem sistema completo
function IsHasGuard(npc)
    -- Linken's
    if NPC.IsLinkensProtected(npc) then
        return "Linkens"
    end
    
    -- Antimage Spell Shield com Aghs
    local spell_shield = NPC.GetAbility(npc, "antimage_spell_shield")
    if not NPC.HasModifier(npc, "modifier_silver_edge_debuff") 
        and spell_shield 
        and Ability.IsReady(spell_shield) 
        and (NPC.HasModifier(npc, "modifier_item_ultimate_scepter") 
            or NPC.HasModifier(npc, "modifier_item_ultimate_scepter_consumed")) then
        return "Lotus"
    end
    
    -- Lotus Orb
    if NPC.HasModifier(npc, "modifier_item_lotus_orb_active") then
        return "Lotus"
    end
    
    -- Magic Immune
    if NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_MAGIC_IMMUNE) 
        or NPC.HasState(npc, Enum.ModifierState.MODIFIER_STATE_OUT_OF_GAME) then
        return "Immune"
    end
    
    return "nil"
end
```

## Particle Tracking

```lua
-- Disruptor rastreia Glimpse via partículas
function OnParticleCreate(particle)
    if particle.name == "disruptor_glimpse_targetend" then
        table.insert(glimpse_table, {particle.index})
    end
end

function OnParticleUpdate(particle)
    for i, j in pairs(glimpse_table) do
        if j[1] == particle.index then
            if particle.position then
                glimpse_table[i][2] = particle.position
            end
        end
    end
end
```

## Cast Delays e Timers

```lua
-- Tinker v2 usa delay simples
local lastCastTime = 0
local castDelay = 0.1

function DoCombo(target)
    local now = os.clock()
    if now - lastCastTime < castDelay then return end
    lastCastTime = now
    
    -- cast abilities
end
```

## Recomendações para TargetLock.lua

### Adicionar Input.GetNearestHeroToCursor
```lua
function TargetLock.FindTargetSimple(teamNum)
    return Input.GetNearestHeroToCursor(teamNum, Enum.TeamType.TEAM_ENEMY)
end
```

### Adicionar Linken Detection
```lua
function TargetLock.HasLinken(target)
    return NPC.IsLinkensProtected(target) 
        or NPC.HasModifier(target, "modifier_item_lotus_orb_active")
end
```

### Adicionar Heroes.InRadius
```lua
function TargetLock.FindTargetsInRadius(pos, radius, teamNum)
    return Heroes.InRadius(pos, radius, teamNum, Enum.TeamType.TEAM_ENEMY)
end
```
