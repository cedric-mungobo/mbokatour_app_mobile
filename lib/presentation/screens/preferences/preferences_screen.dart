import 'package:flutter/material.dart';
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
          child: _isLoading.value
              ? const Center(child: CircularProgressIndicator())
              : Padding(
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
                      const SizedBox(height: 8),
                      Text(
                        'Personnalisez votre expérience. Vous pouvez sélectionner plusieurs catégories.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _categories.value.isEmpty
                            ? Center(
                                child: Text(
                                  'Aucune catégorie disponible.',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              )
                            : SingleChildScrollView(
                                child: Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _categories.value.map((category) {
                                    final isSelected = _selectedCategoryIds
                                        .value
                                        .contains(category.id);
                                    final icon = (category.icon ?? '').trim();
                                    final label = icon.isEmpty
                                        ? category.name
                                        : '$icon ${category.name}';
                                    return FilterChip(
                                      selected: isSelected,
                                      label: Text(label),
                                      onSelected: (_) =>
                                          _toggleCategory(category.id),
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _isSaving.value ? null : _savePreferences,
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
    );
  }
}
