import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  bool _isRefreshing = false;

  Future<void> _onRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: _onRefresh,
                color: AppColors.royalGold,
                backgroundColor: AppColors.deepGreen1,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverHeader(),
                    _buildTransactionGroups(),
                  ],
                ),
              ),
              if (_isRefreshing)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.royalGold),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
              const Row(
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 16),
                  SizedBox(width: 8),
                  Text('OFFLINE MODE', style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'ACTIVITY HISTORY',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppColors.royalGold,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'Detailed logs of all your financial movements',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildTransactionGroups() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateHeader(index == 0 ? 'Today' : 'Yesterday'),
                const SizedBox(height: 16),
                ...List.generate(3, (i) => _buildHistoryItem(i)),
                const SizedBox(height: 32),
              ],
            );
          },
          childCount: 2,
        ),
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Text(
      date.toUpperCase(),
      style: const TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
    ).animate().fadeIn();
  }

  Widget _buildHistoryItem(int index) {
    final isDebit = index % 2 == 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDebit ? Colors.redAccent : AppColors.royalGold).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDebit ? Icons.arrow_outward_rounded : Icons.south_west_rounded,
                color: isDebit ? Colors.redAccent : AppColors.royalGold,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDebit ? 'Transfer to James' : 'Received via MoMo',
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Text('Ref: VP-8829-X-22', style: TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isDebit ? '-' : '+'} GHS 120.00',
                  style: TextStyle(
                    color: isDebit ? Colors.white : AppColors.royalGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Text('10:45 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
  }
}
