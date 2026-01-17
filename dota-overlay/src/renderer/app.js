// Conexão WebSocket com o servidor
let ws;
let reconnectInterval;
let heroesData = [];

// Elementos DOM (serão inicializados após carregar)
let draftPanel;
let gameOverlay;
let statusIndicator;
let statusDot;
let statusText;

// Draft panel dragging
let isDraggingDraft = false;
let draftCurrentX = 0;
let draftCurrentY = 0;
let draftInitialX = 0;
let draftInitialY = 0;
let draftXOffset = 0;
let draftYOffset = 0;

// Status indicator dragging
let isDraggingStatus = false;
let statusCurrentX = 0;
let statusCurrentY = 0;
let statusInitialX = 0;
let statusInitialY = 0;
let statusXOffset = 0;
let statusYOffset = 0;

// Game overlay auto-hide timer
let gameOverlayTimer = null;
let lastGameUpdate = null;

// Conecta ao WebSocket
function connectWebSocket() {
  ws = new WebSocket('ws://localhost:3001');

  ws.onopen = () => {
    console.log('✅ Conectado ao servidor');
    statusDot.classList.add('connected');
    statusText.textContent = 'Conectado - Aguardando Dota...';
    clearInterval(reconnectInterval);
  };

  ws.onmessage = (event) => {
    const message = JSON.parse(event.data);
    handleGameStateUpdate(message.data);
  };

  ws.onerror = (error) => {
    console.error('❌ Erro no WebSocket:', error);
    statusDot.classList.remove('connected');
    statusDot.classList.add('disconnected');
    statusText.textContent = 'Erro de conexão';
  };

  ws.onclose = () => {
    console.log('🔌 Desconectado do servidor');
    statusDot.classList.remove('connected');
    statusDot.classList.add('disconnected');
    statusText.textContent = 'Desconectado - Reconectando...';
    
    // Tenta reconectar a cada 5 segundos
    reconnectInterval = setInterval(() => {
      console.log('🔄 Tentando reconectar...');
      connectWebSocket();
    }, 5000);
  };
}

// Carrega dados dos heróis
async function loadHeroesData() {
  try {
    const response = await fetch('http://localhost:3000/api/heroes');
    heroesData = await response.json();
    console.log(`📊 ${heroesData.length} heróis carregados`);
  } catch (error) {
    console.error('Erro ao carregar heróis:', error);
  }
}

// Processa atualização do estado do jogo
function handleGameStateUpdate(gameState) {
  if (!gameState) return;

  console.log('📡 Dados recebidos do Dota:', gameState);
  
  // Log do draft se existir
  if (gameState.draft) {
    console.log('📋 Draft data:', gameState.draft);
  }
  
  // Atualiza status
  statusText.textContent = 'Recebendo dados do Dota ✓';

  // Detecta fase do jogo
  const gamePhase = gameState.map?.game_state;
  
  console.log('🎮 Fase do jogo:', gamePhase);
  
  if (gamePhase === 'DOTA_GAMERULES_STATE_HERO_SELECTION') {
    console.log('⭐ DRAFT DETECTADO');
    statusText.textContent = 'DRAFT - Analisando...';
    // Mostra painel de draft
    showDraftPanel(gameState);
    hideGameOverlay();
  } else if (gamePhase === 'DOTA_GAMERULES_STATE_PRE_GAME' || gamePhase === 'DOTA_GAMERULES_STATE_GAME_IN_PROGRESS') {
    console.log('⚔️ JOGO EM ANDAMENTO');
    statusText.textContent = 'JOGO - Calculando...';
    // Mostra overlay in-game e atualiza com dados do jogo
    hideDraftPanel();
    showGameOverlay(gameState);
    
    // Se tiver draft data, atualiza os heróis também
    if (gameState.draft || gameState.hero) {
      updateDraftAnalysis(gameState);
    }
  } else {
    console.log('📋 Fase:', gamePhase || 'Menu');
    statusText.textContent = `Aguardando partida...`;
    // Menu ou outras fases - esconde tudo
    hideDraftPanel();
    hideGameOverlay();
  }
}

// Mostra painel de draft
function showDraftPanel(gameState) {
  draftPanel.classList.remove('hidden');
  
  // TODO: Implementar lógica de análise de draft
  // Por enquanto, mostra exemplo
  updateDraftAnalysis(gameState);
}

function hideDraftPanel() {
  draftPanel.classList.add('hidden');
}

// Mostra overlay in-game
function showGameOverlay(gameState) {
  const now = Date.now();
  
  // Só mostra uma vez e mantém (não fica atualizando)
  if (!gameOverlay.classList.contains('hidden')) {
    return; // Já está visível, não faz nada
  }
  
  gameOverlay.classList.remove('hidden');
  
  // Calcula power balance baseado em gold/xp
  if (gameState.player && gameState.map) {
    updatePowerBalance(gameState);
  }
  
  lastGameUpdate = now;
  
  // Auto-hide após 10 segundos
  if (gameOverlayTimer) {
    clearTimeout(gameOverlayTimer);
  }
  
  gameOverlayTimer = setTimeout(() => {
    gameOverlay.classList.add('hidden');
  }, 10000); // 10 segundos
}

