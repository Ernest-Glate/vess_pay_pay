/// Utility class for formatting currency values, rates, and fees
class CurrencyFormatters {
  CurrencyFormatters._(); // Private constructor to prevent instantiation

  /// Format fee percentage as decimal
  /// Example: 3 (percent) → "0.03"
  static String formatFeeAsDecimal(double feePercentage) {
    return (feePercentage / 100).toStringAsFixed(2);
  }

  /// Format fee percentage with % sign
  /// Example: 3 → "3%"
  static String formatFeeAsPercentage(double feePercentage) {
    return '${feePercentage.toStringAsFixed(1)}%';
  }

  /// Format exchange rate to specified decimals
  /// Example: 14.2567 → "14.2567" (4 decimals)
  static String formatRate(double rate, {int decimals = 4}) {
    return rate.toStringAsFixed(decimals);
  }

  /// Format amount with currency symbol
  /// Example: 100.50, '$' → "$100.50"
  static String formatAmount(double amount, String symbol, {int decimals = 2}) {
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }

  /// Format amount with currency code
  /// Example: 100.50, 'USD' → "100.50 USD"
  static String formatAmountWithCode(double amount, String code, {int decimals = 2}) {
    return '${amount.toStringAsFixed(decimals)} $code';
  }

  /// Calculate receive amount after fee deduction
  /// Example: 1000, 3 → 970.0 (3% fee deducted)
  static double calculateAfterFee(double amount, double feePercentage) {
    return amount * (1 - feePercentage / 100);
  }

  /// Calculate fee amount
  /// Example: 1000, 3 → 30.0 (3% of 1000)
  static double calculateFeeAmount(double amount, double feePercentage) {
    return amount * (feePercentage / 100);
  }

  /// Parse amount string to double, handling common formats
  /// Example: "1,234.56" → 1234.56
  static double? parseAmount(String input) {
    try {
      // Remove common formatting characters
      final cleaned = input.replaceAll(RegExp(r'[,\s]'), '');
      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }
}
