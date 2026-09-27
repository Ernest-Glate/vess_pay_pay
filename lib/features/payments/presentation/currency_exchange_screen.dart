import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatters.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/currency_selector_widget.dart';
import '../../../shared/models/currency_model.dart';
import '../data/exchange_provider.dart';
import '../../wallet/data/wallet_provider.dart';

class CurrencyExchangeScreen extends ConsumerStatefulWidget {
  const CurrencyExchangeScreen({super.key});

  @override
  ConsumerState<CurrencyExchangeScreen> createState() => _CurrencyExchangeScreenState();
}

class _CurrencyExchangeScreenState extends ConsumerState<CurrencyExchangeScreen> {
  final _amountController = TextEditingController();
  String _fromCurrency = 'GHS';
  String _toCurrency = 'USD';

  // Transaction fee percentage
  static const double _feePercentage = 3.0;

  // ── Countdown Timer State ──────────────────────────────────────────────
  static const int _rateLockDuration = 60;
  int _countdownSeconds = _rateLockDuration;
  Timer? _countdownTimer;
  bool _isRateRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Initial rate fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(exchangeProvider.notifier).refreshRates();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = _rateLockDuration;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdownSeconds--;
      });
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _refreshRate();
      }
    });
  }

  Future<void> _refreshRate() async {
    setState(() => _isRateRefreshing = true);
    await ref.read(exchangeProvider.notifier).refreshRates();
    if (mounted) {
      setState(() => _isRateRefreshing = false);
      _startCountdown();
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final walletState = ref.watch(walletProvider);
    final exchangeRates = ref.watch(exchangeProvider.notifier);
    final rate = exchangeRates.getRate(_fromCurrency, _toCurrency);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'EXCHANGE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
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
                // Market Chart
                _buildMarketChart(context, rate),

                const SizedBox(height: 20),

                // ── Rate Lock Countdown Timer ──────────────────
                _buildCountdownTimer(rate),

                const SizedBox(height: 24),

                // Exchange Form
                GlassContainer(
                  borderRadius: 24,
                  child: Column(
                    children: [
                      _buildCurrencyInput(
                        label: 'You Send',
                        currency: _fromCurrency,
                        controller: _amountController,
                        isInput: true,
                      ),

                      const SizedBox(height: 12),

                      Semantics(
                        label: 'Swap currencies',
                        button: true,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              final temp = _fromCurrency;
                              _fromCurrency = _toCurrency;
                              _toCurrency = temp;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.forestDepths,
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: const Icon(Icons.swap_vert_rounded, color: AppColors.royalGold, size: 28),
                          ),
                        ),
                      ).animate(key: ValueKey(_fromCurrency)).rotate(duration: 400.ms, curve: Curves.easeInOutBack),

                      const SizedBox(height: 12),

                      _buildCurrencyInput(
                        label: 'You Receive',
                        currency: _toCurrency,
                        amount: _amountController.text.isEmpty
                            ? '0.00'
                            : ((double.tryParse(_amountController.text) ?? 0) * rate).toStringAsFixed(2),
                        isInput: false,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Rate Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rate: 1 $_fromCurrency = ${CurrencyFormatters.formatRate(rate)} $_toCurrency',
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                    Text(
                      'Fee: ${CurrencyFormatters.formatFeeAsDecimal(_feePercentage)}',
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // Confirm Button — shows locked rate + countdown
                Semantics(
                  label: 'Confirm exchange transaction',
                  button: true,
                  child: Builder(
                    builder: (_) {
                      final quote = ref.read(exchangeProvider.notifier).currentQuote;
                      final hasQuote = quote != null && !quote.isExpired;
                      final isLow = _countdownSeconds <= 10;

                      if (_isRateRefreshing) {
                        return AppButton(
                          label: 'Refreshing Rate...',
                          disabled: true,
                          onPress: () {},
                        );
                      }

                      if (hasQuote) {
                        // Phase 2: Execute the locked quote
                        return AppButton(
                          label: 'Confirm at ${CurrencyFormatters.formatRate(quote.effectiveRate)} — ${_countdownSeconds}s',
                          icon: isLow ? Icons.timer_off_rounded : Icons.lock_clock_rounded,
                          disabled: _countdownSeconds <= 0,
                          onPress: () => _executeLockedQuote(quote.quoteId),
                        );
                      }

                      // Phase 1: Lock a quote
                      return AppButton(
                        label: 'Lock Rate & Convert',
                        icon: Icons.lock_rounded,
                        onPress: () => _lockAndConvert(rate),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                _buildBalanceInfo(context, walletState.balance, walletState.currency),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  COUNTDOWN TIMER WIDGET
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCountdownTimer(double rate) {
    final progress = _countdownSeconds / _rateLockDuration;
    final isLow = _countdownSeconds <= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: (isLow ? AppColors.warning : AppColors.royalGold).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isLow ? AppColors.warning : AppColors.royalGold).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          // Circular countdown arc
          SizedBox(
            width: 36,
            height: 36,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _isRateRefreshing ? null : progress,
                  strokeWidth: 3,
                  backgroundColor: AppColors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isLow ? AppColors.warning : AppColors.royalGold,
                  ),
                ),
                Text(
                  _isRateRefreshing ? '...' : '$_countdownSeconds',
                  style: TextStyle(
                    color: isLow ? AppColors.warning : AppColors.royalGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRateRefreshing
                      ? 'Fetching fresh treasury rate...'
                      : 'Ecobank Treasury Rate locked for ${_countdownSeconds}s',
                  style: TextStyle(
                    color: isLow ? AppColors.warning : AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Wholesale rate · Anti-arbitrage protection',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isRateRefreshing ? null : _refreshRate,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.04),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: _isRateRefreshing
                    ? AppColors.textSecondary.withValues(alpha: 0.3)
                    : AppColors.royalGold,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PHASE 1: LOCK QUOTE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _lockAndConvert(double rate) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Check balance
    final walletState = ref.read(walletProvider);
    if (amount > walletState.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    try {
      // Lock a quote via POST /fx/calculate
      final quote = await ref.read(exchangeProvider.notifier).lockQuote(
        fromCurrency: _fromCurrency,
        toCurrency: _toCurrency,
        amount: amount,
      );

      if (mounted) {
        // Restart countdown from the quote's lock window
        _countdownTimer?.cancel();
        _countdownSeconds = quote.lockWindowSeconds;
        _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _countdownSeconds--;
          });
          if (_countdownSeconds <= 0) {
            timer.cancel();
            // Quote expired — clear it and show refresh prompt
            ref.read(exchangeProvider.notifier).clearQuote();
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Rate expired. Tap to get a fresh quote.'),
                action: SnackBarAction(
                  label: 'REFRESH',
                  onPressed: _refreshRate,
                ),
              ),
            );
          }
        });

        setState(() {}); // Rebuild to show locked button state

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔒 Rate locked at ${quote.effectiveRate.toStringAsFixed(4)} for 60 seconds',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to lock rate: $e')),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PHASE 2: EXECUTE LOCKED QUOTE
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _executeLockedQuote(String quoteId) async {
    try {
      final result = await ref.read(exchangeProvider.notifier).executeQuote(quoteId);

      _countdownTimer?.cancel();

      if (mounted) {
        context.pushReplacement(
          '/exchange-success',
          extra: {
            'fromCurrency': result.fromCurrency,
            'toCurrency': result.toCurrency,
            'fromAmount': result.amountDebited,
            'toAmount': result.amountCredited,
            'rate': result.effectiveRate,
            'timestamp': result.executedAt,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        final isExpired = e.toString().contains('QUOTE_EXPIRED');

        if (isExpired) {
          ref.read(exchangeProvider.notifier).clearQuote();
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Quote expired. Getting fresh rate...'),
              backgroundColor: Color(0xFFE65100),
            ),
          );
          _refreshRate();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exchange failed: $e')),
          );
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MARKET CHART
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildMarketChart(BuildContext context, double rate) {
    return GlassContainer(
      height: 180,
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_fromCurrency/$_toCurrency',
                    style: const TextStyle(color: Colors.white30, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    rate.toStringAsFixed(4),
                    style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: AppColors.success, size: 14),
                    SizedBox(width: 4),
                    Text('+0.24%', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            height: 60,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 1.5),
                      FlSpot(2, 1.2),
                      FlSpot(3, 2),
                      FlSpot(4, 1.8),
                      FlSpot(5, 2.5),
                      FlSpot(6, 2.2),
                    ],
                    isCurved: true,
                    color: AppColors.royalGold,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.royalGold.withValues(alpha: 0.2),
                          AppColors.royalGold.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CURRENCY INPUT
  // ══════════════════════════════════════════════════════════════════════════

  void _showCurrencyPicker(bool isFrom) async {
    final selectedCurrency = await showCurrencySelector(
      context: context,
      currentCurrency: isFrom ? _fromCurrency : _toCurrency,
    );

    if (selectedCurrency != null) {
      setState(() {
        if (isFrom) {
          _fromCurrency = selectedCurrency.code;
        } else {
          _toCurrency = selectedCurrency.code;
        }
      });
      // Restart countdown when currencies change
      _refreshRate();
    }
  }

  Widget _buildCurrencyInput({
    required String label,
    required String currency,
    TextEditingController? controller,
    String? amount,
    bool isInput = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1),
                ),
                const SizedBox(height: 8),
                if (isInput)
                  TextField(
                    controller: controller,
                    onChanged: (val) => setState(() {}),
                    style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )
                else
                  Text(
                    amount ?? '0.00',
                    style: const TextStyle(color: AppColors.royalGold, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showCurrencyPicker(isInput),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    Currency.fromCode(currency)?.flag ?? '',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    currency,
                    style: const TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.royalGold, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(BuildContext context, double balance, String currency) {
    final symbol = currency == 'GHS' ? '₵' : currency;
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wallet_rounded, color: AppColors.royalGold, size: 16),
          const SizedBox(width: 8),
          Text(
            'BALANCE: $symbol${balance.toStringAsFixed(2)} $currency',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
