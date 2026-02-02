import 'package:flutter/foundation.dart';

/// A domain model representing an inspirational quote.
///
/// This class is used to display daily motivation to the user, typically fetched
/// from an external API (e.g., ZenQuotes).
@immutable
class Quote {
  /// The actual text content of the quote.
  final String text;

  /// The name of the author attributed to the quote.
  final String author;

  /// Creates a constant [Quote] instance.
  const Quote({required this.text, required this.author});

  /// Creates a [Quote] instance from a JSON map.
  ///
  /// Designed to parse responses from the ZenQuotes API, where 'q' represents
  /// the quote text and 'a' represents the author.
  ///
  /// Returns a valid object with default values if specific keys are missing,
  /// ensuring the UI does not crash on malformed data.
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['q'] as String? ?? '',
      author: json['a'] as String? ?? 'Unknown',
    );
  }

  /// A fallback quote used when the network is unavailable or the API fails.
  static const fallback = Quote(
    text: "The best way to predict the future is to create it.",
    author: "Peter Drucker",
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Quote &&
              runtimeType == other.runtimeType &&
              text == other.text &&
              author == other.author;

  @override
  int get hashCode => text.hashCode ^ author.hashCode;

  @override
  String toString() => 'Quote(text: $text, author: $author)';
}