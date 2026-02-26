import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/user_location_service.dart';
import '../../../core/stores/place_store.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/place_entity.dart';
import '../../widgets/category_filter_chips_bar.dart';
import '../../widgets/mini_place_card.dart';

class NearbyPlacesScreen extends StatefulWidget {
  const NearbyPlacesScreen({super.key});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  final _store = PlaceStore.instance;
  final _locationService = UserLocationService();
  final _radiusKm = signal<double>(10);
  final _isLocating = signal(false);
  List<CategoryEntity> _categories = const [];
  String? _selectedCategorySlug;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _radiusKm.dispose();
    _isLocating.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await _store.init();
    await _loadCategories();
    await _loadNearbyPlaces();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final repository = CategoryRepositoryImpl(
        dioService: DioService(cacheService),
      );
      final categories = await repository.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _loadNearbyPlaces() async {
    _isLocating.value = true;
    try {
      final position = await _locationService.getCurrentPosition();
      await _store.loadNearbyPlaces(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: _radiusKm.value,
        categorySlug: _selectedCategorySlug,
        categoryId: _selectedCategoryId,
      );
      if (!mounted) return;
      if (_store.errorMessage.value != null) {
        NotificationService.error(context, _store.errorMessage.value!);
      }
    } on UserLocationException catch (e) {
      if (!mounted) return;
      NotificationService.warning(context, e.message);
    } catch (_) {
      if (!mounted) return;
      NotificationService.error(
        context,
        'Impossible de charger les lieux proches',
      );
    } finally {
      _isLocating.value = false;
    }
  }

  String _distanceLabel(PlaceEntity place) {
    final distance = place.distance;
    if (distance == null) return 'Distance inconnue';
    return '${distance.toStringAsFixed(1)} km';
  }

  Future<void> _onRadiusChanged(double value) async {
    _radiusKm.value = value;
    await _loadNearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _isLocating.value || _store.isNearbyPlacesLoading.value;
      final places = _store.nearbyPlaces.value;
      final radius = _radiusKm.value;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Lieux proches'),
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            PopupMenuButton<double>(
              tooltip: 'Rayon',
              initialValue: radius,
              onSelected: _onRadiusChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(value: 3, child: Text('3 km')),
                PopupMenuItem(value: 5, child: Text('5 km')),
                PopupMenuItem(value: 10, child: Text('10 km')),
                PopupMenuItem(value: 15, child: Text('15 km')),
                PopupMenuItem(value: 20, child: Text('20 km')),
                PopupMenuItem(value: 30, child: Text('30 km')),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${radius.toStringAsFixed(0)} km',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              icon: const Icon(AppIcons.refresh),
              onPressed: _loadNearbyPlaces,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: CategoryFilterChipsBar(
                categories: _categories,
                selectedSlug: _selectedCategorySlug,
                allLabel: 'Tous',
                onSelected: (category) {
                  final nextSlug = category?.slug;
                  final nextId = category?.id;
                  if (_selectedCategorySlug == nextSlug &&
                      _selectedCategoryId == nextId) {
                    return;
                  }
                  setState(() {
                    _selectedCategorySlug = nextSlug;
                    _selectedCategoryId = nextId;
                  });
                  _loadNearbyPlaces();
                },
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : places.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Aucun lieu trouvé autour de vous dans ce rayon.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: places.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return MiniPlaceCard(
                          place: place,
                          distanceLabel: _distanceLabel(place),
                          onTap: () => context.push('/place/${place.id}'),
                        ).animate(
                          delay: (50 + (index % 8) * 40).ms,
                        ).fadeIn(duration: 260.ms).slideY(
                          begin: 0.05,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    });
  }
}
