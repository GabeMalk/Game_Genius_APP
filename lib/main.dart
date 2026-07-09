// ============================================================
// Mains
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:indicador_jogos/l10n/app_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/tela_recomendacao.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Isso aqui é pra não bugar no chrome
  if (!kIsWeb) {
  await MobileAds.instance.initialize();}
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