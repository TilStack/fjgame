// Moteur de jeu pur Dart. Toutes les méthodes sont des fonctions pures :
// elles prennent un GameState en entrée et retournent un nouveau GameState.
// Aucun état interne mutable, aucune dépendance Flutter.

import 'dart:math';
import '../models/famille.dart';
import '../models/game_state.dart';

class GameEngine {
  // Initialise une nouvelle partie avec 3 à 6 joueurs.
  // seed : valeur optionnelle pour reproductibilité (tests).
  GameState initGame(
    List<String> playerNames,
    List<Famille> familles, {
    int? seed,
  }) {
    assert(playerNames.length >= 3 && playerNames.length <= 6,
        'Le nombre de joueurs doit être entre 3 et 6');

    final joueurs = List.generate(
      playerNames.length,
      (i) => JoueurPartie(
        id: 'j$i',
        nom: playerNames[i],
        main: [],
        famillesGagnees: [],
      ),
    );

    // Constituer et mélanger toutes les cartes
    final toutes = familles.expand((f) => f.personnages).toList();
    final rng = seed != null ? Random(seed) : Random();
    toutes.shuffle(rng);

    // Distribution round-robin
    final mains = List.generate(joueurs.length, (_) => <Personnage>[]);
    for (var i = 0; i < toutes.length; i++) {
      mains[i % joueurs.length].add(toutes[i]);
    }

    // Construire les joueurs avec leurs mains initiales
    var joueursAvecMain = List.generate(
      joueurs.length,
      (i) => joueurs[i].copyWith(main: mains[i]),
    );

    // Poser immédiatement les familles complètes dès la distribution
    joueursAvecMain = joueursAvecMain.map((j) {
      return _deposerFamillesCompletes(j, familles);
    }).toList();

    return GameState(
      joueurs: joueursAvecMain,
      indexJoueurActif: 0,
      toutesLesFamilles: familles,
      statut: StatutPartie.enCours,
      historique: [],
    );
  }

  // Résout une demande du joueur actif vers une cible.
  GameState traiterDemande({
    required GameState gameState,
    required String joueurActifId,
    required String cibleId,
    required String familleId,
    required String descripteurId,
  }) {
    // Vérification des préconditions
    if (joueurActifId != gameState.joueurActif.id) {
      throw ArgumentError(
          'joueurActifId "$joueurActifId" ne correspond pas au joueur actif "${gameState.joueurActif.id}"');
    }
    if (cibleId == joueurActifId) {
      throw ArgumentError('La cible ne peut pas être le joueur actif lui-même');
    }

    final cible = gameState.joueurs.firstWhere(
      (j) => j.id == cibleId,
      orElse: () => throw ArgumentError('Cible "$cibleId" introuvable'),
    );

    if (cible.main.isEmpty) {
      throw ArgumentError('La cible "$cibleId" n\'a pas de cartes en main');
    }

    final joueurActif = gameState.joueurActif;
    final cartesJoueurDansFamille =
        joueurActif.main.where((p) => p.familleId == familleId).toList();

    if (cartesJoueurDansFamille.isEmpty) {
      throw ArgumentError(
          'Le joueur actif ne possède aucune carte de la famille "$familleId"');
    }

    // Vérifier que descripteurId est bien une clé-description (non-identifiant)
    // pour les cartes du joueur actif dans cette famille
    final famille = gameState.toutesLesFamilles
        .firstWhere((f) => f.id == familleId);
    final clesValides = <String>{};
    for (final carte in cartesJoueurDansFamille) {
      for (final d in famille.descriptionsClesDe(carte)) {
        clesValides.add(d.id);
      }
    }
    if (!clesValides.contains(descripteurId)) {
      throw ArgumentError(
          'Le descripteur "$descripteurId" n\'est pas une clé-description valide '
          'pour le joueur actif dans la famille "$familleId"');
    }

    // Chercher la carte dans la main de la cible
    Personnage? carteRecherchee;
    try {
      carteRecherchee = cible.main.firstWhere(
        (p) =>
            p.familleId == familleId &&
            p.descripteurIdentifiantId == descripteurId,
      );
    } catch (_) {
      carteRecherchee = null;
    }

    if (carteRecherchee != null) {
      return _resoudreSucces(
        gameState: gameState,
        joueurActifId: joueurActifId,
        cibleId: cibleId,
        carte: carteRecherchee,
        famille: famille,
      );
    } else {
      return _resoudreEchec(
        gameState: gameState,
        cibleId: cibleId,
        familleId: familleId,
        descripteurId: descripteurId,
      );
    }
  }

