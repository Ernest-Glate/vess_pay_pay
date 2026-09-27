/// Card validation utilities meeting PCI-DSS standards.
/// Validates card numbers (Luhn), expiry dates, CVV codes,
/// and detects card brands from BIN ranges.
class CardValidator {
  CardValidator._();

  // ──────────────── Card Brand Detection ────────────────

  /// Detects the card brand from the card number prefix (BIN).
  static CardBrand detectBrand(String cardNumber) {
    final cleaned = _stripFormatting(cardNumber);
    if (cleaned.isEmpty) return CardBrand.unknown;

    // Visa: starts with 4
    if (cleaned.startsWith('4')) return CardBrand.visa;

    // Mastercard: 51-55 or 2221-2720
    if (cleaned.length >= 2) {
      final prefix2 = int.tryParse(cleaned.substring(0, 2)) ?? 0;
      if (prefix2 >= 51 && prefix2 <= 55) return CardBrand.mastercard;
    }
    if (cleaned.length >= 4) {
      final prefix4 = int.tryParse(cleaned.substring(0, 4)) ?? 0;
      if (prefix4 >= 2221 && prefix4 <= 2720) return CardBrand.mastercard;
    }

    // Amex: 34 or 37
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) {
      return CardBrand.amex;
    }

    // Discover: 6011, 622126-622925, 644-649, 65
    if (cleaned.startsWith('6011') || cleaned.startsWith('65')) {
      return CardBrand.discover;
    }
    if (cleaned.length >= 6) {
      final prefix6 = int.tryParse(cleaned.substring(0, 6)) ?? 0;
      if (prefix6 >= 622126 && prefix6 <= 622925) return CardBrand.discover;
    }
    if (cleaned.length >= 3) {
      final prefix3 = int.tryParse(cleaned.substring(0, 3)) ?? 0;
      if (prefix3 >= 644 && prefix3 <= 649) return CardBrand.discover;
    }

    // Verve (West African): 506099-506198, 650002-650027
    if (cleaned.length >= 6) {
      final prefix6 = int.tryParse(cleaned.substring(0, 6)) ?? 0;
      if ((prefix6 >= 506099 && prefix6 <= 506198) ||
          (prefix6 >= 650002 && prefix6 <= 650027)) {
        return CardBrand.verve;
      }
    }

