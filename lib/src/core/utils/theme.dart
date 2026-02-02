import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Provides centralized theme configurations for the application.
///
/// This class encapsulates the logic for generating Material 3 [ThemeData]
/// based on user preferences such as accent colors and brightness modes. It
/// ensures a consistent visual identity across the entire widget tree.
class AppTheme {
  /// The standard corner radius applied to cards and surface containers.
  static const double _cardRadius = 24.0;

  /// Generates the light [ThemeData] derived from the provided [accentColor].
  ///
  /// Uses the [accentColor] as a seed to generate a harmonious Material 3
  /// [ColorScheme]. This method configures global component themes for the
  /// [AppBar] and [Card] to maintain a clean, flat aesthetic by disabling
  /// unnecessary elevations and tinting.
  static ThemeData createLightTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: accentColor,

      // Applies the Poppins font family across the entire application.
      textTheme: GoogleFonts.poppinsTextTheme(),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        // Disabling scrolledUnderElevation prevents the AppBar from changing
        // color when content scrolls beneath it.
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        // Ensures the card surface remains white rather than adopting
        // a primary-colored tint from the Material 3 color scheme.
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
    );
  }

  /// Generates the dark [ThemeData] derived from the provided [accentColor].
  ///
  /// This configuration is optimized for OLED displays using a near-black
  /// background to improve contrast and energy efficiency. It mirrors the
  /// component configurations of the light theme while adjusting surface
  /// colors for high legibility in low-light environments.
  static ThemeData createDarkTheme(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: accentColor,

      // OLED-optimized background for deeper blacks.
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),

      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),

      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        // Uses a slightly lighter grey for cards to provide visual depth
        // against the true black scaffold background.
        color: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_cardRadius),
        ),
      ),
    );
  }
}