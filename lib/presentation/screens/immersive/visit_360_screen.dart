import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:mbokatour_app_mobile/core/services/media_cache_manager.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:mbokatour_app_mobile/domain/entities/place_entity.dart';
import 'package:webview_flutter/webview_flutter.dart';

class Visit360Screen extends StatefulWidget {
  final String placeId;
  final String placeName;
  final String? placeAddress;
  final String? coverImageUrl;
  final PlaceImmersiveTour? tour;

  const Visit360Screen({
    super.key,
    required this.placeId,
    required this.placeName,
    this.placeAddress,
    this.coverImageUrl,
    this.tour,
  });

  @override
  State<Visit360Screen> createState() => _Visit360ScreenState();
}

class _Visit360ScreenState extends State<Visit360Screen> {
  late final WebViewController _webViewController;
  bool _viewerReady = false;
  bool _pageLoading = true;
  String? _viewerMessage;
  String? _currentSceneId;
  final Map<String, String> _offlinePanoramaPathsByRemoteUrl = {};
  bool _cachePrefetchStarted = false;
  bool _tourInitSent = false;

  @override
  void initState() {
    super.initState();
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: _onJavaScriptMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _pageLoading = true;
              _viewerReady = false;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            setState(() {
              _pageLoading = false;
              _viewerReady = true;
            });
            await _sendPlaceMetaToViewer();
            await _sendTourToViewerIfPossible();
          },
          onWebResourceError: (error) {
            if (!mounted) return;
            setState(() {
              _pageLoading = false;
              _viewerMessage = 'Erreur viewer: ${error.description}';
            });
          },
        ),
      );

    _loadViewerDocument();
    _prepareOfflinePanoramaCache();
  }

  Future<void> _loadViewerDocument() async {
    try {
      final html = await _buildViewerHtml();
      await _webViewController.loadHtmlString(html);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pageLoading = false;
        _viewerMessage = 'Impossible de charger le viewer local: $e';
      });
    }
  }

  Future<String> _buildViewerHtml() async {
    final viewerHtml = await rootBundle.loadString('assets/360/viewer.html');
    final pannellumCss =
        await rootBundle.loadString('assets/360/pannellum/pannellum.css');
    final pannellumJs =
        await rootBundle.loadString('assets/360/pannellum/pannellum.js');

    String libPannellumJs = '';
    try {
      libPannellumJs =
          await rootBundle.loadString('assets/360/pannellum/libpannellum.js');
    } catch (_) {
      libPannellumJs = '';
    }

    final cssInjection = '<style>\n$pannellumCss\n</style>';
    final jsBuffer = StringBuffer()
      ..writeln('<script>')
      ..writeln('window.__mbokaPannellumScriptLoaded = false;')
      ..writeln('window.__mbokaPannellumScriptError = null;')
      ..writeln('</script>');

    if (libPannellumJs.isNotEmpty) {
      jsBuffer
        ..writeln('<script>')
        ..writeln(libPannellumJs)
        ..writeln('</script>');
    }

    jsBuffer
      ..writeln('<script>')
      ..writeln(pannellumJs)
      ..writeln('window.__mbokaPannellumScriptLoaded = true;')
      ..writeln('</script>');

    return viewerHtml
        .replaceFirst('<!-- __PANNELLUM_CSS__ -->', cssInjection)
        .replaceFirst('<!-- __PANNELLUM_JS__ -->', jsBuffer.toString());
  }

  Future<void> _sendTourToViewerIfPossible() async {
    final tour = widget.tour;
    if (_tourInitSent || !_viewerReady || tour == null || !tour.isUsable) return;
    final payload = jsonEncode(tour.toJson());
    try {
      await _webViewController.runJavaScript('window.initTour($payload);');
      _tourInitSent = true;
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _viewerMessage = 'Impossible d’initialiser la visite 360.';
      });
    }
  }

  Future<void> _sendPlaceMetaToViewer() async {
    if (!_viewerReady) return;
    final payload = jsonEncode({
      'name': widget.placeName,
      'address': widget.placeAddress,
    });
    try {
      await _webViewController.runJavaScript('window.setPlaceMeta($payload);');
    } catch (_) {
      // Non-blocking: the viewer can still render the panorama without metadata.
    }
  }

  Future<void> _prepareOfflinePanoramaCache() async {
    final tour = widget.tour;
    if (_cachePrefetchStarted || tour == null || !tour.isUsable) return;
    _cachePrefetchStarted = true;

    final uniqueUrls = <String>{
      for (final scene in tour.scenes)
        if (scene.panoramaUrl.trim().isNotEmpty) scene.panoramaUrl.trim(),
    };

    for (final url in uniqueUrls) {
      final cached = await MediaCacheManager.instance.getFileFromCache(url);
      final file = cached?.file;
      if (file != null && await file.exists()) {
        _offlinePanoramaPathsByRemoteUrl[url] = file.path;
      }
    }

    for (final url in uniqueUrls) {
      _prefetchPanoramaInBackground(url);
    }
  }

  Future<void> _prefetchPanoramaInBackground(String url) async {
    if (_offlinePanoramaPathsByRemoteUrl.containsKey(url)) return;
    try {
      final file = await MediaCacheManager.instance.getSingleFile(url);
      if (!await file.exists()) return;
      _offlinePanoramaPathsByRemoteUrl[url] = file.path;
      debugPrint(
        '360_CACHE_PREFETCH ${jsonEncode({'place_id': widget.placeId, 'url': url, 'path': file.path})}',
      );
    } catch (e) {
      debugPrint(
        '360_CACHE_PREFETCH_ERROR ${jsonEncode({'place_id': widget.placeId, 'url': url, 'error': e.toString()})}',
      );
    }
  }

  Future<void> _goToMainScene() async {
    final tour = widget.tour;
    if (tour == null || tour.scenes.isEmpty) return;
    final targetSceneId = (tour.startSceneId != null && tour.startSceneId!.isNotEmpty)
        ? tour.startSceneId!
        : tour.scenes.first.id;
    try {
      await _webViewController.runJavaScript(
        'window.goToScene(${jsonEncode(targetSceneId)});',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _viewerMessage = 'Impossible de revenir à la scène principale.';
      });
    }
  }

  void _onJavaScriptMessage(JavaScriptMessage message) {
    Map<String, dynamic>? data;
    try {
      final decoded = jsonDecode(message.message);
      if (decoded is Map<String, dynamic>) {
        data = decoded;
      } else if (decoded is Map) {
        data = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      data = null;
    }

    final type = data?['type']?.toString();
    if (type == 'viewer_ready') {
      _sendPlaceMetaToViewer();
      _sendTourToViewerIfPossible();
      return;
    }
    if (type == 'scene_changed') {
      final sceneId = data?['scene_id']?.toString();
      if (mounted && sceneId != null && sceneId.isNotEmpty) {
        setState(() {
          _currentSceneId = sceneId;
        });
      }
      _trackSceneChanged(sceneId: sceneId);
      return;
    }
    if (type == 'hotspot_clicked') {
      final hotspot = data?['hotspot'];
      if (hotspot is Map) {
        _trackHotspotClicked(Map<String, dynamic>.from(hotspot));
      } else {
        _trackHotspotClicked(const {});
      }
      return;
    }
    if (type == 'error' && mounted) {
      setState(() {
        _viewerMessage = data?['message']?.toString() ?? 'Erreur viewer';
      });
    }
  }

  void _trackSceneChanged({String? sceneId}) {
    final payload = {
      'event': 'scene_changed',
      'place_id': widget.placeId,
      'scene_id': sceneId,
      'tour_id': widget.tour?.id,
    };
    debugPrint('360_ANALYTICS ${jsonEncode(payload)}');
  }

  void _trackHotspotClicked(Map<String, dynamic> hotspot) {
    final payload = {
      'event': 'hotspot_clicked',
      'place_id': widget.placeId,
      'scene_id': _currentSceneId,
      'tour_id': widget.tour?.id,
      'hotspot_id': hotspot['id']?.toString(),
      'action_type': hotspot['action_type']?.toString(),
      'target_scene_id': hotspot['target_scene_id']?.toString(),
      'label': hotspot['label']?.toString(),
    };
    debugPrint('360_ANALYTICS ${jsonEncode(payload)}');
  }

  @override
  Widget build(BuildContext context) {
    final hasTour = widget.tour?.isUsable == true;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: WebViewWidget(controller: _webViewController),
          ),
          if (_pageLoading)
            const ColoredBox(
              color: Color(0xAA0D1117),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!hasTour)
            const ColoredBox(
              color: Color(0xD90D1117),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'La visite 360 n’est pas encore disponible.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _OverlayCircleButton(
                        icon: AppIcons.arrow_back,
                        onTap: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/place/${widget.placeId}');
                          }
                        },
                      ),
                      if (hasTour) ...[
                        const SizedBox(width: 8),
                        _OverlayPillButton(
                          label: 'Scène principale',
                          onTap: _goToMainScene,
                        ),
                      ],
                      if (_viewerMessage != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 260),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: const Color(0xFFFFB4AB).withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                          child: Text(
                            _viewerMessage!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFD0CB),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _OverlayCircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.52),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _OverlayPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OverlayPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
