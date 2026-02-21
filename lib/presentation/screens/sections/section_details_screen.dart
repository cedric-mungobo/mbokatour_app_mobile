import 'package:flutter/material.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/section_repository_impl.dart';
import '../../../domain/entities/place_entity.dart';
import '../../../domain/entities/section_entity.dart';
import '../../widgets/mini_place_card.dart';

class SectionDetailsScreen extends StatefulWidget {
  final String slug;

  const SectionDetailsScreen({super.key, required this.slug});

  @override
  State<SectionDetailsScreen> createState() => _SectionDetailsScreenState();
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen> {
  final _isLoading = signal(true);
  final _section = signal<SectionEntity?>(null);
  final _error = signal<String?>(null);
  late final Future<SectionRepositoryImpl> _repositoryFuture =
      _buildRepository();

  @override
  void initState() {
    super.initState();
    _loadSection();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _section.dispose();
    _error.dispose();
    super.dispose();
  }

  Future<SectionRepositoryImpl> _buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return SectionRepositoryImpl(dioService: DioService(cacheService));
  }

  Future<void> _loadSection() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final repository = await _repositoryFuture;
      final result = await repository.getSectionBySlug(widget.slug);
      _section.value = result;
    } catch (e) {
      _section.value = null;
      _error.value = 'Impossible de charger cette section.';
      if (mounted) NotificationService.error(context, '$e');
    } finally {
      _isLoading.value = false;
    }
  }

  String _badgeLabel(PlaceEntity place) {
    final names = place.categories;
    if (names.isNotEmpty) return names.first;
    return place.isRecommended ? 'Recommandé' : 'Lieu';
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _isLoading.value;
      final section = _section.value;
      final error = _error.value;

      return Scaffold(
        appBar: AppBar(
          title: Text(section?.name ?? 'Section spéciale'),
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/sections');
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _loadSection,
              icon: const Icon(AppIcons.refresh),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadSection,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : section == null
            ? const Center(child: Text('Section non trouvée.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                children: [
                  Text(
                    section.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (section.description.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      section.description,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    '${section.places.length} lieu(x)',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (section.places.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Aucun lieu disponible dans cette section.',
                        ),
                      ),
                    )
                  else
                    ...section.places.map(
                      (place) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: MiniPlaceCard(
                          place: place,
                          distanceLabel: _badgeLabel(place),
                          onTap: () => context.push('/place/${place.id}'),
                        ),
                      ),
                    ),
                ],
              ),
      );
    });
  }
}
