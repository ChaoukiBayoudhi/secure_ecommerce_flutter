# Secure E-Commerce Flutter Client

A secure, production-ready Flutter mobile application client for a Django REST API-based e-commerce platform. This application implements industry-standard security practices including JWT authentication, Multi-Factor Authentication (MFA), WebAuthn/biometric authentication, and comprehensive security measures.

## 🎯 Overview

This Flutter application serves as the mobile client for a secure e-commerce backend system. It demonstrates best practices in secure mobile application development, including encrypted storage, secure token management, input validation, and protection against common security vulnerabilities.

## ✨ Features

### Authentication & Security
- **JWT-based Authentication**: Secure token-based authentication with automatic refresh
- **Multi-Factor Authentication (MFA/TOTP)**: Time-based One-Time Password support with QR code generation
- **WebAuthn/Biometric Authentication**: Face ID, Touch ID, and Windows Hello support via `local_auth`
- **Encrypted Storage**: Secure storage of sensitive data using `flutter_secure_storage`
- **Token Management**: Automatic token refresh and secure token storage
- **CSRF Protection**: Cross-Site Request Forgery protection
- **Input Validation**: Client-side validation for all user inputs
- **Rate Limiting**: Client-side rate limiting to prevent abuse

### User Features
- **User Registration**: Secure user registration with validation
- **User Login**: Secure login with MFA support
- **Dashboard**: User dashboard with role-based access
- **Monitoring Dashboard**: Security monitoring and audit logs (admin only)

### Technical Features
- **State Management**: Riverpod for reactive state management
- **Routing**: GoRouter for type-safe navigation with route guards
- **HTTP Client**: Dio with interceptors for authentication and error handling
- **Error Handling**: Comprehensive error handling and user feedback
- **Environment Configuration**: Environment-based configuration management

## 🏗️ Technology Stack

- **Flutter SDK**: 3.9.0+
- **Dart**: 3.9.0+
- **State Management**: `flutter_riverpod` 3.0.3
- **HTTP Client**: `dio` 5.9.0
- **Secure Storage**: `flutter_secure_storage` 9.2.4
- **Routing**: `go_router` 14.6.2
- **JWT Handling**: `jwt_decode` 0.3.1
- **MFA Support**: `qr_flutter` 4.1.0
- **Biometric Auth**: `local_auth` 2.3.0
- **Configuration**: `flutter_dotenv` 6.0.0
- **Utilities**: `intl`, `shared_preferences`, `crypto`

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.9.0 or higher)
- **Dart SDK** (3.9.0 or higher)
- **Android Studio** or **Xcode** (for mobile development)
- **Git**
- **Backend API** running (Django REST API)

## 🚀 Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/secure_ecommerce_flutter.git
   cd secure_ecommerce_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the root directory:
   ```env
   API_BASE_URL=http://localhost:8000
   API_URL=http://localhost:8000/api
   ENABLE_DEBUG_LOGGING=true
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Platform Support

- ✅ **Android** (API level 21+)
- ✅ **iOS** (iOS 12.0+)
- ✅ **Web** (with limitations for biometric features)
- ✅ **Windows** (with limitations for biometric features)
- ✅ **macOS** (with limitations for biometric features)
- ✅ **Linux** (with limitations for biometric features)

## 📁 Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart          # App configuration
│   ├── models/
│   │   └── user_model.dart          # Data models
│   ├── providers/
│   │   └── auth_providers.dart      # Riverpod providers
│   ├── routes/
│   │   └── app_router.dart          # Navigation & guards
│   └── services/
│       ├── auth_service.dart        # Authentication logic
│       ├── storage_service.dart     # Secure storage
│       ├── http_client_service.dart # HTTP client & interceptors
│       ├── mfa_service.dart         # MFA/TOTP
│       └── webauthn_service.dart    # WebAuthn/biometric
├── features/
│   ├── auth/
│   │   └── screens/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       └── unauthorized_screen.dart
│   ├── dashboard/
│   │   └── screens/
│   │       └── dashboard_screen.dart
│   └── monitoring/
│       └── screens/
│           └── monitoring_dashboard_screen.dart
└── main.dart
```

## 🔐 Security Features

### Token Management
- Tokens stored securely using `flutter_secure_storage`
- Automatic token refresh before expiration
- Token validation and error handling
- Secure token transmission via HTTPS

### Data Protection
- Encrypted storage for sensitive data
- No sensitive data in logs (disabled in production)
- Secure HTTP interceptors
- Input sanitization and validation

### Authentication
- JWT-based authentication
- MFA/TOTP support
- Biometric authentication (Face ID, Touch ID)
- Session management
- Automatic logout on token expiry

### Network Security
- HTTPS enforcement
- CSRF token handling
- Rate limiting
- Request/response interceptors
- Error handling without exposing sensitive information

## 🔧 Configuration

### Environment Variables

Create a `.env` file with the following variables:

```env
# API Configuration
API_BASE_URL=http://localhost:8000
API_URL=http://localhost:8000/api

# Debug Settings
ENABLE_DEBUG_LOGGING=true

# Security Settings
TOKEN_REFRESH_INTERVAL=840000  # 14 minutes in milliseconds
AUTO_LOGOUT_ON_EXPIRY=true
```

### Backend Integration

Ensure your Django backend is running and accessible at the configured API URL. The backend should support:

- JWT authentication endpoints
- MFA/TOTP endpoints
- WebAuthn endpoints
- User registration and login
- Role-based access control

## 📖 Usage

### Running the Application

```bash
# Development mode
flutter run

# Production build (Android)
flutter build apk --release

# Production build (iOS)
flutter build ios --release

# Production build (Web)
flutter build web --release
```

### Testing

```bash
# Run tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 🔄 Backend Integration

This Flutter client integrates with a Django REST API backend. Ensure the backend is configured with:

- CORS enabled for your Flutter app
- JWT authentication endpoints
- MFA/TOTP support
- WebAuthn support
- Rate limiting configured
- CSRF protection (for web)

## 📚 Documentation

For detailed implementation guides, see:

- [FLUTTER_IMPLEMENTATION_COMPLETE_GUIDE.md](./FLUTTER_IMPLEMENTATION_COMPLETE_GUIDE.md) - Complete implementation guide
- [SECURITY_REVIEW_AND_FIXES.md](./SECURITY_REVIEW_AND_FIXES.md) - Security review and fixes
- [FIXES_APPLIED_DETAILED.md](./FIXES_APPLIED_DETAILED.md) - Detailed fixes documentation
- [INSTALL_DEPENDENCIES.md](./INSTALL_DEPENDENCIES.md) - Dependency installation guide

## 🐛 Troubleshooting

### Common Issues

1. **Token refresh failures**
   - Check backend API is accessible
   - Verify token refresh endpoint is working
   - Check network connectivity

2. **Biometric authentication not working**
   - Ensure device supports biometric authentication
   - Check app permissions
   - Verify `local_auth` package is properly configured

3. **MFA QR code not displaying**
   - Check `qr_flutter` package is installed
   - Verify backend MFA setup endpoint
   - Check device permissions

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is part of a secure programming course at ISG Tunis. Please refer to your course materials for licensing information.

## 👥 Authors

- **ISG Tunis Secure Programming Course** - Initial work

## 🙏 Acknowledgments

- Flutter team for the excellent framework
- All package maintainers for their contributions
- ISG Tunis for the course materials

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Contact your course instructor
- Refer to the documentation files in the repository

---

**Note**: This is an educational project demonstrating secure mobile application development practices. Always follow security best practices in production environments.
