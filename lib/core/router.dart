import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mission.dart';
import '../screens/achievements_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/collection_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/mission_detail_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/ranking_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';

/// Nomes/caminhos das rotas em um só lugar.
class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const collection = '/collection';
  static const achievements = '/achievements';
  static const ranking = '/ranking';
  static const profile = '/profile';

  static String mission(int id) => '/mission/$id';
  static String battle(int id) => '/mission/$id/battle';
}

/// Faz o GoRouter reavaliar o `redirect` sempre que o login muda.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _rootKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  final auth = Supabase.instance.client.auth;

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(auth.onAuthStateChange),

    // Proteção das rotas: sem sessão, só splash/login/cadastro.
    redirect: (context, state) {
      final loggedIn = auth.currentSession != null;
      final location = state.matchedLocation;
      if (location == AppRoutes.splash) return null;

      final onAuthPage = location == AppRoutes.login || location == AppRoutes.register;
      if (!loggedIn) return onAuthPage ? null : AppRoutes.login;
      if (onAuthPage) return AppRoutes.home;
      return null;
    },

    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterScreen()),

      // Abas principais com barra de navegação inferior (cada aba guarda seu estado).
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.collection, builder: (_, _) => const CollectionScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.achievements, builder: (_, _) => const AchievementsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.ranking, builder: (_, _) => const RankingScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen()),
          ]),
        ],
      ),

      // Detalhes da missão: recebe o id pela URL e o objeto Mission via `extra`.
      GoRoute(
        path: '/mission/:id',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => MissionDetailScreen(
          missionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
          initialMission: state.extra is Mission ? state.extra as Mission : null,
        ),
        routes: [
          GoRoute(
            path: 'battle',
            parentNavigatorKey: _rootKey,
            builder: (context, state) => BattleScreen(
              missionId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
              initialMission: state.extra is Mission ? state.extra as Mission : null,
            ),
          ),
        ],
      ),
    ],
  );
}
