import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_service.dart';
import '../models/currency_model.dart';
import 'shimmer_loading.dart';

/// Modern accessible currency selector bottom sheet
/// 
/// Features:
/// - Searchable list with real-time filtering
/// - Keyboard navigation support
/// - WCAG 2.2 AA compliant with semantic labels
/// - Shimmer loading placeholders
/// - Micro-animations (<200ms)
/// - Dark/light mode support
/// - 8-pt grid alignment
class CurrencySelectorWidget extends StatefulWidget {
  final String? currentCurrency;
  final Function(Currency) onCurrencySelected;
  final bool isLoading;

  const CurrencySelectorWidget({
    super.key,
    this.currentCurrency,
    required this.onCurrencySelected,
    this.isLoading = false,
  });

  @override
  State<CurrencySelectorWidget> createState() => _CurrencySelectorWidgetState();
}

class _CurrencySelectorWidgetState extends State<CurrencySelectorWidget> {
  final _searchController = TextEditingController();
  List<Currency> _filteredCurrencies = Currency.supported;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCurrencies);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = Currency.supported;
      } else {
        _filteredCurrencies = Currency.supported.where((currency) {
          return currency.code.toLowerCase().contains(query) ||
                 currency.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  void _selectCurrency(Currency currency) {
    HapticService.light();
    widget.onCurrencySelected(currency);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.verticalGradient,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'SELECT CURRENCY',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.white),
                    tooltip: 'Close currency selector',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search currency...',
                  hintStyle: TextStyle(color: AppColors.white.withValues(alpha: 0.4)),
                  prefixIcon: Icon(Icons.search_rounded, color: AppColors.royalGold.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: AppColors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.royalGold, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
            
            const SizedBox(height: 16),
            
            // Currency list
            Flexible(
              child: widget.isLoading 
                ? _buildLoadingState()
                : _filteredCurrencies.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredCurrencies.length,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        itemBuilder: (context, index) {
                          final currency = _filteredCurrencies[index];
                          final isSelected = currency.code == widget.currentCurrency;
                          
                          return Semantics(
                            label: 'Select ${currency.name}, ${currency.code}',
                            selected: isSelected,
                            button: true,
                            child: _buildCurrencyTile(currency, isSelected, index),
                          );
                        },
                      ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyTile(Currency currency, bool isSelected, int index) {
    return InkWell(
      onTap: () => _selectCurrency(currency),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppColors.royalGold.withValues(alpha: 0.1)
            : AppColors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? AppColors.royalGold.withValues(alpha: 0.3)
              : AppColors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Flag emoji
            Text(
              currency.flag,
              style: const TextStyle(fontSize: 32),
            ),
            
            const SizedBox(width: 16),
            
            // Currency info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.code,
                    style: TextStyle(
                      color: isSelected ? AppColors.royalGold : AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currency.name,
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            // Selection indicator
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.royalGold,
                  size: 20,
                ),
              ).animate().scale(duration: 200.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
    ).animate(delay: (index * 30).ms).fadeIn(duration: 150.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: const ShimmerLoading(
            width: double.infinity,
            height: 72,
            borderRadius: 16,
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No currencies found',
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with a different term',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show currency selector bottom sheet
Future<Currency?> showCurrencySelector({
  required BuildContext context,
  String? currentCurrency,
  bool isLoading = false,
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => CurrencySelectorWidget(
        currentCurrency: currentCurrency,
        isLoading: isLoading,
        onCurrencySelected: (currency) {
          Navigator.pop(context, currency);
        },
      ),
    ),
  );
}
