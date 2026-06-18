// Écran de résultat du tour : annonce succès ou échec avant de passer au joueur suivant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/game/carte_personnage_widget.dart';

class ResultatTourScreen extends ConsumerWidget {
  const ResultatTourScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (gameNotifier.gameState == null || gameNotifier.dernierResultat == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final gs = gameNotifier.gameState!;
    final resultat = gameNotifier.dernierResultat!;
    final cibleNom = gameNotifier.dernierCibleNom ?? '?';
    final succes = resultat.succes;

    final couleur = succes ? AppColors.success : AppColors.error;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Personnage? carteGagnee;
    Famille? familleCarte;
    String? nomFamilleCompletee;

    if (succes && resultat.carteTransferee != null) {
      carteGagnee = resultat.carteTransferee;
      familleCarte = gs.toutesLesFamilles
          .firstWhere((f) => f.id == carteGagnee!.familleId);
    }

    if (resultat.famillePoseeId != null) {
      nomFamilleCompletee = gs.toutesLesFamilles
          .firstWhere((f) => f.id == resultat.famillePoseeId)
          .nom;
    }

    void continuer() {
      ref.read(gameNotifierProvider.notifier).continuerApresResultat();
      final next = ref.read(gameNotifierProvider);
      if (next.etape == EtapeJeu.terminee) {
        context.go('/game/fin');
      } else {
        context.go('/game/transition');
      }
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  succes ? Icons.check_circle_outline : Icons.cancel_outlined,
                  size: 72,
                  color: couleur,
                ),
                const SizedBox(height: 20),
                Text(
                  succes ? l10n.successTitle : l10n.failTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.cinzel(fontSize: 28, color: couleur),
                ),
                const SizedBox(height: 12),
                Text(
                  succes && carteGagnee != null
                      ? l10n.successMessage(cibleNom, carteGagnee.nom)
                      : l10n.failMessage(cibleNom),
                  textAlign: TextAlign.center,
                  style:
                      AppTextStyles.inter(fontSize: 14, color: textSecondary),
                ),
                if (nomFamilleCompletee != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          const Border.fromBorderSide(BorderSide(color: Color(0xFFFFD700))),
                    ),
                    child: Text(
                      '🏆 ${l10n.familyCompleted(nomFamilleCompletee)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.inter(
                        fontSize: 15,
                        color: const Color(0xFFB8860B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                if (succes && carteGagnee != null && familleCarte != null) ...[
                  const SizedBox(height: 20),
                  CartePersonnageWidget(
                    personnage: carteGagnee,
                    famille: familleCarte,
                    mode: CartePersonnageMode.reveal,
                  ),
                ],
                if (succes) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.youReplay,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.inter(
                      fontSize: 14,
                      color: primary,
                    ),
                  ),
                ],
                const Spacer(),
                PrimaryButton(
                  label: l10n.continueButton,
                  onPressed: continuer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
