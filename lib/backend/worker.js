// ============================================================
// CLOUDFLARE WORKER - Proxy + motor de recomendação sobre a IGDB

// Endpoint: POST /jogos

// Body (JSON):
// {
//   "plataforma": 6,                    // OBRIGATÓRIO
//   "filtros": ["rpg", "estrategia"],   // opcional — chaves do catálogo
//   "filtrosNegativos": ["anime"]       // opcional — chaves do catálogo a excluir
//   "modoJogo": "single",               // opcional — "single" | "multi"
//   "eras": ["atualidade"],             // opcional - filtros de data de lançamento
//   "historicoIds": [1022, 341705]      // opcional — blacklist dos últimos jogos sorteados
// }

// Resposta: UM jogo (objeto JSON) já sorteado pelo Worker, ou
// { "erro": "..." } com status 404 se nada bater com os filtros.
// ============================================================

// ============================================================

// ============================================================
// CONSTANTES
// ============================================================

// --- CORS ---
// Headers que serão incluídos em todas as respostas para permitir
// que o frontend possa chamar o worker, coisa padrão

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, X-App-Secret',};

// --- Catálogo ---
// Catálogo de filtros: chave -> quais ids ela representa
// "basico: true" = usado também no sorteio secreto de filtro quando nada foi selecionado

const FILTROS_CATALOGO = {
  // ---- básicos ----
  rpg:               { basico: true, generos: [12] },
  aventura:          { basico: true, generos: [31] },
  acao:              { basico: true, generos: [25], temas: [1] },
  plataforma_genero: { basico: true, generos: [8] },
  estrategia:        { basico: true, generos: [15, 24, 16], temas: [41] },
  tiro:              { basico: true, generos: [5] },
  luta:              { basico: true, generos: [4] },
  simulacao_trabalho:{ basico: true, generos: [13], temas: [28] },
  visual_novel:      { basico: true, generos: [34] },
  esportes_corrida:  { basico: true, generos: [10, 14, 30] },
  quebra_cabeca:     { basico: true, generos: [9] },
  cartas_tabuleiro:  { basico: true, generos: [35] },
  terror_suspense:   { basico: true, temas: [19, 20] },

  // ---- avançados ----
  roguelike:         { keywords: [17292, 416, 27419, 41781] },
  primeira_pessoa:   { perspectivas: [1] },
  indie:             { generos: [32] },
  point_and_click:   { generos: [2] },
  mundo_aberto:      { temas: [38] },
  drama_misterio:    { temas: [31, 43] },
  sandbox:           { temas: [33] },
  sobrevivencia:     { temas: [21] },
  furtividade:       { temas: [23] },
  fantasia_medieval: { temas: [17], keywords: [151] },
  ficcao_cientifica: { temas: [18] },
  musica:            { generos: [7] },
  rts:               { generos: [11] },
  jogo_de_festa:     { temas: [40] },
  engracado:         { temas: [27] },
  romance:           { temas: [44] },
  anime:             { keywords: [78] },
  erotic:            { temas: [42] },
};

// --- Filtros básicos ---
// Dicionario dos filtros basicos criado a partir do dicionario maior.
// O filter é basicamente um for loop que retorna tudo que for
// "verdadeirin" na propriedade especificada. Nesse caso, o "basico".
const CHAVES_BASICAS = Object.keys(FILTROS_CATALOGO).filter((key) => FILTROS_CATALOGO[key].basico);

// --- Campos ---
// Definimos os campos que vamos pedir ao IGDB (Apicalypse) e juntamos eles com virgula
const CAMPOS = [
  'name',
  'summary',
  'cover.url',
  'genres.id',
  'genres.name',
  'themes.id',
  'themes.name',
  'keywords.id',
  'player_perspectives.id',
  'player_perspectives.name',
  'websites.url',
  'rating',
  'rating_count',
].join(',');

// --- Erro ---
// Espero que nunca seja usado rs
class ErroValidacao extends Error {}

