import 'package:flutter/material.dart';

class AppTheme {
  // Theme Color Tokens
  static const Color background = Color(0xFF121418); // Dark industrial slate
  static const Color surfaceCard = Color(0xFF1E222B); // Surface / Cards
  static const Color primaryBlue = Color(0xFF3B82F6); // Electric Blue
  static const Color statusMatch = Color(0xFF10B981); // Emerald Green
  static const Color statusShortage = Color(0xFFEF4444); // Crimson Red
  static const Color statusSurplus = Color(0xFFF59E0B); // Amber Gold

  // Backward-compatible alias getters
  static const Color matchSuccess = statusMatch;
  static const Color shortageLoss = statusShortage;
  static const Color surplusAlert = statusSurplus;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        surface: surfaceCard,
        secondary: primaryBlue,
        error: statusShortage,
      ),
      cardColor: surfaceCard,
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2C3240), width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
