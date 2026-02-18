import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../../core/services/media_settings_service.dart';
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

  void _openMediaViewer(int index, List<PlaceMedia> media) {
    if (media.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MediaViewerScreen(media: media, initialIndex: index),
      ),
    );
  }

  int _resolvePrimaryMediaIndex(List<PlaceMedia> media) {
    final primaryIndex = media.indexWhere((item) => item.isPrimary);
    return primaryIndex >= 0 ? primaryIndex : 0;
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
                background: GestureDetector(
                  onTap: place.media.isNotEmpty
                      ? () => _openMediaViewer(
                          _resolvePrimaryMediaIndex(place.media),
                          place.media,
                        )
                      : null,
                  child: _HeroMedia(place: place),
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
                            return _MediaPreview(
                              media: media,
                              onTap: () => _openMediaViewer(index, place.media),
                            );
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

class _HeroMedia extends StatelessWidget {
  final PlaceEntity place;

  const _HeroMedia({required this.place});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isMuted = MediaSettingsService.isMuted.value;
      final primary = _resolvePrimary(place.media);
      if (primary != null) {
        if (primary.canPlayVideo) {
          return _InlineAutoPlayVideo(
            url: primary.url,
            isMuted: isMuted,
            fit: BoxFit.cover,
          );
        }
        return CachedNetworkImage(
          imageUrl: primary.url,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            return _buildFallback();
          },
        );
      }

      if (place.imageUrl != null) {
        return CachedNetworkImage(
          imageUrl: place.imageUrl!,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) {
            return _buildFallback();
          },
        );
      }

      if (place.videoUrl != null) {
        return _InlineAutoPlayVideo(
          url: place.videoUrl!,
          isMuted: isMuted,
          fit: BoxFit.cover,
        );
      }

      return _buildFallback();
    });
  }

  PlaceMedia? _resolvePrimary(List<PlaceMedia> media) {
    if (media.isEmpty) return null;
    final index = media.indexWhere((item) => item.isPrimary);
    return index >= 0 ? media[index] : media.first;
  }

  Widget _buildFallback() {
    return Container(
      color: Colors.grey[300],
      child: const Icon(Icons.place, size: 100),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final PlaceMedia media;
  final VoidCallback onTap;

  const _MediaPreview({required this.media, required this.onTap});

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
    return Watch((context) {
      final isMuted = MediaSettingsService.isMuted.value;
      return SizedBox(
        width: 160,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey.shade200,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media.canPlayVideo)
                    _InlineAutoPlayVideo(
                      url: media.url,
                      isMuted: isMuted,
                      fit: BoxFit.cover,
                    )
                  else if (_canRenderAsImage)
                    CachedNetworkImage(
                      imageUrl: media.url,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
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
            ),
          ),
        ),
      );
    });
  }
}

class _InlineAutoPlayVideo extends StatefulWidget {
  final String url;
  final bool isMuted;
  final BoxFit fit;

  const _InlineAutoPlayVideo({
    required this.url,
    required this.isMuted,
    this.fit = BoxFit.cover,
  });

  @override
  State<_InlineAutoPlayVideo> createState() => _InlineAutoPlayVideoState();
}

class _InlineAutoPlayVideoState extends State<_InlineAutoPlayVideo> {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;
  bool _visible = false;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _initIfNeeded();
  }

  Future<void> _initIfNeeded() async {
    if (_initializing || _ready || _failed) return;
    _initializing = true;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.isMuted ? 0 : 1);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _ready = true;
      });
      if (_visible) {
        await controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      _initializing = false;
    }
  }

  @override
  void didUpdateWidget(covariant _InlineAutoPlayVideo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMuted != widget.isMuted) {
      _controller?.setVolume(widget.isMuted ? 0 : 1);
    }
  }

  Future<void> _onVisibilityChanged(VisibilityInfo info) async {
    final visible = info.visibleFraction > 0.55;
    _visible = visible;
    if (visible) {
      await _initIfNeeded();
      await _controller?.play();
    } else {
      await _controller?.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.videocam_off, color: Colors.white70, size: 34),
      );
    }

    return VisibilityDetector(
      key: Key('inline-video-${widget.url.hashCode}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: !_ready || _controller == null
          ? Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : FittedBox(
              fit: widget.fit,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
    );
  }
}

class _MediaViewerScreen extends StatefulWidget {
  final List<PlaceMedia> media;
  final int initialIndex;

  const _MediaViewerScreen({required this.media, required this.initialIndex});

  @override
  State<_MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<_MediaViewerScreen> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final isMuted = MediaSettingsService.isMuted.value;

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.media.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                final item = widget.media[index];
                return item.canPlayVideo
                    ? _FullscreenVideoPlayer(url: item.url, isMuted: isMuted)
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: item.url,
                            fit: BoxFit.contain,
                            errorWidget: (context, url, error) {
                              return const Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 72,
                              );
                            },
                          ),
                        ),
                      );
              },
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_index + 1}/${widget.media.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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

class _FullscreenVideoPlayer extends StatefulWidget {
  final String url;
  final bool isMuted;

  const _FullscreenVideoPlayer({required this.url, required this.isMuted});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _hasError = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.isMuted ? 0 : 1);
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }
      controller.addListener(_syncPlayingState);
      setState(() {
        _controller = controller;
        _loading = false;
        _isPlaying = controller.value.isPlaying;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_syncPlayingState);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FullscreenVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMuted != widget.isMuted) {
      _controller?.setVolume(widget.isMuted ? 0 : 1);
    }
  }

  void _syncPlayingState() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing != _isPlaying && mounted) {
      setState(() => _isPlaying = playing);
    }
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_hasError || _controller == null) {
      return const Center(
        child: Icon(Icons.videocam_off, color: Colors.white70, size: 72),
      );
    }

    return Stack(
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: _togglePlayPause,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      Watch((context) {
                        final isMuted = MediaSettingsService.isMuted.value;
                        return IconButton(
                          onPressed: () {
                            final muted = MediaSettingsService.toggleMute();
                            _controller?.setVolume(muted ? 0 : 1);
                          },
                          icon: Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            color: Colors.white,
                            size: 26,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
