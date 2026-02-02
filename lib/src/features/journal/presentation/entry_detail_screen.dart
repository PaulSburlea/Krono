import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import 'package:gap/gap.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/utils/logger_service.dart';
import '../data/journal_repository.dart';
import '../data/models/journal_entry.dart';
import 'add_entry_screen.dart';

/// A screen that displays the full details of a single [JournalEntry].
///
/// This screen provides a rich view of the entry's photo, mood, metadata, and note.
/// It also offers actions to edit, delete, or export the entry's photo.
class EntryDetailScreen extends ConsumerWidget {
  /// The journal entry to be displayed.
  final JournalEntry entry;

  /// Creates the detail screen for a journal entry.
  const EntryDetailScreen({super.key, required this.entry});

  /// Navigates to a full-screen, interactive viewer for the entry's photo.
  void _showFullScreenImage(BuildContext context) {
    Logger.info('Showing full-screen image for entry ID: ${entry.id}');
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => _FullScreenImageViewer(entry: entry),
      ),
    );
  }

  /// Saves the entry's photo to the device's native photo gallery.
  ///
  /// Shows a success or error [SnackBar] upon completion.
  Future<void> _saveToGallery(BuildContext context, AppLocalizations l10n) async {
    Logger.info('Attempting to save image to gallery for entry ID: ${entry.id}');
    try {
      await Gal.putImage(entry.photoPath);
      Logger.info('Successfully saved image to gallery for entry ID: ${entry.id}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.saveGallerySuccess),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e, stack) {
      Logger.error('Failed to save image to gallery.', e, stack);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorExport(e.toString()))),
        );
      }
    }
  }

  /// Displays a confirmation dialog before permanently deleting the journal entry.
  void _showDeleteDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    Logger.info('Delete dialog opened for entry ID: ${entry.id}');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.deleteEntryTitle),
        content: Text(l10n.deleteEntryDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () async {
              Logger.info('User confirmed deletion for entry ID: ${entry.id}');
              try {
                await ref.read(journalRepositoryProvider).deleteEntry(entry);
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back from detail screen
                }
              } catch (e, stack) {
                Logger.error('Failed to delete entry ID: ${entry.id}', e, stack);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Could not delete entry.')),
                  );
                }
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Logger.info('Building EntryDetailScreen for entry ID: ${entry.id}');
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    final rawDate = DateFormat('EEEE, d MMMM yyyy', locale).format(entry.date);
    final formattedDate = rawDate[0].toUpperCase() + rawDate.substring(1);
    final formattedTime = DateFormat('HH:mm', locale).format(entry.date);
    final bool showTime = entry.date.hour != 0 || entry.date.minute != 0;

    final double systemBottomPadding = MediaQuery.of(context).padding.bottom;
    final double bottomContentPadding = systemBottomPadding > 0
        ? systemBottomPadding + 24
        : 40.0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _AppBarCircleAction(child: const BackButton(color: Colors.white)),
        actions: [
          _AppBarCircleAction(
            child: IconButton(
              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
              onPressed: () => _saveToGallery(context, l10n),
            ),
          ),
          _AppBarCircleAction(
            child: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 20),
              onPressed: () async {
                Logger.info('Navigating to edit screen for entry ID: ${entry.id}');
                final bool? refresh = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEntryScreen(entry: entry)),
                );
                if (refresh == true && context.mounted) Navigator.pop(context);
              },
            ),
          ),
          _AppBarCircleAction(
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
              onPressed: () => _showDeleteDialog(context, l10n, ref),
            ),
          ),
          const Gap(8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ParallaxHeader(
              entry: entry,
              dateText: formattedDate,
              timeText: showTime ? formattedTime : null,
              onTap: () => _showFullScreenImage(context),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomContentPadding),
              child: Column(
                children: [
                  _MoodCard(entry: entry, l10n: l10n),
                  const Gap(16),
                  _MetadataRow(entry: entry),
                  const Gap(32),
                  _NoteContainer(entry: entry, l10n: l10n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A private widget that wraps an action icon in a semi-transparent circular background.
class _AppBarCircleAction extends StatelessWidget {
  /// The child widget, typically an [IconButton].
  final Widget child;

  /// Creates a styled circular action for the app bar.
  const _AppBarCircleAction({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.2),
        child: child,
      ),
    );
  }
}

/// The main header widget displaying the entry's photo with a parallax-like effect.
///
/// It includes an optimized image loading strategy that shows a low-resolution
/// thumbnail instantly while the high-resolution image fades in.
class _ParallaxHeader extends StatelessWidget {
  /// The entry containing the photo to display.
  final JournalEntry entry;
  /// The formatted date string to overlay on the image.
  final String dateText;
  /// The optional formatted time string to overlay on the image.
  final String? timeText;
  /// The callback executed when the header is tapped.
  final VoidCallback onTap;

  /// Creates the parallax header.
  const _ParallaxHeader({
    required this.entry,
    required this.dateText,
    this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final int screenWidth = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round();

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Hero(
            tag: 'photo_${entry.id}',
            child: Container(
              height: MediaQuery.of(context).size.height * 0.48,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                color: Colors.black12,
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                child: Image.file(
                  File(entry.photoPath),
                  fit: BoxFit.cover,
                  cacheWidth: screenWidth,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (entry.thumbnailPath != null && entry.thumbnailPath!.isNotEmpty)
                          Image.file(
                            File(entry.thumbnailPath!),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          child: child,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                  ),
                ),
                if (timeText != null) ...[
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(Icons.access_time_filled_rounded, color: Colors.white70, size: 14),
                      const Gap(6),
                      Text(
                        timeText!,
                        style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that displays the mood rating of the entry with a corresponding emoji.
class _MoodCard extends StatelessWidget {
  /// The entry from which to derive the mood.
  final JournalEntry entry;
  /// The localization instance for displaying labels.
  final AppLocalizations l10n;

  /// Creates a card for displaying the mood.
  const _MoodCard({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emojis = ['😢', '🙁', '😐', '🙂', '🤩'];
    final emoji = emojis[entry.moodRating.clamp(1, 5) - 1];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.moodLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.myMood,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A row that conditionally displays metadata cards for location and weather.
class _MetadataRow extends StatelessWidget {
  /// The entry containing the metadata to display.
  final JournalEntry entry;

  /// Creates a row for displaying metadata.
  const _MetadataRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.location == null && entry.weatherTemp == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (entry.location != null)
          Expanded(child: _AutoMarqueeCard(icon: Icons.location_on_rounded, text: entry.location!)),
        if (entry.location != null && entry.weatherTemp != null) const Gap(8),
        if (entry.weatherTemp != null)
          Expanded(child: _AutoMarqueeCard(
            icon: Icons.wb_cloudy_rounded,
            text: entry.weatherTemp!,
            weatherIcon: entry.weatherIcon,
          )),
      ],
    );
  }
}

/// A styled container that displays the user's note for the journal entry.
class _NoteContainer extends StatelessWidget {
  /// The entry containing the note to display.
  final JournalEntry entry;
  /// The localization instance for labels and fallbacks.
  final AppLocalizations l10n;

  /// Creates a container for the journal note.
  const _NoteContainer({required this.entry, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: theme.colorScheme.primary),
              const Gap(12),
              Text(
                l10n.journal.toUpperCase(),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          Text(
            entry.note ?? l10n.noNote,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.7,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-screen, zoomable viewer for the entry's photo.
class _FullScreenImageViewer extends StatelessWidget {
  /// The entry whose photo will be displayed.
  final JournalEntry entry;

  /// Creates a full-screen image viewer.
  const _FullScreenImageViewer({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const CloseButton(color: Colors.white),
      ),
      body: SizedBox.expand(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: 'photo_${entry.id}',
            child: Image.file(File(entry.photoPath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

/// A card with auto-scrolling text, used for displaying potentially long metadata.
class _AutoMarqueeCard extends StatefulWidget {
  /// The icon to display next to the text.
  final IconData icon;
  /// The text content to display and scroll.
  final String text;
  /// An optional weather icon URL to display instead of the default icon.
  final String? weatherIcon;

  /// Creates a card with auto-scrolling text.
  const _AutoMarqueeCard({required this.icon, required this.text, this.weatherIcon});

  @override
  State<_AutoMarqueeCard> createState() => _AutoMarqueeCardState();
}

class _AutoMarqueeCardState extends State<_AutoMarqueeCard> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  /// Initiates the periodic scrolling animation if the text overflows.
  void _startScrolling() {
    if (!mounted || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(maxScroll, duration: Duration(milliseconds: maxScroll.toInt() * 65), curve: Curves.linear);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(0, duration: const Duration(milliseconds: 1000), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          if (widget.weatherIcon != null)
            Image.network('https://openweathermap.org/img/wn/${widget.weatherIcon}.png', width: 28, height: 28)
          else
            Icon(widget.icon, size: 18, color: theme.colorScheme.primary),
          const Gap(10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}