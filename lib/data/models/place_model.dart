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
    final primary = _primaryMedia(media);

    String? imageUrl = primary?.url ?? _asString(json['image_url']);
    String? videoUrl = primary?.isVideo == true ? primary?.url : null;
    imageUrl ??= _extractPrimaryPhoto(media)?.url;
    videoUrl ??= _extractPrimaryVideo(media)?.url;

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
      hasVideo: media.any((m) => m.isVideo),
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

      final url = _asString(item['image_url']);
      if (url == null) continue;

      output.add(
        PlaceMedia(
          id: item['id'].toString(),
          url: url,
          type: type,
          isPrimary: item['is_primary'] == true,
        ),
      );
    }
    return output;
  }

  static PlaceMedia? _primaryMedia(List<PlaceMedia> media) {
    if (media.isEmpty) return null;
    return media.firstWhere((m) => m.isPrimary, orElse: () => media.first);
  }

  static PlaceMedia? _extractPrimaryPhoto(List<PlaceMedia> media) {
    final photos = media.where((m) => m.isPhoto).toList();
    if (photos.isEmpty) return null;
    return photos.firstWhere((m) => m.isPrimary, orElse: () => photos.first);
  }

  static PlaceMedia? _extractPrimaryVideo(List<PlaceMedia> media) {
    final videos = media.where((m) => m.isVideo).toList();
    if (videos.isEmpty) return null;
    return videos.firstWhere((m) => m.isPrimary, orElse: () => videos.first);
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    return raw.isEmpty ? null : raw;
  }
}
