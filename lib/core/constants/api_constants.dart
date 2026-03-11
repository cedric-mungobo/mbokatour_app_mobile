import 'app_config.dart';

class ApiConstants {
  // API key (Postman: X-API-Key)
  static const String apiKeyHeader = 'X-API-Key';
  static String get apiKey => AppConfig.apiKey.trim();
  static String get baseUrl {
    final raw = AppConfig.baseUrl.trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  // Préfixe API
  static String get apiPrefix => baseUrl.endsWith('/api') ? '' : '/api';

  // Endpoints
  static String get places => '$apiPrefix/places';
  static String get placeSearch => '$apiPrefix/places/search';
  static String get placeNearby => '$apiPrefix/places/nearby';
  static String placeLike(String placeId) => '$apiPrefix/places/$placeId/like';
  static String placeFavorite(String placeId) =>
      '$apiPrefix/places/$placeId/favorite';
  static String placeReviews(String placeId) =>
      '$apiPrefix/places/$placeId/reviews';
  static String get reviews => '$apiPrefix/reviews';
  static String get favorites => '$apiPrefix/favorites';
  static String get visits => '$apiPrefix/visits';
  static String get sections => '$apiPrefix/sections';
  static String sectionBySlug(String slug) => '$sections/$slug';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 45);
  static const Duration receiveTimeout = Duration(seconds: 45);
}
