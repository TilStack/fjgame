// Dépôt Firebase Firestore pour le multijoueur en ligne.
// Gère la création/rejointe de salles, la synchronisation d'état et les mains.
// TODO Phase 3 Cloud Functions: la validation serveur des moves sera déléguée ici.

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/famille.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/online_room.dart';
import '../../domain/engine/game_engine.dart';

class OnlineGameRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final _engine = GameEngine();

  OnlineGameRepository({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  String get _uid => _auth.currentUser!.uid;
  String get _pseudo => _auth.currentUser!.displayName ?? 'Joueur';

  CollectionReference get _rooms => _firestore.collection('rooms');

  // --- Création de salle ---
  Future<String> createRoom(int maxPlayers) async {
    final code = await _generateUniqueCode();
    final roomRef = _rooms.doc();
    final player = OnlinePlayer(
      uid: _uid,
      pseudo: _pseudo,
      avatarColor: _randomColor(),
      isReady: false,
      isHost: true,
    );
    await roomRef.set({
      'roomCode': code,
      'status': RoomStatus.waiting.name,
      'hostId': _uid,
      'playerIds': [_uid],
      'players': [player.toMap()],
      'maxPlayers': maxPlayers,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  // --- Rejoindre une salle ---
  Future<String> joinRoom(String roomCode) async {
    final query = await _rooms
        .where('roomCode', isEqualTo: roomCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('roomNotFound');

    final doc = query.docs.first;
    final room = OnlineRoom.fromFirestore(doc);

    if (room.status != RoomStatus.waiting) throw Exception('gameAlreadyStarted');
    if (room.playerIds.length >= room.maxPlayers) throw Exception('roomFull');
    if (room.playerIds.contains(_uid)) return doc.id;

    final player = OnlinePlayer(
      uid: _uid,
      pseudo: _pseudo,
      avatarColor: _randomColor(),
      isReady: false,
      isHost: false,
    );
    await doc.reference.update({
      'playerIds': FieldValue.arrayUnion([_uid]),
      'players': FieldValue.arrayUnion([player.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // --- Quitter une salle ---
  Future<void> leaveRoom(String roomId) async {
    final doc = await _rooms.doc(roomId).get();
    if (!doc.exists) return;
    final room = OnlineRoom.fromFirestore(doc);
    final playerData = room.players.where((p) => p.uid == _uid).toList();
    if (playerData.isEmpty) return;

    final newPlayerIds = room.playerIds.where((id) => id != _uid).toList();
    final newPlayers = room.players.where((p) => p.uid != _uid).toList();

    if (newPlayerIds.isEmpty) {
      await _rooms.doc(roomId).delete();
      return;
    }

    final update = <String, dynamic>{
      'playerIds': newPlayerIds,
      'players': newPlayers.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (room.hostId == _uid) {
      update['hostId'] = newPlayerIds.first;
      final newPlayers2 = newPlayers.map((p) {
        if (p.uid == newPlayerIds.first) {
          return OnlinePlayer(
            uid: p.uid, pseudo: p.pseudo, avatarColor: p.avatarColor,
            isReady: p.isReady, isHost: true,
          );
        }
        return p;
      }).toList();
      update['players'] = newPlayers2.map((p) => p.toMap()).toList();
    }
    await _rooms.doc(roomId).update(update);
  }

  // --- Prêt/Pas prêt ---
  Future<void> setReady(String roomId, bool isReady) async {
    final doc = await _rooms.doc(roomId).get();
    final room = OnlineRoom.fromFirestore(doc);
    final updatedPlayers = room.players.map((p) {
      if (p.uid == _uid) {
        return OnlinePlayer(
          uid: p.uid, pseudo: p.pseudo, avatarColor: p.avatarColor,
          isReady: isReady, isHost: p.isHost,
        );
      }
      return p;
    }).toList();
    await _rooms.doc(roomId).update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Démarrer la partie (hôte seulement) ---
  // TODO Phase 3 Cloud Functions: la validation que seul l'hôte peut démarrer
  // sera déplacée côté serveur.
  Future<void> startGame(String roomId, List<Famille> familles) async {
    final doc = await _rooms.doc(roomId).get();
    final room = OnlineRoom.fromFirestore(doc);

    final playerNames = room.playerIds.map((uid) {
      final p = room.players.firstWhere((p) => p.uid == uid);
      return p.pseudo;
    }).toList();

    final gameState = _engine.initGame(playerNames, familles);

    // Écrire game/state
    final gsMap = <String, dynamic>{
      'currentPlayerIndex': gameState.indexJoueurActif,
      'etape': 'transition',
      'completedFamilies': [],
      'lastAction': null,
      'scores': {for (int i = 0; i < room.playerIds.length; i++)
        room.playerIds[i]: 0},
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _rooms.doc(roomId).collection('game').doc('state').set(gsMap);

    // Écrire les mains
    for (int i = 0; i < room.playerIds.length; i++) {
      final uid = room.playerIds[i];
      final joueur = gameState.joueurs[i];
      await _rooms.doc(roomId).collection('hands').doc(uid).set({
        'personnageIds': joueur.main.map((p) => p.id).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Passer status à playing
    await _rooms.doc(roomId).update({
      'status': RoomStatus.playing.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Soumettre un move ---
  // TODO Phase 3 Cloud Functions: la validation et résolution du move sera
  // déléguée à une Cloud Function pour éviter la dépendance à l'hôte client.
  // Architecture actuelle : le joueur écrit lastAction avec success=null,
  // l'hôte détecte ce changement via stream et résout le move localement.
  Future<void> submitMove(
    String roomId,
    String targetId,
    String familyId,
    String descripteurId,
  ) async {
    await _rooms.doc(roomId).collection('game').doc('state').update({
      'lastAction': {
        'requesterId': _uid,
        'targetId': targetId,
        'familyId': familyId,
        'descripteurId': descripteurId,
        'success': null,
        'cardTransferedId': null,
        'familyCompletedId': null,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Résoudre un move (appelé par l'hôte) ---
  // TODO Phase 3 Cloud Functions: cette méthode sera supprimée et remplacée
  // par la CF qui exécutera la même logique côté serveur avec accès complet.
  Future<void> resolveMove({
    required String roomId,
    required GameState localGameState,
    required List<Famille> familles,
    required String requesterId,
    required String targetId,
    required String familyId,
    required String descripteurId,
    required List<String> requesterPlayerIds,
  }) async {
    final requesterJoueurId = localGameState.joueurs[
        requesterPlayerIds.indexOf(requesterId)].id;
    final targetJoueurId = localGameState.joueurs[
        requesterPlayerIds.indexOf(targetId)].id;

    late GameState newState;
    try {
      newState = _engine.traiterDemande(
        gameState: localGameState,
        joueurActifId: requesterJoueurId,
        cibleId: targetJoueurId,
        familleId: familyId,
        descripteurId: descripteurId,
      );
    } catch (_) {
      // Si la demande échoue (précondition non satisfaite), marquer échec
      await _rooms.doc(roomId).collection('game').doc('state').update({
        'lastAction': {
          'requesterId': requesterId,
          'targetId': targetId,
          'familyId': familyId,
          'descripteurId': descripteurId,
          'success': false,
          'cardTransferedId': null,
          'familyCompletedId': null,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final lastResult = newState.historique.last;
    final isTerminee = newState.estTerminee;
    final newScores = <String, int>{};
    for (int i = 0; i < requesterPlayerIds.length; i++) {
      newScores[requesterPlayerIds[i]] = newState.joueurs[i].famillesGagnees.length;
    }

    // Mettre à jour les mains des joueurs concernés
    final requesterJoueur = newState.joueurs[requesterPlayerIds.indexOf(requesterId)];
    final targetJoueur = newState.joueurs[requesterPlayerIds.indexOf(targetId)];
    await _rooms.doc(roomId).collection('hands').doc(requesterId).update({
      'personnageIds': requesterJoueur.main.map((p) => p.id).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _rooms.doc(roomId).collection('hands').doc(targetId).update({
      'personnageIds': targetJoueur.main.map((p) => p.id).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _rooms.doc(roomId).collection('game').doc('state').update({
      'currentPlayerIndex': newState.indexJoueurActif,
      'etape': isTerminee ? 'terminee' : (lastResult.succes ? 'en_cours' : 'transition'),
      'scores': newScores,
      'lastAction': {
        'requesterId': requesterId,
        'targetId': targetId,
        'familyId': familyId,
        'descripteurId': descripteurId,
        'success': lastResult.succes,
        'cardTransferedId': lastResult.carteTransferee?.id,
        'familyCompletedId': lastResult.famillePoseeId,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Streams ---
  Stream<OnlineRoom?> roomStream(String roomId) {
    return _rooms.doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return OnlineRoom.fromFirestore(snap);
    });
  }

  Stream<OnlineGameState?> gameStateStream(String roomId) {
    return _rooms.doc(roomId).collection('game').doc('state')
        .snapshots().map((snap) {
      if (!snap.exists) return null;
      return OnlineGameState.fromFirestore(snap);
    });
  }

  Stream<List<String>> myHandStream(String roomId) {
    return _rooms.doc(roomId).collection('hands').doc(_uid)
        .snapshots().map((snap) {
      if (!snap.exists) return [];
      final data = snap.data()!;
      return List<String>.from(data['personnageIds'] as List? ?? []);
    });
  }

  // --- Helpers privés ---
  Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rng = Random();
    while (true) {
      final code = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
      );
      final existing = await _rooms
          .where('roomCode', isEqualTo: code)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) return code;
    }
  }

  String _randomColor() {
    const colors = [
      '#E53935', '#8E24AA', '#1E88E5', '#00897B',
      '#43A047', '#FB8C00', '#F4511E', '#6D4C41',
    ];
    return colors[Random().nextInt(colors.length)];
  }
}
