# Phase 5 — Design & UX Refonte Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refonte design et UX complète (AppBar, auth, home, lobby, cartes, sons, animations) sans toucher GameEngine/GameNotifier.

**Architecture:** Chaque tâche est indépendante sauf les dépendances explicites (SoundService avant SettingsBottomSheet, i18n avant toute UI). Les écrans de jeu reçoivent un Theme local pour l'AppBar neutre. La nouvelle interaction cartes (grille + overlay peek) remplace la liste verticale de la main.

**Tech Stack:** Flutter 3.22+, Dart 3.4+, flutter_animate ^4.5.0, audioplayers ^6.0.0, flutter_svg ^2.0.10, Riverpod ^2.5.1, go_router ^14.2.7, SharedPreferences, cloud_firestore ^5.x

## Global Constraints

- `flutter analyze` : zéro issue après chaque tâche
- Zéro string hardcodée — tout via AppLocalizations
- SoundService : try/catch silencieux, ne crashe jamais
- Toutes animations flutter_animate : vérifier `MediaQuery.of(context).disableAnimations` → `Duration.zero`
- GameEngine et GameNotifier : non modifiés
- Tout nouveau fichier Dart : commentaire d'en-tête français en première ligne
- `flutter pub get` après modification de pubspec.yaml

---

## File Structure

### Nouveaux fichiers à créer
```
lib/core/services/sound_service.dart          — Singleton AudioPlayer + SharedPrefs
lib/presentation/widgets/common/settings_bottom_sheet.dart — Thème/langue/sons
lib/presentation/widgets/home/home_animation_widget.dart   — 4 cartes éventail flutter_animate
lib/presentation/widgets/game/carte_mini_widget.dart       — Mini carte dos (grille)
lib/presentation/widgets/game/player_hand_grid_widget.dart — Grille 2 colonnes de CarteMini
lib/presentation/widgets/game/card_peek_overlay.dart       — Overlay peek + flip
lib/presentation/screens/auth/forgot_password_screen.dart  — Reset mot de passe
assets/images/game_bg_pattern.svg                          — Motif croix 60×60
assets/sounds/card_flip.mp3   (stub vide)
assets/sounds/card_deal.mp3   (stub vide)
assets/sounds/success.mp3     (stub vide)
assets/sounds/fail.mp3        (stub vide)
assets/sounds/family_complete.mp3 (stub vide)
assets/sounds/game_win.mp3    (stub vide)
assets/sounds/button_tap.mp3  (stub vide)
```

### Fichiers modifiés
```
pubspec.yaml                                    — +audioplayers, +flutter_animate, +cloud_firestore, +assets/sounds/
lib/l10n/app_fr.arb + app_en.arb               — 21 nouvelles clés
lib/l10n/app_localizations.dart + _fr + _en    — implémentation des nouvelles clés
lib/domain/models/app_user.dart                — +pseudo, +avatarColor
lib/application/providers/auth_provider.dart   — registerWithEmail accepte pseudo, écrit Firestore
lib/core/theme/app_theme.dart                  — AppBarTheme neutre pour jeu, exposé comme const
lib/core/router/app_router.dart                — +route /forgot-password, gardes inchangées
lib/presentation/screens/auth/login_screen.dart         — +lien oublié, -toggles thème/langue
lib/presentation/screens/auth/register_screen.dart      — +champ pseudo, -toggles thème/langue
lib/presentation/screens/home/home_screen.dart          — redesign complet (ConsumerStatefulWidget)
lib/presentation/screens/game/lobby_local_screen.dart   — redesign layout + animations
lib/presentation/widgets/game/carte_personnage_widget.dart — face redessinée (F1)
lib/presentation/widgets/game/distribution_animation_widget.dart — +playCardDeal
lib/presentation/screens/game/game_screen.dart          — grille + fond pattern
lib/presentation/screens/game/resultat_tour_screen.dart — fan CarteMini + sons
lib/presentation/screens/game/transition_screen.dart    — SVG animé inline
lib/presentation/screens/game/fin_partie_screen.dart    — badges colorés flutter_animate
lib/presentation/screens/splash/splash_screen.dart      — flutter_animate fadeIn+scale
lib/presentation/widgets/common/primary_button.dart     — +playButtonTap au onPressed
```

---

## Task 1: Dépendances & assets sons

**Files:**
- Modify: `pubspec.yaml`
- Create: `assets/sounds/card_flip.mp3`, `card_deal.mp3`, `success.mp3`, `fail.mp3`, `family_complete.mp3`, `game_win.mp3`, `button_tap.mp3`

**Interfaces:**
- Produces: packages `audioplayers`, `flutter_animate`, `cloud_firestore` disponibles; dossier `assets/sounds/` déclaré

- [ ] **Step 1: Ajouter les dépendances dans pubspec.yaml**

Dans la section `dependencies:`, ajouter après `flutter_svg: ^2.0.10` :
```yaml
  audioplayers: ^6.0.0
  flutter_animate: ^4.5.0
  cloud_firestore: ^5.5.0
```
Dans `flutter.assets:`, ajouter après `- assets/images/` :
```yaml
    - assets/sounds/
```

- [ ] **Step 2: Créer les stubs sons vides**

```bash
mkdir -p /home/tilstack/Bureau/fjgame/assets/sounds
touch assets/sounds/card_flip.mp3 assets/sounds/card_deal.mp3 \
      assets/sounds/success.mp3 assets/sounds/fail.mp3 \
      assets/sounds/family_complete.mp3 assets/sounds/game_win.mp3 \
      assets/sounds/button_tap.mp3
```

- [ ] **Step 3: Installer les packages**

```bash
cd /home/tilstack/Bureau/fjgame && flutter pub get
```
Expected: exit 0, no dependency conflicts.

- [ ] **Step 4: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 2: Nouvelles clés i18n

**Files:**
- Modify: `lib/l10n/app_fr.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_fr.dart`
- Modify: `lib/l10n/app_localizations_en.dart`

**Interfaces:**
- Produces: `l10n.pseudo`, `l10n.pseudoHint`, `l10n.pseudoRequired`, `l10n.pseudoTooShort`, `l10n.pseudoInvalid`, `l10n.forgotPassword`, `l10n.forgotPasswordExplain`, `l10n.sendResetLink`, `l10n.resetPasswordSent`, `l10n.comingSoon`, `l10n.settings`, `l10n.appVersion`, `l10n.onlineStatus`, `l10n.offlineStatus`, `l10n.tapCard`, `l10n.soundOn`, `l10n.soundOff`, `l10n.closeCard`, `l10n.playOnline` (déjà présent), `l10n.pseudoHint`

- [ ] **Step 1: Ajouter dans app_fr.arb** (avant le `}` final)

