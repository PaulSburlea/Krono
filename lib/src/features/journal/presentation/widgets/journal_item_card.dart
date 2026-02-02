import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/utils/logger_service.dart';
import '../../data/models/journal_entry.dart';
import '../add_entry_screen.dart';
import '../entry_detail_screen.dart';

/// A cache of emoji strings corresponding to mood ratings 1 through 5.
const _emojiCache = ['😢', '🙁', '😐', '🙂', '🤩'];

/// A card representing a single day in the journal grid.
///
/// Displays a thumbnail from a [JournalEntry] if one exists for the given [date].
/// Handles user interactions such as tapping to view details or add a new entry,
/// and long-pressing to show a preview overlay. It can also display a badge
/// indicating multiple entries for a single day.
class JournalItemCard extends StatefulWidget {
  /// The specific date this card represents.
  final DateTime date;

  /// A list of all journal entries recorded for this [date].
  final List<JournalEntry> dayEntries;

  /// The target width in physical pixels for image caching, optimizing memory usage.
  final int cacheSize;

  /// Creates a card widget for a day in the journal.
  const JournalItemCard({
    super.key,
    required this.date,
    required this.dayEntries,
    required this.cacheSize,
  });

  @override
  State<JournalItemCard> createState() => _JournalItemCardState();
}

/// Manages the state for [JournalItemCard], including animations and overlay visibility.
class _JournalItemCardState extends State<JournalItemCard> {
  /// The overlay entry used to display the long-press image preview.
  OverlayEntry? _overlayEntry;

  /// Tracks the pressed state for tap-down animations.
  bool _isPressed = false;

