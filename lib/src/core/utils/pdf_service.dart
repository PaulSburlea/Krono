import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/utils/logger_service.dart';
import '../../features/journal/data/models/journal_entry.dart';

/// A service responsible for generating, formatting, and exporting PDF documents.
///
/// This service is decoupled from the database layer and operates on
/// [JournalEntry] domain models to produce a visual representation of the journal.
class PdfService {
  /// Maps a numerical mood rating (1-5) to a corresponding emoji string.
  String _getMoodEmoji(int rating) {
    switch (rating) {
      case 1:
        return '😢';
      case 2:
        return '😐';
      case 3:
        return '😊';
      case 4:
        return '😁';
      case 5:
        return '🤩';
      default:
        return '😶';
    }
  }

  /// Generates a visual journal PDF and invokes the native sharing dialog.
  ///
  /// The document includes a cover page followed by a chronological list of
  /// [entries] formatted with the provided [title]. It utilizes Google Fonts
  /// to ensure proper Unicode and Emoji rendering.
  Future<void> generateJournalPdf(
      List<JournalEntry> entries, String title) async {
    Logger.info('PDF generation process started for ${entries.length} entries.');

    try {
      final pdf = pw.Document();

      // Loading fonts for proper Unicode and Emoji support
      final font = await PdfGoogleFonts.robotoRegular();
      final boldFont = await PdfGoogleFonts.robotoBold();
      final emojiFont = await PdfGoogleFonts.notoColorEmoji();

      // 1. Cover Page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Divider(
                    indent: 100, endIndent: 100, color: PdfColors.indigo200),
                pw.SizedBox(height: 10),
                pw.Text("Jurnal Personal",
                    style:
                    const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                pw.SizedBox(height: 50),
                pw.Text(
                    "Exportat la: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}"),
              ],
            ),
          ),
        ),
      );

      // 2. Content Pages
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          maxPages: 1000,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
            fontFallback: [emojiFont],
          ),
          build: (context) {
            List<pw.Widget> widgets = [];

            for (var entry in entries) {
              widgets.add(
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      DateFormat('EEEE, d MMM yyyy')
                          .format(entry.date)
                          .toUpperCase(),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.indigo700,
                      ),
                    ),
                    pw.Text(_getMoodEmoji(entry.moodRating),
                        style: const pw.TextStyle(fontSize: 14)),
                  ],
                ),
              );

              widgets.add(pw.SizedBox(height: 10));

              if (entry.photoPath.isNotEmpty) {
                final img = _buildSafeImage(entry.photoPath);
                if (img != null) widgets.add(img);
              }

              if (entry.note != null && entry.note!.isNotEmpty) {
                widgets.add(
                  pw.Paragraph(
                    text: entry.note!,
                    style: const pw.TextStyle(
                        fontSize: 11, lineSpacing: 2, color: PdfColors.grey900),
                    margin: const pw.EdgeInsets.only(top: 5),
                  ),
                );
              }

              widgets.add(pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 15),
                child: pw.Divider(thickness: 0.5, color: PdfColors.grey300),
              ));
            }

            return widgets;
          },
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Pagina ${context.pageNumber}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
          ),
        ),
      );

      final bytes = await pdf.save();
      Logger.info('PDF generated successfully. Initiating share dialog.');

      await Printing.sharePdf(
        bytes: bytes,
        filename: '${title.replaceAll(' ', '_')}.pdf',
      );
    } catch (e, stack) {
      Logger.error('Critical failure during PDF generation or sharing', e, stack);
    }
  }

  /// Attempts to load an image file from the provided [path] and format it for the PDF.
  ///
  /// Returns a [pw.Widget] containing the clipped image if the file exists and
  /// is valid; otherwise, returns null and logs the failure.
  pw.Widget? _buildSafeImage(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      Logger.debug('Skipping PDF image: File does not exist at $path');
      return null;
    }

    try {
      final image = pw.MemoryImage(file.readAsBytesSync());
      return pw.Center(
        child: pw.Container(
          constraints: const pw.BoxConstraints(maxHeight: 220),
          margin: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(image),
          ),
        ),
      );
    } catch (e, stack) {
      Logger.error('Failed to process image for PDF inclusion: $path', e, stack);
      return null;
    }
  }
}