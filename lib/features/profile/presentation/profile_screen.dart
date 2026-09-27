import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/network_telemetry_banner.dart';
import '../../auth/data/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // ── Linked Mobile Money Accounts ────────────────────────────────────────
  final List<_LinkedMoMoAccount> _linkedAccounts = [
    _LinkedMoMoAccount(network: 'MTN Ghana', number: '+233 24 XXX XXXX', flag: '🇬🇭', verified: true),
    _LinkedMoMoAccount(network: 'M-Pesa Kenya', number: '+254 7XX XXX XXX', flag: '🇰🇪', verified: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile',
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
              children: [
                // ── Profile Header ─────────────────────────────
                _buildProfileHeader(context),

                const SizedBox(height: 16),

                // ── Ecobank Compliance Badge ────────────────────
                _buildComplianceBadge(context),

                const SizedBox(height: 28),

                // ── Account Settings ───────────────────────────
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.person_outline, 'Personal Information', onTap: () => context.push('/account-settings')),
                      _buildDivider(),
                      _buildProfileItem(Icons.account_balance_rounded, 'Bank Accounts & Cards', onTap: () => context.push('/bank-accounts')),
                      _buildDivider(),
                      _buildProfileItem(Icons.history_rounded, 'Transaction History', onTap: () => context.push('/transaction-history')),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // ── Direct Deposit Control Hub ─────────────────
                _buildSectionTitle(context, 'DIRECT DEPOSIT'),
                const SizedBox(height: 12),
                _buildDirectDepositHub(context),

                const SizedBox(height: 24),

                // ── Linked Mobile Money Accounts ───────────────
                _buildSectionTitle(context, 'LINKED MOBILE MONEY ACCOUNTS'),
                const SizedBox(height: 12),
                _buildLinkedMoMoSection(context),

                const SizedBox(height: 24),

                // ── Security ───────────────────────────────────
                _buildSectionTitle(context, 'SECURITY'),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.fingerprint_rounded, 'Security Center', onTap: () => context.push('/security')),
                      _buildDivider(),
                      _buildProfileItem(Icons.lock_reset_rounded, 'Change Transaction PIN', onTap: () => context.push('/change-pin')),
                      _buildDivider(),
                      _buildProfileItem(
                        Icons.security_rounded,
                        'Two-Factor Authentication (2FA)',
                        trailing: const Text('Enabled', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // ── Network Status ─────────────────────────────
                _buildSectionTitle(context, 'NETWORK STATUS'),
                const SizedBox(height: 12),
                const NetworkTelemetryBanner(),

                const SizedBox(height: 48),

                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.outline,
                  onPress: () => _showLogoutConfirmation(context, ref),
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 24),
                const Text('App Version 2.0.0 (Flutter)', style: TextStyle(color: Colors.white12, fontSize: 10)),
                const SizedBox(height: 100), // Bottom padding for tab bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROFILE HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3), width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.forestDepths,
                child: Icon(Icons.person_outline_rounded, size: 50, color: AppColors.royalGold),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.royalGold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_rounded, color: AppColors.black, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Alexander Vesspay',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ECOBANK COMPLIANCE BADGE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildComplianceBadge(BuildContext context) {
    return GestureDetector(
      onTap: () => _showTransferThresholds(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.royalGold.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ecobank Sponsored Tier 3 · Fully Compliant',
                  style: TextStyle(
                    color: AppColors.royalGold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Tap to view transfer thresholds',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.info_outline_rounded, color: AppColors.royalGold.withValues(alpha: 0.5), size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  void _showTransferThresholds(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ecobank Tier 3', style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('Fully Compliant • KYC Verified', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildThresholdRow('Daily Transfer Limit', '₵10,000 / \$650'),
            _buildThresholdRow('Single Transaction Max', '₵5,000 / \$325'),
            _buildThresholdRow('Monthly Volume Cap', '₵100,000 / \$6,500'),
            _buildThresholdRow('International Outbound', '\$2,000 / day'),
            _buildThresholdRow('Mobile Money Cashout', '₵5,000 / day'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.royalGold.withValues(alpha: 0.5), size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Limits are set by Ecobank Ghana under Bank of Ghana regulatory guidelines.',
                      style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 13)),
          Text(value, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DIRECT DEPOSIT CONTROL HUB
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildDirectDepositHub(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.royalGold, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Direct Deposit Setup', style: TextStyle(color: AppColors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Share these with freelance portals', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // US Routing
          _buildRoutingCard(
            flag: '🇺🇸',
            title: 'US Dollar Account',
            rows: [
              _RoutingRow('Bank Name', 'VessPay Digital (via Ecobank)'),
              _RoutingRow('Routing Number', '084009519'),
              _RoutingRow('Account Number', 'VP-8801234567'),
              _RoutingRow('Account Type', 'Checking'),
            ],
          ),
          const SizedBox(height: 14),

          // UK Routing
          _buildRoutingCard(
            flag: '🇬🇧',
            title: 'UK Sterling Account',
            rows: [
              _RoutingRow('Bank Name', 'VessPay Digital (via Ecobank)'),
              _RoutingRow('Sort Code', '23-14-70'),
              _RoutingRow('Account Number', 'VP-6609876543'),
              _RoutingRow('IBAN', 'GB29 VPAY 2314 7066 0987 6543'),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildRoutingCard({
    required String flag,
    required String title,
    required List<_RoutingRow> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...rows.map((row) => _buildCopyableRow(row.label, row.value)),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 2,
            child: Text(label, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11)),
          ),
          Flexible(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
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
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.copy_rounded, color: AppColors.royalGold.withValues(alpha: 0.6), size: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LINKED MOBILE MONEY ACCOUNTS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLinkedMoMoSection(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        children: [
          ..._linkedAccounts.asMap().entries.map((entry) {
            final account = entry.value;
            final isLast = entry.key == _linkedAccounts.length - 1;
            return Column(
              children: [
                Row(
                  children: [
                    Text(account.flag, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.network,
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          Text(
                            account.number,
                            style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.7), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (account.verified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                if (!isLast) Divider(color: AppColors.white.withValues(alpha: 0.06), height: 24),
              ],
            );
          }),
          const SizedBox(height: 16),
          // Add new account button
          GestureDetector(
            onTap: () => _showAddMoMoSheet(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: AppColors.royalGold.withValues(alpha: 0.7), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Add Mobile Money Account',
                    style: TextStyle(color: AppColors.royalGold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  void _showAddMoMoSheet(BuildContext context) {
    final networkController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedCountry = 'Ghana';
    String selectedFlag = '🇬🇭';

    final countries = [
      {'name': 'Ghana', 'flag': '🇬🇭', 'networks': 'MTN, Vodafone, AirtelTigo'},
      {'name': 'Kenya', 'flag': '🇰🇪', 'networks': 'M-Pesa, Airtel Money'},
      {'name': 'Nigeria', 'flag': '🇳🇬', 'networks': 'OPay, Palmpay'},
      {'name': 'Tanzania', 'flag': '🇹🇿', 'networks': 'M-Pesa, Tigo Pesa'},
      {'name': 'Uganda', 'flag': '🇺🇬', 'networks': 'MTN MoMo, Airtel Money'},
      {'name': 'Rwanda', 'flag': '🇷🇼', 'networks': 'MTN MoMo'},
      {'name': 'Senegal', 'flag': '🇸🇳', 'networks': 'Orange Money, Wave'},
      {'name': 'South Africa', 'flag': '🇿🇦', 'networks': 'FNB eWallet'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.verticalGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add Mobile Money Account',
                style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Country selector
              Text('COUNTRY', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.6), fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: countries.map((c) {
                  return GestureDetector(
                    onTap: () {
                      selectedCountry = c['name']!;
                      selectedFlag = c['flag']!;
                      networkController.text = c['networks']!.split(',').first.trim();
                      (ctx as Element).markNeedsBuild();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedCountry == c['name']
                            ? AppColors.royalGold.withValues(alpha: 0.12)
                            : AppColors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedCountry == c['name']
                              ? AppColors.royalGold.withValues(alpha: 0.3)
                              : AppColors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        '${c['flag']} ${c['name']}',
                        style: TextStyle(
                          color: selectedCountry == c['name'] ? AppColors.white : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: selectedCountry == c['name'] ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              // Phone number
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: Theme.of(ctx).textTheme.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter mobile money number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Link Account',
                onPress: () {
                  if (phoneController.text.trim().isNotEmpty) {
                    setState(() {
                      _linkedAccounts.add(_LinkedMoMoAccount(
                        network: '${networkController.text.isNotEmpty ? networkController.text : selectedCountry} Mobile Money',
                        number: phoneController.text.trim(),
                        flag: selectedFlag,
                        verified: false,
                      ));
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Account linked — verification pending'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.royalGold, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w500),
              ),
            ),
            trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: 32,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 32),
            ),
            const SizedBox(height: 24),
            Text(
              'Sign Out?',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to sign out from your account?',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.secondary,
                    onPress: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppButton(
                    label: 'Sign Out',
                    variant: AppButtonVariant.danger,
                    onPress: () async {
                      // Call auth provider logout to clear state
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        context.go('/landing'); // Navigate to landing
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () async {
                // Call auth provider logout to clear state
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  context.go('/landing'); // Navigate to landing
                }
              },
              child: const Text('Sign out from all devices', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.white10);
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

class _LinkedMoMoAccount {
  final String network;
  final String number;
  final String flag;
  final bool verified;

  const _LinkedMoMoAccount({
    required this.network,
    required this.number,
    required this.flag,
    required this.verified,
  });
}

class _RoutingRow {
  final String label;
  final String value;
  const _RoutingRow(this.label, this.value);
}
