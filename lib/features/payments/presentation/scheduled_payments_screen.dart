import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/scheduled_payment_model.dart';
import '../data/scheduled_payment_provider.dart';

class ScheduledPaymentsScreen extends ConsumerStatefulWidget {
  const ScheduledPaymentsScreen({super.key});

  @override
  ConsumerState<ScheduledPaymentsScreen> createState() => _ScheduledPaymentsScreenState();
}

class _ScheduledPaymentsScreenState extends ConsumerState<ScheduledPaymentsScreen> {
  String _selectedFilter = 'all'; // all, active, paused

  @override
  Widget build(BuildContext context) {
    final scheduledPayments = ref.watch(scheduledPaymentProvider);
    final filteredPayments = _filterPayments(scheduledPayments);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scheduled Payments',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.royalGold),
            onPressed: () => _showAddPaymentDialog(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filter tabs
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildFilterTabs(),
              ),

              // Payment list
              Expanded(
                child: filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPayments.length,
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(filteredPayments[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Row(
      children: [
        Expanded(
          child: _buildFilterTab('All', 'all'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab('Active', 'active'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildFilterTab('Paused', 'paused'),
        ),
      ],
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.royalGold : AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.royalGold : AppColors.borderGray,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? AppColors.darkBg : AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(ScheduledPaymentModel payment) {
    final frequencyIcon = _getFrequencyIcon(payment.frequency);
    final categoryColor = _getCategoryColor(payment.category);

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: categoryColor.withValues(alpha: 0.2),
                ),
                child: Icon(frequencyIcon, color: categoryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.recipientName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      payment.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatters.formatAmount(payment.amount, payment.currency),
                    style: TextStyle(
                      color: payment.isActive ? AppColors.royalGold : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: payment.isActive ? AppColors.successGreen.withValues(alpha: 0.2) : AppColors.borderGray,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      payment.isActive ? 'ACTIVE' : 'PAUSED',
                      style: TextStyle(
                        color: payment.isActive ? AppColors.successGreen : AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: AppColors.borderGray, height: 1),
          const SizedBox(height: 12),

          // Payment details
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Frequency',
                  payment.frequency.toUpperCase(),
                  Icons.repeat_rounded,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Next Payment',
                  _formatDate(payment.nextPaymentDate),
                  Icons.calendar_today_rounded,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditPaymentDialog(context, payment),
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
                    ref.read(scheduledPaymentProvider.notifier).togglePaymentStatus(payment.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(payment.isActive ? 'Payment paused' : 'Payment activated'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: payment.isActive ? AppColors.errorRed : AppColors.successGreen,
                    side: BorderSide(color: payment.isActive ? AppColors.errorRed : AppColors.successGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(payment.isActive ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 16),
                  label: Text(payment.isActive ? 'Pause' : 'Resume', style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _confirmDelete(context, payment),
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

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_repeat_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No scheduled payments',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a new scheduled payment to get started',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<ScheduledPaymentModel> _filterPayments(List<ScheduledPaymentModel> payments) {
    switch (_selectedFilter) {
      case 'active':
        return payments.where((p) => p.isActive).toList();
      case 'paused':
        return payments.where((p) => !p.isActive).toList();
      default:
        return payments;
    }
  }

  IconData _getFrequencyIcon(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return Icons.today_rounded;
      case 'weekly':
        return Icons.date_range_rounded;
      case 'monthly':
        return Icons.calendar_month_rounded;
      default:
        return Icons.repeat_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'bills':
        return AppColors.errorRed;
      case 'savings':
        return AppColors.successGreen;
      case 'transfers':
        return AppColors.royalGold;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference < 7) return 'In $difference days';

    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddPaymentDialog(BuildContext context) {
    // Implementation for add payment form dialog
    showDialog(
      context: context,
      builder: (context) => _PaymentFormDialog(
        onSave: (payment) {
          ref.read(scheduledPaymentProvider.notifier).addScheduledPayment(payment);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled payment added successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, ScheduledPaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => _PaymentFormDialog(
        payment: payment,
        onSave: (updatedPayment) {
          ref.read(scheduledPaymentProvider.notifier).updateScheduledPayment(updatedPayment);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scheduled payment updated successfully'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, ScheduledPaymentModel payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkBg,
        title: const Text('Delete Payment', style: TextStyle(color: AppColors.white)),
        content: Text(
          'Are you sure you want to delete the scheduled payment to ${payment.recipientName}?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(scheduledPaymentProvider.notifier).deleteScheduledPayment(payment.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scheduled payment deleted'),
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

// Payment Form Dialog Widget
class _PaymentFormDialog extends StatefulWidget {
  final ScheduledPaymentModel? payment;
  final Function(ScheduledPaymentModel) onSave;

  const _PaymentFormDialog({
    this.payment,
    required this.onSave,
  });

  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _recipientController;
  late TextEditingController _accountController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  
  String _selectedFrequency = 'monthly';
  String _selectedCategory = 'bills';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController(text: widget.payment?.recipientName ?? '');
    _accountController = TextEditingController(text: widget.payment?.recipientAccount ?? '');
    _amountController = TextEditingController(text: widget.payment?.amount.toString() ?? '');
    _descriptionController = TextEditingController(text: widget.payment?.description ?? '');
    _selectedFrequency = widget.payment?.frequency ?? 'monthly';
    _selectedCategory = widget.payment?.category ?? 'bills';
    _startDate = widget.payment?.startDate ?? DateTime.now();
    _endDate = widget.payment?.endDate;
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _accountController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.darkBg,
      title: Text(
        widget.payment == null ? 'Add Scheduled Payment' : 'Edit Scheduled Payment',
        style: const TextStyle(color: AppColors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _recipientController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Recipient Name',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGray)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Account Number',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGray)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                style: const TextStyle(color: AppColors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGray)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.borderGray)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.royalGold)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedFrequency,
                dropdownColor: AppColors.darkBg,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) => setState(() => _selectedFrequency = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.darkBg,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                ),
                items: const [
                  DropdownMenuItem(value: 'bills', child: Text('Bills')),
                  DropdownMenuItem(value: 'savings', child: Text('Savings')),
                  DropdownMenuItem(value: 'transfers', child: Text('Transfers')),
                ],
                onChanged: (value) => setState(() => _selectedCategory = value!),
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
          onPressed: _savePayment,
          child: const Text('Save', style: TextStyle(color: AppColors.royalGold)),
        ),
      ],
    );
  }

  void _savePayment() {
    if (_formKey.currentState?.validate() ?? false) {
      final payment = ScheduledPaymentModel(
        id: widget.payment?.id ?? 'sp_${DateTime.now().millisecondsSinceEpoch}',
        recipientName: _recipientController.text,
        recipientAccount: _accountController.text,
        amount: double.parse(_amountController.text),
        currency: 'GHS',
        frequency: _selectedFrequency,
        startDate: _startDate ?? DateTime.now(),
        endDate: _endDate,
        nextPaymentDate: _calculateNextPaymentDate(),
        isActive: widget.payment?.isActive ?? true,
        description: _descriptionController.text,
        category: _selectedCategory,
      );

      widget.onSave(payment);
      Navigator.pop(context);
    }
  }

  DateTime _calculateNextPaymentDate() {
    final start = _startDate ?? DateTime.now();
    switch (_selectedFrequency) {
      case 'daily':
        return start.add(const Duration(days: 1));
      case 'weekly':
        return start.add(const Duration(days: 7));
      case 'monthly':
        return DateTime(start.year, start.month + 1, start.day);
      default:
        return start;
    }
  }
}
