import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';

class BillPaymentScreen extends ConsumerStatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  ConsumerState<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends ConsumerState<BillPaymentScreen> {
  String? _selectedCategory;
  String? _selectedProvider;
  final _accountController = TextEditingController();
  final _amountController = TextEditingController();

  final Map<String, List<String>> _billCategories = {
    'Electricity': ['ECG', 'NEDCo'],
    'Water': ['Ghana Water Company', 'Aqua Vitens Rand'],
    'Internet/Cable': ['Vodafone', 'MTN', 'AirtelTigo', 'DStv', 'GOtv'],
    'Mobile Airtime': ['MTN', 'Vodafone', 'AirtelTigo'],
    'Mobile Data': ['MTN', 'Vodafone', 'AirtelTigo'],
  };

  @override
  void dispose() {
    _accountController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Pay Bills',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Bill Category',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCategoryGrid(),
                
                if (_selectedCategory != null) ...[
                  const SizedBox(height: 24),
                  _buildProviderSelection(),
                  const SizedBox(height: 24),
                  _buildPaymentForm(),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Continue to Payment',
                    onPress: _processPayment,
                    disabled: !(_selectedProvider != null &&
                            _accountController.text.isNotEmpty &&
                            _amountController.text.isNotEmpty),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: _billCategories.keys.map((category) {
        return _buildCategoryCard(category);
      }).toList(),
    );
  }

  Widget _buildCategoryCard(String category) {
    final isSelected = _selectedCategory == category;
    final icon = _getCategoryIcon(category);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = category;
          _selectedProvider = null;
        });
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.royalGold : AppColors.white,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              category,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.royalGold : AppColors.white,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderSelection() {
    final providers = _billCategories[_selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Provider',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: providers.map((provider) {
            final isSelected = _selectedProvider == provider;
            return GestureDetector(
              onTap: () => setState(() => _selectedProvider = provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.royalGold
                      : AppColors.royalGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.royalGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  provider,
                  style: TextStyle(
                    color: isSelected ? AppColors.darkBg : AppColors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Details',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Account/Meter Number
          TextField(
            controller: _accountController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: _getAccountLabel(),
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: _getAccountHint(),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.royalGold),
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.royalGold),
            ),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          // Amount
          TextField(
            controller: _amountController,
            style: const TextStyle(color: AppColors.white),
            decoration: InputDecoration(
              labelText: 'Amount',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter amount',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.borderGray),
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: AppColors.royalGold),
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.royalGold),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electricity':
        return Icons.flash_on_rounded;
      case 'Water':
        return Icons.water_drop_rounded;
      case 'Internet/Cable':
        return Icons.tv_rounded;
      case 'Mobile Airtime':
        return Icons.phone_android_rounded;
      case 'Mobile Data':
        return Icons.wifi_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  String _getAccountLabel() {
    switch (_selectedCategory) {
      case 'Electricity':
      case 'Water':
        return 'Meter Number';
      case 'Mobile Airtime':
      case 'Mobile Data':
        return 'Phone Number';
      default:
        return 'Account Number';
    }
  }

  String _getAccountHint() {
    switch (_selectedCategory) {
      case 'Electricity':
      case 'Water':
        return 'Enter your meter number';
      case 'Mobile Airtime':
      case 'Mobile Data':
        return '+233XXXXXXXXX';
      default:
        return 'Enter account number';
    }
  }

  void _processPayment() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.royalGold),
              const SizedBox(height: 24),
              const Text(
                'Processing Payment...',
                style: TextStyle(color: AppColors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Close loading dialog
      // ignore: use_build_context_synchronously
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: AppColors.successGreen),
              const SizedBox(width: 12),
              const Text('Payment Successful', style: TextStyle(color: AppColors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your $_selectedCategory bill payment has been processed successfully.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildSummaryRow('Provider', _selectedProvider ?? ''),
              _buildSummaryRow('Account', _accountController.text),
              _buildSummaryRow('Amount', CurrencyFormatters.formatAmount(double.parse(_amountController.text), 'GHS')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop();
              },
              child: const Text('Done', style: TextStyle(color: AppColors.royalGold)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
