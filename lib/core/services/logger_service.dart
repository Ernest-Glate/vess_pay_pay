import 'package:flutter/foundation.dart';

/// Centralized logging service for the VessPay application
/// 
/// Usage:
/// ```dart
/// LoggerService.logInfo('UserLogin', 'User logged in successfully');
/// LoggerService.logError('PaymentFailed', error, stackTrace);
/// ```
class LoggerService {
  LoggerService._();

  /// Log informational messages
  static void logInfo(String context, String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ [$context] $message');
    }
    // TODO: In production, send to analytics service
  }

  /// Log warning messages
  static void logWarning(String context, String message) {
    if (kDebugMode) {
      debugPrint('⚠️ [$context] WARNING: $message');
    }
    // TODO: In production, send to monitoring service
  }

  /// Log errors with optional stack trace
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ [$context] ERROR: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    }
    
    // TODO: In production, send to crash reporting service (e.g., Firebase Crashlytics)
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: context);
  }

  /// Log network requests (helpful for debugging API issues)
  static void logNetworkRequest(String method, String url, {Map<String, dynamic>? data}) {
    if (kDebugMode) {
      debugPrint('🌐 [Network] $method $url');
      if (data != null) {
        debugPrint('   Data: $data');
      }
    }
  }

  /// Log network responses
  static void logNetworkResponse(String url, int statusCode, {dynamic data}) {
    if (kDebugMode) {
      debugPrint('📥 [Network] Response from $url: $statusCode');
      if (data != null && kDebugMode) {
        // Only log response data in debug mode for security
        debugPrint('   Response: $data');
      }
    }
  }

  /// Log navigation events
  static void logNavigation(String from, String to) {
    if (kDebugMode) {
      debugPrint('🧭 [Navigation] $from → $to');
    }
    // TODO: Track in analytics
  }

  /// Log user actions for analytics
  static void logUserAction(String action, {Map<String, dynamic>? parameters}) {
    if (kDebugMode) {
      debugPrint('👤 [UserAction] $action ${parameters ?? ''}');
    }
    // TODO: Send to analytics service (e.g., Firebase Analytics)
    // FirebaseAnalytics.instance.logEvent(name: action, parameters: parameters);
  }
}
