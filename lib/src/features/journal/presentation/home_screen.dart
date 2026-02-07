import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/database.dart';
import '../../../core/providers/streak_provider.dart';
import '../../../core/providers/date_provider.dart'; // Import the new provider
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/logger_service.dart';
import '../../../../l10n/app_localizations.dart';

import '../data/models/journal_entry.dart';
import 'add_entry_screen.dart';
import 'widgets/journal_grid.dart';
import 'widgets/quote_card.dart';
import 'widgets/streak_card.dart';

/// Provides a real-time stream of all [JournalEntry] items from the database.
final journalStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.dayEntries)
    ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]);

  return query.watch().map((rows) => rows.map((row) => JournalEntry.fromDrift(row)).toList());
});

/// The main screen of the application.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final ScrollController _scrollController;
  final ValueNotifier<bool> _showBackToTopNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    final bool shouldShow = _scrollController.offset > 400;
    if (shouldShow != _showBackToTopNotifier.value) {
      _showBackToTopNotifier.value = shouldShow;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _showBackToTopNotifier.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    Logger.info('User tapped "Back to Top" button.');
    HapticFeedback.mediumImpact();
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 600), curve: Curves.fastOutSlowIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final journalAsync = ref.watch(journalStreamProvider);
    final l10n = AppLocalizations.of(context)!;
    final streakState = ref.watch(streakProvider);

    // Watch the current date. This triggers a rebuild at midnight.
    final now = ref.watch(currentDateProvider);

    final double topPadding = MediaQuery.paddingOf(context).top;
    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    const double dockHeight = 72.0;
    final double dockBottomMargin = systemBottomPadding > 0 ? systemBottomPadding + 20 : 24.0;
    final double dockTopEdge = dockHeight + dockBottomMargin;
    final double fabPadding = (dockTopEdge + 16.0) - systemBottomPadding;
    final double contentBottomPadding = dockTopEdge + 24.0;

    return Scaffold(
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _showBackToTopNotifier,
        builder: (context, visible, _) {
          return _BackToTopButton(isVisible: visible, onPressed: _scrollToTop, bottomOffset: fabPadding);
        },
      ),
      body: journalAsync.when(
        loading: () => _buildLoadingShimmer(),
        data: (entries) {
          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  streakCount: streakState.count,
                  activeDates: streakState.activeDates,
                  topPadding: topPadding,
                  onToggleTheme: () {
                    Logger.info('User toggled theme.');
                    HapticFeedback.selectionClick();
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: QuoteCard(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Text(
                    l10n.yourMemories,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
              ),
              if (entries.isEmpty)
                SliverFillRemaining(hasScrollBody: false, child: _EmptyJournalState(l10n: l10n))
              else
              // Pass the reactive 'now' date to the grid
                ...JournalGrid.sliversFor(entries, context, now),
              SliverGap(contentBottomPadding),
            ],
          );
        },
        error: (err, st) {
          Logger.error('Failed to load journal stream.', err, st);
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  streakCount: streakState.count,
                  activeDates: streakState.activeDates,
                  topPadding: topPadding,
                  onToggleTheme: () {
                    Logger.info('User toggled theme.');
                    HapticFeedback.selectionClick();
                    ref.read(themeNotifierProvider.notifier).toggleTheme();
                  },
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      const Gap(16),
                      Text(l10n.loadingError),
                      const Gap(16),
                      ElevatedButton(
                          onPressed: () {
                            Logger.info('User tapped "Retry" on journal stream error.');
                            final _ = ref.refresh(journalStreamProvider);
                          },
                          child: Text(l10n.retry)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 6,
      padding: const EdgeInsets.all(20),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 20, width: 150, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4))),
            const Gap(16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: 9,
              itemBuilder: (context, idx) => Container(decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12))),
            ),
          ]),
        );
      },
    );
  }
}

class _BackToTopButton extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onPressed;
  final double bottomOffset;

  const _BackToTopButton({required this.isVisible, required this.onPressed, required this.bottomOffset});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomOffset),
        child: FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
        ),
      ),
    );
  }
}

class _EmptyJournalState extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyJournalState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(28), decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3), shape: BoxShape.circle), child: Icon(Icons.auto_stories_rounded, size: 64, color: colorScheme.secondary)),
        const Gap(24),
        Text(l10n.emptyJournalTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
        const Gap(8),
        Text(l10n.emptyJournalMessage, style: TextStyle(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
        const Gap(32),
        FilledButton.icon(
          onPressed: () {
            Logger.info('User tapped "Create Memory" from empty state.');
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEntryScreen()));
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.createMemory),
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        ),
      ]),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final int streakCount;
  final List<DateTime> activeDates;
  final double topPadding;
  final VoidCallback onToggleTheme;

  _HeaderDelegate({
    required this.streakCount,
    required this.activeDates,
    required this.topPadding,
    required this.onToggleTheme,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final bool isScrolled = shrinkOffset > 0 || overlapsContent;

    return Consumer(
      builder: (context, ref, _) {
        final themeMode = ref.watch(themeNotifierProvider);
        final theme = Theme.of(context);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: maxExtent,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: isScrolled ? 0.95 : 1.0),
            boxShadow: isScrolled
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          // ✅ FIX: Folosește SafeArea pentru a gestiona automat topPadding
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 16, bottom: 8, top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Krono',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                      fontSize: 32,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onToggleTheme,
                    icon: Icon(
                      themeMode == ThemeMode.light ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: themeMode == ThemeMode.light ? Colors.orange : Colors.indigo[200],
                    ),
                  ),
                  StreakCard(streak: streakCount, activeDates: activeDates),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ FIX: Înălțimea corectată - doar conținutul vizibil (60px) fără topPadding duplicat
  @override
  double get maxExtent => 60.0 + topPadding;

  @override
  double get minExtent => 60.0 + topPadding;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return oldDelegate.streakCount != streakCount ||
        oldDelegate.topPadding != topPadding ||
        !listEquals(oldDelegate.activeDates, activeDates);
  }
}