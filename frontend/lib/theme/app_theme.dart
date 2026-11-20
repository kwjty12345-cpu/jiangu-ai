import 'package:flutter/material.dart';

// Five-color bronze and lacquer palette
const Color kBgXuanBlack = Color(0xFF14110F);
const Color kCinnabar = Color(0xFFB23A2E);
const Color kAntiqueGold = Color(0xFFC8A24B);
const Color kBronzePatina = Color(0xFF4E6B5E);
const Color kXuanPaper = Color(0xFFE9DFC8);

// Lacquer surfaces and high-contrast secondary text (>= 4.5:1)
const Color kBgSecondary = Color(0xFF231C16);
const Color kSurfaceLacquer = Color(0xFF1B1612);
const Color kSurfaceElevated = Color(0xFF251E18);
const Color kTextSecondary = Color(0xFFBBAE97);
const Color kTextMuted = Color(0xFFA2947D);
const Color kOverlayDark = Color(0xCC14110F);

// Compatibility aliases
const Color kBgPrimary = kBgXuanBlack;
const Color kSurfaceDialogue = kSurfaceLacquer;
const Color kBronzeGold = kAntiqueGold;
const Color kPatinaGreen = kBronzePatina;
const Color kCinnabarRed = kCinnabar;
const Color kTextPrimary = kXuanPaper;

// English-only font stacks
const List<String> kSerifFontFallback = [
  'Cormorant Garamond',
  'Georgia',
  'Times New Roman',
  'serif',
];

const List<String> kSansFontFallback = [
  'Inter',
  'Segoe UI',
  'Roboto',
  'Helvetica Neue',
  'sans-serif',
];

Color withAlphaColor(Color color, double opacity) =>
    color.withAlpha((opacity * 255).round());

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: kBgXuanBlack,
      textTheme: ThemeData.dark().textTheme.apply(
            bodyColor: kXuanPaper,
            displayColor: kXuanPaper,
            fontFamilyFallback: kSerifFontFallback,
          ),
    );
  }
}