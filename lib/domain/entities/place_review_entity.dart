import 'package:equatable/equatable.dart';

class PlaceReviewUserEntity extends Equatable {
  final String id;
  final String? name;
  final String? avatar;

  const PlaceReviewUserEntity({required this.id, this.name, this.avatar});

  @override
  List<Object?> get props => [id, name, avatar];
}

class PlaceReviewEntity extends Equatable {
  final String id;
  final String placeId;
  final PlaceReviewUserEntity? user;
  final String comment;
  final DateTime? createdAt;

  const PlaceReviewEntity({
    required this.id,
    required this.placeId,
    this.user,
    required this.comment,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, placeId, user, comment, createdAt];
}
