# Mudanças no AutoStacker

## ✅ Correções Implementadas:

### 1. **Modo Manual - Seleção Individual**
**ANTES:** Ao pressionar KEY_0, substituía TODAS as unidades anteriores
**AGORA:** Cada vez que pressiona KEY_0, ADICIONA as unidades selecionadas

**Como usar:**
```
1. Selecione Bear → Pressione KEY_0
2. Selecione Illusion 1 → Pressione KEY_0
3. Selecione Illusion 2 → Pressione KEY_0
...e assim por diante
```

Cada unidade é adicionada individualmente sem apagar as anteriores!

### 2. **Limite de Unidades Corrigido**
**PROBLEMA:** Só stackava 2-3 unidades simultaneamente
**CAUSA:** A função `assignUnitsToNearestCamps()` estava reutilizando camps antes de usar todos os 28 disponíveis

**SOLUÇÃO:**
- Agora rastreia GLOBALMENTE quais camps já estão em uso
- Só reutiliza camps quando TODOS os 28 já foram usados
- Console avisa: `[AutoStacker] WARNING: All camps already assigned, reusing nearest camp`

### 3. **Modo Automático Unificado**
- `autoAssignNonHeroUnits()` agora usa a MESMA lógica de `assignUnitsToNearestCamps()`
- Garante consistência entre modo manual e automático
- Sem duplicação de código

## 🎮 Comportamento Atual:

### Modo Manual (KEY_0):
```
Seleciona Bear → KEY_0 → "Adding 1 units (total: 1)"
Seleciona PL → KEY_0 → "Adding 1 units (total: 2)"
Seleciona Illusion → KEY_0 → "Adding 1 units (total: 3)"
```

### Modo Automático (KEY_9):
```
KEY_9 → Detecta automaticamente TODAS as unidades controláveis
[AutoStacker AUTO] npc_dota_lone_druid_bear -> Camp #5
[AutoStacker AUTO] npc_dota_hero_phantom_lancer (illusion) -> Camp #12
[AutoStacker AUTO] npc_dota_neutral_centaur_khan -> Camp #7
```

## 📊 Capacidade:

- **28 camps disponíveis** no mapa
- Pode stackar até **28 unidades simultaneamente** (1 por camp)
- Se tiver mais de 28, avisa e reutiliza o camp mais próximo

## 🐛 Console Logs:

### Manual:
```
[AutoStacker] Adding 1 units (total: 3)
[AutoStacker] Assigned unit to camp #15 (distance: 450)
```

### Automático:
```
[AutoStacker AUTO] npc_dota_lone_druid_bear -> Camp #5
[AutoStacker] Assigned unit to camp #5 (distance: 320)
```

### Aviso de Limite:
```
[AutoStacker] WARNING: All camps already assigned, reusing nearest camp
[AutoStacker] Assigned unit to camp #8 (SHARED, distance: 280)
```

## ✨ Melhorias:

1. ✅ Modo manual adiciona unidades incrementalmente
2. ✅ Suporte para até 28 unidades simultâneas (1 por camp)
3. ✅ Modo auto usa mesma lógica que manual
4. ✅ Mensagens de console mais informativas
5. ✅ Previne conflitos de camps
