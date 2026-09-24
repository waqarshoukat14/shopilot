import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  /// Set once per frame by [ShopilotApp] before the tree rebuilds, so every
  /// getter below reflects the active theme without each widget needing to
  /// reach through `Theme.of(context)` (most screens reference these
  /// statically rather than via the InheritedWidget).
  static bool _isDark = false;
  static void setDark(bool value) => _isDark = value;
  static bool get isDark => _isDark;

  // ── Primary Blues (brand hue — shared across both themes) ──
  static const Color primary = Color(0xFF0EA5E9);      // Sky blue
  static const Color primaryDark = Color(0xFF0284C7);   // Deep sky blue
  static const Color primaryLight = Color(0xFF7DD3FC);  // Light sky blue
  static Color get primarySoft =>
      _isDark ? const Color(0xFF0F2A3D) : const Color(0xFFE0F2FE);

  // ── Secondary ──
  static const Color secondary = Color(0xFF06B6D4);     // Cyan accent
  static const Color secondaryLight = Color(0xFFA5F3FC);

  // ── Backgrounds ──
  static Color get background =>
      _isDark ? const Color(0xFF0A1420) : const Color(0xFFF0F9FF);
  static Color get surface =>
      _isDark ? const Color(0xFF121D2C) : Colors.white;
  static Color get surfaceElevated =>
      _isDark ? const Color(0xFF17263A) : const Color(0xFFFFFFFF);

  // ── Text ──
  static Color get textPrimary =>
      _isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  static Color get textSecondary =>
      _isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static const Color textOnGradient = Colors.white;

  // ── Borders & Dividers ──
  static Color get border =>
      _isDark ? const Color(0xFF1E3548) : const Color(0xFFBAE6FD);
  static Color get divider =>
      _isDark ? const Color(0xFF1B2A3A) : const Color(0xFFE0F2FE);

  // ── Status Colors (kept vivid/legible on both backgrounds) ──
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color lowStock = Color(0xFFF97316);

  // ── Gradients (brand gradient — unchanged across themes) ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8), Color(0xFF7DD3FC)],
  );

  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF0F9FF)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0284C7), Color(0xFF0EA5E9), Color(0xFF38BDF8)],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF06B6D4)],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
  );
}
