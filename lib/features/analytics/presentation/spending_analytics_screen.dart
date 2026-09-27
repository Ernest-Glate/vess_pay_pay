import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/transaction_model.dart';
import '../../wallet/data/transaction_provider.dart';

class SpendingAnalyticsScreen extends ConsumerStatefulWidget {
  const SpendingAnalyticsScreen({super.key});

  @override
  ConsumerState<SpendingAnalyticsScreen> createState() => _SpendingAnalyticsScreenState();
}

class _SpendingAnalyticsScreenState extends ConsumerState<SpendingAnalyticsScreen> {
  String _selectedPeriod = 'month'; // week, month, year

  @override
  Widget build(BuildContext context) {
    final allTransactions = ref.watch(transactionListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Spending Analytics',
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
                _buildPeriodSelector(),
                const SizedBox(height: 24),
                _buildSummaryCards(allTransactions),
                const SizedBox(height: 24),
                _buildSpendingTrendChart(allTransactions),
                const SizedBox(height: 24),
                _buildCategoryBreakdown(allTransactions),
                const SizedBox(height: 24),
                _buildTopMerchants(allTransactions),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return GlassContainer(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildPeriodChip('Week', 'week'),
          _buildPeriodChip('Month', 'month'),
          _buildPeriodChip('Year', 'year'),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalGold : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.darkBg : AppColors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<TransactionModel> transactions) {
    final filtered = _getFilteredTransactions(transactions);
    final totalSpent = filtered
        .where((t) => t.type == 'debit')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final totalReceived = filtered
        .where((t) => t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
    
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Spent',
            CurrencyFormatters.formatAmount(totalSpent, 'GHS'),
            Icons.trending_down_rounded,
            AppColors.errorRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Received',
            CurrencyFormatters.formatAmount(totalReceived, 'GHS'),
            Icons.trending_up_rounded,
            AppColors.successGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendChart(List<TransactionModel> transactions) {
    final filtered = _getFilteredTransactions(transactions);
    
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending Trend',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1000,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderGray.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '₵${value.toInt()}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Text(
                        _getBottomTitleText(value.toInt()),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _getSpendingSpots(filtered),
                    isCurved: true,
                    color: AppColors.royalGold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.royalGold.withValues(alpha: 0.3),
                          AppColors.royalGold.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(List<TransactionModel> transactions) {
    final filtered = _getFilteredTransactions(transactions);
    final categories = _getCategoryBreakdown(filtered);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: _getPieSections(categories),
                      centerSpaceRadius: 50,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCategoryLegend(categories),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(Map<String, double> categories) {
    final colors = [
      AppColors.royalGold,
      AppColors.successGreen,
      AppColors.errorRed,
      AppColors.royalGold.withValues(alpha: 0.5),
      AppColors.textSecondary,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: categories.entries.take(5).toList().asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                category.key,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopMerchants(List<TransactionModel> transactions) {
    final filtered = _getFilteredTransactions(transactions);
    final merchants = _getTopMerchants(filtered);

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Recipients',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...merchants.entries.take(5).map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.royalGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.store_rounded, color: AppColors.royalGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value['count']} transactions',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatters.formatAmount(entry.value['amount'], 'GHS'),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> transactions) {
    final now = DateTime.now();
    DateTime cutoff;

    switch (_selectedPeriod) {
      case 'week':
        cutoff = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'year':
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        cutoff = DateTime(now.year, now.month - 1, now.day);
    }

    return transactions.where((t) => t.createdAt.isAfter(cutoff)).toList();
  }

  List<FlSpot> _getSpendingSpots(List<TransactionModel> transactions) {
    // Group transactions by day and sum spending
    final spots = <FlSpot>[];
    final spendingByDay = <int, double>{};

    for (var t in transactions) {
      if (t.type == 'debit') {
        final dayIndex = t.createdAt.day;
        spendingByDay[dayIndex] = (spendingByDay[dayIndex] ?? 0) + t.amount;
      }
    }

    final sortedDays = spendingByDay.keys.toList()..sort();
    for (var i = 0; i < sortedDays.length; i++) {
      spots.add(FlSpot(i.toDouble(), spendingByDay[sortedDays[i]]!));
    }

    return spots.isEmpty ? [const FlSpot(0, 0)] : spots;
  }

  Map<String, double> _getCategoryBreakdown(List<TransactionModel> transactions) {
    final categories = <String, double>{};
    
    for (var t in transactions) {
      if (t.type == 'debit') {
        final category = _categorizeTransaction(t);
        categories[category] = (categories[category] ?? 0) + t.amount;
      }
    }

    return categories;
  }

  Map<String, Map<String, dynamic>> _getTopMerchants(List<TransactionModel> transactions) {
    final merchants = <String, Map<String, dynamic>>{};
    
    for (var t in transactions) {
      if (t.type == 'debit' || t.type == 'momo_send') {
        final merchant = t.description ?? t.recipientNumber ?? 'Unknown';
        if (merchants.containsKey(merchant)) {
          merchants[merchant]!['amount'] += t.amount;
          merchants[merchant]!['count'] += 1;
        } else {
          merchants[merchant] = {'amount': t.amount, 'count': 1};
        }
      }
    }

    // Sort by amount
    final sorted = merchants.entries.toList()
      ..sort((a, b) => (b.value['amount'] as double).compareTo(a.value['amount'] as double));

    return Map.fromEntries(sorted);
  }

  List<PieChartSectionData> _getPieSections(Map<String, double> categories) {
    final colors = [
      AppColors.royalGold,
      AppColors.successGreen,
      AppColors.errorRed,
      AppColors.royalGold.withValues(alpha: 0.5),
      AppColors.textSecondary,
    ];

    return categories.entries.take(5).toList().asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return PieChartSectionData(
        value: category.value,
        color: colors[index % colors.length],
        radius: 60,
        title: '',
      );
    }).toList();
  }

  String _categorizeTransaction(TransactionModel transaction) {
    final desc = (transaction.description ?? transaction.recipientNumber ?? '').toLowerCase();
    
    if (desc.contains('food') || desc.contains('restaurant') || desc.contains('grocery')) {
      return 'Food & Dining';
    } else if (desc.contains('transport') || desc.contains('uber') || desc.contains('taxi')) {
      return 'Transportation';
    } else if (desc.contains('shop') || desc.contains('store')) {
      return 'Shopping';
    } else if (desc.contains('bill') || desc.contains('utility') || desc.contains('electricity')) {
      return 'Bills & Utilities';
    } else if (desc.contains('entertainment') || desc.contains('movie') || desc.contains('game')) {
      return 'Entertainment';
    }
    
    return 'Other';
  }

  String _getBottomTitleText(int value) {
    if (_selectedPeriod == 'week') {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return value < days.length ? days[value] : '';
    } else if (_selectedPeriod == 'month') {
      return value % 5 == 0 ? 'Day $value' : '';
    }
    return value < 12 ? ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][value] : '';
  }
}
