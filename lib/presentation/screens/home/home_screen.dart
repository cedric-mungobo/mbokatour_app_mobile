import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/notification_service.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/stores/place_store.dart';
import '../../../domain/entities/place_entity.dart';
import '../../widgets/place_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  final _store = PlaceStore.instance;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeDependencies() async {
    await _store.init();
    await _loadPlaces();
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  Future<void> _loadPlaces({bool forceRefresh = false}) async {
    await _store.loadPlaces(
      query: _searchController.text,
      forceRefresh: forceRefresh,
    );
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPlaces);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Watch((context) {
          final isLoading = _store.isPlacesLoading.value;
          final isLoadingMore = _store.isPlacesLoadingMore.value;
          final places = _store.places.value;

          return MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Stack(
              children: [
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.extentAfter < 600 &&
                          _store.hasMorePlaces.value &&
                          !isLoading &&
                          !isLoadingMore) {
                        _store.loadMorePlaces(query: _searchController.text);
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: () => _loadPlaces(forceRefresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 0, bottom: 0),
                        children: [
                          if (isLoading)
                            const SizedBox(
                              height: 380,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (places.isEmpty)
                            const SizedBox(
                              height: 380,
                              child: Center(child: Text('Aucun lieu trouvé')),
                            )
                          else
                            MasonryGridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                final place = places[index];
                                return PlaceCard(
                                  place: place,
                                  aspectRatio: _resolveAspectRatio(place),
                                  onTap: () => context.go('/place/${place.id}'),
                                );
                              },
                            ),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (!isLoading &&
                              !isLoadingMore &&
                              places.isNotEmpty &&
                              !_store.hasMorePlaces.value)
                            const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 16 + bottomInset,
                  child: _BottomSearchBar(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  double _resolveAspectRatio(PlaceEntity place) {
    final primaryUrl = place.videoUrl ?? place.imageUrl;
    final fromUrl = _extractRatioFromUrl(primaryUrl);
    if (fromUrl != null) {
      return fromUrl.clamp(0.65, 1.55);
    }

    final seed = place.id.toString().codeUnits.fold<int>(0, (a, b) => a + b);
    final variants = place.hasVideo
        ? [0.80, 0.95, 1.10, 1.25]
        : [0.72, 0.88, 1.00, 1.20, 1.35];
    return variants[seed % variants.length];
  }

  double? _extractRatioFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    final match = RegExp(r'(\d{2,5})x(\d{2,5})').firstMatch(url);
    if (match == null) return null;

    final width = double.tryParse(match.group(1)!);
    final height = double.tryParse(match.group(2)!);
    if (width == null || height == null || height == 0) return null;
    return width / height;
  }
}

class _BottomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _BottomSearchBar({required this.controller, required this.onChanged});

  @override
  State<_BottomSearchBar> createState() => _BottomSearchBarState();
}

class _BottomSearchBarState extends State<_BottomSearchBar> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    final isFocused = _focusNode.hasFocus;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 52, maxHeight: 56),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        border: Border.all(
          color: isFocused
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.55)
              : Colors.black.withValues(alpha: 0.06),
          width: isFocused ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.search, color: Colors.black45, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  setState(() {});
                  widget.onChanged(value);
                },
                onSubmitted: widget.onChanged,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search locations...',
                  hintStyle: TextStyle(
                    color: Colors.black38,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            if (hasText)
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  tooltip: 'Effacer',
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Colors.black54,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
