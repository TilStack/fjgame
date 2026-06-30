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

  // Fix #4 — helper that throws cleanly if no authenticated user.
  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('notAuthenticated');
    return user;
  }

  CollectionReference get _rooms => _firestore.collection('rooms');

  // --- Création de salle ---
  Future<String> createRoom(int maxPlayers) async {
    final user = _requireUser();
    final code = await _generateUniqueCode();
    final roomRef = _rooms.doc();
    final player = OnlinePlayer(
      uid: user.uid,
      pseudo: user.displayName ?? 'Joueur',
      avatarColor: _randomColor(),
      isReady: false,
      isHost: true,
    );
    await roomRef.set({
      'roomCode': code,
      'status': RoomStatus.waiting.name,
      'hostId': user.uid,
      'playerIds': [user.uid],
      'players': [player.toMap()],
      'maxPlayers': maxPlayers,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return roomRef.id;
  }

  // --- Rejoindre une salle ---
  // Fix #1 — use a transaction to avoid duplicate entries via arrayUnion on Maps.
  Future<String> joinRoom(String roomCode) async {
    final user = _requireUser();

    final query = await _rooms
        .where('roomCode', isEqualTo: roomCode.toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) throw Exception('roomNotFound');

    final docRef = query.docs.first.reference;
    final roomId = query.docs.first.id;

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final room = OnlineRoom.fromFirestore(snap);

      if (room.status != RoomStatus.waiting) throw Exception('gameAlreadyStarted');
      if (room.playerIds.length >= room.maxPlayers) throw Exception('roomFull');
      // Already in room — nothing to do (transaction will still commit harmlessly).
      if (room.playerIds.contains(user.uid)) return;

      final player = OnlinePlayer(
        uid: user.uid,
        pseudo: user.displayName ?? 'Joueur',
        avatarColor: _randomColor(),
        isReady: false,
        isHost: false,
      );

      final newPlayerIds = [...room.playerIds, user.uid];
      final newPlayers = [...room.players.map((p) => p.toMap()), player.toMap()];

      tx.update(docRef, {
        'playerIds': newPlayerIds,
        'players': newPlayers,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return roomId;
  }

  // --- Quitter une salle ---
  Future<void> leaveRoom(String roomId) async {
    final user = _requireUser();
    final doc = await _rooms.doc(roomId).get();
    if (!doc.exists) return;
    final room = OnlineRoom.fromFirestore(doc);
    final playerData = room.players.where((p) => p.uid == user.uid).toList();
    if (playerData.isEmpty) return;

    final newPlayerIds = room.playerIds.where((id) => id != user.uid).toList();
    final newPlayers = room.players.where((p) => p.uid != user.uid).toList();

    if (newPlayerIds.isEmpty) {
      await _rooms.doc(roomId).delete();
      return;
    }

    final update = <String, dynamic>{
      'playerIds': newPlayerIds,
      'players': newPlayers.map((p) => p.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (room.hostId == user.uid) {
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
  // Fix #5 — wrap in a transaction to avoid TOCTOU races.
  Future<void> setReady(String roomId, bool isReady) async {
    final user = _requireUser();
    final docRef = _rooms.doc(roomId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final room = OnlineRoom.fromFirestore(snap);

      final updatedPlayers = room.players.map((p) {
        if (p.uid == user.uid) {
          return OnlinePlayer(
            uid: p.uid, pseudo: p.pseudo, avatarColor: p.avatarColor,
            isReady: isReady, isHost: p.isHost,
          );
        }
        return p;
      }).toList();

      tx.update(docRef, {
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- Démarrer la partie (hôte seulement) ---
  // Fix #2 — use a WriteBatch so all hand writes + status update are atomic.
  // Fix #6 — host guard: only the room host may call startGame.
  // TODO Phase 3 Cloud Functions: la validation que seul l'hôte peut démarrer
  // sera déplacée côté serveur.
  Future<void> startGame(String roomId, List<Famille> familles) async {
    final user = _requireUser();

    final doc = await _rooms.doc(roomId).get();
    final room = OnlineRoom.fromFirestore(doc);

    // Fix #6 — host guard
    if (room.hostId != user.uid) throw Exception('notHost');

    final playerNames = room.playerIds.map((uid) {
      final p = room.players.firstWhere((p) => p.uid == uid);
      return p.pseudo;
    }).toList();

    final gameState = _engine.initGame(playerNames, familles);

    final batch = _firestore.batch();

    // Écrire game/state
    final gsRef = _rooms.doc(roomId).collection('game').doc('state');
    final gsMap = <String, dynamic>{
      'currentPlayerIndex': gameState.indexJoueurActif,
      'etape': 'transition',
      'completedFamilies': [],
      'lastAction': null,
      'scores': {for (int i = 0; i < room.playerIds.length; i++)
        room.playerIds[i]: 0},
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.set(gsRef, gsMap);

    // Écrire les mains
    for (int i = 0; i < room.playerIds.length; i++) {
      final uid = room.playerIds[i];
      final joueur = gameState.joueurs[i];
      final handRef = _rooms.doc(roomId).collection('hands').doc(uid);
      batch.set(handRef, {
        'personnageIds': joueur.main.map((p) => p.id).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Passer status à playing
    batch.update(_rooms.doc(roomId), {
      'status': RoomStatus.playing.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
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
    _requireUser();
    await _rooms.doc(roomId).collection('game').doc('state').update({
      'lastAction': {
        'requesterId': _auth.currentUser!.uid,
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
  // Fix #3 — use a WriteBatch so gameState + both hand updates are atomic.
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
    _requireUser();

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

    final requesterJoueur = newState.joueurs[requesterPlayerIds.indexOf(requesterId)];
    final targetJoueur = newState.joueurs[requesterPlayerIds.indexOf(targetId)];

    // Fix #3 — atomic batch: both hand updates + gameState update in one commit.
    final batch = _firestore.batch();

    batch.update(
      _rooms.doc(roomId).collection('hands').doc(requesterId),
      {
        'personnageIds': requesterJoueur.main.map((p) => p.id).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _rooms.doc(roomId).collection('hands').doc(targetId),
      {
        'personnageIds': targetJoueur.main.map((p) => p.id).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.update(
      _rooms.doc(roomId).collection('game').doc('state'),
      {
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
      },
    );

    await batch.commit();
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
    final user = _requireUser();
    return _rooms.doc(roomId).collection('hands').doc(user.uid)
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
