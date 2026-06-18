// Carte d'un Personnage. Mode "main" : vue complète pour le joueur actif.
// Mode "reveal" : vue condensée pour l'écran de résultat.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/famille.dart';

enum CartePersonnageMode { main, reveal }

class CartePersonnageWidget extends StatelessWidget {
  final Personnage personnage;
  final Famille famille;
  final bool isSelected;
  final CartePersonnageMode mode;

  const CartePersonnageWidget({
    super.key,
    required this.personnage,
    required this.famille,
    this.isSelected = false,
    this.mode = CartePersonnageMode.main,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final cardSurface =
        isDark ? AppColors.darkCardSurface : AppColors.lightCardSurface;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final identifiant = famille.descripteurIdentifiantDe(personnage);
    final cles = famille.descriptionsClesDe(personnage);

    return Card(
      color: cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: mode == CartePersonnageMode.main
            ? _buildMain(primary, textSecondary, textPrimary, identifiant, cles)
            : _buildReveal(primary, textSecondary, identifiant),
      ),
    );
  }

  Widget _buildMain(
    Color primary,
    Color textSecondary,
    Color textPrimary,
    Descripteur identifiant,
    List<Descripteur> cles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            personnage.nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.cinzel(fontSize: 18, color: primary),
          ),
        ),
        const Divider(height: 20),
        Text(
          '★  ${identifiant.texte}',
          style: AppTextStyles.inter(fontSize: 13, color: primary),
        ),
        const SizedBox(height: 10),
        ...cles.map(
          (d) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '🔑  ${d.texte}',
              style: AppTextStyles.inter(fontSize: 12, color: textPrimary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            identifiant.reference,
            style: AppTextStyles.inter(
              fontSize: 11,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReveal(
    Color primary,
    Color textSecondary,
    Descripteur identifiant,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          personnage.nom,
          textAlign: TextAlign.center,
          style: AppTextStyles.cinzel(fontSize: 22, color: primary),
        ),
        const SizedBox(height: 10),
        Text(
          identifiant.texte,
          textAlign: TextAlign.center,
          style: AppTextStyles.inter(fontSize: 14, color: primary),
        ),
        const SizedBox(height: 6),
        Text(
          identifiant.reference,
          textAlign: TextAlign.center,
          style: AppTextStyles.inter(
            fontSize: 11,
            color: textSecondary,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
