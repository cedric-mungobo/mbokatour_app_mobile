import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:mbokatour_app_mobile/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/media_settings_service.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/stores/place_store.dart';
import '../../../domain/entities/place_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../widgets/bored_bottom_sheet.dart';
import '../../widgets/category_filter_chips_bar.dart';
import '../../widgets/home_bottom_nav.dart';
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
  List<CategoryEntity> _categories = const [];
  String? _selectedCategorySlug;
  bool _isBootstrapping = true;
  bool _hasStartedGuide = false;

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
    if (mounted && _store.errorMessage.value != null) {
      NotificationService.error(context, _store.errorMessage.value!);
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _loadPlaces);
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

  void _openSections() {
    context.go('/sections');
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
        title: 'Profil',
        description:
            'Appuyez ici pour accéder à votre profil et gérer votre compte.',
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
    final topInset = MediaQuery.of(context).padding.top;
    const topFiltersHeight = 42.0;
    const gridTopSpacing = 8.0;
    const bottomDockHeight = 96.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.brandBlack,
        bottomNavigationBar:
            HomeBottomNav(
                  onHomeTap: () {},
                  onExploreTap: _openBoredSheet,
                  onContributeTap: _openSearchSheet,
                  onSavedTap: _openSections,
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
                        _store.loadMorePlaces(
                          query: _searchController.text,
                          categorySlug: _selectedCategorySlug,
                        );
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: () => _loadPlaces(forceRefresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: topInset + topFiltersHeight + gridTopSpacing,
                          bottom: bottomDockHeight,
                        ),
                        children: [
                          if (showInitialLoader)
                            const SizedBox(
                              height: 380,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (places.isEmpty)
                            SizedBox(
                              height: 380,
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
                            MasonryGridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: places.length,
                              itemBuilder: (context, index) {
                                final place = places[index];
                                final card =
                                    PlaceCard(
                                          place: place,
                                          aspectRatio: _resolveAspectRatio(
                                            place,
                                          ),
                                          isMuted: isMuted,
                                          onTap: () => context.push(
                                            '/place/${place.id}',
                                          ),
                                        )
                                        .animate(
                                          delay: (50 + (index % 10) * 30).ms,
                                        )
                                        .fadeIn(duration: 260.ms)
                                        .slideY(
                                          begin: 0.04,
                                          end: 0,
                                          curve: Curves.easeOutCubic,
                                        );
                                if (index == 0) {
                                  return Container(
                                    key: _firstPlaceCardKey,
                                    child: card,
                                  );
                                }
                                return card;
                              },
                            ),
                          if (isLoadingMore)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          if (!showInitialLoader &&
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
                  left: 10,
                  right: 10,
                  top: topInset + 6,
                  child:
                      SizedBox(
                            key: _categoryFilterKey,
                            height: topFiltersHeight,
                            child: CategoryFilterChipsBar(
                              categories: _categories,
                              selectedSlug: _selectedCategorySlug,
                              darkMode: true,
                              allLabel: 'Decouverte',
                              onSelected: (category) {
                                final nextSlug = category?.slug;
                                if (_selectedCategorySlug == nextSlug) return;
                                setState(
                                  () => _selectedCategorySlug = nextSlug,
                                );
                                _loadPlaces(forceRefresh: true);
                              },
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 140.ms, duration: 280.ms)
                          .slideY(
                            begin: -0.04,
                            end: 0,
                            curve: Curves.easeOutCubic,
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
