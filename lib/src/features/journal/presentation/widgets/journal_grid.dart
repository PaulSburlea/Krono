import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/database.dart';
import '../add_entry_screen.dart';
import '../entry_detail_screen.dart';
import 'journal_item_card.dart';

class JournalGrid extends StatelessWidget {
  final List<DayEntry> entries;

  JournalGrid({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;
    final Map<String, Map<int, List<DayEntry>>> organizedEntries = {};

    for (var entry in entries) {
      String monthKey = DateFormat('MMMM yyyy', locale).format(entry.date);
      organizedEntries.putIfAbsent(monthKey, () => {});
      organizedEntries[monthKey]!.putIfAbsent(entry.date.day, () => []).add(entry);
    }

    final monthKeys = organizedEntries.keys.toList();
    final now = DateTime.now();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final monthKey = monthKeys[index];
          final daysWithData = organizedEntries[monthKey]!;
          int totalEntriesInMonth = daysWithData.values.fold(0, (sum, list) => sum + list.length);

          final firstEntryInMonth = daysWithData.values.isNotEmpty
              ? daysWithData.values.first.first.date
              : now;

          final dateInMonth = DateTime(firstEntryInMonth.year, firstEntryInMonth.month);
          int lastDay = DateUtils.getDaysInMonth(dateInMonth.year, dateInMonth.month);

          int daysToShow = (dateInMonth.year == now.year && dateInMonth.month == now.month)
              ? now.day
              : lastDay;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEnhancedMonthHeader(context, monthKey, totalEntriesInMonth),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8, // ✅ 8px = Spațiere perfectă, modernă
                    mainAxisSpacing: 8,  // ✅ 8px
                    childAspectRatio: 0.85, // Ușor portret (standard gallery)
                  ),
                  itemCount: daysToShow,
                  itemBuilder: (context, dayIndex) {
                    int dayNum = daysToShow - dayIndex;
                    DateTime currentDay = DateTime(dateInMonth.year, dateInMonth.month, dayNum);
                    final dayEntries = daysWithData[dayNum] ?? [];

                    return GestureDetector(
                      onTap: () => _handleDayTap(context, currentDay, dayEntries),
                      child: JournalItemCard(
                        date: currentDay,
                        dayEntries: dayEntries,
                      ),
                    );
                  },
                ),
              ),
              const Gap(24), // Spațiu între luni
            ],
          );
        },
        childCount: monthKeys.length,
      ),
    );
  }

  void _handleDayTap(BuildContext context, DateTime date, List<DayEntry> entries) {
    HapticFeedback.lightImpact();
    final l10n = AppLocalizations.of(context)!;

    if (entries.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) => EntryDetailScreen(entry: entries.first)));
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (date.isAfter(today)) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.futureDateError),
              behavior: SnackBarBehavior.floating,
            )
        );
      } else {
        Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddEntryScreen(initialDate: date)));
      }
    }
  }

  Widget _buildEnhancedMonthHeader(BuildContext context, String title, int count) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final formattedTitle = title.isNotEmpty
        ? title[0].toUpperCase() + title.substring(1)
        : title;

    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 40, bottom: 20, right: 24),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                formattedTitle,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.2)
            ),
            const Gap(4),
            Text(
                l10n.memoriesCount(count),
                style: TextStyle(fontSize: 11, color: colorScheme.primary.withOpacity(0.6), fontWeight: FontWeight.w600)
            ),
          ]),
          const Gap(16),
          Expanded(child: Divider(color: colorScheme.primary.withOpacity(0.1))),
        ],
      ),
    );
  }
}