import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krono/src/features/journal/presentation/add_entry_screen.dart';
import 'package:krono/src/features/journal/data/journal_repository.dart';
import 'package:krono/src/core/database/database.dart';
import 'package:krono/src/core/utils/weather_service.dart';
import 'package:krono/src/features/settings/providers/locale_provider.dart';
import 'package:krono/src/features/settings/providers/theme_provider.dart';
import 'package:krono/l10n/app_localizations.dart';

@GenerateMocks([JournalRepository, AppDatabase, WeatherService, SharedPreferences])
import 'add_entry_screen_test.mocks.dart';

class FakeGeolocator extends GeolocatorPlatform {
  @override Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;
  @override Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;
  @override Future<bool> isLocationServiceEnabled() async => true;
  @override Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
  }
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override Locale build() => const Locale('en');
}

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;

    mockPrefs = MockSharedPreferences();
    GeolocatorPlatform.instance = FakeGeolocator();
    when(mockPrefs.getBool(any)).thenReturn(false);
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.getInt(any)).thenReturn(null);
  });

  Widget createWidget() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(mockPrefs),
      localeProvider.overrideWith(() => FakeLocaleNotifier()),
      weatherServiceProvider.overrideWithValue(MockWeatherService()),
      journalRepositoryProvider.overrideWithValue(MockJournalRepository()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: AddEntryScreen(),
    ),
  );

  group('AddEntryScreen Production Tests', () {
    testWidgets('Metadata loading state', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      final locationIcon = find.byIcon(Icons.location_on_rounded);
      await tester.ensureVisible(locationIcon);
      await tester.tap(locationIcon);

      await tester.pump(const Duration(milliseconds: 10));

      // ✅ FIX: Expect 2 spinners because both cards enter loading state
      expect(find.byType(CircularProgressIndicator), findsNWidgets(2));

      await tester.pumpAndSettle();
    });
  });
}