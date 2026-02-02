import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/logger_service.dart';
import 'theme_provider.dart';

/// Provides and manages the application's current [Locale].
///
/// This provider determines the initial locale based on a priority system:
/// 1. User's saved preference.
/// 2. Device's system language.
/// 3. A default fallback locale.
/// It allows the UI to reactively rebuild when the locale is changed.
final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

/// A [Notifier] that handles locale detection, persistence, and state management.
class LocaleNotifier extends Notifier<Locale> {
  /// The key used to persist the user's selected locale in [SharedPreferences].
  static const _storageKey = 'selected_locale';

  /// The default locale to use if no preference is set and the system locale is unsupported.
  static const _defaultLocale = Locale('en');

  /// A list of ISO 639-1 language codes that the application officially supports.
  static const _supportedLanguageCodes = ['en', 'ro', 'fr'];

  @override
  Locale build() {
    // Watches the shared preferences provider for reactive initialization.
    final prefs = ref.watch(sharedPreferencesProvider);
    final languageCode = prefs.getString(_storageKey);

    // Priority 1: Use the language code stored in user preferences.
    if (languageCode != null) {
      Logger.debug('Initializing locale from saved preference: $languageCode');
      return Locale(languageCode);
    }

    // Priority 2: If no preference is found, attempt to use the device's system language.
    final String systemLanguageCode =
        PlatformDispatcher.instance.locale.languageCode;

    if (_supportedLanguageCodes.contains(systemLanguageCode)) {
      Logger.debug('Initializing locale from system setting: $systemLanguageCode');
      return Locale(systemLanguageCode);
    }

    // Priority 3: Fallback to the default locale if the system language is not supported.
    Logger.debug(
        'System locale "$systemLanguageCode" is not supported. Falling back to default.');
    return _defaultLocale;
  }

  /// Updates the application's current locale and persists the new selection.
  ///
  /// This method saves the language code of the given [locale] to local storage
  /// and updates the provider's state, causing the UI to rebuild with the
  /// new translations.
  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);

    final success = await prefs.setString(_storageKey, locale.languageCode);

    if (success) {
      Logger.info('User changed locale to ${locale.languageCode}');
      state = locale;
    } else {
      Logger.error(
        'Failed to persist new locale setting: ${locale.languageCode}',
        'SharedPreferences.setString returned false',
        StackTrace.current,
      );
    }
  }
}