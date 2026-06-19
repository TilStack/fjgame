// Animation de distribution des cartes en début de partie.
// Les cartes volent une par une du centre vers les positions des joueurs.
// Un bouton "Passer" apparaît après 2 secondes.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/sound_service.dart';
import '../../../l10n/app_localizations.dart';

class DistributionAnimationWidget extends StatefulWidget {
  final int nombreJoueurs;
  final int nombreCartesTotal;
  final VoidCallback onAnimationComplete;

  const DistributionAnimationWidget({
    super.key,
    required this.nombreJoueurs,
    required this.nombreCartesTotal,
    required this.onAnimationComplete,
  });

  @override
  State<DistributionAnimationWidget> createState() =>
      _DistributionAnimationWidgetState();
}

class _DistributionAnimationWidgetState
    extends State<DistributionAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _cardAnimations;
  late List<Offset> _playerPositions;
  late Offset _centerPos;
  bool _initialized = false;
  bool _showSkip = false;

  @override
  void initState() {
    super.initState();
    final int total = widget.nombreCartesTotal;
    final int totalMs = total * 80 + 400;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalMs),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onAnimationComplete();
      }
    });

    SoundService.instance.playCardDeal();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showSkip = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final size = MediaQuery.of(context).size;
    _centerPos = Offset(size.width / 2, size.height / 2);
    _playerPositions = _computePlayerPositions(size, widget.nombreJoueurs);

    final int total = widget.nombreCartesTotal;
    final double totalMs = total * 80.0 + 400.0;

    _cardAnimations = List.generate(total, (i) {
      final start = (i * 80.0) / totalMs;
      final end = (i * 80.0 + 400.0) / totalMs;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
    } else {
      _controller.forward();
    }
  }

  List<Offset> _computePlayerPositions(Size size, int n) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    switch (n) {
      case 3:
        return [
          Offset(cx, size.height * 0.82),
          Offset(size.width * 0.18, size.height * 0.15),
          Offset(size.width * 0.82, size.height * 0.15),
        ];
      case 4:
        return [
          Offset(cx, size.height * 0.82),
          Offset(size.width * 0.08, cy),
          Offset(cx, size.height * 0.12),
          Offset(size.width * 0.92, cy),
        ];
      case 5:
        return [
          Offset(cx, size.height * 0.82),
          Offset(size.width * 0.10, size.height * 0.68),
          Offset(size.width * 0.10, size.height * 0.20),
          Offset(size.width * 0.90, size.height * 0.20),
          Offset(size.width * 0.90, size.height * 0.68),
        ];
      case 6:
      default:
        return [
          Offset(cx, size.height * 0.82),
          Offset(size.width * 0.10, size.height * 0.68),
          Offset(size.width * 0.08, size.height * 0.28),
          Offset(cx, size.height * 0.12),
          Offset(size.width * 0.92, size.height * 0.28),
          Offset(size.width * 0.90, size.height * 0.68),
        ];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const textSecondary = Color(0xFF9E9E9E);
    const cardW = 40.0;
    const cardH = 56.0;

    if (!_initialized) return const SizedBox.shrink();

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Paquet source au centre
          Positioned(
            left: _centerPos.dx - cardW / 2,
            top: _centerPos.dy - cardH / 2 - 20,
            child: Column(
              children: [
                SvgPicture.asset(
                  'assets/images/card_back_placeholder.svg',
                  width: cardW,
                  height: cardH,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.distributing,
                  style: AppTextStyles.inter(
                      fontSize: 13, color: textSecondary),
                ),
              ],
            ),
          ),

          // Cartes en vol
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Stack(
                children: List.generate(widget.nombreCartesTotal, (i) {
                  final progress = _cardAnimations[i].value;
                  if (progress <= 0.0) return const SizedBox.shrink();

                  final targetIndex = i % widget.nombreJoueurs;
                  final target = _playerPositions[targetIndex];
                  final pos = Offset.lerp(_centerPos, target, progress)!;
                  final opacity = progress < 0.9 ? 1.0 : (1.0 - progress) / 0.1;

                  return Positioned(
                    left: pos.dx - cardW / 2,
                    top: pos.dy - cardH / 2,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: SvgPicture.asset(
                        'assets/images/card_back_placeholder.svg',
                        width: cardW,
                        height: cardH,
                      ),
                    ),
                  );
                }),
              );
            },
          ),

          // Bouton "Passer" après 2 secondes
          if (_showSkip)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton(
                  onPressed: widget.onAnimationComplete,
                  child: Text(
                    l10n.skipAnimation,
                    style: AppTextStyles.inter(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
