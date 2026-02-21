import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/section_repository_impl.dart';
import '../../../domain/entities/section_entity.dart';

class SectionsScreen extends StatefulWidget {
  const SectionsScreen({super.key});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final _isLoading = signal(true);
  final _sections = signal<List<SectionEntity>>([]);
  final _error = signal<String?>(null);
  late final Future<SectionRepositoryImpl> _repositoryFuture =
      _buildRepository();

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _sections.dispose();
    _error.dispose();
    super.dispose();
  }

  Future<SectionRepositoryImpl> _buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return SectionRepositoryImpl(dioService: DioService(cacheService));
  }

  Future<void> _loadSections() async {
    _isLoading.value = true;
    _error.value = null;
    try {
      final repository = await _repositoryFuture;
      final result = await repository.getSections();
      _sections.value = result;
    } catch (e) {
      _sections.value = [];
      _error.value = 'Impossible de charger les sections.';
      if (mounted) NotificationService.error(context, 'Sections: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _isLoading.value;
      final sections = _sections.value;
      final error = _error.value;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Sections spéciales'),
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          actions: [
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _loadSections,
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
                      onPressed: _loadSections,
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              )
            : sections.isEmpty
            ? const Center(child: Text('Aucune section disponible.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final section = sections[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/sections/${section.slug}'),
                    child: Ink(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(AppIcons.auto_awesome_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  section.description.isNotEmpty
                                      ? section.description
                                      : 'Section spéciale',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${section.placesCount}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate(
                    delay: (40 + (index % 8) * 35).ms,
                  ).fadeIn(duration: 250.ms).slideY(
                    begin: 0.05,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
      );
    });
  }
}
