import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:logger/logger.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  BIOMETRIC SECURITY SERVICE
//
//  Integrates local_auth (Face ID / Fingerprint) with flutter_secure_storage
//  (iOS Secure Enclave / Android Keystore) for continuous biometric validation
//  on sensitive operations like FX swaps and large payouts.
// ══════════════════════════════════════════════════════════════════════════════

enum BiometricAuthResult {
  success,
  failed,
  notAvailable,
  notEnrolled,
  cancelled,
  lockout,
}

class BiometricSecurityService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // Uses Android Keystore for hardware-backed encryption
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      // Uses iOS Secure Enclave for hardware-backed key storage
    ),
  );

  final Logger _logger = Logger(printer: SimplePrinter());

  // ── Threshold Configuration ──────────────────────────────────────────────
  // Amounts above these thresholds trigger biometric verification
  static const double _fxSwapThreshold = 0.0; // Always require for FX swaps
  static const double _payoutThresholdUSD = 100.0;
  static const double _payoutThresholdGHS = 1000.0;

  // ── BIOMETRIC AVAILABILITY ───────────────────────────────────────────────

  /// Check if the device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException catch (e) {
      _logger.e('Biometric availability check failed: $e');
      return false;
    }
  }

  /// Get available biometric types (fingerprint, face, iris)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException {
      return [];
    }
  }

  /// Human-readable biometric type name
  Future<String> getBiometricTypeName() async {
    final types = await getAvailableBiometrics();
    if (types.contains(BiometricType.face)) return 'Face ID';
    if (types.contains(BiometricType.fingerprint)) return 'Fingerprint';
    if (types.contains(BiometricType.iris)) return 'Iris Scan';
    return 'Biometric';
  }

  // ── TRANSACTION AUTHENTICATION ───────────────────────────────────────────

  /// Authenticate for a transaction. Auto-triggers based on amount/type thresholds.
  /// Returns BiometricAuthResult indicating success or failure reason.
  Future<BiometricAuthResult> authenticateForTransaction({
    required double amount,
    required String transactionType,
    String currency = 'USD',
  }) async {
    // Determine if biometric is required based on thresholds
    final requiresBiometric = _requiresBiometric(amount, transactionType, currency);

    if (!requiresBiometric) {
      _logger.i('Transaction below biometric threshold — skipping auth');
      return BiometricAuthResult.success;
    }

    return await authenticate(
      reason: _getAuthReason(amount, transactionType, currency),
    );
  }

  /// Core biometric authentication. Triggers Face ID / Fingerprint.
  Future<BiometricAuthResult> authenticate({
    required String reason,
  }) async {
    if (!await isBiometricAvailable()) {
      _logger.w('Biometric not available on this device');
      return BiometricAuthResult.notAvailable;
    }

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN fallback for accessibility
          sensitiveTransaction: true,
        ),
      );

      if (didAuthenticate) {
        _logger.i('Biometric authentication successful');
        // Log the successful auth event
        await _logAuthEvent('success', reason);
        return BiometricAuthResult.success;
      } else {
        _logger.w('Biometric authentication failed');
        return BiometricAuthResult.failed;
      }
    } on PlatformException catch (e) {
      _logger.e('Biometric auth error: ${e.code} - ${e.message}');
      if (e.code == 'NotEnrolled') return BiometricAuthResult.notEnrolled;
      if (e.code == 'LockedOut') return BiometricAuthResult.lockout;
      if (e.code == 'UserCanceled') return BiometricAuthResult.cancelled;
      return BiometricAuthResult.failed;
    }
  }

  // ── SECURE KEY STORAGE (Hardware-Backed) ─────────────────────────────────

  /// Store a key-value pair in the device's hardware security module.
  /// iOS: Secure Enclave | Android: Keystore
  Future<void> storeSecureKey(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      _logger.i('Stored secure key: $key');
    } catch (e) {
      _logger.e('Failed to store secure key: $e');
      rethrow;
    }
  }

  /// Retrieve a value from hardware-backed secure storage.
  Future<String?> getSecureKey(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      _logger.e('Failed to read secure key: $e');
      return null;
    }
  }

  /// Delete a key from secure storage.
  Future<void> deleteSecureKey(String key) async {
    try {
      await _secureStorage.delete(key: key);
      _logger.i('Deleted secure key: $key');
    } catch (e) {
      _logger.e('Failed to delete secure key: $e');
    }
  }

  /// Check if a secure key exists.
  Future<bool> hasSecureKey(String key) async {
    final value = await getSecureKey(key);
    return value != null;
  }

  /// Store the user's auth session token in hardware-backed storage.
  Future<void> storeAuthToken(String token) async {
    await storeSecureKey('vesspay_auth_token', token);
  }

  /// Retrieve the auth session token from hardware-backed storage.
  Future<String?> getAuthToken() async {
    return await getSecureKey('vesspay_auth_token');
  }

  /// Store biometric enrollment flag.
  Future<void> setBiometricEnrolled(bool enrolled) async {
    await storeSecureKey('vesspay_biometric_enrolled', enrolled.toString());
  }

  /// Check if user has enrolled biometric authentication.
  Future<bool> isBiometricEnrolled() async {
    final value = await getSecureKey('vesspay_biometric_enrolled');
    return value == 'true';
  }

  // ── INTERNAL HELPERS ─────────────────────────────────────────────────────

  bool _requiresBiometric(double amount, String transactionType, String currency) {
    // Always require for FX swaps (any amount)
    if (transactionType == 'fx_swap' || transactionType == 'exchange') {
      return amount >= _fxSwapThreshold;
    }

    // Threshold-based for payouts
    if (currency == 'USD' || currency == 'GBP' || currency == 'EUR') {
      return amount >= _payoutThresholdUSD;
    }

    return amount >= _payoutThresholdGHS;
  }

  String _getAuthReason(double amount, String transactionType, String currency) {
    switch (transactionType) {
      case 'fx_swap':
      case 'exchange':
        return 'Authenticate to approve FX swap of $amount $currency';
      case 'send_money':
        return 'Authenticate to send $amount $currency';
      case 'pay_momo':
        return 'Authenticate Mobile Money payout of $amount $currency';
      case 'bill_payment':
        return 'Authenticate bill payment of $amount $currency';
      default:
        return 'Authenticate transaction of $amount $currency';
    }
  }

  Future<void> _logAuthEvent(String result, String reason) async {
    try {
      // Store last successful auth timestamp for audit trail
      await storeSecureKey(
        'vesspay_last_biometric_auth',
        DateTime.now().toIso8601String(),
      );
    } catch (_) {
      // Non-critical — don't fail the auth flow for logging errors
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final biometricSecurityProvider = Provider<BiometricSecurityService>((ref) {
  return BiometricSecurityService();
});

/// Stream of biometric availability (useful for conditional UI)
final isBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(biometricSecurityProvider);
  return service.isBiometricAvailable();
});

/// Human-readable biometric type for UI labels
final biometricTypeNameProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(biometricSecurityProvider);
  return service.getBiometricTypeName();
});
