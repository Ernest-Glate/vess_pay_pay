import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../shared/models/wallet_model.dart';

/// Multi-currency wallet state.
///
/// Holds 1–2 wallets based on user's country:
/// - African user: local currency + USD holding
/// - Diaspora user: USD only
class WalletState {
  final List<WalletModel> wallets;
  final bool isLoading;
  final String? error;
  final List<FxRateModel> fxRates;
  final int activeCardIndex;

  const WalletState({
    this.wallets = const [],
    this.isLoading = false,
    this.error,
    this.fxRates = const [],
    this.activeCardIndex = 0,
  });

  /// Primary wallet (the active card in the carousel)
  WalletModel? get activeWallet =>
      wallets.isNotEmpty && activeCardIndex < wallets.length
          ? wallets[activeCardIndex]
          : wallets.isNotEmpty
              ? wallets.first
              : null;

  /// Backward-compatible getters
  WalletModel? get wallet => wallets.isNotEmpty ? wallets.first : null;
  double get balance => activeWallet?.balance ?? 0.0;
  String get currency => activeWallet?.currency ?? 'GHS';
  bool get isFrozen => activeWallet?.isFrozen ?? false;

  /// Find a specific wallet by currency code
  WalletModel? walletFor(String currency) {
    try {
      return wallets.firstWhere((w) => w.currency == currency);
    } catch (_) {
      return null;
    }
  }

  /// Whether this user has multiple wallets (African user)
  bool get hasMultipleWallets => wallets.length > 1;

  WalletState copyWith({
    List<WalletModel>? wallets,
    bool? isLoading,
    String? error,
    List<FxRateModel>? fxRates,
    int? activeCardIndex,
    bool clearError = false,
  }) {
    return WalletState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      fxRates: fxRates ?? this.fxRates,
      activeCardIndex: activeCardIndex ?? this.activeCardIndex,
    );
  }
}

class WalletNotifier extends StateNotifier<WalletState> {
  final WalletRepository _repo;

  WalletNotifier(this._repo) : super(const WalletState());

  /// Fetch all wallets from GET /api/v1/wallets.
  /// The backend returns an array of wallet objects, one per currency.
  Future<void> fetchBalance() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final wallet = await _repo.getBalance();
      // The repo currently returns a single WalletModel.
      // Build the multi-wallet list from it + a simulated USD holding.
      // In production, GET /wallets returns the full array.
      final wallets = _buildWalletList(wallet);
      state = state.copyWith(wallets: wallets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Build the wallet list based on the primary wallet's currency.
  /// African user: [local, USD]. Diaspora: [USD].
  List<WalletModel> _buildWalletList(WalletModel primary) {
    if (primary.currency == 'USD') {
      // Diaspora user — single USD wallet
      return [primary];
    }

    // African user — local currency + USD holding
    // TODO: In production, the backend returns both wallets.
    // For now, simulate the USD holding.
    final usdHolding = WalletModel(
      balance: primary.balance > 0 ? (primary.balance / 15.5) : 0.0,
      currency: 'USD',
      isFrozen: false,
      totalLoaded: 0,
      totalSpent: 0,
      totalRefunded: 0,
      dailySpendToday: 0,
      dailySpendLimit: 5000,
      dailyLimitRemaining: 5000,
    );

    return [primary, usdHolding];
  }

  /// Set the active card index (when user swipes the carousel)
  void setActiveCard(int index) {
    if (index >= 0 && index < state.wallets.length) {
      state = state.copyWith(activeCardIndex: index);
    }
  }

  /// GET /api/v1/wallet/fx-rates (all)
  Future<void> fetchFxRates() async {
    try {
      final rates = await _repo.getAllFxRates();
      state = state.copyWith(fxRates: rates);
    } catch (_) {
      // Non-fatal — FX rates may not be critical for every screen
    }
  }

  /// GET /api/v1/wallet/fx-rates?currency=USD
  Future<FxRateModel?> getFxRate(String currency) async {
    try {
      return await _repo.getFxRate(currency);
    } catch (_) {
      return null;
    }
  }

  /// POST /api/v1/wallet/load/initiate
  Future<LoadFeeBreakdown?> initiateLoad({
    required double amountForeign,
    required String currency,
    required String method,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repo.initiateLoad(
        amountForeign: amountForeign,
        currency: currency,
        method: method,
      );
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// POST /api/v1/wallet/load/confirm
  Future<bool> confirmLoad(String transactionId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.confirmLoad(transactionId);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Update balance after a successful payment (optimistic)
  void updateBalance(double newBalance) {
    if (state.wallets.isNotEmpty) {
      final updated = state.wallets.map((w) {
        if (w.currency == state.currency) {
          return w.copyWith(balance: newBalance);
        }
        return w;
      }).toList();
      state = state.copyWith(wallets: updated);
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, WalletState>((ref) {
  return WalletNotifier(ref.watch(walletRepositoryProvider));
});

// Convenience providers
final balanceProvider = Provider<double>((ref) {
  return ref.watch(walletProvider).balance;
});

final walletFrozenProvider = Provider<bool>((ref) {
  return ref.watch(walletProvider).isFrozen;
});
