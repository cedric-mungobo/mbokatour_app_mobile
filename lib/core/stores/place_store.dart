import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/storage_constants.dart';
import '../services/cache_service.dart';
import '../services/dio_service.dart';
import '../../data/models/place_model.dart';
import '../../data/repositories/place_repository_impl.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/entities/place_review_entity.dart';

class PlaceStore {
  PlaceStore._();

  static final PlaceStore instance = PlaceStore._();

  final places = signal<List<PlaceEntity>>([]);
  final nearbyPlaces = signal<List<PlaceEntity>>([]);
  final favoritePlaces = signal<List<PlaceEntity>>([]);
  final visitedPlaces = signal<List<PlaceEntity>>([]);
  final selectedPlace = signal<PlaceEntity?>(null);
  final isPlacesLoading = signal(false);
  final isNearbyPlacesLoading = signal(false);
  final isPlacesLoadingMore = signal(false);
  final isPlaceLoading = signal(false);
  final isFavoritePlacesLoading = signal(false);
  final isVisitedPlacesLoading = signal(false);
  final placeReviews = signal<List<PlaceReviewEntity>>([]);
  final isPlaceReviewsLoading = signal(false);
  final isSubmittingPlaceReview = signal(false);
  final isPlaceLiked = signal(false);
  final isPlaceFavorited = signal(false);
  final isTogglingPlaceLike = signal(false);
  final isTogglingPlaceFavorite = signal(false);
  final errorMessage = signal<String?>(null);
  final reviewErrorMessage = signal<String?>(null);
  final hasMorePlaces = signal(false);
  final isOffline = signal(false);

