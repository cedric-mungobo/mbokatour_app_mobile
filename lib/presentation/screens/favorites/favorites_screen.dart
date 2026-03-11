import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/stores/place_store.dart';
import '../../../core/theme/app_icons.dart';
import '../../../domain/entities/place_entity.dart';
import '../../widgets/mini_place_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _store = PlaceStore.instance;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _store.init();
    await _store.loadFavoritePlaces();
  }

  String _subtitle(PlaceEntity place) {
    final address = place.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    final category = place.category?.trim();
    if (category != null && category.isNotEmpty) return category;
    return 'Lieu favori';
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _store.isFavoritePlacesLoading.value;
      final favorites = _store.favoritePlaces.value;

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          title: const Text('Favoris'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : favorites.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Aucun lieu favori pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _store.loadFavoritePlaces,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final place = favorites[index];
                    return MiniPlaceCard(
                          place: place,
                          distanceLabel: _subtitle(place),
                          onTap: () => context.push('/place/${place.id}'),
                        )
                        .animate(delay: (50 + (index % 8) * 35).ms)
                        .fadeIn(duration: 240.ms)
                        .slideY(
                          begin: 0.05,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                ),
              ),
      );
    });
  }
}
