import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/transaction_limit_model.dart';
import '../data/transaction_limit_provider.dart';

class TransactionLimitsScreen extends ConsumerStatefulWidget {
  const TransactionLimitsScreen({super.key});

  @override
  ConsumerState<TransactionLimitsScreen> createState() => _TransactionLimitsScreenState();
}

class _TransactionLimitsScreenState extends ConsumerState<TransactionLimitsScreen> {
  @override
  Widget build(BuildContext context) {
    final limits = ref.watch(transactionLimitProvider);
    final exceededLimits = ref.read(transactionLimitProvider.notifier).getExceededLimits();
    final nearLimitAlerts = ref.read(transactionLimitProvider.notifier).getNearLimitAlerts();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Transaction Limits',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.royalGold),
            onPressed: () => _showAddLimitDialog(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alerts Section
                if (exceededLimits.isNotEmpty || nearLimitAlerts.isNotEmpty) ...[
                  _buildAlertsSection(exceededLimits, nearLimitAlerts),
                  const SizedBox(height: 24),
                ],

                // Summary Cards
                _buildSummaryCards(limits),
                const SizedBox(height: 24),

                // Limits List
                const Text(
                  'YOUR LIMITS',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (limits.isEmpty)
                  _buildEmptyState()
                else
                  ...limits.map((limit) => _buildLimitCard(limit)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertsSection(List<TransactionLimitModel> exceeded, List<TransactionLimitModel> nearLimit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ALERTS',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        
        if (exceeded.isNotEmpty)
          ...exceeded.map((limit) => _buildAlertCard(
                'Limit Exceeded',
                'Your ${limit.type} ${limit.category ?? 'spending'} limit has been exceeded',
                AppColors.errorRed,
                Icons.error_outline_rounded,
              )),
        
        if (nearLimit.isNotEmpty)
          ...nearLimit.map((limit) => _buildAlertCard(
                'Approaching Limit',
                '${limit.category ?? 'Daily spending'} is at ${limit.percentageUsed.toStringAsFixed(0)}% of limit',
                Colors.orange,
                Icons.warning_amber_rounded,
              )),
      ],
    );
  }

  Widget _buildAlertCard(String title, String message, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<TransactionLimitModel> limits) {
    final activeLimits = limits.where((l) => l.isActive).length;
    final totalBudget = limits.fold<double>(0, (sum, l) => sum + l.limitAmount);

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Active Limits',
            activeLimits.toString(),
            Icons.check_circle_outline_rounded,
            AppColors.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Budget',
            CurrencyFormatters.formatAmount(totalBudget, 'GHS'),
            Icons.account_balance_wallet_rounded,
            AppColors.royalGold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
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
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitCard(TransactionLimitModel limit) {
    final progressColor = limit.isExceeded
        ? AppColors.errorRed
        : limit.isNearLimit
            ? Colors.orange
            : AppColors.successGreen;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getLimitTypeLabel(limit.type),
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (limit.category != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.royalGold.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              limit.category!.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.royalGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Limit: ${CurrencyFormatters.formatAmount(limit.limitAmount, limit.currency)}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: limit.isActive
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.borderGray,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  limit.isActive ? 'ACTIVE' : 'PAUSED',
                  style: TextStyle(
                    color: limit.isActive ? AppColors.successGreen : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${CurrencyFormatters.formatAmount(limit.currentSpending, limit.currency)}',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${limit.percentageUsed.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: progressColor,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: limit.percentageUsed / 100,
                  backgroundColor: AppColors.borderGray,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditLimitDialog(context, limit),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.royalGold,
                    side: const BorderSide(color: AppColors.royalGold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ref.read(transactionLimitProvider.notifier).toggleLimitStatus(limit.id);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: limit.isActive ? AppColors.errorRed : AppColors.successGreen,
                    side: BorderSide(color: limit.isActive ? AppColors.errorRed : AppColors.successGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(limit.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 16),
                  label: Text(limit.isActive ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(context, limit),
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No transaction limits set',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a limit to control your spending',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLimitTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return 'Daily Limit';
      case 'weekly':
        return 'Weekly Limit';
      case 'monthly':
        return 'Monthly Limit';
      case 'per_transaction':
        return 'Per Transaction Limit';
      default:
        return type;
    }
  }

  void _showAddLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _LimitFormDialog(
        onSave: (limit) {
          ref.read(transactionLimitProvider.notifier).addLimit(limit);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Limit added successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _showEditLimitDialog(BuildContext context, TransactionLimitModel limit) {
    showDialog(
      context: context,
      builder: (context) => _LimitFormDialog(
        limit: limit,
        onSave: (updatedLimit) {
          ref.read(transactionLimitProvider.notifier).updateLimit(updatedLimit);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Limit updated successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, TransactionLimitModel limit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBg,
        title: const Text('Delete Limit', style: TextStyle(color: AppColors.white)),
        content: Text(
          'Are you sure you want to delete this ${limit.type} limit?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(transactionLimitProvider.notifier).deleteLimit(limit.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Limit deleted'),
                  backgroundColor: AppColors.errorRed,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
          ),
        ],
      ),
    );
  }
}

// Limit Form Dialog Widget
class _LimitFormDialog extends StatefulWidget {
  final TransactionLimitModel? limit;
  final Function(TransactionLimitModel) onSave;

  const _LimitFormDialog({
    this.limit,
    required this.onSave,
  });

  @override
  State<_LimitFormDialog> createState() => _LimitFormDialogState();
}

class _LimitFormDialogState extends State<_LimitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  
  String _selectedType = 'daily';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.limit?.limitAmount.toString() ?? '');
    _selectedType = widget.limit?.type ?? 'daily';
    _selectedCategory = widget.limit?.category;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkBg,
      title: Text(
        widget.limit == null ? 'Add Transaction Limit' : 'Edit Transaction Limit',
        style: const TextStyle(color: AppColors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                dropdownColor: AppColors.darkBg,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Limit Type',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'per_transaction', child: Text('Per Transaction')),
                ],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.darkBg,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Category (Optional)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Transactions')),
                  DropdownMenuItem(value: 'bills', child: Text('Bills')),
                  DropdownMenuItem(value: 'entertainment', child: Text('Entertainment')),
                  DropdownMenuItem(value: 'food', child: Text('Food & Dining')),
                  DropdownMenuItem(value: 'transport', child: Text('Transport')),
                  DropdownMenuItem(value: 'shopping', child: Text('Shopping')),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: AppColors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Limit Amount (GHS)',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGray)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: _saveLimit,
          child: const Text('Save', style: TextStyle(color: AppColors.royalGold)),
        ),
      ],
    );
  }

  void _saveLimit() {
    if (_formKey.currentState?.validate() ?? false) {
      final limit = TransactionLimitModel(
        id: widget.limit?.id ?? 'limit_${DateTime.now().millisecondsSinceEpoch}',
        type: _selectedType,
        category: _selectedCategory,
        limitAmount: double.parse(_amountController.text),
        currency: 'GHS',
        currentSpending: widget.limit?.currentSpending ?? 0.0,
        isActive: widget.limit?.isActive ?? true,
        createdAt: widget.limit?.createdAt ?? DateTime.now(),
        lastResetDate: widget.limit?.lastResetDate,
      );

      widget.onSave(limit);
      Navigator.pop(context);
    }
  }
}
