import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/category_repository_impl.dart';
import '../../widgets/app_logo_widget.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const _backgroundImages = [
    'assets/images/card2.jpg',
    'assets/images/bg.jpg',
    'assets/images/card3.jpg',
  ];
  static const _googleLogo = 'assets/images/google-logo.png';

  int _currentImageIndex = 0;
  bool _isGoogleSigningIn = false;

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (_isGoogleSigningIn) return;
    setState(() => _isGoogleSigningIn = true);
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
    } finally {
      if (mounted) {
        setState(() => _isGoogleSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: AspectRatio(
                  aspectRatio: 0.76,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        itemCount: _backgroundImages.length,
                        onPageChanged: (index) {
                          if (!mounted) return;
                          setState(() => _currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Image.asset(
                            _backgroundImages[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                AppTheme.accentBlue.withValues(alpha: 0.10),
                                AppTheme.brandBlack.withValues(alpha: 0.10),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        top: 16,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            child: AppLogoWidget(size: 58),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_backgroundImages.length, (
                            index,
                          ) {
                            final isActive = index == _currentImageIndex;
                            return AnimatedContainer(
                              duration: 220.ms,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 8,
                              width: isActive ? 20 : 8,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 700.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.03, end: 0, duration: 700.ms),
              const SizedBox(height: 34),
              const Text(
                'Découvre les meilleurs\nlieux à Kinshasa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.brandBlack,
                  fontSize: 28,
                  height: 1.18,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 180.ms, duration: 600.ms),
              const SizedBox(height: 18),
              Text(
                'MbokaTour te révèle des endroits uniques à visiter, lieux touristiques, hôtels, restaurants etc..',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.hintColor,
                  fontSize: 15,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 280.ms, duration: 600.ms),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.brandBlack,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _isGoogleSigningIn
                            ? null
                            : () => _handleGoogleSignIn(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isGoogleSigningIn) ...[
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Connexion...',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Image.asset(
                                _googleLogo,
                                width: 20,
                                height: 20,
                              ),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'Continuer',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.brandBlack,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: _isGoogleSigningIn
                            ? null
                            : () => context.go('/login'),
                        child: const Text(
                          'Se connecter',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 420.ms, duration: 600.ms)
                  .slideY(begin: 0.04, end: 0, duration: 600.ms),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _isGoogleSigningIn
                      ? null
                      : () => context.go('/register'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.brandBlack,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Créer un compte'),
                ),
              ).animate().fadeIn(delay: 520.ms, duration: 560.ms),
            ],
          ),
        ),
      ),
    );
  }
}
