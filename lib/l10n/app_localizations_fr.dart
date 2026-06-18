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
}
