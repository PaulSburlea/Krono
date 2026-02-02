import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger_service.dart';
import '../../data/models/journal_entry.dart';
import 'journal_item_card.dart';

/// A widget that displays a list of [JournalEntry] items in a scrollable grid,
/// visually grouped and sectioned by month.
class JournalGrid extends StatelessWidget {
  /// The complete list of journal entries to be displayed.
  final List<JournalEntry> entries;

  /// Creates a grid for displaying journal entries.
  const JournalGrid({super.key, required this.entries});

  /// Generates a list of slivers for a [CustomScrollView] to display journal entries.
  ///
  /// This method groups the provided [entries] by month, creating a header for each
  /// month followed by a grid of [JournalItemCard] widgets for each day.
  /// It includes performance optimizations such as pre-calculating image cache sizes
  /// and disabling `addAutomaticKeepAlives` for smoother scrolling with large datasets.
  static List<Widget> sliversFor(List<JournalEntry> entries, BuildContext context) {
    Logger.info('Generating journal grid slivers for ${entries.length} entries.');
    final width = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    // Calculate the exact width of a column in physical pixels for image caching.
    final int itemCacheSize = ((width - 40 - 16) / 3 * dpr).round();

    final sections = _groupOptimized(entries);
    final now = DateTime.now();

    final children = <Widget>[];

    for (final section in sections) {
      final bool isCurrentMonth = section.year == now.year && section.month == now.month;
      final int daysToShow = isCurrentMonth ? now.day : section.daysInMonth;

      final String monthName = DateFormat('MMMM yyyy', Localizations.localeOf(context).languageCode)
          .format(DateTime(section.year, section.month));

      children.add(SliverToBoxAdapter(
          child: _MonthHeader(
              title: monthName,
              count: section.total,
              memoriesLabel: AppLocalizations.of(context)!.memoriesCount(section.total)
          )
      ));

      children.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final day = daysToShow - index;
                final date = DateTime(section.year, section.month, day);
                final dayEntries = section.days[day] ?? [];

                return JournalItemCard(
                    date: date,
                    dayEntries: dayEntries,
                    cacheSize: itemCacheSize
                );
              },
              childCount: daysToShow,
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: false,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
          ),
        ),
      );

      children.add(const SliverToBoxAdapter(child: Gap(24)));
    }

    children.add(const SliverToBoxAdapter(child: Gap(80)));
    return children;
  }

  /// Groups a list of [JournalEntry] items by month using an efficient integer-based key.
  ///
  /// The key is generated as `year * 100 + month` (e.g., May 2024 becomes 202405),
  /// which is faster for sorting and map lookups than string-based keys.
  /// Returns a list of [_MonthData] sorted in descending chronological order.
  static List<_MonthData> _groupOptimized(List<JournalEntry> entries) {
    final map = <int, _MonthData>{};
    for (final e in entries) {
      final key = e.date.year * 100 + e.date.month;

      final monthData = map.putIfAbsent(key, () => _MonthData(year: e.date.year, month: e.date.month));
      monthData.add(e);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => map[k]!).toList();
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(slivers: sliversFor(entries, context));
}

/// A private helper class to store and manage journal entries for a single month.
class _MonthData {
  /// The year of the month (e.g., 2024).
  final int year;
  /// The month number (1-12).
  final int month;
  /// A map where keys are days of the month and values are lists of entries for that day.
  final Map<int, List<JournalEntry>> days = {};

  /// Constructs data for a specific month.
  _MonthData({required this.year, required this.month});

  /// Adds a [JournalEntry] to the correct day within this month's data.
  void add(JournalEntry e) {
    days.putIfAbsent(e.date.day, () => []).add(e);
  }

  /// The total number of days in this specific month and year.
  int get daysInMonth => DateUtils.getDaysInMonth(year, month);
  /// The total count of all journal entries within this month.
  int get total => days.values.fold(0, (s, l) => s + l.length);
}

/// A private widget that displays a title and a subtitle for a month section.
///
/// Used as a header in the journal grid to separate entries from different months.
class _MonthHeader extends StatelessWidget {
  /// The main title, typically the month and year (e.g., "May 2024").
  final String title;
  /// The total number of entries for this month.
  final int count;
  /// The localized label describing the number of memories (e.g., "5 memories").
  final String memoriesLabel;

  /// Creates a header for a month section.
  const _MonthHeader({required this.title, required this.count, required this.memoriesLabel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedTitle = title.isNotEmpty ? title[0].toUpperCase() + title.substring(1) : title;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 16),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(formattedTitle, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, fontSize: 18)),
          const Gap(4),
          Text(memoriesLabel, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary.withAlpha(179), fontWeight: FontWeight.w600)),
        ]),
        const Gap(16),
        const Expanded(child: Divider(thickness: 1)),
      ]),
    );
  }
}