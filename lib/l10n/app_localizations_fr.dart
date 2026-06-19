// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'FJ Game';

  @override
  String get tagline => 'Connais-tu la Parole ?';

  @override
  String get login => 'Connexion';

  @override
  String get register => 'Inscription';

  @override
  String get email => 'Adresse e-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get loginButton => 'Se connecter';

  @override
  String get registerButton => 'Créer un compte';

  @override
  String get playAsGuest => 'Jouer en invité';

  @override
  String get guestDisclaimer =>
      'Sans compte, votre progression ne sera pas sauvegardée';

  @override
  String get noAccount => 'Pas encore de compte ?';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get alreadyAccount => 'Déjà un compte ?';

  @override
  String get signIn => 'Se connecter';

  @override
  String get orSeparator => 'ou';

  @override
  String get emailRequired => 'L\'adresse e-mail est requise';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get passwordTooShort => 'Minimum 6 caractères';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get invalidEmail => 'Adresse e-mail invalide';

  @override
  String get emailAlreadyInUse => 'Cette adresse est déjà utilisée';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get userNotFound => 'Aucun compte associé à cet e-mail';

  @override
  String get networkError => 'Vérifiez votre connexion internet';

  @override
  String get errorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String get loading => 'Chargement...';

  @override
  String get logout => 'Déconnexion';

  @override
  String get welcomeGuest => 'Bienvenue, Invité';

  @override
  String welcomeUser(String name) {
    return 'Bienvenue, $name';
  }

  @override
  String get themeLight => 'Mode clair';

  @override
  String get themeDark => 'Mode sombre';

  @override
  String get themeSystem => 'Système';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get badgeGuest => 'Invité';

  @override
  String get badgeConnected => 'Connecté';

  @override
  String get gameComingSoon => 'L\'écran de jeu arrive bientôt...';

  @override
  String get playLocal => 'Jouer en local';

  @override
  String get playOnline => 'Jouer en ligne';

  @override
  String get players => 'Joueurs';

  @override
  String get addPlayer => 'Ajouter un joueur';

  @override
  String get removePlayer => 'Supprimer';

  @override
  String playerName(int number) {
    return 'Nom du joueur $number';
  }

  @override
  String get minPlayers => 'Minimum 3 joueurs requis';

  @override
  String get maxPlayers => 'Maximum 6 joueurs';

  @override
  String get startGame => 'Lancer la partie';

  @override
  String get passPhone => 'Passe le téléphone à';

  @override
  String get iAmReady => 'Je suis prêt';

  @override
  String get myHand => 'Ma main';

  @override
  String get chooseFamily => 'Quelle famille ?';

  @override
  String get chooseDescriptor => 'Quelle description allez-vous demander ?';

  @override
  String get chooseTarget => 'À qui allez-vous demander ?';

  @override
  String get askButton => 'Demander !';

  @override
  String get successTitle => 'Bonne réponse !';

  @override
  String get failTitle => 'Raté !';

  @override
  String successMessage(String targetName, String personnageName) {
    return '$targetName t\'a donné la carte de $personnageName';
  }

  @override
  String failMessage(String targetName) {
    return '$targetName n\'avait pas cette carte';
  }

  @override
  String familyCompleted(String familyName) {
    return 'Famille $familyName complétée !';
  }

  @override
  String get continueButton => 'Continuer';

  @override
  String get gameOver => 'Partie terminée !';

  @override
  String get finalRanking => 'Classement final';

  @override
  String get families => 'familles';

  @override
  String get playAgain => 'Rejouer';

  @override
  String get backHome => 'Accueil';

  @override
  String get yourTurn => 'C\'est ton tour';

  @override
  String cardsInHand(int count) {
    return '$count carte(s) en main';
  }

  @override
  String get completedFamilies => 'Familles posées';

  @override
  String get score => 'Score';

  @override
  String get identifiant => 'Identifiant';

  @override
  String get cle => 'Clé';

  @override
  String get youReplay => 'Tu rejoues !';

  @override
  String get scores => 'Scores';

  @override
  String familiesCount(int count) {
    return '$count famille(s)';
  }

  @override
  String get distributing => 'Distribution en cours...';

  @override
  String get skipAnimation => 'Passer';

  @override
  String get familyReveal => 'Famille complétée !';

  @override
  String get tapToReveal => 'Appuie pour voir ta carte';

  @override
  String get pseudo => 'Pseudo';

  @override
  String get pseudoHint => '@mon_pseudo';

  @override
  String get pseudoRequired => 'Le pseudo est requis';

  @override
  String get pseudoTooShort => 'Minimum 3 caractères';

  @override
  String get pseudoInvalid => 'Lettres, chiffres et _ uniquement';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get forgotPasswordExplain => 'Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get resetPasswordSent => 'Lien envoyé, vérifiez votre boîte mail';

  @override
  String get comingSoon => 'Bientôt';

  @override
  String get settings => 'Paramètres';

  @override
  String get appVersion => 'FJ Game v1.0.0';

  @override
  String get onlineStatus => 'En ligne';

  @override
  String get offlineStatus => 'Hors ligne';

  @override
  String get tapCard => 'Appuie sur une carte pour la voir';

  @override
  String get soundOn => 'Sons activés';

  @override
  String get soundOff => 'Sons désactivés';

  @override
  String get closeCard => 'Appuie pour fermer';
}
