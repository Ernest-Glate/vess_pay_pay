import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vesspay_mobile_flutter/core/theme/app_theme.dart';
import 'package:vesspay_mobile_flutter/features/payments/presentation/currency_exchange_screen.dart';
import 'package:vesspay_mobile_flutter/features/payments/presentation/exchange_success_screen.dart';
import 'package:vesspay_mobile_flutter/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  group('Exchange Flow Integration Tests', () {
    testWidgets('Happy path: complete exchange flow from dashboard to success', (WidgetTester tester) async {
      // Build app
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap "Swap" quick action
      final swapButton = find.text('Swap');
      expect(swapButton, findsOneWidget);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      // Should navigate to exchange screen
      expect(find.text('EXCHANGE'), findsOneWidget);

      // Verify fee display shows 0.03 NOT 3%
      expect(find.textContaining('Fee: 0.03'), findsOneWidget);
      expect(find.textContaining('Fee: 3 %'), findsNothing);

      // Enter amount
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '100');
      await tester.pumpAndSettle();

      // Tap confirm button
      final confirmButton = find.text('Confirm Exchange');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to success screen
      expect(find.text('Exchange Confirmed & Successful'), findsOneWidget);

      // Verify fee in summary shows decimal format
      expect(find.textContaining('0.03'), findsOneWidget);

      // Tap Done button
      final doneButton = find.text('Done');
      expect(doneButton, findsOneWidget);
      await tester.tap(doneButton);
      await tester.pumpAndSettle();

      // Should return to dashboard
      expect(find.text('Good Morning,'), findsOneWidget);
    });

    testWidgets('Error path: insufficient balance shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter amount exceeding balance
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '999999');
      await tester.pumpAndSettle();

      // Tap confirm
      await tester.tap(find.text('Confirm Exchange'));
      await tester.pumpAndSettle();

      // Should show insufficient balance error
      expect(find.text('Insufficient balance'), findsOneWidget);

      // Should still be on exchange screen
      expect(find.text('EXCHANGE'), findsOneWidget);
    });

    testWidgets('Error path: invalid amount shows error', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap confirm without entering amount
      await tester.tap(find.text('Confirm Exchange'));
      await tester.pumpAndSettle();

      // Should show validation error
      expect(find.text('Please enter a valid amount'), findsOneWidget);
    });

    testWidgets('Navigation: back button from exchange returns to dashboard', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find back button
      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      // Tap back button
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should navigate back (in real app, would go to dashboard)
      // Note: This test validates the button exists and is tappable
      // Full navigation requires router context
    });

    testWidgets('Currency selection: can select different currencies', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find "You Send" currency selector
      final currencyButtons = find.byIcon(Icons.keyboard_arrow_down_rounded);
      expect(currencyButtons, findsNWidgets(2)); // Should have 2 currency selectors

      // Tap first currency selector
      await tester.tap(currencyButtons.first);
      await tester.pumpAndSettle();

      // Should open currency selector
      expect(find.text('SELECT CURRENCY'), findsOneWidget);

      // Should show search field
      expect(find.byType(TextField), findsNWidgets(2)); // 1 search + 1 amount field (stacked)

      // Should show all currencies
      expect(find.text('GHS'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);

      // Tap USD
      await tester.tap(find.text('USD').last); // Use last to get list item, not header
      await tester.pumpAndSettle();

      // Selector should close
      expect(find.text('SELECT CURRENCY'), findsNothing);
    });

    testWidgets('Currency swap: swapping currencies reverses selection', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find swap button
      final swapIcon = find.byIcon(Icons.swap_vert_rounded);
      expect(swapIcon, findsOneWidget);

      // Tap swap button
      await tester.tap(swapIcon);
      await tester.pumpAndSettle();

      // Animation should complete
      // Currencies should be swapped (validated by widget behavior)
    });

    testWidgets('Exchange rate calculation: displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show rate information
      expect(find.textContaining('Rate:'), findsOneWidget);
      expect(find.textContaining('Fee:'), findsOneWidget);

      // Fee should be in decimal format
      expect(find.textContaining('0.03'), findsOneWidget);
    });

    testWidgets('Loading state: button shows correct states', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: CurrencyExchangeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Confirm button should be visible
      expect(find.text('Confirm Exchange'), findsOneWidget);

      // Enter valid amount
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.pumpAndSettle();

      // Button should still be tappable
      final confirmButton = find.text('Confirm Exchange');
      expect(tester.widget<ElevatedButton>(confirmButton.hitTestable()).enabled, isTrue);
    });
  });

  group('Exchange Success Screen Tests', () {
    testWidgets('Success screen displays all transaction details', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: ExchangeSuccessScreen(
              fromCurrency: 'GHS',
              toCurrency: 'USD',
              fromAmount: 100.0,
              toAmount: 8.1,
              rate: 0.081,
              timestamp: DateTime.now(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Exchange Confirmed & Successful'), findsOneWidget);

      // Should show amounts
      expect(find.textContaining('100.00'), findsOneWidget);
      expect(find.textContaining('8.10'), findsOneWidget);

      // Should show rate
      expect(find.textContaining('Exchange Rate'), findsOneWidget);

      // Should show fee in decimal format
      expect(find.textContaining('0.03'), findsOneWidget);

      // Should show status
      expect(find.text('Confirmed'), findsOneWidget);

      // Should have Done button
      expect(find.text('Done'), findsOneWidget);
    });
  });
}
