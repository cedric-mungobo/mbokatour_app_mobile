part of '../screens/place_details/place_details_screen.dart';

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: child,
    );
  }
}

class _MiniPlaceMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final VoidCallback onTap;

  const _MiniPlaceMap({
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);

    return SizedBox(
      height: 180,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                IgnorePointer(
                  child: FlutterMap(
                    options: MapOptions(initialCenter: center, initialZoom: 15),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.mbokatour.mobile',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_on,
                              color: AppTheme.accentRed,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Voir sur la carte',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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

class _DetailGridItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;
  final VoidCallback? onTap;

  const _DetailGridItem({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.open_in_new,
                    size: 14,
                    color: Colors.black45,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: fullWidth ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpeningHourRow extends StatelessWidget {
  final String day;
  final String hours;

  const _OpeningHourRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.schedule_outlined, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              day,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hours,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatInlineItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatInlineItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final PlaceMedia media;
  final VoidCallback onTap;
  final int? remainingCount;

  const _MediaPreview({
    required this.media,
    required this.onTap,
    this.remainingCount,
  });

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
        width: double.infinity,
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
                  if (remainingCount != null && remainingCount! > 0)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Text(
                          '+$remainingCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

class _MediaBentoGrid extends StatelessWidget {
  final List<PlaceMedia> media;
  final ValueChanged<int> onTapMedia;

  const _MediaBentoGrid({required this.media, required this.onTapMedia});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) {
      return const SizedBox.shrink();
    }

    if (media.length == 1) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _MediaPreview(media: media[0], onTap: () => onTapMedia(0)),
      );
    }

    if (media.length == 2) {
      return AspectRatio(
        aspectRatio: 2.1,
        child: Row(
          children: [
            Expanded(
              child: _MediaPreview(media: media[0], onTap: () => onTapMedia(0)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MediaPreview(media: media[1], onTap: () => onTapMedia(1)),
            ),
          ],
        ),
      );
    }

    final remaining = media.length - 3;
    return AspectRatio(
      aspectRatio: 1.35,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _MediaPreview(media: media[0], onTap: () => onTapMedia(0)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _MediaPreview(
                    media: media[1],
                    onTap: () => onTapMedia(1),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _MediaPreview(
                    media: media[2],
                    remainingCount: remaining > 0 ? remaining : null,
                    onTap: () => onTapMedia(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
  bool _isDisposed = false;

  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    try {
      await controller.pause();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initIfNeeded();
  }

  Future<void> _initIfNeeded() async {
    if (_isDisposed || _initializing || _ready || _failed) return;
    _initializing = true;
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.isMuted ? 0 : 1);
      if (!mounted || _isDisposed) {
        await _disposeController(controller);
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
    if (_isDisposed) return;
    if (oldWidget.isMuted != widget.isMuted) {
      final controller = _controller;
      if (controller != null) {
        controller.setVolume(widget.isMuted ? 0 : 1);
      }
    }
  }

  Future<void> _onVisibilityChanged(VisibilityInfo info) async {
    if (_isDisposed) return;
    final visible = info.visibleFraction > 0.55;
    _visible = visible;
    if (visible) {
      await _initIfNeeded();
      final controller = _controller;
      if (controller != null && !_isDisposed) {
        await controller.play();
      }
    } else {
      final controller = _controller;
      if (controller != null && !_isDisposed) {
        await controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final controller = _controller;
    _controller = null;
    _disposeController(controller);
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
  bool _isDisposed = false;

  Future<void> _disposeController(VideoPlayerController? controller) async {
    if (controller == null) return;
    try {
      await controller.pause();
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

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

      if (!mounted || _isDisposed) {
        await _disposeController(controller);
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
    _isDisposed = true;
    _controller?.removeListener(_syncPlayingState);
    final controller = _controller;
    _controller = null;
    _disposeController(controller);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _FullscreenVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDisposed) return;
    if (oldWidget.isMuted != widget.isMuted) {
      final controller = _controller;
      if (controller != null) {
        controller.setVolume(widget.isMuted ? 0 : 1);
      }
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
    if (controller == null || _isDisposed) return;
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
