// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bank_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BankAccountModel _$BankAccountModelFromJson(Map<String, dynamic> json) =>
    BankAccountModel(
      id: json['id'] as String,
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      accountType: json['accountType'] as String,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$BankAccountModelToJson(BankAccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bankName': instance.bankName,
      'accountNumber': instance.accountNumber,
      'accountType': instance.accountType,
      'isPrimary': instance.isPrimary,
    };
