import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/wallet_model.dart';
import '../../../shared/models/currency_model.dart';
import '../data/wallet_provider.dart';
import '../../profile/data/settings_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final settings = ref.watch(settingsProvider);
    final isHidden = settings.isBalanceHidden;

    final wallets = walletState.wallets;
    final activeWallet = walletState.activeWallet;
    final activeCurrency = activeWallet?.currency ?? 'GHS';
    final activeBalance = activeWallet?.balance ?? 0.0;
    final currencyInfo = Currency.fromCode(activeCurrency);
    final symbol = currencyInfo?.symbol ?? activeCurrency;
    final dailyLimitRemaining = activeWallet?.dailyLimitRemaining ?? 0.0;
    final dailySpendLimit = activeWallet?.dailySpendLimit ?? 300.0;
    final totalLoaded = activeWallet?.totalLoaded ?? 0.0;
    final totalSpent = activeWallet?.totalSpent ?? 0.0;
    final isFrozen = activeWallet?.isFrozen ?? false;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────────────
                      _buildHeader(context, ref, walletState, isHidden),

                      const SizedBox(height: 12),

                      // ── Primary Balance (active wallet) ────────────
                      _buildPrimaryBalance(context, activeBalance, symbol, isHidden, isFrozen, activeCurrency, currencyInfo),

                      const SizedBox(height: 28),

                      // ── Wallet Card Carousel (1–2 cards) ───────────
                      _buildCardCarousel(context, wallets, isHidden),

                      const SizedBox(height: 28),

                      // ── Quick Actions ──────────────────────────────
                      _buildActionGrid(context, activeCurrency),

                      const SizedBox(height: 32),

                      // ── Analytics: Inflow vs Outflow ───────────────
                      _buildAnalyticsSection(context, totalLoaded, totalSpent, symbol),

                      const SizedBox(height: 28),

                      // ── Wallet Stats ───────────────────────────────
                      Text(
                        'WALLET OVERVIEW',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatCard(context, 'Total Loaded', '$symbol ${totalLoaded.toStringAsFixed(2)}', Icons.arrow_downward_rounded, Colors.green, isHidden),
                    const SizedBox(height: 12),
                    _buildStatCard(context, 'Total Spent', '$symbol ${totalSpent.toStringAsFixed(2)}', Icons.arrow_upward_rounded, AppColors.royalGold, isHidden),
                    const SizedBox(height: 12),
                    _buildStatCard(context, 'Daily Limit Remaining', '$symbol ${dailyLimitRemaining.toStringAsFixed(2)} / ${dailySpendLimit.toStringAsFixed(0)}', Icons.speed_rounded, AppColors.royalGoldLight, isHidden),
                  ]),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HEADER — dynamic label + eye toggle
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context, WidgetRef ref, WalletState walletState, bool isHidden) {
    final activeIndex = walletState.activeCardIndex;
    final activeWallet = walletState.activeWallet;
    final isUsd = activeWallet?.currency == 'USD';

    final label = isUsd ? 'USD HOLDING ACCOUNT' : 'LOCAL SPENDING ACCOUNT';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => ref.read(settingsProvider.notifier).toggleBalanceVisibility(),
                  child: Icon(
                    isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Wallet count indicator
            if (walletState.hasMultipleWallets)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: AppColors.royalGold.withValues(alpha: 0.7), size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Swipe to switch wallet • ${activeIndex + 1}/${walletState.wallets.length}',
                      style: TextStyle(
                        color: AppColors.royalGold.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (walletState.isLoading)
          const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.royalGold),
          )
        else
          GestureDetector(
            onTap: () => ref.read(walletProvider.notifier).fetchBalance(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh_rounded, color: AppColors.royalGold),
            ),
          ),
      ],
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PRIMARY BALANCE — adapts to active wallet currency
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPrimaryBalance(
    BuildContext context,
    double balance,
    String symbol,
    bool isHidden,
    bool isFrozen,
    String currencyCode,
    Currency? currencyInfo,
  ) {
    final subtitle = currencyCode == 'USD'
        ? 'US Dollars • Inflation Shield'
        : '${currencyInfo?.name ?? currencyCode} • Mobile Money Ready';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            isHidden ? '••••••' : '$symbol ${balance.toStringAsFixed(2)}',
            key: ValueKey('$currencyCode-$isHidden-$balance'),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isFrozen ? AppColors.danger : AppColors.white,
              fontSize: 42,
            ),
          ),
        ),
        if (isFrozen)
          const Text(
            'WALLET FROZEN',
            style: TextStyle(color: AppColors.danger, fontSize: 10, letterSpacing: 1.5),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              subtitle,
              key: ValueKey(subtitle),
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WALLET CARD CAROUSEL (1–2 cards with dot indicator)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCardCarousel(BuildContext context, List<WalletModel> wallets, bool isHidden) {
    if (wallets.isEmpty) {
      return const SizedBox(height: 220);
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: wallets.length,
            onPageChanged: (index) {
              ref.read(walletProvider.notifier).setActiveCard(index);
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildWalletCard(context, wallets[index], isHidden),
              );
            },
          ),
        ),

        // Dot indicator (only if multiple wallets)
        if (wallets.length > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(wallets.length, (index) {
              final isActive = index == ref.watch(walletProvider).activeCardIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 28 : 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? AppColors.royalGold
                      : AppColors.royalGold.withValues(alpha: 0.2),
                ),
              );
            }),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  INDIVIDUAL WALLET CARD — adapts colors and labels per currency
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildWalletCard(BuildContext context, WalletModel wallet, bool isHidden) {
    final currencyInfo = Currency.fromCode(wallet.currency);
    final symbol = currencyInfo?.symbol ?? wallet.currency;
    final flag = currencyInfo?.flag ?? '💳';
    final isFrozen = wallet.isFrozen;

    // Card colors based on currency type
    final isUsd = wallet.currency == 'USD';
    final cardGradient = isFrozen
        ? [Colors.red.shade900.withValues(alpha: 0.8), AppColors.forestDepths]
        : isUsd
            ? [const Color(0xFF1A237E), const Color(0xFF0D1B2A)] // Deep navy for USD
            : [AppColors.deepGreen2, AppColors.forestDepths]; // Green for local

    final cardLabel = isFrozen
        ? 'WALLET FROZEN'
        : isUsd
            ? 'USD HOLDING'
            : '${wallet.currency} LOCAL ACCOUNT';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUsd ? Colors.blue : AppColors.royalGold).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isUsd ? Colors.blue : AppColors.royalGold).withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardLabel,
                      style: TextStyle(
                        color: isFrozen
                            ? AppColors.danger
                            : isUsd
                                ? Colors.blue.shade200
                                : AppColors.royalGold,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                    ),
                    Text(flag, style: const TextStyle(fontSize: 24)),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isHidden ? '••••••' : '$symbol ${wallet.balance.toStringAsFixed(2)}',
                    key: ValueKey('${wallet.currency}-$isHidden'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CURRENCY', style: TextStyle(color: Colors.white24, fontSize: 10)),
                        Text(
                          '${currencyInfo?.name.toUpperCase() ?? wallet.currency} (${wallet.currency})',
                          style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    Icon(
                      isUsd ? Icons.shield_rounded : Icons.phone_android_rounded,
                      color: isUsd ? Colors.blue.shade200 : AppColors.royalGold,
                      size: 36,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ACTION GRID — adapts to active wallet currency
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionGrid(BuildContext context, String activeCurrency) {
    final isUsd = activeCurrency == 'USD';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickAction(context, Icons.currency_exchange_rounded, 'Swap FX', () => context.push('/fx-convert')),
        _buildQuickAction(context, Icons.send_rounded, 'Send', () => context.push('/pay-momo')),
        _buildQuickAction(context, Icons.history_rounded, 'History', () => context.push('/transaction-history')),
        _buildQuickAction(
          context,
          isUsd ? Icons.add_rounded : Icons.pie_chart_rounded,
          isUsd ? 'Add USD' : 'Stats',
          () => context.push(isUsd ? '/add-money' : '/spending-analytics'),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          GlassContainer(
            borderRadius: 20,
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: AppColors.royalGold),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ANALYTICS — B2B Inflows vs Local Outflows
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildAnalyticsSection(BuildContext context, double totalLoaded, double totalSpent, String symbol) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FLOW ANALYTICS',
                style: TextStyle(color: AppColors.royalGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              Text(
                'THIS WEEK',
                style: TextStyle(color: AppColors.white.withValues(alpha: 0.3), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Legend ─────────────────────────────────────────
          Row(
            children: [
              _buildLegendDot(Colors.green, 'Corporate / B2B Inflows'),
              const SizedBox(width: 20),
              _buildLegendDot(AppColors.royalGold, 'Local Cashouts / QR'),
            ],
          ),
          const SizedBox(height: 20),

          // ── Dual-line chart ───────────────────────────────
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.white.withValues(alpha: 0.03),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.5),
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
                lineBarsData: [
                  // B2B Corporate Inflows (green)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3),
                      FlSpot(3, 5), FlSpot(4, 3.5), FlSpot(5, 4.5), FlSpot(6, 4),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.08),
                    ),
                  ),
                  // Local Outflows — Telco cashout / QR (gold)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1), FlSpot(1, 2.5), FlSpot(2, 1.5),
                      FlSpot(3, 3), FlSpot(4, 2), FlSpot(5, 2.5), FlSpot(6, 3),
                    ],
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: AppColors.royalGold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.royalGold.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Inflow vs Outflow summary row ─────────────────
          Row(
            children: [
              Expanded(
                child: _buildFlowSummary(
                  label: 'B2B Inflows',
                  amount: '$symbol${totalLoaded.toStringAsFixed(0)}',
                  icon: Icons.south_west_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFlowSummary(
                  label: 'Local Cashouts',
                  amount: '$symbol${totalSpent.toStringAsFixed(0)}',
                  icon: Icons.north_east_rounded,
                  color: AppColors.royalGold,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFlowSummary({
    required String label,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  amount,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
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
  //  WALLET STAT CARDS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color color, bool isHidden) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text(
                isHidden ? '••••••' : value,
                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}
