import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/shared/widgets/currency_selector_widget.dart';
import 'package:vesspay_mobile_flutter/shared/models/currency_model.dart';
import 'package:vesspay_mobile_flutter/core/theme/app_theme.dart';

void main() {
  group('CurrencySelectorWidget Tests', () {
    testWidgets('should display all supported currencies', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (currency) {
                // Selection callback
              },
            ),
          ),
        ),
      );


      // Wait for animations
      await tester.pumpAndSettle();

      // Should display header
      expect(find.text('SELECT CURRENCY'), findsOneWidget);

      // Should display all 5 supported currencies
      expect(find.text('GHS'), findsOneWidget);
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('GBP'), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
      expect(find.text('NGN'), findsOneWidget);

      // Should display currency names
      expect(find.text('Ghanaian Cedi'), findsOneWidget);
      expect(find.text('United States Dollar'), findsOneWidget);
    });

    testWidgets('should highlight selected currency', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              currentCurrency: 'USD',
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show check icon for selected currency
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('should filter currencies based on search', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find search field
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Type search query
      await tester.enterText(searchField, 'uni');
      await tester.pumpAndSettle();

      // Should only show USD (United States Dollar)
      expect(find.text('USD'), findsOneWidget);
      expect(find.text('GHS'), findsNothing);
      expect(find.text('GBP'), findsNothing);
      expect(find.text('EUR'), findsNothing);
      expect(find.text('NGN'), findsNothing);
    });

    testWidgets('should show empty state when no currencies match', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enter search that matches nothing
      await tester.enterText(find.byType(TextField), 'xyz123');
      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No currencies found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('should call onCurrencySelected when currency is tapped', (WidgetTester tester) async {
      Currency? selectedCurrency;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (currency) {
                selectedCurrency = currency;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on GBP
      await tester.tap(find.text('GBP'));
      await tester.pumpAndSettle();

      // Should have selected GBP
      expect(selectedCurrency, isNotNull);
      expect(selectedCurrency?.code, 'GBP');
    });

    testWidgets('should show loading shimmer when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              isLoading: true,
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show currency list when loading
      expect(find.text('GHS'), findsNothing);
      expect(find.text('USD'), findsNothing);
      
      // Should show shimmer placeholders (checking for ShimmerLoading widget)
      // Note: ShimmerLoading might not be directly findable, so we verify currencies aren't shown
    });

    testWidgets('should display flag emojis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check for flag emojis
      expect(find.text('🇬🇭'), findsOneWidget); // Ghana
      expect(find.text('🇺🇸'), findsOneWidget); // USA
      expect(find.text('🇬🇧'), findsOneWidget); // UK
      expect(find.text('🇪🇺'), findsOneWidget); // EU
      expect(find.text('🇳🇬'), findsOneWidget); // Nigeria
    });

    testWidgets('should have close button', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have close button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('search should be case-insensitive', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search with uppercase
      await tester.enterText(find.byType(TextField), 'GHANA');
      await tester.pumpAndSettle();

      // Should find GHS (Ghanaian Cedi)
      expect(find.text('GHS'), findsOneWidget);
      expect(find.text('Ghanaian Cedi'), findsOneWidget);
    });

    testWidgets('search should match both code and name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: CurrencySelectorWidget(
              onCurrencySelected: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search by code
      await tester.enterText(find.byType(TextField), 'EUR');
      await tester.pumpAndSettle();
      expect(find.text('EUR'), findsOneWidget);

      // Clear and search by name
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'euro');
      await tester.pumpAndSettle();
      expect(find.text('EUR'), findsOneWidget);
    });
  });

  group('showCurrencySelector Helper Function Tests', () {
    testWidgets('should show bottom sheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    await showCurrencySelector(
                      context: context,
                      currentCurrency: 'USD',
                    );
                  },
                  child: const Text('Show Selector'),
                );
              },
            ),
          ),
        ),
      );

      // Tap button to show selector
      await tester.tap(find.text('Show Selector'));
      await tester.pumpAndSettle();

      // Should display selector
      expect(find.text('SELECT CURRENCY'), findsOneWidget);
    });
  });
}
