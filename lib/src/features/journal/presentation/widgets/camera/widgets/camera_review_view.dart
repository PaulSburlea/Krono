import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../../../../l10n/app_localizations.dart';
import '../../../../../../core/utils/logger_service.dart';
import 'camera_ui_elements.dart';

/// Displays the captured image for user approval before saving.
///
/// This screen handles two states:
/// 1. **Processing:** Shows a loading indicator while the image is being optimized/saved in the background.
/// 2. **Review:** Displays the final image file, allowing the user to either discard (Retake) or confirm (Save).
class CameraReviewView extends StatelessWidget {
  /// The absolute path to the image file to be displayed.
  final String filePath;

  /// Callback triggered when the user chooses to discard the current image.
  final VoidCallback onRetake;

  /// Callback triggered when the user confirms the image.
  final VoidCallback onSave;

  /// The accent color used for the primary action button (Save).
  final Color primaryColor;

  /// Indicates whether the background image processing is still active.
  final bool isProcessing;

  /// Optional key to force the [Image] widget to rebuild/reload when the file changes.
  final Key? imageKey;

  const CameraReviewView({
    super.key,
    required this.filePath,
    required this.onRetake,
    required this.onSave,
    required this.primaryColor,
    this.isProcessing = false,
    this.imageKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (isProcessing)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    l10n.processing,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            )
          else
            Center(
              child: Image.file(
                File(filePath),
                key: imageKey,
                fit: BoxFit.contain,
                gaplessPlayback: true,
                cacheWidth: 1080,
                errorBuilder: (context, error, stackTrace) {
                  // Log the visual failure to Crashlytics without crashing the app.
                  Logger.warning(
                    'Failed to render review image from path: $filePath',
                    error,
                    stackTrace,
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.broken_image,
                          color: Colors.white, size: 64),
                      const SizedBox(height: 12),
                      Text(
                        l10n.imageLoadError,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  );
                },
              ),
            ),

          // Bottom gradient to increase contrast for action buttons against the image.
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black87, Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextActionButton(
                  icon: Icons.refresh_rounded,
                  label: l10n.retake,
                  onTap: onRetake,
                ),
                TextActionButton(
                  icon: Icons.check_circle_rounded,
                  label: l10n.save,
                  color: primaryColor,
                  isPrimary: true,
                  onTap: onSave,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}