// Écran de transition pass-and-play : cache la main du joueur précédent
// avant de passer le téléphone au joueur suivant.
// Animation : FadeIn du nom (300ms), SlideIn du bouton (600ms).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';

class TransitionScreen extends ConsumerStatefulWidget {
  const TransitionScreen({super.key});

  @override
  ConsumerState<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends ConsumerState<TransitionScreen> {
  bool _nameVisible = false;
  bool _buttonVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _nameVisible = true);
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _buttonVisible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final primary = Theme.of(context).colorScheme.primary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 400);

    if (gameState.gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
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

                // Nom du joueur avec FadeIn
                AnimatedOpacity(
                  opacity: _nameVisible || reduceMotion ? 1.0 : 0.0,
                  duration: animDuration,
                  child: Text(
                    nomJoueur,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.cinzel(
                      fontSize: 32,
                      color: primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Bouton avec SlideIn depuis le bas
                AnimatedSlide(
                  offset: _buttonVisible || reduceMotion
                      ? Offset.zero
                      : const Offset(0, 0.4),
                  duration: animDuration,
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: _buttonVisible || reduceMotion ? 1.0 : 0.0,
                    duration: animDuration,
                    child: PrimaryButton(
                      label: l10n.iAmReady,
                      onPressed: () {
                        ref.read(gameNotifierProvider.notifier).joueurPret();
                        context.go('/game/play');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