```json
  "pseudo": "Pseudo",
  "pseudoHint": "@mon_pseudo",
  "pseudoRequired": "Le pseudo est requis",
  "pseudoTooShort": "Minimum 3 caractères",
  "pseudoInvalid": "Lettres, chiffres et _ uniquement",
  "forgotPassword": "Mot de passe oublié ?",
  "forgotPasswordExplain": "Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe",
  "sendResetLink": "Envoyer le lien",
  "resetPasswordSent": "Lien envoyé, vérifiez votre boîte mail",
  "comingSoon": "Bientôt",
  "settings": "Paramètres",
  "appVersion": "FJ Game v1.0.0",
  "onlineStatus": "En ligne",
  "offlineStatus": "Hors ligne",
  "tapCard": "Appuie sur une carte pour la voir",
  "soundOn": "Sons activés",
  "soundOff": "Sons désactivés",
  "closeCard": "Appuie pour fermer"
```

- [ ] **Step 2: Ajouter dans app_en.arb** (avant le `}` final)

```json
  "pseudo": "Username",
  "pseudoHint": "@my_username",
  "pseudoRequired": "Username is required",
  "pseudoTooShort": "Minimum 3 characters",
  "pseudoInvalid": "Letters, numbers and _ only",
  "forgotPassword": "Forgot password?",
  "forgotPasswordExplain": "Enter your email address and we will send you a link to reset your password",
  "sendResetLink": "Send link",
  "resetPasswordSent": "Link sent, check your inbox",
  "comingSoon": "Soon",
  "settings": "Settings",
  "appVersion": "FJ Game v1.0.0",
  "onlineStatus": "Online",
  "offlineStatus": "Offline",
  "tapCard": "Tap a card to see it",
  "soundOn": "Sounds enabled",
  "soundOff": "Sounds disabled",
  "closeCard": "Tap to close"
```

- [ ] **Step 3: Ajouter les abstracts dans app_localizations.dart**

Dans la classe `AppLocalizations`, ajouter après `String get tapToReveal;` :
```dart
  String get pseudo;
  String get pseudoHint;
  String get pseudoRequired;
  String get pseudoTooShort;
  String get pseudoInvalid;
  String get forgotPassword;
  String get forgotPasswordExplain;
  String get sendResetLink;
  String get resetPasswordSent;
  String get comingSoon;
  String get settings;
  String get appVersion;
  String get onlineStatus;
  String get offlineStatus;
  String get tapCard;
  String get soundOn;
  String get soundOff;
  String get closeCard;
```

- [ ] **Step 4: Implémenter dans app_localizations_fr.dart**

Ajouter après `String get tapToReveal => 'Appuie pour voir ta carte';` :
```dart
  @override String get pseudo => 'Pseudo';
  @override String get pseudoHint => '@mon_pseudo';
  @override String get pseudoRequired => 'Le pseudo est requis';
  @override String get pseudoTooShort => 'Minimum 3 caractères';
  @override String get pseudoInvalid => 'Lettres, chiffres et _ uniquement';
  @override String get forgotPassword => 'Mot de passe oublié ?';
  @override String get forgotPasswordExplain => 'Entrez votre adresse e-mail, nous vous enverrons un lien pour réinitialiser votre mot de passe';
  @override String get sendResetLink => 'Envoyer le lien';
  @override String get resetPasswordSent => 'Lien envoyé, vérifiez votre boîte mail';
  @override String get comingSoon => 'Bientôt';
  @override String get settings => 'Paramètres';
  @override String get appVersion => 'FJ Game v1.0.0';
  @override String get onlineStatus => 'En ligne';
  @override String get offlineStatus => 'Hors ligne';
  @override String get tapCard => 'Appuie sur une carte pour la voir';
  @override String get soundOn => 'Sons activés';
  @override String get soundOff => 'Sons désactivés';
  @override String get closeCard => 'Appuie pour fermer';
```

- [ ] **Step 5: Implémenter dans app_localizations_en.dart**

Ajouter après `String get tapToReveal => 'Tap to reveal your card';` :
```dart
  @override String get pseudo => 'Username';
  @override String get pseudoHint => '@my_username';
  @override String get pseudoRequired => 'Username is required';
  @override String get pseudoTooShort => 'Minimum 3 characters';
  @override String get pseudoInvalid => 'Letters, numbers and _ only';
  @override String get forgotPassword => 'Forgot password?';
  @override String get forgotPasswordExplain => 'Enter your email address and we will send you a link to reset your password';
  @override String get sendResetLink => 'Send link';
  @override String get resetPasswordSent => 'Link sent, check your inbox';
  @override String get comingSoon => 'Soon';
  @override String get settings => 'Settings';
  @override String get appVersion => 'FJ Game v1.0.0';
  @override String get onlineStatus => 'Online';
  @override String get offlineStatus => 'Offline';
  @override String get tapCard => 'Tap a card to see it';
  @override String get soundOn => 'Sounds enabled';
  @override String get soundOff => 'Sounds disabled';
  @override String get closeCard => 'Tap to close';
```

- [ ] **Step 6: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 3: SoundService singleton

**Files:**
- Create: `lib/core/services/sound_service.dart`

**Interfaces:**
- Consumes: `audioplayers`, `shared_preferences`
- Produces: `SoundService.instance` avec méthodes `playCardFlip()`, `playCardDeal()`, `playSuccess()`, `playFail()`, `playFamilyComplete()`, `playGameWin()`, `playButtonTap()`, `setEnabled(bool)`, getter `enabled`

- [ ] **Step 1: Créer lib/core/services/sound_service.dart**

```dart
// Service de sons singleton. Joue les MP3 depuis assets/sounds/.
// Silencieux si le fichier est absent ou si enabled == false.

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _enabled = true;

  bool get enabled => _enabled;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sound_enabled') ?? true;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_enabled', value);
  }

  Future<void> _play(String file) async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/$file'));
    } catch (_) {}
  }

  Future<void> playCardFlip() => _play('card_flip.mp3');
  Future<void> playCardDeal() => _play('card_deal.mp3');
  Future<void> playSuccess() => _play('success.mp3');
  Future<void> playFail() => _play('fail.mp3');
  Future<void> playFamilyComplete() => _play('family_complete.mp3');
  Future<void> playGameWin() => _play('game_win.mp3');
  Future<void> playButtonTap() => _play('button_tap.mp3');
}
```

- [ ] **Step 2: Initialiser dans main.dart**

Dans `main()`, avant `runApp`, ajouter :
```dart
await SoundService.instance.init();
```
Ajouter l'import :
```dart
import 'core/services/sound_service.dart';
```

- [ ] **Step 3: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 4: AppUser model + AuthNotifier (pseudo + Firestore)

**Files:**
- Modify: `lib/domain/models/app_user.dart`
- Modify: `lib/application/providers/auth_provider.dart`

**Interfaces:**
- Consumes: `cloud_firestore`, `firebase_auth`
- Produces: `AppUser` avec `pseudo` (String), `avatarColor` (String); `AuthNotifier.registerWithEmail(email, password, pseudo)`

- [ ] **Step 1: Réécrire lib/domain/models/app_user.dart**

