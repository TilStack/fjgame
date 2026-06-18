// Écran de connexion : Email/Password, connexion anonyme, toggle langue et thème.
// Les erreurs Firebase sont affichées via SnackBar avec messages localisés.

import 'package:flutter/material.dart';
import 'package:fjgame/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/auth_provider.dart';
import '../../../application/providers/locale_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _resolveError(AppLocalizations l10n, String key) {
    return switch (key) {
      'emailAlreadyInUse' => l10n.emailAlreadyInUse,
      'wrongPassword'     => l10n.wrongPassword,
      'userNotFound'      => l10n.userNotFound,
      'networkError'      => l10n.networkError,
      _                   => l10n.errorGeneric,
    };
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _signIn(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.error && state.errorMessage != null) {
      _showError(_resolveError(l10n, state.errorMessage!));
    }
  }

  Future<void> _signInAnonymously(AppLocalizations l10n) async {
    await ref.read(authNotifierProvider.notifier).signInAnonymously();
    if (!mounted) return;
    final state = ref.read(authNotifierProvider);
    if (state.status == AuthStatus.error && state.errorMessage != null) {
      _showError(_resolveError(l10n, state.errorMessage!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final themeMode = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    ref.listen(authNotifierProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => ref.read(localeNotifierProvider.notifier).setLocale(
                  locale.languageCode == 'fr'
                      ? const Locale('en')
                      : const Locale('fr'),
                ),
            child: Text(
              locale.languageCode == 'fr' ? 'EN' : 'FR',
              style: AppTextStyles.inter(fontSize: 14, color: primary),
            ),
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            color: primary,
            onPressed: () =>
                ref.read(themeNotifierProvider.notifier).setTheme(
                      themeMode == ThemeMode.dark
                          ? ThemeMode.light
                          : ThemeMode.dark,
                    ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                l10n.login,
                style: AppTextStyles.cinzel(fontSize: 28, color: primary),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _emailCtrl,
                labelText: l10n.email,
                prefixIcon: Icons.email_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return l10n.emailRequired;
                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$')
                      .hasMatch(v.trim())) {
                    return l10n.invalidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _passwordCtrl,
                labelText: l10n.password,
                prefixIcon: Icons.lock_outlined,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return l10n.passwordRequired;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: l10n.loginButton,
                isLoading: isLoading,
                onPressed: isLoading ? null : () => _signIn(l10n),
              ),
              const SizedBox(height: 20),
              Text(
                '— ${l10n.orSeparator} —',
                textAlign: TextAlign.center,
                style: AppTextStyles.inter(fontSize: 13, color: textSecondary),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.playAsGuest,
                variant: PrimaryButtonVariant.outlined,
                isLoading: isLoading,
                onPressed: isLoading ? null : () => _signInAnonymously(l10n),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.guestDisclaimer,
                textAlign: TextAlign.center,
                style: AppTextStyles.inter(fontSize: 11, color: textSecondary),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.noAccount} ',
                    style:
                        AppTextStyles.inter(fontSize: 13, color: textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text(
                      l10n.signUp,
                      style: AppTextStyles.inter(
                        fontSize: 13,
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
