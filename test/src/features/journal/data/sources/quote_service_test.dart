import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:krono/src/features/journal/data/sources/quote_service.dart';
import 'package:krono/src/features/journal/domain/models/quote.dart';

// Generate a MockClient for the http package
@GenerateMocks([http.Client])
import 'quote_service_test.mocks.dart';

void main() {
  late QuoteService quoteService;
  late MockClient mockHttpClient;

  setUp(() {
    mockHttpClient = MockClient();
    quoteService = QuoteService(mockHttpClient);
  });

  group('Production Tests for QuoteService', () {
    const tApiUrl = 'https://zenquotes.io/api/today';

    test('fetchDailyQuote returns parsed Quote on 200 OK with valid data', () async {
      // Arrange
      final mockResponse = [
        {
          "q": "Test Quote Text",
          "a": "Test Author",
          "h": "..."
        }
      ];

      when(mockHttpClient.get(Uri.parse(tApiUrl)))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      // Act
      final result = await quoteService.fetchDailyQuote();

      // Assert
      expect(result.text, "Test Quote Text");
      expect(result.author, "Test Author");
      verify(mockHttpClient.get(Uri.parse(tApiUrl))).called(1);
    });

    test('fetchDailyQuote returns Fallback Quote on non-200 status code (e.g. 404)', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse(tApiUrl)))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      // Act
      final result = await quoteService.fetchDailyQuote();

      // Assert
      expect(result, Quote.fallback);
    });

    test('fetchDailyQuote returns Fallback Quote on 200 OK but empty list', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse(tApiUrl)))
          .thenAnswer((_) async => http.Response('[]', 200));

      // Act
      final result = await quoteService.fetchDailyQuote();

      // Assert
      expect(result, Quote.fallback);
    });

    test('fetchDailyQuote returns Fallback Quote on Network Exception', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse(tApiUrl)))
          .thenThrow(http.ClientException('Network Error'));

      // Act
      final result = await quoteService.fetchDailyQuote();

      // Assert
      expect(result, Quote.fallback);
    });

    test('fetchDailyQuote returns Fallback Quote on Malformed JSON', () async {
      // Arrange
      when(mockHttpClient.get(Uri.parse(tApiUrl)))
          .thenAnswer((_) async => http.Response('{ not a list }', 200));

      // Act
      final result = await quoteService.fetchDailyQuote();

      // Assert
      expect(result, Quote.fallback);
    });
  });
}