```dart
// Modèle de domaine représentant l'utilisateur authentifié ou anonyme.
// pseudo : displayName Firebase Auth, sinon partie email avant @, sinon "Invité".
// avatarColor : couleur Firestore ou rouge primaire par défaut.

import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    required this.isAnonymous,
    required this.pseudo,
    required this.avatarColor,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
  final String pseudo;
  final String avatarColor;

  static const List<String> _avatarColors = [
    '#FF1744', '#1E88E5', '#43A047', '#FB8C00', '#8E24AA', '#00ACC1',
  ];

  factory AppUser.fromFirebaseUser(User user, {String? avatarColor}) {
    final pseudo = _resolvePseudo(user);
    return AppUser(
      uid: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
      pseudo: pseudo,
      avatarColor: avatarColor ?? _avatarColors[0],
    );
  }

  static String _resolvePseudo(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'Invité';
  }

  // Compatibilité avec le code existant
  String get displayName => pseudo;
}
```

- [ ] **Step 2: Mettre à jour auth_provider.dart**

Ajouter l'import Firestore en haut :
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
```

Modifier `registerWithEmail` pour accepter `pseudo` et écrire Firestore :
```dart
  Future<void> registerWithEmail(
      String email, String password, String pseudo) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final colors = [
        '#FF1744', '#1E88E5', '#43A047', '#FB8C00', '#8E24AA', '#00ACC1',
      ];
      final avatarColor = colors[DateTime.now().millisecondsSinceEpoch % 6];

      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      await cred.user?.updateDisplayName(pseudo);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'pseudo': pseudo,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'avatarColor': avatarColor,
      });
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: mapFirebaseAuthError(e.code),
      );
    }
  }
```

- [ ] **Step 3: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 5: ForgotPasswordScreen + route

**Files:**
- Create: `lib/presentation/screens/auth/forgot_password_screen.dart`
- Modify: `lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: `firebase_auth`, `l10n.forgotPassword`, `l10n.forgotPasswordExplain`, `l10n.sendResetLink`, `l10n.resetPasswordSent`, `mapFirebaseAuthError`
- Produces: route `/forgot-password` accessible sans garde

- [ ] **Step 1: Créer forgot_password_screen.dart**

```dart
// Écran de réinitialisation de mot de passe via Firebase Auth.
// Envoie un email de reset et redirige vers /login après succès.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/firebase_error_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset(AppLocalizations l10n) async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.resetPasswordSent),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) context.go('/login');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(mapFirebaseAuthError(e.code)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forgotPassword),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.lock_reset, size: 64, color: primary),
            const SizedBox(height: 24),
            Text(
              l10n.forgotPassword,
              textAlign: TextAlign.center,
              style: AppTextStyles.cinzel(fontSize: 22, color: primary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.forgotPasswordExplain,
              textAlign: TextAlign.center,
              style: AppTextStyles.inter(fontSize: 13, color: textSecondary),
            ),
            const SizedBox(height: 32),
            AppTextField(
              controller: _emailCtrl,
              labelText: l10n.email,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n.sendResetLink,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : () => _sendReset(l10n),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Ajouter la route dans app_router.dart**

Dans la liste `routes:`, après la route `/register` :
```dart
GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
```
Ajouter l'import :
```dart
import '../../presentation/screens/auth/forgot_password_screen.dart';
```

- [ ] **Step 3: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 6: AppTheme AppBar neutre + wrapper pour écrans jeu

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

**Interfaces:**
- Produces: `AppTheme.gameAppBarThemeLight` (AppBarTheme), `AppTheme.gameAppBarThemeDark` (AppBarTheme), utilisés par un Theme local dans chaque écran de jeu

Note: Le wrapper `Theme(data: ..., child: Scaffold(...))` sera ajouté directement dans chaque écran de jeu concerné (LobbyLocalScreen, TransitionScreen, GameScreen, ResultatTourScreen, FinPartieScreen) lors de leurs tâches respectives. Ici on expose seulement les constantes.

- [ ] **Step 1: Ajouter dans app_theme.dart les AppBarThemes de jeu**

Ajouter dans la classe `AppTheme`, après `get darkTheme` :

```dart
  static const AppBarTheme gameAppBarThemeLight = AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A), // AppColors.lightTextPrimary
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static const AppBarTheme gameAppBarThemeDark = AppBarTheme(
    backgroundColor: Color(0xFF0D0D14), // AppColors.darkBackground
    foregroundColor: Color(0xFFE0E0E0), // AppColors.darkTextPrimary
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );
```

Ajouter l'import manquant en haut de app_theme.dart :
```dart
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 7: SettingsBottomSheet

**Files:**
- Create: `lib/presentation/widgets/common/settings_bottom_sheet.dart`

**Interfaces:**
- Consumes: `ThemeNotifier`, `LocaleNotifier`, `SoundService.instance`, `l10n.settings`, `l10n.themeLight`, `l10n.themeDark`, `l10n.themeSystem`, `l10n.languageFr`, `l10n.languageEn`, `l10n.soundOn`, `l10n.soundOff`, `l10n.appVersion`
- Produces: `SettingsBottomSheet.show(context)` méthode statique

- [ ] **Step 1: Créer settings_bottom_sheet.dart**

```dart
// BottomSheet de paramètres : thème, langue, sons. Accessible depuis HomeScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers/locale_provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/sound_service.dart';
import '../../../l10n/app_localizations.dart';

class SettingsBottomSheet extends ConsumerStatefulWidget {
  const SettingsBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProviderScope.containerOf(context, listen: false)
          .let((c) => UncontrolledProviderScope(
                container: c,
                child: const SettingsBottomSheet(),
              )),
    );
  }

  @override
  ConsumerState<SettingsBottomSheet> createState() =>
      _SettingsBottomSheetState();
}

class _SettingsBottomSheetState extends ConsumerState<SettingsBottomSheet> {
  bool _soundEnabled = SoundService.instance.enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settings,
              style: AppTextStyles.cinzel(fontSize: 20, color: primary),
            ),
            const SizedBox(height: 20),

            // Thème
            Text(l10n.themeLight.replaceAll('Mode ', '').isEmpty
                ? 'Thème'
                : 'Thème',
              style: AppTextStyles.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeNotifierProvider.notifier).setTheme(s.first),
              style: ButtonStyle(
                textStyle: WidgetStateProperty.all(
                    AppTextStyles.inter(fontSize: 11, color: primary)),
              ),
            ),
            const SizedBox(height: 20),

            // Langue
            Text('Langue', style: AppTextStyles.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            SegmentedButton<Locale>(
              segments: [
                ButtonSegment(
                  value: const Locale('fr'),
                  label: Text(l10n.languageFr),
                ),
                ButtonSegment(
                  value: const Locale('en'),
                  label: Text(l10n.languageEn),
                ),
              ],
              selected: {locale},
              onSelectionChanged: (s) =>
                  ref.read(localeNotifierProvider.notifier).setLocale(s.first),
            ),
            const SizedBox(height: 8),

            // Sons
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _soundEnabled ? l10n.soundOn : l10n.soundOff,
                style: AppTextStyles.inter(fontSize: 14),
              ),
              value: _soundEnabled,
              activeColor: primary,
              onChanged: (v) {
                setState(() => _soundEnabled = v);
                SoundService.instance.setEnabled(v);
              },
            ),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.appVersion,
                style: AppTextStyles.inter(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

Note: `ProviderScope.containerOf` + `UncontrolledProviderScope` permet de partager le même container Riverpod depuis le contexte parent vers le BottomSheet. Si cette approche génère une erreur, utiliser directement le `WidgetRef` passé via closure.

Alternative plus simple (si l'approche ci-dessus échoue) :
```dart
  static void show(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _SettingsBottomSheetContent(ref: ref),
    );
  }
