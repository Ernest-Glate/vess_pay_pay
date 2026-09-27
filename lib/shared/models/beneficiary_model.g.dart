// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'beneficiary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BeneficiaryModel _$BeneficiaryModelFromJson(Map<String, dynamic> json) =>
    BeneficiaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      accountNumber: json['accountNumber'] as String,
      bankName: json['bankName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsed: DateTime.parse(json['lastUsed'] as String),
      usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$BeneficiaryModelToJson(BeneficiaryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'accountNumber': instance.accountNumber,
      'bankName': instance.bankName,
      'phoneNumber': instance.phoneNumber,
      'isFavorite': instance.isFavorite,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUsed': instance.lastUsed.toIso8601String(),
      'usageCount': instance.usageCount,
    };
