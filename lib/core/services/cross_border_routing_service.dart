import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  DATA MODELS
// ══════════════════════════════════════════════════════════════════════════════

/// Represents a resolved payout route through Ecobank's Rapidtransfer engine.
class PayoutRoute {
  /// Origin → Destination corridor (e.g., "GH→CI")
  final String corridor;

  /// Target telco clearing network (e.g., "Orange Money", "MTN MoMo")
  final String clearingNetwork;

  /// Settlement rail used (always Ecobank Rapidtransfer for cross-border)
  final String settlementRail;

  /// Target country name
  final String targetCountry;

  /// ISO country code
  final String targetCountryCode;

  /// Estimated arrival time in minutes
  final int estimatedMinutes;

  /// Applicable corridor fee (flat + percentage)
  final double corridorFeeFlat;
  final double corridorFeePercent;

  /// Resolved payout currency
  final String payoutCurrency;

  /// Exchange rate applied for the corridor
  final double exchangeRate;

  PayoutRoute({
    required this.corridor,
    required this.clearingNetwork,
    required this.settlementRail,
    required this.targetCountry,
    required this.targetCountryCode,
    required this.estimatedMinutes,
    required this.corridorFeeFlat,
    required this.corridorFeePercent,
    required this.payoutCurrency,
    required this.exchangeRate,
  });

  /// Total fee for a given amount
  double totalFee(double amount) => corridorFeeFlat + (amount * corridorFeePercent / 100);

  /// Net amount after fees
  double netPayout(double amount) => (amount - totalFee(amount)) * exchangeRate;
}

/// Represents a supported country + mobile money networks
class SupportedCorridor {
  final String countryName;
  final String countryCode;
  final String flag;
  final String currency;
  final List<String> networks;

