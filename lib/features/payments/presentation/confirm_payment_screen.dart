import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/fee_calculator.dart';
import '../../../core/repositories/transfer_repository.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_container.dart';

class ConfirmPaymentScreen extends ConsumerStatefulWidget {
  final String amount;
  final String recipient;
  final String? phone;
  final String? note;
  final String? network;
  final String? fee;

  const ConfirmPaymentScreen({
    super.key,
    this.amount = '0.00',
    this.recipient = 'Unknown',
    this.phone,
    this.note,
    this.network,
    this.fee,
  });

  @override
  ConsumerState<ConfirmPaymentScreen> createState() => _ConfirmPaymentScreenState();
}

class _ConfirmPaymentScreenState extends ConsumerState<ConfirmPaymentScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _confirmAndSend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final amount = double.tryParse(widget.amount) ?? 0;
      final idempotencyKey = 'momo-${DateTime.now().millisecondsSinceEpoch}';

      final transaction = await ref.read(paymentRepositoryProvider).sendMoMo(
        recipientNumber: widget.phone ?? '',
        amount: amount,
        description: widget.note,
        idempotencyKey: idempotencyKey,
      );

      if (mounted) {
        context.pushReplacement('/payment-success', extra: {
          'amount': widget.amount,
          'recipient': widget.recipient,
          'transactionId': transaction.id,
          'type': 'outgoing',
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountVal = double.tryParse(widget.amount) ?? 0.0;
    final feeResult = FeeCalculator.calculate(amount: amountVal, currency: 'GHS');
    final total = feeResult.total.toStringAsFixed(2);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.verticalGradient,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  IconButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                    padding: EdgeInsets.zero,
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  Text(
                    'Confirm Payment',
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(duration: 600.ms),
                  
                  const SizedBox(height: 40),
                  
                  GlassContainer(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text(
                          'You\'re sending',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'GHS ${widget.amount}',
                          style: const TextStyle(
                            color: AppColors.royalGold,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 24),
                        _buildInfoRow('To', widget.recipient),
                        if (widget.phone != null && widget.phone!.isNotEmpty)
                          _buildInfoRow('Phone', widget.phone!),
                        if (widget.network != null && widget.network!.isNotEmpty)
                          _buildInfoRow('Network', widget.network!),
                        _buildInfoRow('Fee (2%)', 'GHS ${feeResult.fee.toStringAsFixed(2)}'),
                        if (widget.note != null && widget.note!.isNotEmpty)
                          _buildInfoRow('Note', widget.note!),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white12),
                        const SizedBox(height: 16),
                        _buildInfoRow('Total Deducted', 'GHS $total', isBold: true),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Spacer(),
                  
                  AppButton(
                    label: 'Confirm & Send Money',
                    isLoading: _isLoading,
                    onPress: _confirmAndSend,
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  
                  const SizedBox(height: 16),
                  
                  Center(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => context.pop(),
                      child: const Text(
                        'Cancel Payment',
                        style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isBold ? AppColors.white : AppColors.textSecondary,
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
