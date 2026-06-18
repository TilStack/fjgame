// Écran de transition pass-and-play : cache la main du joueur précédent
// avant de passer le téléphone au joueur suivant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';

class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;

    if (gameState.gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final nomJoueur = gameState.gameState!.joueurActif.nom;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.smartphone, size: 72, color: primary),
                const SizedBox(height: 32),
                Text(
                  l10n.passPhone,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cinzel(fontSize: 22, color: primary),
                ),
                const SizedBox(height: 12),
                Text(
                  nomJoueur,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cinzel(
                    fontSize: 32,
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  label: l10n.iAmReady,
                  onPressed: () {
                    ref.read(gameNotifierProvider.notifier).joueurPret();
                    context.go('/game/play');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
