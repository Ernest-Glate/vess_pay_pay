// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_limit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TransactionLimitModel _$TransactionLimitModelFromJson(
        Map<String, dynamic> json) =>
    TransactionLimitModel(
      id: json['id'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      limitAmount: (json['limitAmount'] as num).toDouble(),
      currency: json['currency'] as String,
      currentSpending: (json['currentSpending'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      notifyAt80Percent: json['notifyAt80Percent'] as bool? ?? true,
      notifyAt100Percent: json['notifyAt100Percent'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastResetDate: json['lastResetDate'] == null
          ? null
          : DateTime.parse(json['lastResetDate'] as String),
    );

Map<String, dynamic> _$TransactionLimitModelToJson(
        TransactionLimitModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'category': instance.category,
      'limitAmount': instance.limitAmount,
      'currency': instance.currency,
      'currentSpending': instance.currentSpending,
      'isActive': instance.isActive,
      'notifyAt80Percent': instance.notifyAt80Percent,
      'notifyAt100Percent': instance.notifyAt100Percent,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastResetDate': instance.lastResetDate?.toIso8601String(),
    };
