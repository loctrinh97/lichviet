import 'package:flutter/material.dart';

class LvColors {
  // Dark theme
  static const bgDark = Color(0xFF161826);
  static const surfaceDark = Color(0xFF232532);
  static const textDark = Color(0xFFE9E9ED);
  static const accentDark = Color(0xFF9184D9);

  // Light theme
  static const bgLight = Color(0xFFF4F5FA);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const textLight = Color(0xFF1C1D26);
  static const accentLight = Color(0xFF5D5294);

  // Accent ramps (shared)
  static const accent300 = Color(0xFFD2CEFD);
  static const accent400 = Color(0xFFB5ABFC);
  static const accent500 = Color(0xFF968AE0);
  static const accent600 = Color(0xFF796CBF);
  static const accent700 = Color(0xFF5D5294);

  // Neutral
  static const neutral300 = Color(0xFFCFD3E5);
  static const neutral500 = Color(0xFF9397AB);
  static const neutral600 = Color(0xFF75798C);

  static const radiusSm = 4.0;
  static const radiusMd = 8.0;
  static const radiusLg = 14.0;

  static LvTheme of(bool isDark) => isDark ? LvTheme.dark() : LvTheme.light();
}

class LvTheme {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color divider;
  final Color muted;
  final Color dim;
  final Color weekend;
  final bool isDark;

  LvTheme.dark()
      : bg = LvColors.bgDark,
        surface = LvColors.surfaceDark,
        text = LvColors.textDark,
        accent = LvColors.accentDark,
        divider = const Color(0xFF9397AB).withOpacity(0.16),
        muted = LvColors.neutral500,
        dim = LvColors.neutral600,
        weekend = LvColors.accent400,
        isDark = true;

  LvTheme.light()
      : bg = LvColors.bgLight,
        surface = LvColors.surfaceLight,
        text = LvColors.textLight,
        accent = LvColors.accentLight,
        divider = const Color(0xFF1C1D26).withOpacity(0.13),
        muted = LvColors.neutral600,
        dim = LvColors.neutral500,
        weekend = LvColors.accent600,
        isDark = false;

  Color accentMix(double alpha) => Color.lerp(accent, Colors.transparent, 1 - alpha)!;
  Color textMix(double alpha) => Color.lerp(text, Colors.transparent, 1 - alpha)!;
}
