// Écran de résultat du tour : annonce succès ou échec avec animations d'entrée.
// Succès : carte arrive du haut (translate+rotation+fade, elasticOut).
// Échec : titre "Raté !" tremble horizontalement.
// Bouton Continuer : apparaît avec FadeIn après un court délai.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/famille.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/game/carte_personnage_widget.dart';

class ResultatTourScreen extends ConsumerStatefulWidget {
  const ResultatTourScreen({super.key});

  @override
  ConsumerState<ResultatTourScreen> createState() => _ResultatTourScreenState();
}

class _ResultatTourScreenState extends ConsumerState<ResultatTourScreen>
    with TickerProviderStateMixin {
  late AnimationController _cardController;
  late AnimationController _shakeController;
  late AnimationController _fanController;

  late Animation<double> _cardSlide;
  late Animation<double> _cardFade;
  late Animation<double> _cardRotate;
  late Animation<double> _shake;
  late Animation<double> _fanScale;
  late Animation<double> _fanOpacity;

  bool _showContinueButton = false;
  bool _showFan = false;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(gameNotifierProvider);
    final succes = notifier.dernierResultat?.succes ?? false;
    final hasFamille = notifier.dernierResultat?.famillePoseeId != null;

    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _cardSlide = Tween<double>(begin: -150.0, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );
    _cardFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );
    _cardRotate = Tween<double>(begin: -pi / 12, end: 0.0).animate(
      CurvedAnimation(parent: _cardController, curve: Curves.elasticOut),
    );

    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    _fanScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 27),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 46),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 27),
    ]).animate(_fanController);

    _fanOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 73),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 27),
    ]).animate(_fanController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (succes) {
        _cardController.forward();
        if (hasFamille) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              setState(() => _showFan = true);
              _fanController.forward().whenComplete(() {
                if (mounted) setState(() => _showFan = false);
              });
            }
          });
        }
      } else {
        _shakeController.forward();
      }
      Future.delayed(Duration(milliseconds: succes ? 600 : 500), () {
        if (mounted) setState(() => _showContinueButton = true);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    _cardController.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 500);
    _shakeController.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 400);
    _fanController.duration =
        reduce ? Duration.zero : const Duration(milliseconds: 1500);
  }

  @override
  void dispose() {
    _cardController.dispose();
    _shakeController.dispose();
    _fanController.dispose();
    super.dispose();
  }

  void _continuer() {
    ref.read(gameNotifierProvider.notifier).continuerApresResultat();
    final next = ref.read(gameNotifierProvider);
    if (next.etape == EtapeJeu.terminee) {
      context.go('/game/fin');
    } else {
      context.go('/game/transition');
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameNotifier = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    if (gameNotifier.gameState == null || gameNotifier.dernierResultat == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final gs = gameNotifier.gameState!;
    final resultat = gameNotifier.dernierResultat!;
    final cibleNom = gameNotifier.dernierCibleNom ?? '?';
    final succes = resultat.succes;

    final couleur = succes ? AppColors.success : AppColors.error;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    Personnage? carteGagnee;
    Famille? familleCarte;
    String? nomFamilleCompletee;

    if (succes && resultat.carteTransferee != null) {
      carteGagnee = resultat.carteTransferee;
      familleCarte = gs.toutesLesFamilles
          .firstWhere((f) => f.id == carteGagnee!.familleId);
    }
    if (resultat.famillePoseeId != null) {
      nomFamilleCompletee = gs.toutesLesFamilles
          .firstWhere((f) => f.id == resultat.famillePoseeId)
          .nom;
    }

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
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),

                    // Icône succès / échec
                    Icon(
                      succes
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 72,
                      color: couleur,
                    ),
                    const SizedBox(height: 20),

                    // Titre avec shake sur échec
                    AnimatedBuilder(
                      animation: _shake,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(_shake.value, 0),
                        child: child,
                      ),
                      child: Text(
                        succes ? l10n.successTitle : l10n.failTitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.cinzel(
                            fontSize: 28, color: couleur),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Message
                    Text(
                      succes && carteGagnee != null
                          ? l10n.successMessage(cibleNom, carteGagnee.nom)
                          : l10n.failMessage(cibleNom),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.inter(
                          fontSize: 14, color: textSecondary),
                    ),

                    // Bannière famille complétée
                    if (nomFamilleCompletee != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border.fromBorderSide(
                              BorderSide(color: Color(0xFFFFD700))),
                        ),
                        child: Text(
                          '🏆 ${l10n.familyCompleted(nomFamilleCompletee)}',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.inter(
                            fontSize: 15,
                            color: const Color(0xFFB8860B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    // Carte gagnée avec animation d'entrée
                    if (succes && carteGagnee != null && familleCarte != null) ...[
                      const SizedBox(height: 20),
                      AnimatedBuilder(
                        animation: _cardController,
                        builder: (context, child) => Opacity(
                          opacity: _cardFade.value,
                          child: Transform.translate(
                            offset: Offset(0, _cardSlide.value),
                            child: Transform.rotate(
                              angle: _cardRotate.value,
                              child: child,
                            ),
                          ),
                        ),
                        child: Center(
                          child: CartePersonnageWidget(
                            personnage: carteGagnee,
                            famille: familleCarte,
                            mode: CarteMode.reveal,
                          ),
                        ),
                      ),
                    ],

                    // Tu rejoues !
                    if (succes) ...[
                      const SizedBox(height: 12),
                      Text(
                        l10n.youReplay,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.inter(
                            fontSize: 14, color: primary),
                      ),
                    ],

                    const Spacer(),

                    // Bouton Continuer (avec FadeIn différé)
                    AnimatedOpacity(
                      opacity: _showContinueButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: IgnorePointer(
                        ignoring: !_showContinueButton,
                        child: PrimaryButton(
                          label: l10n.continueButton,
                          onPressed: _continuer,
                        ),
                      ),
                    ),
                  ],
                ),

                // Fan de cartes (famille complétée)
                if (_showFan)
                  Center(
                    child: AnimatedBuilder(
                      animation: _fanController,
                      builder: (context, _) => Opacity(
                        opacity: _fanOpacity.value,
                        child: Transform.scale(
                          scale: _fanScale.value,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(4, (i) {
                              final angle = (-0.3 + i * 0.2);
                              return Transform.rotate(
                                angle: angle,
                                child: SvgPicture.asset(
                                  'assets/images/card_back_placeholder.svg',
                                  width: 90,
                                  height: 126,
                                ),
                              );
                            }),
                          ),
                        ),
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
