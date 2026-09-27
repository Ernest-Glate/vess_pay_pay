import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/scheduled_payment_model.dart';

class ScheduledPaymentNotifier extends StateNotifier<List<ScheduledPaymentModel>> {
  ScheduledPaymentNotifier() : super([]) {
    _loadScheduledPayments();
  }

  void _loadScheduledPayments() {
    // Mock data for demonstration
    state = [
      ScheduledPaymentModel(
        id: 'sp_1',
        recipientName: 'Electricity Company',
        recipientAccount: 'ECG-001234',
        amount: 150.00,
        currency: 'GHS',
        frequency: 'monthly',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        nextPaymentDate: DateTime.now().add(const Duration(days: 5)),
        isActive: true,
        description: 'Monthly Electricity Bill',
        category: 'bills',
      ),
      ScheduledPaymentModel(
        id: 'sp_2',
        recipientName: 'Internet Provider',
        recipientAccount: 'ISP-789456',
        amount: 200.00,
        currency: 'GHS',
        frequency: 'monthly',
        startDate: DateTime.now().subtract(const Duration(days: 60)),
        nextPaymentDate: DateTime.now().add(const Duration(days: 12)),
        isActive: true,
        description: 'Monthly Internet Subscription',
        category: 'bills',
      ),
      ScheduledPaymentModel(
        id: 'sp_3',
        recipientName: 'Savings Account',
        recipientAccount: 'SAV-555111',
        amount: 500.00,
        currency: 'GHS',
        frequency: 'weekly',
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        nextPaymentDate: DateTime.now().add(const Duration(days: 2)),
        isActive: true,
        description: 'Weekly Savings Transfer',
        category: 'savings',
      ),
      ScheduledPaymentModel(
        id: 'sp_4',
        recipientName: 'Loan Repayment',
        recipientAccount: 'LOAN-333222',
        amount: 1000.00,
        currency: 'GHS',
        frequency: 'monthly',
        startDate: DateTime.now().subtract(const Duration(days: 180)),
        nextPaymentDate: DateTime.now().add(const Duration(days: 20)),
        isActive: false,
        description: 'Monthly Loan Payment',
        category: 'transfers',
      ),
    ];
  }

  void addScheduledPayment(ScheduledPaymentModel payment) {
    state = [...state, payment];
  }

  void updateScheduledPayment(ScheduledPaymentModel payment) {
    state = [
      for (final p in state)
        if (p.id == payment.id) payment else p
    ];
  }

  void deleteScheduledPayment(String id) {
    state = state.where((p) => p.id != id).toList();
  }

  void togglePaymentStatus(String id) {
    state = [
      for (final p in state)
        if (p.id == id) p.copyWith(isActive: !p.isActive) else p
    ];
  }

  List<ScheduledPaymentModel> getActivePayments() {
    return state.where((p) => p.isActive).toList();
  }

  List<ScheduledPaymentModel> getPaymentsByCategory(String category) {
    return state.where((p) => p.category == category).toList();
  }
}

final scheduledPaymentProvider = StateNotifierProvider<ScheduledPaymentNotifier, List<ScheduledPaymentModel>>((ref) {
  return ScheduledPaymentNotifier();
});
