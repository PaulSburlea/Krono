import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../settings/providers/locale_provider.dart';
import '../../../settings/providers/theme_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../../../l10n/app_localizations.dart';

/// A professional bottom sheet widget that allows the user to select the application language.
///
/// This widget is designed to be displayed within a modal bottom sheet. It lists
/// the supported languages and updates the global [localeProvider] upon selection.
/// It follows the same design pattern as the theme selector for a cohesive user experience.
class LanguageSelector extends ConsumerWidget {
  /// Creates a [LanguageSelector] instance.
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final accentColor = ref.watch(accentColorProvider);

    // Definition of supported languages.
    // In a global scale app, this list could come from a config file or remote config.
    final List<_LanguageModel> languages = [
      _LanguageModel(name: "English", flag: "🇺🇸", locale: const Locale('en')),
      _LanguageModel(name: "Română", flag: "🇷🇴", locale: const Locale('ro')),
      _LanguageModel(name: "Français", flag: "🇫🇷", locale: const Locale('fr')),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sheet Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Gap(24),
          Text(
            l10n.chooseLanguage,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(24),

          // List of languages wrapped in a flexible container to handle layout constraints.
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: languages.length,
              separatorBuilder: (context, index) => const Gap(8),
              itemBuilder: (context, index) {
                final lang = languages[index];
                final isSelected =
                    currentLocale.languageCode == lang.locale.languageCode;

                return _LanguageTile(
                  lang: lang,
                  isSelected: isSelected,
                  accentColor: accentColor,
                  onTap: () {
                    Logger.info(
                        'User selected language: ${lang.name} (${lang.locale.languageCode})');
                    HapticFeedback.lightImpact();
                    ref.read(localeProvider.notifier).setLocale(lang.locale);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized visual component for displaying a single language option.
///
/// Renders the flag, language name, and a selection indicator if active.
class _LanguageTile extends StatelessWidget {
  /// The data model containing language details.
  final _LanguageModel lang;

  /// Whether this language is currently active.
  final bool isSelected;

  /// The application's current accent color, used for highlighting.
  final Color accentColor;

  /// Callback triggered when the user taps this tile.
  final VoidCallback onTap;

  const _LanguageTile({
    required this.lang,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? accentColor.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              lang.flag,
              style: const TextStyle(fontSize: 28),
            ),
            const Gap(16),
            Expanded(
              child: Text(
                lang.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.textTheme.bodyLarge?.color,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

/// A private data model representing a supported language.
class _LanguageModel {
  final String name;
  final String flag;
  final Locale locale;

  _LanguageModel({
    required this.name,
    required this.flag,
    required this.locale,
  });
}