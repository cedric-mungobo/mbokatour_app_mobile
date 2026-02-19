import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../../domain/entities/category_entity.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _isLoading = signal(true);
  final _isSaving = signal(false);
  final _categories = signal<List<CategoryEntity>>([]);
  final _selectedCategoryIds = signal<Set<int>>(<int>{});

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<CategoryRepositoryImpl> _buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return CategoryRepositoryImpl(dioService: DioService(cacheService));
  }

  Future<void> _loadData() async {
    _isLoading.value = true;
    try {
      final repository = await _buildRepository();
      final categories = await repository.getCategories();
      final selected = await repository.getUserPreferenceCategoryIds();
      if (!mounted) return;
      _categories.value = categories;
      _selectedCategoryIds.value = {...selected};
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        context,
        'Impossible de charger les préférences: $e',
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _savePreferences() async {
    _isSaving.value = true;
    try {
      final repository = await _buildRepository();
      await repository.saveUserPreferences(_selectedCategoryIds.value.toList());
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      await cacheService.savePreferencesOnboardingDone(true);
      if (!mounted) return;
      NotificationService.success(context, 'Préférences enregistrées');
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(context, 'Enregistrement impossible: $e');
    } finally {
      _isSaving.value = false;
    }
  }

  void _toggleCategory(int categoryId) {
    final next = {..._selectedCategoryIds.value};
    if (next.contains(categoryId)) {
      next.remove(categoryId);
    } else {
      next.add(categoryId);
    }
    _selectedCategoryIds.value = next;
  }

  @override
  void dispose() {
    _isLoading.dispose();
    _isSaving.dispose();
    _categories.dispose();
    _selectedCategoryIds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vos préférences')),
      body: Watch(
        (context) => SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _isLoading.value
                ? const Center(
                    key: ValueKey('prefs-loading'),
                    child: CircularProgressIndicator(),
                  )
                : TweenAnimationBuilder<double>(
                    key: const ValueKey('prefs-content'),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, t, child) {
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(0, (1 - t) * 18),
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Choisissez vos catégories favorites',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ).animate().fadeIn(delay: 60.ms, duration: 220.ms),
                          Text(
                            'Personnalisez votre expérience. Vous pouvez sélectionner plusieurs catégories.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ).animate().fadeIn(delay: 100.ms, duration: 260.ms),
                          const SizedBox(height: 20),
                          Expanded(
                            child: _categories.value.isEmpty
                                ? Center(
                                    child: Text(
                                      'Aucune catégorie disponible.',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  )
                                : SingleChildScrollView(
                                    child: Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: _categories.value
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                            final i = entry.key;
                                            final category = entry.value;
                                            final isSelected =
                                                _selectedCategoryIds.value
                                                    .contains(category.id);
                                            final icon = (category.icon ?? '')
                                                .trim();
                                            final label = icon.isEmpty
                                                ? category.name
                                                : '$icon ${category.name}';
                                            return AnimatedScale(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              curve: Curves.easeOut,
                                              scale: isSelected ? 1.03 : 1.0,
                                              child:
                                                  FilterChip(
                                                    selected: isSelected,
                                                    label: Text(label),
                                                    onSelected: (_) =>
                                                        _toggleCategory(
                                                          category.id,
                                                        ),
                                                  ).animate().fadeIn(
                                                    delay:
                                                        (120 + (i % 8) * 35).ms,
                                                    duration: 260.ms,
                                                  ),
                                            );
                                          })
                                          .toList(),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: _isSaving.value
                                  ? null
                                  : _savePreferences,
                              child: _isSaving.value
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _selectedCategoryIds.value.isEmpty
                                          ? 'Continuer sans préférence'
                                          : 'Enregistrer mes préférences',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
