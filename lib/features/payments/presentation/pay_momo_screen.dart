import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/momo_lookup_service.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

class PayMoMoScreen extends ConsumerStatefulWidget {
  const PayMoMoScreen({super.key});

  @override
  ConsumerState<PayMoMoScreen> createState() => _PayMoMoScreenState();
}

class _PayMoMoScreenState extends ConsumerState<PayMoMoScreen> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _detectedNetwork = '';
  String _selectedWallet = 'GHS'; // 'GHS' or 'USD'

  final List<Map<String, String>> _recentContacts = [
    {'id': '1', 'name': 'Kofi', 'phone': '0241234567', 'initials': 'K', 'color': '0xFFD4AF37'},
    {'id': '2', 'name': 'Ama', 'phone': '0559876543', 'initials': 'A', 'color': '0xFFC0C0C0'},
    {'id': '3', 'name': 'Kwame', 'phone': '0201112223', 'initials': 'K', 'color': '0xFFCD7F32'},
    {'id': '4', 'name': 'Abena', 'phone': '0543334445', 'initials': 'A', 'color': '0xFFD4AF37'},
  ];

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() {
    _detectNetwork(_phoneController.text);
    ref.read(momoLookupProvider.notifier).onPhoneChanged(_phoneController.text);
  }

  void _detectNetwork(String phone) {
    if (phone.isEmpty) {
      setState(() => _detectedNetwork = '');
      return;
    }
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    String prefix = cleaned.length >= 3 ? cleaned.substring(0, 3) : '';
    if (['024', '054', '055', '059'].contains(prefix)) {
      setState(() => _detectedNetwork = 'MTN');
    } else if (['020', '050'].contains(prefix)) {
      setState(() => _detectedNetwork = 'Vodafone');
    } else if (['027', '057', '026', '056'].contains(prefix)) {
      setState(() => _detectedNetwork = 'AirtelTigo');
    } else {
      setState(() => _detectedNetwork = '');
    }
  }

  void _selectContact(Map<String, String> contact) {
    _phoneController.text = contact['phone']!;
    // Listener will trigger network detection + lookup automatically
  }

  @override
  Widget build(BuildContext context) {
    final lookupState = ref.watch(momoLookupProvider);
    final isLookupSuccess = lookupState is MoMoLookupSuccess;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SEND MOMO',
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
                const SizedBox(height: 10),
                Text(
                  'RECENT RECIPIENTS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Recent Contacts Scroll
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _recentContacts[index];
                      return GestureDetector(
                        onTap: () => _selectContact(contact),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Column(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(int.parse(contact['color']!)).withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  color: AppColors.white.withValues(alpha: 0.05),
                                ),
                                child: Center(
                                  child: Text(
                                    contact['initials']!,
                                    style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                contact['name']!,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                
                const SizedBox(height: 32),
                
                // Transfer Form
                GlassContainer(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      // ── Phone Number Input ──
                      FormInput(
                        label: 'Recipient Number',
                        hint: '024XXXXXXX',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                        suffixIcon: _buildPhoneSuffix(lookupState),
                      ),

                      // ── Network Detection Chip ──
                      if (_detectedNetwork.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.royalGold.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.royalGold.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cell_tower_rounded, color: AppColors.royalGold, size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _detectedNetwork,
                                  style: const TextStyle(
                                    color: AppColors.royalGold,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 200.ms).scale(
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1, 1),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ── Smart Recipient Result Banner ──
                      _buildLookupBanner(lookupState),

                      const SizedBox(height: 20),
                      Text(
                        'AMOUNT (GHS)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('₵', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.royalGold)),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 150,
                            child: TextField(
                              controller: _amountController,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.white),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      FormInput(
                        label: 'Note',
                        hint: 'What is this for?',
                        controller: _noteController,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 32),

                // ── Funding Source Selector ──
                Text(
                  'PAY FROM',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildWalletOption(
                      label: 'GHS Wallet',
                      balance: '₵12,450.00',
                      icon: Icons.account_balance_wallet_rounded,
                      currency: 'GHS',
                    ),
                    const SizedBox(width: 12),
                    _buildWalletOption(
                      label: 'USD Holding',
                      balance: '\$2,380.50',
                      icon: Icons.currency_exchange_rounded,
                      currency: 'USD',
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 32),
                
                AppButton(
                  label: _selectedWallet == 'USD'
                      ? 'Convert & Transfer Instantly'
                      : 'Secure Transfer',
                  icon: _selectedWallet == 'USD'
                      ? Icons.currency_exchange_rounded
                      : null,
                  disabled: !isLookupSuccess,
                  onPress: () {
                    final amount = _amountController.text;
                    final resolvedName = lookupState is MoMoLookupSuccess
                        ? lookupState.result.accountName
                        : _phoneController.text;
                    
                    if (amount.isEmpty || _phoneController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill in all details')),
                      );
                      return;
                    }

                    context.push('/payment-success', extra: {
                      'amount': 'GHS $amount',
                      'recipient': resolvedName,
                      'transactionId': '#VP-${(1000 + (DateTime.now().millisecond * 9)).toString()}-X',
                      'type': 'MoMo Transfer',
                    });
                  },
                ),
                
                const SizedBox(height: 24),
                
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, color: Colors.white24, size: 14),
                      SizedBox(width: 8),
                      Text(
                        'PRIVATE & ENCRYPTED TRANSFER',
                        style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Phone Input Suffix Icon ─────────────────────────────────────────────

  Widget _buildPhoneSuffix(MoMoLookupState state) {
    return switch (state) {
      MoMoLookupLoading() => const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.royalGold),
            ),
          ),
        ),
      MoMoLookupSuccess() => const Icon(Icons.check_circle_rounded, color: AppColors.success),
      MoMoLookupError() => const Icon(Icons.error_outline_rounded, color: AppColors.error),
      _ => ValueListenableBuilder(
          valueListenable: _phoneController,
          builder: (context, value, child) {
            if (_phoneController.text.length >= 10) {
              return const Icon(Icons.check_circle_rounded, color: AppColors.success);
            }
            return const SizedBox.shrink();
          },
        ),
    };
  }

  // ── Lookup Result Banner ────────────────────────────────────────────────

  Widget _buildLookupBanner(MoMoLookupState state) {
    return switch (state) {
      MoMoLookupIdle() => const SizedBox.shrink(),
      MoMoLookupLoading() => _buildLoadingBanner(),
      MoMoLookupSuccess(result: final r) => _buildSuccessBanner(r),
      MoMoLookupError(message: final msg) => _buildErrorBanner(msg),
    };
  }

  Widget _buildLoadingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.royalGold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.royalGold.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer placeholder for name
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .shimmer(
                      duration: 1200.ms,
                      color: AppColors.royalGold.withValues(alpha: 0.15),
                    ),
                const SizedBox(height: 6),
                Text(
                  'VERIFYING RECIPIENT…',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildSuccessBanner(MoMoRecipientResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.success,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.accountName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  result.network.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.success.withValues(alpha: 0.8),
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error.withValues(alpha: 0.15),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VERIFICATION FAILED',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(momoLookupProvider.notifier).retry(_phoneController.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'RETRY',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shakeX(amount: 2, hz: 3, duration: 400.ms);
  }

  // ── Wallet Source Option Card ────────────────────────────────────────────

  Widget _buildWalletOption({
    required String label,
    required String balance,
    required IconData icon,
    required String currency,
  }) {
    final isActive = _selectedWallet == currency;
    final borderColor = isActive
        ? (currency == 'USD' ? AppColors.info : AppColors.royalGold)
        : AppColors.white.withValues(alpha: 0.08);
    final accentColor = currency == 'USD' ? AppColors.info : AppColors.royalGold;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedWallet = currency),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? accentColor.withValues(alpha: 0.1)
                : AppColors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: isActive ? accentColor : AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: isActive ? AppColors.white : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle_rounded, color: accentColor, size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                balance,
                style: TextStyle(
                  color: isActive ? accentColor : AppColors.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
