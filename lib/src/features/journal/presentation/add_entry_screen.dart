import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:drift/drift.dart' show InsertMode;

import '../../../../l10n/app_localizations.dart';
import '../../../core/database/database.dart';
import '../../settings/providers/locale_provider.dart';
import '../../settings/providers/theme_provider.dart';
import '../../../core/utils/logger_service.dart';
import '../../../core/utils/weather_service.dart';
import '../data/journal_repository.dart';
import '../data/models/journal_entry.dart';
import 'widgets/camera/custom_camera_screen.dart';

/// Helper class to prevent excessive disk writes while typing.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

/// A screen for creating a new journal entry or editing an existing one.
/// Includes Draft Auto-Save, Date Anchoring, and Metadata Management.
class AddEntryScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  final DateTime? initialDate;
  final String? initialImagePath;

  const AddEntryScreen({super.key, this.entry, this.initialDate, this.initialImagePath});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> with WidgetsBindingObserver {
  // State variables
  String? _imagePath;
  int _mood = 3;
  String? _location;
  String? _weatherTemp;
  String? _weatherIcon;
  bool _isImageTemporary = false;

  late final TextEditingController _noteController;
  bool _isSaving = false;
  bool _isLoadingMetadata = false;
  bool _hasUnsavedChanges = false;

  // Debouncer for text saving
  final _textDebouncer = Debouncer(milliseconds: 500);

  /// The date this entry is anchored to.
  late DateTime _anchoredDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 1. Anchor the date immediately
    _anchoredDate = widget.initialDate ?? widget.entry?.date ?? DateTime.now();

    _noteController = TextEditingController(text: widget.entry?.note ?? '');

    // 2. Initialize state or load draft
    if (widget.entry != null) {
      _imagePath = widget.entry!.photoPath;
      _mood = widget.entry!.moodRating;
      _location = widget.entry!.location;
      _weatherTemp = widget.entry!.weatherTemp;
      _weatherIcon = widget.entry!.weatherIcon;
    } else {
      _imagePath = widget.initialImagePath;
      _isImageTemporary = widget.initialImagePath != null;
      if (_imagePath != null) _hasUnsavedChanges = true;
      _loadDraft();
    }

    // 3. Listen to text changes for Auto-Save and Dirty State
    _noteController.addListener(() {
      if (!_hasUnsavedChanges && _noteController.text.isNotEmpty) {
        setState(() => _hasUnsavedChanges = true);
      }
      _textDebouncer.run(() => _saveDraft());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _textDebouncer.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- LIFECYCLE & DRAFT LOGIC ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    if (widget.entry != null) return;
    if (_imagePath == null && _noteController.text.isEmpty && _location == null) return;

    // Mark as dirty if not already
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final draftData = {
        'imagePath': _imagePath,
        'mood': _mood,
        'note': _noteController.text,
        'location': _location,
        'weatherTemp': _weatherTemp,
        'weatherIcon': _weatherIcon,
        'isImageTemporary': _isImageTemporary,
        'anchoredDate': _anchoredDate.toIso8601String(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('journal_draft', jsonEncode(draftData));
    } catch (e) {
      Logger.error('Failed to save draft.', e, StackTrace.current);
    }
  }

  Future<void> _loadDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final draftString = prefs.getString('journal_draft');

    if (draftString != null) {
      try {
        final data = jsonDecode(draftString);
        final savedAnchorDate = DateTime.parse(data['anchoredDate']);

        setState(() {
          _anchoredDate = savedAnchorDate;
          _imagePath = data['imagePath'];
          _mood = data['mood'] ?? 3;
          if (_noteController.text != (data['note'] ?? '')) {
            _noteController.text = data['note'] ?? '';
          }
          _location = data['location'];
          _weatherTemp = data['weatherTemp'];
          _weatherIcon = data['weatherIcon'];
          _isImageTemporary = data['isImageTemporary'] ?? false;
          _hasUnsavedChanges = true;
        });
        Logger.info('Draft restored. Entry anchored to: $_anchoredDate');
      } catch (e) {
        Logger.error('Failed to load draft.', e, StackTrace.current);
      }
    }
  }

  Future<void> _clearDraft() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove('journal_draft');
  }

  // --- EXIT CONFIRMATION ---

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _isSaving || widget.entry != null) {
      await _clearDraft();
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.discardChangesTitle),
        content: Text(l10n.discardChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    if (shouldDiscard == true) {
      await _clearDraft();
      return true;
    }
    return false;
  }

  // --- METADATA LOGIC ---

  void _handleMetadataInteraction({required bool isLocation}) {
    final bool hasData = isLocation ? _location != null : _weatherTemp != null;
    final bool isToday = DateUtils.isSameDay(_anchoredDate, DateTime.now());

    if (hasData) {
      _showMetadataOptions(isLocation: isLocation, canUpdate: isToday);
    } else if (isToday) {
      _fetchMetadata();
    }
  }

  void _showMetadataOptions({required bool isLocation, required bool canUpdate}) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUpdate)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l10n.update),
                onTap: () {
                  Navigator.pop(context);
                  _fetchMetadata();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
              title: Text(l10n.remove, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  if (isLocation) {
                    _location = null;
                  } else {
                    _weatherTemp = null;
                    _weatherIcon = null;
                  }
                });
                _saveDraft();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchMetadata() async {
    Logger.info('Fetching metadata...');
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoadingMetadata = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar(l10n.locationPermissionDenied);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar(l10n.locationPermissionDenied);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 10));

      final langCode = ref.read(localeProvider).languageCode;

      await Future.wait([
        placemarkFromCoordinates(position.latitude, position.longitude).then((placemarks) {
          if (placemarks.isNotEmpty) {
            final p = placemarks.first;
            setState(() => _location = "${p.locality}, ${p.administrativeArea}");
          }
        }),
        ref.read(weatherServiceProvider).fetchWeather(
          lat: position.latitude,
          lon: position.longitude,
          langCode: langCode,
        ).then((weatherData) {
          setState(() {
            _weatherTemp = weatherData.temperature;
            _weatherIcon = weatherData.iconCode;
          });
        }),
      ]);

      _saveDraft();

    } catch (e) {
      Logger.error('Metadata fetch error', e, StackTrace.current);
      _showErrorSnackBar(l10n.noInternetError);
    } finally {
      if (mounted) setState(() => _isLoadingMetadata = false);
    }
  }

  // --- SAVE LOGIC ---

  Future<void> _saveEntry() async {
    if (_imagePath == null) return;

    Logger.info('Saving entry for date: $_anchoredDate');
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(journalRepositoryProvider);
      final db = ref.read(databaseProvider);

      final journalEntry = JournalEntry(
        id: widget.entry?.id,
        date: _anchoredDate,
        photoPath: _imagePath!,
        thumbnailPath: widget.entry?.thumbnailPath,
        moodRating: _mood,
        note: _noteController.text,
        location: _location,
        weatherTemp: _weatherTemp,
        weatherIcon: _weatherIcon,
      );

      if (widget.entry != null) {
        final bool imageChanged = _imagePath != widget.entry!.photoPath;
        await repo.updateEntry(
          journalEntry,
          newTempPath: imageChanged ? _imagePath : null,
          deleteSource: imageChanged ? _isImageTemporary : false,
        );
      } else {
        await repo.addEntry(journalEntry, _imagePath!, deleteSource: _isImageTemporary);
        await _clearDraft();
      }

      final normalizedDate = DateTime(_anchoredDate.year, _anchoredDate.month, _anchoredDate.day);
      await db.into(db.activityLog).insert(
        ActivityLogCompanion.insert(date: normalizedDate),
        mode: InsertMode.insertOrIgnore,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e, stack) {
      Logger.error('Failed to save journal entry.', e, stack);
      if (mounted) _showErrorSnackBar("Error saving entry");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isToday = DateUtils.isSameDay(_anchoredDate, DateTime.now());

    // Calculăm padding-ul de jos pentru a evita suprapunerea cu bara de navigare
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.entry != null ? l10n.editEntry : l10n.moodTitle,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SingleChildScrollView(
          // ✅ FIX: Adăugăm bottomPadding la padding-ul existent
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PhotoPlaceholder(
                imagePath: _imagePath,
                heroTag: widget.entry != null ? 'photo_${widget.entry!.id}' : 'add_photo',
                onTap: () => _showImageSourceSheet(context, l10n),
              ),
              const Gap(24),

              Text(l10n.myMood, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(12),

              _MoodSelector(
                currentMood: _mood,
                onMoodSelected: (val) {
                  setState(() => _mood = val);
                  _saveDraft();
                },
              ),
              const Gap(24),

              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MetadataCard(
                        icon: Icons.location_on_rounded,
                        label: _location ?? l10n.addLocation,
                        isSelected: _location != null,
                        isEnabled: (_location != null) || isToday,
                        onTap: () => _handleMetadataInteraction(isLocation: true),
                        isLoading: _isLoadingMetadata,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _MetadataCard(
                        icon: Icons.wb_cloudy_rounded,
                        label: _weatherTemp ?? l10n.addWeather,
                        isSelected: _weatherTemp != null,
                        isEnabled: (_weatherTemp != null) || isToday,
                        onTap: () => _handleMetadataInteraction(isLocation: false),
                        isLoading: _isLoadingMetadata,
                        weatherIcon: _weatherIcon,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isToday && _location == null && _weatherTemp == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    "Metadata is only available for today's entries.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              const Gap(24),

              Text(l10n.noteHint, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(12),

              TextField(
                controller: _noteController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  hintText: l10n.writeMemory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const Gap(40),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton(
                  onPressed: _isSaving || _imagePath == null ? null : _saveEntry,
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(l10n.saveDay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              // Nu mai e nevoie de Gap(24) aici pentru că am pus padding la SingleChildScrollView
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 12, right: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: Text(l10n.camera),
                onTap: () async {
                  Navigator.pop(context);
                  final String? photoPath = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
                  );
                  if (photoPath != null) {
                    _handleNewImage(photoPath, isTemporary: true);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.gallery),
                onTap: () async {
                  Navigator.pop(context);
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (photo != null) {
                    _handleNewImage(photo.path, isTemporary: false);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNewImage(String path, {required bool isTemporary}) {
    setState(() {
      _imagePath = path;
      _isImageTemporary = isTemporary;
    });
    _saveDraft();
  }
}

// --- WIDGETS ---

class _PhotoPlaceholder extends StatelessWidget {
  final String? imagePath;
  final String heroTag;
  final VoidCallback onTap;

  const _PhotoPlaceholder({required this.imagePath, required this.heroTag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: heroTag,
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.1)),
              image: imagePath != null
                  ? DecorationImage(image: FileImage(File(imagePath!)), fit: BoxFit.cover)
                  : null,
            ),
            child: imagePath == null
                ? Center(child: Icon(Icons.add_a_photo_outlined, size: 48, color: colorScheme.primary))
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _MoodSelector extends StatelessWidget {
  final int currentMood;
  final ValueChanged<int> onMoodSelected;

  const _MoodSelector({required this.currentMood, required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final emojis = ['😢', '🙁', '😐', '🙂', '🤩'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        int rating = index + 1;
        bool isSelected = currentMood == rating;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            onMoodSelected(rating);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              // ✅ FIX: Transparent dacă nu e selectat
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [BoxShadow(color: colorScheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Text(emojis[index], style: const TextStyle(fontSize: 30)),
          ),
        );
      }),
    );
  }
}

class _MetadataCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool isLoading;
  final String? weatherIcon;

  const _MetadataCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    this.isLoading = false,
    this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: (isLoading || !isEnabled) ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          height: 64,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary.withValues(alpha: 0.08) : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? colorScheme.primary.withValues(alpha: 0.3) : colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Center(
                  child: isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  )
                      : weatherIcon != null
                      ? Image.network(
                    'https://openweathermap.org/img/wn/$weatherIcon@2x.png',
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Icon(icon, size: 20),
                  )
                      : Icon(
                    icon,
                    size: 20,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}