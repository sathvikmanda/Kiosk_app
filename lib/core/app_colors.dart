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
  static const Color _lightBackground  = Color(0xFFF0F0F0);
  static const Color _lightPanel       = Color(0xFFE2E2E2);
  static const Color _lightCard        = Color(0xFFD4D4D4);
  static const Color _lightTextPrimary = Color(0xFF1A1A1A);
  static const Color _lightTextMuted   = Color(0xFF555555);
  static const Color _lightBorder      = Color(0xFFBBBBBB);

  // ── Dynamic getters ───────────────────────────────────────────
  static bool get _dark => ThemeNotifier().isDark;

  static Color get background  => _dark ? _darkBackground  : _lightBackground;
  static Color get panel       => _dark ? _darkPanel       : _lightPanel;
  static Color get card        => _dark ? _darkCard        : _lightCard;
  static Color get textPrimary => _dark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textMuted   => _dark ? _darkTextMuted   : _lightTextMuted;
  static Color get border      => _dark ? _darkBorder      : _lightBorder;

  // aliases used in some screens
  static Color get bgDark        => background;
  static Color get cardDark      => card;
  static Color get textSecondary => textMuted;

  // ── Semantic tokens — use these instead of Colors.white* ──────
  // Icon/text on a coloured surface (e.g. orange button) — always white
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Subtle separator / unfilled OTP box border
  static Color get subtle => _dark ? const Color(0x1FFFFFFF) : const Color(0x33000000);

  // Empty/placeholder text inside input boxes
  static Color get placeholder => _dark ? const Color(0x61FFFFFF) : const Color(0x61000000);

  // Disabled/inactive text (e.g. "Clear" key, inactive resend)
  static Color get inactive => _dark ? const Color(0xB3FFFFFF) : const Color(0x99000000);

  // Surface overlay — used for modal backdrops, audio tester panel bg
  static Color get overlay => _dark ? const Color(0xEB000000) : const Color(0xEBFFFFFF);

  // Text that sits directly on card/panel surfaces
  static Color get onSurface => _dark ? const Color(0xFFFFFFFF) : const Color(0xFF1A1A1A);

  // Muted text on surface (secondary info rows)
  static Color get onSurfaceMuted => _dark ? const Color(0xB3FFFFFF) : const Color(0xAA000000);

  // Divider lines
  static Color get divider => _dark ? const Color(0x1FFFFFFF) : const Color(0x33000000);
}
