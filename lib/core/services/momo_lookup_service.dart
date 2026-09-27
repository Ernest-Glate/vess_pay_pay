import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_service.dart';
import '../network/api_endpoints.dart';

// ── Models ──────────────────────────────────────────────────────────────────

/// Result returned after a successful MoMo account lookup.
class MoMoRecipientResult {
  final String accountName;
  final String network;
  final bool isValid;

  const MoMoRecipientResult({
    required this.accountName,
    required this.network,
    required this.isValid,
  });

  factory MoMoRecipientResult.fromJson(Map<String, dynamic> json) {
    return MoMoRecipientResult(
      accountName: json['accountName'] as String? ?? '',
      network: json['network'] as String? ?? '',
      isValid: json['isValid'] as bool? ?? false,
    );
  }
}

// ── State ───────────────────────────────────────────────────────────────────

/// Represents all possible states for a MoMo recipient lookup.
sealed class MoMoLookupState {
  const MoMoLookupState();
}

class MoMoLookupIdle extends MoMoLookupState {
  const MoMoLookupIdle();
}

class MoMoLookupLoading extends MoMoLookupState {
  const MoMoLookupLoading();
}

class MoMoLookupSuccess extends MoMoLookupState {
  final MoMoRecipientResult result;
  const MoMoLookupSuccess(this.result);
}

class MoMoLookupError extends MoMoLookupState {
  final String message;
  const MoMoLookupError(this.message);
}

// ── Notifier ────────────────────────────────────────────────────────────────

class MoMoLookupNotifier extends StateNotifier<MoMoLookupState> {
  final ApiService _api;
  Timer? _debounce;

  /// Toggle this to `false` once the real backend endpoint is live.
  static const bool _useMock = true;

  MoMoLookupNotifier(this._api) : super(const MoMoLookupIdle());

  /// Call this on every phone-input change.
  /// The lookup only fires once the cleaned number is ≥ 10 digits,
  /// after a 500 ms debounce window with no further input.
  void onPhoneChanged(String raw) {
    _debounce?.cancel();
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');

    if (cleaned.length < 10) {
      state = const MoMoLookupIdle();
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _lookup(cleaned);
    });
  }

  /// Manually retry the last lookup (e.g. after a network error).
  void retry(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length >= 10) _lookup(cleaned);
  }

  /// Reset to idle (e.g. when the user clears the field).
  void reset() {
    _debounce?.cancel();
    state = const MoMoLookupIdle();
  }

  // ── Private ─────────────────────────────────────────────────────────────

  Future<void> _lookup(String phone) async {
    state = const MoMoLookupLoading();

    try {
      if (_useMock) {
        await _mockLookup(phone);
      } else {
        await _realLookup(phone);
      }
    } catch (e) {
      state = MoMoLookupError(e.toString());
    }
  }

  /// Real API call — swap in once backend is live.
  Future<void> _realLookup(String phone) async {
    final response = await _api.get(ApiEndpoints.momoValidate(phone));
    final data = _api.extractData(response);

    if (data is Map<String, dynamic>) {
      final result = MoMoRecipientResult.fromJson(data);
      if (result.isValid) {
        state = MoMoLookupSuccess(result);
      } else {
        state = const MoMoLookupError('This number is not registered on any mobile money network.');
      }
    } else {
      state = const MoMoLookupError('Unexpected response from server.');
    }
  }

  /// Realistic mock — 800 ms delay, returns a believable name.
  Future<void> _mockLookup(String phone) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Detect network from prefix for the mock
    final prefix = phone.length >= 3 ? phone.substring(0, 3) : '';
    String network = 'Unknown';
    if (['024', '054', '055', '059'].contains(prefix)) {
      network = 'MTN Mobile Money';
    } else if (['020', '050'].contains(prefix)) {
      network = 'Vodafone Cash';
    } else if (['027', '057', '026', '056'].contains(prefix)) {
      network = 'AirtelTigo Money';
    }

    // Simulated names keyed by last two digits for variety
    final lastTwo = phone.substring(phone.length - 2);
    final names = {
      '67': 'KOFI MENSAH',
      '43': 'AMA SERWAA',
      '23': 'KWAME ASANTE',
      '45': 'ABENA POKUA',
      '89': 'YAW BOATENG',
      '01': 'AKUA AFRIYIE',
    };
    final name = names[lastTwo] ?? 'FRANK ADJEI BEDIAKO';

    state = MoMoLookupSuccess(
      MoMoRecipientResult(
        accountName: name,
        network: network,
        isValid: true,
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// ── Provider ────────────────────────────────────────────────────────────────

final momoLookupProvider =
    StateNotifierProvider.autoDispose<MoMoLookupNotifier, MoMoLookupState>(
  (ref) => MoMoLookupNotifier(ref.watch(apiServiceProvider)),
);
