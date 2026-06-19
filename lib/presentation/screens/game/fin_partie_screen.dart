// Écran de fin de partie : classement final avec apparition staggerée des rangs.
// Rang 1 : délai 0ms, rang 2 : 150ms, rang 3 : 300ms, etc.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';

class FinPartieScreen extends ConsumerStatefulWidget {
  const FinPartieScreen({super.key});

  @override
  ConsumerState<FinPartieScreen> createState() => _FinPartieScreenState();
}

class _FinPartieScreenState extends ConsumerState<FinPartieScreen> {
  List<bool> _rankVisible = [];

  @override
  void initState() {
    super.initState();
    final classement = ref.read(gameNotifierProvider).classement;
    _rankVisible = List.filled(classement.length, false);

    for (var i = 0; i < classement.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) setState(() => _rankVisible[i] = true);
      });
    }
  }

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
  Widget build(BuildContext context) {
    final gameNotifier = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 350);

    if (gameNotifier.gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final gs = gameNotifier.gameState!;
    final classement = gameNotifier.classement;

    // Synchronise _rankVisible si le classement change de taille (sécurité)
    if (_rankVisible.length != classement.length) {
      _rankVisible = List.filled(classement.length, true);
    }

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

            final isVisible =
                rank < _rankVisible.length ? _rankVisible[rank] : true;

            return AnimatedOpacity(
              opacity: isVisible ? 1.0 : 0.0,
              duration: animDuration,
              child: AnimatedSlide(
                offset: isVisible ? Offset.zero : const Offset(0.15, 0),
                duration: animDuration,
                curve: Curves.easeOutCubic,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: rank == 0
                          ? const Color(0xFFFFD700)
                          : (isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder),
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
                              .map(
                                (name) => Chip(
                                  label: Text(
                                    name,
                                    style: AppTextStyles.inter(
                                        fontSize: 11, color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.success,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
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
