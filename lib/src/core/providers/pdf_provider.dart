import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/journal/data/journal_repository.dart';
import '../utils/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

class PdfExportLoading extends Notifier<bool> {
  @override
  bool build() => false;
  void setLoading(bool value) => state = value;
}

final pdfExportLoadingProvider = NotifierProvider<PdfExportLoading, bool>(PdfExportLoading.new);

/// Orchestrates PDF export with optional date range filtering.
final exportPdfProvider = Provider<Future<void> Function(DateTimeRange?)>((ref) {
  final repository = ref.read(journalRepositoryProvider);
  final pdfService = ref.read(pdfServiceProvider);

  return (DateTimeRange? range) async {
    ref.read(pdfExportLoadingProvider.notifier).setLoading(true);

    try {
      var entries = await repository.getAllEntries();

      if (range != null) {
        // Filter entries within the selected range (inclusive)
        entries = entries.where((e) {
          final date = DateTime(e.date.year, e.date.month, e.date.day);
          return (date.isAtSameMomentAs(range.start) || date.isAfter(range.start)) &&
              (date.isAtSameMomentAs(range.end) || date.isBefore(range.end));
        }).toList();
      }

      if (entries.isEmpty) throw Exception('No entries found for the selected period');

      await pdfService.generateJournalPdf(entries, "Krono Journal");
    } finally {
      ref.read(pdfExportLoadingProvider.notifier).setLoading(false);
    }
  };
});