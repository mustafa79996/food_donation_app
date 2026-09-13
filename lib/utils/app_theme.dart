import 'package:flutter/material.dart';

/// Application theme using Material 3 and a modern green palette.
abstract class AppTheme {
  static const Color primary = Color(0xFF1E7D45);
  static const Color primaryContainer = Color(0xFFDFF6E6);
  static const Color onPrimary = Colors.white;
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFF5FCF7);
  static const Color surfaceTint = Color(0xFF1E7D45);
  static const Color success = Color(0xFF2E7D32);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      secondary: Color(0xFF7CBF77),
      onSecondary: Colors.white,
      error: Color(0xFFB00020),
      onError: Colors.white,
      background: background,
      onBackground: Colors.black,
      surface: surface,
      onSurface: Colors.black,
      tertiary: Color(0xFF8CC78C),
      onTertiary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: Colors.black,
      secondaryContainer: Color(0xFFDEF4DD),
      onSecondaryContainer: Colors.black,
      surfaceVariant: Color(0xFFE9F3EA),
      onSurfaceVariant: Colors.black87,
      outline: Color(0xFF6B8A6B),
      shadow: Colors.black,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: primary,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        minimumSize: const Size.fromHeight(52),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: primary,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
  );
}