// ============================================================
// ORQUESTRADOR
// Essa função é o coração do que esse código faz,
// ela orquestra, organiza e executada como os filtros serão usados
// para chegar em um jogo adequado do IGDB
// ============================================================

async function buscarRecomendacao(env, corpo) {
  // "corpo" é o objeto JSON recebido na requisição (ex: corpo.plataforma, corpo.filtros, etc.)
  const plataforma = INTorNULL(corpo.plataforma);

  // --- VALIDAÇÃO E NORMALIZAÇÃO DAS ENTRADAS ---
  // Cada campo é passado por uma função de segurança,
  // se vier algo inválido, elas retornam arrays vazios, null ou valores padrão.

  if (plataforma === null) { throw new ErroValidacao('O campo "plataforma" é obrigatório (número inteiro).'); }

  const eras = ChecarEras(corpo.eras);
  let filtrosNegativos = ChecarFiltrosValidos(corpo.filtrosNegativos);
  const modoJogo = GMorNULL(corpo.modoJogo);
  const historicoIds = listaINT(corpo.historicoIds, 50); // blacklist, até 50

  let filtros = ChecarFiltrosValidos(corpo.filtros);

  // Se o usuário não passou nenhum filtro, escolhemos um filtro básico aleatório
  if (filtros.length === 0) {
  const candidatosValidos = CHAVES_BASICAS.filter((chave) => !filtrosNegativos.includes(chave));

  if (candidatosValidos.length > 0) {
    filtros = [Aleatorio(candidatosValidos)];
  } else {
    // Se os 13 básicos estão TODOS marcados como negativo —
    // Escolhe um qualquer e remove SÓ ELE da lista de negativos
    const escolhido = FiltroBasicoAleatorio();
    filtros = [escolhido];
    filtrosNegativos = filtrosNegativos.filter((chave) => chave !== escolhido);
  }
}
  
// Agrupamos os parâmetros que serão usados nas queries.
  const baseParams = { plataforma, eras, filtrosNegativos, modoJogo, historicoIds };

  // ---------------- BRANCH 1: 1 a 3 filtros (match estrito) ----------------
  // A primeira abordagem é tenta achar jogos que satisfaçam TODOS os filtros.
  // Começa exigindo qualidade, se não achar, remove a exigência.
  // Se ainda assim não achar, cai para o Branch 2 (OR).

  if (filtros.length <= 3) {
    const pagina1 = await buscarPagina(
      env,
      montarQuery({ baseParams, filtros, modo: 'AND', comQualidade: true, offset: 0 }),);
    // Se a primeira página veio cheia, buscamos a segunda página para aumentar a variedade.
    if (pagina1.length === 500) {
      const pagina2 = await buscarPagina(env,
        montarQuery({ baseParams, filtros, modo: 'AND', comQualidade: true, offset: 500 }),);
      // Concatena as duas páginas e escolhe um jogo aleatório dentre todos.
      // Isso é o caso ideal, muitos resultados com qualidade.
      return Aleatorio(pagina1.concat(pagina2));} // 1.1

    // Se a página1 tiver entre 1 e 499 jogos, escolhe um aleatório dela.
    if (pagina1.length >= 1) {
        // Aqui são resultados com qualidade, mas menos diversos.
      return Aleatorio(pagina1);} // 1.2

    // Se não achou nada com qualidade, fallback sem restrições de qualidade.
    const semQualidade = await buscarPagina(env,
      montarQuery({ baseParams, filtros, modo: 'AND', comQualidade: false, offset: 0 }),);
    if (semQualidade.length >= 1) {
      return Aleatorio(semQualidade);} // 1.3 sucesso
     
    // 1.3.1 : se falhar, cai pro Branch 2 abaixo.
  }

  // ---------------- BRANCH 2: >3 filtros, ou Branch 1 esgotado ----------------
  // Esse é modo "OR", basta atender a qualquer um dos filtros que é selecionado
  // Depois aplica um pós-filtro local (MatchMinimo) para garantir que o jogo
  // atenda a pelo menos 2 dos filtros selecionados.

  // Primeira tentativa: OR com qualidade.
  const pagina1b2 = await buscarPagina(env,
    montarQuery({ baseParams, filtros, modo: 'OR', comQualidade: true, offset: 0 }) );
  // Mesma lógica do branch 1, se der uma pagina cheia, pede a proxima
  if (pagina1b2.length === 500) {
    const pagina2b2 = await buscarPagina(env,
      montarQuery({ baseParams, filtros, modo: 'OR', comQualidade: true, offset: 500 }),);
    //Une as duas páginas e aplica o filtro de pelo menos 2 matches.
    return MatchMinimo(pagina1b2.concat(pagina2b2), filtros, 2);} // 2.1

  // Mesma lógica, entre 1 e 499, pega um jogo, mas agora aplica o match minimo
  if (pagina1b2.length >= 1)
    { return MatchMinimo(pagina1b2, filtros, 2);} // 2.2

  // Mesma lógica, sem qualidade, matchminimo.
  const semQualidadeB2 = await buscarPagina(env,
    montarQuery({ baseParams, filtros, modo: 'OR', comQualidade: false, offset: 0 }),);
  if (semQualidadeB2.length >= 1) {
    return MatchMinimo(semQualidadeB2, filtros, 2);} // 2.3 sucesso

  return null; // 2.3.1: Tudo falhou, por algum motivo NENHUM jogo foi encontrado
}

