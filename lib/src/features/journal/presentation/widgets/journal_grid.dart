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
  /// This method groups the provided [entries] by month. It ensures the current
  /// month is always displayed as the first section, even if it contains no entries.
  ///
  /// [now] is passed from the parent to ensure reactive updates at midnight.
  static List<Widget> sliversFor(
      List<JournalEntry> entries,
      BuildContext context,
      DateTime now
      ) {
    Logger.info('Generating journal grid slivers for ${entries.length} entries.');
    final width = MediaQuery.of(context).size.width;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final int itemCacheSize = ((width - 40 - 16) / 3 * dpr).round();

    final sections = _groupOptimized(entries, now);

    final children = <Widget>[];

    for (final section in sections) {
      final bool isCurrentMonth = section.year == now.year && section.month == now.month;
      // For the current month, we only show days up to today.
      // For past months, we show all days in that month.
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
                // Iterate backwards from the latest day to the first day of the month.
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

  /// Groups entries by month and ensures the current month is always present.
  static List<_MonthData> _groupOptimized(List<JournalEntry> entries, DateTime now) {
    final map = <int, _MonthData>{};

    // Explicitly initialize the current month to ensure it appears even if empty.
    final currentMonthKey = now.year * 100 + now.month;
    map[currentMonthKey] = _MonthData(year: now.year, month: now.month);

    for (final e in entries) {
      final key = e.date.year * 100 + e.date.month;
      final monthData = map.putIfAbsent(key, () => _MonthData(year: e.date.year, month: e.date.month));
      monthData.add(e);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return sortedKeys.map((k) => map[k]!).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Fallback for standalone usage, though typically sliversFor is called directly.
    return CustomScrollView(slivers: sliversFor(entries, context, DateTime.now()));
  }
}

/// Helper class to manage journal entries for a specific month.
class _MonthData {
  final int year;
  final int month;
  final Map<int, List<JournalEntry>> days = {};

  _MonthData({required this.year, required this.month});

  void add(JournalEntry e) {
    days.putIfAbsent(e.date.day, () => []).add(e);
  }

  /// Returns the number of days in the month, correctly handling leap years.
  int get daysInMonth => DateUtils.getDaysInMonth(year, month);

  int get total => days.values.fold(0, (s, l) => s + l.length);
}

/// Header widget for month sections.
class _MonthHeader extends StatelessWidget {
  final String title;
  final int count;
  final String memoriesLabel;

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