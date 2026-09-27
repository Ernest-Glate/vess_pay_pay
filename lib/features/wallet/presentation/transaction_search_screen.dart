import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/models/transaction_model.dart';
import '../../wallet/data/transaction_provider.dart';

class TransactionSearchScreen extends ConsumerStatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  ConsumerState<TransactionSearchScreen> createState() => _TransactionSearchScreenState();
}

class _TransactionSearchScreenState extends ConsumerState<TransactionSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedType = 'all'; // all, credit, debit, exchange
  String _selectedStatus = 'all'; // all, completed, pending, failed
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date'; // date, amount
  bool _ascending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          'Search Transactions',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppColors.royalGold),
            onPressed: () => _showFilterSheet(context),
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
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search_rounded, color: AppColors.royalGold),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Active filters
              if (_hasActiveFilters())
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildActiveFilters(),
                ),

              // Results
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredTransactions = _filterTransactions(allTransactions);
                    final sortedTransactions = _sortTransactions(filteredTransactions);

                    if (sortedTransactions.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedTransactions.length,
                      itemBuilder: (context, index) {
                        return _buildTransactionCard(sortedTransactions[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _selectedType != 'all' ||
        _selectedStatus != 'all' ||
        _startDate != null ||
        _endDate != null;
  }

  Widget _buildActiveFilters() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (_selectedType != 'all')
            _buildFilterChip('Type: ${_selectedType.toUpperCase()}', () {
              setState(() => _selectedType = 'all');
            }),
          if (_selectedStatus != 'all')
            _buildFilterChip('Status: ${_selectedStatus.toUpperCase()}', () {
              setState(() => _selectedStatus = 'all');
            }),
          if (_startDate != null)
            _buildFilterChip('From: ${_formatDate(_startDate!)}', () {
              setState(() => _startDate = null);
            }),
          if (_endDate != null)
            _buildFilterChip('To: ${_formatDate(_endDate!)}', () {
              setState(() => _endDate = null);
            }),
          if (_hasActiveFilters())
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedType = 'all';
                  _selectedStatus = 'all';
                  _startDate = null;
                  _endDate = null;
                });
              },
              icon: const Icon(Icons.clear_all_rounded, size: 16, color: AppColors.errorRed),
              label: const Text('Clear All', style: TextStyle(color: AppColors.errorRed)),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(color: AppColors.white, fontSize: 12)),
        backgroundColor: AppColors.royalGold.withValues(alpha: 0.2),
        deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.white),
        onDeleted: onRemove,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No transactions found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try different search criteria',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final isCredit = transaction.type == 'credit';
    final icon = transaction.type == 'exchange'
        ? Icons.swap_horiz_rounded
        : isCredit
            ? Icons.arrow_downward_rounded
            : Icons.arrow_upward_rounded;
    
    final color = transaction.type == 'exchange'
        ? AppColors.royalGold
        : isCredit
            ? AppColors.successGreen
            : AppColors.errorRed;

    return GlassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/transaction-details/${transaction.id}'),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.description ?? transaction.recipientNumber ?? 'Transaction',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction.status).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(transaction.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'}${CurrencyFormatters.formatAmount(transaction.amount, transaction.currency)}',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    var filtered = transactions;

    // Search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((t) {
        return (t.description ?? '').toLowerCase().contains(query) ||
            t.id.toLowerCase().contains(query) ||
            (t.recipientNumber?.toLowerCase().contains(query) ?? false) ||
            (t.hubtelTransactionId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Type filter
    if (_selectedType != 'all') {
      filtered = filtered.where((t) => t.type == _selectedType).toList();
    }

    // Status filter
    if (_selectedStatus != 'all') {
      filtered = filtered.where((t) => t.status == _selectedStatus).toList();
    }

    // Date range filter
    if (_startDate != null) {
      filtered = filtered.where((t) => t.createdAt.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((t) => t.createdAt.isBefore(_endDate!)).toList();
    }

    return filtered;
  }

  List<TransactionModel> _sortTransactions(List<TransactionModel> transactions) {
    final sorted = [...transactions];

    if (_sortBy == 'date') {
      sorted.sort((a, b) => _ascending
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'amount') {
      sorted.sort((a, b) => _ascending
          ? a.amount.compareTo(b.amount)
          : b.amount.compareTo(a.amount));
    }

    return sorted;
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Type filter
              const Text('Transaction Type', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'credit', 'debit', 'exchange'].map((type) {
                  return ChoiceChip(
                    label: Text(type.toUpperCase()),
                    selected: _selectedType == type,
                    onSelected: (selected) {
                      setModalState(() => _selectedType = type);
                      setState(() => _selectedType = type);
                    },
                    selectedColor: AppColors.royalGold,
                    labelStyle: TextStyle(
                      color: _selectedType == type ? AppColors.darkBg : AppColors.white,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Status filter
              const Text('Status', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['all', 'completed', 'pending', 'failed'].map((status) {
                  return ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: _selectedStatus == status,
                    onSelected: (selected) {
                      setModalState(() => _selectedStatus = status);
                      setState(() => _selectedStatus = status);
                    },
                    selectedColor: AppColors.royalGold,
                    labelStyle: TextStyle(
                      color: _selectedStatus == status ? AppColors.darkBg : AppColors.white,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Sort by
              const Text('Sort By', style: TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('DATE'),
                      selected: _sortBy == 'date',
                      onSelected: (selected) {
                        setModalState(() => _sortBy = 'date');
                        setState(() => _sortBy = 'date');
                      },
                      selectedColor: AppColors.royalGold,
                      labelStyle: TextStyle(
                        color: _sortBy == 'date' ? AppColors.darkBg : AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('AMOUNT'),
                      selected: _sortBy == 'amount',
                      onSelected: (selected) {
                        setModalState(() => _sortBy = 'amount');
                        setState(() => _sortBy = 'amount');
                      },
                      selectedColor: AppColors.royalGold,
                      labelStyle: TextStyle(
                        color: _sortBy == 'amount' ? AppColors.darkBg : AppColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: AppColors.royalGold,
                    ),
                    onPressed: () {
                      setModalState(() => _ascending = !_ascending);
                      setState(() => _ascending = !_ascending);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.royalGold,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(color: AppColors.darkBg, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.successGreen;
      case 'pending':
        return AppColors.royalGold;
      case 'failed':
        return AppColors.errorRed;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
