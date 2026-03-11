import 'package:flutter/material.dart';
import 'package:mbokatour_app_mobile/core/constants/app_config.dart';
import 'package:mbokatour_app_mobile/core/theme/app_theme.dart';

import '../../core/theme/app_icons.dart';
import '../../domain/entities/category_entity.dart';
import 'category_filter_chips_bar.dart';

class HomeTopHeader extends StatelessWidget {
  final GlobalKey categoryFilterKey;
  final List<CategoryEntity> categories;
  final String? selectedCategorySlug;
  final VoidCallback onContributeTap;
  final VoidCallback onDrawerTap;
  final ValueChanged<CategoryEntity?> onCategorySelected;
  final GlobalKey contributeButtonKey;
  final GlobalKey profileButtonKey;

  const HomeTopHeader({
    super.key,
    required this.categoryFilterKey,
    required this.categories,
    required this.selectedCategorySlug,
    required this.onContributeTap,
    required this.onDrawerTap,
    required this.onCategorySelected,
    required this.contributeButtonKey,
    required this.profileButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color:  AppTheme.brandBlack,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 2, 10, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _TopBarButton(
                      key: contributeButtonKey,
                      icon: AppIcons.add,
                      onTap: onContributeTap,
                    ),
                  ),
                  const _BrandWordmark(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _TopBarButton(
                      key: profileButtonKey,
                      icon: AppIcons.menu,
                      onTap: onDrawerTap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              key: categoryFilterKey,
              height: 28,
              child: CategoryFilterChipsBar(
                categories: categories,
                selectedSlug: selectedCategorySlug,
                darkMode: true,
                textOnly: true,
                allLabel: 'Decouverte',
                onSelected: onCategorySelected,
              ),
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.06)),
          ],
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFD54F), Color(0xFFFF7043), Color(0xFFD32F2F)],
      ).createShader(bounds),
      child: Text(
        'MbokaTour',
        maxLines: 1,
        overflow: TextOverflow.visible,
        style: baseStyle,
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopBarButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141414),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
