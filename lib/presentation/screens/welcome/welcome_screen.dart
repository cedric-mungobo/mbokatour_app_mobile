import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../widgets/app_logo_widget.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (kDebugMode) {
      debugPrint('AUTH_GOOGLE: button pressed, starting flow');
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final repository = AuthRepositoryImpl(
        googleSignIn: GoogleSignIn.instance,
        dioService: DioService(cacheService),
        cacheService: cacheService,
      );
      final categoryRepository = CategoryRepositoryImpl(
        dioService: DioService(cacheService),
      );

      await repository.signInWithGoogle();

      if (context.mounted) {
        final isOnboardingDone = await cacheService
            .isPreferencesOnboardingDone();
        if (isOnboardingDone) {
          if (!context.mounted) return;
          context.go('/home');
          return;
        }
        final selectedCategoryIds = await categoryRepository
            .getUserPreferenceCategoryIds();
        if (!context.mounted) return;
        if (selectedCategoryIds.isEmpty) {
          context.go('/preferences');
        } else {
          await cacheService.savePreferencesOnboardingDone(true);
          if (!context.mounted) return;
          context.go('/home');
        }
      }
    } on AuthException catch (e) {
      if (!context.mounted) return;
      if (e.code == 'cancelled') {
        NotificationService.warning(
          context,
          'Connexion Google annulée par l’utilisateur.',
        );
        return;
      }
      if (e.code == 'network_error') {
        NotificationService.error(
          context,
          'Connexion internet indisponible. Réessayez.',
        );
        return;
      }
      if (e.code == 'config_error') {
        NotificationService.error(context, 'Configuration Google invalide .');
        return;
      }
      NotificationService.error(context, e.message);
    } catch (e) {
      if (context.mounted) {
        NotificationService.error(context, 'Connexion Google impossible');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              const AppLogoWidget(size: 180),
              const SizedBox(height: 24),

              Text(
                'Mbokatour',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Découvrez les meilleurs endroits',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: colorScheme.secondary),
              ),

              const Spacer(),

              // Bouton Google Sign-In
              OutlinedButton.icon(
                onPressed: () => _handleGoogleSignIn(context),
                icon: const Icon(Icons.g_mobiledata, size: 32),
                label: const Text('Se connecter avec Google'),
              ),

              const SizedBox(height: 16),

              // Bouton Email Login
              FilledButton.icon(
                onPressed: () {
                  context.go('/login');
                },
                icon: const Icon(Icons.email),
                label: const Text('Se connecter'),
              ),

              const SizedBox(height: 12),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.secondary,
                ),
                onPressed: () => context.go('/register'),
                child: const Text('Créer un compte'),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
