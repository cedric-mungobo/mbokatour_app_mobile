import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

class CacheService {
  static const _secureStorage = FlutterSecureStorage();
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // Token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageConstants.userToken, value: token);
    // Backward compatibility migration: ensure old plain token is removed.
    await _prefs.remove(StorageConstants.userToken);
  }

  Future<String?> getToken() async {
    final secureToken = await _secureStorage.read(key: StorageConstants.userToken);
    if (secureToken != null && secureToken.isNotEmpty) return secureToken;

    // Migration path for already installed app versions.
    final legacyToken = _prefs.getString(StorageConstants.userToken);
    if (legacyToken != null && legacyToken.isNotEmpty) {
      await _secureStorage.write(
        key: StorageConstants.userToken,
        value: legacyToken,
      );
      await _prefs.remove(StorageConstants.userToken);
      return legacyToken;
    }
    return null;
  }

  Future<void> removeToken() async {
    await _secureStorage.delete(key: StorageConstants.userToken);
    await _prefs.remove(StorageConstants.userToken);
  }

  // User ID
  Future<void> saveUserId(String userId) async {
    await _prefs.setString(StorageConstants.userId, userId);
  }

  Future<String?> getUserId() async {
    return _prefs.getString(StorageConstants.userId);
  }

  // User Email
  Future<void> saveUserEmail(String email) async {
    await _prefs.setString(StorageConstants.userEmail, email);
  }

  Future<String?> getUserEmail() async {
    return _prefs.getString(StorageConstants.userEmail);
  }

  // User Name
  Future<void> saveUserName(String name) async {
    await _prefs.setString(StorageConstants.userName, name);
  }

  Future<String?> getUserName() async {
    return _prefs.getString(StorageConstants.userName);
  }

  // Login Status
  Future<void> saveLoginStatus(bool isLoggedIn) async {
    await _prefs.setBool(StorageConstants.isLoggedIn, isLoggedIn);
  }

  Future<bool> isLoggedIn() async {
    return _prefs.getBool(StorageConstants.isLoggedIn) ?? false;
  }

  // Preferences onboarding
  Future<void> savePreferencesOnboardingDone(bool isDone) async {
    await _prefs.setBool(StorageConstants.preferencesOnboardingDone, isDone);
  }

  Future<bool> isPreferencesOnboardingDone() async {
    return _prefs.getBool(StorageConstants.preferencesOnboardingDone) ?? false;
  }

  // First-time textual guides
  Future<void> saveHomeGuideSeen(bool isSeen) async {
    await _prefs.setBool(StorageConstants.homeGuideSeen, isSeen);
  }

  Future<bool> isHomeGuideSeen() async {
    return _prefs.getBool(StorageConstants.homeGuideSeen) ?? false;
  }

  Future<void> saveHomeButtonsGuideSeen(bool isSeen) async {
    await _prefs.setBool(StorageConstants.homeButtonsGuideSeen, isSeen);
  }

  Future<bool> isHomeButtonsGuideSeen() async {
    return _prefs.getBool(StorageConstants.homeButtonsGuideSeen) ?? false;
  }

  Future<void> saveBoredGuideSeen(bool isSeen) async {
    await _prefs.setBool(StorageConstants.boredGuideSeen, isSeen);
  }

  Future<bool> isBoredGuideSeen() async {
    return _prefs.getBool(StorageConstants.boredGuideSeen) ?? false;
  }

  Future<void> savePreferencesGuideSeen(bool isSeen) async {
    await _prefs.setBool(StorageConstants.preferencesGuideSeen, isSeen);
  }

  Future<bool> isPreferencesGuideSeen() async {
    return _prefs.getBool(StorageConstants.preferencesGuideSeen) ?? false;
  }

  Future<void> saveProfileGuideSeen(bool isSeen) async {
    await _prefs.setBool(StorageConstants.profileGuideSeen, isSeen);
  }

  Future<bool> isProfileGuideSeen() async {
    return _prefs.getBool(StorageConstants.profileGuideSeen) ?? false;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _secureStorage.delete(key: StorageConstants.userToken);
    await _prefs.clear();
  }
}
