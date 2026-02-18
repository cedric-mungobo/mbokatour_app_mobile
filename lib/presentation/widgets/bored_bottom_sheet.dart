import 'package:flutter/material.dart';

enum BoredAction { nearby, special }

Future<BoredAction?> showBoredBottomSheet(BuildContext context) {
  return showModalBottomSheet<BoredAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _BoredBottomSheet(),
  );
}

class _BoredBottomSheet extends StatelessWidget {
  const _BoredBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Je m\'ennuie',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.near_me_outlined,
              title: 'Les lieux proches de moi',
              subtitle: 'Découvrir les meilleurs spots autour de vous',
              onTap: () => Navigator.of(context).pop(BoredAction.nearby),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              icon: Icons.auto_awesome_outlined,
              title: 'Section spéciale',
              subtitle: 'Sélection spéciale pour sortir maintenant',
              onTap: () => Navigator.of(context).pop(BoredAction.special),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
