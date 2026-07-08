// ============================================================
// As chaves abaixo espelham o FILTROS_CATALOGO do
// worker.js. Só o "label" é exclusivo daqui.
// ============================================================

import 'package:indicador_jogos/l10n/app_localizations.dart';

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
  final bool basico; // se true, é mostrado por padrão; se false, só após expandir "avançados"

  // Construtor constante (permite criar objetos em tempo de compilação,
  // otimizando performance e permitindo listas const)
  const FiltroInfo({required this.chave, this.basico = false});
}

// --- LISTA DE TODOS OS FILTROS  ---

// Espelho do FILTROS_CATALOGO do Worker.
// A chave deve ser idêntica à usada lá, pois será enviada na requisição.
// O label é o texto que aparece na tela; só existe no lado Flutter.

const List<FiltroInfo> catalogoDeFiltros = [
  // ---- básicos (aparecem por padrão) ----
  FiltroInfo(chave: 'rpg', basico: true),
  FiltroInfo(chave: 'aventura', basico: true),
  FiltroInfo(chave: 'acao', basico: true),
  FiltroInfo(chave: 'plataforma_genero', basico: true),
  FiltroInfo(chave: 'estrategia', basico: true),
  FiltroInfo(chave: 'tiro', basico: true),
  FiltroInfo(chave: 'luta', basico: true),
  FiltroInfo(chave: 'simulacao_trabalho', basico: true),
  FiltroInfo(chave: 'visual_novel', basico: true),
  FiltroInfo(chave: 'esportes_corrida', basico: true),
  FiltroInfo(chave: 'quebra_cabeca', basico: true),
  FiltroInfo(chave: 'cartas_tabuleiro', basico: true),
  FiltroInfo(chave: 'terror_suspense', basico: true),

  // ---- avançados (só aparecem ao clicar em "Avançados") ----
  FiltroInfo(chave: 'roguelike'),
  FiltroInfo(chave: 'primeira_pessoa'),
  FiltroInfo(chave: 'indie'),
  FiltroInfo(chave: 'point_and_click'),
  FiltroInfo(chave: 'mundo_aberto'),
  FiltroInfo(chave: 'drama_misterio'),
  FiltroInfo(chave: 'sandbox'),
  FiltroInfo(chave: 'sobrevivencia'),
  FiltroInfo(chave: 'furtividade'),
  FiltroInfo(chave: 'fantasia_medieval'),
  FiltroInfo(chave: 'ficcao_cientifica'),
  FiltroInfo(chave: 'musica'),
  FiltroInfo(chave: 'rts'),
  FiltroInfo(chave: 'jogo_de_festa'),
  FiltroInfo(chave: 'engracado'),
  FiltroInfo(chave: 'romance'),
  FiltroInfo(chave: 'anime'),
  FiltroInfo(chave: 'erotic'),
];

// --- GETTERS PARA LISTAS ESPECÍFICAS ---

// Retorna apenas os filtros marcados como básicos
List<FiltroInfo> get filtrosBasicos => catalogoDeFiltros.where((f) => f.basico).toList();
// Retorna apenas os filtros avançados
List<FiltroInfo> get filtrosAvancados => catalogoDeFiltros.where((f) => !f.basico).toList();

// --- Chave para texto localizado ---
String labelDoFiltro(AppLocalizations l10n, String chave) {
  switch (chave) {
    case 'rpg': return l10n.filtroRpg;
    case 'aventura': return l10n.filtroAventura;
    case 'acao': return l10n.filtroAcao;
    case 'plataforma_genero': return l10n.filtroPlataformaGenero;
    case 'estrategia': return l10n.filtroEstrategia;
    case 'tiro': return l10n.filtroTiro;
    case 'luta': return l10n.filtroLuta;
    case 'simulacao_trabalho': return l10n.filtroSimulacaoTrabalho;
    case 'visual_novel': return l10n.filtroVisualNovel;
    case 'esportes_corrida': return l10n.filtroEsportesCorrida;
    case 'quebra_cabeca': return l10n.filtroQuebraCabeca;
    case 'cartas_tabuleiro': return l10n.filtroCartasTabuleiro;
    case 'terror_suspense': return l10n.filtroTerrorSuspense;
    case 'roguelike': return l10n.filtroRoguelike;
    case 'primeira_pessoa': return l10n.filtroPrimeiraPessoa;
    case 'indie': return l10n.filtroIndie;
    case 'point_and_click': return l10n.filtroPointAndClick;
    case 'mundo_aberto': return l10n.filtroMundoAberto;
    case 'drama_misterio': return l10n.filtroDramaMisterio;
    case 'sandbox': return l10n.filtroSandbox;
    case 'sobrevivencia': return l10n.filtroSobrevivencia;
    case 'furtividade': return l10n.filtroFurtividade;
    case 'fantasia_medieval': return l10n.filtroFantasiaMedieval;
    case 'ficcao_cientifica': return l10n.filtroFiccaoCientifica;
    case 'musica': return l10n.filtroMusica;
    case 'rts': return l10n.filtroRts;
    case 'jogo_de_festa': return l10n.filtroJogoDeFesta;
    case 'engracado': return l10n.filtroEngracado;
    case 'romance': return l10n.filtroRomance;
    case 'anime': return l10n.filtroAnime;
    case 'erotic': return l10n.filtroErotic;
    default: return chave; // nunca deveria cair aqui
  }
}

// ---- Eras / igual ao calcularEras() do worker ----

// Representa uma era (período de lançamento)
class EraInfo {
  final String chave;
  const EraInfo(this.chave);
}

// Lista espelho das chaves retornadas por calcularEras() no Worker
const List<EraInfo> catalogoDeEras = [
  EraInfo('lancamentos'),
  EraInfo('atualidade'),
  EraInfo('modernos'),
  EraInfo('old_school'),
  EraInfo('classicos'),
];

String labelDaEra(AppLocalizations l10n, String chave) {
  switch (chave) {
    case 'lancamentos': return l10n.eraLancamentos;
    case 'atualidade': return l10n.eraAtualidade;
    case 'modernos': return l10n.eraModernos;
    case 'old_school': return l10n.eraOldSchool;
    case 'classicos': return l10n.eraClassicos;
    default: return chave;
  }
}

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