    return CardBrand.unknown;
  }

  // ──────────────── Luhn Algorithm ────────────────

  /// Validates a card number using the Luhn (mod-10) algorithm.
  static bool isValidLuhn(String cardNumber) {
    final cleaned = _stripFormatting(cardNumber);
    if (cleaned.isEmpty || cleaned.length < 13 || cleaned.length > 19) {
      return false;
    }

    // All characters must be digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return false;

    int sum = 0;
    bool alternate = false;

    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  // ──────────────── Card Number Validation ────────────────

  /// Full card number validation: length + Luhn + brand check.
  static CardValidationResult validateCardNumber(String cardNumber) {
    final cleaned = _stripFormatting(cardNumber);

    if (cleaned.isEmpty) {
      return CardValidationResult(isValid: false, error: 'Card number is required');
    }

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return CardValidationResult(isValid: false, error: 'Card number must contain only digits');
    }

    final brand = detectBrand(cleaned);
    final expectedLength = brand == CardBrand.amex ? 15 : 16;

    if (cleaned.length < 13) {
      return CardValidationResult(isValid: false, error: 'Card number is too short');
    }

    if (cleaned.length > 19) {
      return CardValidationResult(isValid: false, error: 'Card number is too long');
    }

    if (brand != CardBrand.unknown && brand != CardBrand.verve && cleaned.length != expectedLength) {
      return CardValidationResult(
        isValid: false,
        error: 'Expected $expectedLength digits for ${brand.displayName}',
      );
    }

    if (!isValidLuhn(cleaned)) {
      return CardValidationResult(isValid: false, error: 'Invalid card number');
    }

    return CardValidationResult(isValid: true, brand: brand);
  }

  // ──────────────── Expiry Validation ────────────────

  /// Validates expiry in MM/YY format.
  static CardValidationResult validateExpiry(String expiry) {
    if (expiry.isEmpty) {
      return CardValidationResult(isValid: false, error: 'Expiry date is required');
    }

    // Accept MM/YY or MMYY
    final cleaned = expiry.replaceAll('/', '');
    if (cleaned.length != 4 || !RegExp(r'^\d{4}$').hasMatch(cleaned)) {
      return CardValidationResult(isValid: false, error: 'Use MM/YY format');
    }

    final month = int.parse(cleaned.substring(0, 2));
    final year = int.parse(cleaned.substring(2, 4)) + 2000;

    if (month < 1 || month > 12) {
      return CardValidationResult(isValid: false, error: 'Invalid month');
    }

    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1, 0); // Last day of expiry month

    if (expiryDate.isBefore(now)) {
      return CardValidationResult(isValid: false, error: 'Card has expired');
    }

    // Reject cards expiring more than 10 years in the future
    if (year > now.year + 10) {
      return CardValidationResult(isValid: false, error: 'Invalid expiry year');
    }

    return CardValidationResult(isValid: true);
  }

  // ──────────────── CVV Validation ────────────────

  /// Validates CVV based on card brand (3 digits for most, 4 for Amex).
  static CardValidationResult validateCvv(String cvv, {CardBrand? brand}) {
    if (cvv.isEmpty) {
      return CardValidationResult(isValid: false, error: 'CVV is required');
    }

    if (!RegExp(r'^\d+$').hasMatch(cvv)) {
      return CardValidationResult(isValid: false, error: 'CVV must contain only digits');
    }

    final expectedLength = brand == CardBrand.amex ? 4 : 3;

    if (cvv.length != expectedLength) {
      return CardValidationResult(
        isValid: false,
        error: brand == CardBrand.amex ? 'Amex requires 4-digit CID' : 'CVV must be 3 digits',
      );
    }

    return CardValidationResult(isValid: true);
  }

  // ──────────────── Formatting Helpers ────────────────

  /// Formats a card number with spaces every 4 digits (or 4-6-5 for Amex).
  static String formatCardNumber(String input) {
    final cleaned = _stripFormatting(input);
    final brand = detectBrand(cleaned);

    if (brand == CardBrand.amex) {
      // Amex: 4-6-5 grouping
      final buffer = StringBuffer();
      for (int i = 0; i < cleaned.length && i < 15; i++) {
        if (i == 4 || i == 10) buffer.write(' ');
        buffer.write(cleaned[i]);
      }
      return buffer.toString();
    }

    // Standard: 4-4-4-4 grouping
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  /// Formats expiry input as MM/YY with auto-slash.
  static String formatExpiry(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length <= 2) return cleaned;
    return '${cleaned.substring(0, 2)}/${cleaned.substring(2, cleaned.length.clamp(0, 4))}';
  }

  /// Strips spaces, dashes, and other formatting from card number.
  static String _stripFormatting(String input) {
    return input.replaceAll(RegExp(r'[\s\-]'), '');
  }
}

// ──────────────── Data Classes ────────────────

enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  verve,
  unknown;

  String get displayName {
    switch (this) {
      case CardBrand.visa: return 'Visa';
      case CardBrand.mastercard: return 'Mastercard';
      case CardBrand.amex: return 'American Express';
      case CardBrand.discover: return 'Discover';
      case CardBrand.verve: return 'Verve';
      case CardBrand.unknown: return 'Card';
    }
  }

  String get iconName {
    switch (this) {
      case CardBrand.visa: return 'visa';
      case CardBrand.mastercard: return 'mastercard';
      case CardBrand.amex: return 'amex';
      case CardBrand.discover: return 'discover';
      case CardBrand.verve: return 'verve';
      case CardBrand.unknown: return 'card';
    }
  }
}

class CardValidationResult {
  final bool isValid;
  final String? error;
  final CardBrand? brand;

  CardValidationResult({required this.isValid, this.error, this.brand});
}
