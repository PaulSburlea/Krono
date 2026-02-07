import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
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
import 'src/features/onboarding/presentation/onboarding_screen.dart';
import 'src/core/utils/thumbnail/thumbnail_migration.dart';

/// Initializes locale date formatting data for supported languages.
Future<void> _initializeDateFormatting() async {
  final locales = ['ro', 'en', 'fr'];
  await Future.wait(locales.map((locale) => initializeDateFormatting(locale, null)));
}

/// The application entry point.
void main() async {
  runZonedGuarded<Future<void>>(() async {
    // 1. Minimal initialization
    final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

    // Note: Orientation lock should be handled natively in AndroidManifest.xml
    // and Info.plist to avoid the async delay here.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 2. Load only critical resources required for the first frame
    Logger.info('Bootstrap: Initializing critical resources...');
    final initResults = await Future.wait([
      SharedPreferences.getInstance(),
      Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
      _initializeDateFormatting(),
    ]);

    final prefs = initResults[0] as SharedPreferences;

    // 3. Configure global error tracking
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // 4. Instantiate core services (Synchronous or non-blocking)
    final database = AppDatabase();
    final notificationService = NotificationService(FlutterLocalNotificationsPlugin());

    // Optimize Image Cache
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100 MB

    final bool onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // 5. Launch the application immediately
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

    // 6. Remove Splash Screen as soon as the app is attached
    FlutterNativeSplash.remove();

    // 7. Deferred Tasks (Non-critical for first frame)
    Future.microtask(() async {
      Logger.info('Bootstrap: Starting deferred background tasks.');
      try {
        // Initialize notifications in the background
        await notificationService.init();

        if (FirebaseAuth.instance.currentUser == null) {
          await FirebaseAuth.instance.signInAnonymously();
        }

        await syncActivityLogFromEntries(database);
        await runBackgroundThumbnailMigration(database, concurrency: 3);
        await runCleanupIfNeeded(db: database, prefs: prefs);
        await BackupService.cleanupCache();

        Logger.info('Bootstrap: Deferred tasks completed.');
      } catch (e, stack) {
        Logger.error('Bootstrap: Error during deferred tasks.', e, stack);
      }
    });

  }, (error, stack) {
    Logger.error('Global: Uncaught error in runZonedGuarded.', error, stack);
  });
}

/// The root widget of the application.
class KronoApp extends ConsumerWidget {
  final bool onboardingCompleted;

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
      home: onboardingCompleted
          ? const AuthWrapper(child: MainWrapper())
          : const OnboardingScreen(),
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: analytics),
      ],
    );
  }
}