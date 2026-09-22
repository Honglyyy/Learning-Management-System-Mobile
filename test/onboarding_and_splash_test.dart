import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lms_flutter/core/constants/app_constants.dart';
import 'package:lms_flutter/core/providers.dart';
import 'package:lms_flutter/features/onboarding/screens/onboarding_screen.dart';
import 'package:lms_flutter/features/splash/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SplashScreen renders title and logo', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    expect(find.text('Lumen LMS'), findsOneWidget);
    expect(find.text('Online Learning & Skills Platform'), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('OnboardingScreen displays slides and navigation controls', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    expect(find.text('Explore Interactive Courses'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Tap Next to navigate to slide 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Quizzes & Assignments'), findsOneWidget);
  });
}
