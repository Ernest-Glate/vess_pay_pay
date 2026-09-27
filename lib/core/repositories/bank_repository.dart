import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import '../network/api_service.dart';

part 'bank_repository.g.dart';

@JsonSerializable()
class BankAccountModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountType; // 'savings', 'current', 'card'
  final bool isPrimary;

  BankAccountModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountType,
    this.isPrimary = false,
  });

  factory BankAccountModel.fromJson(Map<String, dynamic> json) => _$BankAccountModelFromJson(json);
  Map<String, dynamic> toJson() => _$BankAccountModelToJson(this);
}

class BankRepository {
  // ignore: unused_field
  final ApiService _apiService;

  BankRepository(this._apiService);

  Future<List<BankAccountModel>> getLinkedAccounts() async {
    try {
      // TODO: Uncomment when backend endpoint /banks is ready
      // final response = await _apiService.get('/banks');
      // return (response.data as List).map((e) => BankAccountModel.fromJson(e)).toList();
      
      // Temporary Mock Data to prevent crash
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
      return [
        BankAccountModel(
          id: '1',
          bankName: 'GT Bank',
          accountNumber: '**** 1234',
          accountType: 'savings',
          isPrimary: true,
        ),
        BankAccountModel(
          id: '2',
          bankName: 'Ecobank',
          accountNumber: '**** 5678',
          accountType: 'current',
          isPrimary: false,
        ),
      ];
    } catch (e) {
      // Fallback to empty list or mock instead of crashing
      return [];
    }
  }

  Future<BankAccountModel> linkAccount(String bankName, String accountNumber) async {
    try {
      // final response = await _apiService.post('/banks', data: {
      //   'bankName': bankName,
      //   'accountNumber': accountNumber,
      // });
      // return BankAccountModel.fromJson(response.data);

      await Future.delayed(const Duration(seconds: 1));
      return BankAccountModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bankName: bankName,
        accountNumber: accountNumber,
        accountType: 'savings',
      );
    } catch (e) {
      rethrow;
    }
  }
}

final bankRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return BankRepository(apiService);
});
