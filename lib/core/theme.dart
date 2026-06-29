import 'package:flutter/material.dart';
import 'transitions.dart';

class AppColors {
  static const brickRed = Color(0xFFB63C3B);
  static const cream    = Color(0xFFFDF6F1);
  static const charcoal = Color(0xFF2B1A17);

  // Dark surfaces (matches the layered dark screenshot)
  static const darkBg      = Color(0xFF1A1413);
  static const darkSurface = Color(0xFF241C1A);
  static const darkCard    = Color(0xFF2A211F);
}

ThemeData _base(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brickRed,
    brightness: brightness,
    primary: AppColors.brickRed,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: isDark ? AppColors.darkBg : AppColors.cream,

    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      foregroundColor: isDark ? Colors.white : AppColors.charcoal,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: isDark ? AppColors.darkCard : Colors.white,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
        ),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
      thickness: 1,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? AppColors.darkSurface : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brickRed, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brickRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.brickRed,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitions(),
        TargetPlatform.iOS: AppPageTransitions(),
      },
    ),
  );
}

final lightTheme = _base(Brightness.light);
final darkTheme = _base(Brightness.dark);