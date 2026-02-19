import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../domain/entities/place_entity.dart';
import 'app_logo_widget.dart';

class PlaceCard extends StatelessWidget {
  final PlaceEntity place;
  final VoidCallback onTap;
  final double aspectRatio;
  final bool isMuted;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.aspectRatio = 1,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    final label = place.name.toUpperCase();
    final hasImage = place.imageUrl != null && place.imageUrl!.isNotEmpty;
    final hasVideo = place.videoUrl != null && place.videoUrl!.isNotEmpty;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            hasVideo
                ? _AutoPlayVideoBackground(
                    videoUrl: place.videoUrl!,
                    isMuted: isMuted,
                  )
                : hasImage
                ? CachedNetworkImage(
                    imageUrl: place.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B1B1B), Color(0xFF111111)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.photo,
                          size: 48,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  )
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF223047), Color(0xFF3D4E2F)],
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const AppLogoWidget(size: 34),
                            const SizedBox(height: 8),
                            Text(
                              place.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            if (hasImage || hasVideo)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.90),
                        Colors.black.withValues(alpha: 0.40),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.50, 1.0],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                children: [
                  if (place.hasVideo) ...[
                    const Icon(
                      Icons.videocam_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoPlayVideoBackground extends StatefulWidget {
  final String videoUrl;
  final bool isMuted;

  const _AutoPlayVideoBackground({
    required this.videoUrl,
    required this.isMuted,
  });

  @override
  State<_AutoPlayVideoBackground> createState() =>
      _AutoPlayVideoBackgroundState();
}

class _AutoPlayVideoBackgroundState extends State<_AutoPlayVideoBackground> {
  VideoPlayerController? _controller;
  bool _isReady = false;
  bool _isFailed = false;
  bool _isInitializing = false;
  bool _isVisible = false;
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

  void _attachErrorListener(VideoPlayerController controller) {
    controller.addListener(() {
      if (_isDisposed || !mounted) return;
      if (!identical(_controller, controller)) return;

      final value = controller.value;
      if (!value.hasError) return;

      if (mounted) {
        setState(() {
          _controller = null;
          _isReady = false;
          _isFailed = true;
        });
      }
      _disposeController(controller);
    });
  }

  Future<void> _initVideo() async {
    if (_isDisposed || _isInitializing || _isReady || _isFailed) return;
    _isInitializing = true;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.isMuted ? 0 : 1);

      if (_isDisposed || !mounted) {
        await _disposeController(controller);
        return;
      }

      _attachErrorListener(controller);

      setState(() {
        _controller = controller;
        _isReady = true;
      });

      if (_isVisible) {
        await controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isReady = false;
          _isFailed = true;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _onVisibilityChanged(VisibilityInfo info) async {
    if (_isDisposed) return;
    final visible = info.visibleFraction > 0.6;
    _isVisible = visible;

    if (visible) {
      if (!_isReady) {
        await _initVideo();
      } else {
        final controller = _controller;
        if (controller != null && !_isDisposed) {
          await controller.play();
        }
      }
    } else {
      final controller = _controller;
      if (controller != null && !_isDisposed) {
        await controller.pause();
      }
    }
  }

  @override
  void didUpdateWidget(covariant _AutoPlayVideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isDisposed) return;
    if (oldWidget.isMuted != widget.isMuted) {
      final controller = _controller;
      if (controller != null) {
        controller.setVolume(widget.isMuted ? 0 : 1);
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
    return VisibilityDetector(
      key: Key('place-video-${widget.videoUrl.hashCode}'),
      onVisibilityChanged: (info) {
        _onVisibilityChanged(info);
      },
      child: !_isReady || _controller == null
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1B1B1B), Colors.grey.shade900],
                ),
              ),
              child: const Center(
                child: Icon(Icons.videocam, size: 48, color: Colors.white70),
              ),
            )
          : FittedBox(
              fit: BoxFit.cover,
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
