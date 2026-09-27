/// Maps Flutterwave error responses and general payment errors
/// to user-friendly messages with actionable guidance.
class PaymentErrorHandler {
  PaymentErrorHandler._();

  /// Convert a Flutterwave error or status string to a user-friendly message.
  static PaymentError fromFlutterwaveStatus(String? status, {String? rawMessage}) {
    if (status == null || status.isEmpty) {
      return PaymentError(
        code: PaymentErrorCode.unknown,
        userMessage: 'An unexpected error occurred. Your card was not charged.',
        technicalMessage: rawMessage ?? 'Empty status received from Flutterwave',
      );
    }

    final normalizedStatus = status.toLowerCase().trim();

    // Match known Flutterwave error patterns
    if (_errorPatterns.containsKey(normalizedStatus)) {
      return _errorPatterns[normalizedStatus]!;
    }

    // Fuzzy match on keywords in the raw message
    if (rawMessage != null) {
      final msg = rawMessage.toLowerCase();
      if (msg.contains('declined')) return _errorPatterns['card_declined']!;
      if (msg.contains('insufficient')) return _errorPatterns['insufficient_funds']!;
      if (msg.contains('expired')) return _errorPatterns['expired_card']!;
      if (msg.contains('invalid') && msg.contains('card')) return _errorPatterns['invalid_card']!;
      if (msg.contains('3ds') || msg.contains('otp') || msg.contains('authentication')) {
        return _errorPatterns['3ds_failed']!;
      }
      if (msg.contains('timeout') || msg.contains('timed out')) return _errorPatterns['timeout']!;
      if (msg.contains('cancel')) return _errorPatterns['cancelled']!;
    }

    return PaymentError(
      code: PaymentErrorCode.unknown,
      userMessage: 'Something went wrong with the payment. Please try again.',
      technicalMessage: rawMessage ?? status,
    );
  }

  /// Handle network/connectivity errors.
  static PaymentError fromNetworkError(dynamic error) {
    final msg = error.toString().toLowerCase();

    if (msg.contains('timeout') || msg.contains('timed out')) {
      return const PaymentError(
        code: PaymentErrorCode.networkTimeout,
        userMessage: 'Connection timed out. Please check your internet and try again.',
        technicalMessage: 'Network timeout',
        isRetryable: true,
      );
    }

    if (msg.contains('socket') || msg.contains('connection refused') || msg.contains('no internet')) {
      return const PaymentError(
        code: PaymentErrorCode.noConnection,
        userMessage: 'No internet connection. Your card was not charged.',
        technicalMessage: 'No network connection',
        isRetryable: true,
      );
    }

    return PaymentError(
      code: PaymentErrorCode.networkError,
      userMessage: 'A connection error occurred. Your card was not charged. Please try again.',
      technicalMessage: error.toString(),
      isRetryable: true,
    );
  }

  // ──── Known Error Patterns ────

  static final Map<String, PaymentError> _errorPatterns = {
    'card_declined': const PaymentError(
      code: PaymentErrorCode.cardDeclined,
      userMessage: 'Your card was declined. Please try a different card or contact your bank.',
      technicalMessage: 'Card declined by issuing bank',
    ),
    'insufficient_funds': const PaymentError(
      code: PaymentErrorCode.insufficientFunds,
      userMessage: 'Insufficient funds on this card. Please try a different card or a smaller amount.',
      technicalMessage: 'Insufficient funds',
    ),
    'invalid_card': const PaymentError(
      code: PaymentErrorCode.invalidCard,
      userMessage: 'Invalid card details. Please check your card number, expiry, and CVV.',
      technicalMessage: 'Invalid card details',
      isRetryable: true,
    ),
    'expired_card': const PaymentError(
      code: PaymentErrorCode.expiredCard,
      userMessage: 'This card has expired. Please use a different card.',
      technicalMessage: 'Card expired',
    ),
    '3ds_failed': const PaymentError(
      code: PaymentErrorCode.authenticationFailed,
      userMessage: 'Card verification failed. Please try again or use a different card.',
      technicalMessage: '3D Secure authentication failed',
      isRetryable: true,
    ),
    'timeout': const PaymentError(
      code: PaymentErrorCode.networkTimeout,
      userMessage: 'The payment timed out. Your card was not charged. Please try again.',
      technicalMessage: 'Payment timeout',
      isRetryable: true,
    ),
    'cancelled': const PaymentError(
      code: PaymentErrorCode.userCancelled,
      userMessage: 'Payment was cancelled.',
      technicalMessage: 'User cancelled payment',
    ),
    'error': const PaymentError(
      code: PaymentErrorCode.unknown,
      userMessage: 'The payment could not be processed. Please try again.',
      technicalMessage: 'Generic error from Flutterwave',
      isRetryable: true,
    ),
  };
}

// ──── Data Classes ────

enum PaymentErrorCode {
  cardDeclined,
  insufficientFunds,
  invalidCard,
  expiredCard,
  authenticationFailed,
  networkTimeout,
  noConnection,
  networkError,
  userCancelled,
  verificationFailed,
  amountLimitExceeded,
  unknown,
}

class PaymentError {
  final PaymentErrorCode code;
  final String userMessage;
  final String technicalMessage;
  final bool isRetryable;

  const PaymentError({
    required this.code,
    required this.userMessage,
    required this.technicalMessage,
    this.isRetryable = false,
  });
}
