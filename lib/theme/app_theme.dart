import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgDark,

    // Text
    fontFamily: 'Inter',

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: Colors.white24, width: 2),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w800,
        ),
      ),
    ),

    // Cards & panels
    cardTheme: CardTheme(
      color: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    dividerTheme: const DividerThemeData(
      color: Colors.white12,
      thickness: 1.2,
    ),
  );
}
