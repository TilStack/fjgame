// Écran de démarrage : affiche le logo et redirige selon l'état d'authentification.
// Durée minimale 1,5 seconde avant redirection. Maximum 3 secondes d'attente.

import 'package:flutter/material.dart';
import 'package:fjgame/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _minDelayElapsed = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _minDelayElapsed = true);
      _tryRedirect();
    });
    // Redirection forcée après 3 secondes maximum
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _redirect();
    });
  }

  void _tryRedirect() {
    final status = ref.read(authNotifierProvider).status;
    if (status != AuthStatus.initial && status != AuthStatus.loading) {
      _redirect();
    }
  }

  void _redirect() {
    if (!mounted) return;
    final status = ref.read(authNotifierProvider).status;
    if (status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authNotifierProvider, (_, next) {
      if (_minDelayElapsed &&
          next.status != AuthStatus.initial &&
          next.status != AuthStatus.loading) {
        _redirect();
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.appName,
              style: AppTextStyles.cinzel(
                fontSize: 36,
                color: primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.tagline,
              style: AppTextStyles.inter(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(color: primary, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}
