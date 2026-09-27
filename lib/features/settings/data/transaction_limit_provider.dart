import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/transaction_limit_model.dart';

class TransactionLimitNotifier extends StateNotifier<List<TransactionLimitModel>> {
  TransactionLimitNotifier() : super([]) {
    _loadLimits();
  }

  void _loadLimits() {
    // Mock data for demonstration
    state = [
      TransactionLimitModel(
        id: 'limit_1',
        type: 'daily',
        limitAmount: 500.00,
        currency: 'GHS',
        currentSpending: 350.00,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        lastResetDate: DateTime.now(),
      ),
      TransactionLimitModel(
        id: 'limit_2',
        type: 'weekly',
        category: 'entertainment',
        limitAmount: 1000.00,
        currency: 'GHS',
        currentSpending: 650.00,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        lastResetDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      TransactionLimitModel(
        id: 'limit_3',
        type: 'monthly',
        limitAmount: 5000.00,
        currency: 'GHS',
        currentSpending: 4750.00,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        lastResetDate: DateTime.now().subtract(const Duration(days: 5)),
      ),
      TransactionLimitModel(
        id: 'limit_4',
        type: 'per_transaction',
        category: 'bills',
        limitAmount: 2000.00,
        currency: 'GHS',
        currentSpending: 0.0,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ];
  }

  void addLimit(TransactionLimitModel limit) {
    state = [...state, limit];
  }

  void updateLimit(TransactionLimitModel limit) {
    state = [
      for (final l in state)
        if (l.id == limit.id) limit else l
    ];
  }

  void deleteLimit(String id) {
    state = state.where((l) => l.id != id).toList();
  }

  void toggleLimitStatus(String id) {
    state = [
      for (final l in state)
        if (l.id == id) l.copyWith(isActive: !l.isActive) else l
    ];
  }

  void updateSpending(String id, double amount) {
    state = [
      for (final l in state)
        if (l.id == id) l.copyWith(currentSpending: amount) else l
    ];
  }

  void resetLimit(String id) {
    state = [
      for (final l in state)
        if (l.id == id)
          l.copyWith(currentSpending: 0.0, lastResetDate: DateTime.now())
        else
          l
    ];
  }

  List<TransactionLimitModel> getActiveLimits() {
    return state.where((l) => l.isActive).toList();
  }

  List<TransactionLimitModel> getExceededLimits() {
    return state.where((l) => l.isExceeded && l.isActive).toList();
  }

  List<TransactionLimitModel> getNearLimitAlerts() {
    return state.where((l) => l.isNearLimit && !l.isExceeded && l.isActive).toList();
  }
}

final transactionLimitProvider = StateNotifierProvider<TransactionLimitNotifier, List<TransactionLimitModel>>((ref) {
  return TransactionLimitNotifier();
});
