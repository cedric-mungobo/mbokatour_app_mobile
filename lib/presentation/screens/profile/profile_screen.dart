import 'package:flutter/material.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../domain/entities/user_entity.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final Future<AuthRepositoryImpl> _repositoryFuture = _buildRepository();
  late final Future<UserEntity?> _userFuture = _loadUser();

  Future<AuthRepositoryImpl> _buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return AuthRepositoryImpl(
      googleSignIn: GoogleSignIn.instance,
      dioService: DioService(cacheService),
      cacheService: cacheService,
    );
  }

  Future<UserEntity?> _loadUser() async {
    final repository = await _repositoryFuture;
    return repository.getCurrentUser();
  }

  Future<void> _logout() async {
    final repository = await _repositoryFuture;
    await repository.signOut();
    if (!mounted) return;
    NotificationService.success(context, 'Déconnexion réussie');
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Profil'),
      ),
      body: FutureBuilder<UserEntity?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text('Utilisateur non connecté'));
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 42,
                backgroundImage:
                    (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                    ? const Icon(AppIcons.person_outline, size: 40)
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.name ?? 'Mon Profil',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  user.email,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileTile(
                icon: AppIcons.settings_outlined,
                title: 'Paramètres',
                subtitle: 'Préférences de compte et application',
              ),
              _ProfileTile(
                icon: AppIcons.favorite_border,
                title: 'Favoris',
                subtitle: 'Retrouver vos lieux sauvegardés',
              ),
              _ProfileTile(
                icon: AppIcons.history,
                title: 'Historique',
                subtitle: 'Dernières visites et recherches',
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _logout,
                  icon: const Icon(AppIcons.logout),
                  label: const Text('Se déconnecter'),
                ),
              ),
            ],
          );
        },
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
