// Configuration de la navigation go_router avec gardes d'authentification et de jeu.
// Les routes /game/* sont protégées par l'état du GameNotifier.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/providers/game_provider.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/game/fin_partie_screen.dart';
import '../../presentation/screens/game/game_screen.dart';
import '../../presentation/screens/game/lobby_local_screen.dart';
import '../../presentation/screens/game/resultat_tour_screen.dart';
import '../../presentation/screens/game/transition_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/splash/splash_screen.dart';

part 'app_router.g.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
    _ref.listen(gameNotifierProvider, (_, __) => notifyListeners());
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
      final gameState = ref.read(gameNotifierProvider);

      if (state.matchedLocation == '/splash') return null;
      if (!isResolved) return null;

      // Auth requise pour les routes de jeu
      final requiresAuth = state.matchedLocation == '/home' ||
          state.matchedLocation == '/lobby-local' ||
          state.matchedLocation.startsWith('/game/');
      if (requiresAuth && !isAuthenticated) return '/login';

      // Gardes de progression de jeu
      if (state.matchedLocation.startsWith('/game/')) {
        if (gameState.gameState == null) return '/lobby-local';

        if (state.matchedLocation == '/game/play' &&
            gameState.etape != EtapeJeu.enCours) {
          return '/lobby-local';
        }
        if (state.matchedLocation == '/game/resultat' &&
            gameState.dernierResultat == null) {
          return '/lobby-local';
        }
        if (state.matchedLocation == '/game/fin' &&
            gameState.etape != EtapeJeu.terminee) {
          return '/lobby-local';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash',      builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',       builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',    builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/lobby-local', builder: (_, __) => const LobbyLocalScreen()),
      GoRoute(path: '/game/transition', builder: (_, __) => const TransitionScreen()),
      GoRoute(path: '/game/play',       builder: (_, __) => const GameScreen()),
      GoRoute(path: '/game/resultat',   builder: (_, __) => const ResultatTourScreen()),
      GoRoute(path: '/game/fin',        builder: (_, __) => const FinPartieScreen()),
    ],
  );
}
