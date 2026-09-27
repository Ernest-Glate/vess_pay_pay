import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final bool isBalanceHidden;
  final String selectedCurrency;

  SettingsState({
    this.isBalanceHidden = false,
    this.selectedCurrency = 'GHS',
  });

  SettingsState copyWith({
    bool? isBalanceHidden,
    String? selectedCurrency,
  }) {
    return SettingsState(
      isBalanceHidden: isBalanceHidden ?? this.isBalanceHidden,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences _prefs;
  static const _hideBalanceKey = 'hide_balance_pref';
  static const _currencyKey = 'selected_currency_pref';

  SettingsNotifier(this._prefs) : super(SettingsState(
    isBalanceHidden: _prefs.getBool(_hideBalanceKey) ?? false,
    selectedCurrency: _prefs.getString(_currencyKey) ?? 'GHS',
  ));

  Future<void> toggleBalanceVisibility() async {
    final newValue = !state.isBalanceHidden;
    await _prefs.setBool(_hideBalanceKey, newValue);
    state = state.copyWith(isBalanceHidden: newValue);
  }

  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
    state = state.copyWith(selectedCurrency: currency);
  }
}

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Should be overridden in ProviderScope
});

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return SettingsNotifier(prefs);
});
