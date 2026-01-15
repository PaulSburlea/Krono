import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final quoteProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final response = await http
        .get(Uri.parse('https://zenquotes.io/api/today'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        return {
          'q': data[0]['q'],
          'a': data[0]['a'],
        };
      }
    }
    throw Exception();
  } catch (e) {
    return {
      'q': "The best way to predict the future is to create it.",
      'a': "Peter Drucker"
    };
  }
});