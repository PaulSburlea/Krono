import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';


import 'logger_service.dart';

/// A service dedicated to optimizing images and managing permanent filesystem storage.
class ImageService {
  /// Optimizes a raw image from [sourcePath], converts it to WebP, and persists it.
  ///
  /// @param deleteSource If true, the original file at [sourcePath] will be deleted.
  /// This should only be used for temporary files (e.g., from the camera).
  /// Returns the absolute path of the new image or null on failure.
  Future<String?> processAndOptimizeImage(String sourcePath, {bool deleteSource = false}) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        Logger.debug('Image source file does not exist at: $sourcePath');
        return null;
      }

      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'krono_${DateTime.now().millisecondsSinceEpoch}.webp';
      final permanentPath = p.join(dir.path, fileName);

      Logger.info('Initiating native WebP compression for image.');

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        sourcePath,
        permanentPath,
        quality: 85,
        format: CompressFormat.webp,
      );

      if (result == null) {
        Logger.debug('Native compression returned a null result.');
        return null;
      }

      final permanentFile = File(result.path);
      if (await permanentFile.exists()) {
        Logger.info('Successfully persisted optimized image.');

        // ✅ SAFETY FIX: Only delete the source file if explicitly instructed.
        if (deleteSource) {
          await _deleteSilently(sourcePath);
        }
        return result.path;
      }

      return null;
    } catch (e, stack) {
      Logger.error('Failed to process and optimize image', e, stack);
      return null;
    }
  }

  /// Removes a file from the local filesystem at the specified [path].
  Future<void> deleteFile(String? path) async {
    if (path == null || path.isEmpty) return;
    await _deleteSilently(path);
  }

  /// Attempts to delete a file at [path] without propagating exceptions.
  Future<void> _deleteSilently(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        Logger.debug('Successfully deleted file: $path');
      }
    } catch (e, stack) {
      Logger.error('Failed to perform silent file deletion for path: $path', e, stack);
    }
  }
}