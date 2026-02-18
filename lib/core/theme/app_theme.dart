import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF79835A);
  static const Color backgroundLight = Color(0xFFFDFDFD);
  static const Color backgroundDark = Color(0xFF050505);
  static const Color appBackground = backgroundLight;

  static ThemeData get light {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        surface: appBackground,
      ),
      scaffoldBackgroundColor: appBackground,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      canvasColor: appBackground,
      cardColor: appBackground,
      dialogTheme: const DialogThemeData(backgroundColor: appBackground),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: appBackground,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black38),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
