import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/locale_provider.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          const Gap(24),
          Text(l10n.chooseLanguage, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(24),
          _langTile(ref, "English", "🇺🇸", const Locale('en'), currentLocale),
          _langTile(ref, "Română", "🇷🇴", const Locale('ro'), currentLocale),
          _langTile(ref, "Français", "🇫🇷", const Locale('fr'), currentLocale),
          const Gap(16),
        ],
      ),
    );
  }

  Widget _langTile(WidgetRef ref, String name, String flag, Locale locale, Locale current) {
    final selected = current.languageCode == locale.languageCode;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected ? const Icon(Icons.check_circle, color: Colors.green) : null,
      onTap: () {
        ref.read(localeProvider.notifier).setLocale(locale);
        Navigator.pop(ref.context); // Sau Navigator.of(context).pop()
      },
    );
  }
}