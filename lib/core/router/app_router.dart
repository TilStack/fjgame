// Configuration de la navigation go_router avec garde d'authentification.
// /home est protégée : redirige vers /login si non authentifié.
// Utilise refreshListenable pour éviter de recréer le GoRouter à chaque changement d'état.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/providers/auth_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

part 'app_router.g.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authStatus = ref.read(authNotifierProvider).status;
      final isResolved = authStatus != AuthStatus.initial &&
          authStatus != AuthStatus.loading;
      final isAuthenticated = authStatus == AuthStatus.authenticated;

      if (state.matchedLocation == '/splash') return null;
      if (!isResolved) return null;
      if (state.matchedLocation == '/home' && !isAuthenticated) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home',   builder: (_, __) => const HomeScreen()),
    ],
  );
}
