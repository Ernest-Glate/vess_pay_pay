import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:dio/dio.dart';

/// Lightweight connectivity service that works on ALL platforms (web, iOS, Android).
/// Uses HTTP-based reachability check instead of dart:io which is unavailable on web.
class ConnectivityService {
  final Logger _logger = Logger(printer: SimplePrinter());

  bool _isOnline = true;
  Timer? _pollingTimer;

  final _controller = StreamController<bool>.broadcast();

  /// Stream of connectivity state changes (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool get isOnline => _isOnline;

  ConnectivityService() {
    // Start polling every 5 seconds
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkConnectivity());
    // Immediate first check
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final wasOnline = _isOnline;
    try {
      // Use a lightweight HTTP HEAD request instead of dart:io InternetAddress.lookup.
      // This works on web, iOS, and Android equally.
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
      ));
      final response = await dio.head('https://www.google.com/generate_204');
      _isOnline = response.statusCode != null && response.statusCode! < 400;
    } on DioException {
      _isOnline = false;
    } on TimeoutException {
      _isOnline = false;
    } catch (e) {
      _isOnline = false;
    }

    // Emit only on state changes
    if (wasOnline != _isOnline) {
      _logger.i('Connectivity changed: ${_isOnline ? "ONLINE" : "OFFLINE"}');
      _controller.add(_isOnline);
    }
  }

  /// Manual connectivity check — useful before critical operations
  Future<bool> checkNow() async {
    await _checkConnectivity();
    return _isOnline;
  }

  void dispose() {
    _pollingTimer?.cancel();
    _controller.close();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Exposes the current online/offline status as a stream
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});
