// Carte d'un Personnage avec flip 3D.
// Mode "main" : tapable, face visible par défaut, flip vers dos sur tap.
// Mode "reveal" : démarre dos, flip automatique vers face.
// Mode "dos" : toujours dos visible, non tapable.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                primary, textSecondary, textPrimary, borderColor, identifiant, cles),
      ),
    );
  }

  Widget _buildMainContent(
    Color primary,
    Color textSecondary,
    Color textPrimary,
    Color borderColor,
    Descripteur identifiant,
    List<Descripteur> cles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // En-tête : croix + badge famille
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Opacity(
              opacity: 0.6,
              child: SizedBox(
                width: 16, height: 16,
                child: Stack(alignment: Alignment.center, children: [
                  Container(width: 2, height: 12, color: primary),
                  Container(width: 12, height: 2, color: primary),
                ]),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                widget.famille.nom.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white, fontSize: 8,
                  fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ],
        ),
        Divider(color: borderColor, height: 10),

        // Nom personnage avec lignes décoratives
        Row(
          children: [
            Expanded(
              child: Divider(
                color: primary.withValues(alpha: 0.3), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                widget.personnage.nom,
                textAlign: TextAlign.center,
                style: AppTextStyles.cinzel(
                    fontSize: 13, color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Divider(
                color: primary.withValues(alpha: 0.3), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Container identifiant
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.08),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 10, color: primary),
                  const SizedBox(width: 4),
                  Text(
                    'IDENTIFIANT',
                    style: TextStyle(
                      fontSize: 9, color: primary, letterSpacing: 0.8,
                      fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                identifiant.texte,
                style: AppTextStyles.inter(
                    fontSize: 10, color: primary, fontStyle: FontStyle.italic),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  identifiant.reference,
                  style: AppTextStyles.inter(
                      fontSize: 9,
                      color: primary.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),

        // Clés 1, 2, 3
        Expanded(
          child: Column(
            children: cles.take(3).toList().asMap().entries.map((e) {
              final idx = e.key;
              final d = e.value;
              return Column(
                children: [
                  if (idx > 0) Divider(color: borderColor, height: 8, thickness: 0.5),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor),
                          ),
                          child: Center(
                            child: Text(
                              '${idx + 1}',
                              style: AppTextStyles.inter(
                                  fontSize: 9, color: textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            d.texte,
                            style: AppTextStyles.inter(
                                fontSize: 10, color: textPrimary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          d.reference,
                          style: AppTextStyles.inter(
                              fontSize: 9, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),

        // Pied de page
        Divider(color: borderColor, height: 8),
        Center(
          child: Text(
            'FJ GAME · ${widget.famille.nom}',
            style: GoogleFonts.lora(
              fontSize: 8, color: textSecondary, letterSpacing: 1),
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
