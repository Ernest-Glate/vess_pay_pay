import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/core/utils/card_validator.dart';

void main() {
  group('CardValidator - Luhn Algorithm', () {
    test('validates known valid card numbers', () {
      // Standard test card numbers
      expect(CardValidator.isValidLuhn('4111111111111111'), isTrue); // Visa
      expect(CardValidator.isValidLuhn('5500000000000004'), isTrue); // MC
      expect(CardValidator.isValidLuhn('340000000000009'), isTrue);  // Amex
      expect(CardValidator.isValidLuhn('6011000000000004'), isTrue); // Discover
    });

    test('rejects invalid card numbers', () {
      expect(CardValidator.isValidLuhn('4111111111111112'), isFalse);
      expect(CardValidator.isValidLuhn('1234567890123456'), isFalse);
      expect(CardValidator.isValidLuhn('0000000000000000'), isTrue); // Luhn-valid but would fail brand check
    });

    test('rejects too-short or too-long numbers', () {
      expect(CardValidator.isValidLuhn('411111'), isFalse);
      expect(CardValidator.isValidLuhn('41111111111111111111'), isFalse);
    });

    test('rejects non-numeric input', () {
      expect(CardValidator.isValidLuhn('abcd1234efgh5678'), isFalse);
      expect(CardValidator.isValidLuhn(''), isFalse);
    });

    test('handles formatted card numbers', () {
      expect(CardValidator.isValidLuhn('4111 1111 1111 1111'), isTrue);
      expect(CardValidator.isValidLuhn('4111-1111-1111-1111'), isTrue);
    });
  });

  group('CardValidator - Brand Detection', () {
    test('detects Visa', () {
      expect(CardValidator.detectBrand('4111111111111111'), CardBrand.visa);
      expect(CardValidator.detectBrand('4242424242424242'), CardBrand.visa);
    });

    test('detects Mastercard', () {
      expect(CardValidator.detectBrand('5500000000000004'), CardBrand.mastercard);
      expect(CardValidator.detectBrand('5105105105105100'), CardBrand.mastercard);
      expect(CardValidator.detectBrand('2221000000000000'), CardBrand.mastercard); // 2-series MC
    });

    test('detects Amex', () {
      expect(CardValidator.detectBrand('340000000000009'), CardBrand.amex);
      expect(CardValidator.detectBrand('370000000000002'), CardBrand.amex);
    });

    test('detects Discover', () {
      expect(CardValidator.detectBrand('6011000000000004'), CardBrand.discover);
      expect(CardValidator.detectBrand('6500000000000002'), CardBrand.discover);
    });

    test('returns unknown for unrecognized', () {
      expect(CardValidator.detectBrand('9999999999999999'), CardBrand.unknown);
    });
  });

  group('CardValidator - Card Number Validation', () {
    test('validates correct Visa number', () {
      final result = CardValidator.validateCardNumber('4111111111111111');
      expect(result.isValid, isTrue);
      expect(result.brand, CardBrand.visa);
    });

    test('rejects empty input', () {
      final result = CardValidator.validateCardNumber('');
      expect(result.isValid, isFalse);
      expect(result.error, 'Card number is required');
    });

    test('rejects non-numeric', () {
      final result = CardValidator.validateCardNumber('abcdefgh12345678');
      expect(result.isValid, isFalse);
    });

    test('rejects wrong length for known brand', () {
      final result = CardValidator.validateCardNumber('411111111111'); // too short for Visa
      expect(result.isValid, isFalse);
    });
  });

  group('CardValidator - Expiry Validation', () {
    test('accepts valid future date', () {
      final result = CardValidator.validateExpiry('12/30');
      expect(result.isValid, isTrue);
    });

    test('rejects past date', () {
      final result = CardValidator.validateExpiry('01/20');
      expect(result.isValid, isFalse);
      expect(result.error, 'Card has expired');
    });

    test('rejects invalid month', () {
      expect(CardValidator.validateExpiry('13/30').isValid, isFalse);
      expect(CardValidator.validateExpiry('00/30').isValid, isFalse);
    });

    test('rejects empty expiry', () {
      final result = CardValidator.validateExpiry('');
      expect(result.isValid, isFalse);
    });

    test('rejects far future (>10 years)', () {
      final result = CardValidator.validateExpiry('12/99');
      expect(result.isValid, isFalse);
    });
  });

  group('CardValidator - CVV Validation', () {
    test('accepts 3-digit CVV for Visa', () {
      final result = CardValidator.validateCvv('123', brand: CardBrand.visa);
      expect(result.isValid, isTrue);
    });

    test('accepts 4-digit CID for Amex', () {
      final result = CardValidator.validateCvv('1234', brand: CardBrand.amex);
      expect(result.isValid, isTrue);
    });

    test('rejects 3-digit for Amex', () {
      final result = CardValidator.validateCvv('123', brand: CardBrand.amex);
      expect(result.isValid, isFalse);
    });

    test('rejects 4-digit for Visa', () {
      final result = CardValidator.validateCvv('1234', brand: CardBrand.visa);
      expect(result.isValid, isFalse);
    });

    test('rejects empty CVV', () {
      final result = CardValidator.validateCvv('');
      expect(result.isValid, isFalse);
    });
  });

  group('CardValidator - Formatting', () {
    test('formats Visa number with spaces', () {
      expect(CardValidator.formatCardNumber('4111111111111111'), '4111 1111 1111 1111');
    });

    test('formats Amex with 4-6-5 grouping', () {
      expect(CardValidator.formatCardNumber('340000000000009'), '3400 000000 00009');
    });

    test('formats expiry with slash', () {
      expect(CardValidator.formatExpiry('1225'), '12/25');
      expect(CardValidator.formatExpiry('12'), '12');
    });
  });
}
