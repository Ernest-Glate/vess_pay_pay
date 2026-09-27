import 'dart:convert';
import 'logger_service.dart';

/// Structured audit logger for payment transactions.
/// Provides an immutable audit trail for all deposit operations.
class AuditLogger {
  AuditLogger._();

  static const String _tag = 'AuditLogger';

  /// Log a deposit initiation event.
  static void depositInitiated({
    required String txRef,
    required double amount,
    required String currency,
    required double fee,
    String? userId,
  }) {
    _log(AuditEvent(
      type: AuditEventType.depositInitiated,
      txRef: txRef,
      amount: amount,
      currency: currency,
      fee: fee,
      userId: userId,
    ));
  }

  /// Log when payment is being processed.
  static void depositProcessing({
    required String txRef,
    String? flutterwaveId,
  }) {
    _log(AuditEvent(
      type: AuditEventType.depositProcessing,
      txRef: txRef,
      flutterwaveId: flutterwaveId,
    ));
  }

  /// Log a successful deposit.
  static void depositSuccess({
    required String txRef,
    required String flutterwaveId,
    required double amount,
    required String currency,
    String? cardLast4,
    String? cardBrand,
  }) {
    _log(AuditEvent(
      type: AuditEventType.depositSuccess,
      txRef: txRef,
      flutterwaveId: flutterwaveId,
      amount: amount,
      currency: currency,
      cardLast4: cardLast4,
      cardBrand: cardBrand,
    ));
  }

  /// Log a failed deposit.
  static void depositFailed({
    required String txRef,
    String? flutterwaveId,
    String? errorCode,
    String? errorMessage,
    double? amount,
    String? currency,
  }) {
    _log(AuditEvent(
      type: AuditEventType.depositFailed,
      txRef: txRef,
      flutterwaveId: flutterwaveId,
      errorCode: errorCode,
      errorMessage: errorMessage,
      amount: amount,
      currency: currency,
    ));
  }

  /// Log a deposit cancellation.
  static void depositCancelled({
    required String txRef,
    double? amount,
    String? currency,
  }) {
    _log(AuditEvent(
      type: AuditEventType.depositCancelled,
      txRef: txRef,
      amount: amount,
      currency: currency,
    ));
  }

  /// Log a verification attempt.
  static void verificationAttempt({
    required String txRef,
    required String flutterwaveId,
    required int attemptNumber,
  }) {
    _log(AuditEvent(
      type: AuditEventType.verificationAttempt,
      txRef: txRef,
      flutterwaveId: flutterwaveId,
      metadata: {'attempt': attemptNumber},
    ));
  }

  // ──── Internal ────

  static void _log(AuditEvent event) {
    final jsonString = const JsonEncoder.withIndent(null).convert(event.toJson());
    LoggerService.logInfo(_tag, '[${event.type.name}] $jsonString');
  }
}

// ──── Data Classes ────

enum AuditEventType {
  depositInitiated,
  depositProcessing,
  depositSuccess,
  depositFailed,
  depositCancelled,
  verificationAttempt,
}

class AuditEvent {
  final AuditEventType type;
  final String? txRef;
  final String? flutterwaveId;
  final double? amount;
  final String? currency;
  final double? fee;
  final String? userId;
  final String? cardLast4;
  final String? cardBrand;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  AuditEvent({
    required this.type,
    this.txRef,
    this.flutterwaveId,
    this.amount,
    this.currency,
    this.fee,
    this.userId,
    this.cardLast4,
    this.cardBrand,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'event': type.name,
      'timestamp': timestamp.toIso8601String(),
    };
    if (txRef != null) map['txRef'] = txRef;
    if (flutterwaveId != null) map['flutterwaveId'] = flutterwaveId;
    if (amount != null) map['amount'] = amount;
    if (currency != null) map['currency'] = currency;
    if (fee != null) map['fee'] = fee;
    if (userId != null) map['userId'] = userId;
    if (cardLast4 != null) map['cardLast4'] = cardLast4;
    if (cardBrand != null) map['cardBrand'] = cardBrand;
    if (errorCode != null) map['errorCode'] = errorCode;
    if (errorMessage != null) map['errorMessage'] = errorMessage;
    if (metadata != null) map.addAll(metadata!);
    return map;
  }
}
