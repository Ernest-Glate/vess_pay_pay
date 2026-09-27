import 'package:flutter/material.dart';

/// Model representing a currency with display information
class Currency {
  final String code;        // ISO 4217 code (e.g., 'USD')
  final String name;        // Full name (e.g., 'United States Dollar')
  final String symbol;      // Symbol (e.g., '$')
  final String flag;        // Emoji flag
  final Color accentColor;  // Theme color for UI

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    required this.accentColor,
  });

  /// Predefined list of supported currencies
  static final List<Currency> supported = [
    const Currency(
      code: 'GHS',
      name: 'Ghanaian Cedi',
      symbol: '₵',
      flag: '🇬🇭',
      accentColor: Color(0xFFD4AF37), // Gold
    ),
    const Currency(
      code: 'USD',
      name: 'United States Dollar',
      symbol: r'$',
      flag: '🇺🇸',
      accentColor: Color(0xFF42A5F5), // Blue
    ),
    const Currency(
      code: 'GBP',
      name: 'British Pound Sterling',
      symbol: '£',
      flag: '🇬🇧',
      accentColor: Color(0xFF7E57C2), // Purple
    ),
    const Currency(
      code: 'EUR',
      name: 'Euro',
      symbol: '€',
      flag: '🇪🇺',
      accentColor: Color(0xFF26A69A), // Teal
    ),
    const Currency(
      code: 'NGN',
      name: 'Nigerian Naira',
      symbol: '₦',
      flag: '🇳🇬',
      accentColor: Color(0xFF66BB6A), // Green
    ),
    const Currency(
      code: 'KES',
      name: 'Kenyan Shilling',
      symbol: 'KSh',
      flag: '🇰🇪',
      accentColor: Color(0xFFEF5350), // Red
    ),
    const Currency(
      code: 'XOF',
      name: 'West African CFA Franc',
      symbol: 'CFA',
      flag: '🌍',
      accentColor: Color(0xFFFF9800), // Orange
    ),
    const Currency(
      code: 'XAF',
      name: 'Central African CFA Franc',
      symbol: 'FCFA',
      flag: '🌍',
      accentColor: Color(0xFF8D6E63), // Brown
    ),
    const Currency(
      code: 'TZS',
      name: 'Tanzanian Shilling',
      symbol: 'TSh',
      flag: '🇹🇿',
      accentColor: Color(0xFF29B6F6), // Light blue
    ),
    const Currency(
      code: 'UGX',
      name: 'Ugandan Shilling',
      symbol: 'USh',
      flag: '🇺🇬',
      accentColor: Color(0xFFFFCA28), // Yellow
    ),
    const Currency(
      code: 'ZAR',
      name: 'South African Rand',
      symbol: 'R',
      flag: '🇿🇦',
      accentColor: Color(0xFF4CAF50), // Green
    ),
    const Currency(
      code: 'EGP',
      name: 'Egyptian Pound',
      symbol: 'E£',
      flag: '🇪🇬',
      accentColor: Color(0xFFAB47BC), // Purple
    ),
    const Currency(
      code: 'RWF',
      name: 'Rwandan Franc',
      symbol: 'RF',
      flag: '🇷🇼',
      accentColor: Color(0xFF00BCD4), // Cyan
    ),
    const Currency(
      code: 'ETB',
      name: 'Ethiopian Birr',
      symbol: 'Br',
      flag: '🇪🇹',
      accentColor: Color(0xFF689F38), // Light green
    ),
  ];

  /// Get currency by code
  static Currency? fromCode(String code) {
    try {
      return supported.firstWhere((c) => c.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get currency symbol by code (fallback helper)
  static String getSymbol(String code) {
    return fromCode(code)?.symbol ?? '';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency && runtimeType == other.runtimeType && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
