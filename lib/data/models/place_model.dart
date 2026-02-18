import '../../domain/entities/place_entity.dart';

class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.id,
    required super.name,
    super.slug,
    required super.description,
    super.imageUrl,
    super.videoUrl,
    super.latitude,
    super.longitude,
    super.address,
    super.city,
    super.commune,
    super.phone,
    super.whatsapp,
    super.website,
    super.openingHours = const {},
    super.rating,
    super.category,
    super.categories = const [],
    super.isActive = true,
    super.isVerified = false,
    super.isRecommended = false,
    super.prices = const [],
    super.stats = const PlaceStats(),
    super.distance,
    super.createdAt,
    super.updatedAt,
    super.hasVideo = false,
    super.media = const [],
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'];
    final media = _extractMedia(rawMedia);
    final categories = json['categories'];
    final primaryPhoto = _extractPrimaryPhoto(media);
    final primaryVideo = _extractPrimaryVideo(media);

    String? imageUrl = primaryPhoto?.url ?? _asString(json['image_url']);
    if (imageUrl != null && !_isLikelyImageUrl(imageUrl)) {
      imageUrl = null;
    }

    String? videoUrl = primaryVideo?.url ?? _asString(json['video_url']);
    if (videoUrl != null && !_isLikelyVideoUrl(videoUrl)) {
      videoUrl = null;
    }

    final categoryNames = _extractCategoryNames(categories);
    String? category = json['category'] as String?;
    category ??= categoryNames.isNotEmpty ? categoryNames.first : null;

    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: _asString(json['slug']),
      description: (json['description'] as String?) ?? '',
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      hasVideo: media.any((m) => m.canPlayVideo),
      latitude: json['lat'] != null
          ? (json['lat'] as num).toDouble()
          : json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['lng'] != null
          ? (json['lng'] as num).toDouble()
          : json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      address: json['address'] as String?,
      city: _asString(json['ville']) ?? _asString(json['city']),
      commune: _asString(json['commune']),
      phone: _asString(json['phone']),
      whatsapp: _asString(json['whatsapp']),
      website: _asString(json['website']),
      openingHours: _extractOpeningHours(json['opening_hours']),
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      category: category,
      categories: categoryNames,
      isActive: json['is_active'] == true,
      isVerified: json['is_verified'] == true,
      isRecommended: json['is_recommended'] == true,
      prices: _extractPrices(json['prices']),
      stats: _extractStats(json['stats']),
      distance: _asDouble(json['distance']),
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
      media: media,
    );
  }

  static List<PlaceMedia> _extractMedia(dynamic rawMedia) {
    if (rawMedia is! List) return const [];

    final output = <PlaceMedia>[];
    for (final item in rawMedia) {
      if (item is! Map) continue;

      final type = (item['type'] ?? 'photo').toString().toLowerCase();
      if (type != 'photo' && type != 'video') continue;

      final itemMap = Map<String, dynamic>.from(item);
      final url = _resolveMediaUrl(itemMap, type);
      if (url == null) continue;

      output.add(
        PlaceMedia(
          id: itemMap['id'].toString(),
          url: url,
          type: type,
          isPrimary: itemMap['is_primary'] == true,
        ),
      );
    }
    return output;
  }

  static PlaceMedia? _extractPrimaryPhoto(List<PlaceMedia> media) {
    final photos = media.where((m) => m.isPhoto).toList();
    if (photos.isEmpty) return null;
    return photos.firstWhere((m) => m.isPrimary, orElse: () => photos.first);
  }

  static PlaceMedia? _extractPrimaryVideo(List<PlaceMedia> media) {
    final videos = media.where((m) => m.canPlayVideo).toList();
    if (videos.isEmpty) return null;
    return videos.firstWhere((m) => m.isPrimary, orElse: () => videos.first);
  }

  static String? _resolveMediaUrl(Map<String, dynamic> item, String type) {
    if (type == 'video') {
      return _asString(item['video_url']) ??
          _asString(item['url']) ??
          _asString(item['file_url']) ??
          _asString(item['image_url']);
    }
    return _asString(item['image_url']) ??
        _asString(item['url']) ??
        _asString(item['thumbnail_url']);
  }

  static List<String> _extractCategoryNames(dynamic rawCategories) {
    if (rawCategories is! List) return const [];
    final names = <String>[];
    for (final category in rawCategories) {
      if (category is! Map) continue;
      final map = Map<String, dynamic>.from(category);
      final name = _asString(map['name']);
      if (name != null) {
        names.add(name);
      }
    }
    return names;
  }

  static Map<String, String> _extractOpeningHours(dynamic rawOpeningHours) {
    if (rawOpeningHours is! Map) return const {};
    final map = <String, String>{};
    rawOpeningHours.forEach((key, value) {
      final hour = _asString(value);
      if (hour != null) {
        map[key.toString()] = hour;
      }
    });
    return map;
  }

  static List<PlacePrice> _extractPrices(dynamic rawPrices) {
    if (rawPrices is! List) return const [];
    final output = <PlacePrice>[];
    for (final item in rawPrices) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      output.add(
        PlacePrice(
          id: map['id'].toString(),
          label: _asString(map['label']) ?? 'Tarif',
          price: _asString(map['price']),
          currency: _asString(map['currency']),
          description: _asString(map['description']),
        ),
      );
    }
    return output;
  }

  static PlaceStats _extractStats(dynamic rawStats) {
    if (rawStats is! Map) return const PlaceStats();
    final map = Map<String, dynamic>.from(rawStats);
    return PlaceStats(
      likesCount: _asInt(map['likes_count']),
      visitsCount: _asInt(map['visits_count']),
      reviewsCount: _asInt(map['reviews_count']),
      favoritesCount: _asInt(map['favorites_count']),
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    return raw.isEmpty ? null : raw;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static DateTime? _asDateTime(dynamic value) {
    final text = _asString(value);
    if (text == null) return null;
    return DateTime.tryParse(text);
  }

  static bool _isLikelyImageUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('/image/upload/') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  static bool _isLikelyVideoUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('/video/upload/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv');
  }
}
