import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaMetadataResolver {
  MediaMetadataResolver._();

  static final Map<String, double> _ratioCache = <String, double>{};
  static final Set<String> _pending = <String>{};

  static double? cachedRatio(String url) => _ratioCache[url];

  static Future<double?> resolveAspectRatio({
    required String url,
    required bool isVideo,
  }) async {
    final cached = _ratioCache[url];
    if (cached != null) return cached;
    if (_pending.contains(url)) return null;

    _pending.add(url);
    try {
      final ratio = isVideo
          ? await _resolveVideoAspectRatio(url)
          : await _resolveImageAspectRatio(url);
      if (ratio != null && ratio.isFinite && ratio > 0) {
        _ratioCache[url] = ratio;
      }
      return ratio;
    } finally {
      _pending.remove(url);
    }
  }

  static Future<double?> _resolveImageAspectRatio(String url) {
    final completer = Completer<double?>();
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo image, bool _) {
        final width = image.image.width.toDouble();
        final height = image.image.height.toDouble();
        if (!completer.isCompleted) {
          completer.complete(height > 0 ? width / height : null);
        }
        stream.removeListener(listener);
      },
      onError: (exception, stackTrace) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        stream.removeListener(listener);
        return null;
      },
    );
  }

  static Future<double?> _resolveVideoAspectRatio(String url) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      final ratio = controller.value.aspectRatio;
      return ratio.isFinite && ratio > 0 ? ratio : null;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }
}
