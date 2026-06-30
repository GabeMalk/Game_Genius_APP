// ============================================================
// ARQUIVO: lib/screens/tela_recomendacao.dart
// Tela principal. Só lida com estado e layout — os dados vêm
// de data/jogos_mock.dart e o modelo de models/jogo.dart.
// ============================================================
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/jogo.dart';
import '../models/genero.dart';
import '../models/preferencia_genero.dart';
import '../data/jogos_mock.dart';
import '../widgets/seletor_generos.dart';

class TelaRecomendacao extends StatefulWidget {
  const TelaRecomendacao({super.key});

  @override
  State<TelaRecomendacao> createState() => _TelaRecomendacaoState();
}

class _TelaRecomendacaoState extends State<TelaRecomendacao>
    with SingleTickerProviderStateMixin {
  // Dado vem do arquivo separado — quando a API chegar, isso
  // troca para algo como `await GameRepository().buscarJogos()`
  final List<Jogo> _jogos = jogosMock;

  // ============================================================
  // PREFERÊNCIAS DE GÊNERO
  // Mapa Genero -> PreferenciaGenero (neutro/gosta/naoGosta).
  // Por ora só é visual (não filtra a lista de fato ainda), mas
  // a estrutura já é a que vai alimentar o filtro real depois:
  // ao sortear, basta checar esse mapa pra excluir/priorizar.
  // Inicializamos todos os gêneros como "neutro".
  // ============================================================
  final Map<Genero, PreferenciaGenero> _preferencias = {
    for (final g in Genero.values) g: PreferenciaGenero.neutro,
  };

  void _alternarPreferencia(Genero genero) {
    setState(() {
      final atual = _preferencias[genero] ?? PreferenciaGenero.neutro;
      _preferencias[genero] = atual.proximo;
    });
  }

  void _limparFiltros() {
    setState(() {
      for (final g in Genero.values) {
        _preferencias[g] = PreferenciaGenero.neutro;
      }
    });
  }

  // Quantos gêneros têm alguma preferência marcada (gosta ou não-gosta).
  // Usado pra mostrar o badge no botão "Filtrar".
  int get _quantidadeFiltrosAtivos =>
      _preferencias.values.where((p) => p != PreferenciaGenero.neutro).length;

  void _voltarParaInicio() {
    setState(() {
      _jogoSugerido = null;
    });
    _animController.reset();
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1B2E),
      isScrollControlled: true,
      // Limita a altura do sheet para não cobrir a tela inteira —
      // ele para antes do cabeçalho, deixando claro que ainda
      // estamos "na mesma tela" por baixo.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        // StatefulBuilder permite que o BottomSheet se redesenhe
        // sozinho a cada toque, sem precisar fechar e reabrir.
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                      child: Row(
                        children: [
                          Icon(Icons.tune, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Seus gêneros',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Toque 1x para 👍 curtir, 2x para 👎 evitar, 3x para limpar.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                    Flexible(
                      child: SeletorGeneros(
                        preferencias: _preferencias,
                        onToqueGenero: (genero) {
                          _alternarPreferencia(genero);
                          setModalState(() {});
                        },
                        onLimparFiltros: () {
                          _limparFiltros();
                          setModalState(() {});
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

  Jogo? _jogoSugerido;
  bool _carregando = false;

  // ============================================================
  // ANIMAÇÃO EM DUAS FASES (estilo "item get" do Zelda):
  // Fase 1 (0% -> 60%): imagem cresce do centro com fade-in e
  //   leve "bounce" no final (easeOutBack), como o item assentando.
  // Fase 2 (55% -> 100%): o texto (gênero, nome, sinopse, botão)
  //   aparece em fade + slide, depois que a imagem já assentou.
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _sortearJogo() async {
    if (_carregando) return; // trava cliques repetidos

    setState(() => _carregando = true);

    // Pequeno delay simulando "busca" — também serve de cooldown
    // pra evitar spam no botão. Quando ligar numa API real, essa
    // espera vira o tempo natural da requisição.
    await Future.delayed(const Duration(milliseconds: 500));

    final random = Random();
    final novoJogo = _jogos[random.nextInt(_jogos.length)];

    setState(() {
      _jogoSugerido = novoJogo;
      _carregando = false;
    });

    _animController.forward(from: 0);
  }

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
                  child: _jogoSugerido == null
                      ? _buildEstadoInicial()
                      : _buildCardJogo(_jogoSugerido!),
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
                // ---- FASE 1: imagem "estilo item get" ----
                FadeTransition(
                  opacity: _imagemFade,
                  child: ScaleTransition(
                    scale: _imagemScale,
                    alignment: Alignment.center,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        jogo.imagemUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.deepPurple.shade900,
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white70),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.deepPurple.shade900,
                          child: const Center(
                            child: Icon(Icons.broken_image_outlined,
                                size: 48, color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---- FASE 2: texto, surge depois, em fade + slide ----
                FadeTransition(
                  opacity: _textoFade,
                  child: SlideTransition(
                    position: _textoSlide,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Chip(s) de gênero — agora pode ter vários
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 6,
                            runSpacing: 6,
                            children: jogo.generos.map((g) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple
                                      .withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  g.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.deepPurple.shade100,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),

                          // Nome — centralizado, efeito "revelação"
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
                          Text(
                            jogo.sinopse,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade300,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Botão da loja
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _abrirLoja(jogo.linkLoja),
                              icon: const Icon(Icons.shopping_bag_outlined,
                                  size: 18),
                              label: const Text('Ver na loja'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                    color: Colors.deepPurple.shade200),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
          // Badge com a quantidade de filtros ativos
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

  // Abre o link da loja no navegador/app externo.
  // canLaunchUrl checa se existe algo no aparelho capaz de abrir
  // esse link antes de tentar — evita travar caso não consiga.
  Future<void> _abrirLoja(String url) async {
    final uri = Uri.parse(url);
    final podeAbrir = await canLaunchUrl(uri);

    if (podeAbrir) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // mounted checa se o widget ainda está na tela antes de usar
      // o context — útil porque houve um "await" antes disso.
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
}