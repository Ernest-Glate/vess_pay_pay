import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/shared/widgets/app_button.dart';
import 'package:vesspay_mobile_flutter/shared/widgets/glass_container.dart';

void main() {
  group('AppButton Widget Tests', () {
    testWidgets('AppButton displays label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              onPress: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
    });

    testWidgets('AppButton shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              label: 'Test Button',
              isLoading: true,
              onPress: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('GlassContainer Widget Tests', () {
    testWidgets('GlassContainer renders child', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GlassContainer(
              child: Text('Inside Glass'),
            ),
          ),
        ),
      );

      expect(find.text('Inside Glass'), findsOneWidget);
    });
  });
}
