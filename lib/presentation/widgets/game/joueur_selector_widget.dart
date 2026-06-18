// Sélecteur de joueur cible : liste verticale de ListTiles cliquables.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/game_state.dart';
import '../../../l10n/app_localizations.dart';

class JoueurSelectorWidget extends StatelessWidget {
  final List<JoueurPartie> joueurs;
  final JoueurPartie? joueurSelectionne;
  final void Function(JoueurPartie) onSelect;

  const JoueurSelectorWidget({
    super.key,
    required this.joueurs,
    required this.joueurSelectionne,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Column(
      children: joueurs.map((j) {
        final selected = joueurSelectionne?.id == j.id;
        return GestureDetector(
          onTap: () => onSelect(j),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    j.nom,
                    style: AppTextStyles.inter(
                      fontSize: 16,
                      color: selected
                          ? Colors.white
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    l10n.cardsInHand(j.main.length),
                    style: AppTextStyles.inter(
                      fontSize: 14,
                      color: selected ? Colors.white70 : textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
