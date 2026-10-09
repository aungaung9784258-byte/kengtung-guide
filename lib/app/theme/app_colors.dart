import 'package:flutter/material.dart';

/// "Jade & Gold" — drawn from Kengtung itself:
/// jade = the Shan hills and Naung Tung Lake, gold = the pagoda stupas,
/// warm sand = the market, deep forest = night in the valley.
class AppColors {
  AppColors._();

  // ---- Brand ----
  static const jade = Color(0xFF0FA47F); // primary
  static const jadeDeep = Color(0xFF07634F); // pressed / gradient end
  static const jadeSoft = Color(0xFFE3F5EF); // light tint fill
  static const gold = Color(0xFFFFB020); // accent (stupa gold)
  static const goldDeep = Color(0xFFE08A00);
  static const coral = Color(0xFFFF6B5A); // highlight / favourite
  static const danger = Color(0xFFE5484D); // emergency

  // ---- Light (warm sand) ----
  static const lightBg = Color(0xFFF7F8F5);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF1F3EF);
  static const lightText = Color(0xFF11231D);
  static const lightMuted = Color(0xFF6E7B76);

  // ---- Dark (forest night) ----
  static const darkBg = Color(0xFF0B1412);
  static const darkSurface = Color(0xFF13201C);
  static const darkSurfaceAlt = Color(0xFF1A2A25);
  static const darkText = Color(0xFFE8F1ED);
  static const darkMuted = Color(0xFF8FA39C);

  // ==========================================================================
  // NAVIGATION — change these and nothing else to restyle the map route
  // and the "you are here" marker.
  // ==========================================================================

  /// The road route line (online, real roads).
  static const routeLine = Color.fromARGB(255, 43, 1, 255);

  /// White casing drawn under the route line so it stays readable on
  /// satellite imagery. Use Colors.transparent to remove it.
  static const routeBorder = Color(0xFFFFFFFF);

  /// Offline / straight-line estimate (the dashed one).
  static const routeApprox = gold;

  /// The part of the route already travelled, while navigating.
  static const routeDone = Color(0xFF9CB8AF);

  /// The heading arrow shown during navigation.
  static const navArrow = Color.fromARGB(255, 0, 13, 255);

  /// Disc behind the arrow.
  static const navArrowDisc = Color(0xFFFFFFFF);

  /// Soft halo that grows around the arrow while moving.
  static const navArrowHalo = jade;

  /// The plain pulsing dot used when NOT navigating.
  static const myLocationDot = Color.fromARGB(255, 242, 11, 11);
  static const myLocationPulse = Color.fromARGB(255, 255, 2, 2);

  // ---- Category pins ----
  static const cPlace = Color(0xFF0FA47F); // jade
  static const cPagoda = Color(0xFFFFB020); // gold
  static const cMarket = Color(0xFFF2762E); // chilli orange
  static const cTransport = Color(0xFF6C5CE7); // indigo
  static const cHotel = Color(0xFF2E8BF2); // sky
  static const cRestaurant = Color(0xFFE2457A); // rose
  static const cEmergency = Color(0xFFE5484D); // red

  // ---- Gradients ----
  static const heroScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x33000000), Color(0xCC000000)],
    stops: [0.35, 0.62, 1.0],
  );

  static const jadeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [jade, jadeDeep],
  );

  static const goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDeep],
  );
}
