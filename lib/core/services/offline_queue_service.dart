import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'connectivity_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  QUEUED TRANSACTION MODEL
// ══════════════════════════════════════════════════════════════════════════════

enum QueuedTransactionType {
  sendMoney,
  payMomo,
  exchangeCurrency,
  billPayment,
  requestMoney,
}

enum QueuedTransactionStatus {
  pending,
  processing,
  completed,
  failed,
}

class QueuedTransaction {
  final String id;
  final QueuedTransactionType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  QueuedTransactionStatus status;
  int retryCount;
  String? errorMessage;

  QueuedTransaction({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.status = QueuedTransactionStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
    'status': status.name,
    'retryCount': retryCount,
    'errorMessage': errorMessage,
  };

  factory QueuedTransaction.fromJson(Map<String, dynamic> json) {
    return QueuedTransaction(
      id: json['id'] as String,
      type: QueuedTransactionType.values.firstWhere((e) => e.name == json['type']),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: QueuedTransactionStatus.values.firstWhere((e) => e.name == json['status']),
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  OFFLINE QUEUE SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class OfflineQueueService extends StateNotifier<List<QueuedTransaction>> {
  static const String _storageKey = 'vesspay_offline_queue';
  static const int _maxRetries = 3;

  final Logger _logger = Logger(printer: SimplePrinter());
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _connectivitySub;
  bool _isProcessing = false;

  OfflineQueueService(this._connectivity) : super([]) {
    _loadFromDisk();
    _listenForConnectivity();
  }

  /// Number of pending transactions in the queue
  int get pendingCount => state.where((t) => t.status == QueuedTransactionStatus.pending).length;

  /// Whether the queue is currently being processed
  bool get isProcessing => _isProcessing;

  // ── ENQUEUE ──────────────────────────────────────────────────────────────

  /// Saves a transaction action locally for deferred execution.
  /// Returns the queued transaction ID for tracking.
  Future<String> enqueue({
    required QueuedTransactionType type,
    required Map<String, dynamic> payload,
  }) async {
    final id = 'q_${DateTime.now().millisecondsSinceEpoch}_${state.length}';
    final transaction = QueuedTransaction(
      id: id,
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
    );

    state = [...state, transaction];
    await _saveToDisk();

    _logger.i('Enqueued offline transaction: $id (${type.name})');

    // If we're online, try to process immediately
    if (_connectivity.isOnline) {
      processQueue();
    }

    return id;
  }

  // ── PROCESS QUEUE ────────────────────────────────────────────────────────

  /// Attempts to execute all pending transactions in FIFO order.
  /// Called automatically when connectivity resumes.
  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (!_connectivity.isOnline) return;

    final pending = state.where((t) => t.status == QueuedTransactionStatus.pending).toList();
    if (pending.isEmpty) return;

    _isProcessing = true;
    _logger.i('Processing offline queue: ${pending.length} pending transactions');

    for (final transaction in pending) {
      if (!_connectivity.isOnline) {
        _logger.w('Lost connectivity during queue processing — pausing');
        break;
      }

      try {
        transaction.status = QueuedTransactionStatus.processing;
        state = [...state];

        // Execute the transaction based on type
        await _executeTransaction(transaction);

        transaction.status = QueuedTransactionStatus.completed;
        _logger.i('Queue item ${transaction.id} completed successfully');
      } catch (e) {
        transaction.retryCount++;
        if (transaction.retryCount >= _maxRetries) {
          transaction.status = QueuedTransactionStatus.failed;
          transaction.errorMessage = e.toString();
          _logger.e('Queue item ${transaction.id} failed after $_maxRetries retries: $e');
        } else {
          transaction.status = QueuedTransactionStatus.pending;
          _logger.w('Queue item ${transaction.id} retry ${transaction.retryCount}/$_maxRetries');
        }
      }

      state = [...state];
      await _saveToDisk();
    }

    _isProcessing = false;
  }

  /// Execute a single queued transaction against the backend.
  /// In production, each type routes to the appropriate repository method.
  Future<void> _executeTransaction(QueuedTransaction transaction) async {
    // Simulate API call latency
    await Future.delayed(const Duration(milliseconds: 500));

    switch (transaction.type) {
      case QueuedTransactionType.sendMoney:
        // TODO: await ref.read(walletRepositoryProvider).sendMoney(transaction.payload);
        _logger.i('Executed queued sendMoney: ${transaction.payload}');
        break;
      case QueuedTransactionType.payMomo:
        // TODO: await ref.read(momoRepositoryProvider).pay(transaction.payload);
        _logger.i('Executed queued payMomo: ${transaction.payload}');
        break;
      case QueuedTransactionType.exchangeCurrency:
        // TODO: await ref.read(exchangeRepositoryProvider).execute(transaction.payload);
        _logger.i('Executed queued exchangeCurrency: ${transaction.payload}');
        break;
      case QueuedTransactionType.billPayment:
        // TODO: await ref.read(billPayRepositoryProvider).pay(transaction.payload);
        _logger.i('Executed queued billPayment: ${transaction.payload}');
        break;
      case QueuedTransactionType.requestMoney:
        // TODO: await ref.read(requestMoneyRepositoryProvider).request(transaction.payload);
        _logger.i('Executed queued requestMoney: ${transaction.payload}');
        break;
    }
  }

  // ── CLEAR / REMOVE ───────────────────────────────────────────────────────

  /// Remove completed or failed transactions from the queue
  Future<void> clearCompleted() async {
    state = state.where((t) =>
      t.status != QueuedTransactionStatus.completed &&
      t.status != QueuedTransactionStatus.failed
    ).toList();
    await _saveToDisk();
  }

  /// Remove a specific transaction by ID
  Future<void> remove(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _saveToDisk();
  }

  // ── PERSISTENCE ──────────────────────────────────────────────────────────

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      _logger.e('Failed to save offline queue to disk: $e');
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_storageKey);
      if (jsonList != null && jsonList.isNotEmpty) {
        state = jsonList
            .map((s) => QueuedTransaction.fromJson(jsonDecode(s) as Map<String, dynamic>))
            .toList();
        _logger.i('Loaded ${state.length} queued transactions from disk');
      }
    } catch (e) {
      _logger.e('Failed to load offline queue from disk: $e');
    }
  }

  // ── CONNECTIVITY LISTENER ────────────────────────────────────────────────

  void _listenForConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline && pendingCount > 0) {
        _logger.i('Connectivity restored — auto-processing ${pendingCount} pending transactions');
        processQueue();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final offlineQueueProvider = StateNotifierProvider<OfflineQueueService, List<QueuedTransaction>>((ref) {
  final connectivity = ref.watch(connectivityServiceProvider);
  return OfflineQueueService(connectivity);
});

/// Convenience provider for pending queue count — used for UI badges
final pendingQueueCountProvider = Provider<int>((ref) {
  final queue = ref.watch(offlineQueueProvider);
  return queue.where((t) => t.status == QueuedTransactionStatus.pending).length;
});
