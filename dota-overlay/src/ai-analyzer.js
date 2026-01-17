const axios = require('axios');
require('dotenv').config();

class AIAnalyzer {
  constructor() {
    this.groqApiKey = process.env.GROQ_API_KEY;
    this.baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  }

  async analyzeDraft(radiantHeroes, direHeroes) {
    if (!this.groqApiKey || this.groqApiKey === 'seu_key_aqui_quando_criar') {
      return this.getMockAnalysis(radiantHeroes, direHeroes);
    }

    try {
      const prompt = `Você é um analista profissional de Dota 2. Analise esta composição de draft:

RADIANT: ${radiantHeroes.join(', ')}
DIRE: ${direHeroes.join(', ')}

Forneça uma análise estratégica curta e direta em português brasileiro com:
1. Win condition de cada time (1 linha cada)
2. Principais sinergias (2-3 linhas)
3. Como cada time deve jogar (2-3 linhas)

Seja objetivo e profissional.`;

      const response = await axios.post(
        this.baseUrl,
        {
          model: 'llama-3.1-70b-versatile',
          messages: [
            {
              role: 'system',
              content: 'Você é um analista profissional de Dota 2 especializado em análise de draft.'
            },
            {
              role: 'user',
              content: prompt
            }
          ],
          temperature: 0.7,
          max_tokens: 500
        },
        {
          headers: {
            'Authorization': `Bearer ${this.groqApiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return this.parseAIResponse(response.data.choices[0].message.content);
    } catch (error) {
      console.error('Erro na análise de IA:', error.message);
      return this.getMockAnalysis(radiantHeroes, direHeroes);
    }
  }

  parseAIResponse(content) {
    // Extrai informações da resposta da IA
    return {
      radiantStrategy: this.extractSection(content, 'RADIANT'),
      direStrategy: this.extractSection(content, 'DIRE'),
      connections: this.extractSection(content, 'sinergias|conexões'),
      concept: content.substring(0, 300) // Primeiras linhas como conceito geral
    };
  }

  extractSection(content, keyword) {
    const regex = new RegExp(`${keyword}[:\\s]+(.*?)(?=\\n\\n|DIRE|$)`, 'is');
    const match = content.match(regex);
    return match ? match[1].trim() : 'Análise em processamento...';
  }

  getMockAnalysis(radiantHeroes, direHeroes) {
    return {
      radiantStrategy: `Vitória via ganhos de smoke e visão com ${radiantHeroes[0] || 'suporte'}, proteger carry durante farm.`,
      direStrategy: `Defender torres com heroes tanques, buscar teamfights favoráveis com ${direHeroes[0] || 'iniciador'}.`,
      connections: `${radiantHeroes[0] || 'Team'} pode criar espaço para ${radiantHeroes[1] || 'carry'}. ${direHeroes[0] || 'Team'} deve focar em controle de mapa.`,
      concept: 'Cerco rápido vs. Teamfight controlado. Um time deve buscar objetivos rápidos enquanto o outro defende e espera oportunidades.'
    };
  }

  async analyzeMatchup(hero1, hero2) {
    // Análise de matchup entre 2 heróis
    if (!this.groqApiKey || this.groqApiKey === 'seu_key_aqui_quando_criar') {
      return `${hero1} vs ${hero2}: Matchup equilibrado`;
    }

    try {
      const response = await axios.post(
        this.baseUrl,
        {
          model: 'llama-3.1-70b-versatile',
          messages: [
            {
              role: 'user',
              content: `Em Dota 2, como ${hero1} se sai contra ${hero2}? Responda em 1-2 linhas.`
            }
          ],
          temperature: 0.5,
          max_tokens: 100
        },
        {
          headers: {
            'Authorization': `Bearer ${this.groqApiKey}`,
            'Content-Type': 'application/json'
          }
        }
      );

      return response.data.choices[0].message.content;
    } catch (error) {
      return `Matchup ${hero1} vs ${hero2}`;
    }
  }
}

module.exports = new AIAnalyzer();
