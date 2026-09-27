import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';

class ExchangeSuccessScreen extends StatelessWidget {
  final String fromCurrency;
  final String toCurrency;
  final double fromAmount;
  final double toAmount;
  final double rate;
  final DateTime? timestamp;
  
  // Transaction fee percentage (matches exchange screen)
  static const double _feePercentage = 3.0;

  const ExchangeSuccessScreen({
    super.key,
    required this.fromCurrency,
    required this.toCurrency,
    required this.fromAmount,
    required this.toAmount,
    required this.rate,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('MMM dd, yyyy • hh:mm a').format(timestamp ?? DateTime.now());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAnimation(context),
                const SizedBox(height: 40),
                Text(
                  'Exchange Confirmed & Successful',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.royalGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 24, // Matching hierarchy
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(height: 16),
                const Text(
                  'Your currency exchange has been processed successfully.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                _buildSummaryCard(timeStr),
                const SizedBox(height: 40),
                AppButton(
                  label: 'Done',
                  onPress: () => context.go('/dashboard'),
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.2, end: 0),
              ],
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
        ...List.generate(12, (index) {
          return Icon(
            Icons.currency_exchange_rounded,
            color: AppColors.royalGold.withValues(alpha: 0.3),
            size: 16 + (index % 4).toDouble() * 4,
          ).animate(onPlay: (controller) => controller.repeat())
            .move(
              begin: Offset.zero,
              end: Offset(
                (index % 2 == 0 ? 1 : -1) * 120 * (index / 12),
                (index % 3 == 0 ? 1 : -1) * 120 * (index / 12),
              ),
              duration: (1200 + index * 100).ms,
              curve: Curves.easeOutCubic,
            )
            .rotate(begin: 0, end: 1)
            .fadeOut();
        }),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.royalGold.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3), width: 2),
          ),
          child: const Center(
            child: Icon(Icons.swap_horiz_rounded, color: AppColors.royalGold, size: 64),
          ),
        ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
      ],
    );
  }

  Widget _buildSummaryCard(String timeStr) {
    final feeAmount = CurrencyFormatters.calculateFeeAmount(fromAmount, _feePercentage);
    
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryRow('You Exchanged', '${_getSymbol(fromCurrency)}${fromAmount.toStringAsFixed(2)} $fromCurrency', isBold: true),
          const SizedBox(height: 16),
          _buildSummaryRow('You Received', '${_getSymbol(toCurrency)}${toAmount.toStringAsFixed(2)} $toCurrency', color: AppColors.royalGold),
          const SizedBox(height: 16),
          _buildSummaryRow('Exchange Rate', '1 $fromCurrency = ${CurrencyFormatters.formatRate(rate)} $toCurrency'),
          const SizedBox(height: 16),
          _buildSummaryRow('Transaction Fee', '${CurrencyFormatters.formatFeeAsDecimal(_feePercentage)} (${_getSymbol(fromCurrency)}${feeAmount.toStringAsFixed(2)})'),
          const SizedBox(height: 16),
          _buildSummaryRow('Timestamp', timeStr),
          const SizedBox(height: 16),
          _buildSummaryRow('Status', 'Confirmed', color: AppColors.success),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
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

  String _getSymbol(String currency) {
    switch (currency) {
      case 'USD': return r'$';
      case 'GBP': return '£';
      case 'GHS': return '₵';
      default: return '';
    }
  }
}
