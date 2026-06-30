// Gestionnaire d'état Riverpod pour le multijoueur en ligne Firebase.
// Orchestre OnlineGameRepository, les streams Firestore, et la résolution locale côté hôte.

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/local/famille_repository_impl.dart';
import '../../data/remote/online_game_repository.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/models/famille.dart';
import '../../domain/models/game_state.dart';
import '../../domain/models/online_room.dart';

part 'online_game_provider.g.dart';

enum OnlineEtape {
  idle,
  creating,
  joining,
  waiting,
  myTurn,
  watchingOtherTurn,
  showingResult,
  gameOver,
}

class OnlineGameNotifierState {
  final OnlineRoom? room;
  final OnlineGameState? gameState;
  final List<String> myHand;
  final List<Famille> familles;
  final OnlineEtape etape;
  final bool isLoading;
  final String? erreur;
  final Map<String, dynamic>? lastActionResult;
  final String? roomId;

  const OnlineGameNotifierState({
    this.room,
    this.gameState,
    this.myHand = const [],
    this.familles = const [],
    this.etape = OnlineEtape.idle,
    this.isLoading = false,
    this.erreur,
    this.lastActionResult,
    this.roomId,
  });

  OnlineGameNotifierState copyWith({
    OnlineRoom? room,
    OnlineGameState? gameState,
    List<String>? myHand,
    List<Famille>? familles,
    OnlineEtape? etape,
    bool? isLoading,
    String? erreur,
    Map<String, dynamic>? lastActionResult,
    String? roomId,
  }) {
    return OnlineGameNotifierState(
      room: room ?? this.room,
      gameState: gameState ?? this.gameState,
      myHand: myHand ?? this.myHand,
      familles: familles ?? this.familles,
      etape: etape ?? this.etape,
      isLoading: isLoading ?? this.isLoading,
      erreur: erreur ?? this.erreur,
      lastActionResult: lastActionResult ?? this.lastActionResult,
      roomId: roomId ?? this.roomId,
    );
  }
}

@Riverpod(keepAlive: true)
class OnlineGameNotifier extends _$OnlineGameNotifier {
  late final OnlineGameRepository _repo;
  final _engine = GameEngine();

  StreamSubscription<OnlineRoom?>? _roomSub;
  StreamSubscription<OnlineGameState?>? _gameStateSub;
  StreamSubscription<List<String>>? _handSub;

  // Hôte uniquement : état local du moteur de jeu pour résoudre les moves.
  GameState? _localGameState;
  // Verrou pour éviter les appels resolveMove en double sur le même lastAction.
  bool _resolving = false;
  // Timer pour l'affichage du résultat — annulé si on quitte la salle avant 2500ms.
  Timer? _showResultTimer;

