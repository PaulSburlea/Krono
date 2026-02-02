import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

import '../../../../../core/utils/logger_service.dart';

/// Processes an image in a background isolate to avoid blocking the UI thread.
///
/// This function handles:
/// 1. Metadata extraction to determine dimensions without full decoding.
/// 2. Native compression (Fast Path) if no geometric edits are needed.
/// 3. Dart-based manipulation (Hybrid Path) for mirroring, cropping, or resizing.
///
/// Expects [rawArgs] to be a [Map] containing:
/// - 'path': [String] path to the image file.
/// - 'mirror': [bool] whether to flip the image horizontally (default: false).
/// - 'aspect': [double] target aspect ratio (default: 0.75).
///
/// Returns the [String] path of the processed image, or null if the file is missing.
Future<String?> processAndSaveImage(dynamic rawArgs) async {
  try {
    final Map args = rawArgs as Map;
    final String path = args['path'] as String;
    final bool mirror = args['mirror'] as bool? ?? false;
    final double targetAspect = args['aspect'] as double? ?? (3 / 4);

    final file = File(path);
    if (!await file.exists()) {
      Logger.warning('Image processing skipped: Source file not found at $path');
      return null;
    }

    // Optimization: Read only metadata first to avoid decoding the full image
    // if it is not strictly necessary.
    final bytes = await file.readAsBytes();
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) {
      Logger.warning('Image processing skipped: Unsupported image format.');
      return path;
    }

    final info = decoder.startDecode(bytes);
    if (info == null) {
      Logger.warning('Image processing skipped: Could not decode image headers.');
      return path;
    }

    final int width = info.width;
    final int height = info.height;

    // Calculate current aspect ratio (normalized to < 1.0 for portrait comparison)
    double currentAspect = width < height ? width / height : height / width;
    bool needsCrop = (currentAspect - targetAspect).abs() > 0.05;

    // --- FAST PATH (Native Compression) ---
    // Use native compression if no geometric transformations (mirror/crop) are required.
    // This is significantly faster and uses less memory.
    if (!mirror && !needsCrop) {
      Logger.debug('Using fast native path (no transformations needed).');
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        path,
        quality: 85,
        autoCorrectionAngle: true,
      );
      return result?.path ?? path;
    }

    // --- HYBRID PATH (Dart Image Library) ---
    // Perform geometric transformations using the Dart image library.
    // This path is taken if the user is using the front camera (mirroring)
    // or if the aspect ratio does not match the target.
    if (mirror || needsCrop) {
      Logger.debug('Using hybrid path (mirror: $mirror, crop: $needsCrop).');

      // 1. Decode the full image
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return path;

      // 2. Bake orientation (EXIF) to ensure correct rotation before editing
      image = img.bakeOrientation(image);

      // 3. Apply mirroring for front camera selfies
      if (mirror) {
        image = img.flipHorizontal(image);
      }

      // 4. Crop to target aspect ratio if necessary
      if (needsCrop) {
        int imgW = image.width;
        int imgH = image.height;
        int cropWidth, cropHeight;

        if (imgW / imgH > targetAspect) {
          cropHeight = imgH;
          cropWidth = (imgH * targetAspect).toInt();
        } else {
          cropWidth = imgW;
          cropHeight = (imgW / targetAspect).toInt();
        }

        final int x = (imgW - cropWidth) ~/ 2;
        final int y = (imgH - cropHeight) ~/ 2;

        image = img.copyCrop(
          image,
          x: x,
          y: y,
          width: cropWidth,
          height: cropHeight,
        );
      }

      // 5. Resize if the image is excessively large (>3000px) to save space
      if (image.width > 3000) {
        image = img.copyResize(image, width: 3000);
      }

      // 6. Encode to JPEG with 85% quality
      final jpg = img.encodeJpg(image, quality: 85);

      // 7. Release memory reference
      image = null;

      // 8. Overwrite the original file with the processed data
      await file.writeAsBytes(jpg, flush: true);
      Logger.debug('Image processing completed (hybrid path).');

      return path;
    }

    return path;
  } catch (e, st) {
    Logger.error("ImageProcessor failed", e, st);
    // Return original path on failure to avoid losing the capture
    return (rawArgs is Map && rawArgs['path'] is String)
        ? rawArgs['path']
        : null;
  }
}