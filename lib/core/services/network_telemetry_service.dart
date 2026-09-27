import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum OperatorHealthStatus {
  operational,
  degraded,
  delayed,
  down,
}

class MoMoOperatorStatus {
  final String name;
  final String country;
  final String flag;
  final OperatorHealthStatus status;
  final int latencyMs;
  final DateTime lastChecked;
  final String? statusMessage;

  const MoMoOperatorStatus({
    required this.name,
    required this.country,
    required this.flag,
    required this.status,
    required this.latencyMs,
    required this.lastChecked,
    this.statusMessage,
  });

  String get displayLabel => '$name: ${statusText}';

  String get statusText {
    switch (status) {
      case OperatorHealthStatus.operational:
        return 'Operational';
      case OperatorHealthStatus.degraded:
        return 'Degraded Performance';
      case OperatorHealthStatus.delayed:
        return 'Delayed Operations';
      case OperatorHealthStatus.down:
        return 'Service Disruption';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  NETWORK TELEMETRY SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class NetworkTelemetryService extends StateNotifier<List<MoMoOperatorStatus>> {
  final Logger _logger = Logger(printer: SimplePrinter());
  Timer? _pollingTimer;

  NetworkTelemetryService() : super([]) {
    _fetchOperatorHealth();
    // Poll every 60 seconds for updated status
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => _fetchOperatorHealth(),
    );
  }

  /// Fetch current health status of all monitored MoMo operators.
  /// In production, this calls the /api/v1/telemetry/momo-health endpoint.
  Future<void> _fetchOperatorHealth() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      final now = DateTime.now();

      // Simulated operator statuses — in production, pulled from
      // real-time monitoring of each telco's API response times
      state = [
        MoMoOperatorStatus(
          name: 'MTN Ghana MoMo',
          country: 'Ghana',
          flag: '🇬🇭',
          status: OperatorHealthStatus.operational,
          latencyMs: 120,
          lastChecked: now,
        ),
        MoMoOperatorStatus(
          name: 'Telecel Ghana MoMo',
          country: 'Ghana',
          flag: '🇬🇭',
          status: OperatorHealthStatus.delayed,
          latencyMs: 2400,
          lastChecked: now,
          statusMessage: 'Intermittent delays on cashout API',
        ),
        MoMoOperatorStatus(
          name: 'AirtelTigo Money',
          country: 'Ghana',
          flag: '🇬🇭',
          status: OperatorHealthStatus.operational,
          latencyMs: 180,
          lastChecked: now,
        ),
        MoMoOperatorStatus(
          name: 'M-Pesa Kenya',
          country: 'Kenya',
          flag: '🇰🇪',
          status: OperatorHealthStatus.operational,
          latencyMs: 95,
          lastChecked: now,
        ),
        MoMoOperatorStatus(
          name: 'MTN Uganda',
          country: 'Uganda',
          flag: '🇺🇬',
          status: OperatorHealthStatus.operational,
          latencyMs: 210,
          lastChecked: now,
        ),
        MoMoOperatorStatus(
          name: 'Orange Money CI',
          country: 'Côte d\'Ivoire',
          flag: '🇨🇮',
          status: OperatorHealthStatus.degraded,
          latencyMs: 1800,
          lastChecked: now,
          statusMessage: 'Elevated latency on deposit endpoints',
        ),
      ];

      _logger.i('Telemetry: fetched ${state.length} operator statuses');
    } catch (e) {
      _logger.e('Failed to fetch operator health: $e');
    }
  }

  /// Force refresh operator health
  Future<void> refresh() async => _fetchOperatorHealth();

  /// Get operators with issues (non-operational)
  List<MoMoOperatorStatus> get operatorsWithIssues =>
      state.where((op) => op.status != OperatorHealthStatus.operational).toList();

  /// Check if all operators are healthy
  bool get allOperational =>
      state.isNotEmpty && state.every((op) => op.status == OperatorHealthStatus.operational);

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final networkTelemetryProvider = StateNotifierProvider<NetworkTelemetryService, List<MoMoOperatorStatus>>((ref) {
  return NetworkTelemetryService();
});

/// Convenience: count of operators with issues
final operatorIssueCountProvider = Provider<int>((ref) {
  final statuses = ref.watch(networkTelemetryProvider);
  return statuses.where((op) => op.status != OperatorHealthStatus.operational).length;
});
