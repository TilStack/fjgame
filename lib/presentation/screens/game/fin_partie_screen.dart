// Écran de fin de partie : classement final et options rejouer / accueil.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';

class FinPartieScreen extends ConsumerWidget {
  const FinPartieScreen({super.key});

  String _medal(int rank) {
    switch (rank) {
      case 0:
        return '🥇';
      case 1:
        return '🥈';
      case 2:
        return '🥉';
      default:
        return '${rank + 1}.';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameNotifier = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (gameNotifier.gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final gs = gameNotifier.gameState!;
    final classement = gameNotifier.classement;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          l10n.gameOver,
          style: AppTextStyles.cinzel(fontSize: 18, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.finalRanking,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(fontSize: 16, color: textSecondary),
          ),
          const SizedBox(height: 24),
          ...classement.asMap().entries.map((entry) {
            final rank = entry.key;
            final joueur = entry.value.key;
            final score = entry.value.value;
            final familleNames = joueur.famillesGagnees.map((fid) {
              return gs.toutesLesFamilles
                  .firstWhere((f) => f.id == fid)
                  .nom;
            }).toList();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: rank == 0
                      ? const Color(0xFFFFD700)
                      : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: rank == 0 ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _medal(rank),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          joueur.nom,
                          style: AppTextStyles.inter(
                            fontSize: 16,
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        l10n.familiesCount(score),
                        style: AppTextStyles.inter(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (familleNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: familleNames
                          .map((name) => Chip(
                                label: Text(
                                  name,
                                  style: AppTextStyles.inter(
                                      fontSize: 11, color: Colors.white),
                                ),
                                backgroundColor: AppColors.success,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            );
          }),
          const SizedBox(height: 40),
          PrimaryButton(
            label: l10n.playAgain,
            onPressed: () {
              ref.read(gameNotifierProvider.notifier).reinitialiser();
              context.go('/lobby-local');
            },
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l10n.backHome,
            variant: PrimaryButtonVariant.outlined,
            onPressed: () {
              ref.read(gameNotifierProvider.notifier).reinitialiser();
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }
}
