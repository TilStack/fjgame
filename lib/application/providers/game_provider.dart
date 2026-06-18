// GameNotifier est le pont entre GameEngine (domaine pur) et l'UI.
// Orchestration uniquement : zéro logique de jeu, zéro BuildContext.

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/famille_repository_impl.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/models/game_state.dart';

part 'game_provider.g.dart';

enum EtapeJeu {
  nonInitialise,
  transition,
  enCours,
  resultatTour,
  terminee,
}

class GameNotifierState {
  final GameState? gameState;
  final EtapeJeu etape;
  final ResultatDemande? dernierResultat;
  final String? dernierCibleNom;
  final bool isLoading;
  final String? erreur;

  const GameNotifierState({
    this.gameState,
    this.etape = EtapeJeu.nonInitialise,
    this.dernierResultat,
    this.dernierCibleNom,
    this.isLoading = false,
    this.erreur,
  });

  GameNotifierState copyWith({
    GameState? gameState,
    EtapeJeu? etape,
    ResultatDemande? dernierResultat,
    String? dernierCibleNom,
    bool? isLoading,
    String? erreur,
  }) {
    return GameNotifierState(
      gameState: gameState ?? this.gameState,
      etape: etape ?? this.etape,
      dernierResultat: dernierResultat ?? this.dernierResultat,
      dernierCibleNom: dernierCibleNom ?? this.dernierCibleNom,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur ?? this.erreur,
    );
  }

  // Classement final calculé directement depuis le gameState.
  List<MapEntry<JoueurPartie, int>> get classement {
    final gs = gameState;
    if (gs == null || !gs.estTerminee) return [];
    final entries = gs.joueurs
        .map((j) => MapEntry(j, j.famillesGagnees.length))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}

@Riverpod(keepAlive: true)
class GameNotifier extends _$GameNotifier {
  final _engine = GameEngine();

  @override
  GameNotifierState build() => const GameNotifierState();

  Future<void> demarrerPartieLocale(List<String> nomsJoueurs) async {
    state = state.copyWith(isLoading: true, erreur: null);
    try {
      final familles = await FamilleRepositoryImpl().chargerFamilles();
      final gameState = _engine.initGame(nomsJoueurs, familles);
      state = GameNotifierState(
        gameState: gameState,
        etape: EtapeJeu.transition,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, erreur: e.toString());
    }
  }

  void joueurPret() {
    state = state.copyWith(etape: EtapeJeu.enCours);
  }

  void traiterDemande({
    required String cibleId,
    required String familleId,
    required String descripteurId,
  }) {
    final gs = state.gameState;
    if (gs == null) return;

    final cibleNom = gs.joueurs.firstWhere((j) => j.id == cibleId).nom;
    final nouveauGs = _engine.traiterDemande(
      gameState: gs,
      joueurActifId: gs.joueurActif.id,
      cibleId: cibleId,
      familleId: familleId,
      descripteurId: descripteurId,
    );
    final dernierResultat = nouveauGs.historique.last;
    state = state.copyWith(
      gameState: nouveauGs,
      dernierResultat: dernierResultat,
      dernierCibleNom: cibleNom,
      etape: EtapeJeu.resultatTour,
    );
  }

  void continuerApresResultat() {
    final gs = state.gameState;
    if (gs == null) return;

    if (_engine.estPartieTerminee(gs)) {
      state = state.copyWith(etape: EtapeJeu.terminee);
    } else {
      state = GameNotifierState(
        gameState: gs,
        etape: EtapeJeu.transition,
      );
    }
  }

  void reinitialiser() {
    state = const GameNotifierState();
  }
}
