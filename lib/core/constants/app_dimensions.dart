import 'package:flutter/material.dart';

class AppDimensions {
  AppDimensions._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const double buttonHeight = 56;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;

  static EdgeInsets get screenPadding => const EdgeInsets.all(md);
  static EdgeInsets get cardPadding => const EdgeInsets.all(md);
  static EdgeInsets get listPadding => const EdgeInsets.symmetric(horizontal: md, vertical: sm);
}
