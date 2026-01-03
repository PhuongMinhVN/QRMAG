import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryRed = Color(0xFFA01515); // Richer Red
  static const Color backgroundWhite = Color(0xFFF8F9FA); // Modern Cool White
  static const Color darkGrey = Color(0xFF2D3436);
  static const Color softGrey = Color(0xFFE0E0E0);
  
  // Backward compatibility aliases
  static const Color darkRed = primaryRed;
  static const Color cream = backgroundWhite;

  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryRed,
      primary: primaryRed,
      onPrimary: Colors.white,
      secondary: primaryRed,
      surface: Colors.white,
      onSurface: darkGrey,
      background: backgroundWhite,
    ),
    scaffoldBackgroundColor: backgroundWhite,
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: darkGrey,
      displayColor: darkGrey,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryRed,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryRed, width: 2),
      ),
    ),
    // cardTheme removed to resolve compilation error
  );
}
