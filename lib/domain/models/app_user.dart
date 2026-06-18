// Modèle de domaine représentant l'utilisateur authentifié ou anonyme.
// Découplé des détails Firebase pour isoler la logique métier.

import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    required this.isAnonymous,
  });

  final String uid;
  final String? email;
  final bool isAnonymous;

  // Retourne la partie avant "@" si email présent, sinon "Invité".
  String get displayName {
    if (email != null && email!.isNotEmpty) {
      return email!.split('@').first;
    }
    return 'Invité';
  }

  factory AppUser.fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }
}
