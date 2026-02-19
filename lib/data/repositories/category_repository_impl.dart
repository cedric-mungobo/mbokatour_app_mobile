import '../../core/services/dio_service.dart';
import '../../domain/entities/category_entity.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl {
  final DioService _dioService;

  CategoryRepositoryImpl({required DioService dioService})
    : _dioService = dioService;

  Future<List<CategoryEntity>> getCategories() async {
    try {
      final response = await _dioService.get('/categories');
      final body = response.data;
      if (body is! Map<String, dynamic>) return const [];

      final data = body['data'];
      if (data is! List) return const [];

      return data
          .whereType<Map<String, dynamic>>()
          .map(CategoryModel.fromJson)
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  Future<List<int>> getUserPreferenceCategoryIds() async {
    try {
      final response = await _dioService.get('/auth/preferences');
      final body = response.data;
      if (body is! Map<String, dynamic>) return const [];

      final data = body['data'];
      if (data is! Map<String, dynamic>) return const [];
      final preferences = data['preferences'];
      if (preferences is! Map<String, dynamic>) return const [];
      final categoryIds = preferences['category_ids'];
      if (categoryIds is! List) return const [];

      return categoryIds
          .map((id) => int.tryParse(id.toString()))
          .whereType<int>()
          .toSet()
          .toList()
        ..sort();
    } catch (e) {
      throw Exception('Erreur lors du chargement des préférences: $e');
    }
  }

  Future<void> saveUserPreferences(List<int> categoryIds) async {
    try {
      final normalized = categoryIds.toSet().toList()..sort();
      final response = await _dioService.post(
        '/auth/preferences',
        data: {'category_ids': normalized},
      );
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        throw Exception(body is Map<String, dynamic> ? body['message'] : null);
      }
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des préférences: $e');
    }
  }
}
