import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../core/stores/place_store.dart';
import '../../../core/theme/app_icons.dart';
import '../../../domain/entities/place_entity.dart';
import '../../widgets/mini_place_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = PlaceStore.instance;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _store.init();
    await _store.loadVisitedPlaces();
  }

  String _subtitle(PlaceEntity place) {
    final address = place.address?.trim();
    if (address != null && address.isNotEmpty) return address;
    final city = place.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    return 'Lieu visite';
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _store.isVisitedPlacesLoading.value;
      final visits = _store.visitedPlaces.value;

      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back),
            onPressed: () => context.go('/profile'),
          ),
          title: const Text('Historique'),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : visits.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Aucune visite pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _store.loadVisitedPlaces,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: visits.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final place = visits[index];
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
