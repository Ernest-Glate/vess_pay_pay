import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

class RequestMoneyScreen extends StatefulWidget {
  const RequestMoneyScreen({super.key});

  @override
  State<RequestMoneyScreen> createState() => _RequestMoneyScreenState();
}

class _RequestMoneyScreenState extends State<RequestMoneyScreen> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _showQR = false;

  void _generateRequest() {
    if (_amountController.text.isEmpty) return;
    setState(() => _showQR = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 32),
                if (!_showQR) _buildRequestForm() else _buildQRResult(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        const SizedBox(height: 20),
        Text(
          'REQUEST MONEY',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppColors.royalGold,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ).animate().fadeIn().slideX(begin: -0.2, end: 0),
        const SizedBox(height: 8),
        const Text(
          'Send a payment request or generate a QR code',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildRequestForm() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              FormInput(
                label: 'Recipient Phone',
                hint: '024 XXX XXXX',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              FormInput(
                label: 'Amount (GHS)',
                hint: '0.00',
                controller: _amountController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.money_rounded),
              ),
              const SizedBox(height: 24),
              FormInput(
                label: 'Note (Optional)',
                hint: 'Payment for dinner',
                controller: _noteController,
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),
        AppButton(
          label: 'Generate Payment Link',
          onPress: _generateRequest,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {},
          child: const Text(
            'Share Request Link directly',
            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildQRResult() {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Text(
                'SCAN TO PAY',
                style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              const SizedBox(height: 8),
              Text(
                'GHS ${_amountController.text}',
                style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 200, color: Colors.black), // Placeholder for real QR
              ).animate().scale(delay: 200.ms),
              const SizedBox(height: 24),
              Text(
                'Request sent to ${_phoneController.text}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 32),
        AppButton(
          label: 'Close',
          onPress: () => setState(() => _showQR = false),
          variant: AppButtonVariant.outline,
        ),
        const SizedBox(height: 16),
        AppButton(
          label: 'Share QR Code',
          onPress: () {},
        ),
      ],
    );
  }
}
