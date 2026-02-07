import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/logger_service.dart';
import '../../features/journal/data/models/journal_entry.dart';

/// Top-level function for background image processing.
Future<Uint8List?> _optimizeImageIsolate(String path) async {
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return null;

    // Determine orientation and target aspect ratio
    final isPortrait = image.height > image.width;
    final targetAspect = isPortrait ? 3 / 4 : 4 / 3;
    final currentAspect = image.width / image.height;

    img.Image cropped = image;
    if ((currentAspect - targetAspect).abs() > 0.01) {
      int cropWidth, cropHeight;
      if (currentAspect > targetAspect) {
        cropHeight = image.height;
        cropWidth = (image.height * targetAspect).round();
      } else {
        cropWidth = image.width;
        cropHeight = (image.width / targetAspect).round();
      }
      cropped = img.copyCrop(
        image,
        x: (image.width - cropWidth) ~/ 2,
        y: (image.height - cropHeight) ~/ 2,
        width: cropWidth,
        height: cropHeight,
      );
    }

    // Resize based on orientation
    img.Image resized = cropped;
    if (isPortrait && cropped.width > 600) {
      resized = img.copyResize(cropped, width: 600, maintainAspect: true);
    } else if (!isPortrait && cropped.width > 800) {
      resized = img.copyResize(cropped, width: 800, maintainAspect: true);
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  } catch (e) {
    return null;
  }
}

/// Service responsible for generating elegant, modern PDF documents from journal entries.
class PdfService {
  // Modern color palette
  static const primaryColor = PdfColor.fromInt(0xFF2D3748); // Charcoal
  static const accentColor = PdfColor.fromInt(0xFF667EEA); // Soft Purple
  static const secondaryAccent = PdfColor.fromInt(0xFF764BA2); // Deep Purple
  static const textPrimary = PdfColor.fromInt(0xFF1A202C);
  static const textSecondary = PdfColor.fromInt(0xFF4A5568);
  static const textTertiary = PdfColor.fromInt(0xFF718096);
  static const backgroundCard = PdfColor.fromInt(0xFFFAFAFA);
  static const dividerColor = PdfColor.fromInt(0xFFE2E8F0);

  // Colors with alpha/opacity
  static const accentLight = PdfColor.fromInt(0x1A667EEA); // 10% opacity
  static const secondaryLight = PdfColor.fromInt(0x0D764BA2); // 5% opacity
  static const whiteTransparent20 = PdfColor.fromInt(0x33FFFFFF); // 20% opacity
  static const whiteTransparent15 = PdfColor.fromInt(0x26FFFFFF); // 15% opacity
  static const whiteTransparent80 = PdfColor.fromInt(0xCCFFFFFF); // 80% opacity
  static const whiteTransparent70 = PdfColor.fromInt(0xB3FFFFFF); // 70% opacity
  static const blackTransparent05 = PdfColor.fromInt(0x0D000000); // 5% opacity

  String _getMoodEmoji(int rating) {
    const emojis = ['😢', '🙁', '😐', '🙂', '🤩'];
    return emojis[(rating - 1).clamp(0, 4)];
  }

  /// Generates a chronological PDF document with elegant, modern design.
  Future<void> generateJournalPdf(List<JournalEntry> entries, String title) async {
    Logger.info('PDF generation started for ${entries.length} entries.');

    if (entries.isEmpty) {
      Logger.warning('No entries to generate PDF');
      throw Exception('Nu există înregistrări pentru a genera PDF');
    }

    entries.sort((a, b) => a.date.compareTo(b.date));

    try {
      final pdf = pw.Document();

      Logger.info('Loading fonts...');
      final regularFont = await PdfGoogleFonts.robotoRegular();
      final mediumFont = await PdfGoogleFonts.robotoMedium();
      final boldFont = await PdfGoogleFonts.robotoBold();
      final emojiFont = await PdfGoogleFonts.notoColorEmoji();
      Logger.info('Fonts loaded successfully');

      final theme = pw.ThemeData.withFont(
        base: regularFont,
        bold: boldFont,
        fontFallback: [emojiFont],
      );

      // Elegant Cover Page
      Logger.info('Building cover page...');
      pdf.addPage(_buildCoverPage(entries, title, theme, boldFont));
      Logger.info('Cover page added successfully');

      // Process all images first
      Logger.info('Processing all images...');
      final allImages = <String, pw.MemoryImage>{};

      for (var i = 0; i < entries.length; i++) {
        final entry = entries[i];
        if (entry.photoPath.isNotEmpty) {
          try {
            Logger.info('Processing image ${i + 1}/${entries.length}: ${entry.photoPath}');
            final processedBytes = await compute(_optimizeImageIsolate, entry.photoPath);
            if (processedBytes != null) {
              allImages[entry.photoPath] = pw.MemoryImage(processedBytes);
              Logger.info('Image processed successfully');
            } else {
              Logger.warning('Failed to process image: ${entry.photoPath}');
            }
          } catch (e) {
            Logger.warning('Error processing image ${entry.photoPath}: $e');
          }
        }
      }
      Logger.info('All images processed: ${allImages.length} images');

      // Add entries - use MultiPage for EACH entry to allow long notes to span pages
      Logger.info('Building entry pages...');
      for (var i = 0; i < entries.length; i++) {
        try {
          final entry = entries[i];
          Logger.info('Adding entry ${i + 1}/${entries.length}');

          pdf.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(40),
              theme: theme,
              build: (context) => [
                _buildEntryCard(entry, allImages, mediumFont, boldFont, emojiFont),
              ],
            ),
          );
        } catch (e) {
          Logger.error('Error building entry ${i + 1}', e, StackTrace.current);
        }
      }
      Logger.info('All entries added successfully');

