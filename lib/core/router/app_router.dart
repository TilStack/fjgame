// Configuration de la navigation go_router avec gardes d'authentification et de jeu.
// Transitions custom sur les routes de jeu. Routes /game/* protégées par GameNotifier.

import 'package:flutter/material.dart';
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

// Construit une transition slide (direction configurable).
Page<void> _slidePage({
  required GoRouterState state,
  required Widget child,
  Offset begin = const Offset(0, 1),
  Duration duration = const Duration(milliseconds: 350),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

// Construit une transition fade.
Page<void> _fadePage({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 300),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

// Construit une transition scale + fade.
Page<void> _scaleAndFadePage({
  required GoRouterState state,
  required Widget child,
  Duration duration = const Duration(milliseconds: 400),
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, _, child) {
      if (MediaQuery.of(context).disableAnimations) return child;
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(curved), child: child),
      );
    },
  );
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
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/home',     builder: (_, __) => const HomeScreen()),

      // /lobby-local : slide depuis le bas
      GoRoute(
        path: '/lobby-local',
        pageBuilder: (_, state) => _slidePage(
          state: state,
          child: const LobbyLocalScreen(),
          begin: const Offset(0, 1),
        ),
      ),

      // /game/transition : slide depuis le bas
      GoRoute(
        path: '/game/transition',
        pageBuilder: (_, state) => _slidePage(
          state: state,
          child: const TransitionScreen(),
          begin: const Offset(0, 1),
        ),
      ),

      // /game/play : fade
      GoRoute(
        path: '/game/play',
        pageBuilder: (_, state) => _fadePage(
          state: state,
          child: const GameScreen(),
        ),
      ),

      // /game/resultat : slide depuis la droite
      GoRoute(
        path: '/game/resultat',
        pageBuilder: (_, state) => _slidePage(
          state: state,
          child: const ResultatTourScreen(),
          begin: const Offset(1, 0),
        ),
      ),

      // /game/fin : scale + fade
      GoRoute(
        path: '/game/fin',
        pageBuilder: (_, state) => _scaleAndFadePage(
          state: state,
          child: const FinPartieScreen(),
        ),
      ),
    ],
  );
}
