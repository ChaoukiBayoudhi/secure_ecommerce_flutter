// Riverpod providers for authentication state management.
//
// Security considerations:
// - Uses singleton AuthService instance to maintain consistent state
// - Prevents multiple instances that could cause authentication inconsistencies
// - Properly manages user state across the application

// Import Riverpod - StateProvider is in the legacy module for Riverpod 3.0+
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth service provider
///
/// Uses the singleton instance of AuthService to ensure consistent state
/// across the entire application. This prevents authentication state
/// inconsistencies that could occur with multiple instances.
final authServiceProvider = Provider<AuthService>((ref) {
  // Use singleton instance instead of creating new instances
  // This ensures consistent authentication state across the app
  return AuthService();
});

/// Current user state provider
///
/// Manages the current authenticated user state.
/// StateProvider is part of flutter_riverpod package (version 3.0.3+).
/// If you see an error, run: flutter pub get
final currentUserProvider = StateProvider<User?>((ref) => null);

/// Is authenticated provider
///
/// Computed provider that returns true if a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Is admin provider
///
/// Computed provider that returns true if the current user is an admin
/// (either superuser or has ADMIN role).
final isAdminProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.isSuperuser == true || user?.hasRole('ADMIN') == true;
});
