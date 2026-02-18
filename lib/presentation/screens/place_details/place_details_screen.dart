import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/services/media_settings_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/stores/place_store.dart';
import '../../../domain/entities/place_entity.dart';

part '../../widgets/place_details_widgets.dart';

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

  Future<void> _loadPlaceDetails({bool forceRefresh = false}) async {
    await _store.loadPlaceById(widget.placeId, forceRefresh: forceRefresh);
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  void _openMediaViewer(int index, List<PlaceMedia> media) {
    if (media.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MediaViewerScreen(media: media, initialIndex: index),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Future<void> _launchExternalUri(
    String uriString,
    String failureMessage,
  ) async {
    final uri = Uri.tryParse(uriString);
    if (uri == null) {
      if (mounted) NotificationService.warning(context, failureMessage);
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      NotificationService.warning(context, failureMessage);
    }
  }

  Future<void> _openPhone(String value) async {
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    await _launchExternalUri(
      'tel:$cleaned',
      'Impossible d’ouvrir le téléphone',
    );
  }

  Future<void> _openWhatsApp(String value) async {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    await _launchExternalUri(
      'https://wa.me/$digits',
      'Impossible d’ouvrir WhatsApp',
    );
  }

  Future<void> _openWebsite(String value) async {
    final url = value.startsWith('http://') || value.startsWith('https://')
        ? value
        : 'https://$value';
    await _launchExternalUri(url, 'Impossible d’ouvrir le site web');
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
              onPressed: () => _loadPlaceDetails(forceRefresh: true),
              child: const Text('Réessayer'),
            ),
          ),
        );
      }

      final hasCity = _hasText(place.city);
      final hasCommune = _hasText(place.commune);
      final hasAddress = _hasText(place.address);
      final hasDistance = place.distance != null;
      final hasLocationSection =
          hasCity || hasCommune || hasAddress || hasDistance;

      final hasPhone = _hasText(place.phone);
      final hasWhatsapp = _hasText(place.whatsapp);
      final hasWebsite = _hasText(place.website);
      final hasContactsSection = hasPhone || hasWhatsapp || hasWebsite;

      final openingEntries = place.openingHours.entries
          .where((e) => _hasText(e.key) && _hasText(e.value))
          .toList();

      return Scaffold(
        appBar: AppBar(
          title: const Text('Détail du lieu'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (place.media.isNotEmpty) ...[
                _MediaBentoGrid(
                  media: place.media,
                  onTapMedia: (index) => _openMediaViewer(index, place.media),
                ),
                const SizedBox(height: 24),
              ],
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
                    Row(
                      children: [
                        Text(
                          place.rating!.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 5),

              if (place.categories.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: place.categories
                      .map((name) => Chip(label: Text(name)))
                      .toList(),
                ),
                const SizedBox(height: 5),
              ],

              const SizedBox(height: 2),

              if (hasLocationSection) ...[
                const _SectionTitle('Localisation'),
                _SectionCard(
                  child: Column(
                    children: [
                      if (hasCity && hasCommune)
                        Row(
                          children: [
                            Expanded(
                              child: _DetailGridItem(
                                icon: Icons.location_city_outlined,
                                label: 'Ville',
                                value: place.city!,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DetailGridItem(
                                icon: Icons.apartment_outlined,
                                label: 'Commune',
                                value: place.commune!,
                              ),
                            ),
                          ],
                        )
                      else if (hasCity)
                        _DetailGridItem(
                          icon: Icons.location_city_outlined,
                          label: 'Ville',
                          value: place.city!,
                          fullWidth: true,
                        )
                      else if (hasCommune)
                        _DetailGridItem(
                          icon: Icons.apartment_outlined,
                          label: 'Commune',
                          value: place.commune!,
                          fullWidth: true,
                        ),
                      if (hasAddress) ...[
                        const SizedBox(height: 10),
                        _DetailGridItem(
                          icon: Icons.location_on_outlined,
                          label: 'Adresse',
                          value: place.address!,
                          fullWidth: true,
                        ),
                      ],
                      if (hasDistance) ...[
                        const SizedBox(height: 10),
                        _DetailGridItem(
                          icon: Icons.social_distance_outlined,
                          label: 'Distance',
                          value: '${place.distance} km',
                          fullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              const _SectionTitle('Description'),
              const SizedBox(height: 1),
              _SectionCard(
                child: Text(
                  place.description.isNotEmpty
                      ? place.description
                      : 'Aucune description',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
              ),

              if (hasContactsSection) ...[
                const SizedBox(height: 18),
                const _SectionTitle('Contacts'),
                _SectionCard(
                  child: Column(
                    children: [
                      if (hasPhone && hasWhatsapp)
                        Row(
                          children: [
                            Expanded(
                              child: _DetailGridItem(
                                icon: Icons.phone_outlined,
                                label: 'Téléphone',
                                value: place.phone!,
                                onTap: () => _openPhone(place.phone!),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DetailGridItem(
                                icon: Icons.chat_outlined,
                                label: 'WhatsApp',
                                value: place.whatsapp!,
                                onTap: () => _openWhatsApp(place.whatsapp!),
                              ),
                            ),
                          ],
                        )
                      else if (hasPhone)
                        _DetailGridItem(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: place.phone!,
                          fullWidth: true,
                          onTap: () => _openPhone(place.phone!),
                        )
                      else if (hasWhatsapp)
                        _DetailGridItem(
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp',
                          value: place.whatsapp!,
                          fullWidth: true,
                          onTap: () => _openWhatsApp(place.whatsapp!),
                        ),
                      if (hasWebsite) ...[
                        const SizedBox(height: 10),
                        _DetailGridItem(
                          icon: Icons.language_outlined,
                          label: 'Site web',
                          value: place.website!,
                          fullWidth: true,
                          onTap: () => _openWebsite(place.website!),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              if (openingEntries.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _SectionTitle('Horaires'),
                _SectionCard(
                  child: Column(
                    children: openingEntries
                        .map((e) => _OpeningHourRow(day: e.key, hours: e.value))
                        .toList(),
                  ),
                ),
              ],

              if (place.prices.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _SectionTitle('Prix'),
                _SectionCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 10) / 2;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(place.prices.length, (index) {
                          final price = place.prices[index];
                          final isLast = index == place.prices.length - 1;
                          final isOdd = place.prices.length.isOdd;
                          final shouldUseFullWidth = isOdd && isLast;
                          return SizedBox(
                            width: shouldUseFullWidth
                                ? constraints.maxWidth
                                : itemWidth,
                            child: _DetailGridItem(
                              icon: Icons.sell_outlined,
                              label: price.label,
                              value:
                                  '${price.price ?? '-'} ${price.currency ?? ''}'
                                      .trim(),
                              fullWidth: true,
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 18),
              const _SectionTitle('Statistiques'),
              _SectionCard(
                child: Row(
                  children: [
                    _StatInlineItem(
                      icon: Icons.favorite_outline,
                      label: 'Likes',
                      value: place.stats.likesCount.toString(),
                    ),
                    _StatInlineItem(
                      icon: Icons.visibility_outlined,
                      label: 'Visites',
                      value: place.stats.visitsCount.toString(),
                    ),
                    _StatInlineItem(
                      icon: Icons.rate_review_outlined,
                      label: 'Avis',
                      value: place.stats.reviewsCount.toString(),
                    ),
                    _StatInlineItem(
                      icon: Icons.bookmark_border_outlined,
                      label: 'Favoris',
                      value: place.stats.favoritesCount.toString(),
                    ),
                  ],
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
      );
    });
  }
}
