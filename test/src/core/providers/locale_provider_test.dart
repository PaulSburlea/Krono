import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krono/src/features/settings/providers/locale_provider.dart';
import 'package:krono/src/features/settings/providers/theme_provider.dart';

@GenerateMocks([SharedPreferences])
import 'locale_provider_test.mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    TestWidgetsFlutterBinding.ensureInitialized();
    // Ensure setString returns true so the state updates
    when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
  });

  ProviderContainer createContainer() => ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(mockPrefs)]
  );

  group('LocaleNotifier Tests', () {
    test('setLocale updates state', () async {
      when(mockPrefs.getString(any)).thenReturn('en');
      final container = createContainer();

      // Listen to the provider to capture state changes
      final listener = ProviderListener<Locale>();

      // Fixed: Explicitly tear off the 'call' method to resolve linter warning
      container.listen(localeProvider, listener.call, fireImmediately: true);

      // Act
      await container.read(localeProvider.notifier).setLocale(const Locale('ro'));

      // Assert: Check the last emitted value
      expect(listener.log.last.languageCode, 'ro');
    });
  });
}

/// Helper class to capture provider state changes.
class ProviderListener<T> {
  final List<T> log = [];

  /// Callable method to match the provider listener signature.
  void call(T? previous, T next) => log.add(next);
}