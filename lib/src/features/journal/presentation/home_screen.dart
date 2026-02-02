import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/database.dart';
import '../../../core/providers/streak_provider.dart';
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/logger_service.dart';
import '../../../../l10n/app_localizations.dart';

import '../data/models/journal_entry.dart';
import 'add_entry_screen.dart';
import 'widgets/journal_grid.dart';
import 'widgets/quote_card.dart';
import 'widgets/streak_card.dart';

/// Provides a real-time stream of all [JournalEntry] items from the database.
///
/// The entries are sorted in descending chronological order, ensuring the most
/// recent memories appear first.
final journalStreamProvider = StreamProvider<List<JournalEntry>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.dayEntries)
    ..orderBy([(t) => drift.OrderingTerm.desc(t.date)]);

  return query.watch().map((rows) => rows.map((row) => JournalEntry.fromDrift(row)).toList());
});

/// The main screen of the application, serving as the central hub for the user.
///
/// It displays a persistent header with streak information, a daily quote, and
/// a grid of all journal entries. It also handles loading, error, and empty states.
class HomeScreen extends ConsumerStatefulWidget {
  /// Creates the main home screen.
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

/// Manages the state for the [HomeScreen], primarily handling the scroll
/// controller to implement a "back to top" button.
class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// Controls the scrolling of the main content to detect scroll offset.
  late final ScrollController _scrollController;

  /// Notifies listeners when the "back to top" button should be visible.
  final ValueNotifier<bool> _showBackToTopNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  /// Listens to scroll events to toggle the visibility of the back-to-top button.
  ///
  /// The button becomes visible after scrolling down a certain threshold.
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

  /// Animates the scroll position back to the top of the page.
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
                ...JournalGrid.sliversFor(entries, context),
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
                            // Explicitly discard the result to satisfy 'unused_result' warning.
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

  /// Builds a shimmer loading placeholder widget to indicate that content is being fetched.
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

/// A small, animated Floating Action Button that appears when the user scrolls down.
///
/// Tapping it scrolls the view back to the top.
class _BackToTopButton extends StatelessWidget {
  /// Determines if the button is currently visible.
  final bool isVisible;
  /// The callback function executed when the button is pressed.
  final VoidCallback onPressed;
  /// The vertical offset from the bottom of the screen.
  final double bottomOffset;

  /// Creates a back-to-top button.
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

/// A widget displayed in the center of the screen when the journal is empty.
///
/// It provides a message and a call-to-action button to create the first entry.
class _EmptyJournalState extends StatelessWidget {
  /// The localization instance for displaying text.
  final AppLocalizations l10n;

  /// Creates the empty state widget.
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

/// A custom [SliverPersistentHeaderDelegate] for the home screen's app bar.
///
/// It displays the app title, a theme toggle button, and the [StreakCard].
/// The background becomes semi-opaque with a shadow when scrolled.
class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  /// The user's current streak count.
  final int streakCount;
  /// The list of dates with journal entries, used by the [StreakCard].
  final List<DateTime> activeDates;
  /// The height of the top safe area (status bar/notch).
  final double topPadding;
  /// The callback function to execute when the theme toggle button is pressed.
  final VoidCallback onToggleTheme;

  /// Creates the header delegate.
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
            // Standardized to use .withValues() for consistency
            color: theme.scaffoldBackgroundColor.withValues(alpha: isScrolled ? 0.95 : 1.0),
            boxShadow: isScrolled
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))]
                : null,
          ),
          padding: EdgeInsets.only(top: topPadding + 4, left: 24, right: 16, bottom: 8),
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
        );
      },
    );
  }

  /// The maximum height of the header, including safe area padding.
  @override
  double get maxExtent => 60 + topPadding;

  /// The minimum height of the header, which is the same as the max height.
  @override
  double get minExtent => 60 + topPadding;

  /// Determines if the header should rebuild when its properties change.
  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return oldDelegate.streakCount != streakCount ||
        oldDelegate.topPadding != topPadding ||
        !listEquals(oldDelegate.activeDates, activeDates);
  }
}