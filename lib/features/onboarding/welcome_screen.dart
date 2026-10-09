import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/motion_widgets.dart';
import '../../shared/widgets/weather_badge.dart';

/// Full-bleed hero with a slow Ken Burns zoom, language picker and CTA.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ken = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ken.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    final lang = ref.watch(langProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ken Burns background (replace gradient with a Kengtung photo)
          AnimatedBuilder(
            animation: _ken,
            builder: (_, child) => Transform.scale(
              scale: 1.05 + _ken.value * 0.12,
              child: child,
            ),
            child: Image.asset(
              'assets/images/hero_kengtung.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF0B3B30),
                      Color(0xFF0FA47F),
                      Color(0xFFFFB020),
                    ],
                    stops: [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.heroScrim),
            ),
          ),

          // Live Kengtung weather, top-centre.
          // Data: Open-Meteo - free, no API key, no billing account.
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            left: 0,
            right: 0,
            child: const Center(
              child: RevealIn(
                index: 0,
                child: WeatherBadge(onLight: true),
              ),
            ),
          ),

          // Language switch, top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 14,
            right: 18,
            child: RevealIn(
              index: 0,
              child: _LangToggle(
                lang: lang,
                onChanged: (l) => ref
                    .read(settingsProvider.notifier)
                    .setLocale(Locale(l)),
              ),
            ),
          ),

          // Headline + CTA
          Positioned(
            left: 26,
            right: 26,
            bottom: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RevealIn(
                  index: 1,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.travel_explore_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 20),
                RevealIn(
                  index: 2,
                  offset: const Offset(0, 0.3),
                  child: Text(
                    t.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                RevealIn(
                  index: 3,
                  offset: const Offset(0, 0.3),
                  child: Text(
                    t.tagline,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 15,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 34),
                RevealIn(
                  index: 4,
                  scaleFrom: 0.9,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.jadeDeep,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: () => context.go('/home'),
                      icon: const Icon(Icons.explore_rounded),
                      label: Text(t.letsTour,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  const _LangToggle({required this.lang, required this.onChanged});
  final String lang;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _opt('EN', 'en'),
          _opt('မြန်မာ', 'my'),
        ],
      ),
    );
  }

  Widget _opt(String label, String code) => GestureDetector(
        onTap: () => onChanged(code),
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOutExpoCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: lang == code ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: lang == code ? AppColors.jadeDeep : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      );
}