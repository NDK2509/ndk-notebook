import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Dark Theme Color System (Default & Recommended)
  static const Color darkBackground = Color(0xFF0F0F11);
  static const Color darkSidebarBackground = Color(0xFF16161A);
  static const Color darkCardBackground = Color(0xFF1E1E24);
  static const Color darkBorder = Color(0xFF2E2E38);
  static const Color darkAccentBlue = Color(0xFF0EA5E9); // Modern sky blue
  static const Color darkAccentTeal = Color(0xFF0D9488);
  static const Color darkTextPrimary = Color(0xFFF3F4F6);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Light Theme Color System
  static const Color lightBackground = Color(0xFFFAFAFC);
  static const Color lightSidebarBackground = Color(0xFFF3F4F6);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightAccentBlue = Color(0xFF0284C7); // Rich sky blue
  static const Color lightAccentTeal = Color(0xFF0F766E);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF4B5563);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: darkAccentBlue,
        secondary: darkAccentTeal,
        background: darkBackground,
        surface: darkCardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
        outline: darkBorder,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: darkTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: darkTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: darkTextSecondary),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: darkCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: darkAccentBlue,
        selectionColor: Color(0x4D0EA5E9), // 30% opacity blue
        selectionHandleColor: darkAccentBlue,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: lightAccentBlue,
        secondary: lightAccentTeal,
        background: lightBackground,
        surface: lightCardBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: lightTextPrimary,
        outline: lightBorder,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: lightTextPrimary),
          bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: lightTextPrimary),
          bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: lightTextSecondary),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: lightCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        elevation: 0,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: lightAccentBlue,
        selectionColor: Color(0x330284C7), // 20% opacity blue
        selectionHandleColor: lightAccentBlue,
      ),
    );
  }
}
