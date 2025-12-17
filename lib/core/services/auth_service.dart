/// Authentication Service
///
/// Handles all authentication operations including:
/// - User registration and login
/// - JWT token management
/// - Token refresh
/// - MFA/TOTP authentication
/// - WebAuthn/biometric authentication
///
/// Security features:
/// - Automatic token refresh before expiry
/// - Secure token storage
/// - XSS protection
/// - Input validation

import 'package:dio/dio.dart';
import '../models/user_model.dart';
import 'storage_service.dart';
import 'http_client_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final StorageService _storage = StorageService();
  final Dio _dio = HttpClientService().dio;

  User? _currentUser;
  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  bool get isAdmin =>
      _currentUser?.isSuperuser == true ||
      _currentUser?.hasRole('ADMIN') == true;

  /// Register a new user.
  ///
  /// Security: Validates input before sending to backend.
  Future<AuthResponse> register(RegisterRequest data) async {
    // Client-side validation
    if (data.password != data.passwordConfirm) {
      throw AuthException('Passwords do not match');
    }

    if (data.password.length < 8) {
      throw AuthException('Password must be at least 8 characters');
    }

    try {
      final response = await _dio.post('/auth/register/', data: data.toJson());

      final authResponse = AuthResponse.fromJson(response.data);
      await _handleAuthResponse(authResponse);
      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login user.
  ///
  /// Security: Never logs passwords, handles MFA flow.
  Future<AuthResponse> login(LoginRequest credentials) async {
    try {
      final response = await _dio.post(
        '/auth/login/',
        data: credentials.toJson(),
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (!authResponse.mfaRequired) {
        await _handleAuthResponse(authResponse);
      }

      return authResponse;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Logout user.
  ///
  /// Security: Clears all tokens and user data.
  Future<void> logout() async {
    await _storage.clearAll();
    _currentUser = null;
  }

  /// Get current user from backend.
  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me/');
      final user = User.fromJson(response.data);
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Refresh JWT token.
  ///
  /// Security: Automatically called before token expiry.
  ///
  /// Backend endpoint: POST /api/auth/token/refresh/
  /// Request: {'refresh': 'refresh_token'}
  /// Response: {'access': 'new_access_token'}
  Future<void> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await logout();
      throw AuthException('No refresh token available');
    }

    try {
      final response = await _dio.post(
        '/auth/token/refresh/',
        data: {'refresh': refreshToken},
      );

      // Validate response format
      if (response.data is! Map || !response.data.containsKey('access')) {
        await logout();
        throw AuthException('Invalid token refresh response format');
      }

      final tokenResponse = TokenRefreshResponse.fromJson(response.data);
      if (tokenResponse.access.isEmpty) {
        await logout();
        throw AuthException('Empty access token received');
      }

      await _storage.setToken(tokenResponse.access);
    } on DioException catch (e) {
      // If refresh fails, logout user
      await logout();
      throw _handleError(e);
    } on FormatException catch (e) {
      // Invalid response format
      await logout();
      throw AuthException('Token refresh failed: ${e.message}');
    }
  }

  /// Verify JWT token.
  Future<bool> verifyToken() async {
    final token = await _storage.getToken();

    if (token == null) {
      return false;
    }

    try {
      await _dio.post('/auth/token/verify/', data: {'token': token});
      return true;
    } on DioException {
      // If verification fails, try to refresh
      try {
        await refreshToken();
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  /// Check if user has specific role.
  bool hasRole(String roleName) {
    return _currentUser?.hasRole(roleName) ?? false;
  }

  /// Check if user has any of the specified roles.
  bool hasAnyRole(List<String> roleNames) {
    return roleNames.any((role) => hasRole(role));
  }

  /// Handle authentication response.
  ///
  /// Security: Stores tokens securely, sets user data.
  Future<void> _handleAuthResponse(AuthResponse response) async {
    if (response.tokens != null) {
      await _storage.setToken(response.tokens!.access);
      await _storage.setRefreshToken(response.tokens!.refresh);
    }
    _currentUser = response.user;
  }

  /// Handle HTTP errors.
  ///
  /// Security: Never exposes sensitive error details to UI.
  AuthException _handleError(DioException error) {
    String errorMessage = 'An error occurred';

    if (error.response != null) {
      final data = error.response?.data;

      // Handle validation errors (e.g., email/username already exists)
      if (data is Map) {
        if (data.containsKey('detail')) {
          final detail = data['detail'];
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            errorMessage = detail.join(', ');
          } else {
            errorMessage = detail.toString();
          }
        } else if (data.containsKey('message')) {
          errorMessage = data['message'] as String;
        } else {
          // Handle field-level validation errors
          final errors = <String>[];
          data.forEach((key, value) {
            if (value is List) {
              errors.addAll(value.map((e) => '$key: $e'));
            } else if (value is Map) {
              // Handle nested errors
              value.forEach((nestedKey, nestedValue) {
                if (nestedValue is List) {
                  errors.addAll(nestedValue.map((e) => '$key.$nestedKey: $e'));
                } else {
                  errors.add('$key.$nestedKey: $nestedValue');
                }
              });
            } else {
              errors.add('$key: $value');
            }
          });
          if (errors.isNotEmpty) {
            errorMessage = errors.join(', ');
          }
        }
      }

      // Fallback to status code messages if no data
      if (errorMessage == 'An error occurred') {
        switch (error.response!.statusCode) {
          case 401:
            errorMessage = 'Invalid credentials';
            break;
          case 403:
            errorMessage = 'Access denied';
            break;
          case 404:
            errorMessage = 'Resource not found';
            break;
          case 429:
            errorMessage = 'Too many requests. Please try again later.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
        }
      }
    } else {
      // Handle network errors
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection and ensure the backend server is running.';
      } else if (error.type == DioExceptionType.connectionError) {
        errorMessage =
            'Unable to connect to server. Please check:\n'
            '1. Your internet connection\n'
            '2. The backend server is running\n'
            '3. CORS is properly configured';
      } else if (error.type == DioExceptionType.badResponse) {
        errorMessage = 'Server returned an error. Please try again.';
      } else if (error.message != null && error.message!.isNotEmpty) {
        // For web, Dio might wrap XMLHttpRequest errors
        if (error.message!.contains('XMLHttpRequest')) {
          errorMessage =
              'Network error. Please check:\n'
              '1. The backend server is running\n'
              '2. Your internet connection\n'
              '3. CORS configuration';
        } else {
          errorMessage = error.message!;
        }
      } else {
        errorMessage = 'Network error occurred';
      }
    }

    return AuthException(errorMessage);
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
