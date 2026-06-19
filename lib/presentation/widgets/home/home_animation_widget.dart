// Widget d'animation de l'écran d'accueil : 4 cartes en éventail animé.
// Utilise flutter_animate avec repeat + reverse.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class HomeAnimationWidget extends StatelessWidget {
  const HomeAnimationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    final cardColor = isDark ? AppColors.darkPrimary : AppColors.lightPrimary;

    // offsets et angles pour l'éventail
    const configs = [
      (dx: -70.0, dy: -50.0, angle: -0.26), // -15°
      (dx: 70.0, dy: -50.0, angle: 0.26), //  15°
      (dx: -50.0, dy: 40.0, angle: -0.14), //  -8°
      (dx: 50.0, dy: 40.0, angle: 0.14), //   8°
    ];

    return SizedBox(
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(4, (i) {
                final cfg = configs[i];
                Widget card = _buildMiniCard(cardColor);
                if (!reduceMotion) {
                  card = card
                      .animate(
                        onPlay: (c) => c.repeat(reverse: true),
                      )
                      .moveX(
                        begin: 0,
                        end: cfg.dx,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .moveY(
                        begin: 0,
                        end: cfg.dy,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      )
                      .rotate(
                        begin: 0,
                        end: cfg.angle,
                        delay: Duration(milliseconds: 120 * i),
                        duration: 900.ms,
                        curve: Curves.easeInOut,
                      );
                } else {
                  card = Transform.translate(
                    offset: Offset(cfg.dx, cfg.dy),
                    child: Transform.rotate(angle: cfg.angle, child: card),
                  );
                }
                return card;
              }),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.appName,
            style: AppTextStyles.cinzel(
              fontSize: 28,
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tagline,
            style: AppTextStyles.inter(fontSize: 12, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(Color color) {
    return Container(
      width: 28,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(width: 1.5, height: 12, color: Colors.white70),
          Container(width: 12, height: 1.5, color: Colors.white70),
        ],
      ),
    );
  }
}
