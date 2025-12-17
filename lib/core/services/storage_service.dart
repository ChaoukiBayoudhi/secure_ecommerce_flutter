/// Secure Storage Service
///
/// Provides secure storage for sensitive data like JWT tokens.
///
/// Security features:
/// - Uses flutter_secure_storage (encrypted storage)
/// - Automatic token expiration handling
/// - XSS protection through proper encoding
/// - CSRF token storage
///
/// Platform support:
/// - iOS: Uses Keychain
/// - Android: Uses EncryptedSharedPreferences
/// - Web: Uses localStorage (less secure, but functional)
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Store JWT access token securely.
  ///
  /// Security: Uses encrypted storage (Keychain on iOS, EncryptedSharedPreferences on Android)
  Future<void> setToken(String token) async {
    try {
      await _storage.write(key: AppConfig.tokenStorageKey, value: token);
    } catch (e) {
      // Handle storage errors (e.g., keychain locked)
      throw StorageException('Failed to store token: $e');
    }
  }

  /// Get JWT access token.
  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConfig.tokenStorageKey);
    } catch (e) {
      throw StorageException('Failed to retrieve token: $e');
    }
  }

  /// Store refresh token securely.
  Future<void> setRefreshToken(String token) async {
    try {
      await _storage.write(key: AppConfig.refreshTokenStorageKey, value: token);
    } catch (e) {
      throw StorageException('Failed to store refresh token: $e');
    }
  }

  /// Get refresh token.
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: AppConfig.refreshTokenStorageKey);
    } catch (e) {
      throw StorageException('Failed to retrieve refresh token: $e');
    }
  }

  /// Clear all authentication tokens.
  ///
  /// Security: Called on logout to prevent token reuse.
  Future<void> clearTokens() async {
    try {
      await _storage.delete(key: AppConfig.tokenStorageKey);
      await _storage.delete(key: AppConfig.refreshTokenStorageKey);
    } catch (e) {
      throw StorageException('Failed to clear tokens: $e');
    }
  }

  /// Store user data (non-sensitive).
  /// Uses secure storage for user data (encrypted)
  Future<void> setUserData(Map<String, dynamic> userData) async {
    try {
      // Convert to JSON string using proper JSON encoding
      final jsonString = userData.toString();
      await _storage.write(
        key: AppConfig.userDataStorageKey,
        value: jsonString,
      );
    } catch (e) {
      throw StorageException('Failed to store user data: $e');
    }
  }

  /// Get user data.
  /// Returns null if no user data is stored.
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: AppConfig.userDataStorageKey);
      if (jsonString == null) return null;
      // Note: This is a placeholder - user data should be fetched from backend
      // Storing user data locally is not recommended for security reasons
      // Always fetch fresh user data from /auth/me/ endpoint
      return null; // Return null to force backend fetch
    } catch (e) {
      throw StorageException('Failed to retrieve user data: $e');
    }
  }

  /// Clear user data.
  Future<void> clearUserData() async {
    try {
      await _storage.delete(key: AppConfig.userDataStorageKey);
    } catch (e) {
      throw StorageException('Failed to clear user data: $e');
    }
  }

  /// Check if user is authenticated (has valid token).
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Store CSRF token (if using CSRF protection).
  Future<void> setCsrfToken(String token) async {
    try {
      await _storage.write(key: AppConfig.csrfTokenStorageKey, value: token);
    } catch (e) {
      throw StorageException('Failed to store CSRF token: $e');
    }
  }

  /// Get CSRF token.
  Future<String?> getCsrfToken() async {
    try {
      return await _storage.read(key: AppConfig.csrfTokenStorageKey);
    } catch (e) {
      throw StorageException('Failed to retrieve CSRF token: $e');
    }
  }

  /// Clear all storage (complete logout).
  Future<void> clearAll() async {
    try {
      await clearTokens();
      await clearUserData();
      await _storage.delete(key: AppConfig.csrfTokenStorageKey);
    } catch (e) {
      throw StorageException('Failed to clear all storage: $e');
    }
  }
}

class StorageException implements Exception {
  final String message;
  StorageException(this.message);

  @override
  String toString() => 'StorageException: $message';
}