```

- [ ] **Step 2: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!` — si erreur sur `ProviderScope.containerOf`, utiliser l'alternative avec `WidgetRef ref`.

---

## Task 8: HomeScreen redesign + HomeAnimationWidget

**Files:**
- Create: `lib/presentation/widgets/home/home_animation_widget.dart`
- Rewrite: `lib/presentation/screens/home/home_screen.dart`

**Interfaces:**
- Consumes: `AppUser` (pseudo, avatarColor, isAnonymous), `AuthNotifier`, `ThemeNotifier`, `SettingsBottomSheet.show`, `flutter_animate`, `l10n.playLocal`, `l10n.playOnline`, `l10n.comingSoon`, `l10n.onlineStatus`, `l10n.tapCard`, `l10n.settings`, `l10n.signUp`
- Produces: HomeScreen redesigné avec animation éventail + statut utilisateur

- [ ] **Step 1: Créer home_animation_widget.dart**

```dart
// Widget d'animation de l'écran d'accueil : 4 cartes en éventail animé.
// Utilise flutter_animate avec repeat + reverse.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class HomeAnimationWidget extends StatelessWidget {
  const HomeAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final cardColor =
        isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    // offsets et angles pour l'éventail
    const configs = [
      (dx: -70.0, dy: -50.0, angle: -0.26), // -15°
      (dx:  70.0, dy: -50.0, angle:  0.26), //  15°
      (dx: -50.0, dy:  40.0, angle: -0.14), //  -8°
      (dx:  50.0, dy:  40.0, angle:  0.14), //   8°
    ];

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(4, (i) {
                final cfg = configs[i];
                Widget card = _buildMiniCard(cardColor);
                if (!reduceMotion) {
                  card = card
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .moveX(
                        begin: 0,
                        end: cfg.dx,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .moveY(
                        begin: 0,
                        end: cfg.dy,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .rotate(
                        begin: 0,
                        end: cfg.angle,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      );
                } else {
                  card = Transform.translate(
                    offset: Offset(cfg.dx, cfg.dy),
                    child: Transform.rotate(angle: cfg.angle, child: card),
                  );
                }
                return card;
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appName,
            style: AppTextStyles.cinzel(
              fontSize: 28, color: primary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tagline,
            style: AppTextStyles.inter(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(Color color) {
    return Container(
      width: 28,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6, offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 1.5, height: 12, color: Colors.white70),
          Container(width: 12, height: 1.5, color: Colors.white70),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Réécrire home_screen.dart**

```dart
// Écran d'accueil redesigné : animation éventail, statut utilisateur, boutons d'action.
// SettingsBottomSheet accessible via icône engrenage.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/auth_provider.dart';
import '../../../application/providers/locale_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/settings_bottom_sheet.dart';
import '../../widgets/home/home_animation_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Zone haute : actions AppBar transparente
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                    ),
                    color: textSecondary,
                    onPressed: () =>
                        ref.read(themeNotifierProvider.notifier).setTheme(
                              themeMode == ThemeMode.dark
                                  ? ThemeMode.light
                                  : ThemeMode.dark,
                            ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    color: textSecondary,
                    onPressed: () => SettingsBottomSheet.show(context),
                  ),
                ],
              ),
            ),

            // Zone centrale
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const HomeAnimationWidget(),
                  const SizedBox(height: 32),

                  // Statut utilisateur
                  if (user != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _AvatarWidget(
                            pseudo: user.pseudo,
                            avatarColor: user.avatarColor,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.pseudo,
                                style: AppTextStyles.inter(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (!user.isAnonymous)
                                Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      l10n.onlineStatus,
                                      style: AppTextStyles.inter(
                                        fontSize: 11, color: AppColors.success),
                                    ),
                                  ],
                                )
                              else
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: Text(
                                    l10n.signUp,
                                    style: AppTextStyles.inter(
                                      fontSize: 11, color: primary),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        PrimaryButton(
                          label: l10n.playLocal,
                          onPressed: () => context.go('/lobby-local'),
                        ),
                        const SizedBox(height: 16),
                        // Jouer en ligne — Coming soon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Opacity(
                              opacity: 0.6,
                              child: PrimaryButton(
                                label: l10n.playOnline,
                                variant: PrimaryButtonVariant.outlined,
                                onPressed: null,
                              ),
                            ),
                            Positioned(
                              top: -6, right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l10n.comingSoon,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Zone basse : version
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.appVersion,
                style: AppTextStyles.inter(fontSize: 11, color: textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.pseudo, required this.avatarColor});
  final String pseudo;
  final String avatarColor;

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFF1744);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(avatarColor);
    final letter = pseudo.isNotEmpty ? pseudo[0].toUpperCase() : '?';
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 9: LoginScreen cleanup + RegisterScreen pseudo + game AppBar

**Files:**
- Modify: `lib/presentation/screens/auth/login_screen.dart`
- Modify: `lib/presentation/screens/auth/register_screen.dart`
- Modify: `lib/presentation/screens/game/lobby_local_screen.dart`
- Modify: `lib/presentation/screens/game/transition_screen.dart`
- Modify: `lib/presentation/screens/game/game_screen.dart`
- Modify: `lib/presentation/screens/game/resultat_tour_screen.dart`
- Modify: `lib/presentation/screens/game/fin_partie_screen.dart`

**Interfaces:**
- Consumes: `AppTheme.gameAppBarThemeLight/Dark`, `l10n.forgotPassword`, `l10n.pseudo`, `l10n.pseudoHint`, validation regex `^[a-z0-9_]{3,20}$`
- Produces: toggles retirés de login/register; pseudo field dans register; AppBar neutre dans 5 écrans jeu

- [ ] **Step 1: Modifier login_screen.dart**

Supprimer les actions de l'AppBar (les deux TextButton/IconButton pour langue et thème).
Ajouter après le champ mot de passe, avant la SizedBox(height: 24) :
```dart
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(
                    l10n.forgotPassword,
                    style: AppTextStyles.inter(
                        fontSize: 12, color: primary),
                  ),
                ),
              ),
```
Supprimer les imports inutiles `locale_provider.dart` et les variables `themeMode`/`locale` si elles n'ont plus d'usage.

- [ ] **Step 2: Modifier register_screen.dart**

Supprimer les actions de l'AppBar (toggles thème/langue).
Ajouter `_pseudoCtrl = TextEditingController()` et son dispose.
Ajouter le champ Pseudo en première position dans le formulaire :
```dart
              AppTextField(
                controller: _pseudoCtrl,
                labelText: l10n.pseudo,
                hintText: l10n.pseudoHint,
                prefixIcon: Icons.alternate_email,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.pseudoRequired;
                  if (v.trim().length < 3) return l10n.pseudoTooShort;
                  if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(v.trim())) {
                    return l10n.pseudoInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
```
Modifier l'appel `_register` pour passer le pseudo :
```dart
    await ref.read(authNotifierProvider.notifier).registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _pseudoCtrl.text.trim(),
        );
```

