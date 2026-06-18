// État complet et immuable d'une partie à un instant T.

import 'famille.dart';

enum StatutPartie { enCours, terminee }

class JoueurPartie {
  final String id;
  final String nom;
  final List<Personnage> main;
  final List<String> famillesGagnees;

  const JoueurPartie({
    required this.id,
    required this.nom,
    required this.main,
    required this.famillesGagnees,
  });

  JoueurPartie copyWith({
    String? id,
    String? nom,
    List<Personnage>? main,
    List<String>? famillesGagnees,
  }) {
    return JoueurPartie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      main: main ?? this.main,
      famillesGagnees: famillesGagnees ?? this.famillesGagnees,
    );
  }
}

class ResultatDemande {
  final bool succes;
  final Personnage? carteTransferee;
  final String? famillePoseeId;

  const ResultatDemande({
    required this.succes,
    this.carteTransferee,
    this.famillePoseeId,
  });

  ResultatDemande copyWith({
    bool? succes,
    Personnage? carteTransferee,
    String? famillePoseeId,
  }) {
    return ResultatDemande(
      succes: succes ?? this.succes,
      carteTransferee: carteTransferee ?? this.carteTransferee,
      famillePoseeId: famillePoseeId ?? this.famillePoseeId,
    );
  }
}

class GameState {
  final List<JoueurPartie> joueurs;
  final int indexJoueurActif;
  final List<Famille> toutesLesFamilles;
  final StatutPartie statut;
  final List<ResultatDemande> historique;

  const GameState({
    required this.joueurs,
    required this.indexJoueurActif,
    required this.toutesLesFamilles,
    required this.statut,
    required this.historique,
  });

  GameState copyWith({
    List<JoueurPartie>? joueurs,
    int? indexJoueurActif,
    List<Famille>? toutesLesFamilles,
    StatutPartie? statut,
    List<ResultatDemande>? historique,
  }) {
    return GameState(
      joueurs: joueurs ?? this.joueurs,
      indexJoueurActif: indexJoueurActif ?? this.indexJoueurActif,
      toutesLesFamilles: toutesLesFamilles ?? this.toutesLesFamilles,
      statut: statut ?? this.statut,
      historique: historique ?? this.historique,
    );
  }

  JoueurPartie get joueurActif => joueurs[indexJoueurActif];

  JoueurPartie joueurParId(String id) {
    return joueurs.firstWhere((j) => j.id == id);
  }

  // Joueurs autres que le joueur actif ayant au moins une carte en main
  List<JoueurPartie> get ciblesValides {
    return joueurs
        .where((j) => j.id != joueurActif.id && j.main.isNotEmpty)
        .toList();
  }

  // Familles dont ce joueur possède au moins 1 Personnage en main
  List<Famille> famillesDisponiblesPourJoueur(String joueurId) {
    final joueur = joueurParId(joueurId);
    final familleIds = joueur.main.map((p) => p.familleId).toSet();
    return toutesLesFamilles.where((f) => familleIds.contains(f.id)).toList();
  }

  // Toutes les descriptions-clés des cartes du joueur dans une famille donnée.
  // Un joueur peut avoir plusieurs cartes d'une même famille.
  List<Descripteur> descriptionsClesPourJoueur(
      String joueurId, String familleId) {
    final joueur = joueurParId(joueurId);
    final famille =
        toutesLesFamilles.firstWhere((f) => f.id == familleId);
    final cartesDelaFamille =
        joueur.main.where((p) => p.familleId == familleId);
    final cles = <Descripteur>{};
    for (final carte in cartesDelaFamille) {
      cles.addAll(famille.descriptionsClesDe(carte));
    }
    return cles.toList();
  }

  bool get estTerminee => statut == StatutPartie.terminee;

  Map<String, int> get scores {
    return {for (final j in joueurs) j.id: j.famillesGagnees.length};
  }
}
