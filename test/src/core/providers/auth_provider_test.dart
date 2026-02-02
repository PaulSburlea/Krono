import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:krono/src/core/providers/auth_provider.dart';
import 'package:krono/src/features/settings/providers/theme_provider.dart';

// Generate mocks
@GenerateMocks([SharedPreferences])
import 'auth_provider_test.mocks.dart';

void main() {
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
      ],
    );
  }

  group('Production Tests for AuthSettingsNotifier', () {
    test('Initial state defaults to FALSE if preference is missing', () {
      // Arrange
      when(mockSharedPreferences.getBool('is_auth_enabled')).thenReturn(null);

      final container = createContainer();

      // Act
      final isEnabled = container.read(authSettingsProvider);

      // Assert
      expect(isEnabled, false);
      verify(mockSharedPreferences.getBool('is_auth_enabled')).called(1);
    });

    test('Initial state loads TRUE if preference is saved as true', () {
      // Arrange
      when(mockSharedPreferences.getBool('is_auth_enabled')).thenReturn(true);

      final container = createContainer();

      // Act
      final isEnabled = container.read(authSettingsProvider);

      // Assert
      expect(isEnabled, true);
    });

    test('toggleAuth updates state and persists to SharedPreferences', () async {
      // Arrange
      when(mockSharedPreferences.getBool('is_auth_enabled')).thenReturn(false);
      when(mockSharedPreferences.setBool(any, any)).thenAnswer((_) async => true);

      final container = createContainer();

      // Verify initial state
      expect(container.read(authSettingsProvider), false);

      // Act
      await container.read(authSettingsProvider.notifier).toggleAuth(true);

      // Assert
      // 1. Verify State Update
      expect(container.read(authSettingsProvider), true);

      // 2. Verify Persistence
      verify(mockSharedPreferences.setBool('is_auth_enabled', true)).called(1);
    });

    test('toggleAuth can disable authentication', () async {
      // Arrange
      when(mockSharedPreferences.getBool('is_auth_enabled')).thenReturn(true);
      when(mockSharedPreferences.setBool(any, any)).thenAnswer((_) async => true);

      final container = createContainer();

      // Act
      await container.read(authSettingsProvider.notifier).toggleAuth(false);

      // Assert
      expect(container.read(authSettingsProvider), false);
      verify(mockSharedPreferences.setBool('is_auth_enabled', false)).called(1);
    });
  });
}