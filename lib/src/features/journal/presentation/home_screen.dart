import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/database.dart';
import '../../../core/providers/streak_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';

import '../data/journal_repository.dart';
import 'add_entry_screen.dart';
import 'widgets/journal_grid.dart';
import 'widgets/quote_card.dart';
import 'widgets/streak_card.dart';

final journalStreamProvider = StreamProvider<List<DayEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.dayEntries)
    ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]))
      .watch();
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    _scrollController.addListener(() {
      if (_scrollController.offset > 400 && !_showBackToTop) {
        setState(() => _showBackToTop = true);
      } else if (_scrollController.offset <= 400 && _showBackToTop) {
        setState(() => _showBackToTop = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    HapticFeedback.mediumImpact();
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final journalAsync = ref.watch(journalStreamProvider);
    final themeMode = ref.watch(themeNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final streakState = ref.watch(streakProvider);

    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: AnimatedScale(
          scale: _showBackToTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutBack,
          child: FloatingActionButton(
            onPressed: _scrollToTop,
            backgroundColor: Theme.of(context).colorScheme.primary,
            elevation: 6,
            shape: const CircleBorder(),
            mini: true,
            child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StaticHeaderDelegate(
              streakCount: streakState.count,
              activeDates: streakState.history,
              themeMode: themeMode,
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SizedBox(height: 155, width: double.infinity, child: QuoteCard()),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 12),
              // ✅ MODIFICARE: Folosim variabila l10n
              child: Text(l10n.yourMemories, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
          ),
          journalAsync.when(
            data: (entries) => entries.isEmpty
            // ✅ MODIFICARE: Empty State frumos cu SliverFillRemaining
                ? SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(context, l10n),
            )
                : JournalGrid(entries: entries),
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text(l10n.loadingError)),
            ),
          ),
          const SliverGap(120),
        ],
      ),
    );
  }

  // Widget pentru starea goală (Empty State)
  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_rounded, size: 64, color: colorScheme.secondary),
          ),
          const Gap(24),
          Text(
            l10n.emptyJournalTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            l10n.emptyJournalMessage,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          FilledButton.icon(
            onPressed: () {
              // Navigăm direct la adăugare pentru ziua de azi
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEntryScreen(initialDate: null)),
              );
            },
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.createMemory),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const Gap(40), // Pentru a nu fi lipit de jos
        ],
      ),
    );
  }
}

// ✅ Delegatul cu UX îmbunătățit (Umbră la scroll)
class _StaticHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int streakCount;
  final List<DateTime> activeDates;
  final ThemeMode themeMode;

  _StaticHeaderDelegate({
    required this.streakCount,
    required this.activeDates,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Detectăm dacă utilizatorul a scrollat
    final isScrolled = shrinkOffset > 0 || overlapsContent;

    return Consumer(
      builder: (context, ref, child) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(isScrolled ? 0.98 : 1.0),
          // ✅ UX: Adăugăm umbră subtilă doar când e scrollat, în loc de border simplu
          boxShadow: isScrolled
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
              : null,
        ),
        padding: const EdgeInsets.only(top: 60, left: 24, right: 16, bottom: 8),
        child: Row(
          children: [
            const Text('Krono',
                style: TextStyle(
                    fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1.2)),
            const Spacer(),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(themeNotifierProvider.notifier).toggleTheme();
              },
              icon: Icon(
                  themeMode == ThemeMode.light
                      ? Icons.wb_sunny_rounded
                      : Icons.nightlight_round,
                  color: themeMode == ThemeMode.light
                      ? Colors.orangeAccent
                      : Colors.indigoAccent[100]),
            ),
            StreakCard(streak: streakCount, activeDates: activeDates),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 115;
  @override
  double get minExtent => 115;
  @override
  bool shouldRebuild(covariant _StaticHeaderDelegate oldDelegate) => true;
}