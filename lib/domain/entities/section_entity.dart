import 'package:equatable/equatable.dart';
import 'place_entity.dart';

class SectionEntity extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int sortOrder;
  final int placesCount;
  final List<PlaceEntity> places;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SectionEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.isActive = true,
    this.sortOrder = 0,
    this.placesCount = 0,
    this.places = const [],
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    isActive,
    sortOrder,
    placesCount,
    places,
    createdAt,
    updatedAt,
  ];
}
