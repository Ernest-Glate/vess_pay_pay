import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../core/repositories/bank_repository.dart';

final bankAccountsProvider = FutureProvider.autoDispose<List<BankAccountModel>>((ref) async {
  final repo = ref.watch(bankRepositoryProvider);
  return repo.getLinkedAccounts();
});

class BankAccountsScreen extends ConsumerWidget {
  const BankAccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(bankAccountsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: accountsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.royalGold)),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
                  data: (accounts) => SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        GlassContainer(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              ...accounts.map((account) => Column(
                                children: [
                                  _buildAccountItem(
                                    icon: Icons.account_balance_rounded,
                                    title: account.bankName,
                                    subtitle: account.accountNumber, // Mask this in real app
                                    isPrimary: account.isPrimary,
                                  ),
                                  const Divider(height: 1, color: Colors.white10),
                                ],
                              )),
                               _buildAddAccountItem(),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(width: 16),
          Text(
            'LINKED ACCOUNTS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.royalGold,
              letterSpacing: 2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isPrimary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.royalGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.royalGold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Primary', style: TextStyle(color: AppColors.royalGold, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

    Widget _buildAddAccountItem() {
    return InkWell(
      onTap: () {
         // Should show dialog to add account via BankRepository.linkAccount
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.add_rounded, color: AppColors.white, size: 20),
            ),
            const SizedBox(width: 16),
             const Text(
                  'Link New Account',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
          ],
        ),
      ),
    );
  }

}
