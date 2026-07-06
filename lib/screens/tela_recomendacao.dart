// ============================================================
// Tela principal. Integrada com o Worker através do
// GameRepository, HistoricoService e ParametrosBusca.
// ============================================================
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/jogo.dart';
import '../models/parametros_busca.dart';
import '../services/game_repository.dart';
import '../services/historico_service.dart';
import '../widgets/seletor_filtros.dart';

class TelaRecomendacao extends StatefulWidget {
  const TelaRecomendacao({super.key});

  @override
  State<TelaRecomendacao> createState() => _TelaRecomendacaoState();
}

class _TelaRecomendacaoState extends State<TelaRecomendacao>
    with SingleTickerProviderStateMixin {
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
  // ESTADO DA TELA
  // ============================================================

  Jogo? _jogoSugerido;            // jogo atualmente exibido (null = estado inicial)
  bool _carregando = false;       // true durante a busca (mostra loading)
  String? _mensagemErro;          // mensagem de erro para exibir (null = sem erro)
  List<int> _historicoIds = [];   // IDs já recomendados (carregados do storage)

  // ============================================================
  // ANIMAÇÃO (mantida igual ao original)
  // ============================================================
  late final AnimationController _animController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Personalizar busca',
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
                        'Toque 1x para 👍 incluir, 2x para 👎 excluir, 3x para limpar.',
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

    try {
      // Chama o repositório passando os parâmetros atuais e o histórico
      final jogo = await _repository.buscarRecomendacao(
        parametros: _parametros,
        historicoIds: _historicoIds,
      );

      // Adiciona o ID do jogo retornado ao histórico local e persistido
      final novosIds = await _historicoService.adicionar(jogo.id);

      setState(() {
        _jogoSugerido = jogo;
        _historicoIds = novosIds;
        _carregando = false;
      });

      // Dispara a animação
      _animController.forward(from: 0);
    } on NenhumJogoEncontradoException catch (e) {
      // Erro esperado: nenhum jogo encontrado com esses filtros
      setState(() {
        _carregando = false;
        _mensagemErro = e.mensagem;
      });
    } catch (e) {
      // Outros erros (rede, Worker fora do ar, etc.)
      setState(() {
        _carregando = false;
        _mensagemErro = 'Erro ao buscar recomendação. Tente novamente.';
      });
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
            content: Text('Não foi possível abrir o link: $url'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ============================================================
  // CONSTRUÇÃO DA UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121018),
      appBar: AppBar(
        leading: IconButton(
          onPressed: _voltarParaInicio,
          icon: const Icon(Icons.home_rounded),
          tooltip: 'Início',
        ),
        title: const Text(
          '🎮 IndicaJogo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
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

  // Decide o que mostrar no centro: estado inicial, erro, jogo ou loading
  Widget _buildConteudoCentral() {
    if (_carregando && _jogoSugerido == null) {
      return _buildEstadoInicial(); // mostra tela inicial enquanto carrega
    }
    if (_mensagemErro != null && _jogoSugerido == null) {
      return _buildMensagemErro();
    }
    if (_jogoSugerido != null) {
      return _buildCardJogo(_jogoSugerido!);
    }
    return _buildEstadoInicial();
  }

  Widget _buildEstadoInicial() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.videogame_asset_outlined,
            size: 72, color: Colors.deepPurple.shade200),
        const SizedBox(height: 16),
        const Text(
          'Clique no botão abaixo para\nreceber uma indicação!',
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
        Icon(Icons.search_off, size: 64, color: Colors.deepPurple.shade200),
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
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1B2E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.25),
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
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        jogo.imagemUrl ?? '', // url já tratada pelo Worker
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.deepPurple.shade900,
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white70),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.deepPurple.shade900,
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
                          // Gêneros e temas (usando o getter generosLabel)
                          if (jogo.generosLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                jogo.generosLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.deepPurple.shade100,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
                                label: const Text('Ver na loja'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.deepPurple.shade200),
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
    final quantidade = _quantidadeFiltrosAtivos;
    final temFiltro = quantidade > 0;

    return TextButton(
      onPressed: _abrirFiltros,
      style: TextButton.styleFrom(
        foregroundColor: Colors.deepPurple.shade100,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune, size: 16),
          const SizedBox(width: 6),
          Text(
            'Filtrar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade100,
            ),
          ),
          if (temFiltro) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
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
  Widget _buildBotao() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _carregando ? null : _sortearJogo,
        icon: _carregando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.casino),
        label: Text(_carregando ? 'Buscando...' : 'Me indica um jogo!'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}