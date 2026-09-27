import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/features/payments/presentation/exchange_success_screen.dart';
import 'package:vesspay_mobile_flutter/shared/widgets/app_button.dart';

void main() {
  testWidgets('ExchangeSuccessScreen renders correctly', (WidgetTester tester) async {
    final timestamp = DateTime(2026, 2, 5, 17, 30);
    
    await tester.pumpWidget(
      MaterialApp(
        home: ExchangeSuccessScreen(
          fromCurrency: 'GHS',
          toCurrency: 'USD',
          fromAmount: 1000.0,
          toAmount: 81.0,
          rate: 0.081,
          timestamp: timestamp,
        ),
      ),
    );

    // Wait for animations
    await tester.pump(const Duration(seconds: 1));

    // Assert headline
    expect(find.text('Exchange Confirmed & Successful'), findsOneWidget);

    // Assert summary values
    expect(find.text('₵1000.00 GHS'), findsOneWidget); // From amount
    expect(find.text('\$81.00 USD'), findsOneWidget);  // To amount
    expect(find.text('1 GHS = 0.0810 USD'), findsOneWidget); // Rate

    // Assert CTA button
    expect(find.byType(AppButton), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
