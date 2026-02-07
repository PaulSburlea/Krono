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
    if (!await file.exists()) return null;

    // OPTIMIZATION: Read bytes once into memory
    final bytes = await file.readAsBytes();

    // Quick check for format without full decode
    final decoder = img.findDecoderForData(bytes);
    if (decoder == null) return path;

    final info = decoder.startDecode(bytes);
    if (info == null) return path;

    final int width = info.width;
    final int height = info.height;

    double currentAspect = width < height ? width / height : height / width;
    bool needsCrop = (currentAspect - targetAspect).abs() > 0.05;

    // --- FAST PATH ---
    if (!mirror && !needsCrop) {
      // If native compression is used, we don't need the bytes in memory anymore.
      // FlutterImageCompress reads from file path directly, which is efficient.
      final result = await FlutterImageCompress.compressAndGetFile(
        path,
        path,
        quality: 85,
        autoCorrectionAngle: true,
      );
      return result?.path ?? path;
    }

    // --- HYBRID PATH ---
    if (mirror || needsCrop) {
      // OPTIMIZATION: Decode only what we need.
      // Since we already have 'bytes', we pass them directly.
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return path;

      image = img.bakeOrientation(image);

      if (mirror) {
        image = img.flipHorizontal(image);
      }

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

        // OPTIMIZATION: Use integer division for speed
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

      if (image.width > 3000) {
        // OPTIMIZATION: Use average interpolation for better quality/speed balance on downscale
        image = img.copyResize(
            image,
            width: 3000,
            interpolation: img.Interpolation.average
        );
      }

      // Encode
      final jpg = img.encodeJpg(image, quality: 85);

      // Explicitly null out image to help GC before writing file
      image = null;

      await file.writeAsBytes(jpg, flush: true);
      return path;
    }

    return path;
  } catch (e, st) {
    Logger.error("ImageProcessor failed", e, st);
    return (rawArgs is Map && rawArgs['path'] is String) ? rawArgs['path'] : null;
  }
}