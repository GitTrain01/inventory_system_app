import 'package:flutter/material.dart';

class AppColors {
  static const brickRed = Color(0xFFB63C3B);
  static const cream    = Color(0xFFFDF6F1);
  static const charcoal = Color(0xFF2B1A17);
}

final lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brickRed,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: AppColors.cream,
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
  ),
);

final darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.brickRed,
    brightness: Brightness.dark,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    fillColor: Color(0xFF2A2A2A),
  ),
);