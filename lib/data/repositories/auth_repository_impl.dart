import 'dart:io';

import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/dio_service.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({required this.code, required this.message});

  @override
  String toString() => 'AuthException($code): $message';
}

class AuthRepositoryImpl {
  final GoogleSignIn _googleSignIn;
  final DioService _dioService;
  final CacheService _cacheService;
  static Future<void>? _googleInitFuture;

  AuthRepositoryImpl({
    required GoogleSignIn googleSignIn,
    required DioService dioService,
    required CacheService cacheService,
  }) : _googleSignIn = googleSignIn,
       _dioService = dioService,
       _cacheService = cacheService;

  Future<UserEntity> signInWithGoogle() async {
    if (kDebugMode) {
      debugPrint('AUTH_GOOGLE: signInWithGoogle started');
    }
    try {
      await _ensureGoogleInitialized();

      GoogleSignInAccount? account = await _googleSignIn
          .attemptLightweightAuthentication();
      account ??= await _googleSignIn.authenticate();

      final user = UserModel(
        id: account.id,
        email: account.email,
        name: account.displayName,
        photoUrl: account.photoUrl,
      );

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          code: 'config_error',
          message: 'ID token Google indisponible.',
        );
      }

      // Exchange Google token with backend (Laravel) to obtain app auth token.
      final response = await _dioService.post(
        '/auth/google',
        data: {'token': idToken},
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'unknown_error',
          message: 'Réponse backend invalide.',
        );
      }

      final payload = data['data'];
      final payloadMap = payload is Map<String, dynamic> ? payload : null;

      final backendToken =
          (payloadMap?['access_token'] as String?) ??
          (data['token'] as String?);
      if (backendToken == null || backendToken.isEmpty) {
        throw const AuthException(
          code: 'config_error',
          message: 'Token backend manquant dans la réponse.',
        );
      }

      UserEntity finalUser = user;
      final backendUser = payloadMap?['user'] ?? data['user'];
      if (backendUser is Map<String, dynamic>) {
        finalUser = UserModel(
          id: (backendUser['id'] ?? user.id).toString(),
          email: (backendUser['email'] ?? user.email).toString(),
          name: backendUser['name']?.toString() ?? user.name,
          photoUrl:
              backendUser['photo_url']?.toString() ??
              backendUser['avatar']?.toString() ??
              user.photoUrl,
        );
      }

      await _cacheService.saveToken(backendToken);
      await _cacheService.saveUserId(finalUser.id);
      await _cacheService.saveUserEmail(finalUser.email);
      if (finalUser.name != null && finalUser.name!.isNotEmpty) {
        await _cacheService.saveUserName(finalUser.name!);
      }
      await _cacheService.saveLoginStatus(true);

      return finalUser;
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          throw const AuthException(
            code: 'cancelled',
            message: 'Connexion Google annulée.',
          );
        case GoogleSignInExceptionCode.clientConfigurationError:
        case GoogleSignInExceptionCode.providerConfigurationError:
        case GoogleSignInExceptionCode.uiUnavailable:
          throw const AuthException(
            code: 'config_error',
            message: 'Configuration Google Sign-In invalide.',
          );
        default:
          final details = '${e.description ?? ''} ${e.details ?? ''}'
              .toLowerCase();
          if (details.contains('network') ||
              details.contains('internet') ||
              details.contains('timeout') ||
              details.contains('socket')) {
            throw const AuthException(
              code: 'network_error',
              message: 'Problème réseau. Vérifiez votre connexion.',
            );
          }
          throw AuthException(
            code: 'unknown_error',
            message: 'Connexion Google échouée: ${e.code.name}',
          );
      }
    } on SocketException {
      throw const AuthException(
        code: 'network_error',
        message: 'Problème réseau. Vérifiez votre connexion.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        code: 'unknown_error',
        message: 'Erreur lors de la connexion Google: $e',
      );
    }
  }

  Future<void> sendOtpToEmail(String email) async {
    try {
      final response = await _dioService.post(
        '/auth/send-otp',
        data: {'email': email},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'unknown_error',
          message: 'Réponse backend invalide pour send-otp.',
        );
      }
      final success = body['success'] == true;
      if (!success) {
        throw AuthException(
          code: 'unknown_error',
          message: (body['message']?.toString() ?? 'Échec envoi OTP'),
        );
      }
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi de l\'OTP: $e');
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? passwordConfirmation,
  }) async {
    try {
      final response = await _dioService.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': passwordConfirmation ?? password,
        },
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'unknown_error',
          message: 'Réponse backend invalide pour register.',
        );
      }
      if (body['success'] != true) {
        throw AuthException(
          code: 'unknown_error',
          message: body['message']?.toString() ?? 'Échec inscription',
        );
      }
      // Register must not authenticate user until OTP is verified.
      await _cacheService.saveLoginStatus(false);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final validationErrors = data['errors'];
        if (validationErrors is Map<String, dynamic>) {
          for (final value in validationErrors.values) {
            if (value is List && value.isNotEmpty) {
              final message = value.first?.toString().trim();
              if (message != null && message.isNotEmpty) {
                throw AuthException(code: 'validation_error', message: message);
              }
            }
            final message = value?.toString().trim();
            if (message != null && message.isNotEmpty) {
              throw AuthException(code: 'validation_error', message: message);
            }
          }
        }

        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          throw AuthException(code: 'validation_error', message: message);
        }
      }

      throw const AuthException(
        code: 'network_error',
        message: 'Inscription impossible. Vérifiez les informations saisies.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        code: 'unknown_error',
        message: 'Erreur lors de l\'inscription.',
      );
    }
  }

  Future<UserEntity> login({
    required String identifiant,
    required String password,
  }) async {
    try {
      final response = await _dioService.post(
        '/auth/login',
        data: {'identifiant': identifiant, 'password': password},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'unknown_error',
          message: 'Réponse backend invalide pour login.',
        );
      }
      if (body['success'] != true) {
        final message = body['message']?.toString() ?? 'Échec connexion';
        final lower = message.toLowerCase();
        if (lower.contains('verify') ||
            lower.contains('vérifi') ||
            lower.contains('email_verified_at')) {
          throw const AuthException(
            code: 'email_not_verified',
            message: 'Email non vérifié. Veuillez valider l’OTP.',
          );
        }
        throw AuthException(code: 'unknown_error', message: message);
      }

      final payload = body['data'];
      if (payload is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'config_error',
          message: 'Payload login invalide.',
        );
      }
      final token =
          (payload['access_token'] as String?) ?? (payload['token'] as String?);
      final backendUser = payload['user'];
      if (token == null ||
          token.isEmpty ||
          backendUser is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'config_error',
          message: 'Champs user/token manquants dans login.',
        );
      }

      final user = UserModel(
        id: (backendUser['id'] ?? '').toString(),
        email: (backendUser['email'] ?? '').toString(),
        name: backendUser['name']?.toString(),
        photoUrl:
            backendUser['photo_url']?.toString() ??
            backendUser['avatar']?.toString(),
      );

      await _cacheService.saveToken(token);
      await _cacheService.saveUserId(user.id);
      await _cacheService.saveUserEmail(user.email);
      if (user.name != null && user.name!.isNotEmpty) {
        await _cacheService.saveUserName(user.name!);
      }
      await _cacheService.saveLoginStatus(true);

      return user;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final validationErrors = data['errors'];
        if (validationErrors is Map<String, dynamic>) {
          for (final value in validationErrors.values) {
            if (value is List && value.isNotEmpty) {
              final message = value.first?.toString().trim();
              if (message != null && message.isNotEmpty) {
                throw AuthException(code: 'validation_error', message: message);
              }
            }
            final message = value?.toString().trim();
            if (message != null && message.isNotEmpty) {
              throw AuthException(code: 'validation_error', message: message);
            }
          }
        }

        final message = data['message']?.toString().trim();
        if (message != null && message.isNotEmpty) {
          final lower = message.toLowerCase();
          if (lower.contains('verify') ||
              lower.contains('vérifi') ||
              lower.contains('email_verified_at')) {
            throw const AuthException(
              code: 'email_not_verified',
              message: 'Email non vérifié. Veuillez valider l’OTP.',
            );
          }
          throw AuthException(code: 'unknown_error', message: message);
        }
      }

      throw const AuthException(
        code: 'network_error',
        message: 'Connexion impossible. Vérifiez vos identifiants.',
      );
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException(
        code: 'unknown_error',
        message: 'Erreur lors de la connexion.',
      );
    }
  }

  Future<UserEntity> verifyOtp(String email, String otp) async {
    try {
      final response = await _dioService.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'unknown_error',
          message: 'Réponse backend invalide pour verify-otp.',
        );
      }

      final success = body['success'] == true;
      if (!success) {
        throw AuthException(
          code: 'unknown_error',
          message: body['message']?.toString() ?? 'Échec vérification OTP',
        );
      }

      final payload = body['data'];
      if (payload is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'config_error',
          message: 'Payload verify-otp invalide.',
        );
      }

      final token = payload['token'] as String?;
      final backendUser = payload['user'];
      if (token == null ||
          token.isEmpty ||
          backendUser is! Map<String, dynamic>) {
        throw const AuthException(
          code: 'config_error',
          message: 'Champs user/token manquants dans verify-otp.',
        );
      }

      final userModel = UserModel(
        id: (backendUser['id'] ?? '').toString(),
        email: (backendUser['email'] ?? '').toString(),
        name: backendUser['name']?.toString(),
        photoUrl:
            backendUser['photo_url']?.toString() ??
            backendUser['avatar']?.toString(),
      );

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
      try {
        await _dioService.post('/auth/logout');
      } catch (_) {
        // If backend logout fails, continue local cleanup anyway.
      }
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
      final response = await _dioService.get('/auth/me');
      final body = response.data;
      if (body is! Map<String, dynamic> || body['success'] != true) {
        return null;
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      final user = data['user'];
      if (user is! Map<String, dynamic>) return null;

      final parsedUser = UserEntity(
        id: (user['id'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        name: user['name']?.toString(),
        photoUrl: user['photo_url']?.toString() ?? user['avatar']?.toString(),
      );
      if (parsedUser.id.isEmpty || parsedUser.email.isEmpty) return null;

      await _cacheService.saveUserId(parsedUser.id);
      await _cacheService.saveUserEmail(parsedUser.email);
      if (parsedUser.name != null && parsedUser.name!.isNotEmpty) {
        await _cacheService.saveUserName(parsedUser.name!);
      }

      return parsedUser;
    } catch (e) {
      return null;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitFuture != null) {
      await _googleInitFuture;
      return;
    }

    final serverClientId = dotenv.env['GOOGLE_SERVER_CLIENT_ID']?.trim();
    final clientId = dotenv.env['GOOGLE_CLIENT_ID']?.trim();

    _googleInitFuture = _googleSignIn.initialize(
      clientId: (clientId != null && clientId.isNotEmpty) ? clientId : null,
      serverClientId: (serverClientId != null && serverClientId.isNotEmpty)
          ? serverClientId
          : null,
    );
    await _googleInitFuture;
  }
}
