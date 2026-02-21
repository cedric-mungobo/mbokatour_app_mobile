import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class OtpScreen extends StatefulWidget {
  final String? initialEmail;

  const OtpScreen({super.key, this.initialEmail});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _otpSent = signal(false);
  final _isLoading = signal(false);
  late final Future<AuthRepositoryImpl> _repositoryFuture = _buildRepository();
  late final Future<CategoryRepositoryImpl> _categoryRepositoryFuture =
      _buildCategoryRepository();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

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
    _emailController.dispose();
    _otpController.dispose();
    _otpSent.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      NotificationService.warning(context, 'Veuillez entrer votre email');
      return;
    }

    _isLoading.value = true;
    try {
      final repository = await _repositoryFuture;
      await repository.sendOtpToEmail(email);
      if (!mounted) return;
      _otpSent.value = true;
      NotificationService.success(context, 'Code OTP envoyé');
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(context, 'Envoi OTP impossible: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (email.isEmpty || otp.isEmpty) {
      NotificationService.warning(context, 'Email et OTP sont requis');
      return;
    }

    _isLoading.value = true;
    try {
      final repository = await _repositoryFuture;
      await repository.verifyOtp(email, otp);
      if (!mounted) return;
      NotificationService.success(context, 'OTP vérifié avec succès');
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
    } catch (e) {
      if (!mounted) return;
      NotificationService.error(context, 'Vérification OTP impossible: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification OTP'),
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: Watch(
        (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Valider votre email',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez votre email puis le code OTP reçu.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'votre@email.com',
                    prefixIcon: Icon(AppIcons.email_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Code OTP',
                    hintText: '000000',
                    prefixIcon: Icon(AppIcons.lock_outline),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading.value ? null : _verifyOtp,
                    child: _isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Vérifier le code'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading.value ? null : _sendOtp,
                  child: Text(
                    _otpSent.value ? 'Renvoyer le code' : 'Envoyer le code',
                  ),
                ),
              ]
                  .animate(interval: 70.ms)
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
      ),
    );
  }
}