  const SupportedCorridor({
    required this.countryName,
    required this.countryCode,
    required this.flag,
    required this.currency,
    required this.networks,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
//  CROSS-BORDER ROUTING SERVICE
// ══════════════════════════════════════════════════════════════════════════════

class CrossBorderRoutingService {
  final Logger _logger = Logger(printer: SimplePrinter());

  // ── SUPPORTED CORRIDORS ──────────────────────────────────────────────────
  // Pan-African coverage: 33 nations (representative subset shown)

  static const List<SupportedCorridor> supportedCorridors = [
    // West Africa
    SupportedCorridor(countryName: 'Ghana', countryCode: 'GH', flag: '🇬🇭', currency: 'GHS', networks: ['MTN MoMo', 'Vodafone Cash', 'AirtelTigo Money']),
    SupportedCorridor(countryName: 'Nigeria', countryCode: 'NG', flag: '🇳🇬', currency: 'NGN', networks: ['OPay', 'Palmpay', 'Bank Transfer']),
    SupportedCorridor(countryName: 'Senegal', countryCode: 'SN', flag: '🇸🇳', currency: 'XOF', networks: ['Orange Money', 'Wave', 'Free Money']),
    SupportedCorridor(countryName: 'Côte d\'Ivoire', countryCode: 'CI', flag: '🇨🇮', currency: 'XOF', networks: ['Orange Money', 'MTN MoMo', 'Moov Money']),
    SupportedCorridor(countryName: 'Mali', countryCode: 'ML', flag: '🇲🇱', currency: 'XOF', networks: ['Orange Money', 'Moov Money']),
    SupportedCorridor(countryName: 'Burkina Faso', countryCode: 'BF', flag: '🇧🇫', currency: 'XOF', networks: ['Orange Money', 'Moov Money']),
    SupportedCorridor(countryName: 'Guinea', countryCode: 'GN', flag: '🇬🇳', currency: 'GNF', networks: ['Orange Money', 'MTN MoMo']),
    SupportedCorridor(countryName: 'Sierra Leone', countryCode: 'SL', flag: '🇸🇱', currency: 'SLL', networks: ['Orange Money', 'Afrimoney']),
    SupportedCorridor(countryName: 'Togo', countryCode: 'TG', flag: '🇹🇬', currency: 'XOF', networks: ['T-Money', 'Flooz']),
    SupportedCorridor(countryName: 'Benin', countryCode: 'BJ', flag: '🇧🇯', currency: 'XOF', networks: ['MTN MoMo', 'Moov Money']),
    SupportedCorridor(countryName: 'Niger', countryCode: 'NE', flag: '🇳🇪', currency: 'XOF', networks: ['Airtel Money', 'Orange Money']),
    SupportedCorridor(countryName: 'Gambia', countryCode: 'GM', flag: '🇬🇲', currency: 'GMD', networks: ['Afrimoney', 'QMoney']),
    SupportedCorridor(countryName: 'Liberia', countryCode: 'LR', flag: '🇱🇷', currency: 'LRD', networks: ['Orange Money', 'Lonestar Money']),
    SupportedCorridor(countryName: 'Cape Verde', countryCode: 'CV', flag: '🇨🇻', currency: 'CVE', networks: ['Bank Transfer']),

    // East Africa
    SupportedCorridor(countryName: 'Kenya', countryCode: 'KE', flag: '🇰🇪', currency: 'KES', networks: ['M-Pesa', 'Airtel Money']),
    SupportedCorridor(countryName: 'Tanzania', countryCode: 'TZ', flag: '🇹🇿', currency: 'TZS', networks: ['M-Pesa', 'Tigo Pesa', 'Airtel Money']),
    SupportedCorridor(countryName: 'Uganda', countryCode: 'UG', flag: '🇺🇬', currency: 'UGX', networks: ['MTN MoMo', 'Airtel Money']),
    SupportedCorridor(countryName: 'Rwanda', countryCode: 'RW', flag: '🇷🇼', currency: 'RWF', networks: ['MTN MoMo', 'Airtel Money']),
    SupportedCorridor(countryName: 'Burundi', countryCode: 'BI', flag: '🇧🇮', currency: 'BIF', networks: ['Ecocash', 'Lumicash']),
    SupportedCorridor(countryName: 'Ethiopia', countryCode: 'ET', flag: '🇪🇹', currency: 'ETB', networks: ['Telebirr', 'M-Birr']),

    // Southern Africa
    SupportedCorridor(countryName: 'South Africa', countryCode: 'ZA', flag: '🇿🇦', currency: 'ZAR', networks: ['FNB eWallet', 'Capitec', 'Bank Transfer']),
    SupportedCorridor(countryName: 'Zambia', countryCode: 'ZM', flag: '🇿🇲', currency: 'ZMW', networks: ['MTN MoMo', 'Airtel Money']),
    SupportedCorridor(countryName: 'Zimbabwe', countryCode: 'ZW', flag: '🇿🇼', currency: 'ZWL', networks: ['Ecocash', 'OneMoney']),
    SupportedCorridor(countryName: 'Malawi', countryCode: 'MW', flag: '🇲🇼', currency: 'MWK', networks: ['Airtel Money', 'TNM Mpamba']),
    SupportedCorridor(countryName: 'Mozambique', countryCode: 'MZ', flag: '🇲🇿', currency: 'MZN', networks: ['M-Pesa', 'e-Mola']),
    SupportedCorridor(countryName: 'Botswana', countryCode: 'BW', flag: '🇧🇼', currency: 'BWP', networks: ['Orange Money', 'MyZaka']),
    SupportedCorridor(countryName: 'Namibia', countryCode: 'NA', flag: '🇳🇦', currency: 'NAD', networks: ['Bank Transfer']),

    // Central Africa
    SupportedCorridor(countryName: 'Cameroon', countryCode: 'CM', flag: '🇨🇲', currency: 'XAF', networks: ['MTN MoMo', 'Orange Money']),
    SupportedCorridor(countryName: 'DR Congo', countryCode: 'CD', flag: '🇨🇩', currency: 'CDF', networks: ['M-Pesa', 'Orange Money', 'Airtel Money']),
    SupportedCorridor(countryName: 'Congo', countryCode: 'CG', flag: '🇨🇬', currency: 'XAF', networks: ['MTN MoMo', 'Airtel Money']),
    SupportedCorridor(countryName: 'Gabon', countryCode: 'GA', flag: '🇬🇦', currency: 'XAF', networks: ['Airtel Money']),
    SupportedCorridor(countryName: 'Chad', countryCode: 'TD', flag: '🇹🇩', currency: 'XAF', networks: ['Airtel Money', 'Tigo Cash']),

    // North Africa
    SupportedCorridor(countryName: 'Egypt', countryCode: 'EG', flag: '🇪🇬', currency: 'EGP', networks: ['Vodafone Cash', 'Bank Transfer']),
    SupportedCorridor(countryName: 'Morocco', countryCode: 'MA', flag: '🇲🇦', currency: 'MAD', networks: ['Bank Transfer', 'Cash Plus']),
  ];

  // ── ROUTE RESOLUTION ─────────────────────────────────────────────────────

  /// Resolves a single wallet transaction into target payout nodes across
  /// different national telco networks via Ecobank Rapidtransfer engine.
  ///
  /// In production, this calls /api/v1/rapidtransfer/resolve-route
  Future<PayoutRoute> resolvePayoutRoute({
    required double amount,
    required String sourceCurrency,
    required String targetCountryCode,
    required String targetNetwork,
  }) async {
    _logger.i('Resolving payout route: $sourceCurrency → $targetCountryCode via $targetNetwork');

    // Simulate Rapidtransfer API call
    await Future.delayed(const Duration(milliseconds: 600));

    final targetCorridor = supportedCorridors.firstWhere(
      (c) => c.countryCode == targetCountryCode,
      orElse: () => throw Exception('Unsupported corridor: $targetCountryCode'),
    );

    // Validate network availability
    if (!targetCorridor.networks.contains(targetNetwork)) {
      throw Exception('Network $targetNetwork not available in ${targetCorridor.countryName}');
    }

    // Determine corridor code (origin is always GH for VessPay)
    final corridor = 'GH→$targetCountryCode';

    // Simulated exchange rates (in production, pulled from Ecobank treasury)
    final exchangeRate = _getCorridorExchangeRate(sourceCurrency, targetCorridor.currency);

    // Corridor-specific fees
    final fees = _getCorridorFees(targetCountryCode);

    final route = PayoutRoute(
      corridor: corridor,
      clearingNetwork: targetNetwork,
      settlementRail: 'Ecobank Rapidtransfer',
      targetCountry: targetCorridor.countryName,
      targetCountryCode: targetCountryCode,
      estimatedMinutes: _getEstimatedArrival(targetCountryCode),
      corridorFeeFlat: fees['flat']!,
      corridorFeePercent: fees['percent']!,
      payoutCurrency: targetCorridor.currency,
      exchangeRate: exchangeRate,
    );

    _logger.i('Route resolved: $corridor via $targetNetwork | '
        'Rate: $exchangeRate | ETA: ${route.estimatedMinutes}m | '
        'Fee: \$${route.totalFee(amount).toStringAsFixed(2)}');

    return route;
  }

  /// Resolve a multi-destination payout (one wallet transaction → multiple
  /// payout nodes across different national telco networks)
  Future<List<PayoutRoute>> resolveMultiDestinationPayout({
    required double totalAmount,
    required String sourceCurrency,
    required List<Map<String, dynamic>> destinations,
  }) async {
    _logger.i('Resolving multi-destination payout: ${destinations.length} targets');

    final routes = <PayoutRoute>[];
    for (final dest in destinations) {
      final route = await resolvePayoutRoute(
        amount: dest['amount'] as double,
        sourceCurrency: sourceCurrency,
        targetCountryCode: dest['countryCode'] as String,
        targetNetwork: dest['network'] as String,
      );
      routes.add(route);
    }

    return routes;
  }

  /// Returns supported countries and their available networks
  List<SupportedCorridor> getSupportedCorridors() {
    return supportedCorridors;
  }

  /// Returns available networks for a given country
  List<String> getNetworksForCountry(String countryCode) {
    try {
      return supportedCorridors
          .firstWhere((c) => c.countryCode == countryCode)
          .networks;
    } catch (_) {
      return [];
    }
  }

  // ── INTERNAL HELPERS ─────────────────────────────────────────────────────

  double _getCorridorExchangeRate(String from, String to) {
    // Simulated rates — in production, sourced from Ecobank Treasury API
    final rates = {
      'GHS_NGN': 82.5,
      'GHS_KES': 9.45,
      'GHS_TZS': 163.0,
      'GHS_UGX': 243.0,
      'GHS_XOF': 42.5,
      'GHS_XAF': 42.5,
      'GHS_ZAR': 1.18,
      'GHS_RWF': 82.0,
      'GHS_CDF': 165.0,
      'GHS_ETB': 3.65,
      'GHS_EGP': 2.52,
      'GHS_ZMW': 1.72,
      'GHS_MZN': 4.15,
      'GHS_MWK': 112.0,
      'USD_GHS': 12.45,
      'GBP_GHS': 15.80,
    };

    final key = '${from}_$to';
    return rates[key] ?? 1.0;
  }

  Map<String, double> _getCorridorFees(String targetCountryCode) {
    // Corridor-specific fee tiers (flat USD + percentage)
    final westAfrica = {'flat': 0.50, 'percent': 1.5};
    final eastAfrica = {'flat': 1.00, 'percent': 2.0};
    final southernAfrica = {'flat': 1.50, 'percent': 2.5};
    final centralAfrica = {'flat': 1.00, 'percent': 2.0};
    final northAfrica = {'flat': 2.00, 'percent': 3.0};

    final regionMap = {
      'GH': westAfrica, 'NG': westAfrica, 'SN': westAfrica, 'CI': westAfrica,
      'ML': westAfrica, 'BF': westAfrica, 'GN': westAfrica, 'SL': westAfrica,
      'TG': westAfrica, 'BJ': westAfrica, 'NE': westAfrica, 'GM': westAfrica,
      'LR': westAfrica, 'CV': westAfrica,
      'KE': eastAfrica, 'TZ': eastAfrica, 'UG': eastAfrica, 'RW': eastAfrica,
      'BI': eastAfrica, 'ET': eastAfrica,
      'ZA': southernAfrica, 'ZM': southernAfrica, 'ZW': southernAfrica,
      'MW': southernAfrica, 'MZ': southernAfrica, 'BW': southernAfrica, 'NA': southernAfrica,
      'CM': centralAfrica, 'CD': centralAfrica, 'CG': centralAfrica, 'GA': centralAfrica, 'TD': centralAfrica,
      'EG': northAfrica, 'MA': northAfrica,
    };

    return regionMap[targetCountryCode] ?? eastAfrica;
  }

  int _getEstimatedArrival(String targetCountryCode) {
    // ETA in minutes based on corridor
    final instantCorridors = ['GH', 'NG', 'KE', 'TZ', 'UG', 'CI', 'SN'];
    if (instantCorridors.contains(targetCountryCode)) return 2;

    final fastCorridors = ['RW', 'CM', 'BF', 'ML', 'TG', 'BJ', 'ZM'];
    if (fastCorridors.contains(targetCountryCode)) return 5;

    return 15; // Standard corridors
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  RIVERPOD PROVIDERS
// ══════════════════════════════════════════════════════════════════════════════

final crossBorderRoutingProvider = Provider<CrossBorderRoutingService>((ref) {
  return CrossBorderRoutingService();
});
