abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException([String? message]) : super(message ?? 'No internet connection');
}

class AuthException extends AppException {
  AuthException([String? message, String? code]) : super(message ?? 'Authentication failed', code);
}

class ValidationException extends AppException {
  ValidationException([String? message, String? code]) : super(message ?? 'Validation failed', code);
}

class ServerException extends AppException {
  ServerException([String? message, String? code]) : super(message ?? 'Server error occurred', code);
}

class InsufficientBalanceException extends AppException {
  InsufficientBalanceException([String? message]) : super(message ?? 'Insufficient balance');
}

class WalletFrozenException extends AppException {
  WalletFrozenException([String? message])
      : super(message ?? 'Your wallet is frozen. Contact support.');
}

class DailyLimitException extends AppException {
  DailyLimitException([String? message])
      : super(message ?? 'Daily transaction limit reached.');
}

class UnknownException extends AppException {
  UnknownException([String? message]) : super(message ?? 'An unknown error occurred');
}
