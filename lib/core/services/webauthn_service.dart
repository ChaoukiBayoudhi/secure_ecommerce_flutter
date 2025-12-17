/// WebAuthn Service
///
/// Handles WebAuthn/Biometric Authentication (Face ID, Touch ID, Windows Hello, etc.).
///
/// Security features:
/// - Public key credential creation
/// - Biometric authentication
/// - Credential management
/// - FIDO2/WebAuthn standard compliance
///
/// Note: WebAuthn API is primarily for web browsers.
/// For mobile apps, consider using platform-specific biometric APIs:
/// - iOS: LocalAuthentication (Face ID, Touch ID)
/// - Android: BiometricPrompt (Fingerprint, Face)
/// - Flutter: local_auth package
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'http_client_service.dart';

class WebAuthnRegisterStartResponse {
  final String challenge;
  final Map<String, dynamic> rp;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> pubKeyCredParams;
  final int timeout;

  WebAuthnRegisterStartResponse({
    required this.challenge,
    required this.rp,
    required this.user,
    required this.pubKeyCredParams,
    required this.timeout,
  });

  factory WebAuthnRegisterStartResponse.fromJson(Map<String, dynamic> json) {
    return WebAuthnRegisterStartResponse(
      challenge: json['challenge'] as String,
      rp: json['rp'] as Map<String, dynamic>,
      user: json['user'] as Map<String, dynamic>,
      pubKeyCredParams: (json['pubKeyCredParams'] as List)
          .cast<Map<String, dynamic>>(),
      timeout: json['timeout'] as int? ?? 60000,
    );
  }
}

class WebAuthnAuthenticateStartResponse {
  final String challenge;
  final String rpId;
  final List<Map<String, dynamic>> allowCredentials;
  final String userVerification;
  final int timeout;

  WebAuthnAuthenticateStartResponse({
    required this.challenge,
    required this.rpId,
    required this.allowCredentials,
    required this.userVerification,
    required this.timeout,
  });

  factory WebAuthnAuthenticateStartResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return WebAuthnAuthenticateStartResponse(
      challenge: json['challenge'] as String,
      rpId: json['rpId'] as String,
      allowCredentials: (json['allowCredentials'] as List)
          .cast<Map<String, dynamic>>(),
      userVerification: json['userVerification'] as String? ?? 'preferred',
      timeout: json['timeout'] as int? ?? 60000,
    );
  }
}

class WebAuthnCredential {
  final int id;
  final String credentialId;
  final String publicKey;
  final int counter;
  final DateTime createdAt;
  final DateTime? lastUsed;

  WebAuthnCredential({
    required this.id,
    required this.credentialId,
    required this.publicKey,
    required this.counter,
    required this.createdAt,
    this.lastUsed,
  });

  factory WebAuthnCredential.fromJson(Map<String, dynamic> json) {
    return WebAuthnCredential(
      id: json['id'] as int,
      credentialId: json['credential_id'] as String,
      publicKey: json['public_key'] as String,
      counter: json['counter'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsed: json['last_used'] != null
          ? DateTime.parse(json['last_used'] as String)
          : null,
    );
  }
}

class WebAuthnService {
  static final WebAuthnService _instance = WebAuthnService._internal();
  factory WebAuthnService() => _instance;
  WebAuthnService._internal();

  final Dio _dio = HttpClientService().dio;

  /// Check if WebAuthn is supported in browser.
  ///
  /// Note: For mobile apps, use platform-specific biometric APIs instead.
  bool isSupported() {
    // WebAuthn is primarily for web browsers
    // For mobile, use local_auth package
    return false; // Simplified - check platform-specific support
  }

  /// Start WebAuthn registration.
  Future<Map<String, dynamic>> registerStart() async {
    try {
      final response = await _dio.post('/auth/webauthn/register/start/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete WebAuthn registration.
  Future<Map<String, dynamic>> registerComplete(
    String challengeId,
    Map<String, dynamic> credentialData,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/webauthn/register/complete/',
        data: {'challenge_id': challengeId, 'credential': credentialData},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Start WebAuthn authentication.
  ///
  /// Returns authentication options including challenge and allowed credentials.
  /// Throws exception if no credentials are registered.
  Future<Map<String, dynamic>> authenticateStart({String? email}) async {
    try {
      final response = await _dio.post(
        '/auth/webauthn/authenticate/start/',
        data: email != null ? {'email': email} : {},
      );
      final data = response.data as Map<String, dynamic>;

      // Check if user has registered credentials
      final options = data['options'] as Map<String, dynamic>?;
      if (options != null) {
        final allowCredentials = options['allowCredentials'] as List?;
        if (allowCredentials == null || allowCredentials.isEmpty) {
          throw Exception(
            'No WebAuthn credentials found. Please register biometric authentication first or use email/password login.',
          );
        }
      }

      return data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Complete WebAuthn authentication.
  Future<Map<String, dynamic>> authenticateComplete(
    String challengeId,
    String credentialId,
    Map<String, dynamic> signature,
  ) async {
    try {
      final response = await _dio.post(
        '/auth/webauthn/authenticate/complete/',
        data: {
          'challenge_id': challengeId,
          'credential_id': credentialId,
          'signature': signature,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Get user's WebAuthn credentials.
  Future<List<WebAuthnCredential>> getCredentials() async {
    try {
      final response = await _dio.get('/auth/webauthn/credentials/');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map(
            (json) => WebAuthnCredential.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Revoke a WebAuthn credential.
  Future<Map<String, dynamic>> revokeCredential(int credentialId) async {
    try {
      final response = await _dio.post(
        '/auth/webauthn/revoke/',
        data: {'credential_id': credentialId},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Convert ArrayBuffer to Base64 URL-safe string.
  String arrayBufferToBase64(Uint8List buffer) {
    return base64Url.encode(buffer);
  }

  /// Convert Base64 URL-safe string to ArrayBuffer.
  Uint8List base64ToArrayBuffer(String base64) {
    return base64Url.decode(base64);
  }

  Exception _handleError(DioException error) {
    String errorMessage = 'WebAuthn operation failed';

    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        errorMessage = data['detail'] as String;
      } else if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'] as String;
      }
    } else if (error.message != null) {
      errorMessage = error.message!;
    }

    return Exception(errorMessage);
  }
}