function hideGameOverlay() {
  gameOverlay.classList.add('hidden');
  if (gameOverlayTimer) {
    clearTimeout(gameOverlayTimer);
    gameOverlayTimer = null;
  }
}

// Atualiza análise de draft
async function updateDraftAnalysis(gameState) {
  // Extrai heróis do game state
  let radiantHeroes = [];
  let direHeroes = [];
  
  console.log('🔍 Tentando detectar heróis...', gameState);
  
  if (gameState.draft && typeof gameState.draft === 'object') {
    // Durante o draft
    const draft = gameState.draft;
    console.log('📋 Draft completo:', JSON.stringify(draft, null, 2));
    
    // Procura picks em estrutura flat (team2_pick0, team2_pick1, etc)
    for (let key in draft) {
      if (key.startsWith('team2_pick') || key.startsWith('team2_class_')) {
        const pick = draft[key];
        if (pick && typeof pick === 'object' && pick.id) {
          const heroName = getHeroNameById(pick.id);
          if (heroName && heroName !== 'Unknown') {
            radiantHeroes.push(heroName);
          }
        } else if (pick && typeof pick === 'number') {
          const heroName = getHeroNameById(pick);
          if (heroName && heroName !== 'Unknown') {
            radiantHeroes.push(heroName);
          }
        }
      } else if (key.startsWith('team3_pick') || key.startsWith('team3_class_')) {
        const pick = draft[key];
        if (pick && typeof pick === 'object' && pick.id) {
          const heroName = getHeroNameById(pick.id);
          if (heroName && heroName !== 'Unknown') {
            direHeroes.push(heroName);
          }
        } else if (pick && typeof pick === 'number') {
          const heroName = getHeroNameById(pick);
          if (heroName && heroName !== 'Unknown') {
            direHeroes.push(heroName);
          }
        }
      }
    }
    
    // Fallback: procura em estrutura aninhada (team2.pick0, team3.pick0, etc)
    if (radiantHeroes.length === 0 && draft.team2 && typeof draft.team2 === 'object') {
      console.log('Radiant team2:', draft.team2);
      for (let key in draft.team2) {
        if (key.includes('pick') || key.includes('class_')) {
          const pick = draft.team2[key];
          if (pick && typeof pick === 'object' && pick.id) {
            const heroName = getHeroNameById(pick.id);
            if (heroName && heroName !== 'Unknown') {
              radiantHeroes.push(heroName);
            }
          } else if (pick && typeof pick === 'number') {
            const heroName = getHeroNameById(pick);
            if (heroName && heroName !== 'Unknown') {
              radiantHeroes.push(heroName);
            }
          }
        }
      }
    }
    
    if (direHeroes.length === 0 && draft.team3 && typeof draft.team3 === 'object') {
      console.log('Dire team3:', draft.team3);
      for (let key in draft.team3) {
        if (key.includes('pick') || key.includes('class_')) {
          const pick = draft.team3[key];
          if (pick && typeof pick === 'object' && pick.id) {
            const heroName = getHeroNameById(pick.id);
            if (heroName && heroName !== 'Unknown') {
              direHeroes.push(heroName);
            }
          } else if (pick && typeof pick === 'number') {
            const heroName = getHeroNameById(pick);
            if (heroName && heroName !== 'Unknown') {
              direHeroes.push(heroName);
            }
          }
        }
      }
    }
  }
  
  // Se não encontrou no draft, tenta dos players
  if (radiantHeroes.length === 0 && direHeroes.length === 0 && gameState.player) {
    // Tenta pegar do player data durante o jogo
    const playerTeam = gameState.player?.team_id;
    const playerHero = gameState.hero?.name?.replace('npc_dota_hero_', '').replace(/_/g, ' ');
    if (playerHero && playerTeam) {
      console.log('🎯 Detectado herói do player:', playerHero, 'team:', playerTeam);
      const heroName = formatHeroName(playerHero);
      if (playerTeam === 2) {
        radiantHeroes.push(heroName);
      } else if (playerTeam === 3) {
        direHeroes.push(heroName);
      }
    }
  }
  
  // Se ainda não encontrou heróis, NÃO usa exemplo - apenas retorna
  if (radiantHeroes.length === 0 && direHeroes.length === 0) {
    console.log('⚠️ Nenhum herói detectado ainda');
    // Mostra mensagem de aguardando
    document.getElementById('radiant-strategy').innerHTML = '<p>Aguardando seleção de heróis...</p>';
    document.getElementById('dire-strategy').innerHTML = '<p>Aguardando seleção de heróis...</p>';
    document.getElementById('connections').innerHTML = '<p>Aguardando draft completo...</p>';
    return;
  }
  
  console.log('🎯 Heróis detectados:', { radiantHeroes, direHeroes });
  
  // Só chama IA se tiver heróis suficientes
  if (radiantHeroes.length < 2 && direHeroes.length < 2) {
    console.log('⚠️ Poucos heróis para análise, aguardando...');
    return;
  }
  
  // Busca análise da IA
  fetch('http://localhost:3000/api/analyze-draft', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ radiantHeroes, direHeroes })
  })
  .then(res => {
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    return res.json();
  })
  .then(analysis => {
    // Atualiza estratégias
    document.getElementById('radiant-strategy').innerHTML = `<p>${analysis.radiantStrategy}</p>`;
    document.getElementById('dire-strategy').innerHTML = `<p>${analysis.direStrategy}</p>`;
    document.getElementById('connections').innerHTML = `<p>${analysis.connections}</p>`;
    
    // Atualiza conceito do jogo
    document.getElementById('game-concept').textContent = analysis.concept;
  })
  .catch(err => {
    console.error('Erro ao buscar análise:', err.message);
    // Mostra mensagem genérica sem chamar a IA
    document.getElementById('radiant-strategy').innerHTML = '<p>Análise de IA indisponível</p>';
    document.getElementById('dire-strategy').innerHTML = '<p>Análise de IA indisponível</p>';
    document.getElementById('connections').innerHTML = '<p>Configure a API key da OpenAI no arquivo .env</p>';
  });
  
  // Renderiza heróis
  renderHeroes('radiant-heroes', radiantHeroes);
  renderHeroes('dire-heroes', direHeroes);
}

