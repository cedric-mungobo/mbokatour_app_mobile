import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/services/dio_service.dart';
import '../../domain/entities/place_entity.dart';
import '../models/place_model.dart';

class PaginatedPlacesResult {
  final List<PlaceEntity> places;
  final int currentPage;
  final int lastPage;

  const PaginatedPlacesResult({
    required this.places,
    required this.currentPage,
    required this.lastPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class PlaceRepositoryImpl {
  final DioService _dioService;

  PlaceRepositoryImpl({required DioService dioService})
    : _dioService = dioService;

  Future<List<PlaceEntity>> getPlaces() async {
    final result = await getPlacesPage(page: 1);
    return result.places;
  }

  Future<PaginatedPlacesResult> getPlacesPage({
    required int page,
    String query = '',
  }) async {
    try {
      final isSearch = query.trim().isNotEmpty;
      final response = await _dioService.get(
        isSearch ? ApiConstants.placeSearch : ApiConstants.places,
        queryParameters: {'page': page, if (isSearch) 'q': query.trim()},
      );
      final payload = _asMap(response.data);
      final List<dynamic> data = _extractPlaces(payload);
      final meta = _extractPaginationMeta(payload, fallbackPage: page);

      return PaginatedPlacesResult(
        places: data.map((json) => PlaceModel.fromJson(json)).toList(),
        currentPage: meta.currentPage,
        lastPage: meta.lastPage,
      );
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
    final result = await getPlacesPage(page: 1, query: query);
    return result.places;
  }

  Future<List<PlaceEntity>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int page = 1,
  }) async {
    final query = <String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'radius': radiusKm,
      'page': page,
    };

    try {
      final response = await _dioService.get(
        ApiConstants.placeNearby,
        queryParameters: query,
      );
      final payload = _asMap(response.data);
      final data = _extractPlaces(payload);
      if (data.isNotEmpty) {
        return data.map((json) => PlaceModel.fromJson(json)).toList();
      }
    } catch (_) {
      // Fallback below for API variants in older deployments.
    }

    try {
      final fallbackResponse = await _dioService.get(
        ApiConstants.places,
        queryParameters: query,
      );
      final payload = _asMap(fallbackResponse.data);
      final data = _extractPlaces(payload);
      return data.map((json) => PlaceModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des lieux proches: $e');
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

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) return payload;
    return const <String, dynamic>{};
  }

  _PaginationMeta _extractPaginationMeta(
    Map<String, dynamic> payload, {
    required int fallbackPage,
  }) {
    final rawMeta = payload['meta'];
    if (rawMeta is Map<String, dynamic>) {
      final currentPage = _asInt(rawMeta['current_page']) ?? fallbackPage;
      final lastPage = _asInt(rawMeta['last_page']) ?? currentPage;
      return _PaginationMeta(
        currentPage: currentPage,
        lastPage: lastPage < 1 ? 1 : lastPage,
      );
    }

    return _PaginationMeta(currentPage: fallbackPage, lastPage: fallbackPage);
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
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

class _PaginationMeta {
  final int currentPage;
  final int lastPage;

  const _PaginationMeta({required this.currentPage, required this.lastPage});
}
