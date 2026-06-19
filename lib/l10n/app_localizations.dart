import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'FJ Game'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'Connais-tu la Parole ?'**
  String get tagline;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get register;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get loginButton;

  /// No description provided for @registerButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get registerButton;

  /// No description provided for @playAsGuest.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en invité'**
  String get playAsGuest;

  /// No description provided for @guestDisclaimer.
  ///
  /// In fr, this message translates to:
  /// **'Sans compte, votre progression ne sera pas sauvegardée'**
  String get guestDisclaimer;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @orSeparator.
  ///
  /// In fr, this message translates to:
  /// **'ou'**
  String get orSeparator;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'adresse e-mail est requise'**
  String get emailRequired;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est requis'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse e-mail invalide'**
  String get invalidEmail;

  /// No description provided for @emailAlreadyInUse.
  ///
  /// In fr, this message translates to:
  /// **'Cette adresse est déjà utilisée'**
  String get emailAlreadyInUse;

  /// No description provided for @wrongPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect'**
  String get wrongPassword;

  /// No description provided for @userNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun compte associé à cet e-mail'**
  String get userNotFound;

  /// No description provided for @networkError.
  ///
  /// In fr, this message translates to:
  /// **'Vérifiez votre connexion internet'**
  String get networkError;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue. Réessayez.'**
  String get errorGeneric;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @welcomeGuest.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, Invité'**
  String get welcomeGuest;

  /// No description provided for @welcomeUser.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue, {name}'**
  String welcomeUser(String name);

  /// No description provided for @themeLight.
  ///
  /// In fr, this message translates to:
  /// **'Mode clair'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get themeDark;

  /// No description provided for @themeSystem.
  ///
  /// In fr, this message translates to:
  /// **'Système'**
  String get themeSystem;

  /// No description provided for @languageFr.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFr;

  /// No description provided for @languageEn.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @badgeGuest.
  ///
  /// In fr, this message translates to:
  /// **'Invité'**
  String get badgeGuest;

  /// No description provided for @badgeConnected.
  ///
  /// In fr, this message translates to:
  /// **'Connecté'**
  String get badgeConnected;

  /// No description provided for @gameComingSoon.
  ///
  /// In fr, this message translates to:
  /// **'L\'écran de jeu arrive bientôt...'**
  String get gameComingSoon;

  /// No description provided for @playLocal.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en local'**
  String get playLocal;

  /// No description provided for @playOnline.
  ///
  /// In fr, this message translates to:
  /// **'Jouer en ligne'**
  String get playOnline;

  /// No description provided for @players.
  ///
  /// In fr, this message translates to:
  /// **'Joueurs'**
  String get players;

  /// No description provided for @addPlayer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un joueur'**
  String get addPlayer;

  /// No description provided for @removePlayer.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get removePlayer;

  /// No description provided for @playerName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du joueur {number}'**
  String playerName(int number);

  /// No description provided for @minPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 3 joueurs requis'**
  String get minPlayers;

  /// No description provided for @maxPlayers.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 6 joueurs'**
  String get maxPlayers;

  /// No description provided for @startGame.
  ///
  /// In fr, this message translates to:
  /// **'Lancer la partie'**
  String get startGame;

  /// No description provided for @passPhone.
  ///
  /// In fr, this message translates to:
  /// **'Passe le téléphone à'**
  String get passPhone;

  /// No description provided for @iAmReady.
  ///
  /// In fr, this message translates to:
  /// **'Je suis prêt'**
  String get iAmReady;

  /// No description provided for @myHand.
  ///
  /// In fr, this message translates to:
  /// **'Ma main'**
  String get myHand;

  /// No description provided for @chooseFamily.
  ///
  /// In fr, this message translates to:
  /// **'Quelle famille ?'**
  String get chooseFamily;

  /// No description provided for @chooseDescriptor.
  ///
  /// In fr, this message translates to:
  /// **'Quelle description allez-vous demander ?'**
  String get chooseDescriptor;

  /// No description provided for @chooseTarget.
  ///
  /// In fr, this message translates to:
  /// **'À qui allez-vous demander ?'**
  String get chooseTarget;

  /// No description provided for @askButton.
  ///
  /// In fr, this message translates to:
  /// **'Demander !'**
  String get askButton;

  /// No description provided for @successTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bonne réponse !'**
  String get successTitle;

  /// No description provided for @failTitle.
  ///
  /// In fr, this message translates to:
  /// **'Raté !'**
  String get failTitle;

  /// No description provided for @successMessage.
  ///
  /// In fr, this message translates to:
  /// **'{targetName} t\'a donné la carte de {personnageName}'**
  String successMessage(String targetName, String personnageName);

  /// No description provided for @failMessage.
  ///
  /// In fr, this message translates to:
  /// **'{targetName} n\'avait pas cette carte'**
  String failMessage(String targetName);

  /// No description provided for @familyCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Famille {familyName} complétée !'**
  String familyCompleted(String familyName);

  /// No description provided for @continueButton.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueButton;

  /// No description provided for @gameOver.
  ///
  /// In fr, this message translates to:
  /// **'Partie terminée !'**
  String get gameOver;

  /// No description provided for @finalRanking.
  ///
  /// In fr, this message translates to:
  /// **'Classement final'**
  String get finalRanking;

  /// No description provided for @families.
  ///
  /// In fr, this message translates to:
  /// **'familles'**
  String get families;

  /// No description provided for @playAgain.
  ///
  /// In fr, this message translates to:
  /// **'Rejouer'**
  String get playAgain;

  /// No description provided for @backHome.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get backHome;

  /// No description provided for @yourTurn.
  ///
  /// In fr, this message translates to:
  /// **'C\'est ton tour'**
  String get yourTurn;

  /// No description provided for @cardsInHand.
  ///
  /// In fr, this message translates to:
  /// **'{count} carte(s) en main'**
  String cardsInHand(int count);

  /// No description provided for @completedFamilies.
  ///
  /// In fr, this message translates to:
  /// **'Familles posées'**
  String get completedFamilies;

  /// No description provided for @score.
  ///
  /// In fr, this message translates to:
  /// **'Score'**
  String get score;

  /// No description provided for @identifiant.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get identifiant;

  /// No description provided for @cle.
  ///
  /// In fr, this message translates to:
  /// **'Clé'**
  String get cle;

  /// No description provided for @youReplay.
  ///
  /// In fr, this message translates to:
  /// **'Tu rejoues !'**
  String get youReplay;

  /// No description provided for @scores.
  ///
  /// In fr, this message translates to:
  /// **'Scores'**
  String get scores;

  /// No description provided for @familiesCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} famille(s)'**
  String familiesCount(int count);

  /// No description provided for @distributing.
  ///
  /// In fr, this message translates to:
  /// **'Distribution en cours...'**
  String get distributing;

  /// No description provided for @skipAnimation.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get skipAnimation;

  /// No description provided for @familyReveal.
  ///
  /// In fr, this message translates to:
  /// **'Famille complétée !'**
  String get familyReveal;

  /// No description provided for @tapToReveal.
  ///
  /// In fr, this message translates to:
  /// **'Appuie pour voir ta carte'**
  String get tapToReveal;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
