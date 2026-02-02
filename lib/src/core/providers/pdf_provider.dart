import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/logger_service.dart';
import '../../features/journal/data/journal_repository.dart';
import '../utils/pdf_service.dart';

/// Provides a singleton instance of the [PdfService].
///
/// This service contains the low-level logic for creating and styling
/// PDF documents from application data.
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

/// Provides a function that orchestrates the entire PDF export process.
///
/// This provider encapsulates the logic of fetching all journal entries from the
/// [journalRepositoryProvider] and passing them to the [pdfServiceProvider]
/// for generation and sharing. It simplifies triggering the export from the UI.
final exportPdfProvider = Provider<Future<void> Function()>((ref) {
  final repository = ref.read(journalRepositoryProvider);
  final pdfService = ref.read(pdfServiceProvider);

  return () async {
    try {
      Logger.info('PDF export process initiated by user.');
      final entries = await repository.getAllEntries();
      Logger.debug('Found ${entries.length} entries for PDF export.');

      if (entries.isNotEmpty) {
        await pdfService.generateJournalPdf(entries, "Krono Journal");
        Logger.info('Successfully generated and shared journal PDF.');
      } else {
        Logger.info('PDF export cancelled: No journal entries found.');
      }
    } catch (e, stack) {
      Logger.error('Failed to generate or share the PDF journal', e, stack);
    }
  };
});