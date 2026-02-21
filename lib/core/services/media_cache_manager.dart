import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MediaCacheManager {
  MediaCacheManager._();

  static const String _cacheKey = 'mbokatour_media_cache_v1';
  static const Duration stalePeriod = Duration(days: 14);
  static const int maxNrOfCacheObjects = 300;

  static final CacheManager instance = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: stalePeriod,
      maxNrOfCacheObjects: maxNrOfCacheObjects,
    ),
  );

  static Future<void> clearAll() => instance.emptyCache();
}
