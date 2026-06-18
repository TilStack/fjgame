// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'FJ Game';

  @override
  String get tagline => 'Do you know the Word?';

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get registerButton => 'Create account';

  @override
  String get playAsGuest => 'Play as guest';

  @override
  String get guestDisclaimer =>
      'Without an account, your progress will not be saved';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyAccount => 'Already have an account?';

  @override
  String get signIn => 'Sign in';

  @override
  String get orSeparator => 'or';

  @override
  String get emailRequired => 'Email address is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Minimum 6 characters';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get emailAlreadyInUse => 'This email is already in use';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get userNotFound => 'No account associated with this email';

  @override
  String get networkError => 'Check your internet connection';

  @override
  String get errorGeneric => 'An error occurred. Please try again.';

  @override
  String get loading => 'Loading...';

  @override
  String get logout => 'Sign out';

  @override
  String get welcomeGuest => 'Welcome, Guest';

  @override
  String welcomeUser(String name) {
    return 'Welcome, $name';
  }

  @override
  String get themeLight => 'Light mode';

  @override
  String get themeDark => 'Dark mode';

  @override
  String get themeSystem => 'System';

  @override
  String get languageFr => 'Français';

  @override
  String get languageEn => 'English';

  @override
  String get badgeGuest => 'Guest';

  @override
  String get badgeConnected => 'Connected';

  @override
  String get gameComingSoon => 'The game screen is coming soon...';
}
