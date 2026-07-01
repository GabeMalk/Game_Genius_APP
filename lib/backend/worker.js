// ============================================================
// CLOUDFLARE WORKER - Proxy seguro para a API da IGDB
//
// Esse worker:
// 1. Recebe pedidos do seu app Flutter (sem nenhum segredo)
// 2. Pede/renova o access_token da Twitch/IGDB usando as
//    variáveis secretas configuradas em Settings > Variables
// 3. Repassa a busca para a IGDB usando a linguagem Apicalypse
// 4. Devolve o JSON pro app
//
// Endpoint de uso: GET /jogos?busca=zelda
// (sem parâmetro "busca" = pega jogos populares aleatórios)
// ============================================================

// Cache do token em memória. Isso funciona porque, enquanto o
// Worker "isolate" estiver ativo (alguns minutos a horas), ele
// reaproveita esse valor em vez de pedir um token novo a cada
// requisição. Se o isolate reiniciar, simplesmente pedimos outro.
let tokenCache = {
  accessToken: null,
  expiraEm: 0, // timestamp em ms
};

async function obterAccessToken(env) {
  const agora = Date.now();

  // Se já temos um token válido (com 60s de margem de segurança),
  // reaproveita em vez de pedir um novo.
  if (tokenCache.accessToken && agora < tokenCache.expiraEm - 60_000) {
    return tokenCache.accessToken;
  }

  const url = `https://id.twitch.tv/oauth2/token?client_id=${env.IGDB_CLIENT_ID}&client_secret=${env.IGDB_CLIENT_SECRET}&grant_type=client_credentials`;

  const resposta = await fetch(url, { method: 'POST' });

  if (!resposta.ok) {
    throw new Error(`Falha ao obter token: ${resposta.status}`);
  }

  const dados = await resposta.json();

  tokenCache = {
    accessToken: dados.access_token,
    expiraEm: agora + dados.expires_in * 1000,
  };

  return tokenCache.accessToken;
}

// Monta a query Apicalypse. Pedimos só os campos que o app usa,
// pra resposta vir mais leve e rápida.
function montarQuery({ busca, limite }) {
  const campos = [
    'name',
    'summary',
    'cover.url',
    'genres.name',
    'websites.url',
    'rating',
  ].join(',');

  if (busca) {
    return `search "${busca}"; fields ${campos}; limit ${limite};`;
  }

  // Sem busca: pega jogos bem avaliados, ordenados por rating,
  // como uma lista "geral" pra sortear localmente.
  return `fields ${campos}; sort rating desc; where rating != null; limit ${limite};`;
}

async function buscarJogosIGDB(env, params) {
  const token = await obterAccessToken(env);

  const resposta = await fetch('https://api.igdb.com/v4/games', {
    method: 'POST',
    headers: {
      'Client-ID': env.IGDB_CLIENT_ID,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'text/plain',
    },
    body: montarQuery(params),
  });

  if (!resposta.ok) {
    const textoErro = await resposta.text();
    throw new Error(`Erro IGDB ${resposta.status}: ${textoErro}`);
  }

  return resposta.json();
}

// Cabeçalhos CORS — necessário para o app conseguir chamar esse
// Worker de fora (Flutter web) ou para testes via navegador.
// Em app mobile nativo (Android/iOS) isso nem é checado, mas
// não tem custo manter por segurança/flexibilidade futura.
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

