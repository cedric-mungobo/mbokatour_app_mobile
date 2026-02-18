import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../domain/entities/place_entity.dart';

class PlaceCard extends StatelessWidget {
  final PlaceEntity place;
  final VoidCallback onTap;
  final double aspectRatio;

  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.aspectRatio = 1,
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
                ? _AutoPlayVideoBackground(videoUrl: place.videoUrl!)
                : hasImage
                ? Image.network(
                    place.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [const Color(0xFF1B1B1B), Colors.grey.shade900],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.photo, size: 48, color: Colors.white70),
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
                            const Icon(
                              Icons.place,
                              size: 34,
                              color: Colors.white,
                            ),
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

  const _AutoPlayVideoBackground({required this.videoUrl});

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

  void _attachErrorListener(VideoPlayerController controller) {
    controller.addListener(() async {
      final value = controller.value;
      if (!mounted || !value.hasError) return;

      await controller.pause();
      await controller.dispose();
      if (mounted) {
        setState(() {
          _controller = null;
          _isReady = false;
          _isFailed = true;
        });
      }
    });
  }

  Future<void> _initVideo() async {
    if (_isInitializing || _isReady || _isFailed) return;
    _isInitializing = true;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      _attachErrorListener(controller);

      if (!mounted) {
        await controller.dispose();
        return;
      }

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
    final visible = info.visibleFraction > 0.6;
    _isVisible = visible;

    if (visible) {
      if (!_isReady) {
        await _initVideo();
      } else {
        await _controller?.play();
      }
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
