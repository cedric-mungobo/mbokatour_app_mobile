import 'package:flutter/material.dart';
import 'package:mbokatour_app_mobile/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/dio_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../../../data/repositories/category_repository_impl.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isLoading = signal(false);
  late final Future<AuthRepositoryImpl> _repositoryFuture = _buildRepository();
  late final Future<CategoryRepositoryImpl> _categoryRepositoryFuture =
      _buildCategoryRepository();

  Future<AuthRepositoryImpl> _buildRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return AuthRepositoryImpl(
      googleSignIn: GoogleSignIn.instance,
      dioService: DioService(cacheService),
      cacheService: cacheService,
    );
  }

  Future<CategoryRepositoryImpl> _buildCategoryRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheService = CacheService(prefs);
    return CategoryRepositoryImpl(dioService: DioService(cacheService));
  }

  @override
  void dispose() {
    _identifiantController.dispose();
    _passwordController.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final identifiant = _identifiantController.text.trim();
    final password = _passwordController.text;
    if (identifiant.isEmpty || password.isEmpty) {
      NotificationService.warning(
        context,
        'Veuillez entrer email/téléphone et mot de passe',
      );
      return;
    }

    _isLoading.value = true;

    try {
      final repository = await _repositoryFuture;
      await repository.login(identifiant: identifiant, password: password);
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final cacheService = CacheService(prefs);
      final isOnboardingDone = await cacheService.isPreferencesOnboardingDone();
      if (isOnboardingDone) {
        if (!mounted) return;
        context.go('/home');
        return;
      }
      final categoryRepository = await _categoryRepositoryFuture;
      final selectedCategoryIds = await categoryRepository
          .getUserPreferenceCategoryIds();
      if (!mounted) return;
      if (selectedCategoryIds.isEmpty) {
        context.go('/preferences');
      } else {
        await cacheService.savePreferencesOnboardingDone(true);
        if (!mounted) return;
        context.go('/home');
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'email_not_verified') {
        NotificationService.warning(context, e.message);
        final maybeEmail = identifiant.contains('@') ? identifiant : '';
        context.go('/otp?email=$maybeEmail');
      } else {
        NotificationService.error(context, e.message);
      }
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(context, 'Connexion impossible.');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Watch(
        (context) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              const SizedBox(height: 22),
              const Text(
                'Connexion',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous avec email ou téléphone et mot de passe.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _identifiantController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email ou téléphone',
                  hintText: 'jean@example.com ou +243...',
                  prefixIcon: Icon(AppIcons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(AppIcons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading.value ? null : _login,
                  child: _isLoading.value
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Se connecter'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading.value ? null : () => context.go('/otp'),
                child: const Text('Vérifier mon OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
