import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../../core/providers/notification_provider.dart';
import '../../../../core/utils/logger_service.dart';
import '../../../../../../l10n/app_localizations.dart';

/// A professional bottom sheet widget for selecting a time.
///
/// Supports two modes:
/// 1. **Wheel Picker:** A classic iOS-style scrolling wheel.
/// 2. **Input Picker:** A direct text input for precise entry.
///
/// This widget is optimized for keyboard interactions, ensuring the layout
/// adjusts smoothly without resizing the decorative container abruptly.
class TimePickerSheet extends ConsumerStatefulWidget {
  /// Creates a [TimePickerSheet].
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
    final state = ref.read(notificationProvider);
    _hour = state.hour;
    _minute = state.minute;

    _hourController =
        TextEditingController(text: _hour.toString().padLeft(2, '0'));
    _minuteController =
        TextEditingController(text: _minute.toString().padLeft(2, '0'));
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  /// Validates and persists the selected time.
  Future<void> _handleSave() async {
    HapticFeedback.mediumImpact();

    int finalHour = _hour;
    int finalMinute = _minute;

    // If in input mode, parse the text fields.
    if (!_isWheelMode) {
      finalHour = int.tryParse(_hourController.text) ?? _hour;
      finalMinute = int.tryParse(_minuteController.text) ?? _minute;
      finalHour = finalHour.clamp(0, 23);
      finalMinute = finalMinute.clamp(0, 59);
    }

    Logger.info('User saved new reminder time: $finalHour:$finalMinute');

    await ref.read(notificationProvider.notifier).updateSettings(
      true,
      finalHour,
      finalMinute,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Retrieve the keyboard height to adjust padding dynamically.
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // OPTIMIZATION: The main container does NOT have bottom padding for the keyboard.
    // It remains fixed, while the internal SingleChildScrollView handles the offset.
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: SingleChildScrollView(
        // Clamping physics prevents visual bouncing during resize events.
        physics: const ClampingScrollPhysics(),
        child: Padding(
          // OPTIMIZATION: Padding is applied here at the end of the scroll view.
          // This pushes content up when the keyboard opens without resizing the decorative container.
          padding: EdgeInsets.only(bottom: bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Gap(48), // Spacer to balance the icon button
                  Text(
                    l10n.dailyReminder,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _isWheelMode = !_isWheelMode);
                    },
                    icon: Icon(
                      _isWheelMode
                          ? Icons.keyboard_rounded
                          : Icons.access_time_filled_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const Gap(32),

              // Picker Area (Fixed Height for consistency)
              SizedBox(
                height: 200,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutQuad,
                  switchOutCurve: Curves.easeInQuad,
                  child: _isWheelMode
                      ? _buildWheelPicker(colorScheme)
                      : _buildInputPicker(colorScheme),
                ),
              ),

              const Gap(48),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: _handleSave,
                  child: Text(
                    l10n.save,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the scrolling wheel picker.
  Widget _buildWheelPicker(ColorScheme colorScheme) {
    return Stack(
      key: const ValueKey('wheel'),
      alignment: Alignment.center,
      children: [
        // Selection Highlight Bar
        Container(
          height: 64,
          width: 200,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _WheelColumn(
              initialItem: _hour,
              maxItems: 24,
              onChanged: (v) => _hour = v,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                ":",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary),
              ),
            ),
            _WheelColumn(
              initialItem: _minute,
              maxItems: 60,
              onChanged: (v) => _minute = v,
            ),
          ],
        ),
      ],
    );
  }

  /// Renders the text input picker.
  Widget _buildInputPicker(ColorScheme colorScheme) {
    return Row(
      key: const ValueKey('input'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimeInputBox(
            controller: _hourController, label: "HH", colorScheme: colorScheme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            ":",
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary),
          ),
        ),
        _TimeInputBox(
            controller: _minuteController,
            label: "MM",
            colorScheme: colorScheme),
      ],
    );
  }
}

/// A reusable scrolling column for the wheel picker.
class _WheelColumn extends StatelessWidget {
  final int initialItem;
  final int maxItems;
  final ValueChanged<int> onChanged;

  const _WheelColumn({
    required this.initialItem,
    required this.maxItems,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Simulate infinite scrolling by starting at a large index offset.
    final int infiniteCenter = 1000 * maxItems;
    final int initialScrollIndex = infiniteCenter + initialItem;

    return SizedBox(
      width: 70,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller:
        FixedExtentScrollController(initialItem: initialScrollIndex),
        itemExtent: 60,
        physics: const FixedExtentScrollPhysics(),
        perspective: 0.005,
        useMagnifier: true,
        magnification: 1.1,
        overAndUnderCenterOpacity: 0.5,
        onSelectedItemChanged: (index) {
          final value = index % maxItems;
          onChanged(value);
          HapticFeedback.selectionClick();
        },
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: null, // Infinite
          builder: (context, index) {
            final value = (index % maxItems + maxItems) % maxItems;
            return Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A styled text input box for manual time entry.
class _TimeInputBox extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ColorScheme colorScheme;

  const _TimeInputBox({
    required this.controller,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 2,
          autofocus: false, // Prevents aggressive focus which can cause UI lag.
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 44, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            border: InputBorder.none,
            counterText: "",
            hintText: label,
            hintStyle: TextStyle(color: colorScheme.outlineVariant),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            // Automatically move focus to the next field when 2 digits are entered.
            if (value.length == 2) FocusScope.of(context).nextFocus();
          },
        ),
      ),
    );
  }
}