// Converte ID do herói para nome
function getHeroNameById(heroId) {
  if (!heroId) return 'Unknown';
  
  const hero = heroesData.find(h => h.id === heroId);
  if (hero) {
    return hero.localized_name;
  }
  
  return `Hero ${heroId}`;
}

// Formata nome do herói
function formatHeroName(name) {
  return name
    .split(' ')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

function renderHeroes(elementId, heroes) {
  const container = document.getElementById(elementId);
  
  container.innerHTML = heroes.map((hero, index) => `
    <div class="hero-item">
      <div class="hero-icon">${getHeroEmoji(index)}</div>
      <div class="hero-info">
        <div class="hero-name">${hero}</div>
        <div class="hero-roles">
          ${getHeroRoles(hero)}
        </div>
      </div>
      <div class="hero-stats">
        <div class="win-rate">${50 + Math.floor(Math.random() * 10)}%</div>
      </div>
    </div>
  `).join('');
}

function getHeroEmoji(index) {
  const emojis = ['🛡️', '🏹', '❄️', '🐍', '🌊', '⚔️', '🦅', '📚', '🗡️', '👻'];
  return emojis[index] || '⚡';
}

function getHeroRoles(heroName) {
  const roles = {
    'Treant Protector': ['support', 'initiator'],
    'Clinkz': ['carry', 'mid'],
    'Tusk': ['support', 'initiator'],
    'Viper': ['mid', 'offlane'],
    'Tide Hunter': ['offlane', 'initiator'],
    'Centaur Warrunner': ['offlane', 'initiator'],
    'Skywrath Mage': ['support', 'mid'],
    'Warlock': ['support'],
    'Phantom Assassin': ['carry'],
    'Witch Doctor': ['support']
  };
  
  const heroRoles = roles[heroName] || ['support'];
  return heroRoles.map(role => 
    `<span class="role-badge role-${role}">${role.toUpperCase()}</span>`
  ).join('');
}

// Atualiza power balance
function updatePowerBalance(gameState) {
  // Usa vantagem de ouro/experiência se disponível
  let radiantPower = 50;
  let direPower = 50;

  const radiantGold = gameState.map?.radiant_gold_adv || 0;
  const direGold = gameState.map?.dire_gold_adv || 0;
  const radiantXP = gameState.map?.radiant_xp_adv || 0;
  const direXP = gameState.map?.dire_xp_adv || 0;

  const goldDelta = radiantGold - direGold;
  const xpDelta = radiantXP - direXP;
  const totalDelta = Math.abs(goldDelta) + Math.abs(xpDelta);

  if (totalDelta > 0) {
    const radiantScore = Math.max(goldDelta, 0) + Math.max(xpDelta, 0);
    radiantPower = Math.round((radiantScore / totalDelta) * 100);
    direPower = 100 - radiantPower;
  }

  const radiantBar = document.getElementById('radiant-power');
  const direBar = document.getElementById('dire-power');
  
  radiantBar.style.width = radiantPower + '%';
  direBar.style.width = direPower + '%';
  
  radiantBar.querySelector('.power-percent').textContent = radiantPower + '%';
  direBar.querySelector('.power-percent').textContent = direPower + '%';
  
  // Conceito estratégico
  let concept = 'Analisando composição do jogo...';

  if (radiantPower > 55) {
    concept = '🟢 Radiant em vantagem. Pressione torres e objetivos.';
  } else if (direPower > 55) {
    concept = '🔴 Dire em vantagem. Defenda e busque teamfights.';
  } else {
    concept = '⚖️ Partida equilibrada. Farm seguro e pickoffs.';
  }

  document.getElementById('game-concept').textContent = concept;
}

// Formata tempo do jogo
function formatTime(seconds) {
  const mins = Math.floor(Math.abs(seconds) / 60);
  const secs = Math.abs(seconds) % 60;
  const sign = seconds < 0 ? '-' : '';
  return `${sign}${mins}:${secs.toString().padStart(2, '0')}`;
}

// Inicialização
async function init() {
  console.log('🚀 Iniciando overlay...');
  
  // Seleciona elementos DOM
  draftPanel = document.getElementById('draft-panel');
  gameOverlay = document.getElementById('game-overlay');
  statusIndicator = document.getElementById('status-indicator');
  statusDot = document.querySelector('.status-dot');
  statusText = document.getElementById('status-text');
  
  await loadHeroesData();
  connectWebSocket();
  
  // Começa com tudo escondido
  hideDraftPanel();
  hideGameOverlay();
  
  // Setup draft panel controls
  setupDraftPanelControls();
  
  // Setup status indicator draggable
  setupStatusIndicatorDraggable();
}

function setupDraftPanelControls() {
  const draftHeader = document.getElementById('draft-header');
  const minimizeBtn = document.getElementById('minimize-draft');
  const closeBtn = document.getElementById('close-draft');
  
  console.log('✋ Setup draft panel: header=', draftHeader, 'minimize=', minimizeBtn, 'close=', closeBtn);
  
  // Arrastar
  draftHeader.addEventListener('mousedown', (e) => {
    console.log('🖱️ Mousedown no draft header');
    dragDraftStart(e);
  });
  document.addEventListener('mousemove', dragDraft);
  document.addEventListener('mouseup', dragDraftEnd);
  
  // Minimizar
  minimizeBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    draftPanel.classList.toggle('minimized');
    minimizeBtn.textContent = draftPanel.classList.contains('minimized') ? '+' : '−';
    console.log('📦 Draft minimizado:', draftPanel.classList.contains('minimized'));
  });
  
  // Fechar
  closeBtn.addEventListener('click', (e) => {
    e.stopPropagation();
    hideDraftPanel();
    console.log('❌ Draft fechado');
  });
}

