import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'theme/app_colors.dart';
import 'theme/app_motion.dart';

/// Bottom-nav shell. Tab switches cross-fade instead of hard-cutting.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: AppMotion.easeOutExpoCurve,
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.99, end: 1.0).animate(anim),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(navigationShell.currentIndex),
          child: navigationShell,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (i) => navigationShell.goBranch(
              i,
              initialLocation: i == navigationShell.currentIndex,
            ),
                     labelBehavior:
                NavigationDestinationLabelBehavior.onlyShowSelected,
            height: 68,
            destinations: [
              _dest(Icons.home_rounded, Icons.home_outlined, t.home),
              _dest(Icons.near_me_rounded, Icons.near_me_outlined, t.map),
              _dest(Icons.today_rounded, Icons.today_outlined, t.t('todayTab')),
              _dest(Icons.favorite_rounded, Icons.favorite_border_rounded,
                  t.favourites),
              _dest(Icons.settings_rounded, Icons.settings_outlined,
                  t.settings),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDestination _dest(IconData sel, IconData unsel, String label) =>
      NavigationDestination(
        icon: Icon(unsel),
        selectedIcon: Icon(sel, color: AppColors.jade),
        label: label,
      );
}
