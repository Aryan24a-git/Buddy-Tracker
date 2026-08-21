import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:buddy_tracker/features/onboarding/screens/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen renders display name input and continue button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: OnboardingScreen(),
        ),
      ),
    );

    // Verify OnboardingScreen elements
    expect(find.text('Welcome to'), findsOneWidget);
    expect(find.text('Buddy Tracker'), findsOneWidget);
    expect(find.text('What should your buddies call you?'), findsOneWidget);
    expect(find.text('CONTINUE'), findsOneWidget);
  });
}
