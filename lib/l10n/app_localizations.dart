import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
  ];

  /// Botão principal para sortear jogos
  ///
  /// In en, this message translates to:
  /// **'Find a new game to play!'**
  String get botaoSortear;

  /// Texto explicativo inicial
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to\nget a recommendation!'**
  String get estadoInicialTexto;

  /// Botão para ver jogo na loja
  ///
  /// In en, this message translates to:
  /// **'View in store'**
  String get botaoVerNaLoja;

  /// Erro ao abrir link
  ///
  /// In en, this message translates to:
  /// **'Could not open the link: {url}'**
  String erroAbrirLink(String url);

  /// Botão para abrir filtros
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filtrarBotao;

  /// Título da tela de filtros
  ///
  /// In en, this message translates to:
  /// **'Customize search'**
  String get personalizarBuscaTitulo;

  /// Dica de uso dos filtros
  ///
  /// In en, this message translates to:
  /// **'Tap once to include, twice to exclude, and once again to clear.'**
  String get dicaFiltros;

  /// Título da tela de opções
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get opcoesTitulo;

  /// Texto de atribuição
  ///
  /// In en, this message translates to:
  /// **'Made by Malk.\n\nGame data provided by IGDB.com'**
  String get sobreTexto;

  /// Botão fechar
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fechar;

  /// Erro genérico de busca
  ///
  /// In en, this message translates to:
  /// **'Error fetching a recommendation. Please try again.'**
  String get erroBuscaGenerico;

  /// Mensagem quando nenhum jogo é encontrado
  ///
  /// In en, this message translates to:
  /// **'No games found with these filters. Try adjusting your options.'**
  String get nenhumJogoEncontrado;

  /// Seção de plataformas
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get secaoPlataforma;

  /// Seção de épocas
  ///
  /// In en, this message translates to:
  /// **'Era'**
  String get secaoEpoca;

  /// Seção de número de jogadores
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get secaoJogadores;

  /// Botão para limpar filtros
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get limparFiltros;

  /// Modo single player
  ///
  /// In en, this message translates to:
  /// **'Single player'**
  String get modoSingle;

  /// Modo multiplayer
  ///
  /// In en, this message translates to:
  /// **'Multiplayer'**
  String get modoMulti;

  /// Botão para mostrar filtros avançados
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get avancados;

  /// Botão para esconder filtros avançados
  ///
  /// In en, this message translates to:
  /// **'Hide advanced'**
  String get ocultarAvancados;

  /// Filtro de novos lançamentos
  ///
  /// In en, this message translates to:
  /// **'New releases'**
  String get eraLancamentos;

  /// Filtro de atualidade
  ///
  /// In en, this message translates to:
  /// **'Current era'**
  String get eraAtualidade;

  /// Filtro de jogos modernos
  ///
  /// In en, this message translates to:
  /// **'Modern'**
  String get eraModernos;

  /// Filtro de jogos old school
  ///
  /// In en, this message translates to:
  /// **'Old school'**
  String get eraOldSchool;

  /// Filtro de clássicos
  ///
  /// In en, this message translates to:
  /// **'Classics'**
  String get eraClassicos;

  /// Filtro de RPG
  ///
  /// In en, this message translates to:
  /// **'RPG'**
  String get filtroRpg;

  /// Filtro de aventura
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get filtroAventura;

  /// Filtro de ação
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get filtroAcao;

  /// Filtro de platformer
  ///
  /// In en, this message translates to:
  /// **'Platformer'**
  String get filtroPlataformaGenero;

  /// Filtro de estratégia
  ///
  /// In en, this message translates to:
  /// **'Strategy'**
  String get filtroEstrategia;

  /// Filtro de shooter
  ///
  /// In en, this message translates to:
  /// **'Shooter'**
  String get filtroTiro;

  /// Filtro de luta
  ///
  /// In en, this message translates to:
  /// **'Fighting'**
  String get filtroLuta;

  /// Filtro de simulação e trabalho
  ///
  /// In en, this message translates to:
  /// **'Simulation & work'**
  String get filtroSimulacaoTrabalho;

  /// Filtro de visual novel
  ///
  /// In en, this message translates to:
  /// **'Visual Novel'**
  String get filtroVisualNovel;

  /// Filtro de esportes e corrida
  ///
  /// In en, this message translates to:
  /// **'Sports & racing'**
  String get filtroEsportesCorrida;

  /// Filtro de puzzle
  ///
  /// In en, this message translates to:
  /// **'Puzzle'**
  String get filtroQuebraCabeca;

  /// Filtro de jogos de cartas e tabuleiro
  ///
  /// In en, this message translates to:
  /// **'Cards & board games'**
  String get filtroCartasTabuleiro;

  /// Filtro de horror e suspense
  ///
  /// In en, this message translates to:
  /// **'Horror & thriller'**
  String get filtroTerrorSuspense;

  /// Filtro de roguelike
  ///
  /// In en, this message translates to:
  /// **'Roguelike'**
  String get filtroRoguelike;

  /// Filtro de primeira pessoa
  ///
  /// In en, this message translates to:
  /// **'First person'**
  String get filtroPrimeiraPessoa;

  /// Filtro indie
  ///
  /// In en, this message translates to:
  /// **'Indie'**
  String get filtroIndie;

  /// Filtro point and click
  ///
  /// In en, this message translates to:
  /// **'Point \'n\' Click'**
  String get filtroPointAndClick;

  /// Filtro de mundo aberto
  ///
  /// In en, this message translates to:
  /// **'Open world'**
  String get filtroMundoAberto;

  /// Filtro de drama e mistério
  ///
  /// In en, this message translates to:
  /// **'Drama & mystery'**
  String get filtroDramaMisterio;

  /// Filtro de sandbox
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get filtroSandbox;

  /// Filtro de sobrevivência
  ///
  /// In en, this message translates to:
  /// **'Survival'**
  String get filtroSobrevivencia;

  /// Filtro de furtividade
  ///
  /// In en, this message translates to:
  /// **'Stealth'**
  String get filtroFurtividade;

  /// Filtro de fantasia e medieval
  ///
  /// In en, this message translates to:
  /// **'Fantasy & medieval'**
  String get filtroFantasiaMedieval;

  /// Filtro de ficção científica
  ///
  /// In en, this message translates to:
  /// **'Science fiction'**
  String get filtroFiccaoCientifica;

  /// Filtro de música
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get filtroMusica;

  /// Filtro de RTS
  ///
  /// In en, this message translates to:
  /// **'RTS'**
  String get filtroRts;

  /// Filtro de jogo de festa
  ///
  /// In en, this message translates to:
  /// **'Party game'**
  String get filtroJogoDeFesta;

  /// Filtro de engraçado
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get filtroEngracado;

  /// Filtro de romance
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get filtroRomance;

  /// Filtro de anime
  ///
  /// In en, this message translates to:
  /// **'Anime'**
  String get filtroAnime;

  /// Filtro erótico
  ///
  /// In en, this message translates to:
  /// **'Erotic'**
  String get filtroErotic;

  /// Texto do botão para o usuário assistir a um anúncio em vídeo para apoiar o app
  ///
  /// In en, this message translates to:
  /// **'🎥 Support by watching a video'**
  String get videoApoiar;

  /// Texto de carregamento exibido enquanto o anúncio em vídeo está sendo baixado
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get videoCarregando;

  /// Título do diálogo de agradecimento após o usuário assistir ao vídeo completo
  ///
  /// In en, this message translates to:
  /// **'Thank you so much!'**
  String get videoObrigadoTitulo;

  /// Mensagem de agradecimento explicando o impacto do apoio do usuário
  ///
  /// In en, this message translates to:
  /// **'Your support helps keep the app running.'**
  String get videoObrigadoMensagem;

  /// Mensagem de erro disparada quando o anúncio falha ao carregar devido à internet
  ///
  /// In en, this message translates to:
  /// **'Failed to load the video. Check your connection and try again.'**
  String get videoErroCarregar;

  /// Mensagem de erro quando o vídeo é carregado mas falha na hora de reproduzir
  ///
  /// In en, this message translates to:
  /// **'Could not display the video. Try again.'**
  String get videoErroExibicao;

  /// Aviso exibido quando a rede do AdMob não tem nenhum anúncio em vídeo para entregar
  ///
  /// In en, this message translates to:
  /// **'Ad is not available at the moment.'**
  String get videoIndisponivel;

  /// Palavra genérica utilizada para indicar um erro no aplicativo
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get erro;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
