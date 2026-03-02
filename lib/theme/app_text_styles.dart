import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppText {
  // Headlines
  static const h1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 1.2,
  );

  static const h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // Body
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );

  static const bodyBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  // Labels / Captions
  static const caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textMuted,
  );

  // Accent
  static const accent = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    color: AppColors.orange,
  );
}