  bool estPartieTerminee(GameState gameState) {
    final totalFamilles = gameState.toutesLesFamilles.length;
    final famillesGagnees = gameState.joueurs
        .expand((j) => j.famillesGagnees)
        .length;
    return famillesGagnees >= totalFamilles;
  }

  // Classement final trié par nombre de familles décroissant.
  // Retourne une liste vide si la partie n'est pas terminée.
  List<MapEntry<JoueurPartie, int>> classementFinal(GameState gameState) {
    if (!gameState.estTerminee) return [];
    final entries = gameState.joueurs
        .map((j) => MapEntry(j, j.famillesGagnees.length))
        .toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // --- Méthodes privées ---

  GameState _resoudreSucces({
    required GameState gameState,
    required String joueurActifId,
    required String cibleId,
    required Personnage carte,
    required Famille famille,
  }) {
    var joueurs = List<JoueurPartie>.from(gameState.joueurs);
    final idxActif = joueurs.indexWhere((j) => j.id == joueurActifId);
    final idxCible = joueurs.indexWhere((j) => j.id == cibleId);

    // Retirer la carte de la cible
    final nouvellMainCible = List<Personnage>.from(joueurs[idxCible].main)
      ..remove(carte);
    joueurs[idxCible] = joueurs[idxCible].copyWith(main: nouvellMainCible);

    // Ajouter la carte au joueur actif
    final nouvellMainActif = List<Personnage>.from(joueurs[idxActif].main)
      ..add(carte);
    joueurs[idxActif] = joueurs[idxActif].copyWith(main: nouvellMainActif);

    // Vérifier si une famille est complète
    joueurs[idxActif] =
        _deposerFamillesCompletes(joueurs[idxActif], gameState.toutesLesFamilles);

    // Famille posée ce tour ?
    final famillePoseeId =
        joueurs[idxActif].famillesGagnees.length >
                gameState.joueurs[idxActif].famillesGagnees.length
            ? famille.id
            : null;

    final resultat = ResultatDemande(
      succes: true,
      carteTransferee: carte,
      famillePoseeId: famillePoseeId,
    );

    // Vérifier fin de partie
    final nouveauStatut =
        estPartieTermineeAvecJoueurs(joueurs, gameState.toutesLesFamilles)
            ? StatutPartie.terminee
            : StatutPartie.enCours;

    return gameState.copyWith(
      joueurs: joueurs,
      // Le joueur actif garde la main (indexJoueurActif inchangé)
      statut: nouveauStatut,
      historique: [...gameState.historique, resultat],
    );
  }

  GameState _resoudreEchec({
    required GameState gameState,
    required String cibleId,
    required String familleId,
    required String descripteurId,
  }) {
    const resultat = ResultatDemande(succes: false);
    final joueurs = gameState.joueurs;

    // La main passe à la cible
    final idxCible = joueurs.indexWhere((j) => j.id == cibleId);
    if (joueurs[idxCible].main.isNotEmpty) {
      return gameState.copyWith(
        indexJoueurActif: idxCible,
        historique: [...gameState.historique, resultat],
      );
    }

    // La cible a la main vide : chercher le prochain joueur valide en ordre circulaire
    final n = joueurs.length;
    for (var delta = 1; delta < n; delta++) {
      final idx = (idxCible + delta) % n;
      if (joueurs[idx].main.isNotEmpty) {
        return gameState.copyWith(
          indexJoueurActif: idx,
          historique: [...gameState.historique, resultat],
        );
      }
    }

    // Aucun joueur n'a de carte : terminer la partie
    return gameState.copyWith(
      statut: StatutPartie.terminee,
      historique: [...gameState.historique, resultat],
    );
  }

  // Détecte et dépose les familles complètes (4/4) dans la main du joueur.
  JoueurPartie _deposerFamillesCompletes(
      JoueurPartie joueur, List<Famille> familles) {
    var main = List<Personnage>.from(joueur.main);
    var famillesGagnees = List<String>.from(joueur.famillesGagnees);

    for (final famille in familles) {
      final cartesDelaFamille =
          main.where((p) => p.familleId == famille.id).toList();
      if (cartesDelaFamille.length == 4) {
        main.removeWhere((p) => p.familleId == famille.id);
        famillesGagnees.add(famille.id);
      }
    }

    return joueur.copyWith(main: main, famillesGagnees: famillesGagnees);
  }

  // Vérifie si toutes les familles ont été gagnées (utilisé après mutation)
  bool estPartieTermineeAvecJoueurs(
      List<JoueurPartie> joueurs, List<Famille> familles) {
    final famillesGagnees =
        joueurs.expand((j) => j.famillesGagnees).toSet();
    return famillesGagnees.length >= familles.length;
  }
}
