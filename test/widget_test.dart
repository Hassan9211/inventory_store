import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventory_store/widgets/app_router_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows splash first then opens signup for new user', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const AppRouterWidget(
        initialThemeMode: ThemeMode.light,
        initialLanguageCode: 'en',
      ),
    );

    expect(find.text('Inventory Store'), findsOneWidget);
    expect(find.text('Smart stock management'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Already have an account? Login'), findsOneWidget);
  });
}
