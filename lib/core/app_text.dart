import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  static const String font = 'Sora';

  static TextStyle get titleXL => TextStyle(
    fontFamily: font, fontSize: 36, fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleL => TextStyle(
    fontFamily: font, fontSize: 28, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleM => TextStyle(
    fontFamily: font, fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle get body => TextStyle(
    fontFamily: font, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get muted => TextStyle(
    fontFamily: font, fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: font, fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static TextStyle get button => TextStyle(
    fontFamily: font, fontSize: 22, fontWeight: FontWeight.w900,
    letterSpacing: 1.2, color: AppColors.textPrimary,
  );

  static const TextStyle keypad = TextStyle(
    fontFamily: font, fontSize: 24, fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );

  static const TextStyle code = TextStyle(
    fontFamily: font, fontSize: 56, fontWeight: FontWeight.w900,
    letterSpacing: 8, color: AppColors.primary,
  );
}
