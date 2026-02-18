import 'package:equatable/equatable.dart';

class PlacePrice extends Equatable {
  final String id;
  final String label;
  final String? price;
  final String? currency;
  final String? description;

  const PlacePrice({
    required this.id,
    required this.label,
    this.price,
    this.currency,
    this.description,
  });

  @override
  List<Object?> get props => [id, label, price, currency, description];
}

class PlaceStats extends Equatable {
  final int likesCount;
  final int visitsCount;
  final int reviewsCount;
  final int favoritesCount;

  const PlaceStats({
    this.likesCount = 0,
    this.visitsCount = 0,
    this.reviewsCount = 0,
    this.favoritesCount = 0,
  });

  @override
  List<Object?> get props => [
    likesCount,
    visitsCount,
    reviewsCount,
    favoritesCount,
  ];
}

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
  bool get canPlayVideo => isVideo && _isLikelyVideoUrl(url);

  static bool _isLikelyVideoUrl(String value) {
    final lower = value.toLowerCase();
    return lower.contains('/video/upload/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.mkv');
  }

  @override
  List<Object?> get props => [id, url, type, isPrimary];
}

class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String? slug;
  final String description;
  final String? imageUrl;
  final String? videoUrl;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? city;
  final String? commune;
  final String? phone;
  final String? whatsapp;
  final String? website;
  final Map<String, String> openingHours;
  final double? rating;
  final String? category;
  final List<String> categories;
  final bool isActive;
  final bool isVerified;
  final bool isRecommended;
  final List<PlacePrice> prices;
  final PlaceStats stats;
  final double? distance;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasVideo;
  final List<PlaceMedia> media;

  const PlaceEntity({
    required this.id,
    required this.name,
    this.slug,
    required this.description,
    this.imageUrl,
    this.videoUrl,
    this.latitude,
    this.longitude,
    this.address,
    this.city,
    this.commune,
    this.phone,
    this.whatsapp,
    this.website,
    this.openingHours = const {},
    this.rating,
    this.category,
    this.categories = const [],
    this.isActive = true,
    this.isVerified = false,
    this.isRecommended = false,
    this.prices = const [],
    this.stats = const PlaceStats(),
    this.distance,
    this.createdAt,
    this.updatedAt,
    this.hasVideo = false,
    this.media = const [],
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    imageUrl,
    videoUrl,
    latitude,
    longitude,
    address,
    city,
    commune,
    phone,
    whatsapp,
    website,
    openingHours,
    rating,
    category,
    categories,
    isActive,
    isVerified,
    isRecommended,
    prices,
    stats,
    distance,
    createdAt,
    updatedAt,
    hasVideo,
    media,
  ];
}
