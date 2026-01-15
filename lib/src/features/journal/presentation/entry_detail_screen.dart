import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gal/gal.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/database/database.dart';
import '../data/journal_repository.dart';
import 'add_entry_screen.dart';

class EntryDetailScreen extends ConsumerWidget {
  final DayEntry entry;
  const EntryDetailScreen({super.key, required this.entry});

  // --- LOGICA FULL SCREEN IMAGE ---
  void _showFullScreenImage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const CloseButton(color: Colors.white),
          ),
          body: SizedBox.expand(
            child: InteractiveViewer(
              clipBehavior: Clip.none,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'photo_${entry.id}',
                child: Image.file(File(entry.photoPath), fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- SALVARE ÎN GALERIE ---
  Future<void> _saveToGallery(BuildContext context, AppLocalizations l10n) async {
    try {
      final file = File(entry.photoPath);
      if (await file.exists()) {
        await Gal.putImage(entry.photoPath);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(l10n.saveGallerySuccess),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorExport(e.toString()))));
      }
    }
  }

  // --- HELPER: CAPITALIZARE ---
  String _capitalize(String input) {
    if (input.isEmpty) return input;
    return input[0].toUpperCase() + input.substring(1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    // 1. Formatare Dată (cu prima literă mare)
    String rawDate = DateFormat('EEEE, d MMMM yyyy', locale).format(entry.date);
    final formattedDate = _capitalize(rawDate);

    // 2. Formatare Oră
    final formattedTime = DateFormat('HH:mm', locale).format(entry.date);

    // 3. Verificăm dacă ora este 00:00 (miezul nopții)
    // Dacă e 00:00, presupunem că nu a fost setată o oră anume și nu o afișăm.
    final bool showTime = entry.date.hour != 0 || entry.date.minute != 0;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black.withOpacity(0.2),
            child: const BackButton(color: Colors.white),
          ),
        ),
        actions: [
          _buildAppBarAction(icon: Icons.download_rounded, onPressed: () => _saveToGallery(context, l10n)),
          _buildAppBarAction(
            icon: Icons.edit_outlined,
            onPressed: () async {
              final bool? refresh = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddEntryScreen(entry: entry)),
              );
              if (refresh == true && context.mounted) Navigator.pop(context);
            },
          ),
          _buildAppBarAction(icon: Icons.delete_outline, onPressed: () => _showDeleteDialog(context, l10n, ref)),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // SECȚIUNEA HERO
            Hero(
              tag: 'photo_${entry.id}',
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.48,
                        width: double.infinity,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
                          child: Image.file(File(entry.photoPath), fit: BoxFit.cover),
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
                                Colors.black.withOpacity(0.1),
                                Colors.transparent,
                                Colors.black.withOpacity(0.7) // Gradient puțin mai închis pentru contrast
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20, // ✅ Am coborât textul (era 30)
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              formattedDate, // ✅ Acum are prima literă mare
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 4),
                                ],
                              ),
                            ),

                            // ✅ Afișăm ora doar dacă NU este 00:00
                            if (showTime) ...[
                              const SizedBox(height: 4), // Spațiu mic între dată și oră
                              Row(
                                children: [
                                  Icon(Icons.access_time_filled_rounded,
                                      color: Colors.white.withOpacity(0.9), size: 14),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedTime,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      shadows: const [
                                        Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 2),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMoodSection(context, l10n),
                  const SizedBox(height: 16),
                  _buildLocationAndWeather(context),
                  const SizedBox(height: 32),

                  // CARDUL NOTIȚEI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.04),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.auto_awesome_rounded,
                                  size: 16, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              l10n.journal.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
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
                            height: 1.8,
                            fontSize: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodSection(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(_getEmoji(entry.moodRating), style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.moodLabel,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  l10n.myMood,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndWeather(BuildContext context) {
    if (entry.location == null && entry.weatherTemp == null) return const SizedBox.shrink();
    return Row(
      children: [
        if (entry.location != null)
          Expanded(child: _buildInfoCard(context, Icons.location_on_rounded, entry.location!)),
        if (entry.location != null && entry.weatherTemp != null) const SizedBox(width: 8),
        if (entry.weatherTemp != null)
          Expanded(child: _buildInfoCard(context, Icons.wb_cloudy_rounded, entry.weatherTemp!, weatherIcon: entry.weatherIcon)),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String text, {String? weatherIcon}) {
    return _AutoMarqueeCard(icon: icon, text: text, weatherIcon: weatherIcon);
  }

  void _showDeleteDialog(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
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
              final repo = ref.read(journalRepositoryProvider);
              await repo.deleteEntry(entry);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBarAction({required IconData icon, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.2),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 18),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String _getEmoji(int rating) {
    const emojis = ['😢', '🙁', '😐', '🙂', '🤩'];
    return emojis[rating.clamp(1, 5) - 1];
  }
}

// --- WIDGET PERSONALIZAT PENTRU EFECTUL MARQUEE ---
class _AutoMarqueeCard extends StatefulWidget {
  final IconData icon;
  final String text;
  final String? weatherIcon;

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

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_scrollController.hasClients) return;

      await _scrollController.animateTo(
        maxScroll,
        duration: Duration(milliseconds: maxScroll.toInt() * 40),
        curve: Curves.linear,
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!_scrollController.hasClients) return;
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOut,
      );
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
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.weatherIcon != null)
            Image.network(
              'https://openweathermap.org/img/wn/${widget.weatherIcon}.png',
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => Icon(widget.icon, size: 18, color: colorScheme.primary),
            )
          else
            Icon(widget.icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
