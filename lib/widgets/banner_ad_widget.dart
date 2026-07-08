// ============================================================
// Carrega e exibe um banner do AdMob.
// ============================================================
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const String _idAnuncioTeste = 'ca-app-pub-3940256099942544/6300978111'; // Banner de tamanho fixo

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  bool _carregado = false;

  @override
  void initState() {
    super.initState();
    _carregarAnuncio();
  }

  void _carregarAnuncio() {
    final anuncio = BannerAd(
      adUnitId: _idAnuncioTeste,
      size: AdSize.banner, // 320x50, fixo — sem API deprecated envolvida
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _carregado = true);
        },
        onAdFailedToLoad: (ad, erro) {
          ad.dispose(); // sempre descarta se falhar, senão vaza memória
          debugPrint('Falha ao carregar anúncio: $erro');
        },
      ),
    );

    anuncio.load();
    _banner = anuncio;
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_carregado || _banner == null) {
      // Espaço reservado do mesmo tamanho, mesmo antes de carregar —
      // evita a tela "pular" quando o anúncio chegar.
      return const SizedBox(width: 320, height: 50);
    }
    return SizedBox(
      width: _banner!.size.width.toDouble(),
      height: _banner!.size.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}