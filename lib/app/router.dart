import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/detail/place_detail_screen.dart';
import '../features/favourites/favourites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../splashScreen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/settings/settings_screen.dart';
import 'shell.dart';
import 'theme/app_motion.dart';

final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (c, s) => _fade(s, const SplashScreen()),
    ),
    GoRoute(
      path: '/welcome',
      pageBuilder: (c, s) => _fade(s, const WelcomeScreen()),
    ),
    GoRoute(
      path: '/place/:id',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(
        s,
        PlaceDetailScreen(placeId: s.pathParameters['id']!),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (c, s, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', pageBuilder: (c, s) => _fade(s, const HomeScreen())),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/map',
            pageBuilder: (c, s) => _fade(
              s,
              MapScreen(
                focusId: s.uri.queryParameters['focus'],
                autoRoute: s.uri.queryParameters['route'] == '1',
              ),
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/favourites',
              pageBuilder: (c, s) => _fade(s, const FavouritesScreen())),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/settings',
              pageBuilder: (c, s) => _fade(s, const SettingsScreen())),
        ]),
      ],
    ),
  ],
);

CustomTransitionPage _fade(GoRouterState s, Widget child) =>
    CustomTransitionPage(
      key: s.pageKey,
      transitionDuration: AppMotion.base,
      child: child,
      transitionsBuilder: (c, a, sa, w) {
        final curved =
            CurvedAnimation(parent: a, curve: AppMotion.easeOutExpoCurve);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween(begin: 0.98, end: 1.0).animate(curved),
            child: w,
          ),
        );
      },
    );

CustomTransitionPage _slideUp(GoRouterState s, Widget child) =>
    CustomTransitionPage(
      key: s.pageKey,
      transitionDuration: AppMotion.hero,
      reverseTransitionDuration: AppMotion.base,
      child: child,
      transitionsBuilder: (c, a, sa, w) {
        final curved =
            CurvedAnimation(parent: a, curve: AppMotion.easeOutExpoCurve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
                .animate(curved),
            child: w,
          ),
        );
      },
    );
