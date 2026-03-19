import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7A00);
  static const Color success = Color(0xFF2E7D32);
  static const Color danger  = Color(0xFFD32F2F);
  static const Color disabled = Color(0xFFBBBBBB);
  static const Color orange = Color(0xFFFF7A00);

  // ── Dark palette ──────────────────────────────────────────────
  static const Color _darkBackground  = Color(0xFF0B0B0B);
  static const Color _darkPanel       = Color(0xFF1A1A1A);
  static const Color _darkCard        = Color(0xFF252525);
  static const Color _darkTextPrimary = Color(0xFFFFFFFF);
  static const Color _darkTextMuted   = Color(0xFF888888);
  static const Color _darkBorder      = Color(0xFF2A2A2A);

  // ── Light palette ─────────────────────────────────────────────
  static const Color _lightBackground  = Color(0xFFFFFFFF);
  static const Color _lightPanel       = Color(0xFFF5F5F5);
  static const Color _lightCard        = Color(0xFFEBEBEB);
  static const Color _lightTextPrimary = Color(0xFF1A1A1A);
  static const Color _lightTextMuted   = Color(0xFF666666);
  static const Color _lightBorder      = Color(0xFFDDDDDD);

  // ── Dynamic getters ───────────────────────────────────────────
  static bool get _dark => ThemeNotifier().isDark;

  static Color get background  => _dark ? _darkBackground  : _lightBackground;
  static Color get panel       => _dark ? _darkPanel       : _lightPanel;
  static Color get card        => _dark ? _darkCard        : _lightCard;
  static Color get textPrimary => _dark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textMuted   => _dark ? _darkTextMuted   : _lightTextMuted;
  static Color get border      => _dark ? _darkBorder      : _lightBorder;

  // aliases used in some screens
  static Color get bgDark      => background;
  static Color get cardDark    => card;
  static Color get textSecondary => textMuted;
}
