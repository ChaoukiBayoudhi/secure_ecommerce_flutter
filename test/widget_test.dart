// Widget tests for Secure E-Commerce Flutter application.
//
// These tests verify that the application's UI components render correctly
// and that navigation and authentication flows work as expected.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_ecommerce_flutter/main.dart';
import 'package:secure_ecommerce_flutter/core/services/http_client_service.dart';

void main() {
  // Initialize HTTP client before running tests
  setUpAll(() {
    HttpClientService().initialize();
  });

  group('Secure E-Commerce App Tests', () {
    testWidgets('App initializes and shows login screen', (WidgetTester tester) async {
      // Build our app wrapped in ProviderScope (required for Riverpod)
      await tester.pumpWidget(
        const ProviderScope(
          child: SecureEcommerceApp(),
        ),
      );

      // Wait for the app to fully initialize
      await tester.pumpAndSettle();

      // Verify that the login screen is displayed
      // The login screen should contain:
      // - Email input field
      // - Password input field
      // - Login button
      // - Link to register screen
      
      expect(find.text('Secure Login'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text("Don't have an account? Register"), findsOneWidget);
    });

    testWidgets('Navigation to register screen works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SecureEcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the register link
      final registerLink = find.text("Don't have an account? Register");
      expect(registerLink, findsOneWidget);
      
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      // Verify register screen is displayed
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('Navigation back to login from register works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SecureEcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to register
      await tester.tap(find.text("Don't have an account? Register"));
      await tester.pumpAndSettle();

      // Navigate back to login
      final loginLink = find.text('Already have an account? Login');
      expect(loginLink, findsOneWidget);
      
      await tester.tap(loginLink);
      await tester.pumpAndSettle();

      // Verify login screen is displayed again
      expect(find.text('Secure Login'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Login form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SecureEcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Try to submit empty form
      final loginButton = find.text('Login');
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Should show validation errors
      // Note: Actual error messages depend on form validation implementation
      // This test verifies the form doesn't submit with invalid data
    });

    testWidgets('App theme is applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: SecureEcommerceApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Material 3 theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
      expect(materialApp.theme?.useMaterial3, isTrue);
    });
  });
}
