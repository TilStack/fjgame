// Génère les deux ThemeData complets (clair et sombre) pour l'application.
// useMaterial3: true. Police titre Cinzel, corps Inter via Google Fonts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

abstract final class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.lightPrimary,
          secondary: AppColors.lightAccent,
          surface: AppColors.lightSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.lightTextPrimary,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          displayLarge: GoogleFonts.cinzel(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.lightPrimary,
          ),
          headlineLarge: GoogleFonts.cinzel(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.lightPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.lightTextSecondary,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.lightTextSecondary,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.lightTextSecondary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightCardSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.error,
          contentTextStyle: GoogleFonts.inter(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.darkPrimary,
          secondary: AppColors.darkAccent,
          surface: AppColors.darkSurface,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.darkTextPrimary,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.cinzel(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.darkPrimary,
          ),
          headlineLarge: GoogleFonts.cinzel(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.darkPrimary,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.darkTextSecondary,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.darkTextSecondary,
          ),
          labelLarge: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.darkTextSecondary,
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: GoogleFonts.cinzel(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCardSurface,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.error,
          contentTextStyle: GoogleFonts.inter(color: Colors.white),
          behavior: SnackBarBehavior.floating,
        ),
      );

  static const AppBarTheme gameAppBarThemeLight = AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF1A1A1A),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );

  static const AppBarTheme gameAppBarThemeDark = AppBarTheme(
    backgroundColor: Color(0xFF0D0D14),
    foregroundColor: Color(0xFFE0E0E0),
    elevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle.light,
  );
}
