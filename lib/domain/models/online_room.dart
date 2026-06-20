// Modèles de domaine pour le multijoueur en ligne : OnlinePlayer, OnlineRoom, OnlineGameState.

import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomStatus { waiting, playing, finished }

class OnlinePlayer {
  final String uid;
  final String pseudo;
  final String avatarColor;
  final bool isReady;
  final bool isHost;

  const OnlinePlayer({
    required this.uid,
    required this.pseudo,
    required this.avatarColor,
    required this.isReady,
    required this.isHost,
  });

  factory OnlinePlayer.fromMap(Map<String, dynamic> map) {
    return OnlinePlayer(
      uid: map['uid'] as String,
      pseudo: map['pseudo'] as String,
      avatarColor: map['avatarColor'] as String,
      isReady: map['isReady'] as bool? ?? false,
      isHost: map['isHost'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'pseudo': pseudo,
    'avatarColor': avatarColor,
    'isReady': isReady,
    'isHost': isHost,
  };
}

class OnlineRoom {
  final String roomId;
  final String roomCode;
  final RoomStatus status;
  final String hostId;
  final List<String> playerIds;
  final List<OnlinePlayer> players;
  final int maxPlayers;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const OnlineRoom({
    required this.roomId,
    required this.roomCode,
    required this.status,
    required this.hostId,
    required this.playerIds,
    required this.players,
    required this.maxPlayers,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OnlineRoom.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OnlineRoom(
      roomId: doc.id,
      roomCode: data['roomCode'] as String,
      status: RoomStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => RoomStatus.waiting,
      ),
      hostId: data['hostId'] as String,
      playerIds: List<String>.from(data['playerIds'] as List),
      players: (data['players'] as List)
          .map((p) => OnlinePlayer.fromMap(p as Map<String, dynamic>))
          .toList(),
      maxPlayers: data['maxPlayers'] as int? ?? 6,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'roomCode': roomCode,
    'status': status.name,
    'hostId': hostId,
    'playerIds': playerIds,
    'players': players.map((p) => p.toMap()).toList(),
    'maxPlayers': maxPlayers,
  };
}

class OnlineGameState {
  final int currentPlayerIndex;
  final String etape;
  final List<Map<String, dynamic>> completedFamilies;
  final Map<String, dynamic>? lastAction;
  final Map<String, int> scores;
  final Timestamp updatedAt;

  const OnlineGameState({
    required this.currentPlayerIndex,
    required this.etape,
    required this.completedFamilies,
    this.lastAction,
    required this.scores,
    required this.updatedAt,
  });

  factory OnlineGameState.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OnlineGameState(
      currentPlayerIndex: data['currentPlayerIndex'] as int? ?? 0,
      etape: data['etape'] as String? ?? 'transition',
      completedFamilies: (data['completedFamilies'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      lastAction: data['lastAction'] != null
          ? Map<String, dynamic>.from(data['lastAction'] as Map)
          : null,
      scores: (data['scores'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toInt())),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'currentPlayerIndex': currentPlayerIndex,
    'etape': etape,
    'completedFamilies': completedFamilies,
    'lastAction': lastAction,
    'scores': scores,
  };
}
