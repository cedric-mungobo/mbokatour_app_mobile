import '../../domain/entities/category_entity.dart';

class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    super.icon,
    required super.placesCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      icon: json['icon']?.toString(),
      placesCount: int.tryParse(json['places_count'].toString()) ?? 0,
    );
  }
}
