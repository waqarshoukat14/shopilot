import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Primary Blues ──
  static const Color primary = Color(0xFF0EA5E9);      // Sky blue
  static const Color primaryDark = Color(0xFF0284C7);   // Deep sky blue
  static const Color primaryLight = Color(0xFF7DD3FC);  // Light sky blue
  static const Color primarySoft = Color(0xFFE0F2FE);   // Very light blue tint

  // ── Secondary ──
  static const Color secondary = Color(0xFF06B6D4);     // Cyan accent
  static const Color secondaryLight = Color(0xFFA5F3FC);

  // ── Backgrounds ──
  static const Color background = Color(0xFFF0F9FF);    // Ice blue background
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // ── Text ──
  static const Color textPrimary = Color(0xFF0F172A);   // Near-black with blue tint
  static const Color textSecondary = Color(0xFF64748B);  // Slate
  static const Color textOnGradient = Colors.white;

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFBAE6FD);        // Light blue border
  static const Color divider = Color(0xFFE0F2FE);

  // ── Status Colors ──
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color lowStock = Color(0xFFF97316);

  // ── Gradients ──
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
