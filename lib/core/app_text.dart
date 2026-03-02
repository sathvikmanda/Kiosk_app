import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  static const String font = 'Sora';

  static const TextStyle titleXL = TextStyle(
    fontFamily: font,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleL = TextStyle(
    fontFamily: font,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleM = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle muted = TextStyle(
    fontFamily: font,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: font,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Colors.white38,
  );

  // 🔑 MISSING ONES (THIS FIXES YOUR ERRORS)
  static const TextStyle button = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle keypad = TextStyle(
    fontFamily: font,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
  static const TextStyle code = TextStyle(
  fontFamily: font,
  fontSize: 56,
  fontWeight: FontWeight.w900,
  letterSpacing: 8,
  color: AppColors.primary,
);

}
