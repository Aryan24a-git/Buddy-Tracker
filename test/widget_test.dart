import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:buddy_tracker/main.dart';

void main() {
  testWidgets('BuddyTrackerApp renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BuddyTrackerApp(),
      ),
    );
    // Splash screen should be visible
    expect(find.text('BUDDY TRACKER'), findsWidgets);
  });
}
