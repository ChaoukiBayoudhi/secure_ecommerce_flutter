/// Application Router
///
/// Defines all routes and navigation guards.
///
/// Security features:
/// - Route guards for protected routes
/// - Role-based access control
/// - Admin-only routes
library;

import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/monitoring/screens/monitoring_dashboard_screen.dart';
import '../../features/auth/screens/unauthorized_screen.dart';
import '../services/auth_service.dart';

class AppRouter {
  static final AuthService _authService = AuthService();

  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      // Check authentication status
      // Note: This checks in-memory state. For app restart, check storage
      final isAuthenticated = _authService.isAuthenticated;
      final isLoginRoute =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Redirect to login if not authenticated and trying to access protected route
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      // Redirect to dashboard if authenticated and on login/register
      if (isAuthenticated && isLoginRoute) {
        return '/dashboard';
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        redirect: (context, state) {
          if (!_authService.isAuthenticated) {
            return '/login';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/monitoring',
        name: 'monitoring',
        builder: (context, state) => const MonitoringDashboardScreen(),
        redirect: (context, state) {
          if (!_authService.isAuthenticated) {
            return '/login';
          }
          if (!_authService.isAdmin) {
            return '/unauthorized';
          }
          return null;
        },
      ),
      GoRoute(
        path: '/unauthorized',
        name: 'unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
    ],
  );
}
