// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheduled_payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduledPaymentModel _$ScheduledPaymentModelFromJson(
        Map<String, dynamic> json) =>
    ScheduledPaymentModel(
      id: json['id'] as String,
      recipientName: json['recipientName'] as String,
      recipientAccount: json['recipientAccount'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      frequency: json['frequency'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      nextPaymentDate: DateTime.parse(json['nextPaymentDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String,
      category: json['category'] as String?,
    );

Map<String, dynamic> _$ScheduledPaymentModelToJson(
        ScheduledPaymentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipientName': instance.recipientName,
      'recipientAccount': instance.recipientAccount,
      'amount': instance.amount,
      'currency': instance.currency,
      'frequency': instance.frequency,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate?.toIso8601String(),
      'nextPaymentDate': instance.nextPaymentDate.toIso8601String(),
      'isActive': instance.isActive,
      'description': instance.description,
      'category': instance.category,
    };
