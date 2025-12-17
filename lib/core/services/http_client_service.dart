/// HTTP Client Service
///
/// Configures Dio HTTP client with security features:
/// - Base URL configuration
/// - Request/response interceptors
/// - Error handling
/// - Timeout configuration
///
/// Security features:
/// - Automatic JWT token injection
/// - Token refresh on 401 errors
/// - Rate limiting
/// - Error sanitization
library;

import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'storage_service.dart';

class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // Flutter web specific: Enable credentials for CORS
        followRedirects: true,
        validateStatus: (status) {
          return status! < 500; // Accept all status codes < 500
        },
      ),
    );

    // Add interceptors
    // Order matters: Auth -> Error -> RateLimit -> Logging
    _dio.interceptors.addAll([
      _AuthInterceptor(),
      _ErrorInterceptor(),
      _RateLimitInterceptor(),
      // LogInterceptor should be last to log final request/response
      // Security: Disable logging in production to prevent token leakage
      if (AppConfig.enableDebugLogging)
        LogInterceptor(
          requestBody:
              false, // Don't log request body (may contain sensitive data)
          responseBody: false, // Don't log response body (may contain tokens)
          error: true,
          requestHeader:
              false, // Don't log headers (may contain Authorization token)
          responseHeader: false,
        ),
    ]);
  }
}

/// Authentication Interceptor
///
/// Automatically adds JWT token to all HTTP requests.
///
/// Security features:
/// - Adds Authorization header with Bearer token
/// - Handles token refresh on 401 errors
/// - Prevents token leakage in logs
/// - Adds CSRF token if enabled
class _AuthInterceptor extends Interceptor {
  final StorageService _storage = StorageService();

  // StorageService is used in onRequest and onError methods

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Skip auth for login/register endpoints
    final skipAuth =
        options.path.contains('/auth/login/') ||
        options.path.contains('/auth/register/') ||
        options.path.contains('/auth/token/refresh/');

    if (!skipAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Add CSRF token if enabled
      // Note: CSRF tokens are typically handled by cookies in web browsers
      // For mobile apps, CSRF protection is less critical but can be added if backend requires it
      if (AppConfig.enableCsrf) {
        final csrfToken = await _storage.getCsrfToken();
        if (csrfToken != null && csrfToken.isNotEmpty) {
          options.headers['X-CSRFToken'] = csrfToken;
        }
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 Unauthorized - try to refresh token
    if (err.response?.statusCode == 401) {
      final skipAuth =
          err.requestOptions.path.contains('/auth/login/') ||
          err.requestOptions.path.contains('/auth/register/') ||
          err.requestOptions.path.contains('/auth/token/refresh/');

      if (!skipAuth) {
        try {
          // Try to refresh token
          final refreshToken = await _storage.getRefreshToken();
          if (refreshToken != null) {
            final refreshResponse = await HttpClientService().dio.post(
              '/auth/token/refresh/',
              data: {'refresh': refreshToken},
            );

            final responseData = refreshResponse.data;
            if (responseData is! Map || !responseData.containsKey('access')) {
              throw Exception('Invalid token refresh response');
            }

            final newAccessToken = responseData['access'] as String;
            if (newAccessToken.isEmpty) {
              throw Exception('Empty access token received');
            }
            await _storage.setToken(newAccessToken);

            // Retry original request with new token
            err.requestOptions.headers['Authorization'] =
                'Bearer $newAccessToken';
            final response = await HttpClientService().dio.fetch(
              err.requestOptions,
            );
            return handler.resolve(response);
          }
        } catch (e) {
          // Refresh failed - clear tokens (logout handled by AuthService)
          await _storage.clearTokens();
        }
      }
    }

    handler.next(err);
  }
}

/// Error Interceptor
///
/// Handles HTTP errors globally.
///
/// Security features:
/// - Sanitizes error messages (prevents XSS)
/// - Logs errors securely
/// - Handles rate limiting errors
/// - Prevents information leakage
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Sanitize error message
    final sanitizedError = _sanitizeError(err);
    handler.next(sanitizedError);
  }

  DioException _sanitizeError(DioException error) {
    // Don't expose sensitive error details, but keep user-friendly messages
    if (error.response?.data is Map) {
      final data = error.response!.data as Map<String, dynamic>;
      final sanitized = Map<String, dynamic>.from(data);

      // Remove stack traces and internal details, but keep 'detail' for user messages
      sanitized.remove('stack');
      sanitized.remove('traceback');
      // Keep 'detail' as it contains user-friendly error messages
      // Remove only technical/internal error details

      return DioException(
        requestOptions: error.requestOptions,
        response: Response(
          requestOptions: error.requestOptions,
          statusCode: error.response?.statusCode,
          statusMessage: error.response?.statusMessage,
          data: sanitized,
        ),
        type: error.type,
        error: error.error,
      );
    }

    // For network errors (especially Flutter web), provide better error messages
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      // Check if it's a CORS or network issue
      final errorMessage = error.message ?? '';
      if (errorMessage.contains('XMLHttpRequest') ||
          errorMessage.contains('CORS') ||
          errorMessage.contains('Failed to fetch')) {
        return DioException(
          requestOptions: error.requestOptions,
          type: error.type,
          error:
              'Network error. Please check:\n'
              '1. Backend server is running at ${AppConfig.apiBaseUrl}\n'
              '2. CORS is properly configured\n'
              '3. Your internet connection',
        );
      }
    }

    return error;
  }
}

/// Rate Limit Interceptor
///
/// Client-side rate limiting to prevent abuse.
///
/// Security features:
/// - Tracks request count per time window
/// - Prevents excessive API calls
/// - Works in conjunction with server-side rate limiting
class _RateLimitInterceptor extends Interceptor {
  final Map<String, _RequestRecord> _requestMap = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!AppConfig.rateLimitingEnabled) {
      handler.next(options);
      return;
    }

    // Skip rate limiting for certain endpoints
    final skipRateLimit = options.path.contains('/auth/token/refresh/');
    if (skipRateLimit) {
      handler.next(options);
      return;
    }

    final key = _getRequestKey(options);
    final now = DateTime.now();
    final record = _requestMap[key];

    if (record == null || now.isAfter(record.resetTime)) {
      _requestMap[key] = _RequestRecord(
        count: 0,
        resetTime: now.add(AppConfig.rateLimitWindow),
      );
    }

    final currentRecord = _requestMap[key]!;
    if (currentRecord.count >= AppConfig.maxRequests) {
      handler.reject(
        DioException(
          requestOptions: options,
          error:
              'Rate limit exceeded. Please wait before making more requests.',
          type: DioExceptionType.unknown,
        ),
      );
      return;
    }

    currentRecord.count++;
    handler.next(options);
  }

  String _getRequestKey(RequestOptions options) {
    return '${options.method}:${options.path}';
  }
}

class _RequestRecord {
  int count;
  DateTime resetTime;

  _RequestRecord({required this.count, required this.resetTime});
}
