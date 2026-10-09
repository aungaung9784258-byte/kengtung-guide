import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_motion.dart';

class AppTheme {
  AppTheme._();

  static const double rLg = 24;
  static const double rMd = 18;
  static const double rSm = 12;

  static ThemeData light() => _base(Brightness.light);
  static ThemeData dark() => _base(Brightness.dark);

  static ThemeData _base(Brightness b) {
    final isLight = b == Brightness.light;
    final surface = isLight ? AppColors.lightSurface : AppColors.darkSurface;
    final bg = isLight ? AppColors.lightBg : AppColors.darkBg;
    final text = isLight ? AppColors.lightText : AppColors.darkText;
    final muted = isLight ? AppColors.lightMuted : AppColors.darkMuted;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.jade,
      brightness: b,
    ).copyWith(
      primary: AppColors.jade,
      onPrimary: Colors.white,
      secondary: AppColors.gold,
      onSecondary: const Color(0xFF3A2600),
      error: AppColors.danger,
      surface: surface,
      onSurface: text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      // Covers inline TextStyle(...) built by widgets that do not read the
      // TextTheme (nav bar labels, chips, snackbars, tooltips).
      fontFamilyFallback: myanmarFallback,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      splashFactory: InkSparkle.splashFactory,

      // Smooth, consistent page transitions on every platform + web.
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: FadeThroughTransitionBuilder(),
        TargetPlatform.iOS: FadeThroughTransitionBuilder(),
        TargetPlatform.windows: FadeThroughTransitionBuilder(),
        TargetPlatform.macOS: FadeThroughTransitionBuilder(),
        TargetPlatform.linux: FadeThroughTransitionBuilder(),
      }),

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rLg)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: muted, fontSize: 14),
        prefixIconColor: muted,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: _inputBorder(muted.withValues(alpha: 0.18)),
        enabledBorder: _inputBorder(muted.withValues(alpha: 0.18)),
        focusedBorder: _inputBorder(AppColors.jade, width: 1.6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.jade,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.1),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          side: BorderSide(color: muted.withValues(alpha: 0.3)),
          shape: const StadiumBorder(),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: muted.withValues(alpha: 0.2)),
        backgroundColor: surface,
        selectedColor: AppColors.jade,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        labelStyle: TextStyle(
            color: text, fontSize: 13, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.jade.withValues(alpha: 0.14),
        indicatorShape: const StadiumBorder(),
        height: 70,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 26,
            color: s.contains(WidgetState.selected) ? AppColors.jade : muted,
          ),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dividerTheme: DividerThemeData(color: muted.withValues(alpha: 0.14), space: 1),

      textTheme: _textTheme(text, muted),
    );
  }

  static OutlineInputBorder _inputBorder(Color c, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(rMd),
        borderSide: BorderSide(color: c, width: width),
      );

  /// Bundled Myanmar font. Registered as a *fallback* rather than the primary
  /// family: Latin keeps the clean default face, and any Myanmar codepoint the
  /// default cannot draw is rendered by Padauk instead of the device font.
  ///
  /// This is what stops stacked diacritics from colliding or showing up as
  /// dotted circles / tofu boxes on phones with an old or Zawgyi-only system
  /// font.
  static const myanmarFallback = <String>['Padauk'];

  /// Apply the fallback to every style in a TextTheme in one go.
  static TextTheme _withFallback(TextTheme t) => t.apply(
        fontFamilyFallback: myanmarFallback,
      );

  static TextTheme _textTheme(Color text, Color muted) => _withFallback(TextTheme(
        displaySmall: TextStyle(
            color: text,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.1),
        headlineMedium: TextStyle(
            color: text,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6),
        titleLarge: TextStyle(
            color: text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3),
        titleMedium: TextStyle(
            color: text, fontSize: 16, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: text, fontSize: 15, height: 1.5),
        bodyMedium: TextStyle(color: text, fontSize: 14, height: 1.55),
        bodySmall: TextStyle(color: muted, fontSize: 13, height: 1.5),
        labelLarge: TextStyle(
            color: text, fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(
            color: muted, fontSize: 12, fontWeight: FontWeight.w500),
      ));
}

/// Shared-axis-ish fade-through used for all Navigator pushes.
class FadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const FadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved =
        CurvedAnimation(parent: animation, curve: AppMotion.easeOutExpoCurve);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.035), end: Offset.zero)
            .animate(curved),
        child: ScaleTransition(
          scale: Tween(begin: 0.985, end: 1.0).animate(curved),
          child: child,
        ),
      ),
    );
  }
}
