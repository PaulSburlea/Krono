import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../database/database.dart';

class PdfService {
  static String _getMoodEmoji(int rating) {
    switch (rating) {
      case 1: return '😢';
      case 2: return '😐';
      case 3: return '😊';
      case 4: return '😁';
      case 5: return '🤩';
      default: return '😶';
    }
  }

  static Future<void> generateJournalPdf(List<DayEntry> entries, String title) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final emojiFont = await PdfGoogleFonts.notoColorEmoji();

    // 1. PAGINA DE COPERTĂ
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text(title, style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
              pw.SizedBox(height: 20),
              pw.Divider(indent: 100, endIndent: 100, color: PdfColors.indigo200),
              pw.SizedBox(height: 10),
              pw.Text("Jurnal Personal", style: const pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
              pw.SizedBox(height: 50),
              pw.Text("Exportat la: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}"),
            ],
          ),
        ),
      ),
    );

    // 2. PAGINILE CU CONȚINUT
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        maxPages: 1000,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont, fontFallback: [emojiFont]),
        build: (context) {
          List<pw.Widget> widgets = [];

          for (var entry in entries) {
            // Header zi (Dată + Mood)
            widgets.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    DateFormat('EEEE, d MMM yyyy').format(entry.date).toUpperCase(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.indigo700),
                  ),
                  pw.Text(_getMoodEmoji(entry.moodRating), style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 10));

            // IMAGINEA (Dacă există) - O punem direct în listă, fără containere complexe
            if (entry.photoPath.isNotEmpty) {
              final img = _buildSafeImage(entry.photoPath);
              if (img != null) widgets.add(img);
            }

            // NOTA - Folosim Paragraph pentru că este singurul care se rupe garantat pe mai multe pagini
            if (entry.note != null && entry.note!.isNotEmpty) {
              widgets.add(
                pw.Paragraph(
                  text: entry.note!,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 2, color: PdfColors.grey900),
                  margin: const pw.EdgeInsets.only(top: 5),
                ),
              );
            }

            // Linie de separare și spațiu
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 15),
              child: pw.Divider(thickness: 0.5, color: PdfColors.grey300),
            ));
          }

          return widgets;
        },
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Pagina ${context.pageNumber}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey)),
        ),
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: '${title.replaceAll(' ', '_')}.pdf');
  }

  static pw.Widget? _buildSafeImage(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final image = pw.MemoryImage(file.readAsBytesSync());
      return pw.Center(
        child: pw.Container(
          // Important: Reducem înălțimea maximă pentru a ne asigura că încape pe orice pagină
          constraints: const pw.BoxConstraints(maxHeight: 220),
          margin: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(image),
          ),
        ),
      );
    } catch (e) {
      return null;
    }
  }
}