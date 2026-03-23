import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = Typography.material2021().black;

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryContainer,
        onPrimary: AppColors.onPrimary,
        secondaryContainer: AppColors.secondaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        outlineVariant: AppColors.outlineVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      
      // Typography: Manrope for display, Work Sans for body
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.manrope(
          textStyle: baseTextTheme.displayLarge,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
        displayMedium: GoogleFonts.manrope(
          textStyle: baseTextTheme.displayMedium,
          letterSpacing: -0.02,
          color: AppColors.onSurface,
        ),
        headlineLarge: GoogleFonts.manrope(
          textStyle: baseTextTheme.headlineLarge,
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.manrope(
          textStyle: baseTextTheme.headlineMedium,
          color: AppColors.onSurface,
        ),
        titleLarge: GoogleFonts.workSans(
          textStyle: baseTextTheme.titleLarge,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.workSans(
          textStyle: baseTextTheme.titleMedium,
          color: AppColors.onSurface,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.workSans(
          textStyle: baseTextTheme.bodyLarge,
          color: AppColors.onSurface,
        ),
        bodyMedium: GoogleFonts.workSans(
          textStyle: baseTextTheme.bodyMedium,
          color: AppColors.onSurface,
        ),
        labelLarge: GoogleFonts.workSans(
          textStyle: baseTextTheme.labelLarge,
          color: AppColors.onSurface,
        ),
      ),
      
      // Component Themes
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0), // 'md' roundness ~ 0.375rem / 6px
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1.0),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outlineVariant, width: 1.0), // "Ghost border"
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),
    );
  }
}
