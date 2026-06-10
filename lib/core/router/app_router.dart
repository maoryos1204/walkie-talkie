import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shmuki_talk/features/auth/presentation/pages/login_page.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/home/presentation/pages/home_page.dart';
import 'package:shmuki_talk/features/room/presentation/pages/room_page.dart';
import 'package:shmuki_talk/features/room/presentation/pages/room_settings_page.dart';
import 'package:shmuki_talk/features/room/presentation/pages/create_room_page.dart';
import 'package:shmuki_talk/features/room/presentation/pages/join_room_page.dart';
import 'package:shmuki_talk/core/presentation/widgets/splash_screen.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const room = '/room/:roomId';
  static const roomSettings = '/room/:roomId/settings';
  static const createRoom = '/create-room';
  static const joinRoom = '/join-room';
  static const joinRoomByCode = '/join/:inviteCode';

  static String roomPath(String roomId) => '/room/$roomId';
  static String roomSettingsPath(String roomId) => '/room/$roomId/settings';
  // Note: settings is a nested sub-route of /room/:roomId
  static String joinByCodePath(String code) => '/join/$code';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoading = authState.isLoading;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isLogin = state.matchedLocation == AppRoutes.login;

      if (isLoading) return isSplash ? null : AppRoutes.splash;
      if (!isLoggedIn && !isLogin) return AppRoutes.login;
      if (isLoggedIn && (isLogin || isSplash)) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomePage(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return RoomPage(roomId: roomId);
        },
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: RoomPage(roomId: roomId),
            transitionsBuilder: _slideUpTransition,
          );
        },
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return RoomSettingsPage(roomId: roomId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.createRoom,
        builder: (context, state) => const CreateRoomPage(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateRoomPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.joinRoom,
        builder: (context, state) => const JoinRoomPage(),
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const JoinRoomPage(),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(
        path: '/join/:inviteCode',
        builder: (context, state) {
          final code = state.pathParameters['inviteCode']!;
          return JoinRoomPage(prefillCode: code);
        },
      ),
    ],
  );
});

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
    child: FadeTransition(opacity: animation, child: child),
  );
}
