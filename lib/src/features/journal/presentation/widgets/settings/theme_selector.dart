import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/theme_provider.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentAccent = ref.watch(accentColorProvider);

    final List<Map<String, dynamic>> themes = [
      {'name': l10n.themeKrono, 'color': const Color(0xFF6366F1)},
      {'name': l10n.themeEmerald, 'color': Colors.teal},
      {'name': l10n.themeOcean, 'color': Colors.blue},
      {'name': l10n.themeSunset, 'color': Colors.orange},
      {'name': l10n.themeBerry, 'color': Colors.pink},
      {'name': l10n.themeMidnight, 'color': Colors.deepPurple},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const Gap(24),
          Text(l10n.chooseTheme, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const Gap(32),
          Wrap(
            spacing: 24, runSpacing: 24,
            alignment: WrapAlignment.center,
            children: themes.map((theme) {
              final isSelected = currentAccent == theme['color'];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(accentColorProvider.notifier).setAccentColor(theme['color']);
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme['color'],
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 30) : null,
                    ),
                    const Gap(8),
                    Text(theme['name'],
                        style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              );
            }).toList(),
          ),
          const Gap(24),
        ],
      ),
    );
  }
}