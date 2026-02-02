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
import '../../../core/utils/logger_service.dart';
import '../../../core/utils/weather_service.dart';
import '../data/journal_repository.dart';
import '../data/models/journal_entry.dart';
import 'widgets/camera/custom_camera_screen.dart';

/// A screen for creating a new journal entry or editing an existing one.
class AddEntryScreen extends ConsumerStatefulWidget {
  final JournalEntry? entry;
  final DateTime? initialDate;
  final String? initialImagePath;

  const AddEntryScreen({super.key, this.entry, this.initialDate, this.initialImagePath});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  String? _imagePath;
  int _mood = 3;
  String? _location;
  String? _weatherTemp;
  String? _weatherIcon;

  // Flag to track if the source image is temporary (from camera)
  bool _isImageTemporary = false;

  late final TextEditingController _noteController;
  bool _isSaving = false;
  bool _isLoadingMetadata = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.entry?.note ?? '');

    if (widget.entry != null) {
      _imagePath = widget.entry!.photoPath;
      _mood = widget.entry!.moodRating;
      _location = widget.entry!.location;
      _weatherTemp = widget.entry!.weatherTemp;
      _weatherIcon = widget.entry!.weatherIcon;
    } else if (widget.initialImagePath != null) {
      _imagePath = widget.initialImagePath;
      // Assume images passed directly are from the camera (temporary)
      _isImageTemporary = true;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    Logger.info('Attempting to fetch location and weather metadata.');
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoadingMetadata = true);

    try {
      await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Logger.warning('User denied location permission.');
          _showErrorSnackBar(l10n.locationPermissionDenied);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Logger.warning('User has permanently denied location permission.');
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.locationPermissionDenied),
              content: Text(l10n.enableLocationMessage),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                TextButton(
                  onPressed: () {
                    Logger.info('User tapped "Open Settings" for location permission.');
                    Navigator.pop(context);
                    Geolocator.openAppSettings();
                  },
                  child: Text(l10n.openSettings),
                ),
              ],
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      ).timeout(const Duration(seconds: 15));
      Logger.debug('Successfully retrieved GPS position: ${position.latitude}, ${position.longitude}');

      try {
        final langCode = ref.read(localeProvider).languageCode;
        await setLocaleIdentifier(langCode);

        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() => _location = "${p.locality}, ${p.administrativeArea}");
        }

        final weatherData = await ref.read(weatherServiceProvider).fetchWeather(
          lat: position.latitude,
          lon: position.longitude,
          langCode: langCode,
        );

        setState(() {
          _weatherTemp = weatherData.temperature;
          _weatherIcon = weatherData.iconCode;
        });
        Logger.debug('Successfully fetched metadata. Location: $_location, Weather: $_weatherTemp');
      } on SocketException catch (e, stack) {
        Logger.error('Network error while fetching metadata.', e, stack);
        _showErrorSnackBar(l10n.noInternetError);
      } catch (e, stack) {
        Logger.error('Failed to fetch geocoding or weather data.', e, stack);
      }
    } catch (e, stack) {
      Logger.error('Failed to get device location.', e, stack);
      _showErrorSnackBar(l10n.locationDisabled);
    } finally {
      if (mounted) setState(() => _isLoadingMetadata = false);
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

  /// Validates and persists the journal entry to the local database.
  Future<void> _saveEntry() async {
    if (_imagePath == null) return;

    Logger.info('User initiated save for journal entry.');
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final repo = ref.read(journalRepositoryProvider);
      final db = ref.read(databaseProvider);
      final entryDate = widget.initialDate ?? widget.entry?.date ?? DateTime.now();

      final journalEntry = JournalEntry(
        id: widget.entry?.id,
        date: entryDate,
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
        Logger.info('Updating existing entry ID: ${widget.entry!.id}. Image changed: $imageChanged');
        await repo.updateEntry(
          journalEntry,
          newTempPath: imageChanged ? _imagePath : null,
          deleteSource: imageChanged ? _isImageTemporary : false,
        );
      } else {
        Logger.info('Adding new entry.');
        await repo.addEntry(journalEntry, _imagePath!, deleteSource: _isImageTemporary);
      }

      final normalizedDate = DateTime(entryDate.year, entryDate.month, entryDate.day);
      await db.into(db.activityLog).insert(
        ActivityLogCompanion.insert(date: normalizedDate),
        mode: InsertMode.insertOrIgnore,
      );
      Logger.info('Activity log updated for date: $normalizedDate');

      if (mounted) Navigator.pop(context, true);
    } catch (e, stack) {
      Logger.error('Failed to save journal entry.', e, stack);
      if (mounted) {
        _showErrorSnackBar("Error: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.entry != null ? l10n.editEntry : l10n.moodTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                Logger.info('Mood changed to: $val');
                setState(() => _mood = val);
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
                      onTap: _fetchMetadata,
                      isLoading: _isLoadingMetadata,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _MetadataCard(
                      icon: Icons.wb_cloudy_rounded,
                      label: _weatherTemp ?? l10n.addWeather,
                      isSelected: _weatherTemp != null,
                      onTap: _fetchMetadata,
                      isLoading: _isLoadingMetadata,
                      weatherIcon: _weatherIcon,
                    ),
                  ),
                ],
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
            const Gap(24),
          ],
        ),
      ),
    );
  }

  /// Displays a modal bottom sheet for selecting an image source.
  void _showImageSourceSheet(BuildContext context, AppLocalizations l10n) {
    Logger.info('Showing image source selection sheet.');
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
                  Logger.info('User selected "Camera" as image source.');
                  final String? photoPath = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CustomCameraScreen()),
                  );
                  if (photoPath != null) {
                    Logger.info('Image captured from camera: $photoPath');
                    _handleNewImage(photoPath, isTemporary: true);
                  } else {
                    Logger.info('Camera action was cancelled by user.');
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: Text(l10n.gallery),
                onTap: () async {
                  Navigator.pop(context);
                  Logger.info('User selected "Gallery" as image source.');
                  final picker = ImagePicker();
                  final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                  if (photo != null) {
                    Logger.info('Image picked from gallery: ${photo.path}');
                    _handleNewImage(photo.path, isTemporary: false);
                  } else {
                    Logger.info('Gallery picking was cancelled by user.');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Updates the UI with the new image path and its temporary status.
  void _handleNewImage(String path, {required bool isTemporary}) {
    setState(() {
      _imagePath = path;
      _isImageTemporary = isTemporary;
    });
  }
}

/// A widget that displays the selected photo or a placeholder to add one.
class _PhotoPlaceholder extends StatelessWidget {
  /// The local file path of the image to display. If null, a placeholder is shown.
  final String? imagePath;
  /// The Hero animation tag for the photo, ensuring a smooth transition.
  final String heroTag;
  /// The callback function to execute when the placeholder is tapped.
  final VoidCallback onTap;

  /// Creates a photo placeholder widget.
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
                  ? DecorationImage(
                  image: FileImage(File(imagePath!)),
                  fit: BoxFit.cover
              )
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

/// A horizontal selector for choosing a mood rating from 1 to 5.
class _MoodSelector extends StatelessWidget {
  /// The currently selected mood rating (1-5).
  final int currentMood;
  /// A callback that is invoked with the new rating when a mood is selected.
  final ValueChanged<int> onMoodSelected;

  /// Creates a mood selector widget.
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
              color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
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

/// A card for displaying and fetching metadata like location or weather.
class _MetadataCard extends StatelessWidget {
  /// The icon representing the type of metadata.
  final IconData icon;
  /// The text label displaying the metadata value or a prompt.
  final String label;
  /// A boolean indicating if the metadata has been successfully fetched.
  final bool isSelected;
  /// The callback function to execute when the card is tapped to fetch data.
  final VoidCallback onTap;
  /// A boolean to show a loading indicator while data is being fetched.
  final bool isLoading;
  /// An optional URL for a weather icon to display instead of the default [icon].
  final String? weatherIcon;

  /// Creates a metadata card widget.
  const _MetadataCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isLoading = false,
    this.weatherIcon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
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
    );
  }
}