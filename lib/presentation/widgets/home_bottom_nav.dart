import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';

class HomeBottomNav extends StatelessWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onExploreTap;
  final VoidCallback onContributeTap;
  final VoidCallback onSavedTap;
  final VoidCallback onProfileTap;
  final GlobalKey boredButtonKey;
  final GlobalKey contributeButtonKey;
  final GlobalKey profileButtonKey;

  const HomeBottomNav({
    super.key,
    required this.onHomeTap,
    required this.onExploreTap,
    required this.onContributeTap,
    required this.onSavedTap,
    required this.onProfileTap,
    required this.boredButtonKey,
    required this.contributeButtonKey,
    required this.profileButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(18, 0, 18, bottomInset > 0 ? 8 : 14),
      child: SizedBox(
        height: 66,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF060606),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavIconButton(
                        icon: Icons.home_rounded,
                        isActive: true,
                        onTap: onHomeTap,
                      ),
                    ),
                    Expanded(
                      child: _NavIconButton(
                        key: boredButtonKey,
                        icon: AppIcons.sentiment_satisfied_alt_outlined,
                        onTap: onExploreTap,
                      ),
                    ),
                    Expanded(
                      child: _NavCenterButton(
                        key: contributeButtonKey,
                        onTap: onContributeTap,
                      ),
                    ),
                    Expanded(
                      child: _NavIconButton(
                        icon: AppIcons.favorite_border,
                        onTap: onSavedTap,
                      ),
                    ),
                    Expanded(
                      child: _NavIconButton(
                        key: profileButtonKey,
                        icon: AppIcons.person_outline_rounded,
                        onTap: onProfileTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeSearchSheet extends StatefulWidget {
  final TextEditingController controller;
  final GlobalKey searchFieldKey;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  const HomeSearchSheet({
    super.key,
    required this.controller,
    required this.searchFieldKey,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  State<HomeSearchSheet> createState() => _HomeSearchSheetState();
}

class _HomeSearchSheetState extends State<HomeSearchSheet> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        key: widget.searchFieldKey,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.search, color: Colors.white54, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                cursorColor: Colors.white70,
                textInputAction: TextInputAction.search,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un lieu...',
                  hintStyle: TextStyle(
                    color: Colors.white38,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  tooltip: 'Effacer',
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged('');
                  },
                  icon: const Icon(Icons.close_rounded, color: Colors.white38),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;

  const _NavIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.white : Colors.white38;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Center(
        child: Icon(icon, color: color, size: isActive ? 28 : 24),
      ),
    );
  }
}

class _NavCenterButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NavCenterButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: const Center(
        child: Icon(AppIcons.search, color: Colors.white38, size: 22),
      ),
    );
  }
}
