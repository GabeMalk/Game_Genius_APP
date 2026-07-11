import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:indicador_jogos/l10n/app_localizations.dart';

class DialogoOpcoes extends StatefulWidget {
  const DialogoOpcoes({super.key, this.isClickShortcut = false,});

 final bool isClickShortcut; 

  @override
  State<DialogoOpcoes> createState() => _DialogoOpcoesState();
}

class _DialogoOpcoesState extends State<DialogoOpcoes> {
  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  bool _rewardedReady = false;

  // O oficial é ca-app-pub-1018185380682464/5490513282
  static const String _rewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  // Carrega o anúncio e retorna true se bem-sucedido.
  Future<bool> _loadRewardedAd() async {
    final completer = Completer<bool>();
    setState(() => _isLoadingRewarded = true);

    await RewardedAd.load(
      adUnitId: _rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            completer.complete(false);
            return;
          }
          setState(() {
            _rewardedAd = ad;
            _rewardedReady = true;
            _isLoadingRewarded = false;
          });
          completer.complete(true);
        },
        onAdFailedToLoad: (error) {
          if (!mounted) {
            completer.complete(false);
            return;
          }
          setState(() {
            _isLoadingRewarded = false;
            _rewardedReady = false;
          });
          debugPrint('Falha ao carregar anúncio premiado: $error');
          completer.complete(false);
        },
      ),
    );
    return completer.future;
  }

  // Exibe o anúncio premiado.
  void _showRewardedAd() {
    final l10n = AppLocalizations.of(context)!;
    if (_rewardedAd == null) return;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        if (mounted) {
          setState(() {});
          if (Navigator.canPop(context)) {
          Navigator.of(context).pop();}
          _mostrarAgradecimento();
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _rewardedReady = false;
        if (mounted) {
          setState(() {});
          _mostrarErro(l10n.videoErroExibicao);
        }
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      // Recompensa concedida (pode adicionar lógica extra).
    });
  }

  // Diálogo centralizado de agradecimento.
  void _mostrarAgradecimento() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              l10n.videoObrigadoTitulo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.videoObrigadoMensagem,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.fechar, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // Diálogo de erro.
  void _mostrarErro(String mensagem) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.erro, style: const TextStyle(color: Colors.white)),
        content: Text(mensagem, style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.fechar, style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  // Ação principal: carrega (se preciso) e exibe o vídeo premiado.
  Future<void> _onApoiar() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_rewardedReady) {
      final carregou = await _loadRewardedAd();
      if (!mounted) return;
      if (!carregou) {
        _mostrarErro(l10n.videoErroCarregar);
        return;
      }
    }
    if (_rewardedReady) {
      _showRewardedAd();
    } else {
      _mostrarErro(l10n.videoIndisponivel);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Texto diferente quando aberto via contador de cliques
     final sobreTexto = widget.isClickShortcut 
      ? l10n.sobreTextoClickShortcut  // Quando tem o limite de click
      : l10n.sobreTexto;
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1B2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(l10n.opcoesTitulo, style: const TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sobreTexto,
            style: const TextStyle(color: Colors.white, height: 1, fontSize: 18),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isLoadingRewarded ? null : _onApoiar,
              icon: _isLoadingRewarded
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_circle_outline),
              label: Text(
                _isLoadingRewarded ? l10n.videoCarregando : l10n.videoApoiar,
                style: const TextStyle(color: Colors.white),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.amber),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.fechar, style: const TextStyle(color: Colors.green)),
        ),
      ],
    );
  }
}