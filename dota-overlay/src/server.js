const express = require('express');
const WebSocket = require('ws');
const axios = require('axios');
const aiAnalyzer = require('./ai-analyzer');
require('dotenv').config();

const app = express();
const PORT = 3000;
const WS_PORT = 3001;

let server;
let wss;
let currentGameState = null;

// Middleware
app.use(express.json());

// Rota para receber dados do GSI do Dota 2
app.post('/gsi', (req, res) => {
  const gameState = req.body;
  currentGameState = gameState;
  
  // Log mais detalhado
  const logData = {
    provider: gameState.provider,
    map: gameState.map?.game_state,
    hero: gameState.hero?.name,
    draft: gameState.draft ? 'Draft data available' : 'No draft'
  };
  
  console.log('GSI Update:', logData);
  
  // Log draft completo apenas quando houver objeto de draft
  if (gameState.draft && typeof gameState.draft === 'object' && Object.keys(gameState.draft).length > 0) {
    console.log('📋 DRAFT DATA COMPLETO:', JSON.stringify(gameState.draft, null, 2));
  }
  
  // Log de tudo que chegou
  console.log('🔍 GameState keys:', Object.keys(gameState));

  // Envia para todos os clientes WebSocket conectados
  if (wss) {
    wss.clients.forEach(client => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify({
          type: 'gsi_update',
          data: gameState
        }));
      }
    });
  }

  res.sendStatus(200);
});

// Rota para buscar estatísticas do OpenDota
app.get('/api/hero-stats/:heroId', async (req, res) => {
  try {
    const { heroId } = req.params;
    const apiKey = process.env.OPENDOTA_API_KEY;
    const response = await axios.get(
      `https://api.opendota.com/api/heroes/${heroId}/matchups?api_key=${apiKey}`
    );
    res.json(response.data);
  } catch (error) {
    console.error('Erro ao buscar stats:', error);
    res.status(500).json({ error: 'Erro ao buscar estatísticas' });
  }
});

// Rota para buscar heróis
app.get('/api/heroes', async (req, res) => {
  try {
    const apiKey = process.env.OPENDOTA_API_KEY;
    const response = await axios.get(`https://api.opendota.com/api/heroes?api_key=${apiKey}`);
    res.json(response.data);
  } catch (error) {
    console.error('Erro ao buscar heróis:', error);
    res.status(500).json({ error: 'Erro ao buscar heróis' });
  }
});

// Rota para análise de draft com IA
app.post('/api/analyze-draft', async (req, res) => {
  try {
    const { radiantHeroes, direHeroes } = req.body;
    const analysis = await aiAnalyzer.analyzeDraft(radiantHeroes, direHeroes);
    res.json(analysis);
  } catch (error) {
    console.error('Erro ao analisar draft:', error);
    res.status(500).json({ error: 'Erro ao analisar draft' });
  }
});

// Rota para análise de matchup
app.get('/api/matchup/:hero1/:hero2', async (req, res) => {
  try {
    const { hero1, hero2 } = req.params;
    const analysis = await aiAnalyzer.analyzeMatchup(hero1, hero2);
    res.json({ analysis });
  } catch (error) {
    console.error('Erro ao analisar matchup:', error);
    res.status(500).json({ error: 'Erro ao analisar matchup' });
  }
});

function start() {
  // Inicia servidor HTTP
  server = app.listen(PORT, () => {
    console.log(`✅ Servidor GSI rodando na porta ${PORT}`);
    console.log(`📡 Aguardando dados do Dota 2...`);
  });

  // Inicia servidor WebSocket
  wss = new WebSocket.Server({ port: WS_PORT });
  
  wss.on('connection', (ws) => {
    console.log('🔌 Cliente conectado ao WebSocket');
    
    // Envia estado atual se existir
    if (currentGameState) {
      ws.send(JSON.stringify({
        type: 'initial_state',
        data: currentGameState
      }));
    }

    ws.on('close', () => {
      console.log('❌ Cliente desconectado');
    });
  });

  console.log(`🌐 WebSocket rodando na porta ${WS_PORT}`);
}

function stop() {
  if (server) {
    server.close();
  }
  if (wss) {
    wss.close();
  }
}

module.exports = { start, stop };

// Se executado diretamente (para desenvolvimento)
if (require.main === module) {
  start();
}