      Logger.info('Saving PDF...');
      final bytes = await pdf.save();
      Logger.info('PDF saved, size: ${bytes.length} bytes');

      Logger.info('Sharing PDF...');
      await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}.pdf');

      Logger.info('PDF generated successfully.');
    } catch (e, stack) {
      Logger.error('PDF Generation Error', e, stack);
      rethrow;
    }
  }

  /// Builds an elegant, modern cover page
  pw.Page _buildCoverPage(List<JournalEntry> entries, String title, pw.ThemeData theme, pw.Font boldFont) {
    final String dateRange = entries.length > 1
        ? "${DateFormat('d MMMM yyyy').format(entries.first.date)} — ${DateFormat('d MMMM yyyy').format(entries.last.date)}"
        : DateFormat('d MMMM yyyy').format(entries.first.date);

    return pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(
            begin: pw.Alignment.topLeft,
            end: pw.Alignment.bottomRight,
            colors: [accentColor, secondaryAccent],
          ),
        ),
        child: pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Decorative line
              pw.Container(
                width: 80,
                height: 4,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(2),
                ),
              ),
              pw.SizedBox(height: 40),

              // Title
              pw.Text(
                title,
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 48,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  letterSpacing: -0.5,
                ),
                textAlign: pw.TextAlign.center,
              ),

              pw.SizedBox(height: 24),

              // Subtitle
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: pw.BoxDecoration(
                  color: whiteTransparent20,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  "Jurnal Personal",
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),

              pw.SizedBox(height: 60),

              // Date range
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: whiteTransparent15,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      dateRange,
                      style: const pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "${entries.length} ${entries.length == 1 ? 'înregistrare' : 'înregistrări'}",
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: whiteTransparent80,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Generated date
              pw.Text(
                "Generat pe ${DateFormat('d MMMM yyyy').format(DateTime.now())}",
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: whiteTransparent70,
                ),
              ),
              pw.SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds an elegant entry card as a full page
  pw.Widget _buildEntryCard(
      JournalEntry entry,
      Map<String, pw.MemoryImage> images,
      pw.Font mediumFont,
      pw.Font boldFont,
      pw.Font emojiFont,
      ) {
    final hasImage = images.containsKey(entry.photoPath);
    final hasNote = entry.note != null && entry.note!.isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header with date and mood
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [accentLight, secondaryLight],
            ),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                DateFormat('EEEE, d MMMM yyyy').format(entry.date),
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
              pw.Text(
                _getMoodEmoji(entry.moodRating),
                style: pw.TextStyle(font: emojiFont, fontSize: 24),
              ),
            ],
          ),
        ),

        pw.SizedBox(height: 20),

        // Location if available
        if (entry.location != null && entry.location!.isNotEmpty)
          pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.Row(
              children: [
                pw.Text(
                  "📍",
                  style: pw.TextStyle(font: emojiFont, fontSize: 12),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  entry.location!,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: textTertiary,
                  ),
                ),
              ],
            ),
          ),

        // Content based on what's available
        if (hasImage)
          pw.Container(
            constraints: const pw.BoxConstraints(maxHeight: 400, maxWidth: 450),
            margin: const pw.EdgeInsets.only(bottom: 20),
            child: pw.ClipRRect(
              horizontalRadius: 12,
              verticalRadius: 12,
              child: pw.Image(
                images[entry.photoPath]!,
                fit: pw.BoxFit.contain,
              ),
            ),
          ),

        if (hasNote)
          pw.Container(
            child: pw.Text(
              entry.note!,
              style: const pw.TextStyle(
                fontSize: 11,
                color: textSecondary,
                lineSpacing: 1.6,
              ),
              textAlign: pw.TextAlign.justify,
            ),
          ),
      ],
    );
  }
}