  PlaceRepositoryImpl? _repository;
  SharedPreferences? _prefs;
  Future<void>? _initializing;
  Future<void>? _placesRequestInFlight;
  Future<void>? _placesLoadMoreInFlight;
  final Map<String, Future<void>> _placeRequestInFlight = {};
  final Map<String, PlaceEntity> _placeByIdCache = {};
  final Map<String, DateTime> _placeByIdFetchedAt = {};
  String _lastPlacesQuery = '';
  String _lastPlacesCategory = '';
  DateTime? _lastPlacesFetchedAt;
  int _currentPlacesPage = 0;
  int _lastPlacesPage = 1;

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
    _prefs = prefs;
    final cacheService = CacheService(prefs);
    final dioService = DioService(cacheService);
    _repository = PlaceRepositoryImpl(dioService: dioService);
    _refreshFavoritePlacesFromLoadedLists();
  }

  Future<void> loadPlaces({
    String query = '',
    String? categorySlug,
    bool forceRefresh = false,
  }) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;
    final normalizedQuery = query.trim();
    final normalizedCategory = categorySlug?.trim() ?? '';

    final isRecentPlacesCache =
        _lastPlacesFetchedAt != null &&
        DateTime.now().difference(_lastPlacesFetchedAt!) < _memoryCacheTtl;
    final canUsePlacesCache =
        !forceRefresh &&
        normalizedQuery == _lastPlacesQuery &&
        normalizedCategory == _lastPlacesCategory &&
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
        final result = await repository.getPlacesPage(
          page: 1,
          query: normalizedQuery,
          categorySlug: normalizedCategory,
        );
        places.value = result.places;
        isOffline.value = false;
        _currentPlacesPage = result.currentPage;
        _lastPlacesPage = result.lastPage;
        hasMorePlaces.value = result.hasMore;
        _lastPlacesQuery = normalizedQuery;
        _lastPlacesCategory = normalizedCategory;
        _lastPlacesFetchedAt = DateTime.now();
        await _savePlacesToDiskCache(result.places);
        _refreshFavoritePlacesFromLoadedLists();
      } catch (e) {
        final hasNetworkIssue = _isNetworkIssue(e);
        isOffline.value = hasNetworkIssue;

        final restored = hasNetworkIssue
            ? await _tryLoadPlacesFromDiskCache()
            : false;
        if (restored) {
          errorMessage.value = null;
          hasMorePlaces.value = false;
          _lastPlacesQuery = normalizedQuery;
          _lastPlacesCategory = normalizedCategory;
          _lastPlacesFetchedAt = DateTime.now();
        } else {
          errorMessage.value = _buildLoadPlacesErrorMessage(e);
          hasMorePlaces.value = false;
        }
      } finally {
        isPlacesLoading.value = false;
        _placesRequestInFlight = null;
      }
    }();

    _placesRequestInFlight = task;
    return task;
  }

  Future<void> loadMorePlaces({String query = '', String? categorySlug}) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    final normalizedQuery = query.trim();
    final normalizedCategory = categorySlug?.trim() ?? '';
    if (isPlacesLoading.value || isPlacesLoadingMore.value) return;
    if (_placesLoadMoreInFlight != null) return _placesLoadMoreInFlight!;
    if (!hasMorePlaces.value) return;
    if (normalizedQuery != _lastPlacesQuery) return;
    if (normalizedCategory != _lastPlacesCategory) return;

    final nextPage = _currentPlacesPage + 1;
    if (nextPage > _lastPlacesPage) {
      hasMorePlaces.value = false;
      return;
    }

    final task = () async {
      isPlacesLoadingMore.value = true;
      try {
        final result = await repository.getPlacesPage(
          page: nextPage,
          query: normalizedQuery,
          categorySlug: normalizedCategory,
        );
        isOffline.value = false;
        final current = places.value;
        final merged = <PlaceEntity>[...current, ...result.places];
        // Avoid duplicates in case the API repeats items between pages.
        final deduped = <String, PlaceEntity>{};
        for (final place in merged) {
          deduped[place.id] = place;
        }
        places.value = deduped.values.toList();
        _currentPlacesPage = result.currentPage;
        _lastPlacesPage = result.lastPage;
        hasMorePlaces.value = result.hasMore;
        _refreshFavoritePlacesFromLoadedLists();
      } catch (e) {
        isOffline.value = _isNetworkIssue(e);
        errorMessage.value = _buildLoadPlacesErrorMessage(e);
      } finally {
        isPlacesLoadingMore.value = false;
        _placesLoadMoreInFlight = null;
      }
    }();

    _placesLoadMoreInFlight = task;
    return task;
  }

  Future<void> loadNearbyPlaces({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    String? categorySlug,
    int? categoryId,
  }) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    isNearbyPlacesLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await repository.getNearbyPlaces(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        categorySlug: categorySlug,
        categoryId: categoryId,
      );
      isOffline.value = false;
      nearbyPlaces.value = result;
      _refreshFavoritePlacesFromLoadedLists();
    } catch (e) {
      isOffline.value = _isNetworkIssue(e);
      nearbyPlaces.value = [];
      errorMessage.value = _buildLoadPlacesErrorMessage(e);
    } finally {
      isNearbyPlacesLoading.value = false;
    }
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
        isOffline.value = false;
        selectedPlace.value = place;
        _placeByIdCache[normalizedId] = place;
        _placeByIdFetchedAt[normalizedId] = DateTime.now();
        await _savePlaceDetailToDiskCache(place);
      } catch (e) {
        final hasNetworkIssue = _isNetworkIssue(e);
        isOffline.value = hasNetworkIssue;

        final restored = hasNetworkIssue
            ? await _tryLoadPlaceDetailFromDiskCache(normalizedId)
            : false;
        if (restored) {
          errorMessage.value = null;
        } else {
          selectedPlace.value = null;
          errorMessage.value = _buildLoadPlaceErrorMessage(e);
        }
      } finally {
        isPlaceLoading.value = false;
        _placeRequestInFlight.remove(normalizedId);
      }
    }();

    _placeRequestInFlight[normalizedId] = task;
    return task;
  }

  Future<void> loadPlaceReviews(String placeId) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty) return;

    isPlaceReviewsLoading.value = true;
    reviewErrorMessage.value = null;

    try {
      final reviews = await repository.getPlaceReviews(normalizedId);
      placeReviews.value = reviews;
      isOffline.value = false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        placeReviews.value = const [];
        return;
      }
      reviewErrorMessage.value = _buildLoadReviewsErrorMessage(e);
      isOffline.value = _isNetworkIssue(e);
    } finally {
      isPlaceReviewsLoading.value = false;
    }
  }

  Future<void> loadPlaceInteractionStates(String placeId) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty) return;

    try {
      final liked = await repository.isPlaceLiked(normalizedId);
      final favorited = await repository.isPlaceFavorited(normalizedId);
      isPlaceLiked.value = liked;
      isPlaceFavorited.value = favorited;
      isOffline.value = false;
    } catch (e) {
      isOffline.value = _isNetworkIssue(e);
    }
  }

  Future<bool> togglePlaceLike(String placeId) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return false;

    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty || isTogglingPlaceLike.value) return false;

    isTogglingPlaceLike.value = true;
    errorMessage.value = null;
    try {
      final previous = isPlaceLiked.value;
      final current = await repository.togglePlaceLike(normalizedId);
      isPlaceLiked.value = current;
      if (previous != current) {
        _updateSelectedPlaceStats(likesDelta: current ? 1 : -1);
      }
      isOffline.value = false;
      return true;
    } catch (e) {
      errorMessage.value = _buildToggleLikeErrorMessage(e);
      isOffline.value = _isNetworkIssue(e);
      return false;
    } finally {
      isTogglingPlaceLike.value = false;
    }
  }

  Future<bool> togglePlaceFavorite(String placeId) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return false;

    final normalizedId = placeId.trim();
    if (normalizedId.isEmpty || isTogglingPlaceFavorite.value) return false;

    isTogglingPlaceFavorite.value = true;
    errorMessage.value = null;
    try {
      final previous = isPlaceFavorited.value;
      final current = await repository.togglePlaceFavorite(normalizedId);
      isPlaceFavorited.value = current;
      await _setPlaceFavoriteLocally(normalizedId, current);
      if (previous != current) {
        _updateSelectedPlaceStats(favoritesDelta: current ? 1 : -1);
      }
      isOffline.value = false;
      return true;
    } catch (e) {
      errorMessage.value = _buildToggleFavoriteErrorMessage(e);
      isOffline.value = _isNetworkIssue(e);
      return false;
    } finally {
      isTogglingPlaceFavorite.value = false;
    }
  }

  Future<bool> submitPlaceReview({
    required String placeId,
    required String comment,
  }) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return false;

    final normalizedPlaceId = placeId.trim();
    final normalizedComment = comment.trim();

    if (normalizedPlaceId.isEmpty) {
      reviewErrorMessage.value = 'Lieu invalide pour publier un avis.';
      return false;
    }
    if (normalizedComment.length < 10 || normalizedComment.length > 1000) {
      reviewErrorMessage.value =
          'Le commentaire doit contenir entre 10 et 1000 caractères.';
      return false;
    }

    final currentUserId = _prefs?.getString(StorageConstants.userId)?.trim();
    if (currentUserId != null && currentUserId.isNotEmpty) {
      final hasAlreadyReviewed = placeReviews.value.any((review) {
        return review.user?.id == currentUserId;
      });
      if (hasAlreadyReviewed) {
        reviewErrorMessage.value =
            'Vous avez déjà publié un avis pour ce lieu.';
        return false;
      }
    }

    isSubmittingPlaceReview.value = true;
    reviewErrorMessage.value = null;

    try {
      final created = await repository.createReview(
        placeId: normalizedPlaceId,
        comment: normalizedComment,
      );
      placeReviews.value = [created, ...placeReviews.value]
        ..sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      isOffline.value = false;
      return true;
    } catch (e) {
      reviewErrorMessage.value = _buildSubmitReviewErrorMessage(e);
      isOffline.value = _isNetworkIssue(e);
      return false;
    } finally {
      isSubmittingPlaceReview.value = false;
    }
  }

  String _buildLoadPlacesErrorMessage(Object error) {
    if (ApiConstants.apiKey.isEmpty) {
      return 'Clé API absente dans la configuration de l’app. Lancez Flutter avec --dart-define-from-file=.env ou --dart-define=API_KEY=...';
    }
    if (error is DioException && error.response?.statusCode == 401) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return 'Accès refusé par l’API. Vérifiez la clé API envoyée par l’application.';
    }
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

  String _buildLoadReviewsErrorMessage(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('timeout')) {
      return 'Le chargement des avis a expiré. Réessayez.';
    }
    if (_isNetworkIssue(error)) {
      return 'Connexion impossible pour charger les avis.';
    }
    return 'Erreur lors du chargement des avis.';
  }

  String _buildSubmitReviewErrorMessage(Object error) {
    if (error is DioException) {
      if (error.response?.statusCode == 409) {
        return 'Vous avez déjà publié un avis pour ce lieu.';
      }
      if (error.response?.statusCode == 422) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          final errors = data['errors'];
          if (errors is Map<String, dynamic>) {
            final comments = errors['comment'];
            if (comments is List && comments.isNotEmpty) {
              final message = comments.first?.toString().trim();
              if (message != null && message.isNotEmpty) {
                return message;
              }
            }
          }
          final message = data['message']?.toString().trim();
          if (message != null && message.isNotEmpty) {
            return message;
          }
        }
      }
    }
    if (_isNetworkIssue(error)) {
      return 'Connexion impossible pour publier votre avis.';
    }
    return 'Impossible de publier votre avis.';
  }

  String _buildToggleLikeErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Connectez-vous pour aimer ce lieu.';
    }
    if (_isNetworkIssue(error)) {
      return 'Connexion impossible pour aimer ce lieu.';
    }
    return 'Impossible de mettre à jour le like.';
  }

  String _buildToggleFavoriteErrorMessage(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Connectez-vous pour ajouter ce lieu aux favoris.';
    }
    if (_isNetworkIssue(error)) {
      return 'Connexion impossible pour mettre à jour les favoris.';
    }
    return 'Impossible de mettre à jour les favoris.';
  }

  bool _isNetworkIssue(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
    }
    final lower = error.toString().toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('network is unreachable') ||
        lower.contains('connexion impossible') ||
        lower.contains('internet');
  }

  Future<void> _savePlacesToDiskCache(List<PlaceEntity> entries) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final payload = entries.map(_placeToCacheJson).toList(growable: false);
    await prefs.setString(
      StorageConstants.placesListCache,
      jsonEncode(payload),
    );
    await prefs.setString(
      StorageConstants.placesListCachedAt,
      DateTime.now().toIso8601String(),
    );
  }

  Future<bool> _tryLoadPlacesFromDiskCache() async {
    final prefs = _prefs;
    if (prefs == null) return false;

    final raw = prefs.getString(StorageConstants.placesListCache);
    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;
      final restored = <PlaceEntity>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        restored.add(PlaceModel.fromJson(Map<String, dynamic>.from(item)));
      }
      if (restored.isEmpty) return false;
      places.value = restored;
      _refreshFavoritePlacesFromLoadedLists();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _savePlaceDetailToDiskCache(PlaceEntity place) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final key = _placeDetailCacheKey(place.id);
    await prefs.setString(key, jsonEncode(_placeToCacheJson(place)));
  }

  Future<bool> _tryLoadPlaceDetailFromDiskCache(String placeId) async {
    final prefs = _prefs;
    if (prefs == null) return false;

    final raw = prefs.getString(_placeDetailCacheKey(placeId));
    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return false;
      final restored = PlaceModel.fromJson(Map<String, dynamic>.from(decoded));
      selectedPlace.value = restored;
      _placeByIdCache[placeId] = restored;
      _placeByIdFetchedAt[placeId] = DateTime.now();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _placeDetailCacheKey(String placeId) =>
      '${StorageConstants.placeDetailCachePrefix}$placeId';

  Future<void> loadFavoritePlaces() async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    isFavoritePlacesLoading.value = true;
    errorMessage.value = null;
    try {
      final favorites = await repository.getFavoritePlaces();
      favoritePlaces.value = favorites;
      final ids = favorites.map((place) => place.id).toList(growable: false);
      final prefs = _prefs;
      if (prefs != null) {
        await prefs.setStringList(StorageConstants.favoritePlaceIds, ids);
      }
      for (final place in favorites) {
        _placeByIdCache[place.id] = place;
        _placeByIdFetchedAt[place.id] = DateTime.now();
      }
      isOffline.value = false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        favoritePlaces.value = const [];
        errorMessage.value = 'Connectez-vous pour voir vos favoris.';
        return;
      }
      final ids = _readFavoritePlaceIds();
      if (ids.isEmpty) {
        favoritePlaces.value = const [];
      } else {
        _refreshFavoritePlacesFromLoadedLists(idsOverride: ids);
      }
      isOffline.value = _isNetworkIssue(e);
      if (!_isNetworkIssue(e)) {
        errorMessage.value = 'Impossible de charger les favoris.';
      }
    } finally {
      isFavoritePlacesLoading.value = false;
    }
  }

  Future<void> loadVisitedPlaces({int perPage = 20}) async {
    if (_repository == null) await init();
    final repository = _repository;
    if (repository == null) return;

    isVisitedPlacesLoading.value = true;
    errorMessage.value = null;
    try {
      final visits = await repository.getVisitedPlaces(perPage: perPage);
      visitedPlaces.value = visits;
      for (final place in visits) {
        _placeByIdCache[place.id] = place;
        _placeByIdFetchedAt[place.id] = DateTime.now();
      }
      isOffline.value = false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        visitedPlaces.value = const [];
        errorMessage.value = 'Connectez-vous pour voir votre historique.';
      } else {
        visitedPlaces.value = const [];
        isOffline.value = _isNetworkIssue(e);
        if (!_isNetworkIssue(e)) {
          errorMessage.value = 'Impossible de charger l\'historique.';
        }
      }
    } finally {
      isVisitedPlacesLoading.value = false;
    }
  }

  List<String> _readFavoritePlaceIds() {
    final prefs = _prefs;
    if (prefs == null) return const [];
    final raw = prefs.getStringList(StorageConstants.favoritePlaceIds);
    if (raw == null || raw.isEmpty) return const [];
    return raw.where((id) => id.trim().isNotEmpty).toList(growable: false);
  }

  Future<void> _setPlaceFavoriteLocally(String placeId, bool isFavorite) async {
    final prefs = _prefs;
    if (prefs == null) return;
    final updated = _readFavoritePlaceIds().toSet();
    if (isFavorite) {
      updated.add(placeId);
    } else {
      updated.remove(placeId);
    }
    await prefs.setStringList(
      StorageConstants.favoritePlaceIds,
      updated.toList(growable: false),
    );
    _refreshFavoritePlacesFromLoadedLists(idsOverride: updated.toList());
  }

  void _refreshFavoritePlacesFromLoadedLists({List<String>? idsOverride}) {
    final ids = idsOverride ?? _readFavoritePlaceIds();
    if (ids.isEmpty) {
      favoritePlaces.value = const [];
      return;
    }
    final loaded = <String, PlaceEntity>{
      for (final place in places.value) place.id: place,
      for (final place in nearbyPlaces.value) place.id: place,
      for (final entry in _placeByIdCache.entries) entry.key: entry.value,
    };
    favoritePlaces.value = ids
        .map((id) => loaded[id])
        .whereType<PlaceEntity>()
        .toList(growable: false);
  }

  void _updateSelectedPlaceStats({int likesDelta = 0, int favoritesDelta = 0}) {
    final current = selectedPlace.value;
    if (current == null) return;

    final updatedStats = PlaceStats(
      likesCount: _clampToPositive(current.stats.likesCount + likesDelta),
      visitsCount: current.stats.visitsCount,
      reviewsCount: current.stats.reviewsCount,
      favoritesCount: _clampToPositive(
        current.stats.favoritesCount + favoritesDelta,
      ),
    );
    final updated = _copyPlaceWith(current, stats: updatedStats);
    selectedPlace.value = updated;
    _placeByIdCache[current.id] = updated;

    places.value = places.value
        .map((place) => place.id == updated.id ? updated : place)
        .toList(growable: false);
    nearbyPlaces.value = nearbyPlaces.value
        .map((place) => place.id == updated.id ? updated : place)
        .toList(growable: false);

    _savePlaceDetailToDiskCache(updated);
  }

  int _clampToPositive(int value) => value < 0 ? 0 : value;

  PlaceEntity _copyPlaceWith(PlaceEntity place, {PlaceStats? stats}) {
    return PlaceEntity(
      id: place.id,
      name: place.name,
      slug: place.slug,
      description: place.description,
      imageUrl: place.imageUrl,
      videoUrl: place.videoUrl,
      latitude: place.latitude,
      longitude: place.longitude,
      address: place.address,
      city: place.city,
      commune: place.commune,
      phone: place.phone,
      whatsapp: place.whatsapp,
      website: place.website,
      openingHours: place.openingHours,
      rating: place.rating,
      category: place.category,
      categories: place.categories,
      isActive: place.isActive,
      isVerified: place.isVerified,
      isRecommended: place.isRecommended,
      prices: place.prices,
      stats: stats ?? place.stats,
      distance: place.distance,
      createdAt: place.createdAt,
      updatedAt: place.updatedAt,
      hasVideo: place.hasVideo,
      media: place.media,
    );
  }

  Map<String, dynamic> _placeToCacheJson(PlaceEntity place) {
    return <String, dynamic>{
      'id': place.id,
      'name': place.name,
      'slug': place.slug,
      'description': place.description,
      'image_url': place.imageUrl,
      'video_url': place.videoUrl,
      'lat': place.latitude,
      'lng': place.longitude,
      'address': place.address,
      'ville': place.city,
      'commune': place.commune,
      'phone': place.phone,
      'whatsapp': place.whatsapp,
      'website': place.website,
      'opening_hours': place.openingHours,
      'rating': place.rating,
      'category': place.category,
      'categories': place.categories
          .map((name) => <String, dynamic>{'name': name})
          .toList(growable: false),
      'is_active': place.isActive,
      'is_verified': place.isVerified,
      'is_recommended': place.isRecommended,
      'prices': place.prices
          .map(
            (price) => <String, dynamic>{
              'id': price.id,
              'label': price.label,
              'price': price.price,
              'currency': price.currency,
              'description': price.description,
            },
          )
          .toList(growable: false),
      'stats': <String, dynamic>{
        'likes_count': place.stats.likesCount,
        'visits_count': place.stats.visitsCount,
        'reviews_count': place.stats.reviewsCount,
        'favorites_count': place.stats.favoritesCount,
      },
      'distance': place.distance,
      'created_at': place.createdAt?.toIso8601String(),
      'updated_at': place.updatedAt?.toIso8601String(),
      'media': place.media
          .map(
            (media) => <String, dynamic>{
              'id': media.id,
              'type': media.type,
              'is_primary': media.isPrimary,
              if (media.isVideo)
                'video_url': media.url
              else
                'image_url': media.url,
            },
          )
          .toList(growable: false),
    };
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
