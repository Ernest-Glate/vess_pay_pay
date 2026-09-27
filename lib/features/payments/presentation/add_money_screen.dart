import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/card_validator.dart';
import '../../../core/services/fee_calculator.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';
import '../../../shared/widgets/success_notification.dart';
import '../../../shared/models/card_transaction_model.dart';
import '../data/payment_method_provider.dart';
import '../data/card_deposit_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  CURRENCY & FUNDING CHANNEL MODELS
// ══════════════════════════════════════════════════════════════════════════════

enum FundingCurrency {
  usd('USD', '\$', [50, 100, 250, 500, 1000]),
  gbp('GBP', '£', [50, 100, 200, 500, 1000]),
  ghs('GHS', '₵', [50, 100, 250, 500, 1000]);

  final String code;
  final String symbol;
  final List<int> quickAmounts;
  const FundingCurrency(this.code, this.symbol, this.quickAmounts);
}

enum FundingChannel {
  internationalCard,
  virtualBankDeposit,
  localMobileMoney,
}

class AddMoneyScreen extends ConsumerStatefulWidget {
  const AddMoneyScreen({super.key});

  @override
  ConsumerState<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends ConsumerState<AddMoneyScreen> {
  final _amountController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedAmount = '';
  bool _isAddingNewCard = false;
  bool _isProcessing = false;

  // ── New: Currency + Funding Channel ──────────────────────────────────────
  FundingCurrency _selectedCurrency = FundingCurrency.usd;
  FundingChannel _selectedChannel = FundingChannel.internationalCard;

  // Validation state
  String? _cardNumberError;
  String? _expiryError;
  String? _cvvError;
  String? _amountError;
  CardBrand _detectedBrand = CardBrand.unknown;
  FeeBreakdown? _feePreview;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INPUT HANDLERS
  // ══════════════════════════════════════════════════════════════════════════

  void _onAmountChanged() {
    final amount = double.tryParse(_amountController.text);
    if (amount != null && amount > 0) {
      final breakdown = FeeCalculator.calculate(amount: amount, currency: _selectedCurrency.code);
      final validation = FeeCalculator.validateAmount(amount: amount, currency: _selectedCurrency.code);
      setState(() {
        _feePreview = breakdown;
        _amountError = validation.isValid ? null : validation.error;
      });
    } else {
      setState(() {
        _feePreview = null;
        _amountError = null;
      });
    }
  }

  void _onCurrencyChanged(FundingCurrency currency) {
    setState(() {
      _selectedCurrency = currency;
      _selectedAmount = '';
      // Auto-select funding channel based on currency
      if (currency == FundingCurrency.ghs) {
        _selectedChannel = FundingChannel.localMobileMoney;
      } else {
        _selectedChannel = FundingChannel.internationalCard;
      }
    });
    // Recalculate fees with new currency
    _onAmountChanged();
  }

  void _onCardNumberChanged(String value) {
    // Format card number
    final formatted = CardValidator.formatCardNumber(value);
    if (formatted != value) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // Detect brand
    final brand = CardValidator.detectBrand(value);
    setState(() => _detectedBrand = brand);

    if (_cardNumberError != null) {
      final result = CardValidator.validateCardNumber(value);
      setState(() => _cardNumberError = result.isValid ? null : result.error);
    }
  }

  void _onExpiryChanged(String value) {
    final formatted = CardValidator.formatExpiry(value);
    if (formatted != value) {
      _expiryController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  bool _validateAllFields() {
    bool valid = true;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Please enter a valid amount');
      valid = false;
    } else {
      final amountVal = FeeCalculator.validateAmount(amount: amount, currency: _selectedCurrency.code);
      if (!amountVal.isValid) {
        setState(() => _amountError = amountVal.error);
        valid = false;
      }
    }

    if (_selectedChannel == FundingChannel.internationalCard && _isAddingNewCard) {
      final cardResult = CardValidator.validateCardNumber(_cardNumberController.text);
      if (!cardResult.isValid) {
        setState(() => _cardNumberError = cardResult.error);
        valid = false;
      }

      final expiryResult = CardValidator.validateExpiry(_expiryController.text);
      if (!expiryResult.isValid) {
        setState(() => _expiryError = expiryResult.error);
        valid = false;
      }

      final cvvResult = CardValidator.validateCvv(_cvvController.text, brand: _detectedBrand);
      if (!cvvResult.isValid) {
        setState(() => _cvvError = cvvResult.error);
        valid = false;
      }

      if (_nameController.text.trim().isEmpty) {
        valid = false;
      }
    }

    return valid;
  }

  void _onQuickAmountSelected(int amount) {
    setState(() {
      _selectedAmount = amount.toString();
      _amountController.text = _selectedAmount;
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FUND WALLET
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _fundWallet() async {
    if (!_validateAllFields()) return;
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      if (_selectedChannel == FundingChannel.internationalCard && _isAddingNewCard) {
        // Add new card to provider
        final cleaned = _cardNumberController.text.replaceAll(' ', '');
        final last4 = cleaned.substring(cleaned.length - 4);
        final newCard = PaymentCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          last4: last4,
          brand: _detectedBrand.displayName.toUpperCase(),
          expiry: _expiryController.text,
          holderName: _nameController.text.toUpperCase(),
          color: _getBrandColor(_detectedBrand),
        );
        ref.read(paymentMethodProvider.notifier).addCard(newCard);
        ref.read(selectedPaymentCardProvider.notifier).state = newCard;
      }

      // Initiate Flutterwave deposit
      final depositNotifier = ref.read(cardDepositProvider.notifier);
      final transaction = await depositNotifier.initiateDeposit(
        context: context,
        amount: amount,
        currency: _selectedCurrency.code,
        userId: 'demo-user',
        email: 'demo@vesspay.com',
        phone: '+233551234567',
        name: _nameController.text.isNotEmpty ? _nameController.text : 'VessPay User',
      );

      if (!mounted) return;

      if (transaction.status == TransactionStatus.successful) {
        _showSuccessResult(transaction);
      } else if (transaction.status == TransactionStatus.cancelled) {
        setState(() => _isProcessing = false);
      } else {
        _showErrorResult(transaction);
      }
    } catch (e) {
      if (!mounted) return;
      _showGenericError(e.toString());
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RESULT DIALOGS
  // ══════════════════════════════════════════════════════════════════════════

  void _showSuccessResult(CardTransaction transaction) {
    SuccessNotification.show(
      context,
      message: 'Wallet Funded Successfully',
      amount: '${_selectedCurrency.symbol}${transaction.amount.toStringAsFixed(2)}',
      timestamp: DateFormat('MMM dd, yyyy • HH:mm').format(DateTime.now()),
    );

    Future.delayed(500.ms, () {
      if (!context.mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    });
  }

  void _showErrorResult(CardTransaction transaction) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 12),
            Text('Payment Failed', style: TextStyle(color: AppColors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          transaction.errorMessage ?? 'An unknown error occurred.',
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showGenericError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getBrandColor(CardBrand brand) {
    switch (brand) {
      case CardBrand.visa: return '0xFF1A1F71';
      case CardBrand.mastercard: return '0xFFEB001B';
      case CardBrand.amex: return '0xFF006FCF';
      case CardBrand.discover: return '0xFFFF6600';
      case CardBrand.verve: return '0xFF00425F';
      case CardBrand.unknown: return '0xFFD4AF37';
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DYNAMIC CTA LABEL
  // ══════════════════════════════════════════════════════════════════════════

  String get _ctaLabel {
    if (_isProcessing) return 'Processing...';

    if (_selectedCurrency != FundingCurrency.ghs) {
      return 'Fund Stable ${_selectedCurrency.code} Wallet';
    }

    if (_selectedChannel == FundingChannel.localMobileMoney) {
      return 'Fund via Mobile Money';
    }

    return _isAddingNewCard ? 'Add & Fund Wallet' : 'Fund Wallet Now';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ADD FUNDS',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
        ),
      ),
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
                // ── Currency Type Selector ──────────────────────
                _buildCurrencySelector(),
                const SizedBox(height: 24),

                // ── Card Carousel ──────────────────────────────
                if (_selectedChannel == FundingChannel.internationalCard) ...[
                  _buildCardCarousel(),
                  const SizedBox(height: 28),
                ],

                // ── Amount Input ───────────────────────────────
                _buildAmountSection(),
                const SizedBox(height: 16),

                // ── Quick Amounts ──────────────────────────────
                _buildQuickAmounts(),
                const SizedBox(height: 24),

                // ── Multi-Channel Funding Row ──────────────────
                _buildFundingChannelRow(),
                const SizedBox(height: 24),

                // ── Channel-Specific Content ───────────────────
                _buildChannelContent(),
                const SizedBox(height: 24),

                // ── Fee Preview ────────────────────────────────
                if (_feePreview != null) ...[
                  _buildFeePreview(),
                  const SizedBox(height: 24),
                ],

                // ── Fund Button (Dynamic CTA) ──────────────────
                _buildFundButton(),
                const SizedBox(height: 24),

                // ── Security Badge ─────────────────────────────
                _buildSecurityBadge(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CURRENCY TYPE SELECTOR
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCurrencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNDING CURRENCY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: FundingCurrency.values.map((currency) {
              final isSelected = _selectedCurrency == currency;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _onCurrencyChanged(currency),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.royalGold.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.royalGold.withValues(alpha: 0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          currency.symbol,
                          style: TextStyle(
                            color: isSelected ? AppColors.royalGold : AppColors.textSecondary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currency.code,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MULTI-CHANNEL FUNDING ROW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFundingChannelRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FUNDING METHOD',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildChannelOption(
              icon: Icons.credit_card_rounded,
              label: 'International\nCard',
              channel: FundingChannel.internationalCard,
            ),
            const SizedBox(width: 10),
            _buildChannelOption(
              icon: Icons.account_balance_rounded,
              label: 'International\nBank',
              channel: FundingChannel.virtualBankDeposit,
            ),
            const SizedBox(width: 10),
            _buildChannelOption(
              icon: Icons.phone_android_rounded,
              label: 'Local Mobile\nMoney',
              channel: FundingChannel.localMobileMoney,
            ),
          ],
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildChannelOption({
    required IconData icon,
    required String label,
    required FundingChannel channel,
  }) {
    final isSelected = _selectedChannel == channel;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChannel = channel),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.royalGold.withValues(alpha: 0.1)
                : AppColors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.royalGold.withValues(alpha: 0.4)
                  : AppColors.white.withValues(alpha: 0.06),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.royalGold : AppColors.textSecondary.withValues(alpha: 0.5),
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CHANNEL-SPECIFIC CONTENT
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildChannelContent() {
    switch (_selectedChannel) {
      case FundingChannel.internationalCard:
        return _isAddingNewCard ? _buildCardForm() : const SizedBox.shrink();

      case FundingChannel.virtualBankDeposit:
        return _buildVirtualBankDetails();

      case FundingChannel.localMobileMoney:
        return _buildMobileMoneySection();
    }
  }

  /// Virtual bank deposit routing details.
  Widget _buildVirtualBankDetails() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flight_takeoff_rounded, color: AppColors.royalGold, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'International Bank Transfer',
                      style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'For international travelers: Wire funds globally',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRoutingRow('Bank Name', 'VessPay Digital Bank'),
          _buildRoutingRow('Account Name', 'VessPay Wallet Ltd'),
          _buildRoutingRow('Account Number', '0012345678'),
          _buildRoutingRow('Routing / SWIFT', 'VSSPGHAC'),
          _buildRoutingRow('Currency', _selectedCurrency.code),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Include your VessPay email as the reference to auto-credit your wallet.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildRoutingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 12)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label copied'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                },
                child: Icon(Icons.copy_rounded, color: AppColors.royalGold.withValues(alpha: 0.5), size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile Money funding section.
  Widget _buildMobileMoneySection() {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_android_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mobile Money Top-Up',
                      style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'MTN, Vodafone, AirtelTigo',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          FormInput(
            label: 'Mobile Money Number',
            hint: '024 XXX XXXX',
            keyboardType: TextInputType.phone,
            prefixIcon: const Icon(Icons.phone_outlined),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(Icons.flash_on_rounded, color: AppColors.success.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You\'ll receive an approval prompt on your phone. Confirm to fund instantly.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CARD CAROUSEL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 200,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add New Card
          GestureDetector(
            onTap: () => setState(() => _isAddingNewCard = !_isAddingNewCard),
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isAddingNewCard ? AppColors.royalGold : AppColors.white.withValues(alpha: 0.1),
                  width: 2,
                ),
                color: _isAddingNewCard
                    ? AppColors.royalGold.withValues(alpha: 0.05)
                    : AppColors.white.withValues(alpha: 0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isAddingNewCard ? Icons.close_rounded : Icons.add_rounded,
                    color: _isAddingNewCard ? AppColors.white : AppColors.royalGold,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isAddingNewCard ? 'CANCEL' : 'ADD NEW CARD',
                    style: TextStyle(
                      color: _isAddingNewCard ? AppColors.white : AppColors.royalGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Saved Cards
          ...ref.watch(paymentMethodProvider).map((card) {
            final isSelected = ref.watch(selectedPaymentCardProvider)?.id == card.id && !_isAddingNewCard;
            return GestureDetector(
              onTap: () {
                setState(() => _isAddingNewCard = false);
                ref.read(selectedPaymentCardProvider.notifier).state = card;
              },
              child: Container(
                width: 320,
                margin: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    _buildCardPreview(
                      number: '**** **** **** ${card.last4}',
                      name: card.holderName,
                      expiry: card.expiry,
                      brand: card.brand,
                      accentColor: Color(int.parse(card.color)),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.royalGold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded, color: AppColors.black, size: 16),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  AMOUNT SECTION (Dynamic symbol based on currency)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAmountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT AMOUNT (${_selectedCurrency.code})',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              _selectedCurrency.symbol,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.royalGold),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _amountController,
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.white),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                decoration: InputDecoration(
                  hintText: '0.00',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  errorText: _amountError,
                  errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  QUICK AMOUNTS (Dynamic chips based on currency)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildQuickAmounts() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _selectedCurrency.quickAmounts.map((amount) {
        final isSelected = _selectedAmount == amount.toString();
        return GestureDetector(
          onTap: () => _onQuickAmountSelected(amount),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.royalGold.withValues(alpha: 0.2) : AppColors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.royalGold : AppColors.white.withValues(alpha: 0.1),
              ),
            ),
            child: Text(
              '+${_selectedCurrency.symbol}$amount',
              style: TextStyle(
                color: isSelected ? AppColors.royalGold : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FEE PREVIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFeePreview() {
    return GlassContainer(
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFeeRow('Amount', _feePreview!.amountDisplay),
          const SizedBox(height: 8),
          _buildFeeRow('Fee (${_feePreview!.percentageRate}%)', _feePreview!.feeDisplay),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white12),
          ),
          _buildFeeRow('Total', _feePreview!.totalDisplay, isBold: true),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildFeeRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isBold ? AppColors.white : AppColors.textSecondary,
          fontSize: 13,
        )),
        Text(value, style: TextStyle(
          color: isBold ? AppColors.royalGold : AppColors.white,
          fontSize: isBold ? 16 : 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        )),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CARD FORM
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCardForm() {
    return GlassContainer(
      borderRadius: 24,
      child: Column(
        children: [
          // Card Number with brand icon
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormInput(
                label: 'Card Number',
                hint: '0000 0000 0000 0000',
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(
                  _detectedBrand == CardBrand.unknown
                      ? Icons.credit_card
                      : Icons.credit_card_rounded,
                  color: _detectedBrand == CardBrand.unknown
                      ? AppColors.textSecondary
                      : AppColors.royalGold,
                ),
                onChanged: _onCardNumberChanged,
              ),
              if (_cardNumberError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(_cardNumberError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                ),
              if (_detectedBrand != CardBrand.unknown && _cardNumberError == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    _detectedBrand.displayName,
                    style: const TextStyle(color: AppColors.royalGold, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Expiry + CVV
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormInput(
                      label: 'Expiry',
                      hint: 'MM/YY',
                      controller: _expiryController,
                      keyboardType: TextInputType.number,
                      onChanged: _onExpiryChanged,
                    ),
                    if (_expiryError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(_expiryError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormInput(
                      label: _detectedBrand == CardBrand.amex ? 'CID' : 'CVV',
                      hint: _detectedBrand == CardBrand.amex ? '1234' : '123',
                      controller: _cvvController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                    ),
                    if (_cvvError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 12),
                        child: Text(_cvvError!, style: const TextStyle(color: AppColors.danger, fontSize: 11)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cardholder Name
          FormInput(
            label: 'Cardholder Name',
            hint: 'AS SHOWN ON CARD',
            controller: _nameController,
            prefixIcon: const Icon(Icons.person_outline),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  FUND BUTTON (Dynamic CTA)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildFundButton() {
    return AppButton(
      label: _ctaLabel,
      isLoading: _isProcessing,
      disabled: _isProcessing,
      onPress: _fundWallet,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECURITY BADGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSecurityBadge() {
    return const Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, color: AppColors.royalGold, size: 16),
          SizedBox(width: 8),
          Text(
            'PCI-DSS COMPLIANT • 256-BIT ENCRYPTION',
            style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CARD PREVIEW
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCardPreview({
    required String number,
    required String name,
    required String expiry,
    String brand = 'VISA',
    Color accentColor = AppColors.royalGold,
  }) {
    return GlassContainer(
      height: 200,
      borderRadius: 20,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          accentColor.withValues(alpha: 0.2),
          accentColor.withValues(alpha: 0.05),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PREMIUM ACCESS',
                style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
              Icon(brand == 'VISA' ? Icons.credit_card : Icons.payment_rounded, color: accentColor, size: 32),
            ],
          ),
          Text(
            number.isEmpty ? 'XXXX XXXX XXXX XXXX' : number,
            style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CARD HOLDER', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text(name.isEmpty ? 'YOUR NAME' : name.toUpperCase(), style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EXPIRES', style: TextStyle(color: Colors.white24, fontSize: 10)),
                  Text(expiry.isEmpty ? 'MM/YY' : expiry, style: const TextStyle(color: AppColors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