// ============================================================
// MONTAGEM E ENVIO
// Aqui que o querry vai ser montado com as condições para a busca
// ============================================================

// --- Querry ---
function montarQuery({ baseParams, filtros, modo, comQualidade, offset }) {
  // Sobre ({}) "desestruturar" e ({...}) "espalhar":
  // Essa função cria um novo objeto "espalhando" todas as propriedades de baseParams
  // e sobrescreve a propriedade comQualidade (boolean).
  // Esse novo objeto é passado para condicoesBase, que o desestrutura
  // para obter cada parâmetro pelo nome (plataforma, eras, etc.).
  const condicoes = condicoesBase({ ...baseParams, comQualidade });

  // Dependendo do modo, adiciona os filtros do catálogo como AND ou OR.
  if (modo === 'AND') {
    condicoes.push(...FiltrosAND(filtros));}
    else {
    condicoes.push(FiltrosOR(filtros));}

  // Junta todas as condições com " & "  para formar a string "where" que será mandanda ao IGDB.
  const condicoes_where = condicoes.join(' & ');
  return `fields ${CAMPOS}; where ${condicoes_where}; sort rating_count desc; limit 500; offset ${offset};`;}

// --- Condições básicas ---
// Entra aqui um array "desestruturado" : "{}", e ai de cada pedacinho montamos um array das condições base
function condicoesBase({
  plataforma,        // ID da plataforma (ex: 6 para PC)
  eras,              // array de chaves de eras (ex: ['modernos', 'atualidade'])
  filtrosNegativos,  // array de filtros a serem excluídos
  modoJogo,          // 'single', 'multi' ou null
  historicoIds,      // array de IDs de jogos já mostrados (para não repetir)
  comQualidade,      // booleano: se true, exige nota e número mínimo de avaliações
}) {
  // Inicializamos o array de condições com o filtro mais básico e sempre ativo: Buscar "main_games", não DLCs e afins
  const condicoes = ['game_type = 0'];

  // Se o parâmetro comQualidade for true, adiciona condições de qualidade:
  // - Pelo menos 5 avaliações (rating_count)
  // - Nota média >= 40
  if (comQualidade) {
    condicoes.push('rating_count >= 5', 'rating >= 40');}

  // Adiciona a plataforma, por ex: PC plataforms = (6)
  condicoes.push(`platforms = (${plataforma})`);

  // Exclusão de filtros negativos
  if (filtrosNegativos.length > 0) {
    condicoes.push(...FiltrosNegativos(filtrosNegativos));}

  // Filtro do modo de jogo:
  // - 'single': apenas single player (game_modes = 1)
  // - 'multi': apenas modos multiplayer (IDs 2,3,5,6 cobrem vários tipos)
  if (modoJogo === 'single') {
    condicoes.push('game_modes = (1)');}
  else if (modoJogo === 'multi') {
    condicoes.push('game_modes = (2,3,5,6)');}
 // Se for null ou outro valor, não adiciona condição de modo.

  // Exclusão de IDs já vistos (histórico): se a lista tiver IDs,
  // adiciona condição para que o jogo NÃO esteja entre esses IDs.
  if (historicoIds.length > 0) {
    condicoes.push(`id != (${historicoIds.join(',')})`);}

  // Filtro por eras, faz uma montagem ai de começo e fim a partir do calculo das eras... Aqui pedi ajuda, fui preguiçoso
  if (eras.length > 0) {
    const erasCalc = calcularEras();
    const partes = eras.map((chave) => {
      const { inicio, fim } = erasCalc[chave];
      return inicio === null
        ? `first_release_date <= ${fim}`
        : `(first_release_date >= ${inicio} & first_release_date <= ${fim})`;});
    condicoes.push(`(${partes.join(' | ')})`);}

  // O que retorna é um array em Apicalypse com as condições que vão montar a query
  return condicoes
}

