import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/transfer_repository.dart';
import '../../../shared/models/transaction_model.dart';

class TransactionState {
  final List<TransactionModel> transactions;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final TransactionModel? selectedTransaction;

  const TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.selectedTransaction,
  });

  TransactionState copyWith({
    List<TransactionModel>? transactions,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    bool? hasMore,
    TransactionModel? selectedTransaction,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      selectedTransaction: clearSelected ? null : (selectedTransaction ?? this.selectedTransaction),
    );
  }
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  final PaymentRepository _repo;

  TransactionNotifier(this._repo) : super(const TransactionState());

  /// GET /api/v1/payments/history — first page
  Future<void> fetchTransactions({
    String? status,
    String? type,
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _repo.getHistory(
        page: 1,
        status: status,
        type: type,
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(
        transactions: page.transactions,
        isLoading: false,
        currentPage: 1,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// GET /api/v1/payments/history — next page (pagination)
  Future<void> fetchMore() async {
    if (!state.hasMore || state.isLoadingMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final page = await _repo.getHistory(page: nextPage);
      state = state.copyWith(
        transactions: [...state.transactions, ...page.transactions],
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  /// GET /api/v1/payments/:transactionId
  Future<void> fetchTransaction(String transactionId) async {
    state = state.copyWith(clearError: true);
    try {
      final tx = await _repo.getTransaction(transactionId);
      state = state.copyWith(selectedTransaction: tx);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// POST /api/v1/payments/:id/cancel
  Future<TransactionModel?> retryTransaction(String transactionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tx = await _repo.cancelPayment(transactionId);
      // Update the transaction in the list
      final updated = state.transactions.map((t) => t.id == tx.id ? tx : t).toList();
      state = state.copyWith(
        transactions: updated,
        selectedTransaction: tx,
        isLoading: false,
      );
      return tx;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Prepend a new transaction after a successful payment (optimistic)
  void addTransaction(TransactionModel transaction) {
    state = state.copyWith(
      transactions: [transaction, ...state.transactions],
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
  void clearSelected() => state = state.copyWith(clearSelected: true);
}

final transactionProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(ref.watch(paymentRepositoryProvider));
});

/// Convenience: flat list of transactions
final transactionListProvider = Provider<List<TransactionModel>>((ref) {
  return ref.watch(transactionProvider).transactions;
});
