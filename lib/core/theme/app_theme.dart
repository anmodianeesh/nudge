import 'package:flutter/material.dart';

class AppTheme {
  // BRAND
  static const brand = Color(0xFF5B7CFA);
  static const brandOn = Colors.white;
  
  // Additional color aliases
  static const primaryPurple = brand;
  static const primaryBlue = brand;
  
  // SURFACES
  static const background = Color(0xFFF6F7F9);
  static const surface = Colors.white;
  static const border = Color(0xFFE6E8EC);
  
  // Aliases for new screens
  static const backgroundGray = background;
  static const cardWhite = surface;
  static const borderGray = border;

  // TEXT
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textMuted = Color(0xFF94A3B8);
  
  // Text aliases
  static const textDark = textPrimary;
  static const textGray = textSecondary;
  static const textLight = Colors.white;

  // GRADIENTS (as static getters, not const)
  static LinearGradient get backgroundGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [background, Color(0xFFEDF2F7)],
  );
  
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, Color(0xFF4C6EF5)],
  );

  // RADII
  static const rLg = 20.0;
  static const rMd = 16.0;

  // Main theme - renamed from 'theme' to 'lightTheme'
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: brand).copyWith(
      background: background,
      surface: surface,
      outline: border,
    ),
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      iconTheme: IconThemeData(color: textSecondary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rLg),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rLg),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(rLg),
        borderSide: const BorderSide(color: brand),
      ),
      hintStyle: const TextStyle(color: textMuted),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: textPrimary),
      labelMedium: TextStyle(color: textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: brandOn,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rMd),
        ),
      ),
    ),
  );
  
  // Keep the old 'theme' getter for backward compatibility
  static ThemeData get theme => lightTheme;
}