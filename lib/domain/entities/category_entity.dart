class CategoryEntity {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final int placesCount;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    required this.placesCount,
  });
}
