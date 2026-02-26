import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';

class CategoryFilterChipsBar extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedSlug;
  final ValueChanged<CategoryEntity?> onSelected;
  final String allLabel;
  final bool darkMode;
  final EdgeInsetsGeometry? padding;

  const CategoryFilterChipsBar({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
    this.allLabel = 'Découverte',
    this.darkMode = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          _CategoryFilterChip(
            label: allLabel,
            isActive: selectedSlug == null,
            darkMode: darkMode,
            onTap: () => onSelected(null),
          ),
          for (final category in categories) ...[
            const SizedBox(width: 8),
            _CategoryFilterChip(
              label: category.name,
              isActive: selectedSlug == category.slug,
              darkMode: darkMode,
              onTap: () => onSelected(category),
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool darkMode;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.isActive,
    required this.darkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = darkMode ? Colors.white : Colors.black87;
    final activeFg = darkMode ? Colors.black87 : Colors.white;
    final inactiveBg = darkMode
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.04);
    final inactiveFg = darkMode ? Colors.white : Colors.black87;
    final inactiveBorder = darkMode ? Colors.white24 : Colors.black12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isActive ? activeBg : inactiveBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeFg : inactiveFg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
