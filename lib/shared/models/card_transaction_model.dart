/// Transaction model for card deposits via Flutterwave.
/// Tracks the full lifecycle: pending → processing → success/failure.
class CardTransaction {
  final String id;
  final String txRef;
  final String? flutterwaveId;
  final double amount;
  final String currency;
  final double fee;
  final double totalCharged;
  final TransactionStatus status;
  final String? cardLast4;
  final String? cardBrand;
  final String? errorMessage;
  final String? errorCode;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? userId;

  const CardTransaction({
    required this.id,
    required this.txRef,
    this.flutterwaveId,
    required this.amount,
    required this.currency,
    required this.fee,
    required this.totalCharged,
    required this.status,
    this.cardLast4,
    this.cardBrand,
    this.errorMessage,
    this.errorCode,
    required this.createdAt,
    this.updatedAt,
    this.userId,
  });

  /// Create a new pending transaction.
  factory CardTransaction.pending({
    required String txRef,
    required double amount,
    required String currency,
    required double fee,
    String? userId,
  }) {
    return CardTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      txRef: txRef,
      amount: amount,
      currency: currency,
      fee: fee,
      totalCharged: amount + fee,
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
      userId: userId,
    );
  }

  /// Copy with updated fields (immutable update pattern).
  CardTransaction copyWith({
    String? flutterwaveId,
    TransactionStatus? status,
    String? cardLast4,
    String? cardBrand,
    String? errorMessage,
    String? errorCode,
    DateTime? updatedAt,
  }) {
    return CardTransaction(
      id: id,
      txRef: txRef,
      flutterwaveId: flutterwaveId ?? this.flutterwaveId,
      amount: amount,
      currency: currency,
      fee: fee,
      totalCharged: totalCharged,
      status: status ?? this.status,
      cardLast4: cardLast4 ?? this.cardLast4,
      cardBrand: cardBrand ?? this.cardBrand,
      errorMessage: errorMessage ?? this.errorMessage,
      errorCode: errorCode ?? this.errorCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId,
    );
  }

  /// Serialize to JSON for backend/logging.
  Map<String, dynamic> toJson() => {
    'id': id,
    'txRef': txRef,
    'flutterwaveId': flutterwaveId,
    'amount': amount,
    'currency': currency,
    'fee': fee,
    'totalCharged': totalCharged,
    'status': status.name,
    'cardLast4': cardLast4,
    'cardBrand': cardBrand,
    'errorMessage': errorMessage,
    'errorCode': errorCode,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
    'userId': userId,
  };

  /// Deserialize from JSON.
  factory CardTransaction.fromJson(Map<String, dynamic> json) {
    return CardTransaction(
      id: json['id'] as String,
      txRef: json['txRef'] as String,
      flutterwaveId: json['flutterwaveId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      fee: (json['fee'] as num).toDouble(),
      totalCharged: (json['totalCharged'] as num).toDouble(),
      status: TransactionStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      cardLast4: json['cardLast4'] as String?,
      cardBrand: json['cardBrand'] as String?,
      errorMessage: json['errorMessage'] as String?,
      errorCode: json['errorCode'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      userId: json['userId'] as String?,
    );
  }

  /// Whether this transaction is in a terminal (final) state.
  bool get isTerminal => status == TransactionStatus.successful ||
      status == TransactionStatus.failed ||
      status == TransactionStatus.cancelled;
}

/// Transaction lifecycle states.
enum TransactionStatus {
  pending,
  processing,
  successful,
  failed,
  cancelled;

  String get displayName {
    switch (this) {
      case TransactionStatus.pending: return 'Pending';
      case TransactionStatus.processing: return 'Processing';
      case TransactionStatus.successful: return 'Successful';
      case TransactionStatus.failed: return 'Failed';
      case TransactionStatus.cancelled: return 'Cancelled';
    }
  }

  bool get isPositive => this == TransactionStatus.successful;
  bool get isNegative => this == TransactionStatus.failed || this == TransactionStatus.cancelled;
}