// --- Busca ---
// Essa função recebe o texto da query (Apicalypse) e a envia
// para a API v4/games, retornando a resposta em JSON.
async function buscarPagina(env, queryTexto) {
  // Pede o token de acesso
  const token = await obterAccessToken(env);
  // Faz a requisição
  const resposta = await fetch('https://api.igdb.com/v4/games', {
    method: 'POST',
    headers: {
      'Client-ID': env.IGDB_CLIENT_ID,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'text/plain',
    },
    // Aqui é a querry completa que o operador vai mandar como string
    body: queryTexto,
  });
  if (!resposta.ok) {
    const textoErro = await resposta.text();
    throw new Error(`Erro IGDB ${resposta.status}: ${textoErro}`);
  }
  return resposta.json();
}

// ============================================================
// MATCH LOCAL
// Verifica se um jogo satisfaz um filtro e conta quantos
// dos filtros selecionados ele satisfaz no total.
// ============================================================

// Função principal
function MatchMinimo(jogos, filtros, minimo) {
  // Filtra os jogos que passam no critério mínimo de filtros satisfeitos.
  const comMatchSuficiente = jogos.filter((j) => contarFiltrosOK(j, filtros) >= minimo);
  // Se existir pelo menos um jogo que atinja o mínimo, escolhe aleatoriamente entre eles.
  // Senão, faz fallback: escolhe aleatoriamente entre todos os jogos recebidos.
  return comMatchSuficiente.length > 0
    ? Aleatorio(comMatchSuficiente)
    : Aleatorio(jogos);
}

function contarFiltrosOK(jogo, filtros) {
  // Converte o array de objetos da IGDB em sets com apenas os IDs, o que é mais eficiente.
  // O operador ?? garante que, se a propriedade for null ou undefined,
  // usamos um array vazio no lugar, evitando erro ao chamar .map.
  const idsPorCampo = {
    genero: new Set((jogo.genres ?? []).map((g) => g.id)),
    tema: new Set((jogo.themes ?? []).map((t) => t.id)),
    keyword: new Set((jogo.keywords ?? []).map((k) => k.id)),
    perspectiva: new Set((jogo.player_perspectives ?? []).map((p) => p.id)),
  };
  // Retorna a contagem de quantos filtros aquele jogo satisfez (.length)
  return filtros.filter((f) => filtroBool(idsPorCampo, f)).length;
}

// Diz se a presença de um filtro é true ou false
function filtroBool(idsPorCampo, filtro) {
  const def = FILTROS_CATALOGO[filtro];
  if (!def) return false; // Nunca deve acontecer
  // Testa cada grupo do filtro: se PELO MENOS UM dos IDs do grupo
  // estiver presente nos IDs do jogo, retorna true imediatamente.
  // O método .some() retorna true se algum elemento do array satisfaz a condição.
  if (def.generos?.some((id) => idsPorCampo.genero.has(id))) return true;
  if (def.temas?.some((id) => idsPorCampo.tema.has(id))) return true;
  if (def.keywords?.some((id) => idsPorCampo.keyword.has(id))) return true;
  if (def.perspectivas?.some((id) => idsPorCampo.perspectiva.has(id))) return true;
  return false;
}

