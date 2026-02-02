import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:krono/src/core/providers/notification_provider.dart';
import 'package:krono/src/features/settings/providers/theme_provider.dart';
import 'package:krono/src/features/settings/providers/locale_provider.dart';
import 'package:krono/src/core/utils/notification_service.dart';

// Generate mocks
@GenerateMocks([NotificationService, SharedPreferences])
import 'notification_provider_test.mocks.dart';

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en');
}

void main() {
  late MockNotificationService mockNotificationService;
  late MockSharedPreferences mockSharedPreferences;

  setUp(() {
    mockNotificationService = MockNotificationService();
    mockSharedPreferences = MockSharedPreferences();

    // ✅ FIX: Add default stubs for all SharedPreferences calls
    when(mockSharedPreferences.getBool(any)).thenReturn(null);
    when(mockSharedPreferences.getInt(any)).thenReturn(null);
    when(mockSharedPreferences.getString(any)).thenReturn(null);
    when(mockSharedPreferences.setBool(any, any)).thenAnswer((_) async => true);
    when(mockSharedPreferences.setInt(any, any)).thenAnswer((_) async => true);
    when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

    when(mockNotificationService.canScheduleExactAlarms())
        .thenAnswer((_) async => true);
    when(mockNotificationService.requestPermission())
        .thenAnswer((_) async => true);
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        notificationServiceProvider.overrideWithValue(mockNotificationService),
        sharedPreferencesProvider.overrideWithValue(mockSharedPreferences),
        localeProvider.overrideWith(() => FakeLocaleNotifier()),
      ],
    );
  }

  group('Production Tests for NotificationNotifier', () {
    test('Initial state is loaded from SharedPreferences (Defaults)', () {
      // Arrange
      when(mockSharedPreferences.getBool('notifications_enabled')).thenReturn(null);
      when(mockSharedPreferences.getInt('notifications_hour')).thenReturn(null);
      when(mockSharedPreferences.getInt('notifications_minute')).thenReturn(null);

      final container = createContainer();

      // Act
      final state = container.read(notificationProvider);

      // Assert
      expect(state.isEnabled, false);
      expect(state.hour, 20);
      expect(state.minute, 0);
    });

    test('Initial state is loaded from SharedPreferences (Saved Values)', () {
      // Arrange
      when(mockSharedPreferences.getBool('notifications_enabled')).thenReturn(true);
      when(mockSharedPreferences.getInt('notifications_hour')).thenReturn(8);
      when(mockSharedPreferences.getInt('notifications_minute')).thenReturn(30);

      final container = createContainer();

      // Act
      final state = container.read(notificationProvider);

      // Assert
      expect(state.isEnabled, true);
      expect(state.hour, 8);
      expect(state.minute, 30);
    });

    test('updateSettings (Enable) persists data and schedules notification', () async {
      // Arrange
      final container = createContainer();

      // Act
      await container.read(notificationProvider.notifier).updateSettings(true, 9, 0);

      // Assert
      verify(mockSharedPreferences.setBool('notifications_enabled', true)).called(1);
      verify(mockSharedPreferences.setInt('notifications_hour', 9)).called(1);
      verify(mockSharedPreferences.setInt('notifications_minute', 0)).called(1);
      verify(mockNotificationService.requestPermission()).called(1);
      verify(mockNotificationService.scheduleDailyReminder(
        title: anyNamed('title'),
        body: anyNamed('body'),
        hour: 9,
        minute: 0,
      )).called(1);

      final state = container.read(notificationProvider);
      expect(state.isEnabled, true);
      expect(state.hour, 9);
    });

    test('updateSettings (Disable) cancels notifications', () async {
      // Arrange
      final container = createContainer();

      // Act
      await container.read(notificationProvider.notifier).updateSettings(false, 9, 0);

      // Assert
      verify(mockNotificationService.cancelAll()).called(1);
      verifyNever(mockNotificationService.scheduleDailyReminder(
          title: anyNamed('title'),
          body: anyNamed('body'),
          hour: anyNamed('hour'),
          minute: anyNamed('minute')
      ));

      final state = container.read(notificationProvider);
      expect(state.isEnabled, false);
    });
  });
}