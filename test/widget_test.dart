import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_water_reminder/core/widgets/app_logo.dart';
import 'package:smart_water_reminder/features/splash/screens/splash_screen.dart';

void main() {
  // All durations are set to zero so:
  //   - AnimationControllers complete in 0 ticks (pumpAndSettle drives them).
  //   - Future.delayed(Duration.zero) resolves in one microtask cycle.
  //   - PageRouteBuilder transition completes immediately.
  //   - No real-world time is ever awaited.
  const zeroDuration = Duration.zero;

  testWidgets(
    'Splash shows logo and app name, then navigates to next screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SplashScreen(
            next: const Scaffold(body: Text('Home ready')),
            introDuration: zeroDuration,
            exitDuration: zeroDuration,
            holdDuration: zeroDuration,
            transitionDuration: zeroDuration,
            startDelay: zeroDuration,
          ),
        ),
      );

      // First frame: splash is visible.
      await tester.pump();

      expect(find.byType(AppLogo), findsOneWidget);
      expect(find.text('Smart Water Reminder'), findsOneWidget);
      expect(find.text('Stay hydrated, stay sharp'), findsOneWidget);

      // Drive all animations, microtasks and the page transition to completion.
      // pumpAndSettle repeatedly pumps until no more frames are pending.
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Next screen must be present and splash logo must be gone.
      expect(find.text('Home ready'), findsOneWidget);
      expect(find.byType(AppLogo), findsNothing);
    },
  );
}
