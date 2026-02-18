import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/stores/place_store.dart';
import '../../../domain/entities/place_entity.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  final _store = PlaceStore.instance;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  Future<void> _initializeDependencies() async {
    await _store.init();
    await _loadPlaceDetails();
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  Future<void> _loadPlaceDetails() async {
    await _store.loadPlaceById(widget.placeId);
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isLoading = _store.isPlaceLoading.value;
      final place = _store.selectedPlace.value;

      if (isLoading) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (place == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('Détail du lieu')),
          body: Center(
            child: ElevatedButton(
              onPressed: _loadPlaceDetails,
              child: const Text('Réessayer'),
            ),
          ),
        );
      }

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            // AppBar avec image
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              leading: IconButton(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.arrow_back, color: Colors.black),
                ),
                onPressed: () => context.go('/home'),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: place.imageUrl != null
                    ? Image.network(
                        place.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.place, size: 100),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.place, size: 100),
                      ),
              ),
            ),

            // Contenu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et note
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (place.rating != null) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 4),
                          Text(
                            place.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Catégorie
                    if (place.category != null)
                      Chip(
                        label: Text(place.category!),
                        backgroundColor: Colors.blue[50],
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Adresse
                    if (place.address != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              place.address!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    if (place.media.isNotEmpty) ...[
                      const Text(
                        'Médias',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: place.media.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final media = place.media[index];
                            return _MediaPreview(media: media);
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      place.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Bouton d'action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Ouvrir dans Google Maps
                          NotificationService.info(
                            context,
                            'Ouverture dans Google Maps...',
                          );
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Obtenir l\'itinéraire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MediaPreview extends StatelessWidget {
  final PlaceMedia media;

  const _MediaPreview({required this.media});

  bool get _canRenderAsImage {
    final lower = media.url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.contains('/image/upload/');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_canRenderAsImage)
            Image.network(
              media.url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(child: Icon(Icons.broken_image));
              },
            )
          else
            Center(
              child: Icon(
                media.isVideo ? Icons.videocam : Icons.image,
                color: Colors.grey.shade700,
                size: 36,
              ),
            ),
          Positioned(
            left: 8,
            top: 8,
            child: Row(
              children: [
                Icon(
                  media.isVideo ? Icons.videocam : Icons.photo,
                  size: 16,
                  color: Colors.white,
                ),
                if (media.isPrimary) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'PRIMARY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
