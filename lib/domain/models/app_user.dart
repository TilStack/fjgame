// Modèle de domaine représentant l'utilisateur authentifié ou anonyme.
// pseudo : displayName Firebase Auth, sinon partie email avant @, sinon "Invité".
// avatarColor : couleur Firestore ou rouge primaire par défaut.

import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    required this.isAnonymous,
    required this.pseudo,
    required this.avatarColor,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;
  final String pseudo;
  final String avatarColor;

  static const List<String> _avatarColors = [
    '#FF1744', '#1E88E5', '#43A047', '#FB8C00', '#8E24AA', '#00ACC1',
  ];

  factory AppUser.fromFirebaseUser(User user, {String? avatarColor}) {
    final pseudo = _resolvePseudo(user);
    return AppUser(
      uid: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
      pseudo: pseudo,
      avatarColor: avatarColor ?? _avatarColors[0],
    );
  }

  static String _resolvePseudo(User user) {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }
    return 'Invité';
  }

  // Compatibilité avec le code existant
  String get displayName => pseudo;
}
