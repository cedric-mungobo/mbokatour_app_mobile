import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../services/cache_service.dart';
import '../services/dio_service.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../domain/entities/place_entity.dart';

class PlaceStore {
  PlaceStore._();

  static final PlaceStore instance = PlaceStore._();

  final places = signal<List<PlaceEntity>>([]);
  final selectedPlace = signal<PlaceEntity?>(null);
  final isPlacesLoading = signal(false);
  final isPlaceLoading = signal(false);
  final errorMessage = signal<String?>(null);

  PlaceRepositoryImpl? _repository;
  Future<void>? _initializing;

  Future<void> init() async {
    if (_repository != null) return;
    if (_initializing != null) return _initializing!;

    _initializing = _initializeInternal();
    await _initializing;
    _initializing = null;
  }

  Future<void> _initializeInternal() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    final dioService = DioService(cacheService);
    _repository = PlaceRepositoryImpl(dioService: dioService);
  }

  Future<void> loadPlaces({String query = ''}) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    isPlacesLoading.value = true;
    errorMessage.value = null;

    try {
      final data = query.trim().isEmpty
          ? await repository.getPlaces()
          : await repository.searchPlaces(query.trim());
      places.value = data;
    } catch (e) {
      errorMessage.value = 'Erreur lors du chargement des lieux: $e';
    } finally {
      isPlacesLoading.value = false;
    }
  }

  Future<void> loadPlaceById(String id) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    isPlaceLoading.value = true;
    errorMessage.value = null;

    try {
      selectedPlace.value = await repository.getPlaceById(id);
    } catch (e) {
      selectedPlace.value = null;
      errorMessage.value = 'Erreur lors du chargement du lieu: $e';
    } finally {
      isPlaceLoading.value = false;
    }
  }
}
