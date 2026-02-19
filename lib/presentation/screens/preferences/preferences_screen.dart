import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _isLoading = true;
  bool _isSaving = false;
  List<CategoryEntity> _categories = const [];
  final Set<int> _selectedCategoryIds = <int>{};

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
    setState(() => _isLoading = true);
    try {
      final repository = await _buildRepository();
      final categories = await repository.getCategories();
      final selected = await repository.getUserPreferenceCategoryIds();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategoryIds
          ..clear()
          ..addAll(selected);
      });
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(
        context,
        'Impossible de charger les préférences: $e',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final repository = await _buildRepository();
      await repository.saveUserPreferences(_selectedCategoryIds.toList());
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedCategoryIds.contains(categoryId)) {
        _selectedCategoryIds.remove(categoryId);
      } else {
        _selectedCategoryIds.add(categoryId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vos préférences')),
      body: SafeArea(
        child: _isLoading
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
                      child: _categories.isEmpty
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
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategoryIds
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
                        onPressed: _isSaving ? null : _savePreferences,
                        child: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _selectedCategoryIds.isEmpty
                                    ? 'Continuer sans préférence'
                                    : 'Enregistrer mes préférences',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
