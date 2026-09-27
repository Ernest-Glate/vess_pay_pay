/// Fee calculation service for card deposits.
/// Supports flat fee + percentage model with currency-specific tables and min/max caps.
class FeeCalculator {
  FeeCalculator._();

  /// Calculate fees for a card deposit.
  static FeeBreakdown calculate({
    required double amount,
    required String currency,
  }) {
    final config = _feeConfigs[currency.toUpperCase()] ?? _defaultConfig;

    double fee = config.flatFee + (amount * config.percentageFee / 100);

    // Apply caps
    if (fee < config.minFee) fee = config.minFee;
    if (config.maxFee > 0 && fee > config.maxFee) fee = config.maxFee;

    // Round to 2 decimal places
    fee = (fee * 100).roundToDouble() / 100;

    return FeeBreakdown(
      amount: amount,
      fee: fee,
      total: amount + fee,
      currency: currency.toUpperCase(),
      percentageRate: config.percentageFee,
      flatRate: config.flatFee,
    );
  }

  /// Validate deposit amount against limits.
  static AmountValidation validateAmount({
    required double amount,
    required String currency,
  }) {
    final limits = _depositLimits[currency.toUpperCase()] ?? _defaultLimits;

    if (amount <= 0) {
      return const AmountValidation(isValid: false, error: 'Amount must be greater than zero');
    }

    if (amount < limits.min) {
      return AmountValidation(
        isValid: false,
        error: 'Minimum deposit is ${limits.symbol}${limits.min.toStringAsFixed(2)}',
      );
    }

    if (amount > limits.max) {
      return AmountValidation(
        isValid: false,
        error: 'Maximum deposit is ${limits.symbol}${limits.max.toStringAsFixed(0)}',
      );
    }

    return const AmountValidation(isValid: true);
  }

  // ──────── Fee Configuration Tables ────────

  static const _defaultConfig = _FeeConfig(
    flatFee: 0.0,
    percentageFee: 1.5,
    minFee: 0.50,
    maxFee: 100.0,
  );

  static const Map<String, _FeeConfig> _feeConfigs = {
    'GHS': _FeeConfig(flatFee: 0.0, percentageFee: 2.0, minFee: 1.0, maxFee: 200.0),
    'USD': _FeeConfig(flatFee: 0.25, percentageFee: 2.9, minFee: 0.50, maxFee: 50.0),
    'GBP': _FeeConfig(flatFee: 0.20, percentageFee: 2.9, minFee: 0.50, maxFee: 40.0),
    'EUR': _FeeConfig(flatFee: 0.25, percentageFee: 2.9, minFee: 0.50, maxFee: 45.0),
    'NGN': _FeeConfig(flatFee: 0.0, percentageFee: 1.4, minFee: 100.0, maxFee: 2000.0),
  };

  // ──────── Deposit Limits ────────

  static const _defaultLimits = _DepositLimits(min: 1.0, max: 50000.0, symbol: '');

  static const Map<String, _DepositLimits> _depositLimits = {
    'GHS': _DepositLimits(min: 1.0, max: 50000.0, symbol: '₵'),
    'USD': _DepositLimits(min: 1.0, max: 10000.0, symbol: r'$'),
    'GBP': _DepositLimits(min: 1.0, max: 8000.0, symbol: '£'),
    'EUR': _DepositLimits(min: 1.0, max: 9000.0, symbol: '€'),
    'NGN': _DepositLimits(min: 100.0, max: 5000000.0, symbol: '₦'),
  };
}

// ──────── Data Classes ────────

class FeeBreakdown {
  final double amount;
  final double fee;
  final double total;
  final String currency;
  final double percentageRate;
  final double flatRate;

  const FeeBreakdown({
    required this.amount,
    required this.fee,
    required this.total,
    required this.currency,
    required this.percentageRate,
    required this.flatRate,
  });

  String get feeDisplay => '${_currencySymbol(currency)}${fee.toStringAsFixed(2)}';
  String get totalDisplay => '${_currencySymbol(currency)}${total.toStringAsFixed(2)}';
  String get amountDisplay => '${_currencySymbol(currency)}${amount.toStringAsFixed(2)}';

  static String _currencySymbol(String currency) {
    const symbols = {'GHS': '₵', 'USD': r'$', 'GBP': '£', 'EUR': '€', 'NGN': '₦'};
    return symbols[currency] ?? '';
  }
}

class AmountValidation {
  final bool isValid;
  final String? error;

  const AmountValidation({required this.isValid, this.error});
}

class _FeeConfig {
  final double flatFee;
  final double percentageFee;
  final double minFee;
  final double maxFee;

  const _FeeConfig({
    required this.flatFee,
    required this.percentageFee,
    required this.minFee,
    required this.maxFee,
  });
}

class _DepositLimits {
  final double min;
  final double max;
  final String symbol;

  const _DepositLimits({required this.min, required this.max, required this.symbol});
}
