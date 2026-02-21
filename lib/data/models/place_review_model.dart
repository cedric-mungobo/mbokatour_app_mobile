import '../../domain/entities/place_review_entity.dart';

class PlaceReviewUserModel extends PlaceReviewUserEntity {
  const PlaceReviewUserModel({required super.id, super.name, super.avatar});

  factory PlaceReviewUserModel.fromJson(Map<String, dynamic> json) {
    return PlaceReviewUserModel(
      id: PlaceReviewModel._asString(json['id']) ?? '',
      name: PlaceReviewModel._asString(json['name']),
      avatar: PlaceReviewModel._asString(json['avatar']),
    );
  }
}

class PlaceReviewModel extends PlaceReviewEntity {
  const PlaceReviewModel({
    required super.id,
    required super.placeId,
    super.user,
    required super.comment,
    super.createdAt,
  });

  factory PlaceReviewModel.fromJson(Map<String, dynamic> json) {
    final userJson = _asMap(json['user']);
    return PlaceReviewModel(
      id: _asString(json['id']) ?? '',
      placeId: _asString(json['place_id']) ?? '',
      user: userJson.isEmpty ? null : PlaceReviewUserModel.fromJson(userJson),
      comment: _asString(json['comment']) ?? '',
      createdAt: _asDateTime(_asString(json['created_at'])),
    );
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _asDateTime(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }
}
