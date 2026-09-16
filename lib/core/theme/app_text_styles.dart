import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get inter => GoogleFonts.inter();

  static TextStyle get displayLarge => inter.copyWith(
    fontSize: 32, fontWeight: FontWeight.w700, height: 1.2,
  );
  static TextStyle get displayMedium => inter.copyWith(
    fontSize: 28, fontWeight: FontWeight.w700, height: 1.2,
  );
  static TextStyle get headlineLarge => inter.copyWith(
    fontSize: 24, fontWeight: FontWeight.w600, height: 1.3,
  );
  static TextStyle get headlineMedium => inter.copyWith(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
  );
  static TextStyle get titleLarge => inter.copyWith(
    fontSize: 18, fontWeight: FontWeight.w600, height: 1.4,
  );
  static TextStyle get titleMedium => inter.copyWith(
    fontSize: 16, fontWeight: FontWeight.w500, height: 1.4,
  );
  static TextStyle get bodyLarge => inter.copyWith(
    fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle get bodyMedium => inter.copyWith(
    fontSize: 14, fontWeight: FontWeight.w400, height: 1.5,
  );
  static TextStyle get labelLarge => inter.copyWith(
    fontSize: 14, fontWeight: FontWeight.w600, height: 1.4,
  );
  static TextStyle get labelMedium => inter.copyWith(
    fontSize: 13, fontWeight: FontWeight.w500, height: 1.4,
  );

  static TextStyle get labelSmall => inter.copyWith(
    fontSize: 12, fontWeight: FontWeight.w500, height: 1.4,
  );
}
