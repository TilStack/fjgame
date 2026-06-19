// Écran principal du tour : le joueur actif consulte sa main et formule sa demande.
// Sections 3 et 4 apparaissent avec FadeIn + SlideIn quand elles deviennent visibles.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers/game_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/famille.dart';
import '../../../domain/models/game_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/game/carte_personnage_widget.dart';
import '../../widgets/game/descripteur_selector_widget.dart';
import '../../widgets/game/famille_selector_widget.dart';
import '../../widgets/game/joueur_selector_widget.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Famille? _selectedFamille;
  Descripteur? _selectedDescripteur;
  JoueurPartie? _selectedCible;

  void _onFamilleSelected(Famille f) {
    setState(() {
      _selectedFamille = f;
      _selectedDescripteur = null;
      _selectedCible = null;
    });
  }

  void _onDescripteurSelected(Descripteur d) {
    setState(() {
      _selectedDescripteur = d;
      _selectedCible = null;
    });
  }

  void _onCibleSelected(JoueurPartie j) {
    setState(() => _selectedCible = j);
  }

  void _ask() {
    if (_selectedFamille == null ||
        _selectedDescripteur == null ||
        _selectedCible == null) {
      return;
    }
    ref.read(gameNotifierProvider.notifier).traiterDemande(
          cibleId: _selectedCible!.id,
          familleId: _selectedFamille!.id,
          descripteurId: _selectedDescripteur!.id,
        );
    context.go('/game/resultat');
  }

  void _showScoresSheet(
      BuildContext context, GameState gs, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.scores,
              style: AppTextStyles.cinzel(fontSize: 20, color: primary),
            ),
            const SizedBox(height: 16),
            ...gs.joueurs.map((j) {
              final isActif = j.id == gs.joueurActif.id;
              final familleNames = j.famillesGagnees.map((fid) {
                return gs.toutesLesFamilles
                    .firstWhere((f) => f.id == fid)
                    .nom;
              }).toList();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isActif)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child:
                                Icon(Icons.play_arrow, size: 16, color: primary),
                          ),
                        Text(
                          j.nom,
                          style: AppTextStyles.inter(
                            fontSize: 15,
                            color: isActif
                                ? primary
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary),
                            fontWeight:
                                isActif ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l10n.familiesCount(j.famillesGagnees.length),
                          style: AppTextStyles.inter(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (familleNames.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 6,
                          children: familleNames
                              .map(
                                (name) => Chip(
                                  label: Text(name,
                                      style: AppTextStyles.inter(
                                          fontSize: 11, color: Colors.white)),
                                  backgroundColor: AppColors.success,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _animatedSection({required bool visible, required Widget child}) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, c) => Transform.translate(
            offset: Offset(0, (1 - animation.value) * 20),
            child: c,
          ),
          child: child,
        ),
      ),
      child: visible
          ? KeyedSubtree(key: const ValueKey(true), child: child)
          : const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameNotifier = ref.watch(gameNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (gameNotifier.gameState == null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.go('/lobby-local'));
      return const SizedBox.shrink();
    }

    final gs = gameNotifier.gameState!;
    final joueurActif = gs.joueurActif;
    final familles = gs.famillesDisponiblesPourJoueur(joueurActif.id);
    final descripteurs = _selectedFamille != null
        ? gs.descriptionsClesPourJoueur(joueurActif.id, _selectedFamille!.id)
        : <Descripteur>[];
    final cibles = gs.ciblesValides;
    final canAsk = _selectedFamille != null &&
        _selectedDescripteur != null &&
        _selectedCible != null;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            joueurActif.nom,
            style: AppTextStyles.cinzel(fontSize: 18, color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.leaderboard),
              tooltip: l10n.scores,
              onPressed: () => _showScoresSheet(context, gs, l10n),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // SECTION 1 — Ma main
            Text(
              l10n.myHand,
              style: AppTextStyles.inter(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 10),
            ...joueurActif.main.map((p) {
              final fam = gs.toutesLesFamilles
                  .firstWhere((f) => f.id == p.familleId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CartePersonnageWidget(
                  personnage: p,
                  famille: fam,
                  isSelected: _selectedFamille?.id == p.familleId,
                ),
              );
            }),
            const SizedBox(height: 20),

            // SECTION 2 — Choisir une famille
            Text(
              l10n.chooseFamily,
              style: AppTextStyles.inter(fontSize: 14, color: textSecondary),
            ),
            const SizedBox(height: 10),
            FamilleSelectorWidget(
              familles: familles,
              familleSelectee: _selectedFamille,
              onSelect: _onFamilleSelected,
            ),
            const SizedBox(height: 20),

            // SECTION 3 — Choisir un descripteur (animée)
            _animatedSection(
              visible: _selectedFamille != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseDescriptor,
                    style: AppTextStyles.inter(
                        fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 10),
                  DescripteurSelectorWidget(
                    descripteurs: descripteurs,
                    descripteurSelectionne: _selectedDescripteur,
                    onSelect: _onDescripteurSelected,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // SECTION 4 — Choisir un joueur (animée)
            _animatedSection(
              visible:
                  _selectedFamille != null && _selectedDescripteur != null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chooseTarget,
                    style: AppTextStyles.inter(
                        fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 10),
                  JoueurSelectorWidget(
                    joueurs: cibles,
                    joueurSelectionne: _selectedCible,
                    onSelect: _onCibleSelected,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // BOUTON D'ACTION
            PrimaryButton(
              label: l10n.askButton,
              onPressed: canAsk ? _ask : null,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