// ============================================================
// TRADUÇÃO E CÁLCULO
// Funções para traduzir os filtros em linguagem
// Apicalypse para ser enviado à API
// ============================================================

// Transforma uma chave de filtro em uma condição Apicalypse. Entra "RPG" e sai "(genres = (12) | themes = (1))".
function extrairPartes(chave, operador) {
  const def = FILTROS_CATALOGO[chave];
  if (!def) return null; // nunca deveria acontecer (já validado antes)

  const partes = [];
  // Para cada grupo, se houver IDs, monta algo como "genres = (12,31)" ou "genres != (12,31)"
  // O operador ?. acessa a propriedade apenas se existir, e .length verifica se o array não está vazio.
  if (def.generos?.length)       partes.push(`genres ${operador} (${def.generos.join(',')})`);
  if (def.temas?.length)         partes.push(`themes ${operador} (${def.temas.join(',')})`);
  if (def.keywords?.length)      partes.push(`keywords ${operador} (${def.keywords.join(',')})`);
  if (def.perspectivas?.length)  partes.push(`player_perspectives ${operador} (${def.perspectivas.join(',')})`);

  return partes; // pode ser vazio []
}

// Tradutor para condição POSITIVA
function TradutorFiltros(chave) {
  const partes = extrairPartes(chave, '=');
  if (!partes || partes.length === 0) return null; // Isso aqui nunca deveria acontecer
  // Retorna as partes, se for maior que 1, une com | e ()
  return partes.length > 1 ? `(${partes.join(' | ')})` : partes[0]; 
}
  
// Tradutor para condição NEGATIVA
// A diferença é que ao invés de unir as coisas com OR
// une as coisas com &, seguindo a lei de Morgan
// Isso da um certo nó na cabeça, mas faz sentido
function TradutorFiltroNegativo(chave) {
  const partes = extrairPartes(chave, '!=');
  if (!partes || partes.length === 0) return null;
  // Junta as partes com " & ". Basta um lado ser falso para o jogo ser removido.
  return partes.join(' & ');
}

// Branch 1: Recebe o array de filtros como strings, traduz para Apicalypse e retorna como array.
function FiltrosAND(chaves) {
  // O map chama o tradutor de filtros para cada chave, gerando um array de strings.
  // Esse filter(Boolean) remove os valores falsy, mantendo só as strings válidas, mas nunca deve acontecer.
  return chaves.map(TradutorFiltros).filter(Boolean);
}

// Branch 2: Recebe, traduz, e retorna como uma string.
function FiltrosOR(chaves) {
  // Igual anterior
  const partes = chaves.map(TradutorFiltros).filter(Boolean);
  // Retorna uma string com | (ou seja, OR)
  return `(${partes.join(' | ')})`;
}

// Manda o recebido para o tradutor espécifico do negativo
function FiltrosNegativos(chaves) {
  return chaves.map(TradutorFiltroNegativo).filter(Boolean);
}

// Calcula as eras em timestamps Unix
function calcularEras() {
  // Obtém o timestamp atual em segundos (Date.now() retorna milissegundos)
  const hoje = Math.floor(Date.now() / 1000);
  // Calcula o início de um mês no passado... matematica e tals.
  const inicioDoMes = (mesesAtras) => {
    const agora = new Date();
    const data = new Date(Date.UTC(agora.getUTCFullYear(), agora.getUTCMonth() - mesesAtras, 1, 0, 0, 0));
    return Math.floor(data.getTime() / 1000);
  };
  // Aqui são datas fixas
  const inicio2002 = Math.floor(Date.UTC(2002, 0, 1) / 1000);
  const inicio2014 = Math.floor(Date.UTC(2014, 0, 1) / 1000);
  const inicio2020 = Math.floor(Date.UTC(2020, 0, 1) / 1000);
  // Retorna as eras e seus UNIXs
  return {
    lancamentos: { inicio: inicioDoMes(2), fim: hoje },
    atualidade: { inicio: inicio2020, fim: hoje },
    modernos: { inicio: inicio2014, fim: inicio2020 - 1 },
    old_school: { inicio: inicio2002, fim: inicio2014 - 1 },
    classicos: { inicio: null, fim: inicio2002 - 1 },
  };
}


