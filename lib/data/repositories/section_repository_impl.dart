import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/dio_service.dart';
import '../../domain/entities/section_entity.dart';
import '../models/section_model.dart';

class SectionRepositoryImpl {
  final DioService _dioService;

  SectionRepositoryImpl({required DioService dioService})
    : _dioService = dioService;

  Future<List<SectionEntity>> getSections() async {
    try {
      final response = await _dioService.get(ApiConstants.sections);
      final body = response.data;
      if (body is! Map<String, dynamic>) return const [];
      final data = body['data'];
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((item) => SectionModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors du chargement des sections: $e');
    }
  }

  Future<SectionEntity> getSectionBySlug(String slug) async {
    try {
      final response = await _dioService.get(ApiConstants.sectionBySlug(slug));
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw Exception('Format invalide');
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Section introuvable');
      }
      return SectionModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Section non trouvée');
      }
      throw Exception('Erreur lors du chargement de la section: $e');
    } catch (e) {
      throw Exception('Erreur lors du chargement de la section: $e');
    }
  }
}
