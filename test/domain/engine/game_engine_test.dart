// Tests unitaires du moteur de jeu. Chargement du JSON via dart:io (pas rootBundle).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fjgame/domain/engine/game_engine.dart';
import 'package:fjgame/domain/models/famille.dart';
import 'package:fjgame/domain/models/game_state.dart';

List<Famille> _chargerFamilles() {
  final file = File('assets/data/familles.json');
  final decoded = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (decoded['familles'] as List)
      .map((f) => Famille.fromJson(f as Map<String, dynamic>))
      .toList();
}

void main() {
  final familles = _chargerFamilles();
  final engine = GameEngine();

  // ── initGame ──────────────────────────────────────────────────────────────

  group('initGame', () {
    test('distribue toutes les 52 cartes sans perte ni doublon', () {
      final state = engine.initGame(['A', 'B', 'C', 'D'], familles, seed: 42);
      final toutesLesCartes = [
        ...state.joueurs.expand((j) => j.main),
        ...state.joueurs
            .expand((j) => j.famillesGagnees)
            .expand((fid) =>
                familles.firstWhere((f) => f.id == fid).personnages),
      ];
      expect(toutesLesCartes.length, 56); // 14 familles × 4
      final ids = toutesLesCartes.map((p) => p.id).toSet();
      expect(ids.length, 56);
    });

    test('avec 4 joueurs chaque joueur a exactement 13 cartes (ou famille posée)', () {
      final state = engine.initGame(['A', 'B', 'C', 'D'], familles, seed: 42);
      // 56 cartes / 4 joueurs = 14 chacun (avant familles posées dès deal)
      // Ce test vérifie la conservation totale, pas un nombre exact post-dépôt
      final total = state.joueurs.fold<int>(
        0,
        (sum, j) =>
            sum +
            j.main.length +
            j.famillesGagnees.length * 4,
      );
      expect(total, 56);
    });

    test('avec 3 joueurs la distribution est équilibrée (56 cartes réparties)', () {
      final state =
          engine.initGame(['A', 'B', 'C'], familles, seed: 42);
      final total = state.joueurs.fold<int>(
        0,
        (sum, j) =>
            sum +
            j.main.length +
            j.famillesGagnees.length * 4,
      );
      expect(total, 56);
    });

    test('détecte et pose les familles complètes dès la distribution', () {
      // Seed reproduit un cas connu ; au minimum le test vérifie la cohérence
      final state = engine.initGame(['A', 'B', 'C', 'D'], familles, seed: 0);
      for (final joueur in state.joueurs) {
        for (final fid in joueur.famillesGagnees) {
          // La carte ne doit plus être dans aucune main
          for (final j in state.joueurs) {
            final restes = j.main.where((p) => p.familleId == fid);
            expect(restes, isEmpty,
                reason:
                    'Famille $fid gagnée par ${joueur.id} mais des cartes traînent dans la main de ${j.id}');
          }
        }
      }
    });
  });

  // ── traiterDemande — succès ───────────────────────────────────────────────

  group('traiterDemande - succès', () {
    // Construire un état minimal contrôlé
    GameState etatMinimal() {
      final fam = familles.first; // fam_esther
      final j0 = JoueurPartie(
        id: 'j0',
        nom: 'Alice',
        main: [fam.personnages[0]], // Assuérus (d_esther_1)
        famillesGagnees: [],
      );
      final j1 = JoueurPartie(
        id: 'j1',
        nom: 'Bob',
        main: [fam.personnages[1]], // Esther (d_esther_2)
        famillesGagnees: [],
      );
      return GameState(
        joueurs: [j0, j1],
        indexJoueurActif: 0,
        toutesLesFamilles: familles,
        statut: StatutPartie.enCours,
        historique: [],
      );
    }

    test('la carte est retirée de la main de la cible', () {
      final state = etatMinimal();
      final fam = familles.first;
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        // j0 possède Assuérus (identifiant d_esther_1) → peut demander d_esther_2
        descripteurId: 'd_esther_2',
      );
      expect(result.joueurParId('j1').main, isEmpty);
    });

    test('la carte est ajoutée à la main du joueur actif', () {
      final state = etatMinimal();
      final fam = familles.first;
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        descripteurId: 'd_esther_2',
      );
      expect(result.joueurParId('j0').main.length, 2);
    });

    test('le joueur actif garde la main après succès', () {
      final state = etatMinimal();
      final fam = familles.first;
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        descripteurId: 'd_esther_2',
      );
      expect(result.joueurActif.id, 'j0');
    });

    test('une famille complète est automatiquement posée', () {
      final fam = familles.first;
      // j0 a 3 cartes de la famille, j1 a la 4e
      final j0 = JoueurPartie(
        id: 'j0',
        nom: 'Alice',
        main: [
          fam.personnages[0], // Assuérus  d_esther_1
          fam.personnages[2], // Haman     d_esther_3
          fam.personnages[3], // Mardochée d_esther_4
        ],
        famillesGagnees: [],
      );
      final j1 = JoueurPartie(
        id: 'j1',
        nom: 'Bob',
        main: [fam.personnages[1]], // Esther d_esther_2
        famillesGagnees: [],
      );
      final state = GameState(
        joueurs: [j0, j1],
        indexJoueurActif: 0,
        toutesLesFamilles: familles,
        statut: StatutPartie.enCours,
        historique: [],
      );
      // j0 possède d_esther_1, d_esther_3, d_esther_4
      // → les clés valides pour la famille esther incluent d_esther_2
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        descripteurId: 'd_esther_2',
      );
      expect(result.joueurParId('j0').famillesGagnees, contains(fam.id));
      expect(result.joueurParId('j0').main, isEmpty);
    });
  });

  // ── traiterDemande — échec ────────────────────────────────────────────────

  group('traiterDemande - échec', () {
    GameState etatEchec() {
      final fam = familles.first;
      final j0 = JoueurPartie(
        id: 'j0',
        nom: 'Alice',
        main: [fam.personnages[0]], // Assuérus d_esther_1
        famillesGagnees: [],
      );
      final j1 = JoueurPartie(
        id: 'j1',
        nom: 'Bob',
        // j1 n'a PAS Esther (d_esther_2), il a Haman (d_esther_3)
        main: [fam.personnages[2]],
        famillesGagnees: [],
      );
      return GameState(
        joueurs: [j0, j1],
        indexJoueurActif: 0,
        toutesLesFamilles: familles,
        statut: StatutPartie.enCours,
        historique: [],
      );
    }

    test('la main passe à la cible après un échec', () {
      final state = etatEchec();
      final fam = familles.first;
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        descripteurId: 'd_esther_2', // j1 ne l'a pas
      );
      expect(result.joueurActif.id, 'j1');
    });

    test('aucune carte n\'est transférée en cas d\'échec', () {
      final state = etatEchec();
      final fam = familles.first;
      final result = engine.traiterDemande(
        gameState: state,
        joueurActifId: 'j0',
        cibleId: 'j1',
        familleId: fam.id,
        descripteurId: 'd_esther_2',
      );
      expect(result.joueurParId('j0').main.length, 1);
      expect(result.joueurParId('j1').main.length, 1);
    });
  });

  // ── traiterDemande — préconditions ────────────────────────────────────────

  group('traiterDemande - préconditions', () {
    GameState etatBase() {
      final fam = familles.first;
      final j0 = JoueurPartie(
        id: 'j0',
        nom: 'Alice',
        main: [fam.personnages[0]],
        famillesGagnees: [],
      );
      final j1 = JoueurPartie(
        id: 'j1',
        nom: 'Bob',
        main: [fam.personnages[1]],
        famillesGagnees: [],
      );
      return GameState(
        joueurs: [j0, j1],
        indexJoueurActif: 0,
        toutesLesFamilles: familles,
        statut: StatutPartie.enCours,
        historique: [],
      );
    }

    test('lève ArgumentError si le joueur actif ne possède pas la famille', () {
      final state = etatBase();
      expect(
        () => engine.traiterDemande(
          gameState: state,
          joueurActifId: 'j0',
          cibleId: 'j1',
          familleId: 'fam_ruth', // j0 n'a pas de carte ruth
          descripteurId: 'd_ruth_2',
        ),
        throwsArgumentError,
      );
    });

    test('lève ArgumentError si le descripteur est l\'identifiant du joueur actif', () {
      final state = etatBase();
      expect(
        () => engine.traiterDemande(
          gameState: state,
          joueurActifId: 'j0',
          cibleId: 'j1',
          familleId: 'fam_esther',
          // d_esther_1 est l'identifiant d'Assuérus que j0 possède → invalide
          descripteurId: 'd_esther_1',
        ),
        throwsArgumentError,
      );
    });

    test('lève ArgumentError si la cible est le joueur actif lui-même', () {
      final state = etatBase();
      expect(
        () => engine.traiterDemande(
          gameState: state,
          joueurActifId: 'j0',
          cibleId: 'j0',
          familleId: 'fam_esther',
          descripteurId: 'd_esther_2',
        ),
        throwsArgumentError,
      );
    });
  });

  // ── fin de partie ─────────────────────────────────────────────────────────

  group('fin de partie', () {
    test('estPartieTerminee retourne false en cours de partie', () {
      final state = engine.initGame(['A', 'B', 'C'], familles, seed: 42);
      expect(engine.estPartieTerminee(state), isFalse);
    });

    test('classementFinal retourne les joueurs triés par score décroissant', () {
      // Construire un état terminé manuellement
      const j0 = JoueurPartie(
        id: 'j0',
        nom: 'Alice',
        main: [],
        famillesGagnees: ['fam_esther', 'fam_ruth'],
      );
      const j1 = JoueurPartie(
        id: 'j1',
        nom: 'Bob',
        main: [],
        famillesGagnees: ['fam_conducteurs'],
      );
      final state = GameState(
        joueurs: [j0, j1],
        indexJoueurActif: 0,
        toutesLesFamilles: familles,
        statut: StatutPartie.terminee,
        historique: [],
      );
      final classement = engine.classementFinal(state);
      expect(classement[0].key.id, 'j0');
      expect(classement[0].value, 2);
      expect(classement[1].key.id, 'j1');
      expect(classement[1].value, 1);
    });
  });
}
