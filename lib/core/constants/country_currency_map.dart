/// Maps African countries to their local currencies.
///
/// Used to determine the primary wallet currency during registration
/// and in the wallet screen. If a user's `countryOfResidence` is found
/// in this map, they get a local currency wallet + USD holding.
/// If not found (diaspora), they default to USD only.
class CountryCurrencyMap {
  CountryCurrencyMap._();

  /// Country name (lowercase) → ISO 4217 currency code
  static const Map<String, String> _africaMap = {
    // West Africa
    'ghana': 'GHS',
    'nigeria': 'NGN',
    'senegal': 'XOF',
    'ivory coast': 'XOF',
    "cote d'ivoire": 'XOF',
    'mali': 'XOF',
    'burkina faso': 'XOF',
    'benin': 'XOF',
    'togo': 'XOF',
    'niger': 'XOF',
    'guinea-bissau': 'XOF',
    'guinea': 'GNF',
    'sierra leone': 'SLL',
    'liberia': 'LRD',
    'gambia': 'GMD',
    'cape verde': 'CVE',

    // East Africa
    'kenya': 'KES',
    'tanzania': 'TZS',
    'uganda': 'UGX',
    'rwanda': 'RWF',
    'ethiopia': 'ETB',
    'somalia': 'SOS',

    // Central Africa
    'cameroon': 'XAF',
    'chad': 'XAF',
    'central african republic': 'XAF',
    'republic of congo': 'XAF',
    'gabon': 'XAF',
    'equatorial guinea': 'XAF',
    'democratic republic of congo': 'CDF',

    // Southern Africa
    'south africa': 'ZAR',
    'zambia': 'ZMW',
    'zimbabwe': 'ZWL',
    'botswana': 'BWP',
    'mozambique': 'MZN',
    'malawi': 'MWK',
    'namibia': 'NAD',

    // North Africa
    'egypt': 'EGP',
    'morocco': 'MAD',
    'tunisia': 'TND',
    'algeria': 'DZD',
  };

  /// Phone prefix → ISO 4217 currency code (for future phone-based registration)
  static const Map<String, String> _phonePrefixMap = {
    '+233': 'GHS', // Ghana
    '+234': 'NGN', // Nigeria
    '+254': 'KES', // Kenya
    '+255': 'TZS', // Tanzania
    '+256': 'UGX', // Uganda
    '+250': 'RWF', // Rwanda
    '+251': 'ETB', // Ethiopia
    '+27': 'ZAR',  // South Africa
    '+237': 'XAF', // Cameroon
    '+221': 'XOF', // Senegal
    '+225': 'XOF', // Ivory Coast
    '+20': 'EGP',  // Egypt
    '+212': 'MAD', // Morocco
    '+260': 'ZMW', // Zambia
  };

  /// Resolve the primary currency from a country name.
  /// Returns null if the country is not African (diaspora user).
  static String? fromCountry(String? country) {
    if (country == null || country.isEmpty) return null;
    return _africaMap[country.toLowerCase().trim()];
  }

  /// Resolve the primary currency from a phone prefix.
  /// Returns null if prefix is not African.
  static String? fromPhonePrefix(String? phone) {
    if (phone == null || phone.isEmpty) return null;
    for (final entry in _phonePrefixMap.entries) {
      if (phone.startsWith(entry.key)) return entry.value;
    }
    return null;
  }

  /// Determine if a country is African.
  static bool isAfricanCountry(String? country) {
    if (country == null) return false;
    return _africaMap.containsKey(country.toLowerCase().trim());
  }

  /// Get the primary currency for a user based on their profile.
  /// African user → local currency, Diaspora → USD.
  static String resolvePrimaryCurrency({
    String? countryOfResidence,
    String? phone,
  }) {
    // Try country first
    final fromCtry = fromCountry(countryOfResidence);
    if (fromCtry != null) return fromCtry;

    // Fallback to phone prefix
    final fromPh = fromPhonePrefix(phone);
    if (fromPh != null) return fromPh;

    // Default: diaspora
    return 'USD';
  }

  /// Whether a user should see a secondary USD holding wallet.
  /// True for African users (they need USD to hedge inflation).
  /// False for diaspora (they're already in USD).
  static bool shouldShowUsdHolding({
    String? countryOfResidence,
    String? phone,
  }) {
    final primary = resolvePrimaryCurrency(
      countryOfResidence: countryOfResidence,
      phone: phone,
    );
    return primary != 'USD';
  }
}
