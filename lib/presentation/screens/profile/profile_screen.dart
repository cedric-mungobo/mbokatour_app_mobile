import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.person_outline, size: 40),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Mon Profil',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
          _ProfileTile(
            icon: Icons.settings_outlined,
            title: 'Paramètres',
            subtitle: 'Préférences de compte et application',
          ),
          _ProfileTile(
            icon: Icons.favorite_border,
            title: 'Favoris',
            subtitle: 'Retrouver vos lieux sauvegardés',
          ),
          _ProfileTile(
            icon: Icons.history,
            title: 'Historique',
            subtitle: 'Dernières visites et recherches',
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }
}
