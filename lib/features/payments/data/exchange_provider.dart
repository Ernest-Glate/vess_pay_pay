import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExchangeRate {
  final String from;
  final String to;
  final double rate;

  ExchangeRate({required this.from, required this.to, required this.rate});
}

/// Represents a locked FX quote from the backend.
class LockedQuote {
  final String quoteId;
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double interbankRate;
  final double effectiveRate;
  final double spreadPercentage;
  final double spreadAmount;
  final DateTime expiresAt;
  final int lockWindowSeconds;

  LockedQuote({
    required this.quoteId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.interbankRate,
    required this.effectiveRate,
    required this.spreadPercentage,
    required this.spreadAmount,
    required this.expiresAt,
    this.lockWindowSeconds = 60,
  });

  /// Parse from POST /fx/calculate response
  factory LockedQuote.fromJson(Map<String, dynamic> json) {
    return LockedQuote(
      quoteId: json['quoteId'] as String,
      fromCurrency: json['fromCurrency'] as String,
      toCurrency: json['toCurrency'] as String,
      fromAmount: (json['fromAmount'] as num).toDouble(),
      toAmount: (json['toAmount'] as num).toDouble(),
      interbankRate: (json['interbankRate'] as num).toDouble(),
      effectiveRate: (json['effectiveRate'] as num).toDouble(),
      spreadPercentage: (json['spreadPercentage'] as num).toDouble(),
      spreadAmount: (json['spreadAmount'] as num).toDouble(),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      lockWindowSeconds: json['lockWindowSeconds'] as int? ?? 60,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  int get remainingSeconds {
    final diff = expiresAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// Result of POST /fx/execute
class ExchangeExecutionResult {
  final String referenceId;
  final String fromCurrency;
  final String toCurrency;
  final double amountDebited;
  final double amountCredited;
  final double effectiveRate;
  final DateTime executedAt;

  ExchangeExecutionResult({
    required this.referenceId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.amountDebited,
    required this.amountCredited,
    required this.effectiveRate,
    required this.executedAt,
  });

  factory ExchangeExecutionResult.fromJson(Map<String, dynamic> json) {
    return ExchangeExecutionResult(
      referenceId: json['referenceId'] as String,
      fromCurrency: json['fromCurrency'] as String,
      toCurrency: json['toCurrency'] as String,
      amountDebited: (json['amountDebited'] as num).toDouble(),
      amountCredited: (json['amountCredited'] as num).toDouble(),
      effectiveRate: (json['effectiveRate'] as num).toDouble(),
      executedAt: DateTime.parse(json['executedAt'] as String),
    );
  }
}

class ExchangeService extends StateNotifier<List<ExchangeRate>> {
  DateTime _lastFetchedAt = DateTime.now();
  bool _isRefreshing = false;
  LockedQuote? _currentQuote;

  DateTime get lastFetchedAt => _lastFetchedAt;
  bool get isRefreshing => _isRefreshing;
  LockedQuote? get currentQuote => _currentQuote;

  ExchangeService() : super([
    ExchangeRate(from: 'GHS', to: 'USD', rate: 0.081),
    ExchangeRate(from: 'USD', to: 'GHS', rate: 12.45),
    ExchangeRate(from: 'GHS', to: 'GBP', rate: 0.063),
    ExchangeRate(from: 'GBP', to: 'GHS', rate: 15.80),
    ExchangeRate(from: 'USD', to: 'GBP', rate: 0.79),
    ExchangeRate(from: 'GBP', to: 'USD', rate: 1.27),
    ExchangeRate(from: 'GHS', to: 'EUR', rate: 0.073),
    ExchangeRate(from: 'EUR', to: 'GHS', rate: 13.60),
    ExchangeRate(from: 'USD', to: 'EUR', rate: 0.92),
    ExchangeRate(from: 'EUR', to: 'USD', rate: 1.088),
  ]);

  double getRate(String from, String to) {
    if (from == to) return 1.0;
    try {
      return state.firstWhere((element) => element.from == from && element.to == to).rate;
    } catch (e) {
      return 1.0;
    }
  }

  /// Fetch live rates from GET /fx/rates.
  /// In mock mode, simulates minor market fluctuation.
  Future<void> refreshRates() async {
    _isRefreshing = true;
    _currentQuote = null; // Clear any locked quote on refresh
    state = [...state];

    try {
      // TODO: Replace with real API call: GET /api/v1/fx/rates
      await Future.delayed(const Duration(milliseconds: 800));

      final jitter = 1.0 + (DateTime.now().millisecond % 10 - 5) * 0.001;

      state = [
        ExchangeRate(from: 'GHS', to: 'USD', rate: 0.081 * jitter),
        ExchangeRate(from: 'USD', to: 'GHS', rate: 12.45 * jitter),
        ExchangeRate(from: 'GHS', to: 'GBP', rate: 0.063 * jitter),
        ExchangeRate(from: 'GBP', to: 'GHS', rate: 15.80 * jitter),
        ExchangeRate(from: 'USD', to: 'GBP', rate: 0.79 * jitter),
        ExchangeRate(from: 'GBP', to: 'USD', rate: 1.27 * jitter),
        ExchangeRate(from: 'GHS', to: 'EUR', rate: 0.073 * jitter),
        ExchangeRate(from: 'EUR', to: 'GHS', rate: 13.60 * jitter),
        ExchangeRate(from: 'USD', to: 'EUR', rate: 0.92 * jitter),
        ExchangeRate(from: 'EUR', to: 'USD', rate: 1.088 * jitter),
      ];

      _lastFetchedAt = DateTime.now();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Lock a quote via POST /fx/calculate.
  /// Returns a LockedQuote with a 60-second TTL.
  Future<LockedQuote> lockQuote({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
  }) async {
    // TODO: Replace with real API call: POST /api/v1/fx/calculate
    await Future.delayed(const Duration(milliseconds: 500));

    final rate = getRate(fromCurrency, toCurrency);
    final toAmount = amount * rate;
    const spreadPct = 2.5;
    final interbankRate = rate / (1 - spreadPct / 100);

    final quote = LockedQuote(
      quoteId: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      fromAmount: amount,
      toAmount: double.parse(toAmount.toStringAsFixed(2)),
      interbankRate: double.parse(interbankRate.toStringAsFixed(6)),
      effectiveRate: double.parse(rate.toStringAsFixed(6)),
      spreadPercentage: spreadPct,
      spreadAmount: double.parse((amount * interbankRate - toAmount).toStringAsFixed(2)),
      expiresAt: DateTime.now().add(const Duration(seconds: 60)),
    );

    _currentQuote = quote;
    state = [...state]; // Trigger rebuild

    return quote;
  }

  /// Execute a locked quote via POST /fx/execute.
  Future<ExchangeExecutionResult> executeQuote(String quoteId) async {
    // TODO: Replace with real API call: POST /api/v1/fx/execute
    await Future.delayed(const Duration(milliseconds: 800));

    if (_currentQuote == null || _currentQuote!.quoteId != quoteId) {
      throw Exception('Quote not found');
    }

    if (_currentQuote!.isExpired) {
      _currentQuote = null;
      throw Exception('QUOTE_EXPIRED');
    }

    final result = ExchangeExecutionResult(
      referenceId: 'fx-${DateTime.now().millisecondsSinceEpoch}',
      fromCurrency: _currentQuote!.fromCurrency,
      toCurrency: _currentQuote!.toCurrency,
      amountDebited: _currentQuote!.fromAmount,
      amountCredited: _currentQuote!.toAmount,
      effectiveRate: _currentQuote!.effectiveRate,
      executedAt: DateTime.now(),
    );

    _currentQuote = null;
    return result;
  }

  void clearQuote() {
    _currentQuote = null;
    state = [...state];
  }
}

final exchangeProvider = StateNotifierProvider<ExchangeService, List<ExchangeRate>>((ref) {
  return ExchangeService();
});
