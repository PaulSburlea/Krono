import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider pentru SharedPreferences (rămâne neschimbat, se face override în main.dart)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences nu a fost override în main.dart');
});

// --- THEME MODE (Dark/Light) ---

final themeNotifierProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'user_theme_preference';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'dark') return ThemeMode.dark;
    if (savedTheme == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void toggleTheme() {
    final prefs = ref.read(sharedPreferencesProvider);
    state = (state == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
    prefs.setString(_themeKey, state == ThemeMode.dark ? 'dark' : 'light');
  }

  void setTheme(ThemeMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    state = mode;
    prefs.setString(_themeKey, mode.toString().split('.').last);
  }
}

// --- ACCENT COLOR (Teme de culori) ---

final accentColorProvider = NotifierProvider<AccentColorNotifier, Color>(() {
  return AccentColorNotifier();
});

class AccentColorNotifier extends Notifier<Color> {
  static const _accentKey = 'user_accent_color';
  static const Color kronoOriginal = Color(0xFF6366F1);

  @override
  Color build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedColorValue = prefs.getInt(_accentKey);
    return savedColorValue != null ? Color(savedColorValue) : kronoOriginal;
  }

  void setAccentColor(Color color) {
    final prefs = ref.read(sharedPreferencesProvider);
    state = color;
    prefs.setInt(_accentKey, color.value);
  }
}