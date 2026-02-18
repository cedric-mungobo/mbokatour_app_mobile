import 'package:equatable/equatable.dart';

class PlaceMedia extends Equatable {
  final String id;
  final String url;
  final String type; // photo | video
  final bool isPrimary;

  const PlaceMedia({
    required this.id,
    required this.url,
    required this.type,
    this.isPrimary = false,
  });

  bool get isVideo => type.toLowerCase() == 'video';
  bool get isPhoto => type.toLowerCase() == 'photo';

  @override
  List<Object?> get props => [id, url, type, isPrimary];
}

class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final double? rating;
  final String? category;
  final bool hasVideo;
  final List<PlaceMedia> media;

  const PlaceEntity({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.rating,
    this.category,
    this.hasVideo = false,
    this.media = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    videoUrl,
    latitude,
    longitude,
    address,
    rating,
    category,
    hasVideo,
    media,
  ];
}
