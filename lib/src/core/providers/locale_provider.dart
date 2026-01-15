import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

// ✅ Definirea Provider-ului pentru Riverpod 3.0
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  static const _key = 'selected_locale';

  @override
  Locale build() {
    // În Riverpod 3.0, watch-uim prefs direct în build
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_key);

    // Returnăm starea inițială (limba salvată sau English ca default)
    return code != null ? Locale(code) : const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);

    // Actualizăm starea
    state = locale;
  }
}