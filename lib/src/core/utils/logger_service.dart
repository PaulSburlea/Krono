import 'dart:developer' as dev;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// A centralized logging utility for the application.
///
/// Provides a standardized interface for different log levels, integrating
/// with `dart:developer` for local debugging and `FirebaseCrashlytics`
/// for production error reporting.
///
/// Safe to use before Firebase is initialized (logs will be skipped or printed locally).
class Logger {
  /// Private constructor to prevent instantiation of this utility class.
  Logger._();

  /// Checks if Firebase has been initialized to prevent [FirebaseCrashlytics] errors.
  static bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Logs a verbose message, intended for deep debugging.
  ///
  /// Use for tracking variable states, raw data dumps, or function entry/exit points.
  /// These logs are only visible in the debug console and are completely stripped
  /// from release builds due to the [kDebugMode] check.
  static void debug(String message) {
    if (kDebugMode) {
      // Using dart:developer's log to prevent truncation of long messages in the console.
      dev.log('🐛 [DEBUG]: $message', name: 'Krono');
    }
  }

  /// Logs an informational message that tracks application flow.
  ///
  /// Use for significant user actions, navigation events, or state changes.
  /// In `kDebugMode`, it prints to the console. In all builds, it is sent
  /// to Crashlytics as a breadcrumb to provide context for potential errors.
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [INFO]: $message');
    }

    if (_isFirebaseReady) {
      try {
        FirebaseCrashlytics.instance.log(message);
      } catch (_) {
        // Silently fail if Crashlytics has issues
      }
    }
  }

  /// Logs a non-fatal warning.
  ///
  /// Use for handled exceptions or recoverable errors where the application can
  /// continue, such as a failed network request that will be retried.
  /// The optional [error] and [stackTrace] are recorded in Crashlytics as a non-fatal issue.
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('⚠️ [WARNING]: $message');
    }

    if (_isFirebaseReady) {
      try {
        FirebaseCrashlytics.instance.log('WARNING: $message');
        if (error != null) {
          FirebaseCrashlytics.instance
              .recordError(error, stackTrace, printDetails: false);
        }
      } catch (_) {}
    }
  }

  /// Logs a critical, potentially fatal error.
  ///
  /// This should be used exclusively in `catch` blocks for unexpected exceptions
  /// that disrupt the user experience. The [message], [error], and [stackTrace]
  /// are sent to Crashlytics as a fatal issue, which will trigger alerts.
  static void error(String message, dynamic error, StackTrace stackTrace) {
    // Always print to console in Debug mode
    if (kDebugMode) {
      dev.log(
        '🚨 [ERROR]: $message',
        error: error,
        stackTrace: stackTrace,
        name: 'Krono',
      );
    } else {
      // In release mode, if Firebase isn't ready, print to stdout so we can debug startup crashes
      if (!_isFirebaseReady) {
        debugPrint('🚨 [ERROR - NO FIREBASE]: $message\n$error\n$stackTrace');
      }
    }

    if (_isFirebaseReady) {
      try {
        // Add a final log message for context before reporting the error.
        FirebaseCrashlytics.instance.log('CRITICAL: $message');
        FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      } catch (_) {}
    }
  }
}