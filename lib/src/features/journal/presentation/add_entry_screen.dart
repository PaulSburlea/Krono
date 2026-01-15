import 'dart:io';
import 'dart:convert';
import 'package:Krono/src/features/journal/presentation/widgets/camera/custom_camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/database/database.dart';
import '../../../core/providers/streak_provider.dart';
import '../../../core/providers/locale_provider.dart';
import '../data/journal_repository.dart';


class AddEntryScreen extends ConsumerStatefulWidget {
  final DayEntry? entry;
  final DateTime? initialDate;

  const AddEntryScreen({super.key, this.entry, this.initialDate});

  @override
  ConsumerState<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends ConsumerState<AddEntryScreen> {
  String? _imagePath;
  int _mood = 3;
  String? _location;
  String? _weatherTemp;
  String? _weatherIcon;
  final _noteController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingData = false;

  final String _weatherApiKey = 'eb6785447d8412398e7cb23918660ece';

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _imagePath = widget.entry!.photoPath;
      _mood = widget.entry!.moodRating;
      _noteController.text = widget.entry!.note ?? '';
      _location = widget.entry!.location;
      _weatherTemp = widget.entry!.weatherTemp;
      _weatherIcon = widget.entry!.weatherIcon;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocationAndWeather() async {
    setState(() => _isLoadingData = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permisiune refuzată';
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);

      final currentLocale = ref.read(localeProvider);
      final String langCode = currentLocale.languageCode;

      await setLocaleIdentifier(langCode);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        setState(() => _location = "${p.locality}, ${p.administrativeArea}");
      }

      final url = 'https://api.openweathermap.org/data/2.5/weather?'
          'lat=${position.latitude}'
          '&lon=${position.longitude}'
          '&appid=$_weatherApiKey'
          '&units=metric'
          '&lang=$langCode';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'].round();
        final description = data['weather'][0]['description'] as String;

        final capitalizedDesc = description.isNotEmpty
            ? description[0].toUpperCase() + description.substring(1)
            : description;

        setState(() {
          _weatherTemp = "$temp°C, $capitalizedDesc";
          _weatherIcon = data['weather'][0]['icon'];
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Eroare date: $e")));
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // Metoda veche pentru galerie (folosește ImagePicker)
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (photo != null) setState(() => _imagePath = photo.path);
  }

  Future<void> _saveEntry() async {
    if (_imagePath == null) return;
    setState(() => _isSaving = true);
    try {
      final repo = ref.read(journalRepositoryProvider);
      if (widget.entry != null) {
        await repo.updateEntry(
          entry: widget.entry!,
          newPhotoPath: _imagePath!,
          newMood: _mood,
          newNote: _noteController.text,
          newLocation: _location,
          newWeatherTemp: _weatherTemp,
          newWeatherIcon: _weatherIcon,
        );
      } else {
        await repo.addEntry(
          tempPhotoPath: _imagePath!,
          mood: _mood,
          note: _noteController.text,
          date: widget.initialDate,
          location: _location,
          weatherTemp: _weatherTemp,
          weatherIcon: _weatherIcon,
        );
        ref.read(streakProvider.notifier).markActivity();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.entry != null ? l10n.editEntry : l10n.moodTitle,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. FOTO
            GestureDetector(
              onTap: () => _showImageSourceSheet(context, l10n),
              child: Hero(
                tag: widget.entry != null ? 'photo_${widget.entry!.id}' : 'add_photo',
                child: Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(32),
                    image: _imagePath != null
                        ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _imagePath == null
                      ? Icon(Icons.add_a_photo_outlined, size: 48, color: colorScheme.primary)
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            const Gap(32),

            // 2. MOOD
            Text(l10n.myMood, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (index) {
                int rating = index + 1;
                bool sel = _mood == rating;
                return GestureDetector(
                  onTap: () => setState(() => _mood = rating),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sel ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_getEmoji(rating), style: const TextStyle(fontSize: 28)),
                  ),
                );
              }),
            ),
            const Gap(24),

            // 3. LOCAȚIE ȘI METEO
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.location_on_rounded,
                    label: _location ?? l10n.addLocation,
                    isSelected: _location != null,
                    onTap: _fetchLocationAndWeather,
                    isLoading: _isLoadingData,
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.wb_cloudy_rounded,
                    label: _weatherTemp ?? l10n.addWeather,
                    isSelected: _weatherTemp != null,
                    onTap: _fetchLocationAndWeather,
                    isLoading: _isLoadingData,
                    weatherIcon: _weatherIcon,
                  ),
                ),
              ],
            ),
            const Gap(32),

            // 4. NOTE
            Text(l10n.noteHint, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const Gap(12),
            TextField(
              controller: _noteController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                hintText: l10n.writeMemory,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              ),
            ),
            const Gap(40),

            // 5. BUTON SALVARE
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving || _imagePath == null ? null : _saveEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.saveDay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isLoading = false,
    String? weatherIcon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.08) : colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary.withOpacity(0.4) : colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            else if (weatherIcon != null)
              Image.network('https://openweathermap.org/img/wn/$weatherIcon@2x.png', width: 32, height: 32)
            else
              Icon(icon, size: 18, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
            const Gap(6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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

  // ✅ MODIFICARE: Integrarea navigării către CustomCameraScreen
  void _showImageSourceSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Opțiunea 1: Camera Custom
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: Text(l10n.camera),
              onTap: () async {
                Navigator.pop(context); // Închidem modalul

                // Deschidem ecranul nostru de cameră Full Screen
                final String? photoPath = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomCameraScreen(),
                  ),
                );

                // Dacă utilizatorul a făcut poza și a dat confirm, o salvăm
                if (photoPath != null) {
                  setState(() => _imagePath = photoPath);
                }
              },
            ),

            // Opțiunea 2: Galerie (Sistem nativ)
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: Text(l10n.gallery),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getEmoji(int rating) {
    const emojis = ['😢', '🙁', '😐', '🙂', '🤩'];
    return emojis[rating.clamp(1, 5) - 1];
  }
}