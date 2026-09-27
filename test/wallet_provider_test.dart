import 'package:flutter_test/flutter_test.dart';
import 'package:vesspay_mobile_flutter/features/wallet/data/wallet_provider.dart';

void main() {
  group('WalletProvider Unit Tests', () {
    test('Initial wallet state should have zero balance', () {
      final state = WalletState();
      expect(state.balance, 0.0);
      expect(state.currency, 'GHS');
      expect(state.isFrozen, false);
      expect(state.isLoading, false);
    });

    test('WalletState copyWith updates fields correctly', () {
      const initial = WalletState();
      final updated = initial.copyWith(isLoading: true);
      expect(updated.isLoading, true);
      expect(updated.balance, 0.0); // unchanged
    });

    test('Balance getter returns wallet balance or 0.0', () {
      const emptyState = WalletState(wallet: null);
      expect(emptyState.balance, 0.0);
    });

    test('clearError sets error to null', () {
      final stateWithError = WalletState(error: 'Some error');
      final cleared = stateWithError.copyWith(clearError: true);
      expect(cleared.error, null);
    });
  });
}
