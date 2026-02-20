import '../../domain/entities/section_entity.dart';
import '../../domain/entities/place_entity.dart';
import 'place_model.dart';

class SectionModel extends SectionEntity {
  const SectionModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.description,
    super.isActive = true,
    super.sortOrder = 0,
    super.placesCount = 0,
    super.places = const [],
    super.createdAt,
    super.updatedAt,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    final places = _extractPlaces(json['places']);
    return SectionModel(
      id: (json['id'] ?? '').toString(),
      name: _asString(json['name']) ?? '',
      slug: _asString(json['slug']) ?? '',
      description: _asString(json['description']) ?? '',
      isActive: json['is_active'] != false,
      sortOrder: _asInt(json['sort_order']),
      placesCount: _asInt(json['places_count']),
      places: places,
      createdAt: _asDateTime(json['created_at']),
      updatedAt: _asDateTime(json['updated_at']),
    );
  }

  static List<PlaceEntity> _extractPlaces(dynamic raw) {
    if (raw is! List) return const [];
    final output = <PlaceEntity>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      output.add(PlaceModel.fromJson(_normalizePlaceJson(map)));
    }
    return output;
  }

  static Map<String, dynamic> _normalizePlaceJson(Map<String, dynamic> raw) {
    final map = Map<String, dynamic>.from(raw);
    final primaryMedia = raw['primary_media'];
    if (primaryMedia is Map) {
      final mediaMap = Map<String, dynamic>.from(primaryMedia);
      final type = _asString(mediaMap['type'])?.toLowerCase();
      final imageUrl = _asString(mediaMap['image_url']);
      if (type == 'video') {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          map['video_url'] = imageUrl;
        }
      } else {
        if (imageUrl != null && imageUrl.isNotEmpty) {
          map['image_url'] = imageUrl;
        }
      }
    }
    return map;
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

  static DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
