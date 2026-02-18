import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/dio_service.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final DioService _dioService;
  final CacheService _cacheService;

  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required DioService dioService,
    required CacheService cacheService,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _dioService = dioService,
       _cacheService = cacheService;

  Future<UserEntity> signInWithGoogle() async {
    try {
      // Note: Pour l'instant, cette méthode est simplifiée
      // TODO: Implémenter la connexion Google avec la nouvelle API (v7.x)
      // Voir: https://pub.dev/packages/google_sign_in

      // Simulation pour le développement
      throw UnimplementedError(
        'Google Sign-In nécessite une configuration Firebase complète. '
        'Veuillez configurer Firebase et implémenter la nouvelle API google_sign_in 7.x',
      );
    } catch (e) {
      throw Exception('Erreur lors de la connexion Google: $e');
    }
  }

  Future<void> sendOtpToEmail(String email) async {
    try {
      // Appel API pour envoyer l'OTP
      await _dioService.post('/auth/send-otp', data: {'email': email});
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'OTP: $e');
    }
  }

  Future<UserEntity> verifyOtp(String email, String otp) async {
    try {
      // Appel API pour vérifier l'OTP
      final response = await _dioService.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );

      final userModel = UserModel.fromJson(response.data['user']);
      final token = response.data['token'] as String;

      // Sauvegarder dans le cache
      await _cacheService.saveToken(token);
      await _cacheService.saveUserId(userModel.id);
      await _cacheService.saveUserEmail(userModel.email);
      if (userModel.name != null) {
        await _cacheService.saveUserName(userModel.name!);
      }
      await _cacheService.saveLoginStatus(true);

      return userModel;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'OTP: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _cacheService.clearAll();
    } catch (e) {
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    return await _cacheService.isLoggedIn();
  }

  Future<UserEntity?> getCurrentUser() async {
    try {
      final userId = await _cacheService.getUserId();
      final email = await _cacheService.getUserEmail();
      final name = await _cacheService.getUserName();

      if (userId == null || email == null) {
        return null;
      }

      return UserEntity(id: userId, email: email, name: name);
    } catch (e) {
      return null;
    }
  }
}
