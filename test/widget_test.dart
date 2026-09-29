import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_water_reminder/core/widgets/app_logo.dart';
import 'package:smart_water_reminder/features/splash/screens/splash_screen.dart';

void main() {
  testWidgets('Splash shows logo and app name then fades to the next screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          next: Scaffold(body: Text('Home ready')),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AppLogo), findsOneWidget);
    expect(find.text('Smart Water Reminder'), findsOneWidget);
    expect(find.text('Stay hydrated, stay sharp'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Home ready'), findsOneWidget);
    expect(find.byType(AppLogo), findsNothing);
  });
}
