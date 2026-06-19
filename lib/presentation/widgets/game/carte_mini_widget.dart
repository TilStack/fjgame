// Mini carte (dos visible) pour la grille de la main du joueur.
// Taille fixe proportionnelle, AnimatedScale et bordure si sélectionnée.

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/famille.dart';

class CarteMiniWidget extends StatelessWidget {
  const CarteMiniWidget({
    super.key,
    required this.personnage,
    required this.famille,
    this.isSelected = false,
    this.onTap,
  });

  final Personnage personnage;
  final Famille famille;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? primary
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.08),
                blurRadius: isSelected ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: AspectRatio(
              aspectRatio: 0.65,
              child: Image.asset(
                'assets/images/card_back.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
