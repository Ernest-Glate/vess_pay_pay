/// Wallet model — mirrors GET /api/v1/wallet/balance response
class WalletModel {
  final double balance;
  final String currency;
  final bool isFrozen;
  final String? freezeReason;
  final double totalLoaded;
  final double totalSpent;
  final double totalRefunded;
  final double dailySpendToday;
  final double dailySpendLimit;
  final double dailyLimitRemaining;

  const WalletModel({
    required this.balance,
    this.currency = 'GHS',
    this.isFrozen = false,
    this.freezeReason,
    this.totalLoaded = 0,
    this.totalSpent = 0,
    this.totalRefunded = 0,
    this.dailySpendToday = 0,
    this.dailySpendLimit = 300,
    this.dailyLimitRemaining = 300,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GHS',
      isFrozen: json['isFrozen'] as bool? ?? false,
      freezeReason: json['freezeReason'] as String?,
      totalLoaded: (json['totalLoaded'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalRefunded: (json['totalRefunded'] as num?)?.toDouble() ?? 0.0,
      dailySpendToday: (json['dailySpendToday'] as num?)?.toDouble() ?? 0.0,
      dailySpendLimit: (json['dailySpendLimit'] as num?)?.toDouble() ?? 300.0,
      dailyLimitRemaining:
          (json['dailyLimitRemaining'] as num?)?.toDouble() ?? 300.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'balance': balance,
        'currency': currency,
        'isFrozen': isFrozen,
        'totalLoaded': totalLoaded,
        'totalSpent': totalSpent,
        'totalRefunded': totalRefunded,
        'dailySpendToday': dailySpendToday,
        'dailySpendLimit': dailySpendLimit,
        'dailyLimitRemaining': dailyLimitRemaining,
      };

  WalletModel copyWith({double? balance, bool? isFrozen}) {
    return WalletModel(
      balance: balance ?? this.balance,
      currency: currency,
      isFrozen: isFrozen ?? this.isFrozen,
      freezeReason: freezeReason,
      totalLoaded: totalLoaded,
      totalSpent: totalSpent,
      totalRefunded: totalRefunded,
      dailySpendToday: dailySpendToday,
      dailySpendLimit: dailySpendLimit,
      dailyLimitRemaining: dailyLimitRemaining,
    );
  }
}

/// FX Rate model — mirrors GET /api/v1/wallet/fx-rates response
class FxRateModel {
  final String? rateId;
  final String fromCurrency;
  final String toCurrency;
  final double vesRate;
  final double marketRate;
  final double marginPercent;
  final String? source;
  final DateTime? validFrom;

  const FxRateModel({
    this.rateId,
    required this.fromCurrency,
    required this.toCurrency,
    required this.vesRate,
    required this.marketRate,
    required this.marginPercent,
    this.source,
    this.validFrom,
  });

  factory FxRateModel.fromJson(Map<String, dynamic> json) {
    return FxRateModel(
      rateId: json['rateId'] as String?,
      fromCurrency: json['fromCurrency'] as String? ?? '',
      toCurrency: json['toCurrency'] as String? ?? 'GHS',
      vesRate: (json['vesRate'] as num?)?.toDouble() ?? 0.0,
      marketRate: (json['marketRate'] as num?)?.toDouble() ?? 0.0,
      marginPercent: (json['marginPercent'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String?,
      validFrom: json['validFrom'] != null
          ? DateTime.tryParse(json['validFrom'] as String)
          : null,
    );
  }
}

/// Load fee breakdown — mirrors POST /wallet/load/initiate response
class LoadFeeBreakdown {
  final String transactionId;
  final double amountForeign;
  final String currency;
  final double exchangeRate;
  final double grossGhs;
  final double fee;
  final double netGhs;
  final String method;
  final String? stripeClientSecret;
  final String? stripePublishableKey;
  final Map<String, dynamic>? bankDetails;
  final Map<String, String>? breakdownDisplay;

  const LoadFeeBreakdown({
    required this.transactionId,
    required this.amountForeign,
    required this.currency,
    required this.exchangeRate,
    required this.grossGhs,
    required this.fee,
    required this.netGhs,
    required this.method,
    this.stripeClientSecret,
    this.stripePublishableKey,
    this.bankDetails,
    this.breakdownDisplay,
  });

  factory LoadFeeBreakdown.fromJson(Map<String, dynamic> json) {
    final breakdown = json['feeBreakdown'] as Map<String, dynamic>?;
    return LoadFeeBreakdown(
      transactionId: json['transactionId'] as String,
      amountForeign: (json['amountForeign'] as num).toDouble(),
      currency: json['currency'] as String,
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      grossGhs: (json['grossGhs'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      netGhs: (json['netGhs'] as num).toDouble(),
      method: json['method'] as String,
      stripeClientSecret: json['stripeClientSecret'] as String?,
      stripePublishableKey: json['stripePublishableKey'] as String?,
      bankDetails: json['bankDetails'] as Map<String, dynamic>?,
      breakdownDisplay: breakdown?.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}
