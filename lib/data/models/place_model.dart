import '../../domain/entities/place_entity.dart';

class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.description,
    super.imageUrl,
    super.videoUrl,
    super.latitude,
    super.longitude,
    super.address,
    super.rating,
    super.category,
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

    String? category = json['category'] as String?;
    if (category == null && categories is List && categories.isNotEmpty) {
      final firstCategory = categories.first;
      if (firstCategory is Map<String, dynamic>) {
        category = firstCategory['name'] as String?;
      }
    }

    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'] as String,
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
      rating: json['rating'] != null
          ? (json['rating'] as num).toDouble()
          : json['average_rating'] != null
          ? (json['average_rating'] as num).toDouble()
          : null,
      category: category,
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

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    return raw.isEmpty ? null : raw;
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
