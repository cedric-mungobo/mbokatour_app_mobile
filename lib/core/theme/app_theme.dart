import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Logo palette: gold, red, slate blue, and black.
  static const Color primary = Color(0xFFFAB40F);
  static const Color accentRed = Color(0xFFE10000);
  static const Color accentBlue = Color(0xFF3B4D6A);
  static const Color brandBlack = Color(0xFF050505);
  static const Color backgroundLight = Color(0xFFF9F6EE);
  static const Color appBackground = backgroundLight;
  static const Color borderColor = Color(0xFFD2D7DF);
  static const Color hintColor = Color(0xFF6E7A8E);

  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: brandBlack,
          secondary: accentRed,
          onSecondary: Colors.white,
          error: accentRed,
          onError: Colors.white,
          surface: appBackground,
          onSurface: brandBlack,
        );

    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: appBackground,
    );

    return base.copyWith(
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ).apply(bodyColor: brandBlack, displayColor: brandBlack),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBackground,
        foregroundColor: brandBlack,
        elevation: 0,
      ),
      canvasColor: appBackground,
      cardColor: Colors.white,
      dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primary,
        contentTextStyle: TextStyle(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: brandBlack,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentRed,
          side: const BorderSide(color: primary),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentRed,
        foregroundColor: Colors.white,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: primary.withValues(alpha: 0.22),
        labelStyle: const TextStyle(color: brandBlack),
        side: const BorderSide(color: borderColor),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentRed,
        linearTrackColor: borderColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.45);
          }
          return borderColor;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return Colors.white;
        }),
        side: const BorderSide(color: accentBlue),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentBlue;
          return hintColor;
        }),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primary.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(color: brandBlack, fontWeight: FontWeight.w600),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: accentRed);
          }
          return const IconThemeData(color: accentBlue);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: accentBlue),
        hintStyle: const TextStyle(color: hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 14,
        ),
      ),
    );
  }
}
