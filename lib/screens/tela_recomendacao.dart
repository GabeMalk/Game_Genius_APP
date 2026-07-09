// ============================================================
// Tela principal. Integrada com o Worker através do
// GameRepository, HistoricoService e ParametrosBusca.
// ============================================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:indicador_jogos/l10n/app_localizations.dart';
import '../models/jogo.dart';
import '../models/parametros_busca.dart';
import '../services/game_repository.dart';
import '../services/historico_service.dart';
import '../widgets/seletor_filtros.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/sobre.dart';
import '../theme/cores_app.dart';

class TelaRecomendacao extends StatefulWidget {
  const TelaRecomendacao({super.key});

  @override
  State<TelaRecomendacao> createState() => _TelaRecomendacaoState();
}

class _TelaRecomendacaoState extends State<TelaRecomendacao>
    with TickerProviderStateMixin {
  // ============================================================
  // DEPENDÊNCIAS (serviços e modelos)
  // ============================================================

  // Repositório que faz a chamada HTTP para o Worker
  final GameRepository _repository = GameRepository();

  // Serviço de histórico que persiste os IDs já recomendados
  final HistoricoService _historicoService = HistoricoService();

  // Parâmetros de busca (filtros, eras, modo de jogo) — mutável.
  // Inicializado com valores padrão no construtor da classe.
  final ParametrosBusca _parametros = ParametrosBusca();

  // ============================================================
  // TEMPOS - LEMBRA DE AUMENTAR DEPOIS
  // ============================================================
  // Delay minimo da busca
  static const Duration _duracaoEsperaMinima = Duration(milliseconds: 3000);
  // Espera da animação
  static const Duration _duracaoAnimacaoRevelacao = Duration(milliseconds: 2200);

  // ============================================================
  // ESTADO DA TELA
  // ============================================================

  Jogo? _jogoSugerido;            // jogo atualmente exibido (null = estado inicial)
  bool _carregando = false;       // true durante a busca (mostra loading)
  String? _mensagemErro;          // mensagem de erro para exibir (null = sem erro)
  List<int> _historicoIds = [];   // IDs já recomendados (carregados do storage)

  // ============================================================
  // ANIMAÇÃO
  // ============================================================
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration:  _duracaoAnimacaoRevelacao,
  ); // Animation Controler

  // Controller dedicado só pra barra de progresso do
  // loading — duração igual ao delay mínimo, pra encher "certinho".
  late final AnimationController _loadingController = AnimationController(
    vsync: this,
    duration: _duracaoEsperaMinima,
  );

  late final Animation<double> _imagemScale = Tween<double>(
    begin: 0.4,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
  ));

  late final Animation<double> _imagemFade = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
  ));

  late final Animation<double> _textoFade = Tween<double>(
    begin: 0.0,
    end: 1.0,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
  ));

  late final Animation<Offset> _textoSlide = Tween<Offset>(
    begin: const Offset(0, 0.15),
    end: Offset.zero,
  ).animate(CurvedAnimation(
    parent: _animController,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
  ));

  @override
  void initState() {
    super.initState();
    // Carrega o histórico salvo assim que a tela for criada
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    final ids = await _historicoService.carregar();
    setState(() => _historicoIds = ids);
  }

  @override
  void dispose() {
    _animController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  // ============================================================
  // AÇÕES DA TELA
  // ============================================================

  // Volta ao estado inicial (sem jogo exibido)
  void _voltarParaInicio() {
    setState(() {
      _jogoSugerido = null;
      _mensagemErro = null;
    });
    _animController.reset();
  }

  // Abre o modal de filtros usando o novo SeletorFiltros
  void _abrirFiltros() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: CoresApp.superficie,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // StatefulBuilder permite que o modal se atualize a cada toque
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Barra de arraste superior
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // Título
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            l10n.personalizarBuscaTitulo,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dica de uso
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.dicaFiltros,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                      ),
                    ),
                    // Lista de filtros (o novo SeletorFiltros)
                    Flexible(
                      child: SeletorFiltros(
                        parametros: _parametros,
                        onChanged: () {
                          // Atualiza o modal e a tela principal (badge)
                          setModalState(() {});
                          setState(() {});
                        },
                        onLimparFiltros: () {
                          _limparTodosFiltros();
                          setModalState(() {});
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Reseta todos os filtros para o estado padrão (neutro, exceto erótico negativo)
  void _limparTodosFiltros() {
    // Cria uma nova instância de ParametrosBusca, que já tem os defaults
    final novo = ParametrosBusca();
    _parametros.plataforma = novo.plataforma;
    _parametros.modoJogo = novo.modoJogo;
    _parametros.eras = novo.eras;
    _parametros.preferenciasFiltros = novo.preferenciasFiltros;
  }

  // Contagem de filtros ativos (exceto erótico negativo padrão)
  int get _quantidadeFiltrosAtivos => _parametros.quantidadeFiltrosAtivos;

  // Realiza a busca por uma recomendação usando o Worker
  Future<void> _sortearJogo() async {
    if (_carregando) return; // evita múltiplos cliques

    setState(() {
      _carregando = true;
      _mensagemErro = null;
    });
    _loadingController.forward(from: 0); // Dispara a barra de progresso

    try {
      // Chama o repositório passando os parâmetros atuais e o histórico
      final resultados = await Future.wait([
        _repository.buscarRecomendacao(
          parametros: _parametros,
          historicoIds: _historicoIds,
        ),
        Future.delayed(_duracaoEsperaMinima), // Delay minimo
      ]);
      final jogo = resultados[0] as Jogo;

      // Adiciona o ID do jogo retornado ao histórico local e persistido
      final novosIds = await _historicoService.adicionar(jogo.id);

      setState(() {
        _jogoSugerido = jogo;
        _historicoIds = novosIds;
      });

      // Dispara a animação
      _animController.forward(from: 0);
       await Future.delayed(_duracaoAnimacaoRevelacao);
       if (mounted) setState(() => _carregando = false);
    } on NenhumJogoEncontradoException catch (_) {
      // Erro esperado: nenhum jogo encontrado com esses filtros
      if (mounted) {
        setState(() {
          _carregando = false;
          _jogoSugerido = null; 
          _mensagemErro = AppLocalizations.of(context)!.nenhumJogoEncontrado;
        });
      }
    } catch (e) {
      // Outros erros
      if (mounted) {
        setState(() {
          _carregando = false;
          _jogoSugerido = null; 
          _mensagemErro = AppLocalizations.of(context)!.erroBuscaGenerico;
        });
      }
    }
  }

  // Abre o link da loja no navegador/app externo
  Future<void> _abrirLoja(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.erroAbrirLink(url)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

 void _abrirOpcoes() {
  showDialog(
    context: context,
    builder: (context) => const DialogoOpcoes(),
  );
}


  // ============================================================
  // CONSTRUÇÃO DA UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CoresApp.fundo,
      // Cabeçalho customizado (_buildTopo) logo abaixo, abrindo espaço pro banner de anúncio.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            children: [
              _buildTopo(),
              Expanded(
                child: Center(
                  child: _buildConteudoCentral(),
                ),
              ),
              const SizedBox(height: 12),
              _buildBotaoFiltrar(),
              const SizedBox(height: 12),
              _buildBotao(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // Cabeçalho customizado — home à esquerda, espaço
  // reservado pro banner de anúncio no meio, opções à direita.
   Widget _buildTopo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: _voltarParaInicio,
            icon: const Icon(Icons.home_rounded, color: Colors.white),
            iconSize: 30,
            tooltip: 'Home',
          ),
          Expanded(
            child: Center(
              child: const BannerAdWidget(),
            ),
          ),
          IconButton(
            onPressed: _abrirOpcoes,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            iconSize: 30,
            tooltip: 'Config',
          ),
        ],
      ),
    );
  }

  // Decide o que mostrar no centro
 Widget _buildConteudoCentral() {
    // O centro simplesmente continua mostrando o que já tinha (o
    // card antigo, ou o estado inicial) enquanto uma nova busca roda.
    if (_mensagemErro != null && _jogoSugerido == null) {
      return _buildMensagemErro();
    }
    if (_jogoSugerido != null) {
      return _buildCardJogo(_jogoSugerido!);
    }
    return _buildEstadoInicial();
  }

  Widget _buildEstadoInicial() {
    final l10n = AppLocalizations.of(context)!; 
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videogame_asset_outlined,
            size: 72, color: const Color.fromARGB(255, 12, 171, 89)),
        const SizedBox(height: 16),
        Text(
          l10n.estadoInicialTexto,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }


  // Exibe a mensagem de erro (ex: "Nenhum jogo encontrado")
  Widget _buildMensagemErro() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: CoresApp.primaria.shade200),
        const SizedBox(height: 16),
        Text(
          _mensagemErro!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // Card do jogo com animação (mantido igual, mas adaptado para os novos campos)
  Widget _buildCardJogo(Jogo jogo) {
    final l10n = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: CoresApp.superficie,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: CoresApp.primaria.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fase 1: imagem
                FadeTransition(
                  opacity: _imagemFade,
                  child: ScaleTransition(
                    scale: _imagemScale,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 227 / 320,
                      child: Image.network(
                        jogo.imagemUrl ?? '', // url já tratada pelo Worker
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: CoresApp.primaria.shade900,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white70),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: CoresApp.primaria.shade900,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Fase 2: texto
                FadeTransition(
                  opacity: _textoFade,
                  child: SlideTransition(
                    position: _textoSlide,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Nome do jogo
                          Text(
                            jogo.nome,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Gêneros e temas (usando o getter generosLabel)
                          if (jogo.generosLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                jogo.generosLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: CoresApp.primaria.shade100,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // Sinopse
                          if (jogo.sinopse != null && jogo.sinopse!.isNotEmpty)
                            Text(
                              jogo.sinopse!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade300,
                                height: 1.5,
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Botão da loja (se houver link)
                          if (jogo.linkLoja != null)
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _abrirLoja(jogo.linkLoja!),
                                icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                                label: Text(l10n.botaoVerNaLoja),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: CoresApp.primaria.shade200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Botão "Filtrar" com badge de quantidade de filtros ativos
  Widget _buildBotaoFiltrar() {
    final l10n = AppLocalizations.of(context)!;
    final quantidade = _quantidadeFiltrosAtivos;
    final temFiltro = quantidade > 0;

    return TextButton(
      onPressed: _abrirFiltros,
      style: TextButton.styleFrom(
        foregroundColor: CoresApp.primaria.shade100, 
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune, size: 16),
          const SizedBox(width: 6),
          Text(
            l10n.filtrarBotao,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CoresApp.primaria.shade100, 
            ),
          ),
          if (temFiltro) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: CoresApp.primaria,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$quantidade',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Botão principal "Me indica um jogo!"
  // Agora, enquanto carrega, o BOTÃO INTEIRO vira
  // uma barra de progresso grossa no mesmo espaço
  // na primeira busca e nas seguintes.
   Widget _buildBotao() {
    if (_carregando) {
      return SizedBox(
        width: double.infinity,
        height: 56, // aprox. a mesma altura do ElevatedButton abaixo
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (context, _) => LinearProgressIndicator(
                value: _loadingController.value,
                minHeight: 18, // barra grossa, não mais uma rodinha fina
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(CoresApp.primaria),
              ),
            ),
          ),
        ),
      );
    }

    final l10n = AppLocalizations.of(context)!;


    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _sortearJogo,
        icon: const Icon(Icons.casino),
        label: Text(l10n.botaoSortear),
        style: ElevatedButton.styleFrom(
          backgroundColor: CoresApp.primaria,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}