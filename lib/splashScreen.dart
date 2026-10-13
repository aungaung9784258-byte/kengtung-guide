import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import 'app/theme/app_colors.dart';
import 'app/theme/app_motion.dart';

/// Animated splash shown while the app warms up, then hands over to
/// `/welcome`.
///
/// Implemented as a normal go_router route rather than with the
/// `animated_splash_screen` package: that package pushes its own Navigator
/// route, which conflicts with go_router's StatefulShellRoute.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// How long the splash stays on screen.
  static const hold = Duration(milliseconds: 2600);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  Timer? _timer;

  late final AnimationController _text = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Drives the Lottie file, so the composition can loop and be disposed.
  late final AnimationController _lottie = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _text.forward();
    _timer = Timer(SplashScreen.hold, _go);
  }

  void _go() {
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    _lottie.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _text, curve: AppMotion.emphasized);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      // Tap to skip - nobody likes being held hostage by a splash screen.
      body: GestureDetector(
        onTap: _go,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 260,
                height: 260,
                child: Lottie.asset(
                  'assets/lottie/travel.json',
                  controller: _lottie,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _lottie
                      ..duration = composition.duration
                      ..repeat();
                  },
                  // The app must still start if the file is missing.
                  errorBuilder: (_, __, ___) => const _PlainFallback(),
                ),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.4),
                    end: Offset.zero,
                  ).animate(fade),
                  child: const Column(
                    children: [
                      Text(
                        'Kengtung Guide',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: AppColors.lightText,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'ကျိုင်းတုံ လမ်းညွှန်',
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.7, // Myanmar needs the taller line box
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Last-resort indicator if the Lottie file cannot be decoded.
class _PlainFallback extends StatelessWidget {
  const _PlainFallback();

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(
          width: 46,
          height: 46,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.jade,
          ),
        ),
      );
}