- [ ] **Step 3: AppBar neutre dans les 5 écrans de jeu**

Dans chaque fichier (lobby_local_screen.dart, transition_screen.dart, game_screen.dart, resultat_tour_screen.dart, fin_partie_screen.dart), envelopper le `Scaffold` dans :
```dart
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark
            ? AppTheme.gameAppBarThemeDark
            : AppTheme.gameAppBarThemeLight,
      ),
      child: Scaffold(
        // ... contenu existant identique ...
      ),
    );
```
Ajouter l'import `app_theme.dart` dans chacun de ces fichiers.

- [ ] **Step 4: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 10: LobbyLocalScreen redesign

**Files:**
- Rewrite: `lib/presentation/screens/game/lobby_local_screen.dart`

**Interfaces:**
- Consumes: `flutter_animate`, liste de 6 couleurs avatar, `l10n.startGame`, `l10n.addPlayer`, `l10n.playerName`
- Produces: layout centré avec champs animés fadeIn+slideY, avatar rond préfixe, suppression par icône Close

- [ ] **Step 1: Réécrire lobby_local_screen.dart**

```dart
// Écran de configuration de la partie locale : saisie des noms de joueurs (3–6).
// Champs animés avec flutter_animate. Avatar coloré en préfixe.
// Suppression par icône close avec slideX+fadeOut 200ms.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/game/distribution_animation_widget.dart';

class LobbyLocalScreen extends ConsumerStatefulWidget {
  const LobbyLocalScreen({super.key});

  @override
  ConsumerState<LobbyLocalScreen> createState() => _LobbyLocalScreenState();
}

class _LobbyLocalScreenState extends ConsumerState<LobbyLocalScreen> {
  final List<TextEditingController> _controllers = [];

  static const _avatarColors = [
    Color(0xFFFF1744), Color(0xFF1E88E5), Color(0xFF43A047),
    Color(0xFFFB8C00), Color(0xFF8E24AA), Color(0xFF00ACC1),
  ];

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 3; i++) _controllers.add(TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  void _addPlayer() {
    if (_controllers.length >= 6) return;
    setState(() => _controllers.add(TextEditingController()));
  }

  void _removePlayer(int index) {
    if (_controllers.length <= 3) return;
    setState(() {
      _controllers[index].dispose();
      _controllers.removeAt(index);
    });
  }

  Future<void> _startGame(AppLocalizations l10n) async {
    final noms = _controllers.map((c) => c.text.trim()).toList();
    if (noms.any((n) => n.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.minPlayers)));
      return;
    }
    await ref.read(gameNotifierProvider.notifier).demarrerPartieLocale(noms);
    if (!mounted) return;
    final state = ref.read(gameNotifierProvider);
    if (state.erreur != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.erreur!)));
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (dCtx) => DistributionAnimationWidget(
        nombreJoueurs: noms.length,
        nombreCartesTotal: 52,
        onAnimationComplete: () => Navigator.of(dCtx).pop(),
      ),
    );
    if (!mounted) return;
    context.go('/game/transition');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final isLoading = ref.watch(gameNotifierProvider).isLoading;
    final canAdd = _controllers.length < 6;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark
            ? AppTheme.gameAppBarThemeDark
            : AppTheme.gameAppBarThemeLight,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.playLocal),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.group, size: 48, color: primary)
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 16),
              Text(
                l10n.players,
                style: AppTextStyles.cinzel(fontSize: 22, color: primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '3 – 6',
                style: AppTextStyles.inter(fontSize: 12, color: textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Champs joueurs animés
              ...List.generate(_controllers.length, (i) {
                final avatarColor = _avatarColors[i % _avatarColors.length];
                final letter = String.fromCharCode(65 + i); // A, B, C...
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          decoration: InputDecoration(
                            labelText: l10n.playerName(i + 1),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(8),
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: avatarColor,
                                child: Text(
                                  letter,
                                  style: const TextStyle(
                                    fontFamily: 'Cinzel',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            suffixIcon: i >= 3
                                ? IconButton(
                                    icon: Icon(Icons.close,
                                        size: 18, color: AppColors.error),
                                    onPressed: () => _removePlayer(i),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 250.ms,
                          delay: Duration(milliseconds: 100 * i))
                      .slideY(
                          begin: 0.3, end: 0,
                          duration: 250.ms,
                          delay: Duration(milliseconds: 100 * i)),
                );
              }),

              const SizedBox(height: 16),

              // Bouton ajouter (visible si < 6)
              if (canAdd)
                GestureDetector(
                  onTap: _addPlayer,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline, size: 20, color: primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.addPlayer,
                        style: AppTextStyles.inter(fontSize: 13, color: primary),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 200.ms),

              const SizedBox(height: 24),
              PrimaryButton(
                label: l10n.startGame,
                isLoading: isLoading,
                onPressed: isLoading ? null : () => _startGame(l10n),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 11: CarteMiniWidget + PlayerHandGridWidget + CardPeekOverlay

**Files:**
- Create: `lib/presentation/widgets/game/carte_mini_widget.dart`
- Create: `lib/presentation/widgets/game/player_hand_grid_widget.dart`
- Create: `lib/presentation/widgets/game/card_peek_overlay.dart`

**Interfaces:**
- Consumes: `Personnage`, `Famille`, `Descripteur`, `SoundService.instance.playCardFlip()`, `Image.asset('assets/images/card_back.png')`, `CarteMode.reveal`, l10n.closeCard
- Produces:
  - `CarteMiniWidget({key, personnage, famille, isSelected, onTap})`
  - `PlayerHandGridWidget({personnages, familles, onDescripteurSelected})`
  - `CardPeekOverlay.show(context, sourceRect, personnage, famille, onDescripteurSelected)`

- [ ] **Step 1: Créer carte_mini_widget.dart**

```dart
// Mini carte (dos visible) pour la grille de la main du joueur.
// Taille fixe, AnimatedScale si sélectionnée.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/models/famille.dart';

class CarteMiniWidget extends StatelessWidget {
  const CarteMiniWidget({
    super.key,
    required this.personnage,
    required this.famille,
    this.isSelected = false,
    this.onTap,
  });

