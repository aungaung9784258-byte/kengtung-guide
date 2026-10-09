import 'package:flutter/animation.dart';

/// One place for every duration and curve, so motion feels like one system.
class AppMotion {
  AppMotion._();

  // Durations
  static const micro = Duration(milliseconds: 140); // taps, ripples
  static const fast = Duration(milliseconds: 240); // chips, toggles
  static const base = Duration(milliseconds: 380); // page / card reveal
  static const slow = Duration(milliseconds: 620); // hero, parallax settle
  static const hero = Duration(milliseconds: 520);

  // Stagger step between list items
  static const stagger = Duration(milliseconds: 70);

  // Curves
  static const easeOutExpoCurve = Cubic(0.16, 1.0, 0.3, 1.0);
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const springy = Cubic(0.34, 1.56, 0.64, 1.0); // slight overshoot
  static const gentle = Curves.easeOutCubic;

  /// Parallax strength: how far the background image drifts inside its frame.
  static const parallaxFactor = 0.35;
}
