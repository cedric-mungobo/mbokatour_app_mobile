import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:dio/dio.dart';
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
  Future<void>? _placesRequestInFlight;
  final Map<String, Future<void>> _placeRequestInFlight = {};
  final Map<String, PlaceEntity> _placeByIdCache = {};
  final Map<String, DateTime> _placeByIdFetchedAt = {};
  String _lastPlacesQuery = '';
  DateTime? _lastPlacesFetchedAt;

  static const Duration _memoryCacheTtl = Duration(minutes: 2);

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

  Future<void> loadPlaces({
    String query = '',
    bool forceRefresh = false,
  }) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;
    final normalizedQuery = query.trim();

    final isRecentPlacesCache =
        _lastPlacesFetchedAt != null &&
        DateTime.now().difference(_lastPlacesFetchedAt!) < _memoryCacheTtl;
    final canUsePlacesCache =
        !forceRefresh &&
        normalizedQuery == _lastPlacesQuery &&
        places.value.isNotEmpty &&
        isRecentPlacesCache;
    if (canUsePlacesCache) {
      return;
    }

    if (_placesRequestInFlight != null) {
      return _placesRequestInFlight!;
    }

    final task = () async {
      isPlacesLoading.value = true;
      errorMessage.value = null;

      try {
        final data = normalizedQuery.isEmpty
            ? await repository.getPlaces()
            : await repository.searchPlaces(normalizedQuery);
        places.value = data;
        _lastPlacesQuery = normalizedQuery;
        _lastPlacesFetchedAt = DateTime.now();
      } catch (e) {
        errorMessage.value = _buildLoadPlacesErrorMessage(e);
      } finally {
        isPlacesLoading.value = false;
        _placesRequestInFlight = null;
      }
    }();

    _placesRequestInFlight = task;
    return task;
  }

  Future<void> loadPlaceById(String id, {bool forceRefresh = false}) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;
    final normalizedId = id.trim();
    if (normalizedId.isEmpty) return;

    final cachedPlace = _placeByIdCache[normalizedId];
    final fetchedAt = _placeByIdFetchedAt[normalizedId];
    final isRecentDetailsCache =
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt) < _memoryCacheTtl;
    if (!forceRefresh && cachedPlace != null && isRecentDetailsCache) {
      selectedPlace.value = cachedPlace;
      return;
    }

    final inFlight = _placeRequestInFlight[normalizedId];
    if (inFlight != null) {
      return inFlight;
    }

    final task = () async {
      isPlaceLoading.value = true;
      errorMessage.value = null;

      try {
        final place = await repository.getPlaceById(normalizedId);
        selectedPlace.value = place;
        _placeByIdCache[normalizedId] = place;
        _placeByIdFetchedAt[normalizedId] = DateTime.now();
      } catch (e) {
        selectedPlace.value = null;
        errorMessage.value = _buildLoadPlaceErrorMessage(e);
      } finally {
        isPlaceLoading.value = false;
        _placeRequestInFlight.remove(normalizedId);
      }
    }();

    _placeRequestInFlight[normalizedId] = task;
    return task;
  }

  String _buildLoadPlacesErrorMessage(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('timeout')) {
      return 'Le serveur met trop de temps à répondre. Vérifiez votre connexion puis réessayez.';
    }
    if (error is DioException &&
        error.type == DioExceptionType.connectionError) {
      return 'Connexion impossible au serveur. Vérifiez internet puis réessayez.';
    }
    return 'Erreur lors du chargement des lieux.';
  }

  String _buildLoadPlaceErrorMessage(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('timeout')) {
      return 'Le détail du lieu a expiré (timeout). Réessayez.';
    }
    if (error is DioException &&
        error.type == DioExceptionType.connectionError) {
      return 'Connexion impossible au serveur pour charger ce lieu.';
    }
    return 'Erreur lors du chargement du lieu.';
  }
}
