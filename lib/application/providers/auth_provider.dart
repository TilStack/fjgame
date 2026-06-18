// Gère l'état d'authentification Firebase et expose les actions auth.
// Écoute FirebaseAuth.authStateChanges() pour maintenir l'état synchronisé.
// Les messages d'erreur sont des clés ARB, jamais des strings brutes.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../core/utils/firebase_error_mapper.dart';
import '../../domain/models/app_user.dart';

part 'auth_provider.g.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final String? errorMessage;
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() {
    final sub = FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        state = AuthState(
          status: AuthStatus.authenticated,
          user: AppUser.fromFirebaseUser(firebaseUser),
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
    ref.onDispose(sub.cancel);
    return const AuthState(status: AuthStatus.initial);
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: mapFirebaseAuthError(e.code),
      );
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: mapFirebaseAuthError(e.code),
      );
    }
  }

  Future<void> signInAnonymously() async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } on FirebaseAuthException catch (e) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: mapFirebaseAuthError(e.code),
      );
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
