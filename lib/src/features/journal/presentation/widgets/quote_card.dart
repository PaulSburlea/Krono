import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/logger_service.dart';
import 'package:gap/gap.dart';

import '../../data/sources/quote_service.dart';

/// A card widget that displays a daily inspirational quote.
///
/// This widget listens to the [quoteProvider] to asynchronously fetch and display
/// a quote. It handles loading and error states gracefully, showing a placeholder
/// during loading and logging any errors to Crashlytics while displaying an empty space.
class QuoteCard extends ConsumerWidget {
  /// Creates a card for displaying a daily quote.
  const QuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quoteAsync = ref.watch(quoteProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return quoteAsync.when(
      data: (quote) {
        Logger.debug('Successfully loaded quote by ${quote.author}');
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 28,
                  color: colorScheme.primary.withValues(alpha: 0.7),
                ),
                const Gap(8),
                Text(
                  quote.text,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Gap(12),
                Text(
                  "- ${quote.author}",
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const _QuoteLoadingPlaceholder(),
      error: (err, stack) {
        Logger.error('Failed to load daily quote from the service.', err, stack);
        return const SizedBox.shrink();
      },
    );
  }
}

/// A private widget that displays a loading indicator placeholder.
///
/// This is shown within the [QuoteCard] while the quote is being fetched
/// by the [quoteProvider].
class _QuoteLoadingPlaceholder extends StatelessWidget {
  /// Creates the loading placeholder for the quote card.
  const _QuoteLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}