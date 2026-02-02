import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'logger_service.dart';

/// Provides a singleton instance of [NotificationService].
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});

/// Service responsible for managing local notifications, permissions, and scheduling.
///
/// This service handles the complexities of timezone detection, platform-specific
/// permission requests (Android/iOS), and ensures daily reminders are scheduled
/// according to the user's local time.
class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  /// Creates a [NotificationService] with the required [FlutterLocalNotificationsPlugin].
  NotificationService(this._notificationsPlugin);

  /// Initializes the notification engine and configures the local timezone location.
  ///
  /// This method performs complex timezone detection with multiple fallback layers
  /// to ensure the scheduling engine functions even if system reporting is irregular.
  Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final dynamic rawLocation = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = rawLocation?.toString() ?? 'UTC';

      // Handle "TimezoneInfo(Europe/Bucharest)" format found on some devices.
      if (timeZoneName.contains('(')) {
        timeZoneName = timeZoneName.split('(').last.replaceAll(')', '');
      }

      // Handle "locale: ..., name: ..." format; if localized, fallback to system ID.
      if (timeZoneName.contains('name: ')) {
        timeZoneName = DateTime.now().timeZoneName;
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        Logger.info('Local timezone set to: $timeZoneName');
      } catch (_) {
        // Fallback: If the detected ID is invalid, try the system's short name.
        try {
          final systemName = DateTime.now().timeZoneName;
          tz.setLocalLocation(tz.getLocation(systemName));
          Logger.info('Timezone detection fallback to system name: $systemName');
        } catch (e2, stack) {
          tz.setLocalLocation(tz.UTC);
          Logger.warning('All timezone detection failed. Defaulting to UTC.', e2, stack);
        }
      }
    } catch (e, stack) {
      Logger.error('Fatal initialization error in NotificationService', e, stack);
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('notification_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  /// Verifies if the application has permission to schedule exact alarms.
  ///
  /// On Android 12+, exact alarms require specific user permission.
  /// Returns `true` if permitted or if the platform does not require it.
  Future<bool> canScheduleExactAlarms() async {
    if (Platform.isAndroid) {
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }

  /// Redirects the user to the system settings to permit exact alarms.
  Future<void> openExactAlarmSettings() async {
    if (Platform.isAndroid) {
      Logger.info('Requesting exact alarm permission from user.');
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// Requests the necessary notification permissions from the operating system.
  ///
  /// Handles both Android and iOS platform-specific permission implementations.
  /// Returns `true` if the user grants the required permissions.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      return await androidImpl?.requestNotificationsPermission() ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await iosImpl?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  /// Schedules a recurring daily notification at the specified [hour] and [minute].
  ///
  /// This method cancels all existing notifications before scheduling the new one
  /// to ensure no duplicate reminders are active. It uses [title] and [body]
  /// for the notification content.
  Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.cancelAll();

    final scheduledDate = _nextInstanceOfTime(hour, minute);
    final bool hasExactPermission = await canScheduleExactAlarms();

    try {
      await _notificationsPlugin.zonedSchedule(
        0,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_channel_v5',
            'Jurnal Zilnic',
            importance: Importance.max,
            priority: Priority.high,
            color: Color(0xFF6366F1),
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: hasExactPermission
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      Logger.info('Daily reminder scheduled for $hour:$minute (Exact: $hasExactPermission)');
    } catch (e, stack) {
      Logger.error('Failed to schedule daily reminder', e, stack);
    }
  }

  /// Cancels all active and pending notifications managed by this service.
  Future<void> cancelAll() async {
    Logger.info('Cancelling all active notifications.');
    await _notificationsPlugin.cancelAll();
  }

  /// Calculates the next [tz.TZDateTime] for a given [hour] and [minute].
  ///
  /// If the specified time has already passed today, it returns the time for tomorrow.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}