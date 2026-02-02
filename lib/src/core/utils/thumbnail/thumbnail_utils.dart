import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../logger_service.dart';

/// Generates a high-performance WebP thumbnail for a given image file.
///
/// The thumbnail is stored in a dedicated 'thumbnails' subdirectory within the
/// application support directory. This utility includes existence checks to prevent
/// I/O exceptions. If the [originalPath] does not exist or the compression process
/// fails, the function returns the [originalPath] as a fallback to ensure the UI
/// still has a valid reference to display.
Future<String> generateThumbnail(
    String originalPath, {
      int width = 300,
      int quality = 85,
    }) async {
  try {
    final sourceFile = File(originalPath);

    // Validate file existence before attempting I/O operations to avoid PathNotFoundException.
    if (!await sourceFile.exists()) {
      Logger.debug('Thumbnail generation skipped: Source file missing at $originalPath');
      return originalPath;
    }

    final dir = await getApplicationSupportDirectory();
    final thumbsDir = Directory(p.join(dir.path, 'thumbnails'));

    // Ensure the destination directory exists.
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }

    final base = p.basenameWithoutExtension(originalPath);
    final outPath = p.join(thumbsDir.path, '${base}_thumb.webp');

    // Avoid redundant compression cycles if the thumbnail already exists on disk.
    if (await File(outPath).exists()) {
      return outPath;
    }

    // Perform native compression to WebP format for optimal size/quality ratio.
    final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
      originalPath,
      outPath,
      minWidth: width,
      quality: quality,
      format: CompressFormat.webp,
    );

    return compressed?.path ?? originalPath;
  } catch (e, stack) {
    Logger.error('Failed to generate thumbnail for path: $originalPath', e, stack);
    return originalPath;
  }
}