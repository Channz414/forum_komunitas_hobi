import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFFFFFEE);
  static const chip = Color(0xFFF7E1B5);
  static const chipBorder = Color(0xFF4A3F1A);
  static const ink = Color(0xFF3D3512);
  static const accent = Color(0xFF3B7BE0);
  static const teal = Color(0xFFABD9D4);
  static const tealText = Color(0xFF2B5551);
  static const open = Color.fromARGB(255, 29, 231, 83);
  static const shadow = Color(0x26000000);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    surface: AppColors.bg,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.bg,
    scrolledUnderElevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: 24,
      fontWeight: FontWeight.w800,
    ),
  ),
);
