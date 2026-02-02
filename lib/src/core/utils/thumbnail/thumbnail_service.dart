import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../logger_service.dart';

/// A service dedicated to the creation and management of image thumbnails.
///
/// Encapsulates compression logic and filesystem paths for thumbnails,
/// keeping this responsibility separate from other image services.
class ThumbnailService {
  /// Generates a WebP thumbnail for a given image file.
  ///
  /// Returns the path to the generated thumbnail or null on failure.
  /// Includes existence checks to prevent [PathNotFoundException].
  Future<String?> generateThumbnail(String originalPath, {int width = 300, int quality = 85}) async {
    try {
      final sourceFile = File(originalPath);

      if (!await sourceFile.exists()) {
        Logger.warning('ThumbnailService: Source file missing at $originalPath');
        return null;
      }

      final dir = await getApplicationSupportDirectory();
      final thumbsDir = Directory(p.join(dir.path, 'thumbnails'));

      if (!await thumbsDir.exists()) {
        await thumbsDir.create(recursive: true);
      }

      final base = p.basenameWithoutExtension(originalPath);
      final outPath = p.join(thumbsDir.path, '${base}_thumb.webp');

      if (await File(outPath).exists()) {
        return outPath;
      }

      final XFile? compressed = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        outPath,
        minWidth: width,
        quality: quality,
        format: CompressFormat.webp,
      );

      return compressed?.path;
    } catch (e, stack) {
      Logger.error('Thumbnail generation failed', e, stack);
      return null;
    }
  }
}