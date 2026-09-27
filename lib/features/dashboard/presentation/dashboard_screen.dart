import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/shimmer_loading.dart';
import '../../wallet/data/wallet_provider.dart';
import '../../wallet/data/transaction_provider.dart';
import '../../auth/data/auth_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _balancePageController = PageController();
  int _currentBalancePage = 0;

  @override
  void initState() {
    super.initState();
    // Auto-fetch wallet balance and recent transactions on dashboard load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).fetchBalance();
      ref.read(transactionProvider.notifier).fetchTransactions();
    });
  }

  @override
  void dispose() {
    _balancePageController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD — wrapped in SingleChildScrollView to prevent overflow
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final authState = ref.watch(authProvider);
    final txState = ref.watch(transactionProvider);
    final balance = walletState.balance;
    final recentTransactions = txState.transactions.take(3).toList();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.royalGold,
            backgroundColor: AppColors.deepGreen1,
            onRefresh: () async {
              await Future.wait([
                ref.read(walletProvider.notifier).fetchBalance(),
                ref.read(transactionProvider.notifier).fetchTransactions(),
              ]);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────
                  _buildHeader(authState),

                  const SizedBox(height: 28),

                  // ── Multi-Currency Balance Carousel ─────────────
                  _buildBalanceCarousel(walletState),

                  const SizedBox(height: 28),

                  // ── Consolidated Action Grid (4 primary) ───────
                  _buildActionGrid(),

                  const SizedBox(height: 28),

                  // ── Cashflow Analytics ─────────────────────────
                  _buildAnalyticsSection(balance, recentTransactions),

                  const SizedBox(height: 28),

                  // ── Recent Activity ────────────────────────────
                  _buildRecentActivity(txState, recentTransactions),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(AuthState authState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                authState.user?.firstName ?? 'VessPay',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white.withValues(alpha: 0.05),
                  border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.notifications_outlined, color: AppColors.royalGold, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => context.push('/profile'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                ),
                child: const CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.forestDepths,
                  child: Icon(Icons.person_rounded, color: AppColors.royalGold),
                ),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MULTI-CURRENCY BALANCE CAROUSEL
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBalanceCarousel(WalletState walletState) {
    final ghsBalance = walletState.balance;
    final ghsCurrency = walletState.currency;

    // Simulated USD balance — in production, pull from multi-wallet API
    final usdBalance = ghsBalance > 0 ? (ghsBalance / 15.5) : 0.0;

    final balanceCards = [
      _BalanceCardData(
        currency: 'USD',
        symbol: '\$',
        balance: usdBalance,
        label: 'Inbound Payroll / Travel Fund',
        accentColor: AppColors.royalGold,
        icon: Icons.account_balance_wallet_rounded,
      ),
      _BalanceCardData(
        currency: ghsCurrency,
        symbol: '₵',
        balance: ghsBalance,
        label: 'Mobile Money Liquidation',
        accentColor: AppColors.success,
        icon: Icons.phone_android_rounded,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _balancePageController,
            onPageChanged: (index) => setState(() => _currentBalancePage = index),
            itemCount: balanceCards.length,
            itemBuilder: (context, index) {
              final card = balanceCards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildBalanceCard(card),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        // Page dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            balanceCards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentBalancePage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentBalancePage == index
                    ? AppColors.royalGold
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOutBack);
  }

  Widget _buildBalanceCard(_BalanceCardData card) {
    return GlassContainer(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      border: Border.all(color: card.accentColor.withValues(alpha: 0.2), width: 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: card.accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(card.icon, color: card.accentColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${card.currency} Balance',
                        style: TextStyle(
                          color: card.accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        card.label,
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: card.accentColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  card.currency,
                  style: TextStyle(
                    color: card.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${card.symbol}${card.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.swipe_rounded, color: AppColors.textSecondary.withValues(alpha: 0.4), size: 14),
              const SizedBox(width: 6),
              Text(
                'Swipe to view other wallets',
                style: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CONSOLIDATED ACTION GRID (4 primary + nested More)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAction(
          icon: Icons.add_rounded,
          label: 'Deposit',
          onTap: () => context.push('/add-money'),
        ),
        _buildQuickAction(
          icon: Icons.currency_exchange_rounded,
          label: 'Swap FX',
          onTap: () => context.push('/fx-convert'),
        ),
        _buildQuickAction(
          icon: Icons.send_rounded,
          label: 'Send',
          onTap: () => context.push('/pay-momo'),
        ),
        _buildQuickAction(
          icon: Icons.qr_code_scanner_rounded,
          label: 'Scan QR',
          onTap: () => context.push('/scan'),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: AppColors.royalGold, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECONDARY ACTIONS MENU (nested under More)
  // ══════════════════════════════════════════════════════════════════════════

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.55,
        ),
        decoration: const BoxDecoration(
          color: AppColors.deepGreen1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Container(
             decoration: const BoxDecoration(
              gradient: AppColors.verticalGradient,
               borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
             ),
             padding: const EdgeInsets.all(24),
             child: SingleChildScrollView(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Center(
                     child: Container(
                       width: 40,
                       height: 4,
                       decoration: BoxDecoration(
                         color: AppColors.white.withValues(alpha: 0.2),
                         borderRadius: BorderRadius.circular(2),
                       ),
                     ),
                   ),
                   const SizedBox(height: 24),
                   Text(
                     'MORE ACTIONS',
                     style: Theme.of(context).textTheme.labelSmall?.copyWith(
                       color: AppColors.textSecondary,
                       letterSpacing: 2,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 24),
                   GridView.count(
                     crossAxisCount: 4,
                     mainAxisSpacing: 16,
                     crossAxisSpacing: 16,
                     shrinkWrap: true,
                     physics: const NeverScrollableScrollPhysics(),
                     children: [
                        _buildMenuOption(context, Icons.south_west_rounded, 'Request', () {
                          Navigator.pop(context);
                          context.push('/request-money');
                        }),
                        _buildMenuOption(context, Icons.receipt_long_rounded, 'Bills', () {
                           Navigator.pop(context);
                           context.push('/bill-payment');
                        }),
                        _buildMenuOption(context, Icons.history_rounded, 'History', () {
                           Navigator.pop(context);
                           context.push('/transaction-history');
                        }),
                        _buildMenuOption(context, Icons.schedule_rounded, 'Scheduled', () {
                           Navigator.pop(context);
                           context.push('/scheduled-payments');
                        }),
                        _buildMenuOption(context, Icons.analytics_rounded, 'Analytics', () {
                           Navigator.pop(context);
                           context.push('/spending-analytics');
                        }),
                        _buildMenuOption(context, Icons.support_agent_rounded, 'Support', () {
                           Navigator.pop(context);
                        }),
                     ],
                   ),
                 ],
               ),
             ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: AppColors.royalGold, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CASHFLOW ANALYTICS SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsSection(double balance, List recentTransactions) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CASHFLOW ANALYTICS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₵${balance.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showMoreOptions(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.grid_view_rounded, color: AppColors.royalGold.withValues(alpha: 0.7), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'More',
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 600.ms),
        const SizedBox(height: 16),
        GlassContainer(
          height: 220,
          padding: const EdgeInsets.all(20),
          child: _buildChart(recentTransactions),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RECENT ACTIVITY
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentActivity(dynamic txState, List recentTransactions) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RECENT ACTIVITY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/transactions'),
              child: Text(
                'SEE ALL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.royalGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 800.ms),
        const SizedBox(height: 16),

        // Transaction list — real data or empty state
        if (txState.isLoading)
          ...[
            for (int i = 0; i < 3; i++) ...[
              const ShimmerLoading(height: 64, borderRadius: 16),
              const SizedBox(height: 12),
            ],
          ]
        else if (recentTransactions.isEmpty)
          GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 48),
                const SizedBox(height: 12),
                Text(
                  'No transactions yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deposit funds or receive a payroll transfer to get started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 800.ms)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentTransactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tx = recentTransactions[index];
              final isCredit = tx.type == 'load' || tx.type == 'refund' || tx.type == 'admin_credit';
              final formatter = DateFormat('MMM d, h:mm a');

              return GestureDetector(
                onTap: () => context.push('/transaction-receipt/${tx.id}', extra: tx),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (isCredit ? Colors.green : AppColors.royalGold).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                          color: isCredit ? Colors.green : AppColors.royalGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description ?? tx.typeLabel,
                              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              formatter.format(tx.createdAt),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${isCredit ? '+' : '-'} ${tx.currency} ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isCredit ? Colors.green : AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CHART
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildChart(List transactions) {
    // Generate chart data from recent transactions or show flat line for empty state
    final spots = transactions.isEmpty
        ? const [FlSpot(0, 1), FlSpot(1, 1), FlSpot(2, 1), FlSpot(3, 1), FlSpot(4, 1), FlSpot(5, 1), FlSpot(6, 1)]
        : List.generate(
            7,
            (i) {
              // Use amount data from last 7 transactions, or pad with 0
              final idx = transactions.length > i ? i : -1;
              if (idx >= 0) {
                final tx = transactions[idx];
                return FlSpot(i.toDouble(), (tx.amount / 100).clamp(0.5, 6));
              }
              return FlSpot(i.toDouble(), 0.5);
            },
          );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.white.withValues(alpha: 0.03),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 2,
              getTitlesWidget: (double value, TitleMeta meta) {
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                if (value.toInt() >= 0 && value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 6,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => AppColors.forestDepths.withValues(alpha: 0.95),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '₵${(barSpot.y * 100).toStringAsFixed(0)}',
                  const TextStyle(
                    color: AppColors.royalGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            preventCurveOverShooting: true,
            color: AppColors.royalGold,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: AppColors.royalGold,
                  strokeWidth: 2,
                  strokeColor: AppColors.deepGreen1,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.royalGold.withValues(alpha: 0.35),
                  AppColors.royalGold.withValues(alpha: 0.15),
                  AppColors.royalGold.withValues(alpha: 0.02),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            shadow: Shadow(
              color: AppColors.royalGold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  BALANCE CARD DATA MODEL
// ══════════════════════════════════════════════════════════════════════════════

class _BalanceCardData {
  final String currency;
  final String symbol;
  final double balance;
  final String label;
  final Color accentColor;
  final IconData icon;

  const _BalanceCardData({
    required this.currency,
    required this.symbol,
    required this.balance,
    required this.label,
    required this.accentColor,
    required this.icon,
  });
}