// ============================================================
// VALIDAÇÃO E SEGURANÇA
// Funções para garatir que nada vai dar merda
// ============================================================

// Transforma qualquer valor em um array seguro de números inteiros.
// Se não for um array, retorna array vazio.
// Filtra apenas os elementos que são inteiros e limita o tamanho a max (padrão 30).
function listaINT(valor, max = 30) {
  if (!Array.isArray(valor)) return [];
  return valor.filter((v) => Number.isInteger(v)).slice(0, max);
}

// Se o valor for um número inteiro, retorna ele. Senão, retorna null.
function INTorNULL(valor) {
  return Number.isInteger(valor) ? valor : null;
}

// Whitelist fechada: só aceita chaves que existem no catálogo.
// Qualquer string desconhecida é descartada silenciosamente.
function ChecarFiltrosValidos(valor) {
  if (!Array.isArray(valor)) return [];
  return valor
    .filter((v) => typeof v === 'string' && FILTROS_CATALOGO[v] !== undefined)
    .slice(0, 30);
}

// Aceita apenas as strings 'single' ou 'multi', retornando a própria string.
// Qualquer outro valor retorna null.
function GMorNULL(valor) {
  return valor === 'single' || valor === 'multi' ? valor : null;
}

// Valida um valor como array de strings com nomes de eras válidas.
// Descarta qualquer string que não seja uma era reconhecida.
function ChecarEras(valor) {
  const validas = ['lancamentos', 'atualidade', 'modernos', 'old_school', 'classicos'];
  if (!Array.isArray(valor)) return [];
  return valor.filter((v) => typeof v === 'string' && validas.includes(v));
}

// ============================================================
// UTILITÁRIOS
// ============================================================

// Escolhe aleatoriamente um filtro que está marcado como "basico" no catálogo.
function FiltroBasicoAleatorio() {
  return CHAVES_BASICAS[Math.floor(Math.random() * CHAVES_BASICAS.length)];
}

// Escolhe um elemento aleatório de qualquer array.
function Aleatorio(lista) {
  return lista[Math.floor(Math.random() * lista.length)];
}

// Função pra melhorar a imagem do jogo
function melhorarImagemDoJogo(jogo) {
  // Se não existir cover ou a URL da capa estiver ausente, retorna o objeto original.
  if (!jogo.cover?.url) return jogo;
  // Cria um novo objeto jogo, mantendo todas as propriedades originais,
  // mas substituindo o objeto cover por uma versão com a URL melhorada.
  return {
    ...jogo,
    cover: {
      ...jogo.cover,
      url: jogo.cover.url.replace('t_thumb', 't_cover_big_2x').replace('//', 'https://'),
    },
  };
}

// ============================================================
// TOKEN
// ============================================================


// Cache em memória para armazenar o token e sua data de expiração.
// Inicialmente sem token (null) e expiração zerada.
let tokenCache = { accessToken: null, expiraEm: 0 };

