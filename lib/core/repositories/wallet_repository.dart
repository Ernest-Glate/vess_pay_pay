import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';
import '../../shared/models/wallet_model.dart';
import '../../shared/models/transaction_model.dart';

class WalletRepository {
  final ApiService _api;

  WalletRepository(this._api);

  /// GET /api/v1/wallets
  /// Backend returns a flat array of wallet objects (virtual multi-currency).
  /// We extract the primary GHS wallet data.
  Future<WalletModel> getBalance() async {
    final response = await _api.get(ApiEndpoints.getBalance);
    final data = response.data;

    // Backend returns array directly (no { success, data } envelope)
    if (data is List && data.isNotEmpty) {
      // Find primary GHS wallet or use first wallet
      final primary = data.firstWhere(
        (w) => w['isPrimary'] == true || w['currency'] == 'GHS',
        orElse: () => data.first,
      );
      return WalletModel.fromJson(primary as Map<String, dynamic>);
    }

    // Fallback: might be wrapped in { data: [...] } or { data: {...} }
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data')) {
        final inner = data['data'];
        if (inner is List && inner.isNotEmpty) {
          return WalletModel.fromJson(inner.first as Map<String, dynamic>);
        }
        if (inner is Map<String, dynamic>) {
          return WalletModel.fromJson(inner);
        }
      }
      return WalletModel.fromJson(data);
    }

    throw Exception('Unexpected wallet response format');
  }

  /// GET /api/v1/fx/rates?currency=USD
  Future<FxRateModel> getFxRate(String fromCurrency) async {
    final response = await _api.get(
      ApiEndpoints.getFxRates,
      queryParameters: {'currency': fromCurrency},
    );
    final body = response.data;
    // Handle both { data: {...} } and flat response
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return FxRateModel.fromJson(body['data'] as Map<String, dynamic>);
    }
    return FxRateModel.fromJson(body as Map<String, dynamic>);
  }

  /// GET /api/v1/fx/rates (all active rates)
  Future<List<FxRateModel>> getAllFxRates() async {
    final response = await _api.get(ApiEndpoints.getFxRates);
    final body = response.data;
    // Handle both { data: [...] } and flat array response
    final List<dynamic> dataList;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      dataList = body['data'] as List<dynamic>;
    } else if (body is List) {
      dataList = body;
    } else {
      return [];
    }
    return dataList
        .map((e) => FxRateModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/v1/funding/initiate
  Future<LoadFeeBreakdown> initiateLoad({
    required double amountForeign,
    required String currency,
    required String method,
  }) async {
    final response = await _api.post(
      ApiEndpoints.initiateLoad,
      data: {
        'amount_foreign': amountForeign,
        'currency': currency,
        'method': method,
      },
    );
    final body = response.data as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    return LoadFeeBreakdown.fromJson(data);
  }

  /// POST /api/v1/funding/confirm
  Future<void> confirmLoad(String transactionId) async {
    await _api.post(
      ApiEndpoints.confirmLoad,
      data: {'transactionId': transactionId},
    );
  }

  /// GET /api/v1/funding/history
  Future<TransactionPage> getLoadHistory({int page = 1, String? status}) async {
    final response = await _api.get(
      ApiEndpoints.loadHistory,
      queryParameters: {
        'page': page,
        'limit': 20,
        if (status != null) 'status': status,
      },
    );
    final body = response.data as Map<String, dynamic>;
    return TransactionPage.fromJson(body);
  }
}

final walletRepositoryProvider = Provider((ref) {
  return WalletRepository(ref.watch(apiServiceProvider));
});
