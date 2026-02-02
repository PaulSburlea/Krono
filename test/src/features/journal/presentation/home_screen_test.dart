import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:krono/src/features/journal/presentation/home_screen.dart';
import 'package:krono/src/features/journal/data/models/journal_entry.dart';
import 'package:krono/src/core/providers/streak_provider.dart';
import 'package:krono/src/features/settings/providers/theme_provider.dart';
import 'package:krono/src/features/journal/data/sources/quote_service.dart';
import 'package:krono/src/features/journal/domain/models/quote.dart';
import 'package:krono/l10n/app_localizations.dart';

@GenerateMocks([QuoteService, SharedPreferences])
import 'home_screen_test.mocks.dart';

void main() {
  late MockSharedPreferences mockPrefs;
  late Directory testDir;

  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 2400);

    mockPrefs = MockSharedPreferences();
    testDir = await Directory.systemTemp.createTemp('home_test');
    when(mockPrefs.getBool(any)).thenReturn(false);
    when(mockPrefs.getString(any)).thenReturn(null);
    when(mockPrefs.getInt(any)).thenReturn(null);
  });

  tearDown(() => testDir.deleteSync(recursive: true));

  Widget createWidget(List<JournalEntry> entries) => ProviderScope(
    overrides: [
      journalStreamProvider.overrideWith((ref) => Stream.value(entries)),
      quoteProvider.overrideWithValue(const AsyncValue.data(Quote(text: 'Hi', author: 'Me'))),
      streakProvider.overrideWithValue(StreakState.initial()),
      sharedPreferencesProvider.overrideWithValue(mockPrefs),
      themeNotifierProvider.overrideWith(() => ThemeNotifier()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: HomeScreen(),
    ),
  );

  group('HomeScreen Tests', () {
    testWidgets('Empty state check', (tester) async {
      await tester.pumpWidget(createWidget([]));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.auto_stories_rounded), findsOneWidget);
    });

    testWidgets('Grid render check', (tester) async {
      final file = File('${testDir.path}/p.jpg')..createSync();
      final entry = JournalEntry(id: 1, date: DateTime.now(), photoPath: file.path, moodRating: 5);
      await tester.pumpWidget(createWidget([entry]));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('🤩'), findsOneWidget);
    });

    testWidgets('Scroll back to top button', (tester) async {
      final file = File('${testDir.path}/p.jpg')..createSync();
      final entries = List.generate(20, (i) => JournalEntry(id: i, date: DateTime.now().subtract(Duration(days: i)), photoPath: file.path, moodRating: 3));
      await tester.pumpWidget(createWidget(entries));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });
}