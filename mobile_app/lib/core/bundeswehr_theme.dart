import 'package:flutter/material.dart';

class BundeswehrTheme {
  // Palette derived from the provided camouflage-style image.
  static const Color olive900 = Color(0xFF2F3A24);
  static const Color olive700 = Color(0xFF4D5F3A);
  static const Color olive500 = Color(0xFF6A7F50);
  static const Color khaki500 = Color(0xFFA69E6E);
  static const Color sand200 = Color(0xFFDAD2B4);
  static const Color brown600 = Color(0xFF6C5335);
  static const Color white = Color(0xFFF4F4F2);

  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: olive700,
      brightness: Brightness.light,
      primary: olive700,
      secondary: khaki500,
      surface: sand200,
      tertiary: brown600,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFE7E3D5),
      appBarTheme: const AppBarTheme(
        backgroundColor: olive900,
        foregroundColor: white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF2EEE0),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: olive700,
          foregroundColor: white,
          disabledBackgroundColor: olive700.withValues(alpha: 0.45),
          disabledForegroundColor: white.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: olive700,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: olive900,
          side: const BorderSide(color: olive700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF7F4EA),
        hintStyle: const TextStyle(
          color: Color(0xFF6A6A5A),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: Color(0xFF5D5D4F),
          fontWeight: FontWeight.w500,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        floatingLabelStyle: const TextStyle(
          fontSize: 13,
          height: 1.0,
          fontWeight: FontWeight.w600,
        ),
        contentPadding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: olive500),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: olive500.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: olive700, width: 1.8),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: olive500.withValues(alpha: 0.18),
        side: BorderSide(color: olive700.withValues(alpha: 0.45)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: olive900.withValues(alpha: 0.18)),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: olive700),
    );
  }
}
