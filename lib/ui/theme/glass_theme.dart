import 'package:flutter/material.dart';

class GlassColors {
  // Light theme glassmorphism colors
  static const glassWhite = Color(0x33FFFFFF); // 20% white
  static const glassBorder = Color(0x4DFFFFFF); // 30% white
  static const glassShadow = Color(0x1A000000); // 10% black
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xCCFFFFFF); // 80% white
  static const accentGlow = Color(0xFF64B5F6); // Light blue glow

  // Dark theme glassmorphism colors
  static const glassDark = Color(0x1AFFFFFF); // 10% white
  static const glassBorderDark = Color(0x26FFFFFF); // 15% white
  static const glassShadowDark = Color(0x33000000); // 20% black
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xB3FFFFFF); // 70% white
  static const accentGlowDark = Color(0xFF42A5F5);

  // Temperature colors with glow
  static const hotGlow = Color(0xFFFF6B6B);
  static const warmGlow = Color(0xFFFFA751);
  static const coolGlow = Color(0xFF4ECDC4);
  static const coldGlow = Color(0xFF95E1D3);
}

class GlassTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: GlassColors.accentGlow,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.light(
        primary: GlassColors.accentGlow,
        onPrimary: Colors.white,
        secondary: Color(0xFF81C784),
        onSecondary: Colors.white,
        surface: Colors.transparent,
        onSurface: GlassColors.textPrimary,
        onSurfaceVariant: GlassColors.textSecondary,
        error: Color(0xFFEF5350),
      ),
      textTheme: _buildTextTheme(GlassColors.textPrimary),
      iconTheme: const IconThemeData(
        color: GlassColors.textPrimary,
        size: 24,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: GlassColors.textPrimary,
        iconTheme: IconThemeData(color: GlassColors.textPrimary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GlassColors.glassWhite,
        foregroundColor: GlassColors.textPrimary,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GlassColors.glassWhite,
          foregroundColor: GlassColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: GlassColors.glassBorder,
              width: 1.5,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassColors.glassWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.glassBorder,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.glassBorder,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.accentGlow,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: GlassColors.textSecondary,
        ),
        labelStyle: const TextStyle(
          color: GlassColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: GlassColors.accentGlowDark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: GlassColors.accentGlowDark,
        onPrimary: Colors.white,
        secondary: Color(0xFF66BB6A),
        onSecondary: Colors.white,
        surface: Colors.transparent,
        onSurface: GlassColors.textPrimaryDark,
        onSurfaceVariant: GlassColors.textSecondaryDark,
        error: Color(0xFFE57373),
      ),
      textTheme: _buildTextTheme(GlassColors.textPrimaryDark),
      iconTheme: const IconThemeData(
        color: GlassColors.textPrimaryDark,
        size: 24,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: GlassColors.textPrimaryDark,
        iconTheme: IconThemeData(color: GlassColors.textPrimaryDark),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: GlassColors.glassDark,
        foregroundColor: GlassColors.textPrimaryDark,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GlassColors.glassDark,
          foregroundColor: GlassColors.textPrimaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: GlassColors.glassBorderDark,
              width: 1.5,
            ),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: GlassColors.glassDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.glassBorderDark,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.glassBorderDark,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: GlassColors.accentGlowDark,
            width: 2,
          ),
        ),
        hintStyle: const TextStyle(
          color: GlassColors.textSecondaryDark,
        ),
        labelStyle: const TextStyle(
          color: GlassColors.textPrimaryDark,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
        color: primaryColor,
      ),
      displayMedium: TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      displaySmall: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: primaryColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: primaryColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primaryColor,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: primaryColor,
      ),
      titleSmall: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: primaryColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: primaryColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: primaryColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: primaryColor.withValues(alpha: 0.8),
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.25,
        color: primaryColor,
      ),
    );
  }
}

