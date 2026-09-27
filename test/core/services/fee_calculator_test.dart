import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/core/services/fee_calculator.dart';

void main() {
  group('FeeCalculator - GHS fees', () {
    test('calculates 2% fee for GHS', () {
      final result = FeeCalculator.calculate(amount: 100, currency: 'GHS');
      expect(result.fee, 2.00);
      expect(result.total, 102.00);
      expect(result.currency, 'GHS');
    });

    test('applies minimum fee when calculated fee is too low', () {
      final result = FeeCalculator.calculate(amount: 1, currency: 'GHS');
      // 2% of 1 = 0.02, but min is 1.0
      expect(result.fee, 1.0);
      expect(result.total, 2.0);
    });

    test('applies maximum fee cap', () {
      final result = FeeCalculator.calculate(amount: 50000, currency: 'GHS');
      // 2% of 50000 = 1000, but max is 200
      expect(result.fee, 200.0);
      expect(result.total, 50200.0);
    });

    test('calculates fee for medium amount', () {
      final result = FeeCalculator.calculate(amount: 500, currency: 'GHS');
      expect(result.fee, 10.00);
      expect(result.total, 510.00);
    });
  });

  group('FeeCalculator - USD fees', () {
    test('calculates 2.9% + \$0.25 for USD', () {
      final result = FeeCalculator.calculate(amount: 100, currency: 'USD');
      // 0.25 + (100 * 2.9 / 100) = 0.25 + 2.90 = 3.15
      expect(result.fee, 3.15);
      expect(result.total, 103.15);
    });

    test('applies minimum fee for small USD amount', () {
      final result = FeeCalculator.calculate(amount: 1, currency: 'USD');
      // 0.25 + (1 * 2.9 / 100) = 0.25 + 0.029 = 0.279, min is 0.50
      expect(result.fee, 0.50);
    });
  });

  group('FeeCalculator - Amount Validation', () {
    test('validates normal GHS amount', () {
      final result = FeeCalculator.validateAmount(amount: 100, currency: 'GHS');
      expect(result.isValid, isTrue);
    });

    test('rejects zero amount', () {
      final result = FeeCalculator.validateAmount(amount: 0, currency: 'GHS');
      expect(result.isValid, isFalse);
    });

    test('rejects negative amount', () {
      final result = FeeCalculator.validateAmount(amount: -50, currency: 'GHS');
      expect(result.isValid, isFalse);
    });

    test('rejects amount below minimum', () {
      final result = FeeCalculator.validateAmount(amount: 0.5, currency: 'GHS');
      expect(result.isValid, isFalse);
      expect(result.error, contains('Minimum'));
    });

    test('rejects amount above maximum', () {
      final result = FeeCalculator.validateAmount(amount: 60000, currency: 'GHS');
      expect(result.isValid, isFalse);
      expect(result.error, contains('Maximum'));
    });

    test('uses default limits for unknown currency', () {
      final result = FeeCalculator.validateAmount(amount: 100, currency: 'XYZ');
      expect(result.isValid, isTrue);
    });
  });

  group('FeeBreakdown - Display helpers', () {
    test('formats GHS display values', () {
      final breakdown = FeeCalculator.calculate(amount: 100, currency: 'GHS');
      expect(breakdown.amountDisplay, '₵100.00');
      expect(breakdown.feeDisplay, '₵2.00');
      expect(breakdown.totalDisplay, '₵102.00');
    });

    test('formats USD display values', () {
      final breakdown = FeeCalculator.calculate(amount: 50, currency: 'USD');
      expect(breakdown.amountDisplay, contains(r'$'));
    });
  });
}
