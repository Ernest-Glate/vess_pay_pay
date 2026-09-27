/// Transaction model — mirrors GET /api/v1/payments/:transactionId response
class TransactionModel {
  final String id;

  /// type: 'load' | 'momo_send' | 'refund' | 'fee' | 'fx_adjustment' | 'admin_credit' | 'admin_debit'
  final String type;

  /// status: 'pending' | 'processing' | 'completed' | 'failed' | 'refunded' | 'cancelled'
  final String status;

  final double amount;
  final double fee;
  final double netAmount;
  final String currency;

  // MoMo send fields
  final String? recipientNumber;
  final String? recipientName;
  final String? recipientNetwork; // 'MTN' | 'VODAFONE' | 'AIRTELTIGO'
  final String? description;

  // Load fields
  final String? loadMethod; // 'stripe_card' | 'bank_transfer' | 'wise'
  final String? loadCurrency; // 'USD' | 'GBP' | 'EUR'
  final double? loadAmountForeign;
  final double? fxRate;

  // External references
  final String? hubtelTransactionId;
  final String? stripePaymentIntent;

  // Status details
  final String? hubtelStatus;
  final String? failureReason;
  final int retryCount;
  final bool canRetry;

  final DateTime? initiatedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.status,
    required this.amount,
    this.fee = 0.0,
    required this.netAmount,
    this.currency = 'GHS',
    this.recipientNumber,
    this.recipientName,
    this.recipientNetwork,
    this.description,
    this.loadMethod,
    this.loadCurrency,
    this.loadAmountForeign,
    this.fxRate,
    this.hubtelTransactionId,
    this.stripePaymentIntent,
    this.hubtelStatus,
    this.failureReason,
    this.retryCount = 0,
    this.canRetry = false,
    this.initiatedAt,
    this.completedAt,
    required this.createdAt,
  });

  /// Whether this is a sent MoMo payment
  bool get isSend => type == 'momo_send';

  /// Whether this is a balance load
  bool get isLoad => type == 'load';

  /// Whether this is a refund
  bool get isRefund => type == 'refund';

  /// Whether transaction is in a terminal state
  bool get isTerminal =>
      status == 'completed' || status == 'failed' ||
      status == 'refunded' || status == 'cancelled';

  /// Display label for transaction type
  String get typeLabel {
    switch (type) {
      case 'momo_send': return 'Sent';
      case 'load': return 'Loaded';
      case 'refund': return 'Refunded';
      case 'fee': return 'Fee';
      case 'admin_credit': return 'Credit';
      case 'admin_debit': return 'Debit';
      default: return type;
    }
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num?)?.toDouble() ??
          (json['feeAmount'] as num?)?.toDouble() ?? 0.0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ??
          (json['net_amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GHS',
      recipientNumber: json['recipientNumber'] as String? ??
          json['recipient_number'] as String?,
      recipientName: json['recipientName'] as String? ??
          json['recipient_name'] as String?,
      recipientNetwork: json['recipientNetwork'] as String? ??
          json['recipient_network'] as String?,
      description: json['description'] as String? ??
          json['paymentDescription'] as String? ??
          json['payment_description'] as String?,
      loadMethod: json['loadMethod'] as String? ??
          json['load_method'] as String?,
      loadCurrency: json['loadCurrency'] as String? ??
          json['load_currency'] as String?,
      loadAmountForeign: (json['loadAmountForeign'] as num?)?.toDouble() ??
          (json['load_amount_foreign'] as num?)?.toDouble(),
      fxRate: (json['fxRate'] as num?)?.toDouble() ??
          (json['fx_rate'] as num?)?.toDouble(),
      hubtelTransactionId: json['hubtelTransactionId'] as String? ??
          json['hubtel_transaction_id'] as String?,
      stripePaymentIntent: json['stripePaymentIntent'] as String? ??
          json['stripe_payment_intent'] as String?,
      hubtelStatus: json['hubtelStatus'] as String? ??
          json['hubtel_status'] as String?,
      failureReason: json['failureReason'] as String? ??
          json['failure_reason'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ??
          (json['retry_count'] as num?)?.toInt() ?? 0,
      canRetry: json['canRetry'] as bool? ?? false,
      initiatedAt: json['initiatedAt'] != null
          ? DateTime.tryParse(json['initiatedAt'] as String)
          : (json['initiated_at'] != null
              ? DateTime.tryParse(json['initiated_at'] as String)
              : null),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : (json['completed_at'] != null
              ? DateTime.tryParse(json['completed_at'] as String)
              : null),
      createdAt: DateTime.parse(
          (json['createdAt'] ?? json['created_at'] ?? DateTime.now().toIso8601String()) as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'status': status,
        'amount': amount,
        'fee': fee,
        'netAmount': netAmount,
        'currency': currency,
        'recipientNumber': recipientNumber,
        'recipientNetwork': recipientNetwork,
        'description': description,
        'retryCount': retryCount,
        'canRetry': canRetry,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Paginated transaction list response
class TransactionPage {
  final List<TransactionModel> transactions;
  final int page;
  final int limit;
  final int total;
  final int pages;

  const TransactionPage({
    required this.transactions,
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory TransactionPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>?;
    final data = json['data'] as List<dynamic>? ?? [];

    return TransactionPage(
      transactions: data
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (pagination?['page'] as num?)?.toInt() ?? 1,
      limit: (pagination?['limit'] as num?)?.toInt() ?? 20,
      total: (pagination?['total'] as num?)?.toInt() ?? 0,
      pages: (pagination?['pages'] as num?)?.toInt() ?? 1,
    );
  }

  bool get hasMore => page < pages;
}
