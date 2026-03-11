import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mbokatour_app_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/media_metadata_resolver.dart';
import '../../../core/services/media_settings_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/stores/place_store.dart';
import '../../../domain/entities/place_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../widgets/app_logo_widget.dart';
import '../../widgets/bored_bottom_sheet.dart';
import '../../widgets/home_bottom_nav.dart';
import '../../widgets/home_top_chrome.dart';
import '../../widgets/place_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const double _portraitAspectRatio = 3 / 4;
  static const double _landscapeAspectRatio = 16 / 9;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  final _store = PlaceStore.instance;
  List<CategoryEntity> _categories = const [];
  String? _selectedCategorySlug;
  bool _isBootstrapping = true;
  bool _hasStartedGuide = false;
  final Map<String, double> _resolvedAspectRatios = <String, double>{};
  final Set<String> _resolvingAspectRatios = <String>{};

  final _categoryFilterKey = GlobalKey();
  final _searchFieldKey = GlobalKey();
  final _boredButtonKey = GlobalKey();
  final _contributeButtonKey = GlobalKey();
  final _profileButtonKey = GlobalKey();
  final _firstPlaceCardKey = GlobalKey();

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
    try {
      await _store.init();
      await _loadCategories();
      await _loadPlaces();
      if (mounted && _store.errorMessage.value != null) {
        NotificationService.error(context, _store.errorMessage.value!);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBootstrapping = false;
        });
        _maybeStartHomeGuide();
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final repository = CategoryRepositoryImpl(
        dioService: DioService(cacheService),
      );
      final categories = await repository.getCategories();
      if (!mounted) return;
      setState(() => _categories = categories);
    } catch (_) {}
  }

  Future<void> _loadPlaces({bool forceRefresh = false}) async {
    await _store.loadPlaces(
      query: _searchController.text,
      categorySlug: _selectedCategorySlug,
      forceRefresh: forceRefresh,
    );
    _primeVisibleMediaRatios();
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPlaces);
  }

  void _primeVisibleMediaRatios() {
    final places = _store.places.value;
    for (final place in places) {
      final media = place.primaryMedia;
      if (media == null) continue;
      if (_resolvedAspectRatios.containsKey(place.id)) continue;
      if (_preferredAspectRatio(place) != null) continue;
      if (_resolvingAspectRatios.contains(place.id)) continue;
      _resolveAspectRatioFromMedia(place, media);
    }
  }

  Future<void> _resolveAspectRatioFromMedia(
    PlaceEntity place,
    PlaceMedia media,
  ) async {
    _resolvingAspectRatios.add(place.id);
    try {
      final ratio = await MediaMetadataResolver.resolveAspectRatio(
        url: media.url,
        isVideo: media.canPlayVideo,
      );
      if (!mounted || ratio == null) return;
      final normalized = ratio.clamp(0.65, 1.55);
      setState(() {
        _resolvedAspectRatios[place.id] = normalized;
      });
    } finally {
      _resolvingAspectRatios.remove(place.id);
    }
  }

  Future<void> _openBoredSheet() async {
    final action = await showBoredBottomSheet(context);
    if (!mounted || action == null) return;

    if (action == BoredAction.nearby) {
      context.push('/nearby');
      return;
    }
    context.push('/sections');
  }

  void _openProfile() {
    context.go('/profile');
  }

  void _openContribute() {
    context.go('/contribute');
  }

  void _openSections() {
    context.go('/sections');
  }

  void _openFavorites() {
    context.go('/favorites');
  }

  void _openPreferences() {
    context.go('/preferences');
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Future<void> _openSearchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + viewInsets),
          child: HomeSearchSheet(
            controller: _searchController,
            searchFieldKey: _searchFieldKey,
            onChanged: (widgetValue) {
              _onSearchChanged(widgetValue);
            },
            onSubmit: (value) {
              _onSearchChanged(value);
              Navigator.of(sheetContext).pop();
            },
          ),
        );
      },
    );
  }

  Future<void> _maybeStartHomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    final alreadySeen = await cacheService.isHomeGuideSeen();
    if (alreadySeen || !mounted || _hasStartedGuide) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _hasStartedGuide) return;
      // Wait until key widgets are mounted (especially first place card).
      for (var i = 0; i < 8; i++) {
        final hasRequiredTargets =
            _categoryFilterKey.currentContext != null &&
            _searchFieldKey.currentContext != null &&
            _boredButtonKey.currentContext != null &&
            _contributeButtonKey.currentContext != null &&
            _profileButtonKey.currentContext != null;

        final hasPlaceCardTarget =
            _store.places.value.isEmpty ||
            _firstPlaceCardKey.currentContext != null;

        if (hasRequiredTargets && hasPlaceCardTarget) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      if (!mounted) return;
      _hasStartedGuide = true;
      final guide = TutorialCoachMark(
        targets: _buildGuideTargets(),
        colorShadow: Colors.black,
        opacityShadow: 0.78,
        hideSkip: false,
        textSkip: 'Passer',
        onSkip: () {
          cacheService.saveHomeGuideSeen(true);
          return true;
        },
        onFinish: () async {
          await cacheService.saveHomeGuideSeen(true);
        },
      );
      guide.show(context: context);
    });
  }

  List<TargetFocus> _buildGuideTargets() {
    final targets = <TargetFocus>[
      _target(
        key: _categoryFilterKey,
        title: 'Filtrer les lieux',
        description:
            'Appuyez ici pour choisir une catégorie et afficher uniquement les lieux qui vous intéressent.',
        align: ContentAlign.bottom,
      ),
      _target(
        key: _searchFieldKey,
        title: 'Rechercher un lieu',
        description:
            'Appuyez sur cette action de recherche, puis saisissez le nom d’un lieu pour le trouver rapidement.',
        align: ContentAlign.top,
      ),
      _target(
        key: _boredButtonKey,
        title: 'Voir autour de moi',
        description:
            'Appuyez sur ce bouton pour découvrir les lieux proches de votre position.',
        align: ContentAlign.top,
      ),
      _target(
        key: _contributeButtonKey,
        title: 'Contribuer',
        description:
            'Appuyez ici pour ajouter un lieu et partager les endroits que vous avez visités.',
        align: ContentAlign.top,
      ),
    ];

    if (_store.places.value.isNotEmpty) {
      targets.add(
        _target(
          key: _firstPlaceCardKey,
          title: 'Ouvrir les détails',
          description:
              'Appuyez sur une image pour afficher la fiche complète du lieu.',
          align: ContentAlign.bottom,
        ),
      );
    }

    targets.add(
      _target(
        key: _profileButtonKey,
        title: 'Menu',
        description:
            'Appuyez ici pour ouvrir le menu et accéder au profil, aux préférences et aux autres sections.',
        align: ContentAlign.top,
        isLast: true,
      ),
    );

    return targets;
  }

  TargetFocus _target({
    required GlobalKey key,
    required String title,
    required String description,
    ContentAlign align = ContentAlign.top,
    bool isLast = false,
  }) {
    return TargetFocus(
      keyTarget: key,
      enableOverlayTab: true,
      contents: [
        TargetContent(
          align: align,
          builder: (context, controller) => _GuideCard(
            title: title,
            description: description,
            isLast: isLast,
            onNext: () {
              if (isLast) {
                controller.skip();
                return;
              }
              controller.next();
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const bottomListSpacing = 20.0;
    const fixedHeaderHeight = 76.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppTheme.brandBlack,
        endDrawer: _HomeMenuDrawer(
          onProfileTap: _openProfile,
          onSectionsTap: _openSections,
          onContributeTap: _openContribute,
          onPreferencesTap: _openPreferences,
        ),
        bottomNavigationBar:
            HomeBottomNav(
                  onHomeTap: () {},
                  onExploreTap: _openBoredSheet,
                  onContributeTap: _openSearchSheet,
                  onSavedTap: _openFavorites,
                  onProfileTap: _openProfile,
                  boredButtonKey: _boredButtonKey,
                  contributeButtonKey: _contributeButtonKey,
                  profileButtonKey: _profileButtonKey,
                )
                .animate()
                .fadeIn(delay: 220.ms, duration: 300.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        body: Watch((context) {
          final isLoading = _store.isPlacesLoading.value;
          final isLoadingMore = _store.isPlacesLoadingMore.value;
          final places = _store.places.value;
          final isMuted = MediaSettingsService.isMuted.value;
          final isOffline = _store.isOffline.value;
          final showInitialLoader = _isBootstrapping || isLoading;

          return SafeArea(
            bottom: false,
            child: Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter < 600 &&
                        _store.hasMorePlaces.value &&
                        !isLoading &&
                        !isLoadingMore) {
                      _store.loadMorePlaces(
                        query: _searchController.text,
                        categorySlug: _selectedCategorySlug,
                      );
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: () => _loadPlaces(forceRefresh: true),
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: const SizedBox(height: fixedHeaderHeight),
                        ),
                        if (showInitialLoader)
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (places.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                isOffline
                                    ? 'Aucune connexion et aucun lieu en cache'
                                    : _selectedCategorySlug != null
                                    ? 'Aucun lieu pour ce filtre'
                                    : 'Aucun lieu trouvé',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.only(bottom: 24),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: _buildPlaceRows(places, isMuted),
                              ),
                            ),
                          ),
                        if (isLoadingMore)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height:
                                (!showInitialLoader &&
                                    !isLoadingMore &&
                                    places.isNotEmpty &&
                                    !_store.hasMorePlaces.value)
                                ? bottomListSpacing + 12
                                : bottomListSpacing,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: HomeTopHeader(
                    categoryFilterKey: _categoryFilterKey,
                    categories: _categories,
                    selectedCategorySlug: _selectedCategorySlug,
                    contributeButtonKey: _contributeButtonKey,
                    profileButtonKey: _profileButtonKey,
                    onContributeTap: _openContribute,
                    onDrawerTap: _openDrawer,
                    onCategorySelected: (category) {
                      final nextSlug = category?.slug;
                      if (_selectedCategorySlug == nextSlug) return;
                      setState(() => _selectedCategorySlug = nextSlug);
                      _loadPlaces(forceRefresh: true);
                    },
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
    if (_isLandscapePlace(place)) return _landscapeAspectRatio;
    if (_isPortraitPlace(place)) return _portraitAspectRatio;
    if (_isSquarePlace(place)) return 1;

    final preferred = _preferredAspectRatio(place);
    if (preferred != null) {
      return preferred.clamp(0.65, 1.55);
    }

    final resolved = _resolvedAspectRatios[place.id];
    if (resolved != null) {
      return resolved;
    }

    final primaryUrl = place.primaryMedia?.url ?? place.videoUrl ?? place.imageUrl;
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

  List<Widget> _buildPlaceRows(List<PlaceEntity> places, bool isMuted) {
    final rows = <Widget>[];
    final landscapes = <_PlaceGridItem>[];
    final portraits = <_PlaceGridItem>[];

    for (var index = 0; index < places.length; index++) {
      final item = _PlaceGridItem(index: index, place: places[index]);
      if (_isLandscapePlace(item.place)) {
        landscapes.add(item);
      } else {
        portraits.add(item);
      }
    }

    while (landscapes.isNotEmpty || portraits.isNotEmpty) {
      if (landscapes.isNotEmpty) {
        rows.add(_buildFullWidthPlace(landscapes.removeAt(0), isMuted));
      }

      if (portraits.isNotEmpty) {
        final first = portraits.removeAt(0);
        final second = portraits.isNotEmpty ? portraits.removeAt(0) : null;
        rows.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPlaceCard(first, isMuted)),
              if (second != null) ...[
                const SizedBox(width: 0),
                Expanded(child: _buildPlaceCard(second, isMuted)),
              ] else
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }
    }

    return rows;
  }

  Widget _buildFullWidthPlace(_PlaceGridItem item, bool isMuted) {
    return _buildPlaceCard(item, isMuted);
  }

  Widget _buildPlaceCard(_PlaceGridItem item, bool isMuted) {
    final card =
        PlaceCard(
              place: item.place,
              aspectRatio: _resolveAspectRatio(item.place),
              isMuted: isMuted,
              onTap: () => context.push('/place/${item.place.id}'),
            )
            .animate(delay: (50 + (item.index % 10) * 30).ms)
            .fadeIn(duration: 260.ms)
            .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);

    if (item.index == 0) {
      return Container(key: _firstPlaceCardKey, child: card);
    }
    return card;
  }

  double? _preferredAspectRatio(PlaceEntity place) {
    final media = place.primaryMedia;
    if (media == null) return null;

    final fromDimensions = media.aspectRatio;
    if (fromDimensions != null && fromDimensions.isFinite && fromDimensions > 0) {
      if (fromDimensions > 1.02) return _landscapeAspectRatio;
      if ((fromDimensions - 1).abs() < 0.05) return 1;
      return _portraitAspectRatio;
    }

    final ratio = _resolvedAspectRatios[place.id];
    if (ratio != null) {
      if (ratio > 1.02) return _landscapeAspectRatio;
      if ((ratio - 1).abs() < 0.05) return 1;
      return _portraitAspectRatio;
    }

    final fromUrl = _extractRatioFromUrl(media.url);
    if (fromUrl != null) {
      if (fromUrl > 1.02) return _landscapeAspectRatio;
      if ((fromUrl - 1).abs() < 0.05) return 1;
      return _portraitAspectRatio;
    }

    switch (media.orientation) {
      case 'portrait':
        return _portraitAspectRatio;
      case 'landscape':
        return _landscapeAspectRatio;
      case 'square':
        return 1.0;
    }

    final cached = MediaMetadataResolver.cachedRatio(media.url);
    if (cached != null) {
      if (cached > 1.02) return _landscapeAspectRatio;
      if ((cached - 1).abs() < 0.05) return 1;
      return _portraitAspectRatio;
    }
    return null;
  }

  bool _isLandscapePlace(PlaceEntity place) {
    final media = place.primaryMedia;
    if (media?.orientation == 'landscape') return true;
    final ratio = _preferredAspectRatio(place);
    return ratio != null && ratio > 1.02;
  }

  bool _isPortraitPlace(PlaceEntity place) {
    final media = place.primaryMedia;
    if (media?.orientation == 'portrait') return true;
    final ratio = _preferredAspectRatio(place);
    return ratio != null && ratio < 0.98;
  }

  bool _isSquarePlace(PlaceEntity place) {
    final media = place.primaryMedia;
    if (media?.orientation == 'square') return true;
    final ratio = _preferredAspectRatio(place);
    return ratio != null && (ratio - 1).abs() < 0.05;
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

class _PlaceGridItem {
  final int index;
  final PlaceEntity place;

  const _PlaceGridItem({required this.index, required this.place});
}

class _GuideCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isLast;
  final VoidCallback onNext;

  const _GuideCard({
    required this.title,
    required this.description,
    required this.isLast,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111111),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF2B2B2B),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF111111),
                  foregroundColor: Colors.white,
                ),
                onPressed: onNext,
                child: Text(isLast ? 'Terminer' : 'Suivant'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeMenuDrawer extends StatelessWidget {
  final VoidCallback onProfileTap;
  final VoidCallback onSectionsTap;
  final VoidCallback onContributeTap;
  final VoidCallback onPreferencesTap;

  const _HomeMenuDrawer({
    required this.onProfileTap,
    required this.onSectionsTap,
    required this.onContributeTap,
    required this.onPreferencesTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0F0F0F),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(
                children: [
                  AppLogoWidget(size: 30),
                  SizedBox(width: 12),
                  Text(
                    'MbokaTour',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0x22FFFFFF), height: 24),
            _DrawerAction(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              onTap: () {
                Navigator.of(context).pop();
                onProfileTap();
              },
            ),
            _DrawerAction(
              icon: Icons.grid_view_rounded,
              label: 'Sections',
              onTap: () {
                Navigator.of(context).pop();
                onSectionsTap();
              },
            ),
            _DrawerAction(
              icon: Icons.add_box_outlined,
              label: 'Contribuer',
              onTap: () {
                Navigator.of(context).pop();
                onContributeTap();
              },
            ),
            _DrawerAction(
              icon: Icons.tune_rounded,
              label: 'Preferences',
              onTap: () {
                Navigator.of(context).pop();
                onPreferencesTap();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      leading: Icon(icon, color: Colors.white70),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
