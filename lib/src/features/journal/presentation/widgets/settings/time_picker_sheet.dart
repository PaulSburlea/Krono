import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../core/providers/notification_provider.dart';

class TimePickerSheet extends ConsumerStatefulWidget {
  const TimePickerSheet({super.key});

  @override
  ConsumerState<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends ConsumerState<TimePickerSheet> {
  bool _isWheelMode = true;
  late int _hour;
  late int _minute;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(notificationsEnabledProvider);
    _hour = state.hour;
    _minute = state.minute;
    _hourController = TextEditingController(text: _hour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _minute.toString().padLeft(2, '0'));

    if (!state.isEnabled) {
      Future.microtask(() =>
          ref.read(notificationsEnabledProvider.notifier).updateSettings(true, _hour, _minute)
      );
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      // Padding-ul acesta asigură că modalul se ridică deasupra tastaturii
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // REZOLVĂ OVERFLOW-UL
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mâner modal
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () => setState(() => _isWheelMode = !_isWheelMode),
                    icon: Icon(_isWheelMode ? Icons.keyboard_outlined : Icons.timer_outlined, color: colorScheme.primary),
                  )
                ],
              ),

              Text(l10n.dailyReminder, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Gap(30),

              // ZONA DE PICKER
              SizedBox(
                height: 200,
                child: _isWheelMode ? _buildWheelPicker(colorScheme) : _buildInputPicker(colorScheme),
              ),

              const Gap(40),

              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    if (!_isWheelMode) {
                      _hour = (int.tryParse(_hourController.text) ?? _hour) % 24;
                      _minute = (int.tryParse(_minuteController.text) ?? _minute) % 60;
                    }
                    await ref.read(notificationsEnabledProvider.notifier).updateSettings(true, _hour, _minute);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.save, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
              ),
              const Gap(15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWheelPicker(ColorScheme colorScheme) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // DREPTUNGHIUL DE FUNDAL UNIC (Hover orizontal continuu)
        Container(
          height: 60,
          width: 220, // Ajustează lățimea în funcție de design
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        // Pickerele deasupra
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _wheelColumn(initialItem: _hour, maxItems: 24, onChanged: (v) => _hour = v, colorScheme: colorScheme),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(":", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: colorScheme.primary)),
            ),
            _wheelColumn(initialItem: _minute, maxItems: 60, onChanged: (v) => _minute = v, colorScheme: colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _wheelColumn({required int initialItem, required int maxItems, required ValueChanged<int> onChanged, required ColorScheme colorScheme}) {
    return SizedBox(
      width: 70, // Lățime fixă pentru fiecare coloană
      child: CupertinoPicker(
        scrollController: FixedExtentScrollController(initialItem: initialItem),
        itemExtent: 60,
        looping: true,
        // Dezactivăm hover-ul lor intern pentru a-l folosi pe cel din Stack
        selectionOverlay: const SizedBox.shrink(),
        onSelectedItemChanged: (v) {
          onChanged(v);
          HapticFeedback.selectionClick();
        },
        children: List.generate(maxItems, (i) => Center(
            child: Text(
                i.toString().padLeft(2, '0'),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: colorScheme.onSurface)
            )
        )),
      ),
    );
  }

  Widget _buildInputPicker(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _inputBox(_hourController, true, colorScheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text(":", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: colorScheme.primary)),
        ),
        _inputBox(_minuteController, false, colorScheme),
      ],
    );
  }

  Widget _inputBox(TextEditingController controller, bool isHour, ColorScheme colorScheme) {
    return Container(
      width: 90, height: 90, alignment: Alignment.center,
      decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2))
      ),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(border: InputBorder.none, counterText: ""),
        onChanged: (value) {
          if (value.length == 2 && isHour) FocusScope.of(context).nextFocus();
        },
      ),
    );
  }
}