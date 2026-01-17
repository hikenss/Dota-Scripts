const axios = require('axios');

const sampleDraft = {
  provider: { name: 'Dota 2', appid: 570 },
  map: {
    name: 'dota',
    game_state: 'DOTA_GAMERULES_STATE_HERO_SELECTION',
    radiant_gold_adv: 700,
    dire_gold_adv: -300,
    radiant_xp_adv: 900,
    dire_xp_adv: -500
  },
  hero: { name: 'npc_dota_hero_crystal_maiden' },
  player: { team_id: 2 },
  draft: {
    team2_pick0: { id: 1 },
    team2_pick1: { id: 2 },
    team2_pick2: { id: 3 },
    team2_pick3: { id: 4 },
    team2_pick4: { id: 5 },
    team3_pick0: { id: 6 },
    team3_pick1: { id: 7 },
    team3_pick2: { id: 8 },
    team3_pick3: { id: 9 },
    team3_pick4: { id: 10 }
  }
};

async function sendMock() {
  try {
    const response = await axios.post('http://localhost:3000/gsi', sampleDraft);
    console.log('Mock GSI enviado, status', response.status);
  } catch (error) {
    console.error('Erro ao enviar mock GSI', error.message);
  }
}

sendMock();
