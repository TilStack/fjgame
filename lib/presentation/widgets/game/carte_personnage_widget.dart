// Carte d'un Personnage avec flip 3D.
// Mode "main" : tapable, face visible par défaut, flip vers dos sur tap.
// Mode "reveal" : démarre dos, flip automatique vers face.
// Mode "dos" : toujours dos visible, non tapable.

import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/famille.dart';

enum CarteMode { main, reveal, dos }

class CartePersonnageWidget extends StatefulWidget {
  final Personnage personnage;
  final Famille famille;
  final bool isSelected;
  final CarteMode mode;
  final bool autoReveal;
  final VoidCallback? onTap;

  const CartePersonnageWidget({
    super.key,
    required this.personnage,
    required this.famille,
    this.isSelected = false,
    this.mode = CarteMode.main,
    this.autoReveal = false,
    this.onTap,
  });

  @override
  State<CartePersonnageWidget> createState() => _CartePersonnageWidgetState();
}

class _CartePersonnageWidgetState extends State<CartePersonnageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  bool _isLifted = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    if (widget.mode == CarteMode.dos) {
      _flipController.value = 1.0;
    } else if (widget.mode == CarteMode.reveal && widget.autoReveal) {
      _flipController.value = 1.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _flipController.reverse();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    _flipController.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 600);
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.mode != CarteMode.main) return;
    setState(() => _isLifted = true);
    if (_flipController.value < 0.5) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isLifted = false);
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final cardSurface =
        isDark ? AppColors.darkCardSurface : AppColors.cardParchment;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return GestureDetector(
      onTap: widget.mode == CarteMode.main ? _handleTap : null,
      child: AnimatedScale(
        scale: _isLifted ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _isLifted ? const Offset(0, -0.03) : Offset.zero,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: _flipController,
            builder: (context, _) {
              final angle = _flipController.value * pi;
              final showBack = angle >= pi / 2;

              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

              final content = showBack
                  ? Transform(
                      transform: Matrix4.identity()..rotateY(pi),
                      alignment: Alignment.center,
                      child: _buildDos(),
                    )
                  : _buildFace(
                      primary,
                      cardSurface,
                      textSecondary,
                      textPrimary,
                      borderColor,
                    );

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: content,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFace(
    Color primary,
    Color cardSurface,
    Color textSecondary,
    Color textPrimary,
    Color borderColor,
  ) {
    final identifiant =
        widget.famille.descripteurIdentifiantDe(widget.personnage);
    final cles = widget.famille.descriptionsClesDe(widget.personnage);

    return SizedBox(
      width: 200,
      height: 280,
      child: Container(
        decoration: BoxDecoration(
          color: cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected ? primary : borderColor,
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isLifted ? 0.30 : 0.12),
              blurRadius: _isLifted ? 18 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: widget.mode == CarteMode.reveal
            ? _buildRevealContent(primary, textSecondary, identifiant)
            : _buildMainContent(
                primary, textSecondary, textPrimary, identifiant, cles),
      ),
    );
  }

  Widget _buildMainContent(
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
            widget.personnage.nom,
            textAlign: TextAlign.center,
            style: AppTextStyles.cinzel(
              fontSize: 15,
              color: primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Divider(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '★ ',
              style: AppTextStyles.inter(fontSize: 12, color: primary),
            ),
            Expanded(
              child: Text(
                identifiant.texte,
                style: AppTextStyles.inter(
                  fontSize: 11,
                  color: primary,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            identifiant.reference,
            style: AppTextStyles.inter(
              fontSize: 10,
              color: textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const Divider(height: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: cles
                .take(3)
                .map(
                  (d) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '— ',
                              style: AppTextStyles.inter(
                                  fontSize: 11, color: textSecondary),
                            ),
                            Expanded(
                              child: Text(
                                d.texte,
                                style: AppTextStyles.inter(
                                    fontSize: 11, color: textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            d.reference,
                            style: AppTextStyles.inter(
                              fontSize: 10,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRevealContent(
    Color primary,
    Color textSecondary,
    Descripteur identifiant,
  ) {
    return Column(
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

  Widget _buildDos() {
    return SizedBox(
      width: 200,
      height: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/card_back.png',
          width: 200,
          height: 280,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
