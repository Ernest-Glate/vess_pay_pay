import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import '../network/api_service.dart';
import '../config/app_config.dart';
import 'logger_service.dart';
import 'audit_logger.dart';
import 'payment_error_handler.dart';
import 'fee_calculator.dart';
import '../../shared/models/card_transaction_model.dart';

/// Flutterwave Payment Service — production-ready.
/// Handles wallet funding via Flutterwave with audit logging,
/// structured error handling, and retry logic for verification.
class FlutterwaveService {
  final ApiService _api;
  String? _publicKey;
  bool _isInitialized = false;

  static const int _maxVerifyRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);

  FlutterwaveService(this._api);

  /// Fetch Flutterwave configuration from backend.
  /// Falls back to AppConfig if backend is unreachable.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final response = await _api.get('/payments/flutterwave/config');
      _publicKey = response.data['data']['publicKey'];
      _isInitialized = true;
      LoggerService.logInfo('FlutterwaveService', 'Initialized from backend');
    } catch (e) {
      // Fallback to environment config
      _publicKey = null; // No fallback key — Flutterwave requires backend config
      _isInitialized = _publicKey != null && _publicKey!.isNotEmpty;
      LoggerService.logWarning(
        'FlutterwaveService',
        'Backend config unavailable, using fallback: $e',
      );
    }
  }

  /// Fund wallet via Flutterwave.
  /// Opens Flutterwave payment UI and handles the full payment lifecycle.
  /// Returns a structured [CardTransaction] with final status.
  Future<CardTransaction> fundWallet({
    required BuildContext context,
    required String userId,
    required double amount,
    required String currency,
    required String email,
    required String phone,
    required String name,
  }) async {
    // Ensure initialized
    if (!_isInitialized) {
      await initialize();
    }

    // Validate amount limits
    final amountValidation = FeeCalculator.validateAmount(
      amount: amount,
      currency: currency,
    );
    if (!amountValidation.isValid) {
      return CardTransaction.pending(
        txRef: 'INVALID',
        amount: amount,
        currency: currency,
        fee: 0,
        userId: userId,
      ).copyWith(
        status: TransactionStatus.failed,
        errorMessage: amountValidation.error,
        errorCode: PaymentErrorCode.amountLimitExceeded.name,
      );
    }

    // Calculate fee
    final feeBreakdown = FeeCalculator.calculate(amount: amount, currency: currency);

    // Generate unique transaction reference
    final txRef = 'VPY_${DateTime.now().millisecondsSinceEpoch}_${userId.length >= 8 ? userId.substring(0, 8) : userId}';

    // Create pending transaction
    var transaction = CardTransaction.pending(
      txRef: txRef,
      amount: amount,
      currency: currency,
      fee: feeBreakdown.fee,
      userId: userId,
    );

    // Audit: initiated
    AuditLogger.depositInitiated(
      txRef: txRef,
      amount: amount,
      currency: currency,
      fee: feeBreakdown.fee,
      userId: userId,
    );

    if (_publicKey == null || _publicKey!.isEmpty) {
      transaction = transaction.copyWith(
        status: TransactionStatus.failed,
        errorMessage: 'Payment service not configured. Please try again later.',
        errorCode: PaymentErrorCode.unknown.name,
      );
      AuditLogger.depositFailed(
        txRef: txRef,
        errorCode: 'CONFIG_MISSING',
        errorMessage: 'Public key not available',
        amount: amount,
        currency: currency,
      );
      return transaction;
    }

    try {
      // Update to processing
      transaction = transaction.copyWith(status: TransactionStatus.processing);
      AuditLogger.depositProcessing(txRef: txRef);

      // Configure Flutterwave
      final customer = Customer(
        name: name,
        phoneNumber: phone,
        email: email,
      );

      final isTestMode = AppConfig.current.baseUrl.contains('localhost') ||
          AppConfig.current.baseUrl.contains('staging');

      final flutterwave = Flutterwave(
        publicKey: _publicKey!,
        currency: currency,
        redirectUrl: 'vesspay://payment/callback',
        txRef: txRef,
        amount: amount.toStringAsFixed(2),
        customer: customer,
        paymentOptions: 'card,mobilemoney,ussd',
        customization: Customization(
          title: 'VessPay Wallet Funding',
          description: 'Add ${feeBreakdown.amountDisplay} to your wallet',
          logo: 'https://vesspay.com/logo.png',
        ),
        isTestMode: isTestMode,
      );

      // Launch Flutterwave payment UI
      // ignore: use_build_context_synchronously
      final ChargeResponse response = await flutterwave.charge(context);

      if (response.success == true && response.transactionId != null) {
        // Verify payment on backend with retry
        final verified = await _verifyWithRetry(response.transactionId!, txRef);

        if (verified) {
          transaction = transaction.copyWith(
            status: TransactionStatus.successful,
            flutterwaveId: response.transactionId,
          );

          AuditLogger.depositSuccess(
            txRef: txRef,
            flutterwaveId: response.transactionId!,
            amount: amount,
            currency: currency,
          );
        } else {
          transaction = transaction.copyWith(
            status: TransactionStatus.failed,
            flutterwaveId: response.transactionId,
            errorMessage: 'Payment verification failed. If you were charged, please contact support.',
            errorCode: PaymentErrorCode.verificationFailed.name,
          );

          AuditLogger.depositFailed(
            txRef: txRef,
            flutterwaveId: response.transactionId,
            errorCode: 'VERIFICATION_FAILED',
            errorMessage: 'Backend verification failed after retries',
            amount: amount,
            currency: currency,
          );
        }
      } else {
        // Payment failed or was cancelled
        final error = PaymentErrorHandler.fromFlutterwaveStatus(
          response.status,
          rawMessage: response.status,
        );

        final isCancelled = error.code == PaymentErrorCode.userCancelled;

        transaction = transaction.copyWith(
          status: isCancelled ? TransactionStatus.cancelled : TransactionStatus.failed,
          errorMessage: error.userMessage,
          errorCode: error.code.name,
        );

        if (isCancelled) {
          AuditLogger.depositCancelled(txRef: txRef, amount: amount, currency: currency);
        } else {
          AuditLogger.depositFailed(
            txRef: txRef,
            errorCode: error.code.name,
            errorMessage: error.technicalMessage,
            amount: amount,
            currency: currency,
          );
        }
      }
    } catch (e) {
      final error = PaymentErrorHandler.fromNetworkError(e);

      transaction = transaction.copyWith(
        status: TransactionStatus.failed,
        errorMessage: error.userMessage,
        errorCode: error.code.name,
      );

      AuditLogger.depositFailed(
        txRef: txRef,
        errorCode: error.code.name,
        errorMessage: e.toString(),
        amount: amount,
        currency: currency,
      );
    }

    return transaction;
  }

  /// Verify payment on backend with exponential backoff retry.
  Future<bool> _verifyWithRetry(String transactionId, String txRef) async {
    for (int attempt = 1; attempt <= _maxVerifyRetries; attempt++) {
      try {
        AuditLogger.verificationAttempt(
          txRef: txRef,
          flutterwaveId: transactionId,
          attemptNumber: attempt,
        );

        await _api.get('/payments/flutterwave/verify/$transactionId');
        LoggerService.logInfo(
          'FlutterwaveService',
          'Payment verified on attempt $attempt: $transactionId',
        );
        return true;
      } catch (e) {
        LoggerService.logWarning(
          'FlutterwaveService',
          'Verification attempt $attempt failed: $e',
        );

        if (attempt < _maxVerifyRetries) {
          await Future.delayed(_retryDelay * attempt); // Exponential backoff
        }
      }
    }
    return false;
  }

  /// Check if service is ready.
  bool get isReady => _isInitialized && _publicKey != null;
}
