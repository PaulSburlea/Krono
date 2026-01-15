import 'package:Krono/src/features/journal/data/journal_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'l10n/app_localizations.dart';
import 'src/core/database/database.dart';
import 'src/features/journal/presentation/main_wrapper.dart';
import 'src/core/providers/theme_provider.dart';
import 'src/core/providers/locale_provider.dart';
import 'src/core/utils/auth_wrapper.dart';
import 'src/core/utils/notification_service.dart';

Future<void> initializeAllDateFormatting() async {
  final locales = ['ro', 'en', 'fr'];
  for (var locale in locales) {
    await initializeDateFormatting(locale, null);
  }
}

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    NotificationService.init(),
    initializeAllDateFormatting(),
  ]);

  final prefs = results[0] as SharedPreferences;

  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        databaseProvider.overrideWithValue(database),
      ],
      child: const KronoApp(),
    ),
  );

  Future.delayed(const Duration(milliseconds: 400), () {
    FlutterNativeSplash.remove();
  });
}

class KronoApp extends ConsumerWidget {
  const KronoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider);
    final accentColor = ref.watch(accentColorProvider);
    final currentLocale = ref.watch(localeProvider);

    ThemeData createTheme(Brightness brightness) {
      return ThemeData(
        useMaterial3: true,
        colorSchemeSeed: accentColor,
        brightness: brightness,
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      );
    }

    return MaterialApp(
      title: 'Krono',
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: createTheme(Brightness.light),
      darkTheme: createTheme(Brightness.dark),
      themeMode: themeMode,
      home: const AuthWrapper(
        child: MainWrapper(),
      ),
    );
  }
}