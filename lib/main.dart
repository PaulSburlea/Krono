import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:krono/src/core/utils/thumbnail/thumbnail_migration.dart';
import 'package:krono/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- FIREBASE IMPORTS ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'firebase_options.dart';

// --- LOCAL IMPORTS ---
import 'l10n/app_localizations.dart';
import 'src/core/bootstrap/cleanup_runner.dart';
import 'src/core/database/database.dart';
import 'src/features/settings/providers/locale_provider.dart';
import 'src/features/settings/providers/theme_provider.dart';
import 'src/core/utils/activity_sync.dart';
import 'src/core/utils/auth_wrapper.dart';
import 'src/core/utils/backup_service.dart';
import 'src/core/utils/logger_service.dart';
import 'src/core/utils/notification_service.dart';
import 'src/core/utils/theme.dart';
import 'src/features/journal/presentation/main_wrapper.dart';

/// Initializes locale date formatting data for supported languages.
///
/// This ensures that date formatting functions (e.g., from the `intl` package)
/// work correctly for Romanian, English, and French before the UI renders.
Future<void> _initializeDateFormatting() async {
  final locales = ['ro', 'en', 'fr'];
  await Future.wait(locales.map((locale) => initializeDateFormatting(locale, null)));
}

/// The application entry point.
///
/// Sets up the execution zone to catch global errors, initializes critical
/// services (Firebase, Database, Preferences) in parallel for performance,
/// and schedules non-critical background tasks to run after the UI is visible.
void main() async {
  runZonedGuarded<Future<void>>(() async {
    // 1. Mandatory minimal initialization
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // 2. Load critical resources in parallel to minimize startup time
    Logger.info('Bootstrap: Initializing critical resources...');
    final initResults = await Future.wait([
      SharedPreferences.getInstance(), // Index 0
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform), // Index 1
      _initializeDateFormatting(), // Index 2
    ]);

    final prefs = initResults[0] as SharedPreferences;

    // 👇 ADAUGĂ ACEST BLOC AICI 👇
    if (kDebugMode) {
      // Această linie va reseta onboarding-ul la fiecare restart în Debug
      // Comenteaz-o după ce ai terminat de testat ecranul!
      await prefs.setBool('onboarding_completed', false);

    }

    // 3. Configure core services
    // Pass all uncaught Flutter errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    final database = AppDatabase();
    final notificationService = NotificationService(FlutterLocalNotificationsPlugin());
    await notificationService.init();

    // Optimize Image Cache for list performance
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB

    Logger.info('Bootstrap: Services initialized. Launching UI.');

    // Check if the user has completed the onboarding flow
    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // 4. Launch the application
    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(database),
          notificationServiceProvider.overrideWithValue(notificationService),
        ],
        child: KronoApp(onboardingCompleted: onboardingCompleted),
      ),
    );

    // 5. Deferred Tasks
    // These operations run in the background after the first frame is rendered
    // to prevent blocking the main thread during startup.
    Future.microtask(() async {
      Logger.info('Bootstrap: Starting deferred background tasks.');
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          Logger.info('Auth: Signing in anonymously.');
          await FirebaseAuth.instance.signInAnonymously();
        }

        // Temporary sync logic for legacy data migration
        await syncActivityLogFromEntries(database);

        await runBackgroundThumbnailMigration(database, concurrency: 3);
        await runCleanupIfNeeded(db: database, prefs: prefs);
        await BackupService.cleanupCache();
        Logger.info('Bootstrap: Deferred tasks completed successfully.');
      } catch (e, stack) {
        Logger.error('Bootstrap: Error during deferred tasks.', e, stack);
      }
    });

    // 6. Remove Splash Screen once the UI is stable
    Future.delayed(const Duration(milliseconds: 200), () {
      FlutterNativeSplash.remove();
    });

  }, (error, stack) {
    // Catch any errors that occur outside the Flutter context (Zone errors)
    Logger.error('Global: Uncaught error in runZonedGuarded.', error, stack);
  });
}

/// The root widget of the application.
///
/// Configures global application settings including:
/// - Routing (via [MainWrapper] or [OnboardingScreen])
/// - Theming (Light/Dark mode)
/// - Localization
/// - Authentication state wrapping
class KronoApp extends ConsumerWidget {
  /// Indicates whether the user has previously completed the onboarding flow.
  final bool onboardingCompleted;

  /// Creates the root application widget.
  const KronoApp({
    super.key,
    required this.onboardingCompleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currentLocale = ref.watch(localeProvider);
    final analytics = FirebaseAnalytics.instance;

    return MaterialApp(
      title: 'Krono',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.createLightTheme(accentColor),
      darkTheme: AppTheme.createDarkTheme(accentColor),
      themeMode: themeMode,
      // Determine the initial screen based on onboarding status
      home: onboardingCompleted
          ? const AuthWrapper(child: MainWrapper())
          : const OnboardingScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}