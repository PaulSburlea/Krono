import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../utils/logger_service.dart';

/// Provides a singleton instance of the [WeatherService].
final weatherServiceProvider =
Provider<WeatherService>((ref) => WeatherService());

/// A simple data model representing the displayable weather conditions.
class WeatherData {
  /// The formatted temperature string (e.g., "25°C, Sunny").
  final String temperature;

  /// The icon code provided by the API, used to resolve the weather image asset.
  final String iconCode;

  const WeatherData({required this.temperature, required this.iconCode});
}

/// Service responsible for fetching real-time weather data.
///
/// Integrates with the OpenWeatherMap API to retrieve current conditions
/// based on geographic coordinates. Requires an API key to be injected
/// via the `--dart-define=OPEN_WEATHER_API_KEY=...` build flag.
class WeatherService {
  static const String _baseUrl =
      'https://api.openweathermap.org/data/2.5/weather';

  /// The API key retrieved from the build environment.
  static const String _apiKey = String.fromEnvironment('OPEN_WEATHER_API_KEY');

  /// Fetches the current weather conditions for the specified coordinates.
  ///
  /// This method constructs the API request using the [lat], [lon], and [langCode].
  /// It handles HTTP errors and network connectivity issues, logging failures
  /// to Crashlytics for analysis.
  ///
  /// Throws an [HttpException] if the API key is missing or the server returns an error.
  /// Throws a [SocketException] if there is no internet connection.
  Future<WeatherData> fetchWeather({
    required double lat,
    required double lon,
    required String langCode,
    http.Client? client, // Dependency Injection for testing
  }) async {
    // Validate configuration before attempting the request.
    if (_apiKey.isEmpty) {
      const error = HttpException('Missing API Key');
      Logger.error(
        'WeatherService configuration error: OPEN_WEATHER_API_KEY is not defined.',
        error,
        StackTrace.current,
      );
      throw error;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=$langCode',
      );

      Logger.debug('Fetching weather data for coordinates: $lat, $lon');

      // Use the injected client or fallback to the default http client.
      final response = await (client ?? http.Client()).get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = (data['main']['temp'] as num).round();
        final description = data['weather'][0]['description'] as String;
        final icon = data['weather'][0]['icon'] as String;

        // Capitalize the first letter of the description for display consistency.
        final formattedDesc = description.isNotEmpty
            ? "${description[0].toUpperCase()}${description.substring(1)}"
            : description;

        Logger.info('Weather successfully fetched: $temp°C, $formattedDesc');

        return WeatherData(
          temperature: "$temp°C, $formattedDesc",
          iconCode: icon,
        );
      } else {
        final errorMsg = 'Weather API Error: ${response.statusCode} - ${response.body}';
        Logger.error(
          'Weather API returned a non-200 status code.',
          HttpException(errorMsg),
          StackTrace.current,
        );
        throw HttpException('Weather API Error: ${response.statusCode}');
      }
    } on SocketException catch (e, stack) {
      // Log as a warning since network issues are expected and recoverable.
      Logger.warning('Failed to fetch weather due to network issues.', e, stack);
      throw const SocketException('No internet connection');
    } catch (e, stack) {
      Logger.error('Unexpected error during weather fetch', e, stack);
      rethrow;
    }
  }
}