  final Personnage personnage;
  final Famille famille;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.08),
                blurRadius: isSelected ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AspectRatio(
              aspectRatio: 0.65,
              child: Image.asset(
                'assets/images/card_back.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Créer player_hand_grid_widget.dart**

```dart
// Grille 2 colonnes de mini cartes représentant la main du joueur.
// Un tap ouvre l'overlay CardPeekOverlay.

import 'package:flutter/material.dart';

import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';
import 'card_peek_overlay.dart';
import 'carte_mini_widget.dart';

class PlayerHandGridWidget extends StatefulWidget {
  const PlayerHandGridWidget({
    super.key,
    required this.personnages,
    required this.familles,
    this.onDescripteurSelected,
  });

  final List<Personnage> personnages;
  final List<Famille> familles;
  final void Function(Descripteur)? onDescripteurSelected;

  @override
  State<PlayerHandGridWidget> createState() => _PlayerHandGridWidgetState();
}

class _PlayerHandGridWidgetState extends State<PlayerHandGridWidget> {
  Personnage? _selected;
  final Map<int, GlobalKey> _keys = {};

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.personnages.length,
      itemBuilder: (context, i) {
        final p = widget.personnages[i];
        final famille = widget.familles.firstWhere((f) => f.id == p.familleId);
        _keys[i] ??= GlobalKey();

        return CarteMiniWidget(
          key: _keys[i],
          personnage: p,
          famille: famille,
          isSelected: _selected?.id == p.id,
          onTap: () => _openPeek(context, i, p, famille),
        );
      },
    );
  }

  void _openPeek(BuildContext context, int i, Personnage p, Famille famille) {
    final renderBox =
        _keys[i]!.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final sourceRect = position & renderBox.size;

    setState(() => _selected = p);

    CardPeekOverlay.show(
      context: context,
      sourceRect: sourceRect,
      personnage: p,
      famille: famille,
      onDescripteurSelected: (d) {
        widget.onDescripteurSelected?.call(d);
      },
      onClose: () {
        if (mounted) setState(() => _selected = null);
      },
    );
  }
}
```

- [ ] **Step 3: Créer card_peek_overlay.dart**

```dart
// Overlay "peek" : la mini carte s'agrandit vers le centre avec flip 3D.
// Animation : sourceRect → 280×392 centrée (300ms) puis flip dos→face (400ms).
// Fermeture : flip face→dos (300ms) puis shrink (300ms).
// Joue SoundService.playCardFlip() à chaque flip.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/sound_service.dart';
import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';

class CardPeekOverlay {
  static void show({
    required BuildContext context,
    required Rect sourceRect,
    required Personnage personnage,
    required Famille famille,
    required void Function(Descripteur) onDescripteurSelected,
    required VoidCallback onClose,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dCtx, anim, _) => _CardPeekDialog(
        sourceRect: sourceRect,
        personnage: personnage,
        famille: famille,
        onDescripteurSelected: (d) {
          Navigator.of(dCtx).pop();
          onClose();
          onDescripteurSelected(d);
        },
        onClose: () {
          Navigator.of(dCtx).pop();
          onClose();
        },
      ),
    );
  }
}

class _CardPeekDialog extends StatefulWidget {
  const _CardPeekDialog({
    required this.sourceRect,
    required this.personnage,
    required this.famille,
    required this.onDescripteurSelected,
    required this.onClose,
  });

  final Rect sourceRect;
  final Personnage personnage;
  final Famille famille;
  final void Function(Descripteur) onDescripteurSelected;
  final VoidCallback onClose;

  @override
  State<_CardPeekDialog> createState() => _CardPeekDialogState();
}

class _CardPeekDialogState extends State<_CardPeekDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _expandAnim; // 0→1 : sourceRect → targetRect
  late Animation<double> _flipAnim;  // 0→1 : dos→face

  bool _expanded = false;
  bool _flipped = false;

  Rect _targetRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _expandAnim = const AlwaysStoppedAnimation(0);
    _flipAnim = const AlwaysStoppedAnimation(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      const cardW = 280.0;
      const cardH = 392.0;
      _targetRect = Rect.fromLTWH(
        (size.width - cardW) / 2,
        (size.height - cardH) / 2,
        cardW,
        cardH,
      );
      _startExpand();
    });
  }

  void _startExpand() {
    setState(() => _expanded = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _startFlip();
    });
  }

  Future<void> _startFlip() async {
    SoundService.instance.playCardFlip();
    await _flipController.forward();
    if (mounted) setState(() => _flipped = true);
  }

  Future<void> _closeOverlay() async {
    SoundService.instance.playCardFlip();
    await _flipController.reverse();
    if (!mounted) return;
    setState(() => _expanded = false);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final reduce = MediaQuery.of(context).disableAnimations;
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 300);

    final srcRect = widget.sourceRect;
    final tgtRect = _targetRect == Rect.zero ? srcRect : _targetRect;

    final animRect = _expanded
        ? tgtRect
        : srcRect;

    return GestureDetector(
      onTap: _closeOverlay,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: dur,
            curve: Curves.easeOutCubic,
            left: animRect.left,
            top: animRect.top,
            width: animRect.width,
            height: animRect.height,
            child: GestureDetector(
              onTap: () {}, // absorb tap pour ne pas fermer depuis la carte
              child: Column(
                children: [
                  Expanded(
                    child: _buildFlipCard(primary, isDark, reduce),
                  ),
                  if (_flipped) ...[
                    const SizedBox(height: 8),
                    _buildDescriptorChips(primary),
                    const SizedBox(height: 8),
                    Text(
                      l10n.closeCard,
                      style: const TextStyle(
                        color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(Color primary, bool isDark, bool reduce) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (_, __) {
        final angle = _flipController.value * pi;
        final showFace = angle >= pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        Widget cardContent;
        if (showFace) {
          cardContent = Transform(
            transform: Matrix4.identity()..rotateY(pi),
            alignment: Alignment.center,
            child: _buildFace(primary, isDark),
          );
        } else {
          cardContent = Image.asset(
            'assets/images/card_back.png',
            fit: BoxFit.cover,
          );
        }

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFace(Color primary, bool isDark) {
    final cardSurface = isDark ? AppColors.darkCardSurface : AppColors.cardParchment;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final identifiant = widget.famille.descripteurIdentifiantDe(widget.personnage);

    return Container(
      color: cardSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.personnage.nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.cinzel(fontSize: 22, color: primary),
          ),
          const SizedBox(height: 10),
          Text(
            identifiant.texte,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
                fontSize: 13, color: primary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            identifiant.reference,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
                fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            widget.famille.nom,
            style: AppTextStyles.inter(
                fontSize: 11, color: textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptorChips(Color primary) {
    final cles = widget.famille.descriptionsClesDe(widget.personnage);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: cles.map((d) {
          final label = d.texte.length > 12
              ? '${d.texte.substring(0, 12)}…'
              : d.texte;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onDescripteurSelected(d),
              child: Chip(
                label: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11),
                ),
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

- [ ] **Step 4: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 12: GameScreen update + game_bg_pattern

**Files:**
- Create: `assets/images/game_bg_pattern.svg`
- Modify: `lib/presentation/screens/game/game_screen.dart`

**Interfaces:**
- Consumes: `PlayerHandGridWidget`, `flutter_svg` (SvgPicture), section 2 conditionnée par descripteur déjà sélectionné
- Produces: GameScreen avec grille main, fond pattern, flow section 2 après sélection descripteur

- [ ] **Step 1: Créer assets/images/game_bg_pattern.svg**

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 60 60" width="60" height="60">
  <g opacity="0.04" fill="currentColor">
    <rect x="22" y="8" width="16" height="44" rx="2"/>
    <rect x="8" y="22" width="44" height="16" rx="2"/>
  </g>
</svg>
```

- [ ] **Step 2: Modifier game_screen.dart**

Remplacer dans la section `// SECTION 1 — Ma main` :
```dart
            // SECTION 1 — Ma main
            Text(
              l10n.myHand,
              style: AppTextStyles.inter(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 10),
            PlayerHandGridWidget(
              personnages: joueurActif.main,
              familles: gs.toutesLesFamilles,
              onDescripteurSelected: _onDescripteurSelected,
            ),
```

Modifier `_onDescripteurSelected` pour recevoir le `Descripteur` depuis l'overlay :
```dart
  void _onDescripteurSelected(Descripteur d) {
    setState(() {
      _selectedDescripteur = d;
      _selectedCible = null;
    });
  }
```

Ajouter les imports :
```dart
import '../../widgets/game/player_hand_grid_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
```

Envelopper le `Scaffold` dans un `Stack` pour le fond pattern :
```dart
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark ? AppTheme.gameAppBarThemeDark : AppTheme.gameAppBarThemeLight,
      ),
      child: Stack(
        children: [
          // Fond pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.06,
              child: SvgPicture.asset(
                'assets/images/game_bg_pattern.svg',
                repeat: ImageRepeat.repeat,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            // ... contenu existant ...
          ),
        ],
      ),
    );
```

Mettre à jour la section 2 : elle reste visible mais n'est active qu'après sélection du descripteur depuis l'overlay. La `FamilleSelectorWidget` sert toujours à choisir la famille cible (existant). La section 3 (descripteur) n'a plus d'interface de sélection directe — le descripteur vient de l'overlay. Retirer la section 3 de sélection de descripteur ou la garder pour compatibilité en la marquant comme résultat.

Note : la section 3 peut être simplifiée pour n'afficher que le descripteur déjà sélectionné (lecture seule), ou retirée. L'overlay remplace la sélection manuelle.

- [ ] **Step 3: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 13: CartePersonnageWidget face redessinée (F1)

**Files:**
- Modify: `lib/presentation/widgets/game/carte_personnage_widget.dart`

**Interfaces:**
- Consumes: `google_fonts` (Lora via GoogleFonts.lora), layout F1 complet
- Produces: face redessinée avec badge famille, ligne décorative nom, container identifiant, clés numérotées, pied de page Lora

- [ ] **Step 1: Remplacer `_buildMainContent` et `_buildRevealContent` dans carte_personnage_widget.dart**

Ajouter l'import :
```dart
import 'package:google_fonts/google_fonts.dart';
```

Remplacer `_buildMainContent` :
```dart
  Widget _buildMainContent(
    Color primary, Color textSecondary, Color textPrimary,
    Color borderColor, Descripteur identifiant, List<Descripteur> cles,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête : croix + badge famille
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: 0.6,
              child: SizedBox(
                width: 16, height: 16,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 2, height: 12, color: primary),
                  Container(width: 12, height: 2, color: primary),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.famille.nom.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white, fontSize: 8,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
        Divider(color: borderColor, height: 10),

        // Nom personnage avec lignes décoratives
        Row(
          children: [
            Expanded(
              child: Divider(
                color: primary.withValues(alpha: 0.3), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.personnage.nom,
                textAlign: TextAlign.center,
                style: AppTextStyles.cinzel(
                    fontSize: 13, color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Divider(
                color: primary.withValues(alpha: 0.3), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Container identifiant
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 10, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    'IDENTIFIANT',
                    style: TextStyle(
                      fontSize: 9, color: primary, letterSpacing: 0.8,
                      fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                identifiant.texte,
                style: AppTextStyles.inter(
                    fontSize: 10, color: primary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  identifiant.reference,
                  style: AppTextStyles.inter(
                      fontSize: 9,
                      color: primary.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),

        // Clés 1, 2, 3
        Expanded(
          child: Column(
            children: cles.take(3).toList().asMap().entries.map((e) {
              final idx = e.key;
              final d = e.value;
              return Column(
                children: [
                  if (idx > 0) Divider(color: borderColor, height: 8, thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: AppTextStyles.inter(
                                  fontSize: 9, color: textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.texte,
                            style: AppTextStyles.inter(
                                fontSize: 10, color: textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          d.reference,
                          style: AppTextStyles.inter(
                              fontSize: 9, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        // Pied de page
        Divider(color: borderColor, height: 8),
        Center(
          child: Text(
            'FJ GAME · ${widget.famille.nom}',
            style: GoogleFonts.lora(
              fontSize: 8, color: textSecondary, letterSpacing: 1),
          ),
        ),
      ],
    );
  }
```

Mettre à jour la signature de `_buildFace` pour passer `borderColor` :
```dart
  Widget _buildFace(...) {
    // déjà disponible dans build context, récupérer borderColor si nécessaire
  }
```

Note: Le redesign F1 s'applique aussi au mode `reveal` — utiliser `_buildRevealContent` inchangé (centré, juste nom + identifiant) pour l'overlay de résultat.

- [ ] **Step 2: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Task 14: ResultatTourScreen fan + sons, SplashScreen, FinPartieScreen, TransitionScreen

**Files:**
- Modify: `lib/presentation/screens/game/resultat_tour_screen.dart`
- Modify: `lib/presentation/screens/game/fin_partie_screen.dart`
- Modify: `lib/presentation/screens/game/transition_screen.dart`
- Modify: `lib/presentation/screens/splash/splash_screen.dart`
- Modify: `lib/presentation/widgets/common/primary_button.dart`
- Modify: `lib/presentation/widgets/game/distribution_animation_widget.dart`

**Interfaces:**
- Consumes: `flutter_animate`, `SoundService.instance`, `CarteMiniWidget`, `AppTheme.gameAppBarTheme*`
- Produces: fan CarteMini dans ResultatTour; badges colorés dans FinPartie; SVG inline TransitionScreen; fadeIn+scale SplashScreen; playButtonTap dans PrimaryButton; playCardDeal dans DistributionAnimationWidget

- [ ] **Step 1: ResultatTourScreen — fan CarteMiniWidget + sons**

Dans `initState`, après `if (succes) _cardController.forward();` ajouter :
```dart
      SoundService.instance.playSuccess();
```
Après `_shakeController.forward();` ajouter :
```dart
      SoundService.instance.playFail();
```
Si famille complète (dans le bloc `hasFamille`) ajouter :
```dart
      SoundService.instance.playFamilyComplete();
```

Remplacer la section fan SVG (les 4 `SvgPicture.asset` dans `List.generate(4, ...)`) par :
```dart
                            children: List.generate(4, (i) {
                              final angle = -0.3 + i * 0.2;
                              final p = gs.toutesLesFamilles
                                  .expand((f) => f.personnages)
                                  .first; // carte décorative quelconque
                              return Transform.rotate(
                                angle: angle,
                                child: SizedBox(
                                  width: 90, height: 126,
                                  child: CarteMiniWidget(
                                    personnage: p,
                                    famille: gs.toutesLesFamilles.first,
                                  ),
                                ),
                              );
                            }),
```
Ajouter l'import `carte_mini_widget.dart`.

Retirer l'import `flutter_svg` de ce fichier si SvgPicture n'est plus utilisé (vérifier).

- [ ] **Step 2: FinPartieScreen — badges colorés + flutter_animate**

Remplacer `_medal(int rank)` et son usage dans le build :

Au lieu d'emoji, utiliser :
```dart
  Widget _rankBadge(int rank) {
    const colors = [
      Color(0xFFFFB300), // or
      Color(0xFF9E9E9E), // argent
      Color(0xFFBF6E3A), // bronze
    ];
    if (rank < 3) {
      return Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: colors[rank], shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${rank + 1}',
            style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    return Text(
      '${rank + 1}.',
      style: AppTextStyles.inter(fontSize: 16, color: textSecondary),
    );
  }
```

Remplacer `Text(_medal(rank), ...)` par `_rankBadge(rank)`.

Remplacer l'animation `AnimatedOpacity + AnimatedSlide` par flutter_animate :
```dart
            return Container(
              // ... décoration existante ...
            )
            .animate()
            .slideX(
              begin: 40, end: 0,
              delay: Duration(milliseconds: 150 * rank),
              duration: reduceMotion ? Duration.zero : 350.ms,
              curve: Curves.easeOutCubic,
            )
            .fadeIn(
              delay: Duration(milliseconds: 150 * rank),
              duration: reduceMotion ? Duration.zero : 350.ms,
            );
```
(Supprimer les `AnimatedOpacity` + `AnimatedSlide` wrappers et `_rankVisible` si on passe entièrement à flutter_animate auto-start.)

Ajouter `SoundService.instance.playGameWin()` dans `initState`.

- [ ] **Step 3: TransitionScreen — SVG animé inline**

Remplacer l'icône existante par un CustomPaint ou Stack représentant croix dans cercle :
```dart
              // SVG inline : cercle + croix animés
              Center(
                child: SizedBox(
                  width: 80, height: 80,
                  child: CustomPaint(
                    painter: _CrossCirclePainter(
                      color: Theme.of(context).colorScheme.primary),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  duration: reduceMotion ? Duration.zero : 2.seconds,
                ),
              ),
```

Créer `_CrossCirclePainter` dans le même fichier :
```dart
class _CrossCirclePainter extends CustomPainter {
  const _CrossCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, paint);
    // Croix
    final arm = radius * 0.45;
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromCenter(center: center, width: 3, height: arm * 2), paint);
    canvas.drawRect(
      Rect.fromCenter(center: center, width: arm * 2, height: 3), paint);
  }

  @override
  bool shouldRepaint(_CrossCirclePainter old) => old.color != color;
}
```

- [ ] **Step 4: SplashScreen — flutter_animate fadeIn+scale**

```dart
            // Remplacer les Text existants par :
            Text(
              l10n.appName,
              style: AppTextStyles.cinzel(
                fontSize: 36, color: primary, fontWeight: FontWeight.bold),
            )
            .animate()
            .fadeIn(duration: reduceMotion ? Duration.zero : 600.ms)
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.0, 1.0),
              duration: reduceMotion ? Duration.zero : 600.ms,
              curve: Curves.easeOut,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tagline,
              style: AppTextStyles.inter(fontSize: 14, color: textSecondary),
            )
            .animate()
            .fadeIn(
              duration: reduceMotion ? Duration.zero : 400.ms,
              delay: reduceMotion ? Duration.zero : 300.ms,
            ),
```
Ajouter `import 'package:flutter_animate/flutter_animate.dart';` et récupérer `reduceMotion` depuis MediaQuery.

- [ ] **Step 5: PrimaryButton — playButtonTap**

Dans `onPressed` du `ElevatedButton`/`TextButton`, avant d'appeler `widget.onPressed?.call()` :
```dart
    onPressed: widget.onPressed == null
        ? null
        : () {
            SoundService.instance.playButtonTap();
            widget.onPressed!();
          },
```
Ajouter `import '../../../core/services/sound_service.dart';`.

- [ ] **Step 6: DistributionAnimationWidget — playCardDeal**

Dans la méthode qui avance l'animation par carte (dans le `AnimationController` listener ou le `builder`), appeler `SoundService.instance.playCardDeal()` quand une nouvelle carte devient visible (quand `progress` pour cette carte passe de 0 à >0).

Alternative simple : appeler une seule fois dans `initState` après le démarrage du controller :
```dart
    SoundService.instance.playCardDeal();
```

- [ ] **Step 7: Vérifier**

```bash
flutter analyze
```
Expected: `No issues found!`

---

## Self-Review

### 1. Spec coverage check

| Section | Tâche |
|---------|-------|
| A1 AppBar neutre jeu | Task 6 + Task 9 (Theme local) |
| A2 SettingsBottomSheet | Task 7 |
| B1 Pseudo inscription | Task 4 (AuthNotifier) + Task 9 (RegisterScreen UI) |
| B2 AppUser pseudo+avatarColor | Task 4 |
| B3 ForgotPassword | Task 5 |
| B4 Nouvelles clés i18n | Task 2 |
| C HomeScreen | Task 8 |
| D LobbyLocalScreen | Task 10 |
| E1-E5 Interaction cartes | Task 11 |
| E6 GameScreen intégration | Task 12 |
| F1 Face carte redessinée | Task 13 |
| G1 SoundService | Task 3 |
| G2 Assets sons | Task 1 |
| G3 Intégration sons | Task 14 |
| H1 game_bg_pattern | Task 12 |
| H2 Fan ResultatTour | Task 14 |
| H3 SplashScreen | Task 14 |
| H4 FinPartie badges | Task 14 |
| I1 TransitionScreen SVG | Task 14 |
| I2 Retrait toggles login/register | Task 9 |

### 2. Placeholder scan

Aucun "TBD" ou "TODO" présent. Task 11 (CardPeekOverlay) note que le descripteur overlay interagit avec FamilleSelectorWidget — précision : la sélection du descripteur depuis l'overlay pré-remplit `_selectedDescripteur` dans GameScreen, la section 3 existante reste comme confirmation visuelle.

### 3. Type consistency

- `Descripteur` : utilisé cohéremment via `widget.famille.descriptionsClesDe(personnage)` (Pattern Phase 3)
- `Personnage` : `p.id`, `p.familleId`, `p.nom` — cohérent avec modèle existant
- `AppUser.pseudo` : nouveau champ String, non nullable — `displayName` conservé comme alias
- `SoundService.instance` : singleton, toutes les tâches utilisent le même accès

---

**Plan complet et sauvegardé dans `docs/superpowers/plans/2026-06-19-phase5-design-ux.md`.**

**Deux options d'exécution :**

**1. Subagent-Driven (recommandé)** — Un sous-agent par tâche, revue entre chaque, itération rapide

**2. Inline Execution** — Exécution dans cette session avec checkpoints

**Laquelle choisissez-vous ?**
