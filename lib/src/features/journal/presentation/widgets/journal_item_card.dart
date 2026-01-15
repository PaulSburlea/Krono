import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/database/database.dart';
import '../entry_detail_screen.dart';

class JournalItemCard extends StatefulWidget {
  final DateTime date;
  final List<DayEntry> dayEntries;

  JournalItemCard({
    super.key,
    required this.date,
    required this.dayEntries,
  });

  @override
  State<JournalItemCard> createState() => _JournalItemCardState();
}

class _JournalItemCardState extends State<JournalItemCard> {
  OverlayEntry? _overlayEntry;

  // Verificare sigură pentru "Azi"
  bool get _isToday {
    final now = DateTime.now();
    return widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
  }

  String _getEmoji(int rating) {
    const emojis = ['😢', '🙁', '😐', '🙂', '🤩'];
    return emojis[rating.clamp(1, 5) - 1];
  }

  void _navigateToDetail(DayEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EntryDetailScreen(entry: entry)),
    );
  }

  // ⚡ OPTIMIZARE MAJORĂ: cacheWidth
  Widget _buildOptimizedImage(String path) {
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      // Încărcăm poza micșorată în memorie (350px e suficient pentru grid)
      // Asta previne crash-urile de memorie și lag-ul la scroll.
      cacheWidth: 350,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
      ),
    );
  }

  void _showMultipleEntriesModal() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final sortedModalEntries = List<DayEntry>.from(widget.dayEntries)
      ..sort((a, b) => b.moodRating.compareTo(a.moodRating));

    String rawDate = DateFormat('d MMMM', locale).format(widget.date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(24),
            Text(
              l10n.memoriesFrom(rawDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            const Gap(24),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: sortedModalEntries.length,
                itemBuilder: (context, index) {
                  final entry = sortedModalEntries[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToDetail(entry);
                    },
                    child: _buildBasicCard(entry, customHeroTag: 'modal_photo_${entry.id}', showDate: false),
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
    if (widget.dayEntries.isEmpty) return _buildEmptyDay();

    final mainEntry = widget.dayEntries.reduce((a, b) => a.moodRating >= b.moodRating ? a : b);
    final hasMultiple = widget.dayEntries.length > 1;

    return GestureDetector(
      onTap: () => hasMultiple ? _showMultipleEntriesModal() : _navigateToDetail(mainEntry),
      onLongPressStart: (_) => _showOverlay(context, mainEntry),
      onLongPressEnd: (_) => _hideOverlay(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBasicCard(mainEntry, showDate: true),

          // Badge pentru intrări multiple (Dreapta Sus)
          if (hasMultiple)
            Positioned(
              top: 6,
              right: 6,
              // Afișăm numărul total, ex: "3"
              child: _buildBadge("${widget.dayEntries.length}"),
            ),
        ],
      ),
    );
  }

  // --- 1. ZIUA GOALĂ ---
  Widget _buildEmptyDay() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _isToday
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12), // Rază medie, modernă
        border: _isToday
            ? Border.all(color: theme.colorScheme.primary.withOpacity(0.6), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          "${widget.date.day}",
          style: TextStyle(
            color: _isToday
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            fontWeight: _isToday ? FontWeight.w800 : FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --- 2. ZIUA PLINĂ (Optimizată) ---
  Widget _buildBasicCard(DayEntry entry, {String? customHeroTag, bool showDate = true}) {
    // ⚡ Folosim clipBehavior aici e mai rapid decât ClipRRect imbricat
    return Hero(
      tag: customHeroTag ?? 'photo_${entry.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          // Umbră ușoară (performantă)
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imaginea
            _buildOptimizedImage(entry.photoPath),

            // Gradient pentru text
            if (showDate) ...[
              const Positioned(
                bottom: 0, left: 0, right: 0, height: 50,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black54, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 6, right: 8,
                child: Text(
                  "${widget.date.day}",
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13,
                    shadows: [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ),
            ],

            // ⚡ EMOJI FĂRĂ BLUR (Performanță maximă)
            Positioned(
              top: 6, left: 6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4), // Negru transparent simplu
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _getEmoji(entry.moodRating),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.copy_rounded, color: Colors.white, size: 10),
          const Gap(4),
          Text(
            text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  void _showOverlay(BuildContext context, DayEntry entry) {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    final emoji = _getEmoji(entry.moodRating);

    _overlayEntry = OverlayEntry(
      builder: (context) => _PreviewPopup(
        entry: entry,
        labelText: l10n.memoryPopup(emoji),
        // Aici lăsăm rezoluție mai mare că e o singură poză
        imageWidget: Image.file(File(entry.photoPath), fit: BoxFit.cover),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
}

// --- POPUP PREVIEW ---
class _PreviewPopup extends StatefulWidget {
  final DayEntry entry;
  final String labelText;
  final Widget imageWidget;

  _PreviewPopup({
    required this.entry,
    required this.labelText,
    required this.imageWidget,
  });

  @override
  State<_PreviewPopup> createState() => _PreviewPopupState();
}

class _PreviewPopupState extends State<_PreviewPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8 * value, sigmaY: 8 * value),
                child: Container(color: Colors.black.withOpacity(0.2 * value)),
              );
            },
          ),
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: widget.imageWidget,
                    ),
                    const Gap(16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)
                        ],
                      ),
                      child: Text(
                        widget.labelText,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}