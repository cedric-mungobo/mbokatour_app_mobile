import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static const String _defaultBaseUrl = 'https://mbokatour.com/api';

  // API key (Postman: X-API-Key)
  static const String apiKeyHeader = 'X-API-Key';
  static String get apiKey => dotenv.env['API_KEY'] ?? '';
  static String get baseUrl {
    final raw = dotenv.env['BASE_URL'] ?? _defaultBaseUrl;
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  // Préfixe API
  static String get apiPrefix => baseUrl.endsWith('/api') ? '' : '/api';

  // Endpoints
  static String get places => '$apiPrefix/places';
  static String get placeSearch => '$apiPrefix/places/search';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
