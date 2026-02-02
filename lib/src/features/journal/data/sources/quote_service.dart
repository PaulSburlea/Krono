import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../../core/utils/logger_service.dart';
import '../../domain/models/quote.dart';

/// Provides a singleton instance of the [http.Client].
///
/// This provider allows for easy dependency injection and mocking of the
/// HTTP client during unit testing.
final httpClientProvider = Provider((ref) => http.Client());

/// Provides the [QuoteService] instance.
final quoteServiceProvider = Provider((ref) {
  return QuoteService(ref.watch(httpClientProvider));
});

/// Asynchronously fetches the daily quote.
///
/// This provider manages the state of the quote fetching operation,
/// returning a [Future] that resolves to a [Quote] object.
final quoteProvider = FutureProvider<Quote>((ref) async {
  final service = ref.watch(quoteServiceProvider);
  return service.fetchDailyQuote();
});

/// Service responsible for fetching inspirational quotes from an external API.
class QuoteService {
  final http.Client _client;
  static const _apiUrl = 'https://zenquotes.io/api/today';

  /// Creates a [QuoteService] with the injected HTTP client.
  QuoteService(this._client);

  /// Fetches the quote of the day from the remote API.
  ///
  /// Implements a fallback mechanism: if the API call fails due to network
  /// issues or returns a non-200 status code, a default [Quote.fallback]
  /// is returned to ensure the UI always has content to display.
  Future<Quote> fetchDailyQuote() async {
    try {
      Logger.debug('Initiating daily quote fetch from $_apiUrl');

      final response = await _client
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          Logger.info('Daily quote fetched successfully.');
          return Quote.fromJson(data[0]);
        }
      }

      Logger.warning(
        'Quote API returned status ${response.statusCode} or empty data. Using fallback.',
      );
      return Quote.fallback;
    } catch (e, stack) {
      // Log as a warning since this is a handled error that doesn't crash the app.
      Logger.warning(
        'Failed to fetch daily quote (Network/Timeout). Returning fallback.',
        e,
        stack,
      );
      return Quote.fallback;
    }
  }
}