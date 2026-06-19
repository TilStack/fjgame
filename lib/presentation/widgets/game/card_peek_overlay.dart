// Overlay "peek" de carte : agrandissement depuis la grille + flip 3D dos→face.
// Fermeture par tap sur le fond ou la carte elle-même.
// Appelle SoundService.playCardFlip() à l'ouverture et fermeture du flip.

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/sound_service.dart';
import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';

class CardPeekOverlay {
  static void show({
    required BuildContext context,
    required Rect sourceRect,
    required Personnage personnage,
    required Famille famille,
    required void Function(Descripteur) onDescripteurSelected,
    required VoidCallback onClose,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dCtx, anim, _) => _CardPeekDialog(
        sourceRect: sourceRect,
        personnage: personnage,
        famille: famille,
        onDescripteurSelected: (d) {
          Navigator.of(dCtx).pop();
          onClose();
          onDescripteurSelected(d);
        },
        onClose: () {
          Navigator.of(dCtx).pop();
          onClose();
        },
      ),
    );
  }
}

class _CardPeekDialog extends StatefulWidget {
  const _CardPeekDialog({
    required this.sourceRect,
    required this.personnage,
    required this.famille,
    required this.onDescripteurSelected,
    required this.onClose,
  });

  final Rect sourceRect;
  final Personnage personnage;
  final Famille famille;
  final void Function(Descripteur) onDescripteurSelected;
  final VoidCallback onClose;

  @override
  State<_CardPeekDialog> createState() => _CardPeekDialogState();
}

class _CardPeekDialogState extends State<_CardPeekDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;

  bool _expanded = false;
  bool _flipped = false;
  Rect _targetRect = Rect.zero;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.of(context).size;
      const cardW = 280.0;
      const cardH = 392.0;
      _targetRect = Rect.fromLTWH(
        (size.width - cardW) / 2,
        (size.height - cardH) / 2,
        cardW,
        cardH,
      );
      setState(() => _expanded = true);
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _startFlip();
      });
    });
  }

  Future<void> _startFlip() async {
    SoundService.instance.playCardFlip();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _flipController.value = 1.0;
    } else {
      await _flipController.forward();
    }
    if (mounted) setState(() => _flipped = true);
  }

  Future<void> _closeOverlay() async {
    SoundService.instance.playCardFlip();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _flipController.value = 0.0;
    } else {
      await _flipController.reverse();
    }
    if (!mounted) return;
    setState(() => _expanded = false);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) widget.onClose();
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final reduce = MediaQuery.of(context).disableAnimations;
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 300);

    final tgtRect = _targetRect == Rect.zero ? widget.sourceRect : _targetRect;
    final animRect = _expanded ? tgtRect : widget.sourceRect;

    return GestureDetector(
      onTap: _closeOverlay,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: dur,
            curve: Curves.easeOutCubic,
            left: animRect.left,
            top: animRect.top,
            width: animRect.width,
            height: animRect.height,
            child: GestureDetector(
              onTap: () {}, // absorb tap on card
              child: Column(
                children: [
                  Expanded(child: _buildFlipCard(primary, isDark)),
                  if (_flipped) ...[
                    const SizedBox(height: 8),
                    _buildDescriptorChips(primary),
                    const SizedBox(height: 8),
                    Text(
                      l10n.closeCard,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlipCard(Color primary, bool isDark) {
    return AnimatedBuilder(
      animation: _flipController,
      builder: (_, __) {
        final angle = _flipController.value * pi;
        final showFace = angle >= pi / 2;
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        Widget cardContent = showFace
            ? Transform(
                transform: Matrix4.identity()..rotateY(pi),
                alignment: Alignment.center,
                child: _buildFace(primary, isDark),
              )
            : Image.asset('assets/images/card_back.png', fit: BoxFit.cover);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: cardContent,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFace(Color primary, bool isDark) {
    final cardSurface =
        isDark ? AppColors.darkCardSurface : AppColors.cardParchment;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final identifiant =
        widget.famille.descripteurIdentifiantDe(widget.personnage);

    return Container(
      color: cardSurface,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.personnage.nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.cinzel(fontSize: 22, color: primary),
          ),
          const SizedBox(height: 10),
          Text(
            identifiant.texte,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
                fontSize: 13,
                color: primary,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(
            identifiant.reference,
            textAlign: TextAlign.center,
            style: AppTextStyles.inter(
                fontSize: 11,
                color: textSecondary,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            widget.famille.nom,
            style: AppTextStyles.inter(
                fontSize: 11,
                color: textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptorChips(Color primary) {
    final cles = widget.famille.descriptionsClesDe(widget.personnage);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: cles.map((d) {
          final label =
              d.texte.length > 12 ? '${d.texte.substring(0, 12)}…' : d.texte;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => widget.onDescripteurSelected(d),
              child: Chip(
                label: Text(label,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: primary,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
