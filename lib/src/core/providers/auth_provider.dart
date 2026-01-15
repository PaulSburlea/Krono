import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';

final authSettingsProvider = NotifierProvider<AuthSettingsNotifier, bool>(() {
  return AuthSettingsNotifier();
});

class AuthSettingsNotifier extends Notifier<bool> {
  static const _key = 'is_auth_enabled';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggleAuth(bool value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_key, value);
    state = value;
  }
}