  /// Gets the emoji for the most significant entry of the day.
  ///
  /// If multiple entries exist, it selects the one with the highest mood rating.
  /// Returns an empty string if there are no entries for the day.
  String get _currentEmoji {
    if (widget.dayEntries.isEmpty) return '';
    final mainEntry = widget.dayEntries.reduce((a, b) => a.moodRating >= b.moodRating ? a : b);
    return _getEmoji(mainEntry.moodRating);
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  /// Determines if the card's [date] is the current calendar day.
  bool get _isToday {
    final now = DateTime.now();
    return widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
  }

  /// Converts a mood rating (1-5) into its corresponding emoji representation.
  String _getEmoji(int rating) {
    final idx = rating.clamp(1, 5) - 1;
    return _emojiCache[idx];
  }

  /// Handles the tap gesture on the card, routing to the appropriate action.
  ///
  /// If the day has no entries, it navigates to the add entry screen.
  /// If it has one entry, it navigates to the detail screen.
  /// If it has multiple entries, it shows a modal to let the user choose.
  void _handleTap() {
    if (widget.dayEntries.isEmpty) {
      Logger.info('Tapped on empty day card: ${widget.date}');
      _handleEmptyDayTap();
      return;
    }
    if (widget.dayEntries.length > 1) {
      Logger.info('Tapped card with multiple entries (${widget.dayEntries.length}), showing modal.');
      _showMultipleEntriesModal();
    } else {
      final main = widget.dayEntries.first;
      Logger.info('Tapped card with single entry, navigating to detail screen for entry ID: ${main.id}');
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: main)),
      );
    }
  }

  /// Handles navigation when an empty day card is tapped.
  ///
  /// Navigates to the [AddEntryScreen]. It prevents adding entries for future dates
  /// by showing a [SnackBar].
  void _handleEmptyDayTap() {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    final l10n = AppLocalizations.of(context)!;

    if (widget.date.isAfter(todayMidnight)) {
      Logger.info('Attempted to add entry for a future date: ${widget.date}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.futureDateError), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Logger.info('Navigating to add entry screen for date: ${widget.date}');
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddEntryScreen(initialDate: widget.date)),
    );
  }

  /// Displays a modal bottom sheet with a grid of all entries for the selected day.
  ///
  /// This is triggered when a user taps a card that represents a day with more
  /// than one [JournalEntry].
  void _showMultipleEntriesModal() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final sortedEntries = List<JournalEntry>.from(widget.dayEntries)
      ..sort((a, b) => b.moodRating.compareTo(a.moodRating));
    final String rawDate = DateFormat('d MMMM', locale).format(widget.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withAlpha(140),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withAlpha(51), borderRadius: BorderRadius.circular(2))),
            const Gap(20),
            Text(l10n.memoriesFrom(rawDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const Gap(20),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.8,
                ),
                itemCount: sortedEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  return GestureDetector(
                    onTap: () {
                      Logger.info('Selected entry ID ${entry.id} from multi-entry modal.');
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailScreen(entry: entry)));
                    },
                    child: _buildModalCard(entry),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dayEntries.isEmpty) {
      return GestureDetector(onTap: _handleTap, child: _buildEmptyDay());
    }

    final mainEntry = widget.dayEntries.reduce((a, b) => a.moodRating >= b.moodRating ? a : b);

    return RepaintBoundary(
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: GestureDetector(
          onTap: _handleTap,
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onLongPressStart: (_) {
            setState(() => _isPressed = true);
            _showOverlay(context, mainEntry);
          },
          onLongPressEnd: (_) {
            setState(() => _isPressed = false);
            _hideOverlay();
          },
          onLongPressCancel: () {
            setState(() => _isPressed = false);
            _hideOverlay();
          },
          child: _buildFilledCard(mainEntry, showDate: true, showBadge: true),
        ),
      ),
    );
  }

  /// Builds the visual representation for a day with no journal entries.
  Widget _buildEmptyDay() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: _isToday ? theme.colorScheme.primary.withAlpha(20) : theme.colorScheme.surfaceContainerHighest.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        border: _isToday ? Border.all(color: theme.colorScheme.primary.withAlpha(153), width: 1.4) : null,
      ),
      child: Center(
        child: Text("${widget.date.day}", style: TextStyle(color: _isToday ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withAlpha(115), fontWeight: _isToday ? FontWeight.w800 : FontWeight.w600, fontSize: 16)),
      ),
    );
  }

  /// Builds the visual representation for a day that has at least one journal entry.
  Widget _buildFilledCard(JournalEntry entry, {bool showDate = true, bool showBadge = false}) {
    final String imagePath = (entry.thumbnailPath?.isNotEmpty == true)
        ? entry.thumbnailPath!
        : (entry.photoPath);

    if (imagePath.isEmpty) {
      Logger.warning('Journal entry ID ${entry.id} has an empty photoPath and thumbnailPath.');
      return _buildBrokenImagePlaceholder();
    }

    final imageFile = File(imagePath);
    if (!imageFile.existsSync()) {
      Logger.warning('Image file does not exist at path: $imagePath for entry ID ${entry.id}.');
      return _buildBrokenImagePlaceholder();
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(fit: StackFit.expand, children: [
        Image.file(
          imageFile,
          fit: BoxFit.cover,
          cacheWidth: widget.cacheSize,
          gaplessPlayback: true,
          isAntiAlias: true,
          filterQuality: FilterQuality.medium,
          errorBuilder: (context, error, stackTrace) {
            Logger.error(
              'Failed to decode image file for entry ID ${entry.id} at path: $imagePath',
              error,
              stackTrace!,
            );
            return _buildBrokenImagePlaceholder();
          },
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync) return child;
            return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: child
            );
          },
        ),
        if (showDate) ...[
          Positioned(bottom: 0, left: 0, right: 0, height: 56, child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withAlpha(166), Colors.transparent], stops: const [0, 0.9])))),
          Positioned(bottom: 6, right: 8, child: Text("${widget.date.day}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, shadows: [Shadow(color: Colors.black, blurRadius: 3)]))),
        ],
        Positioned(top: 6, left: 6, child: Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.black.withAlpha(115), shape: BoxShape.circle), child: Text(_currentEmoji, style: const TextStyle(fontSize: 12)))),
        if (showBadge && widget.dayEntries.length > 1)
          Positioned(
            top: 6,
            right: 6,
            child: _buildBadge("${widget.dayEntries.length}"),
          ),
        Positioned.fill(child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withAlpha(20), width: 1, strokeAlign: BorderSide.strokeAlignInside))))
      ]),
    );
  }

  /// Builds a placeholder widget for when an image fails to load or is missing.
  Widget _buildBrokenImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.broken_image_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 32),
          const Gap(8),
          Text('Error', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ]),
      ),
    );
  }

  /// A convenience method to build a card for the multi-entry modal.
  Widget _buildModalCard(JournalEntry entry) => _buildFilledCard(entry, showDate: false, showBadge: false);

  /// Builds a small badge widget, typically used to show the count of multiple entries.
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(158),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(41), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.copy_rounded, color: Colors.white, size: 10),
          const Gap(4),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Safely removes the long-press preview overlay from the screen.
  void _hideOverlay() {
    if (_overlayEntry != null) {
      try {
        _overlayEntry?.remove();
      } catch (e, stack) {
        Logger.error('Failed to remove overlay entry.', e, stack);
      }
      _overlayEntry = null;
    }
  }

  /// Creates and displays a full-screen overlay to preview an entry's image.
  ///
  /// Triggered on long-press. It provides haptic feedback and inserts an
  /// [_AnimatedPreviewPopup] into the application's overlay.
  void _showOverlay(BuildContext context, JournalEntry entry) {
    _hideOverlay();
    HapticFeedback.mediumImpact();
    Logger.info('Showing long-press preview for entry ID: ${entry.id}');
    final l10n = AppLocalizations.of(context)!;

    _overlayEntry = OverlayEntry(builder: (context) {
      return _AnimatedPreviewPopup(
          entry: entry,
          labelText: l10n.memoryPopup(_getEmoji(entry.moodRating))
      );
    });

    try {
      Overlay.of(context).insert(_overlayEntry!);
    } catch (e, stack) {
      Logger.error('Failed to insert overlay entry into the overlay.', e, stack);
      _overlayEntry = null;
    }
  }
}

/// A private widget that displays a full-screen, animated preview of a journal entry.
///
/// This popup appears on top of a blurred background when a user long-presses
/// a [JournalItemCard].
class _AnimatedPreviewPopup extends StatefulWidget {
  /// The journal entry to be displayed in the preview.
  final JournalEntry entry;

  /// The label text to display below the image.
  final String labelText;

  /// Creates an animated preview popup.
  const _AnimatedPreviewPopup({required this.entry, required this.labelText});

  @override
  State<_AnimatedPreviewPopup> createState() => _AnimatedPreviewPopupState();
}

class _AnimatedPreviewPopupState extends State<_AnimatedPreviewPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cacheSize = (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round();

    return Material(
      color: Colors.transparent,
      child: Stack(children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(color: Colors.black.withAlpha(82))
          ),
        ),
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.file(
                        File(widget.entry.photoPath),
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        cacheWidth: cacheSize,
                        errorBuilder: (context, error, stackTrace) {
                          Logger.error(
                            'Failed to decode full-size preview image for entry ID ${widget.entry.id}',
                            error,
                            stackTrace!,
                          );
                          return const SizedBox.shrink();
                        },
                      )
                  ),
                ),
                const Gap(14),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)),
                    child: Text(widget.labelText, style: const TextStyle(fontWeight: FontWeight.bold))
                ),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}