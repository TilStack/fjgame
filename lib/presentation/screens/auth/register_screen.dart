// Écran d'inscription : Email/Password avec validation client avant appel Firebase.
// Validation : format email, longueur mot de passe >= 6, confirmation identique.

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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pseudoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
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

  Future<void> _register(AppLocalizations l10n) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          _pseudoCtrl.text.trim(),
        );
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
                l10n.register,
                style: AppTextStyles.cinzel(fontSize: 28, color: primary),
              ),
              const SizedBox(height: 32),
              AppTextField(
                controller: _pseudoCtrl,
                labelText: 'Pseudo',
                prefixIcon: Icons.person_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Pseudo requis';
                  return null;
                },
              ),
              const SizedBox(height: 16),
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
                  if (v.length < 6) return l10n.passwordTooShort;
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _confirmCtrl,
                labelText: l10n.confirmPassword,
                prefixIcon: Icons.lock_outlined,
                obscureText: true,
                validator: (v) {
                  if (v != _passwordCtrl.text) return l10n.passwordMismatch;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: l10n.registerButton,
                isLoading: isLoading,
                onPressed: isLoading ? null : () => _register(l10n),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${l10n.alreadyAccount} ',
                    style:
                        AppTextStyles.inter(fontSize: 13, color: textSecondary),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      l10n.signIn,
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
