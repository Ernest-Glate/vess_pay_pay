import 'package:json_annotation/json_annotation.dart';

part 'transaction_limit_model.g.dart';

@JsonSerializable()
class TransactionLimitModel {
  final String id;
  final String type; // 'daily', 'weekly', 'monthly', 'per_transaction'
  final String? category; // null = all transactions, or specific category
  final double limitAmount;
  final String currency;
  final double currentSpending;
  final bool isActive;
  final bool notifyAt80Percent;
  final bool notifyAt100Percent;
  final DateTime createdAt;
  final DateTime? lastResetDate;

  TransactionLimitModel({
    required this.id,
    required this.type,
    this.category,
    required this.limitAmount,
    required this.currency,
    this.currentSpending = 0.0,
    this.isActive = true,
    this.notifyAt80Percent = true,
    this.notifyAt100Percent = true,
    required this.createdAt,
    this.lastResetDate,
  });

  double get percentageUsed => (currentSpending / limitAmount * 100).clamp(0, 100);
  double get remainingAmount => (limitAmount - currentSpending).clamp(0, limitAmount);
  bool get isExceeded => currentSpending >= limitAmount;
  bool get isNearLimit => percentageUsed >= 80;

  TransactionLimitModel copyWith({
    String? id,
    String? type,
    String? category,
    double? limitAmount,
    String? currency,
    double? currentSpending,
    bool? isActive,
    bool? notifyAt80Percent,
    bool? notifyAt100Percent,
    DateTime? createdAt,
    DateTime? lastResetDate,
  }) {
    return TransactionLimitModel(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      currency: currency ?? this.currency,
      currentSpending: currentSpending ?? this.currentSpending,
      isActive: isActive ?? this.isActive,
      notifyAt80Percent: notifyAt80Percent ?? this.notifyAt80Percent,
      notifyAt100Percent: notifyAt100Percent ?? this.notifyAt100Percent,
      createdAt: createdAt ?? this.createdAt,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  factory TransactionLimitModel.fromJson(Map<String, dynamic> json) => _$TransactionLimitModelFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionLimitModelToJson(this);
}
