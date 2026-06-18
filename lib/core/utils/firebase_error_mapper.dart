// Convertit les codes d'erreur FirebaseAuthException en clés ARB
// pour afficher des messages localisés dans l'UI sans couplage direct.

String mapFirebaseAuthError(String code) {
  return switch (code) {
    'email-already-in-use'   => 'emailAlreadyInUse',
    'wrong-password'         => 'wrongPassword',
    'invalid-credential'     => 'wrongPassword',
    'user-not-found'         => 'userNotFound',
    'network-request-failed' => 'networkError',
    _                        => 'errorGeneric',
  };
}