export default {
  async fetch(request, env, ctx) {
    // Requisições "preflight" do navegador (CORS)
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);

    if (url.pathname === '/count') {
      try {
        const token = await obterAccessToken(env);
        
        const hoje = Math.floor(Date.now() / 1000);
        
        // CORREÇÃO APLICADA AQUI: game_type = 0 no lugar do erro anterior
        // Filtro: RPG (12), PC (6), Jogo Base, Pós-2015, Até Hoje, Mínimo 5 votos.
        const regrasDeFiltro = `genres = (12) & platforms = (6) & game_type = 0 & first_release_date > 1420070400 & first_release_date <= ${hoje} & rating_count >= 5`;

        // 1. Pega o número total de jogos que passaram no filtro
        const respostaCount = await fetch('https://api.igdb.com/v4/games/count', {
          method: 'POST',
          headers: {
            'Client-ID': env.IGDB_CLIENT_ID,
            'Authorization': `Bearer ${token}`, 
            'Content-Type': 'text/plain',
          },
          body: `where ${regrasDeFiltro};`,
        });
        const dadosCount = await respostaCount.json();

        // ==========================================
        // 2. A MÁGICA DOS 1000 JOGOS (PAGINAÇÃO)
        // ==========================================
        const headersIGDB = {
          'Client-ID': env.IGDB_CLIENT_ID,
          'Authorization': `Bearer ${token}`, 
          'Content-Type': 'text/plain',
        };

        // Pedido 1: Traz os jogos do 1 ao 500 (offset 0)
        const queryPagina1 = `fields name, rating, rating_count; where ${regrasDeFiltro}; sort rating_count desc; limit 500; offset 0;`;
        const fetchPagina1 = fetch('https://api.igdb.com/v4/games', { method: 'POST', headers: headersIGDB, body: queryPagina1 });

        // Pedido 2: Traz os jogos do 501 ao 1000 (offset 500)
        const queryPagina2 = `fields name, rating, rating_count; where ${regrasDeFiltro}; sort rating_count desc; limit 500; offset 500;`;
        const fetchPagina2 = fetch('https://api.igdb.com/v4/games', { method: 'POST', headers: headersIGDB, body: queryPagina2 });

        // Dispara as duas buscas na IGDB ao mesmo tempo
        const [res1, res2] = await Promise.all([fetchPagina1, fetchPagina2]);
        
        const dados1 = await res1.json();
        const dados2 = await res2.json();

        // Junta as duas listas numa só
        const dadosJogos = [...dados1, ...dados2];

        // 3. Monta o texto para a tela
        const listaDeNomes = dadosJogos.map((jogo, index) => {
          const nota = jogo.rating ? Math.round(jogo.rating) : 'N/A';
          const votos = jogo.rating_count ? jogo.rating_count : 0;
          return `${index + 1}. ${jogo.name} (Nota: ${nota} | Votos: ${votos})`;
        }).join('\n');
        
        const textoDaTela = `TOTAL GERAL DE RPGs NO BANCO: ${dadosCount.count}\n` +
                            `MOSTRANDO TOP ${dadosJogos.length} JOGOS (Ordenados por popularidade e filtrados por game_type):\n` +
                            `--------------------------------------------------------\n\n` +
                            `${listaDeNomes}`;

        return new Response(textoDaTela, {
          headers: { 'Content-Type': 'text/plain; charset=utf-8', ...corsHeaders }
        });
      } catch (erro) {
        return new Response(JSON.stringify({ erro: erro.message }), {
          status: 500,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }
    }

    // ============================================================
    // ENDPOINT TEMPORÁRIO DE EXPLORAÇÃO
    // Uso: /explorar/themes  ou  /explorar/genres
    //      /explorar/platforms  ou /explorar/platform_families
    // Lista os valores reais que existem na IGDB para aquele
    // recurso — assim a gente não fica adivinhando enum por aí.
    // Pode remover esse bloco depois de mapear tudo que precisa.
    // ============================================================
    if (url.pathname.startsWith('/explorar/')) {
      const recurso = url.pathname.replace('/explorar/', '');
      const recursosPermitidos = [
        'themes', 'genres', 'platforms', 'platform_families', 'keywords',
        'game_types','game_modes', 'age_rating_categories', 'age_ratings','player_perspectives'
      ];

      if (!recursosPermitidos.includes(recurso)) {
        return new Response(
          JSON.stringify({ erro: `Use um destes: ${recursosPermitidos.join(', ')}` }),
          { status: 400, headers: { 'Content-Type': 'application/json', ...corsHeaders } }
        );
      }

      try {
        const token = await obterAccessToken(env);
        const queryApicalypse = recurso === 'game_types' 
          ? 'fields *; limit 500;' 
          : 'fields name; sort name asc; limit 500;';
        const resposta = await fetch(`https://api.igdb.com/v4/${recurso}`, {
          method: 'POST',
          headers: {
            'Client-ID': env.IGDB_CLIENT_ID,
            Authorization: `Bearer ${token}`,
            'Content-Type': 'text/plain',
          },
          body: queryApicalypse, // <--- Ajustado aqui
        });
        const dados = await resposta.json();
        return new Response(JSON.stringify(dados, null, 2), {
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      } catch (erro) {
        return new Response(JSON.stringify({ erro: erro.message }), {
          status: 500,
          headers: { 'Content-Type': 'application/json', ...corsHeaders },
        });
      }
    }

    if (url.pathname !== '/jogos') {
      return new Response('Não encontrado. Use /jogos', {
        status: 404,
        headers: corsHeaders,
      });
    }

    try {
      const busca = url.searchParams.get('busca') ?? null;
      const limite = url.searchParams.get('limite') ?? '20';

      const jogos = await buscarJogosIGDB(env, { busca, limite });

      return new Response(JSON.stringify(jogos), {
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders,
        },
      });
    } catch (erro) {
      return new Response(
        JSON.stringify({ erro: erro.message }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            ...corsHeaders,
          },
        }
      );
    }
  },
};
