import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/dio_service.dart';
import '../../domain/entities/place_entity.dart';
import '../models/place_model.dart';

class PlaceRepositoryImpl {
  final DioService _dioService;

  PlaceRepositoryImpl({required DioService dioService})
    : _dioService = dioService;

  Future<List<PlaceEntity>> getPlaces() async {
    try {
      final response = await _dioService.get(ApiConstants.places);
      final List<dynamic> data = _extractPlaces(response.data);

      return data.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des lieux: $e');
    }
  }

  Future<PlaceEntity> getPlaceById(String id) async {
    try {
      if (kDebugMode) {
        debugPrint('PLACE GET_BY_ID => id=$id');
      }
      final response = await _dioService.get('${ApiConstants.places}/$id');
      if (kDebugMode) {
        _logChunks('PLACE GET_BY_ID RESPONSE', response.data);
      }
      final place = PlaceModel.fromJson(_extractPlace(response.data));
      if (kDebugMode) {
        debugPrint(
          'PLACE GET_BY_ID OK => id=${place.id}, '
          'name=${place.name}, media=${place.media.length}',
        );
      }
      return place;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du lieu: $e');
    }
  }

  Future<List<PlaceEntity>> searchPlaces(String query) async {
    try {
      final response = await _dioService.get(
        ApiConstants.placeSearch,
        queryParameters: {'q': query},
      );
      final List<dynamic> data = _extractPlaces(response.data);

      return data.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de lieux: $e');
    }
  }

  List<dynamic> _extractPlaces(dynamic payload) {
    if (payload is! Map<String, dynamic>) return const [];

    if (payload['data'] is List) {
      return payload['data'] as List<dynamic>;
    }
    if (payload['places'] is List) {
      return payload['places'] as List<dynamic>;
    }

    return const [];
  }

  Map<String, dynamic> _extractPlace(dynamic payload) {
    if (payload is! Map<String, dynamic>) {
      throw Exception('Format de réponse invalide');
    }

    if (payload['data'] is Map<String, dynamic>) {
      return payload['data'] as Map<String, dynamic>;
    }
    if (payload['place'] is Map<String, dynamic>) {
      return payload['place'] as Map<String, dynamic>;
    }

    throw Exception('Lieu introuvable dans la réponse API');
  }

  void _logChunks(String label, dynamic payload) {
    final text = payload?.toString() ?? 'null';
    const chunkSize = 700;
    for (var i = 0; i < text.length; i += chunkSize) {
      final end = (i + chunkSize < text.length) ? i + chunkSize : text.length;
      debugPrint('$label [${(i ~/ chunkSize) + 1}]: ${text.substring(i, end)}');
    }
  }
}
