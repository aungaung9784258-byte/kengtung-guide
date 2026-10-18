import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/detail/place_detail_screen.dart';
import '../features/favourites/favourites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../splashScreen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/today/today_screen.dart';
import '../features/villages/village_detail_screen.dart';
import '../features/villages/villages_screen.dart';
import 'shell.dart';
import 'theme/app_motion.dart';
import '../features/about/about_kengtung_screen.dart';
import '../features/today/markets_guide_screen.dart';

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
    GoRoute(
      path: '/villages',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(s, const VillagesScreen()),
    ),
    GoRoute(
      path: '/village/:id',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(
        s,
        VillageDetailScreen(villageId: s.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/about-kengtung',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(s, const AboutKengtungScreen()),
    ),
    GoRoute(
      path: '/markets-guide',
      parentNavigatorKey: _rootKey,
      pageBuilder: (c, s) => _slideUp(s, const MarketsGuideScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (c, s, shell) => AppShell(navigationShell: shell),
      branches: [
        // 0 — Home
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', pageBuilder: (c, s) => _fade(s, const HomeScreen())),
        ]),
        // 1 — Map
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
        // 2 — Today  (must stay in the middle: shell.dart puts it third too)
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/today',
              pageBuilder: (c, s) => _fade(s, const TodayScreen())),
        ]),
        // 3 — Favourites
        StatefulShellBranch(routes: [
          GoRoute(
              path: '/favourites',
              pageBuilder: (c, s) => _fade(s, const FavouritesScreen())),
        ]),
        // 4 — Settings
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