// Função assíncrona que obtém um access token do IGDB.
// Recebe "env", que é o enviroment do cloudfare worker com minhas variaveis secretas.
async function obterAccessToken(env) {
// Captura o timestamp atual em milissegundos.
  const agora = Date.now();
  // Verifica se o cache é válido:
  //  tokenCache.accessToken existe (não é null/undefined)
  //  E ainda não expirou (com margem de 60 segundos = 60.000 ms)
  if (tokenCache.accessToken && agora < tokenCache.expiraEm - 60_000) {
    // Se válido, retorna o token armazenado sem fazer requisição.
    return tokenCache.accessToken;
  }
  // Monta a URL para obter o token via OAuth. Não sei exatamente como isso funciona, mas funciona.
  const url = `https://id.twitch.tv/oauth2/token?client_id=${env.IGDB_CLIENT_ID}&client_secret=${env.IGDB_CLIENT_SECRET}&grant_type=client_credentials`;
  // Faz a requisição metodo POST (enviar).
  const resposta = await fetch(url, { method: 'POST' });
  // Se a resposta não for bem-sucedida (status ≠ 2xx), lança erro. Os status 2xx indicam que deu certo (diferente de 4xx ou 5xx).
  if (!resposta.ok) throw new Error(`Falha ao obter token: ${resposta.status}`);
  // Converte a resposta para JSON (access_token e expires_in).
  const dados = await resposta.json();
  // Atualiza o cache: cria um NOVO objeto com o token e a expiração.
  // expires_in vem em segundos, então multiplicamos por 1000 para ms.
  tokenCache = { accessToken: dados.access_token, expiraEm: agora + dados.expires_in * 1000 };
  // Retorna o token finalmente.
  return tokenCache.accessToken;
}


// ============================================================
// HANDLER PRINCIPAL DO WORKER
// ============================================================

// Muito daqui são coisas de backend que eu sinceramente ainda não entendo nos detalhes
// É bem copiado e colado de outros codigos similares, mas parece estar tudo dentro do padrão
export default {
  // Função fetch: ponto de entrada de toda requisição HTTP no Worker.
  // Recebe o objeto request, as variáveis de ambiente (env) e o contexto (ctx).
  async fetch(request, env, ctx) {
    // Navegadores enviam uma requisição OPTIONS antes de POST para verificar CORS.
    // Por isso, respondemos com os headers CORS e status 204 (sem conteúdo).
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders });
    }

    // O cabeçalho X-App-Secret deve conter o segredo definido nas variáveis de ambiente.
    // Isso protege o endpoint contra uso não autorizado.
    const segredoRecebido = request.headers.get('X-App-Secret');
    if (segredoRecebido !== env.APP_SECRET) {
      return new Response(JSON.stringify({ erro: 'Não autorizado' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
    
    // Só aceitamos POST no caminho /jogos. Qualquer outra combinação retorna 404.
    const url = new URL(request.url);
    if (url.pathname !== '/jogos' || request.method !== 'POST') {
      return new Response(JSON.stringify({ erro: 'Use POST /jogos com um corpo JSON' }), {
        status: 404,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }

    try {
      // Tenta fazer o parse do corpo como JSON. Se falhar (ex: corpo vazio ou inválido),
      // usa um objeto vazio como fallback, permitindo que os validadores internos tratem os default
      const corpo = await request.json().catch(() => ({}));
      // Chama o orquestrador de recomendação com o ambiente e o corpo parseado.
      const jogo = await buscarRecomendacao(env, corpo);

      // Se o orquestrador retornou null, significa que nenhum jogo foi encontrado.
      if (jogo === null) {
        return new Response(
          JSON.stringify({ erro: 'Nenhum jogo encontrado com esses filtros. Tente ajustar as opções.' }),
          { status: 404, headers: { 'Content-Type': 'application/json', ...corsHeaders } },
        );
      }

      // Sucesso! Retorna o jogo encontrado
      return new Response(JSON.stringify(melhorarImagemDoJogo(jogo)), {
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    } catch (erro) {
      // Captura qualquer erro lançado durante o processo.
      // Se for um ErroValidacao (erro customizado de validação de entrada),
      // retornamos status 400 (Bad Request). Caso contrário, 500 (Internal Server Error).
      const status = erro instanceof ErroValidacao ? 400 : 500;
      return new Response(JSON.stringify({ erro: erro.message }), {
        status,
        headers: { 'Content-Type': 'application/json', ...corsHeaders },
      });
    }
  },
};