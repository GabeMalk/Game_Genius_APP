// ============================================================
// PARAMETROS BUSCA é o elo entre o app e o worker,
// pegando os filtros atuais e transformando num JSON
// ============================================================
import 'filtro.dart';  // importa o catálogo de filtros e o enum

class ParametrosBusca {
  // ---- CAMPOS ----

  // Plataforma selecionada (ID da IGDB). Inicia com 6 (PC).
  String plataforma;

  // Aqui está o "estado" de cada filtro
  // Mapa que associa a chave do filtro (ex: 'rpg') ao estado atual
  // (neutro, positivo, negativo). É neste valor que chamaremos .proximo
  Map<String, PreferenciaFiltro> preferenciasFiltros;

  // Modo de jogo: 'single', 'multi' ou null (sem restrição).
  String? modoJogo;

  // Eras selecionadas (chaves como 'atualidade', 'classicos', etc.).
  Set<String> eras;

  // ---- CONSTRUTOR ----

  // Inicializa os campos com valores padrão.
  ParametrosBusca()
      : plataforma = 'pc',               // PC por padrão
        modoJogo = null,               // sem restrição de modo
        eras = {'atualidade'},         // era padrão: jogos de 2020 até hoje
        preferenciasFiltros = {
          // Cria uma entrada no mapa para CADA filtro do catálogo.
          // O valor padrão é neutro, EXCETO para 'erotic', que já
          // começa como negativo (excluir conteúdo erótico por padrão).
          for (final f in catalogoDeFiltros)
            f.chave: f.chave == 'erotic'
                ? PreferenciaFiltro.negativo
                : PreferenciaFiltro.neutro,
        };

  // ---- GETTERS DERIVADOS ----

  // Retorna um Set com as chaves dos filtros que estão no estado POSITIVO.
  Set<String> get filtrosPositivos => preferenciasFiltros.entries
      .where((e) => e.value == PreferenciaFiltro.positivo) // filtra só os positivos
      .map((e) => e.key)                                   // extrai a chave (string)
      .toSet();                                            // converte para Set

  // Retorna um Set com as chaves dos filtros que estão no estado NEGATIVO.
  Set<String> get filtrosNegativos => preferenciasFiltros.entries
      .where((e) => e.value == PreferenciaFiltro.negativo)
      .map((e) => e.key)
      .toSet();

  // Conta quantos filtros foram ativamente alterados pelo usuário
  // (não conta neutros nem o erótico negativo padrão).
  int get quantidadeFiltrosAtivos {
    var contagem = 0;
    preferenciasFiltros.forEach((chave, pref) {
      if (pref == PreferenciaFiltro.neutro) return; // neutros não são "ativos"
      // O erótico negativo já vem por padrão; não deve contar como ação do usuário
      if (chave == 'erotic' && pref == PreferenciaFiltro.negativo) return;
      contagem++;
    });
    return contagem;
  }

  // Resolve a chave em ids
  List<int> get plataformaIds =>
        catalogoDePlataformas.firstWhere((p) => p.chave == plataforma).ids;

  // ---- SERIALIZAÇÃO PARA JSON ----

  // Converte os parâmetros atuais para um mapa JSON compatível com o Worker.
  // Recebe a lista de IDs do histórico (jogos já vistos).
  Map<String, dynamic> toJson(List<int> historicoIds) {
    return {
      'plataforma': plataformaIds,
      // só inclui os campos se não estiverem vazios/nulos
      if (filtrosPositivos.isNotEmpty) 'filtros': filtrosPositivos.toList(),
      if (filtrosNegativos.isNotEmpty) 'filtrosNegativos': filtrosNegativos.toList(),
      if (modoJogo != null) 'modoJogo': modoJogo,
      if (eras.isNotEmpty) 'eras': eras.toList(),
      if (historicoIds.isNotEmpty) 'historicoIds': historicoIds,
    };
  }
}