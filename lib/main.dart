// ============================================================
// Mains
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:indicador_jogos/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/tela_recomendacao.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const IndicaJogoApp());
}

class IndicaJogoApp extends StatelessWidget {
  const IndicaJogoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const TelaRecomendacao(),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}