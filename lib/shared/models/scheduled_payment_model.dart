import 'package:json_annotation/json_annotation.dart';

part 'scheduled_payment_model.g.dart';

@JsonSerializable()
class ScheduledPaymentModel {
  final String id;
  final String recipientName;
  final String recipientAccount;
  final double amount;
  final String currency;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime nextPaymentDate;
  final bool isActive;
  final String description;
  final String? category; // 'bills', 'savings', 'transfers'

  ScheduledPaymentModel({
    required this.id,
    required this.recipientName,
    required this.recipientAccount,
    required this.amount,
    required this.currency,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.nextPaymentDate,
    this.isActive = true,
    required this.description,
    this.category,
  });

  ScheduledPaymentModel copyWith({
    String? id,
    String? recipientName,
    String? recipientAccount,
    double? amount,
    String? currency,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextPaymentDate,
    bool? isActive,
    String? description,
    String? category,
  }) {
    return ScheduledPaymentModel(
      id: id ?? this.id,
      recipientName: recipientName ?? this.recipientName,
      recipientAccount: recipientAccount ?? this.recipientAccount,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      category: category ?? this.category,
    );
  }

  factory ScheduledPaymentModel.fromJson(Map<String, dynamic> json) => _$ScheduledPaymentModelFromJson(json);
  Map<String, dynamic> toJson() => _$ScheduledPaymentModelToJson(this);
}
