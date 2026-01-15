import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      tz.setLocalLocation(tz.UTC);
    }

    // Aici folosim 'notification_icon' care trebuie sa fie alba pe fundal transparent
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('notification_icon');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {},
    );
  }

  static Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidImpl?.requestNotificationsPermission();
      final exactAlarm = await androidImpl?.requestExactAlarmsPermission();

      return (granted ?? false) && (exactAlarm ?? true);
    }
    return true;
  }

  static Future<void> scheduleDailyReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _notificationsPlugin.cancelAll();

    final scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notificationsPlugin.zonedSchedule(
      0,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel_v9', // ✅ ID NOU pentru a reseta setările pe A50
          'Daily Reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'notification_icon', // Aceasta e cea albă

          // ✅ ACEASTA ESTE CHEIA:
          // Setează culoarea cercului la negru (#101010).
          // Astfel, iconița ta ALBĂ se va vedea perfect în interiorul cercului NEGRU.
          color: const Color(0xFF101010),

          // Forțează utilizarea culorii pe sistemele Samsung mai vechi
          colorized: false,

          // Menținem și poza mare pentru branding
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

          fullScreenIntent: true,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}