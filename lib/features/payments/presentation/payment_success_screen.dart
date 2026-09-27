import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String? amount;
  final String? recipient;
  final String? transactionId;
  final String? type;

  const PaymentSuccessScreen({
    super.key,
    this.amount,
    this.recipient,
    this.transactionId,
    this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimation(context),
                      const SizedBox(height: 40),
                      Text(
                        'Payment Successful!',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.royalGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 16),
                      const Text(
                        'Your transaction has been processed and funds are on the way.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 48),
                      _buildReceiptCard(),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Share Receipt',
                              variant: AppButtonVariant.outline,
                              onPress: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              label: 'Download PDF',
                              variant: AppButtonVariant.outline,
                              onPress: () {},
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                      const Spacer(),
                      AppButton(
                        label: 'Back to Dashboard',
                        onPress: () => context.go('/dashboard'),
                      ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimation(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Confetti effect (Simulated with icons)
        ...List.generate(12, (index) {
          return Icon(
            Icons.star_rounded,
            color: AppColors.royalGold.withValues(alpha: 0.5),
            size: 16 + (index % 4).toDouble() * 4,
          ).animate(onPlay: (controller) => controller.repeat())
            .move(
              begin: Offset.zero,
              end: Offset(
                (index % 2 == 0 ? 1 : -1) * 100 * (index / 12),
                (index % 3 == 0 ? 1 : -1) * 100 * (index / 12),
              ),
              duration: (1000 + index * 100).ms,
              curve: Curves.easeOutCubic,
            )
            .fadeOut();
        }),
        // Main Check Circle
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.royalGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.check_rounded, color: AppColors.royalGold, size: 64),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildReceiptCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildReceiptRow('Amount Sent', amount ?? 'GHS 0.00', isBold: true),
          const SizedBox(height: 16),
          _buildReceiptRow('Recipient', recipient ?? 'N/A'),
          const SizedBox(height: 16),
          _buildReceiptRow('Transaction ID', transactionId ?? '#VP-XXXX-X'),
          const SizedBox(height: 16),
          _buildReceiptRow('Transaction Type', type ?? 'Transfer'),
          const SizedBox(height: 16),
          _buildReceiptRow('Status', 'Success', color: AppColors.success),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }
}
