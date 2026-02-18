import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_constants.dart';

class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // Token
  Future<void> saveToken(String token) async {
    await _prefs.setString(StorageConstants.userToken, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(StorageConstants.userToken);
  }

  Future<void> removeToken() async {
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

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

