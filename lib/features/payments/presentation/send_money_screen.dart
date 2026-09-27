import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/fee_calculator.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  
  // Controllers
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _detectedNetwork = '';

  void _detectNetwork(String phone) {
    if (phone.isEmpty) {
      setState(() => _detectedNetwork = '');
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('24') || cleaned.startsWith('54') || cleaned.startsWith('55') || cleaned.startsWith('59')) {
      setState(() => _detectedNetwork = 'MTN');
    } else if (cleaned.startsWith('20') || cleaned.startsWith('50')) {
      setState(() => _detectedNetwork = 'Vodafone');
    } else if (cleaned.startsWith('27') || cleaned.startsWith('57') || cleaned.startsWith('26') || cleaned.startsWith('56')) {
      setState(() => _detectedNetwork = 'AirtelTigo');
    } else {
      setState(() => _detectedNetwork = '');
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep == 0) {
      // Step 1: Lookup Recipient
      if (_phoneController.text.length < 10) return;
      
      setState(() => _isLoading = true);
      // In a real app, we would perform lookup here
      // final user = await ref.read(transferRepositoryProvider).lookupRecipient(_phoneController.text);
      // if (user != null) _nameController.text = user.fullName;
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simulating lookup
      setState(() => _isLoading = false);
      
      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    
    } else if (_currentStep == 1) {
       _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      // Step 3: Review -> Navigate to Confirm Screen
      final amount = double.tryParse(_amountController.text) ?? 0;
      final feeResult = FeeCalculator.calculate(amount: amount, currency: 'GHS');
      context.push('/confirm-payment', extra: {
        'amount': _amountController.text,
        'recipient': _nameController.text.isNotEmpty ? _nameController.text : _phoneController.text,
        'phone': _phoneController.text,
        'note': _noteController.text,
        'network': _detectedNetwork,
        'fee': feeResult.fee.toStringAsFixed(2),
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: 400.ms, curve: Curves.easeInOutCubic);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStepper(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentStep = index),
                  children: [
                    _buildStep1(),
                    _buildStep2(),
                    _buildStep3(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
            padding: EdgeInsets.zero,
          ),
          Text(
            'SEND MONEY',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.white,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 48), // Spacer
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(0, Icons.person_rounded),
          _buildStepLine(0),
          _buildStepCircle(1, Icons.account_balance_wallet_rounded),
          _buildStepLine(1),
          _buildStepCircle(2, Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, IconData icon) {
    final isActive = _currentStep == index;
    final isCompleted = _currentStep > index;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isActive || isCompleted ? AppColors.royalGold : AppColors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        boxShadow: isActive ? [
          BoxShadow(color: AppColors.royalGold.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)
        ] : null,
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : icon,
        size: 20,
        color: isActive || isCompleted ? AppColors.black : AppColors.white.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildStepLine(int index) {
    final isCompleted = _currentStep > index;
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? AppColors.royalGold : AppColors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Who are you sending to?',
            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FormInput(
                  label: 'Phone Number',
                  hint: '024 XXX XXXX',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  onChanged: _detectNetwork,
                ),
                if (_detectedNetwork.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.network_cell, color: AppColors.royalGold, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Detected: $_detectedNetwork',
                          style: const TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().scale(),
                ],
                const SizedBox(height: 24),
                FormInput(
                  label: 'Recipient Name (Optional)',
                  hint: 'Enter full name',
                  controller: _nameController,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'How much?',
            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FormInput(
                  label: 'Amount (GHS)',
                  hint: '0.00',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.money_rounded),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Builder(builder: (_) {
                  final amount = double.tryParse(_amountController.text) ?? 0;
                  final feeResult = FeeCalculator.calculate(amount: amount, currency: 'GHS');
                  return Column(children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Transfer Fee (2%)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Text('GHS ${feeResult.fee.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Deducted', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        Text(
                          'GHS ${feeResult.total.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                  ]);
                }),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Review Transaction',
            style: TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildReviewRow(Icons.person_outline_rounded, 'Recipient', _nameController.text.isEmpty ? _phoneController.text : _nameController.text),
                const SizedBox(height: 24),
                _buildReviewRow(Icons.phone_iphone_rounded, 'Number', _phoneController.text),
                const SizedBox(height: 24),
                _buildReviewRow(Icons.account_balance_wallet_rounded, 'Amount', 'GHS ${_amountController.text}'),
                const SizedBox(height: 24),
                FormInput(
                  label: 'Add a note',
                  hint: 'Payment for lunch',
                  controller: _noteController,
                ),
              ],
            ),
          ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }

  Widget _buildReviewRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: AppButton(
        label: _currentStep == 2 ? 'Confirm & Send' : 'Continue',
        isLoading: _isLoading,
        onPress: _nextStep,
      ),
    );
  }
}
