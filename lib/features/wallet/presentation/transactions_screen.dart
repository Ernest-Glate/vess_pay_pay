import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _activeFilter = 'All';
  final List<String> _filters = ['All', 'Credit', 'Debit', 'Completed', 'Pending'];
  
  final List<Map<String, dynamic>> _allTransactions = [
    {
      'id': '1',
      'title': 'Salary Deposit',
      'amount': '1,000.00',
      'currency': 'GHS',
      'status': 'Completed',
      'type': 'Credit',
      'date': '2024-01-15T10:30:00Z',
      'recipient': 'Company Inc.'
    },
    {
      'id': '2',
      'title': 'Payment to Vendor',
      'amount': '200.00',
      'currency': 'GHS',
      'status': 'Completed',
      'type': 'Debit',
      'date': '2024-01-14T14:45:00Z',
      'recipient': 'John Doe'
    },
    {
      'id': '3',
      'title': 'Mobile Money Transfer',
      'amount': '50.00',
      'currency': 'GHS',
      'status': 'Pending',
      'type': 'Debit',
      'date': '2024-01-14T09:15:00Z',
      'recipient': '0241234567'
    },
    {
      'id': '4',
      'title': 'Fund Wallet',
      'amount': '500.00',
      'currency': 'GHS',
      'status': 'Completed',
      'type': 'Credit',
      'date': '2024-01-13T16:20:00Z',
      'recipient': 'Bank Transfer'
    },
    {
      'id': '5',
      'title': 'Currency Exchange',
      'amount': '100.00',
      'currency': 'USD',
      'status': 'Completed',
      'type': 'Debit',
      'date': '2024-01-12T11:10:00Z',
      'recipient': 'FX Conversion'
    }
  ];

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_activeFilter == 'All') return _allTransactions;
    return _allTransactions.where((t) {
      if (_activeFilter == 'Credit' || _activeFilter == 'Debit') return t['type'] == _activeFilter;
      return t['status'] == _activeFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildFilterBar(),
              Expanded(child: _buildTransactionList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.royalGold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'TRANSACTIONS',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.search_rounded, color: AppColors.royalGold),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          const SizedBox(height: 8),
          const Text(
            'View and manage all your activity',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter;
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter),
            child: AnimatedContainer(
              duration: 300.ms,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppColors.royalGold : AppColors.royalGold.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isActive ? AppColors.royalGold : AppColors.royalGold.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isActive ? AppColors.black : AppColors.royalGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTransactionList() {
    final list = _filteredTransactions;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.white.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            const Text('No transactions found', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final t = list[index];
        final isCredit = t['type'] == 'Credit';
        return _buildTransactionCard(t, isCredit, index);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> t, bool isCredit, int index) {
    return GestureDetector(
      onTap: () => context.push('/transaction-details'),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t['title'],
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t['recipient'],
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isCredit ? '+' : '-'} ${t['currency']} ${t['amount']}',
                  style: TextStyle(
                    color: isCredit ? AppColors.royalGold : AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('Jan 15, 2024', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 12, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text('10:30 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                _buildStatusBadge(t['status']),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * (index % 5)).ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatusBadge(String status) {
    final isPending = status == 'Pending';
    return Row(
      children: [
        Icon(
          isPending ? Icons.access_time_filled_rounded : Icons.check_circle_rounded,
          size: 14,
          color: isPending ? Colors.orangeAccent : AppColors.royalGold,
        ),
        const SizedBox(width: 4),
        Text(
          status.toUpperCase(),
          style: TextStyle(
            color: isPending ? Colors.orangeAccent : AppColors.royalGold,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
