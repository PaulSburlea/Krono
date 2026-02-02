import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger_service.dart';

/// Provides the global singleton instance of [SharedPreferences].
///
/// This provider is essential for persistence throughout the app. It is declared
/// here but must be initialized in the `main.dart` file by overriding its
/// value within the root [ProviderScope].
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  // This exception serves as a safeguard to ensure the provider is correctly
  // initialized at app startup.
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

// --- THEME MODE MANAGEMENT ---

/// Manages the application's overall brightness [ThemeMode] (light, dark, or system).
///
/// This provider exposes the [ThemeNotifier], allowing the UI to reactively
/// rebuild when the theme changes and providing methods to update the theme.
final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

/// A [Notifier] responsible for managing and persisting the application's theme state.
///
/// On the first launch, it defaults to [ThemeMode.system], allowing the operating
/// system to control the theme. Once a user manually selects a theme, that
/// choice is persisted and will override the system setting on subsequent launches.
class ThemeNotifier extends Notifier<ThemeMode> {
  /// The key used to store the theme preference in [SharedPreferences].
  static const _themeKey = 'user_theme_preference';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final String? savedTheme = prefs.getString(_themeKey);

    // If no preference is saved, the app will follow the system's brightness setting.
    if (savedTheme == null) {
      Logger.debug('No saved theme preference found, defaulting to system theme.');
      return ThemeMode.system;
    }

    // Maps the stored string preference back to its corresponding ThemeMode enum.
    return switch (savedTheme) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.system, // Fallback for any unexpected stored value.
    };
  }

  /// Toggles the theme between [ThemeMode.light] and [ThemeMode.dark].
  ///
  /// This action persists the new choice, effectively overriding the system
  /// setting until it is explicitly reset.
  Future<void> toggleTheme() async {
    final newMode =
    (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    await setTheme(newMode);
  }

  /// Sets the application theme to a specific [ThemeMode] and persists the choice.
  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;

    Logger.info('User changed theme to ${mode.name}.');
    await prefs.setString(_themeKey, mode.name);
  }

  /// Resets the theme preference, causing the app to follow the OS theme again.
  ///
  /// This is achieved by removing the stored preference from [SharedPreferences].
  Future<void> resetToSystem() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_themeKey);
    state = ThemeMode.system;
    Logger.info('User reset theme to follow system setting.');
  }
}

// --- ACCENT COLOR MANAGEMENT ---

/// Manages the application's primary accent [Color].
///
/// This provider exposes the [AccentColorNotifier], allowing the UI to
/// reactively update when the accent color is changed.
final accentColorProvider = NotifierProvider<AccentColorNotifier, Color>(() {
  return AccentColorNotifier();
});

/// A [Notifier] responsible for managing and persisting the user's chosen accent color.
class AccentColorNotifier extends Notifier<Color> {
  /// The key used to store the accent color in [SharedPreferences].
  static const _accentKey = 'user_accent_color';

  /// The default brand color used if no custom color has been selected.
  static const Color kronoOriginal = Color(0xFF6366F1);

  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final int? savedColorValue = prefs.getInt(_accentKey);

    return savedColorValue != null ? Color(savedColorValue) : kronoOriginal;
  }

  /// Updates the application's accent color and persists the new value.
  ///
  /// The [color] is stored as an integer representation.
  Future<void> setAccentColor(Color color) async {
    final prefs = ref.read(sharedPreferencesProvider);
    state = color;
    Logger.info('User changed accent color to ${color.toString()}.');
    // The extension method `toARGB32()` is assumed to exist on Color.
    // If not, `color.value` is the standard way to get the integer.
    await prefs.setInt(_accentKey, color.toARGB32());
  }
}