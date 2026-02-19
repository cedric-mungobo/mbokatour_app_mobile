import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/app_logo_widget.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  static const _backgroundImage = 'assets/images/bg.jpg';

  Future<void> _handleGoogleSignIn(BuildContext context) async {
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
        NotificationService.error(context, 'Configuration Google invalide.');
        return;
      }
      NotificationService.error(context, e.message);
    } catch (_) {
      if (context.mounted) {
        NotificationService.error(context, 'Connexion Google impossible');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_backgroundImage, fit: BoxFit.cover),
          Container(color: AppTheme.accentRed.withValues(alpha: 0.52)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  const AppLogoWidget(size: 120),
                  const SizedBox(height: 18),
                
                  const SizedBox(height: 10),
                  const Text(
                    'Découvre la RDC, autrement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Lieux, sorties, culture et nature autour de toi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Trouve des lieux sympas en 2 minutes.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 4),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.black,
                        
                        backgroundColor: Colors.white.withValues(alpha: 0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => _handleGoogleSignIn(context),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.g_mobiledata, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Se connecter avec Google',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
