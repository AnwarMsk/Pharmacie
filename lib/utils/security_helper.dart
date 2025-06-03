import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper class for securely storing and retrieving sensitive information
class SecurityHelper {
  static final SecurityHelper _instance = SecurityHelper._internal();
  factory SecurityHelper() => _instance;
  
  SecurityHelper._internal();
  
  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: false,
    ),
  );
  
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userCredentialsKey = 'user_credentials';
  static const String _apiCredentialsKey = 'api_credentials';
  
  /// Stores the authentication token securely
  Future<void> storeAuthToken(String token) async {
    if (token.isEmpty) return;
    await _secureStorage.write(key: _authTokenKey, value: token);
  }
  
  /// Retrieves the stored authentication token
  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _authTokenKey);
  }
  
  /// Stores the refresh token securely
  Future<void> storeRefreshToken(String token) async {
    if (token.isEmpty) return;
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }
  
  /// Retrieves the stored refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }
  
  /// Stores user credentials as encrypted JSON
  Future<void> storeUserCredentials(Map<String, dynamic> credentials) async {
    if (credentials.isEmpty) return;
    final String jsonData = jsonEncode(credentials);
    await _secureStorage.write(key: _userCredentialsKey, value: jsonData);
  }
  
  /// Retrieves and decodes stored user credentials
  Future<Map<String, dynamic>?> getUserCredentials() async {
    final String? jsonData = await _secureStorage.read(key: _userCredentialsKey);
    if (jsonData == null || jsonData.isEmpty) return null;
    
    try {
      return jsonDecode(jsonData) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  /// Stores API credentials as encrypted JSON
  Future<void> storeApiCredentials(Map<String, String> credentials) async {
    if (credentials.isEmpty) return;
    final String jsonData = jsonEncode(credentials);
    await _secureStorage.write(key: _apiCredentialsKey, value: jsonData);
  }
  
  /// Retrieves and decodes stored API credentials
  Future<Map<String, String>?> getApiCredentials() async {
    final String? jsonData = await _secureStorage.read(key: _apiCredentialsKey);
    if (jsonData == null || jsonData.isEmpty) return null;
    
    try {
      final Map<String, dynamic> data = jsonDecode(jsonData);
      return data.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      return null;
    }
  }
  
  /// Stores any custom secure value with the given key
  Future<void> storeSecureData(String key, String value) async {
    if (key.isEmpty || value.isEmpty) return;
    await _secureStorage.write(key: key, value: value);
  }
  
  /// Retrieves a custom secure value by key
  Future<String?> getSecureData(String key) async {
    if (key.isEmpty) return null;
    return await _secureStorage.read(key: key);
  }
  
  /// Deletes a specific secure value by key
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  /// Clears all secure storage data (used during logout)
  Future<void> clearAllSecureData() async {
    await _secureStorage.deleteAll();
  }
  
  /// Checks if a specific key exists in secure storage
  Future<bool> containsKey(String key) async {
    return await _secureStorage.containsKey(key: key);
  }
  
  /// Retrieves all secure storage entries (for debugging only)
  Future<Map<String, String>> getAllSecureData() async {
    return await _secureStorage.readAll();
  }
}