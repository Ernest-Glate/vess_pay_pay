import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/flutterwave_service.dart';
import '../../../core/services/fee_calculator.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/card_transaction_model.dart';
import '../../wallet/data/wallet_provider.dart';

/// State for a card deposit operation.
class CardDepositState {
  final CardTransaction? currentTransaction;
  final bool isProcessing;
  final String? errorMessage;
  final FeeBreakdown? feePreview;
  final List<CardTransaction> history;

  const CardDepositState({
    this.currentTransaction,
    this.isProcessing = false,
    this.errorMessage,
    this.feePreview,
    this.history = const [],
  });

  CardDepositState copyWith({
    CardTransaction? currentTransaction,
    bool? isProcessing,
    String? errorMessage,
    FeeBreakdown? feePreview,
    List<CardTransaction>? history,
  }) {
    return CardDepositState(
      currentTransaction: currentTransaction ?? this.currentTransaction,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
      feePreview: feePreview ?? this.feePreview,
      history: history ?? this.history,
    );
  }
}

/// Manages card deposit state and orchestrates the deposit flow.
class CardDepositNotifier extends StateNotifier<CardDepositState> {
  final FlutterwaveService _flutterwaveService;
  final WalletNotifier _walletNotifier;

  CardDepositNotifier(this._flutterwaveService, this._walletNotifier)
      : super(const CardDepositState());

  /// Preview the fee for a given amount and currency.
  void previewFee({required double amount, required String currency}) {
    if (amount <= 0) {
      state = state.copyWith(feePreview: null);
      return;
    }

    final breakdown = FeeCalculator.calculate(amount: amount, currency: currency);
    state = state.copyWith(feePreview: breakdown);
  }

  /// Validate amount before initiating deposit.
  String? validateAmount(double amount, String currency) {
    final validation = FeeCalculator.validateAmount(amount: amount, currency: currency);
    return validation.isValid ? null : validation.error;
  }

  /// Initiate a card deposit via Flutterwave.
  Future<CardTransaction> initiateDeposit({
    required BuildContext context,
    required double amount,
    required String currency,
    required String userId,
    required String email,
    required String phone,
    required String name,
  }) async {
    // Clear previous error
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final transaction = await _flutterwaveService.fundWallet(
        context: context,
        userId: userId,
        amount: amount,
        currency: currency,
        email: email,
        phone: phone,
        name: name,
      );

      // Update state with result
      state = state.copyWith(
        currentTransaction: transaction,
        isProcessing: false,
        errorMessage: transaction.status.isNegative ? transaction.errorMessage : null,
        history: [transaction, ...state.history],
      );

      // If successful, refresh wallet balance from server
      if (transaction.status == TransactionStatus.successful) {
        await _walletNotifier.fetchBalance();
      }

      return transaction;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      rethrow;
    }
  }

  /// Reset state for a new deposit.
  void reset() {
    state = const CardDepositState();
  }

  /// Clear only the error message.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ──── Providers ────

final flutterwaveServiceProvider = Provider<FlutterwaveService>((ref) {
  final api = ref.watch(apiServiceProvider);
  return FlutterwaveService(api);
});

final cardDepositProvider = StateNotifierProvider<CardDepositNotifier, CardDepositState>((ref) {
  final flutterwaveService = ref.watch(flutterwaveServiceProvider);
  final walletNotifier = ref.watch(walletProvider.notifier);
  return CardDepositNotifier(flutterwaveService, walletNotifier);
});
