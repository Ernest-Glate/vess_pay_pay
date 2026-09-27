import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/core/utils/currency_formatters.dart';

void main() {
  group('CurrencyFormatters Unit Tests', () {
    group('formatFeeAsDecimal', () {
      test('should format 3% as 0.03', () {
        expect(CurrencyFormatters.formatFeeAsDecimal(3.0), '0.03');
      });

      test('should format 0% as 0.00', () {
        expect(CurrencyFormatters.formatFeeAsDecimal(0.0), '0.00');
      });

      test('should format 10% as 0.10', () {
        expect(CurrencyFormatters.formatFeeAsDecimal(10.0), '0.10');
      });

      test('should format 1.5% as 0.02', () {
        expect(CurrencyFormatters.formatFeeAsDecimal(1.5), '0.02');
      });

      test('should format 100% as 1.00', () {
        expect(CurrencyFormatters.formatFeeAsDecimal(100.0), '1.00');
      });
    });

    group('formatFeeAsPercentage', () {
      test('should format 3.0 as "3.0%"', () {
        expect(CurrencyFormatters.formatFeeAsPercentage(3.0), '3.0%');
      });

      test('should format 0.0 as "0.0%"', () {
        expect(CurrencyFormatters.formatFeeAsPercentage(0.0), '0.0%');
      });

      test('should format 10.5 as "10.5%"', () {
        expect(CurrencyFormatters.formatFeeAsPercentage(10.5), '10.5%');
      });
    });

    group('formatRate', () {
      test('should format rate with 4 decimals by default', () {
        expect(CurrencyFormatters.formatRate(14.256789), '14.2568');
      });

      test('should format rate with custom decimals', () {
        expect(CurrencyFormatters.formatRate(14.256789, decimals: 2), '14.26');
      });

      test('should format rate with 6 decimals', () {
        expect(CurrencyFormatters.formatRate(0.081234567, decimals: 6), '0.081235');
      });

      test('should handle whole numbers', () {
        expect(CurrencyFormatters.formatRate(12.0), '12.0000');
      });
    });

    group('formatAmount', () {
      test('should format amount with symbol', () {
        expect(CurrencyFormatters.formatAmount(100.50, r'$'), r'$100.50');
      });

      test('should format amount with GHS symbol', () {
        expect(CurrencyFormatters.formatAmount(1234.56, '₵'), '₵1234.56');
      });

      test('should handle zero', () {
        expect(CurrencyFormatters.formatAmount(0.0, r'$'), r'$0.00');
      });

      test('should format with custom decimals', () {
        expect(CurrencyFormatters.formatAmount(100.123456, r'$', decimals: 4), r'$100.1235');
      });
    });

    group('formatAmountWithCode', () {
      test('should format amount with currency code', () {
        expect(CurrencyFormatters.formatAmountWithCode(100.50, 'USD'), '100.50 USD');
      });

      test('should format large amounts', () {
        expect(CurrencyFormatters.formatAmountWithCode(12450.00, 'GHS'), '12450.00 GHS');
      });

      test('should format with custom decimals', () {
        expect(CurrencyFormatters.formatAmountWithCode(100.1, 'EUR', decimals: 4), '100.1000 EUR');
      });
    });

    group('calculateAfterFee', () {
      test('should deduct 3% fee from 1000', () {
        expect(CurrencyFormatters.calculateAfterFee(1000.0, 3.0), 970.0);
      });

      test('should deduct 0% fee (no change)', () {
        expect(CurrencyFormatters.calculateAfterFee(1000.0, 0.0), 1000.0);
      });

      test('should deduct 10% fee from 500', () {
        expect(CurrencyFormatters.calculateAfterFee(500.0, 10.0), 450.0);
      });

      test('should handle decimal amounts', () {
        expect(CurrencyFormatters.calculateAfterFee(123.45, 5.0), closeTo(117.2775, 0.0001));
      });
    });

    group('calculateFeeAmount', () {
      test('should calculate 3% of 1000 as 30', () {
        expect(CurrencyFormatters.calculateFeeAmount(1000.0, 3.0), 30.0);
      });

      test('should calculate 0% of any amount as 0', () {
        expect(CurrencyFormatters.calculateFeeAmount(999.99, 0.0), 0.0);
      });

      test('should calculate 5% of 200 as 10', () {
        expect(CurrencyFormatters.calculateFeeAmount(200.0, 5.0), 10.0);
      });

      test('should handle decimal percentages', () {
        expect(CurrencyFormatters.calculateFeeAmount(100.0, 2.5), 2.5);
      });
    });

    group('parseAmount', () {
      test('should parse simple amount', () {
        expect(CurrencyFormatters.parseAmount('100.50'), 100.50);
      });

      test('should parse amount with commas', () {
        expect(CurrencyFormatters.parseAmount('1,234.56'), 1234.56);
      });

      test('should parse amount with spaces', () {
        expect(CurrencyFormatters.parseAmount('1 234.56'), 1234.56);
      });

      test('should handle invalid input', () {
        expect(CurrencyFormatters.parseAmount('abc'), null);
      });

      test('should handle empty string', () {
        expect(CurrencyFormatters.parseAmount(''), null);
      });

      test('should parse integer', () {
        expect(CurrencyFormatters.parseAmount('1000'), 1000.0);
      });

      test('should parse amount with multiple commas', () {
        expect(CurrencyFormatters.parseAmount('1,234,567.89'), 1234567.89);
      });
    });

    group('Edge Cases', () {
      test('should handle very large amounts', () {
        expect(CurrencyFormatters.formatAmount(1000000000.00, r'$'), r'$1000000000.00');
      });

      test('should handle very small amounts', () {
        expect(CurrencyFormatters.formatAmount(0.01, r'$'), r'$0.01');
      });

      test('should handle negative fee percentage (edge case)', () {
        // While negative fees don't make business sense, formatter should handle it
        expect(CurrencyFormatters.formatFeeAsDecimal(-5.0), '-0.05');
      });

      test('should handle very high fee percentage', () {
        expect(CurrencyFormatters.calculateFeeAmount(100.0, 200.0), 200.0);
      });
    });
  });
}
