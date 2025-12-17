/// MFA/TOTP Service
///
/// Handles Multi-Factor Authentication using TOTP (Time-based One-Time Password).
///
/// Security features:
/// - QR code generation for TOTP setup
/// - Secure TOTP code verification
/// - MFA status management
library;

import 'package:dio/dio.dart';
import 'http_client_service.dart';

class TOTPSetupResponse {
  final String? message;
  final String secret;
  final String qrCode; // Base64 encoded QR code image data URL
  final String? uri; // TOTP URI
  final String? instructions;

  TOTPSetupResponse({
    this.message,
    required this.secret,
    required this.qrCode,
    this.uri,
    this.instructions,
  });

  factory TOTPSetupResponse.fromJson(Map<String, dynamic> json) {
    return TOTPSetupResponse(
      message: json['message'] as String?,
      secret: json['secret'] as String,
      qrCode: json['qr_code'] as String,
      uri: json['uri'] as String?,
      instructions: json['instructions'] as String?,
    );
  }
}

class TOTPVerifyResponse {
  final String message;
  final bool? mfaEnabled;

  TOTPVerifyResponse({required this.message, this.mfaEnabled});

  factory TOTPVerifyResponse.fromJson(Map<String, dynamic> json) {
    return TOTPVerifyResponse(
      message: json['message'] as String,
      mfaEnabled: json['mfa_enabled'] as bool?,
    );
  }
}

class MfaService {
  static final MfaService _instance = MfaService._internal();
  factory MfaService() => _instance;
  MfaService._internal();

  final Dio _dio = HttpClientService().dio;

  /// Setup TOTP for user.
  /// Returns secret and QR code URL.
  Future<TOTPSetupResponse> setupTOTP() async {
    try {
      final response = await _dio.post('/auth/totp/setup/');
      return TOTPSetupResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify TOTP code during setup.
  Future<TOTPVerifyResponse> verifyTOTPSetup(String code) async {
    try {
      final response = await _dio.post(
        '/auth/totp/verify/',
        data: {'code': code},
      );
      return TOTPVerifyResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Disable TOTP for user.
  ///
  /// Security: Requires TOTP code verification before disabling.
  Future<TOTPVerifyResponse> disableTOTP(String code) async {
    try {
      final response = await _dio.post(
        '/auth/totp/disable/',
        data: {'code': code},
      );
      return TOTPVerifyResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Verify TOTP code during login.
  /// Note: This uses the same endpoint as setup verification.
  Future<TOTPVerifyResponse> verifyTOTPLogin(String code) async {
    try {
      final response = await _dio.post(
        '/auth/totp/verify/',
        data: {'code': code},
      );
      return TOTPVerifyResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    String errorMessage = 'MFA operation failed';

    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('detail')) {
        errorMessage = data['detail'] as String;
      } else if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'] as String;
      }
    }

    return Exception(errorMessage);
  }
}
