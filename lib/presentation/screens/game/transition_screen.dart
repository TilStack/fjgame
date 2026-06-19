// Écran de transition pass-and-play : cache la main du joueur précédent
// avant de passer le téléphone au joueur suivant.
// Animation : FadeIn du nom (300ms), SlideIn du bouton (600ms).

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: isDark
            ? AppTheme.gameAppBarThemeDark
            : AppTheme.gameAppBarThemeLight,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: CustomPaint(
                        painter: _CrossCirclePainter(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.1, 1.1),
                      duration: reduceMotion ? Duration.zero : 2.seconds,
                    ),
                  ),
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
      ),
    );
  }
}

class _CrossCirclePainter extends CustomPainter {
  const _CrossCirclePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    canvas.drawCircle(center, radius, paint);
    final arm = radius * 0.45;
    paint.style = PaintingStyle.fill;
    canvas.drawRect(
        Rect.fromCenter(center: center, width: 3, height: arm * 2), paint);
    canvas.drawRect(
        Rect.fromCenter(center: center, width: arm * 2, height: 3), paint);
  }

  @override
  bool shouldRepaint(_CrossCirclePainter old) => old.color != color;
}
