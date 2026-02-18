import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';
import '../../../core/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _otpSent = signal(false);
  final _isLoading = signal(false);

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _otpSent.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailController.text.isEmpty) {
      NotificationService.warning(context, 'Veuillez entrer votre email');
      return;
    }

    _isLoading.value = true;

    // TODO: Implémenter l'envoi de l'OTP
    await Future.delayed(const Duration(seconds: 1));

    _isLoading.value = false;
    _otpSent.value = true;

    if (mounted) {
      NotificationService.success(context, 'Code OTP envoyé à votre email');
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.isEmpty) {
      NotificationService.warning(context, 'Veuillez entrer le code OTP');
      return;
    }

    _isLoading.value = true;

    // TODO: Implémenter la vérification de l'OTP
    await Future.delayed(const Duration(seconds: 1));

    _isLoading.value = false;

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion par Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Watch((context) {
            final otpSent = _otpSent.value;
            final isLoading = _isLoading.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                const Text(
                  'Connexion OTP',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Entrez votre email pour recevoir un code de vérification',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // Champ Email
                TextField(
                  controller: _emailController,
                  enabled: !otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'votre@email.com',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Champ OTP (visible après envoi)
                if (otpSent) ...[
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Code OTP',
                      hintText: '000000',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bouton d'action
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (otpSent ? _verifyOtp : _sendOtp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(otpSent ? 'Vérifier le code' : 'Envoyer le code'),
                ),

                if (otpSent) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: isLoading ? null : _sendOtp,
                    child: const Text('Renvoyer le code'),
                  ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}
