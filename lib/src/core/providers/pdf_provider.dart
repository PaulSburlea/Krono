import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/pdf_service.dart';
import '../../features/journal/data/journal_repository.dart';

final exportPdfProvider = Provider((ref) {
  final repository = ref.read(journalRepositoryProvider);

  return () async {
    final entries = await repository.getAllEntries();

    if (entries.isNotEmpty) {
      await PdfService.generateJournalPdf(entries, "Krono Journal");
    }
  };
});