function dragDraftStart(e) {
  if (e.target.closest('.minimize-btn') || e.target.closest('.close-btn')) return;
  
  draftInitialX = e.clientX - draftXOffset;
  draftInitialY = e.clientY - draftYOffset;
  
  isDraggingDraft = true;
}

function dragDraft(e) {
  if (!isDraggingDraft) return;
  
  e.preventDefault();
  
  draftCurrentX = e.clientX - draftInitialX;
  draftCurrentY = e.clientY - draftInitialY;
  
  draftXOffset = draftCurrentX;
  draftYOffset = draftCurrentY;
  
  draftPanel.style.transform = `translate3d(${draftCurrentX}px, ${draftCurrentY}px, 0)`;
}

function dragDraftEnd(e) {
  draftInitialX = draftCurrentX;
  draftInitialY = draftCurrentY;
  isDraggingDraft = false;
}

function setupStatusIndicatorDraggable() {
  statusIndicator.addEventListener('mousedown', dragStatusStart);
  document.addEventListener('mousemove', dragStatus);
  document.addEventListener('mouseup', dragStatusEnd);
}

function dragStatusStart(e) {
  statusInitialX = e.clientX - statusXOffset;
  statusInitialY = e.clientY - statusYOffset;
  isDraggingStatus = true;
  statusIndicator.style.cursor = 'grabbing';
}

function dragStatus(e) {
  if (!isDraggingStatus) return;
  
  e.preventDefault();
  
  statusCurrentX = e.clientX - statusInitialX;
  statusCurrentY = e.clientY - statusInitialY;
  
  statusXOffset = statusCurrentX;
  statusYOffset = statusCurrentY;
  
  statusIndicator.style.transform = `translate3d(${statusCurrentX}px, ${statusCurrentY}px, 0)`;
}

function dragStatusEnd(e) {
  statusInitialX = statusCurrentX;
  statusInitialY = statusCurrentY;
  isDraggingStatus = false;
  statusIndicator.style.cursor = 'grab';
}

// Inicia quando a página carregar
window.addEventListener('DOMContentLoaded', init);
