// Sélecteur de descripteur-clé : liste verticale de Cards cliquables.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';

class DescripteurSelectorWidget extends StatelessWidget {
  final List<Descripteur> descripteurs;
  final Descripteur? descripteurSelectionne;
  final void Function(Descripteur) onSelect;

  const DescripteurSelectorWidget({
    super.key,
    required this.descripteurs,
    required this.descripteurSelectionne,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;

    return Column(
      children: descripteurs.map((d) {
        final selected = descripteurSelectionne?.id == d.id;
        return GestureDetector(
          onTap: () => onSelect(d),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: selected
                  ? primary.withValues(alpha: 0.08)
                  : surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? primary : Colors.transparent,
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.texte,
                    style: AppTextStyles.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🔑 ${l10n.cle}',
                        style: AppTextStyles.inter(
                          fontSize: 11,
                          color: textSecondary,
                        ),
                      ),
                      Text(
                        d.reference,
                        style: AppTextStyles.inter(
                          fontSize: 11,
                          color: textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
