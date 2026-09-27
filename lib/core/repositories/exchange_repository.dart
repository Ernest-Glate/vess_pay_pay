import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../../shared/models/transaction_model.dart';

class ExchangeRepository {
  final ApiService _apiService;

  ExchangeRepository(this._apiService);

  Future<double> getRate(String from, String to) async {
    final response = await _apiService.get('/exchange/rate', queryParameters: {
      'from': from,
      'to': to,
    });
    return (response.data['rate'] as num).toDouble();
  }

  Future<TransactionModel> executeExchange({
    required String fromCurrency,
    required String toCurrency,
    required double fromAmount,
  }) async {
    final response = await _apiService.post('/exchange', data: {
      'from': fromCurrency,
      'to': toCurrency,
      'amount': fromAmount,
    });
    return TransactionModel.fromJson(response.data);
  }
}

final exchangeRepositoryProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExchangeRepository(apiService);
});
