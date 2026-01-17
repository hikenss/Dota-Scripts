# Dota 2 Overlay - Análise com IA

Overlay transparente para Dota 2 com análise de draft, estatísticas e IA.

## 🚀 Como Usar (SIMPLES)

### Opção 1: Apenas o Overlay
Clique 2x em: **`ABRIR.bat`**
- Abre só o overlay
- Você abre o Dota separadamente

### Opção 2: Overlay + Dota Juntos
Clique 2x em: **`ABRIR_COM_DOTA.bat`**
- Abre o overlay E o Dota automaticamente
- Tudo em um clique!

### Para Fechar
Clique 2x em: **`FECHAR.bat`**
- Fecha o overlay

**OU** pressione qualquer tecla na janela preta que apareceu quando abriu.

---

## 📋 Funcionalidades

### ✅ Implementado
- [x] Janela transparente sobre o Dota 2
- [x] Game State Integration (GSI)
- [x] Servidor para receber dados do Dota
- [x] WebSocket para comunicação em tempo real
- [x] Interface de draft com heróis
- [x] Overlay in-game com power balance
- [x] Debug panel

### 🔨 Em Desenvolvimento
- [ ] Integração com OpenDota API
- [ ] Análise automática de draft
- [ ] Cálculo de win rate por matchup
- [ ] Integração com IA (GPT/Claude)
- [ ] Detecção automática de roles
- [ ] Sugestões estratégicas

## 🎮 Como Usar

1. Inicie o overlay com `npm start`
2. Abra o Dota 2
3. Entre em uma partida
4. O overlay aparecerá automaticamente sobre o jogo

### Atalhos
- O overlay é transparente e permite clicar através dele
- Panel de debug no canto inferior direito
- Durante o draft: mostra análise de composição
- Durante o jogo: mostra power balance e conceitos estratégicos

## 🔧 Configuração

### Portas
- **3000**: Servidor HTTP (recebe dados GSI)
- **3001**: WebSocket (comunicação com interface)

### Desenvolvimento
```bash
# Iniciar apenas o servidor (sem Electron)
npm run dev

# Build para produção
npm run build
```

## 📊 APIs Utilizadas

- **OpenDota API**: Estatísticas de heróis e matchups
- **Stratz API**: Dados avançados (futuro)
- **OpenAI/Claude**: Análise estratégica com IA (futuro)

## 🐛 Debug

Veja os logs no terminal e no painel de debug do overlay.

### Problemas Comuns

**Overlay não aparece:**
- Verifique se o servidor está rodando
- Confira se o arquivo GSI está na pasta correta do Dota

**Sem dados do jogo:**
- Entre em uma partida (não funciona no menu)
- Verifique os logs no terminal

**Erro de conexão:**
- Certifique-se que as portas 3000 e 3001 estão livres

## 📝 TODO

- [ ] Adicionar cache de dados da API
- [ ] Implementar análise de IA
- [ ] Adicionar configurações customizáveis
- [ ] Criar sistema de themes
- [ ] Adicionar histórico de partidas
- [ ] Implementar notificações de eventos importantes
