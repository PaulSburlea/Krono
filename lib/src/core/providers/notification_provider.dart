import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../features/settings/providers/locale_provider.dart';
import '../../features/settings/providers/theme_provider.dart';
import '../utils/logger_service.dart';
import '../utils/notification_service.dart';

/// An immutable data class representing the user's notification settings.
@immutable
class NotificationState {
  /// Whether the daily reminder notification is enabled.
  final bool isEnabled;

  /// The hour (0-23) at which the notification should be delivered.
  final int hour;

  /// The minute (0-59) at which the notification should be delivered.
  final int minute;

  /// Creates an instance of the notification settings state.
  const NotificationState({
    this.isEnabled = false,
    this.hour = 20,
    this.minute = 0,
  });

  /// Creates a new [NotificationState] instance with updated values.
  NotificationState copyWith({bool? isEnabled, int? hour, int? minute}) {
    return NotificationState(
      isEnabled: isEnabled ?? this.isEnabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is NotificationState &&
              runtimeType == other.runtimeType &&
              isEnabled == other.isEnabled &&
              hour == other.hour &&
              minute == other.minute;

  @override
  int get hashCode => isEnabled.hashCode ^ hour.hashCode ^ minute.hashCode;
}

/// Manages the state of the daily reminder notification settings.
///
/// This provider exposes the [NotificationNotifier], allowing the UI to read
/// and update notification preferences.
final notificationProvider =
NotifierProvider<NotificationNotifier, NotificationState>(() {
  return NotificationNotifier();
});

/// A [Notifier] that handles the business logic for notification settings.
///
/// This class is responsible for reading and writing settings to [SharedPreferences]
/// and interacting with the [NotificationService] to schedule or cancel
/// system alarms based on user preferences.
class NotificationNotifier extends Notifier<NotificationState> {
  /// The storage key for the notification enabled/disabled flag.
  static const String _keyEnabled = 'notifications_enabled';

  /// The storage key for the notification's scheduled hour.
  static const String _keyHour = 'notifications_hour';

  /// The storage key for the notification's scheduled minute.
  static const String _keyMinute = 'notifications_minute';

  @override
  NotificationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final enabled = prefs.getBool(_keyEnabled) ?? false;
    final hour = prefs.getInt(_keyHour) ?? 20;
    final minute = prefs.getInt(_keyMinute) ?? 0;
    return NotificationState(isEnabled: enabled, hour: hour, minute: minute);
  }

  /// Updates notification settings and synchronizes them with the system's scheduler.
  ///
  /// This method persists the user's choices and then either schedules a new
  /// daily reminder or cancels all existing ones. It returns a boolean
  /// indicating if the app has permission to schedule exact alarms.
  Future<bool> updateSettings(bool enabled, int h, int m,
      {bool force = false}) async {
    if (!force &&
        state.isEnabled == enabled &&
        state.hour == h &&
        state.minute == m) {
      Logger.debug('Skipping notification update; settings are unchanged.');
      return true;
    }

    try {
      Logger.info('Updating notification settings: enabled=$enabled, time=$h:$m');
      final prefs = ref.read(sharedPreferencesProvider);
      await Future.wait([
        prefs.setBool(_keyEnabled, enabled),
        prefs.setInt(_keyHour, h),
        prefs.setInt(_keyMinute, m),
      ]);

      state = state.copyWith(isEnabled: enabled, hour: h, minute: m);
      final service = ref.read(notificationServiceProvider);

      if (enabled) {
        final hasPermission = await service.requestPermission();
        if (hasPermission) {
          final currentLocale = ref.read(localeProvider);
          final l10n = await AppLocalizations.delegate.load(currentLocale);

          await service.scheduleDailyReminder(
            title: l10n.notificationTitle,
            body: l10n.notificationBody,
            hour: h,
            minute: m,
          );
          Logger.info('Scheduled daily reminder for $h:$m.');
        }
      } else {
        await service.cancelAll();
        Logger.info('Cancelled all scheduled notifications.');
      }

      return await service.canScheduleExactAlarms();
    } catch (e, stack) {
      Logger.error('Failed to update notification settings', e, stack);
      return false;
    }
  }
}