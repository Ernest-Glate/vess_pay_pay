import 'package:json_annotation/json_annotation.dart';

part 'beneficiary_model.g.dart';

@JsonSerializable()
class BeneficiaryModel {
  final String id;
  final String name;
  final String accountNumber;
  final String bankName;
  final String? phoneNumber;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime lastUsed;
  final int usageCount;

  BeneficiaryModel({
    required this.id,
    required this.name,
    required this.accountNumber,
    required this.bankName,
    this.phoneNumber,
    this.isFavorite = false,
    required this.createdAt,
    required this.lastUsed,
    this.usageCount = 0,
  });

  factory BeneficiaryModel.fromJson(Map<String, dynamic> json) => _$BeneficiaryModelFromJson(json);
  Map<String, dynamic> toJson() => _$BeneficiaryModelToJson(this);

  BeneficiaryModel copyWith({
    String? id,
    String? name,
    String? accountNumber,
    String? bankName,
    String? phoneNumber,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? lastUsed,
    int? usageCount,
  }) {
    return BeneficiaryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}
