import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors (Material Design - Medical Blue)
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryBlueDark = Color(0xFF003c8f);
  static const Color primaryBlueLight = Color(0xFF5e92f3);
  static const Color accentBlue = Color(0xFF1976D2);

  // Risk category colors
  static const Color riskLow = Color(0xFF4CAF50);
  static const Color riskLowInt = Color(0xFF8BC34A);
  static const Color riskIntermediate = Color(0xFFFFC107);
  static const Color riskHighInt = Color(0xFFFF9800);
  static const Color riskHigh = Color(0xFFF44336);
  static const Color riskAdvanced = Color(0xFF9C27B0);

  // Surface colors
  static const Color surface = Color(0xFFF8FAFF);
  static const Color cardBackground = Colors.white;

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: accentBlue,
      surface: surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardBackground,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE0E8F5)),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1A1A2E),
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A2E),
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF2C3E50),
      ),
      bodyLarge: TextStyle(fontSize: 15, color: Color(0xFF2C3E50)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF546E7A)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF78909C)),
    ),
  );

  static Color getRiskColor(int colorValue) => Color(colorValue);
}
