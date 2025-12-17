/// Application configuration and environment settings.
///
/// Security considerations:
/// - API URLs should be configured per environment
/// - Never expose sensitive keys in frontend code
/// - Use environment variables for configuration
library;

class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const String apiUrl = '$apiBaseUrl/api';

  // Security Configuration
  static const String tokenStorageKey = 'auth_token';
  static const String refreshTokenStorageKey = 'refresh_token';
  static const String csrfTokenStorageKey = 'csrf_token';
  static const String userDataStorageKey = 'user_data';

  // Token refresh interval (14 minutes before 15min expiry)
  static const Duration tokenRefreshInterval = Duration(minutes: 14);

  // Auto-logout on token expiry
  static const bool autoLogoutOnExpiry = true;

  // Enable CSRF protection
  static const bool enableCsrf = true;

  // Rate Limiting Configuration
  static const bool rateLimitingEnabled = true;
  static const int maxRequests = 100;
  static const Duration rateLimitWindow = Duration(minutes: 1);

  // Feature Flags
  static const bool mfaEnabled = true;
  static const bool webauthnEnabled = true;
  static const bool fileUploadEnabled = true;
  static const bool monitoringEnabled = true;

  // Request Timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Connection Timeout
  static const Duration connectTimeout = Duration(seconds: 10);

  // Receive Timeout
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Debug Logging (disable in production)
  // Set to true temporarily for debugging network issues
  static const bool enableDebugLogging =
      true; // TODO: Set to false in production
}