  @override
  OnlineGameNotifierState build() {
    _repo = OnlineGameRepository(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    ref.onDispose(dispose);
    // Charger les familles en arrière-plan dès la construction.
    Future.microtask(_ensureFamilles);
    return const OnlineGameNotifierState();
  }

  void dispose() {
    _showResultTimer?.cancel();
    _showResultTimer = null;
    _roomSub?.cancel();
    _gameStateSub?.cancel();
    _handSub?.cancel();
  }

  // --- Chargement des familles ---

  Future<void> _ensureFamilles() async {
    if (state.familles.isNotEmpty) return;
    final familles = await FamilleRepositoryImpl().chargerFamilles();
    state = state.copyWith(familles: familles);
  }

  // Extrait la clé i18n d'une exception (ex: Exception('roomNotFound') → 'roomNotFound').
  String _extractKey(Object e) =>
      e is Exception ? e.toString().replaceFirst('Exception: ', '') : e.toString();

  // --- Actions publiques ---

  Future<void> createRoom(int maxPlayers) async {
    state = OnlineGameNotifierState(
      familles: state.familles,
      etape: OnlineEtape.creating,
      isLoading: true,
    );
    try {
      await _ensureFamilles();
      final roomId = await _repo.createRoom(maxPlayers);
      _subscribeToRoom(roomId);
      state = state.copyWith(
        roomId: roomId,
        etape: OnlineEtape.waiting,
        isLoading: false,
      );
    } catch (e) {
      state = OnlineGameNotifierState(
        familles: state.familles,
        erreur: _extractKey(e),
      );
    }
  }

  Future<void> joinRoom(String roomCode) async {
    state = OnlineGameNotifierState(
      familles: state.familles,
      etape: OnlineEtape.joining,
      isLoading: true,
    );
    try {
      await _ensureFamilles();
      final roomId = await _repo.joinRoom(roomCode);
      _subscribeToRoom(roomId);
      state = state.copyWith(
        roomId: roomId,
        etape: OnlineEtape.waiting,
        isLoading: false,
      );
    } catch (e) {
      state = OnlineGameNotifierState(
        familles: state.familles,
        erreur: _extractKey(e),
      );
    }
  }

  Future<void> setReady(bool isReady) async {
    final roomId = state.roomId;
    if (roomId == null) return;
    try {
      await _repo.setReady(roomId, isReady);
    } catch (e) {
      state = state.copyWith(erreur: _extractKey(e));
    }
  }

  Future<void> startGame() async {
    final roomId = state.roomId;
    final familles = state.familles;
    if (roomId == null || familles.isEmpty) return;
    try {
      // startGame retourne le GameState initialisé — utilisé par l'hôte pour resolveMove.
      _localGameState = await _repo.startGame(roomId, familles);
    } catch (e) {
      state = state.copyWith(erreur: _extractKey(e));
    }
  }

  Future<void> submitMove({
    required String targetId,
    required String familyId,
    required String descripteurId,
  }) async {
    final roomId = state.roomId;
    if (roomId == null) return;
    try {
      await _repo.submitMove(roomId, targetId, familyId, descripteurId);
    } catch (e) {
      state = state.copyWith(erreur: _extractKey(e));
    }
  }

  Future<void> leaveRoom() async {
    final roomId = state.roomId;
    _cancelSubscriptions();
    if (roomId != null) {
      try {
        await _repo.leaveRoom(roomId);
      } catch (_) {}
    }
    _localGameState = null;
    _resolving = false;
    state = OnlineGameNotifierState(familles: state.familles);
  }

  void clearErreur() {
    state = OnlineGameNotifierState(
      room: state.room,
      gameState: state.gameState,
      myHand: state.myHand,
      familles: state.familles,
      etape: state.etape,
      isLoading: state.isLoading,
      lastActionResult: state.lastActionResult,
      roomId: state.roomId,
    );
  }

  // --- Gestion des streams ---

  void _subscribeToRoom(String roomId) {
    _roomSub?.cancel();
    _gameStateSub?.cancel();
    _handSub?.cancel();

    _roomSub = _repo.roomStream(roomId).listen(_onRoomUpdate);
    _gameStateSub = _repo.gameStateStream(roomId).listen(_onGameStateUpdate);
    _handSub = _repo.myHandStream(roomId).listen(
      (hand) => state = state.copyWith(myHand: hand),
    );
  }

  void _cancelSubscriptions() {
    _showResultTimer?.cancel();
    _showResultTimer = null;
    _roomSub?.cancel();
    _gameStateSub?.cancel();
    _handSub?.cancel();
    _roomSub = null;
    _gameStateSub = null;
    _handSub = null;
  }

  void _onRoomUpdate(OnlineRoom? room) {
    if (room == null) {
      leaveRoom();
      return;
    }
    state = state.copyWith(room: room);

    // Transition waiting → jeu quand la partie démarre.
    if (room.status == RoomStatus.playing &&
        state.etape == OnlineEtape.waiting) {
      _updateTurnEtape();
    }
  }

  void _onGameStateUpdate(OnlineGameState? gameState) {
    if (gameState == null) return;
    state = state.copyWith(gameState: gameState);

    if (gameState.etape == 'terminee') {
      state = state.copyWith(etape: OnlineEtape.gameOver);
      return;
    }

    final room = state.room;
    if (room == null) return;

    final lastAction = gameState.lastAction;

    // Hôte : résoudre le move en attente (success == null signifie en attente).
    if (_isHost(room) &&
        lastAction != null &&
        lastAction['success'] == null &&
        !_resolving) {
      _resolving = true;
      _resolveHostMove(room, lastAction);
      return;
    }

    // Move résolu : afficher le résultat pendant 2500ms puis reprendre le jeu.
    if (lastAction != null && lastAction['success'] != null) {
      state = state.copyWith(
        lastActionResult: lastAction,
        etape: OnlineEtape.showingResult,
      );
      _showResultTimer?.cancel();
      _showResultTimer = Timer(const Duration(milliseconds: 2500), () {
        if (state.etape == OnlineEtape.showingResult) {
          _updateTurnEtape();
        }
      });
      return;
    }

    _updateTurnEtape();
  }

  Future<void> _resolveHostMove(
    OnlineRoom room,
    Map<String, dynamic> lastAction,
  ) async {
    final localGs = _localGameState;
    final familles = state.familles;
    if (localGs == null || familles.isEmpty) {
      _resolving = false;
      return;
    }

    final requesterId = lastAction['requesterId'] as String;
    final targetId = lastAction['targetId'] as String;
    final familyId = lastAction['familyId'] as String;
    final descripteurId = lastAction['descripteurId'] as String;

    try {
      await _repo.resolveMove(
        roomId: room.roomId,
        localGameState: localGs,
        familles: familles,
        requesterId: requesterId,
        targetId: targetId,
        familyId: familyId,
        descripteurId: descripteurId,
        requesterPlayerIds: room.playerIds,
      );

      // Mettre à jour l'état local du moteur pour le prochain move.
      final requesterIndex = room.playerIds.indexOf(requesterId);
      final targetIndex = room.playerIds.indexOf(targetId);
      if (requesterIndex >= 0 &&
          requesterIndex < localGs.joueurs.length &&
          targetIndex >= 0 &&
          targetIndex < localGs.joueurs.length) {
        try {
          _localGameState = _engine.traiterDemande(
            gameState: localGs,
            joueurActifId: localGs.joueurs[requesterIndex].id,
            cibleId: localGs.joueurs[targetIndex].id,
            familleId: familyId,
            descripteurId: descripteurId,
          );
        } catch (_) {
          // Move invalide — resolveMove a déjà écrit l'échec dans Firestore.
        }
      }
    } catch (e) {
      state = state.copyWith(erreur: _extractKey(e));
    } finally {
      _resolving = false;
    }
  }

  void _updateTurnEtape() {
    final room = state.room;
    final gameState = state.gameState;
    if (room == null || gameState == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;

    final idx = gameState.currentPlayerIndex;
    final currentPlayerUid =
        (idx >= 0 && idx < room.playerIds.length) ? room.playerIds[idx] : null;

    state = state.copyWith(
      etape: currentPlayerUid == currentUid
          ? OnlineEtape.myTurn
          : OnlineEtape.watchingOtherTurn,
    );
  }

  bool _isHost(OnlineRoom room) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && room.hostId == uid;
  }
}
