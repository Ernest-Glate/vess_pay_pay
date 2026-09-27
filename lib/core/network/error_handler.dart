import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException('Connection timed out. Please try again.');
        case DioExceptionType.badResponse:
          return _handleHttpError(error);
        case DioExceptionType.cancel:
          return UnknownException('Request cancelled');
        case DioExceptionType.connectionError:
          return ServerException('Cannot reach VessPay servers. Please try again in a moment.', 'CONNECTION_ERROR');
        case DioExceptionType.unknown:
          final msg = error.error?.toString() ?? '';
          if (msg.contains('SocketException') || msg.contains('Connection refused')) {
            return ServerException('Cannot reach VessPay servers. Please try again in a moment.', 'CONNECTION_ERROR');
          }
          return UnknownException('Something went wrong. Please try again.');
        default:
          return UnknownException('Something went wrong. Please try again.');
      }
    } else if (error is AppException) {
      return error;
    }
    return UnknownException(error.toString());
  }

  static AppException _handleHttpError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final dynamic data = error.response?.data;

    // Extract backend error envelope: { success: false, error: { code, message, details } }
    final String message = _extractMessage(data) ?? _defaultMessage(statusCode);
    final String? code = _extractCode(data);

    // Map backend error codes to typed exceptions
    if (code != null) {
      return _mapByCode(code, message);
    }

    // Fallback by HTTP status
    if (statusCode == 401) return AuthException(message, code);
    if (statusCode == 403) return AuthException(message, code);
    if (statusCode == 400 || statusCode == 422) return ValidationException(message, code);
    if (statusCode == 404) return ServerException(message, code);
    if (statusCode == 409) return ValidationException(message, code);
    if (statusCode == 429) return NetworkException('Too many requests. Please slow down.');
    if (statusCode >= 500) return ServerException('Server error. Please try again later.', code);

    return ServerException(message, code);
  }

  static AppException _mapByCode(String code, String message) {
    // AUTH codes
    if (code == 'AUTH_001') return ValidationException('An account with this email already exists', code);
    if (code == 'AUTH_002') return AuthException('Invalid email or password', code);
    if (code == 'AUTH_003') return AuthException('Account locked. Try again later.', code);
    if (code == 'AUTH_004') return AuthException('Account blocked. Contact support.', code);
    if (code == 'AUTH_005') return AuthException('Invalid or expired token', code);
    if (code == 'AUTH_006') return AuthException('Session expired. Please log in again.', code);

    // Wallet codes
    if (code == 'WAL_001') return InsufficientBalanceException(message);
    if (code == 'WAL_002') return WalletFrozenException(message);
    if (code == 'WAL_003') return DailyLimitException(message);
    if (code == 'WAL_004') return ValidationException(message, code);

    // Payment codes
    if (code == 'PAY_001') return ValidationException(message, code);
    if (code == 'PAY_002') return ValidationException('Invalid phone number', code);
    if (code == 'PAY_003') return ServerException('MoMo payment failed. Please retry.', code);
    if (code == 'PAY_004') return ServerException(message, code);
    if (code == 'PAY_005') return ValidationException('Daily payment limit exceeded', code);

    // KYC codes
    if (code == 'KYC_001') return ValidationException(message, code);
    if (code == 'KYC_002') return ValidationException('KYC already submitted', code);

    // User codes
    if (code == 'USR_001') return ValidationException(message, code);

    // Generic
    if (code == 'GEN_001') return ValidationException(message, code);
    if (code == 'GEN_002') return AuthException(message, code);
    if (code == 'GEN_003') return NetworkException('Too many requests. Please slow down.');
    if (code == 'GEN_004') return ServerException(message, code);
    if (code == 'GEN_005') return ServerException(message, code);

    return ServerException(message, code);
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map) {
      // Backend envelope: { success: false, error: { code, message } }
      final errorObj = data['error'];
      if (errorObj is Map) {
        return errorObj['message'] as String?;
      }
      // Fallback flat fields
      return (data['message'] ?? data['msg']) as String?;
    }
    return null;
  }

  static String? _extractCode(dynamic data) {
    if (data is Map) {
      final errorObj = data['error'];
      if (errorObj is Map) {
        return errorObj['code'] as String?;
      }
      return data['code'] as String?;
    }
    return null;
  }

  static String _defaultMessage(int statusCode) {
    switch (statusCode) {
      case 400: return 'Invalid request';
      case 401: return 'Authentication required';
      case 403: return 'Access denied';
      case 404: return 'Not found';
      case 409: return 'Conflict';
      case 422: return 'Validation failed';
      case 429: return 'Too many requests';
      case 500: return 'Server error';
      default: return 'Something went wrong';
    }
  }
}
