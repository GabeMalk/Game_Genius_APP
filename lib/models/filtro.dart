// ============================================================
// As chaves abaixo espelham o FILTROS_CATALOGO do
// worker.js. Só o "label" é exclusivo daqui.
// ============================================================

// --- CICLO DE PREFERÊNCIA (neutro / positivo / negativo) ---

// Enum que representa o estado atual de um filtro na interface:
// - neutro: não selecionado
// - positivo: quer incluir (filtro positivo)
// - negativo: quer excluir (filtro negativo)
enum PreferenciaFiltro { neutro, positivo, negativo }

// Extension: adiciona um getter "proximo" ao enum, que calcula o próximo estado
// no ciclo: neutro → positivo → negativo → neutro.
// Isso é usado para alternar entre os estados ao tocar no chip do filtro.
extension CicloPreferenciaFiltro on PreferenciaFiltro {
  PreferenciaFiltro get proximo {
    switch (this) {
      case PreferenciaFiltro.neutro:
        return PreferenciaFiltro.positivo;
      case PreferenciaFiltro.positivo:
        return PreferenciaFiltro.negativo;
      case PreferenciaFiltro.negativo:
        return PreferenciaFiltro.neutro;
    }
  }
}

// --- CLASSE PARA REPRESENTAR UM FILTRO DO CATÁLOGO ---

// Um filtro individual do catálogo.
class FiltroInfo {
  final String chave; // TEM que bater com a chave do worker.js
  final String label; // texto exibido na UI (fica isolado aqui pensando em i18n futuro)
  final bool basico; // se true, é mostrado por padrão; se false, só após expandir "avançados"

  // Construtor constante (permite criar objetos em tempo de compilação,
  // otimizando performance e permitindo listas const)
  const FiltroInfo({required this.chave, required this.label, this.basico = false});
}

// --- LISTA DE TODOS OS FILTROS  ---

// Espelho do FILTROS_CATALOGO do Worker.
// A chave deve ser idêntica à usada lá, pois será enviada na requisição.
// O label é o texto que aparece na tela; só existe no lado Flutter.

const List<FiltroInfo> catalogoDeFiltros = [
  // ---- básicos (aparecem por padrão) ----
  FiltroInfo(chave: 'rpg', label: 'RPG', basico: true),
  FiltroInfo(chave: 'aventura', label: 'Aventura', basico: true),
  FiltroInfo(chave: 'acao', label: 'Ação', basico: true),
  FiltroInfo(chave: 'plataforma_genero', label: 'Jogos de plataforma', basico: true),
  FiltroInfo(chave: 'estrategia', label: 'Estratégia', basico: true),
  FiltroInfo(chave: 'tiro', label: 'Tiro', basico: true),
  FiltroInfo(chave: 'luta', label: 'Luta', basico: true),
  FiltroInfo(chave: 'simulacao_trabalho', label: 'Simulação e trabalho', basico: true),
  FiltroInfo(chave: 'visual_novel', label: 'Visual Novel', basico: true),
  FiltroInfo(chave: 'esportes_corrida', label: 'Esportes e corrida', basico: true),
  FiltroInfo(chave: 'quebra_cabeca', label: 'Quebra-cabeça', basico: true),
  FiltroInfo(chave: 'cartas_tabuleiro', label: 'Cartas e tabuleiro', basico: true),
  FiltroInfo(chave: 'terror_suspense', label: 'Terror e suspense', basico: true),

  // ---- avançados (só aparecem ao clicar em "Avançados") ----
  FiltroInfo(chave: 'roguelike', label: 'Roguelike'),
  FiltroInfo(chave: 'primeira_pessoa', label: 'Primeira pessoa'),
  FiltroInfo(chave: 'indie', label: 'Indie'),
  FiltroInfo(chave: 'point_and_click', label: "Point 'n' Click"),
  FiltroInfo(chave: 'mundo_aberto', label: 'Mundo aberto'),
  FiltroInfo(chave: 'drama_misterio', label: 'Drama e mistério'),
  FiltroInfo(chave: 'sandbox', label: 'Sandbox'),
  FiltroInfo(chave: 'sobrevivencia', label: 'Sobrevivência'),
  FiltroInfo(chave: 'furtividade', label: 'Furtividade'),
  FiltroInfo(chave: 'fantasia_medieval', label: 'Fantasia e medieval'),
  FiltroInfo(chave: 'ficcao_cientifica', label: 'Ficção científica'),
  FiltroInfo(chave: 'musica', label: 'Música'),
  FiltroInfo(chave: 'rts', label: 'RTS'),
  FiltroInfo(chave: 'jogo_de_festa', label: 'Jogo de festa'),
  FiltroInfo(chave: 'engracado', label: 'Engraçado'),
  FiltroInfo(chave: 'romance', label: 'Romance'),
  FiltroInfo(chave: 'anime', label: 'Anime'),
  FiltroInfo(chave: 'erotic', label: 'Erótico'),
];

// --- GETTERS PARA LISTAS ESPECÍFICAS ---

// Retorna apenas os filtros marcados como básicos
List<FiltroInfo> get filtrosBasicos => catalogoDeFiltros.where((f) => f.basico).toList();
// Retorna apenas os filtros avançados
List<FiltroInfo> get filtrosAvancados => catalogoDeFiltros.where((f) => !f.basico).toList();

// ---- Eras / igual ao calcularEras() do worker ----

// Representa uma era (período de lançamento)
class EraInfo {
  final String chave;
  final String label;
  const EraInfo(this.chave, this.label);
}

// Lista espelho das chaves retornadas por calcularEras() no Worker
const List<EraInfo> catalogoDeEras = [
  EraInfo('lancamentos', 'Lançamentos'),
  EraInfo('atualidade', 'Atualidade'),
  EraInfo('modernos', 'Modernos'),
  EraInfo('old_school', 'Old School'),
  EraInfo('classicos', 'Clássicos'),
];

// --- PLATAFORMAS ---

// Representa uma plataforma (ex: PC, Xbox, etc.).
class PlataformaInfo {
  final int id;  // ID da plataforma na IGDB (ex: 6 = PC)
  final String label; // texto exibido
  const PlataformaInfo({required this.id, required this.label});
}

// Lista de plataformas disponíveis. Apenas PC por enquanto.
const List<PlataformaInfo> catalogoDePlataformas = [
  PlataformaInfo(id: 6, label: 'PC'),
];