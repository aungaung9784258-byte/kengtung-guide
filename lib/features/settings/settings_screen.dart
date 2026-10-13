import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';
import 'credits_card.dart';
import 'offline_maps_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final s = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar.large(
            title: Text(t.settings),
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.list(children: [
              RevealIn(
                index: 0,
                child: _Card(
                  title: t.language,
                  icon: Icons.translate_rounded,
                  child: _Segmented(
                    options: const ['English', 'မြန်မာ'],
                    selectedIndex: s.locale.languageCode == 'my' ? 1 : 0,
                    onSelect: (i) =>
                        notifier.setLocale(Locale(i == 1 ? 'my' : 'en')),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              RevealIn(
                index: 1,
                child: _Card(
                  title: t.theme,
                  icon: Icons.dark_mode_rounded,
                  child: _Segmented(
                    options: [t.lightMode, t.darkMode, t.systemMode],
                    selectedIndex: switch (s.themeMode) {
                      ThemeMode.light => 0,
                      ThemeMode.dark => 1,
                      ThemeMode.system => 2,
                    },
                    onSelect: (i) => notifier.setThemeMode(switch (i) {
                      0 => ThemeMode.light,
                      1 => ThemeMode.dark,
                      _ => ThemeMode.system,
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const RevealIn(index: 2, child: OfflineMapsCard()),
              const SizedBox(height: 16),
              RevealIn(
                index: 3,
                child: _Card(
                  title: t.about,
                  icon: Icons.info_outline_rounded,
                  child: Text(t.t('aboutBody'),
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ),
              const SizedBox(height: 16),
              const RevealIn(index: 4, child: CreditsCard()),
              const SizedBox(height: 16),
              const RevealIn(index: 5, child: ThanksCard()),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.jadeGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Animated sliding segmented control.
class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.options,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth / options.length;
      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: AppMotion.base,
              curve: AppMotion.easeOutExpoCurve,
              left: w * selectedIndex,
              top: 4,
              bottom: 4,
              width: w,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: AppColors.jadeGradient,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.jade.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ),
            Row(
              children: List.generate(
                options.length,
                (i) => Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: AppMotion.fast,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: i == selectedIndex
                              ? Colors.white
                              : cs.onSurface.withValues(alpha: 0.65),
                        ),
                        child: Text(options[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
