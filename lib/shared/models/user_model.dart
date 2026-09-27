/// User model — mirrors backend POST /auth/login and GET /users/me response
class UserModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? nationality;
  final String? countryOfResidence;
  final String? profilePhotoUrl;

  // KYC fields
  final String kycStatus; // 'pending' | 'submitted' | 'verified' | 'rejected'
  final int kycTier; // 0, 1, 2
  final bool emailVerified;
  final bool twoFaEnabled;

  // Wallet snapshot (included in login/me response)
  final double? walletBalance;
  final String walletCurrency;
  final bool walletFrozen;

  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.nationality,
    this.countryOfResidence,
    this.profilePhotoUrl,
    this.kycStatus = 'pending',
    this.kycTier = 0,
    this.emailVerified = false,
    this.twoFaEnabled = false,
    this.walletBalance,
    this.walletCurrency = 'GHS',
    this.walletFrozen = false,
    this.createdAt,
  });

  /// Full name convenience getter
  String get fullName => '$firstName $lastName';

  /// Whether user is KYC verified (Tier 2)
  bool get isKycVerified => kycStatus == 'verified' && kycTier >= 2;

  /// Whether user can make transactions (email verified = Tier 1+)
  bool get canTransact => emailVerified && !walletFrozen;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Handle both top-level user object and nested under 'user' key
    final data = json.containsKey('user') ? json['user'] as Map<String, dynamic> : json;
    final wallet = json['wallet'] as Map<String, dynamic>?;

    return UserModel(
      id: data['id'] as String,
      email: data['email'] as String,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      phone: data['phone'] as String?,
      nationality: data['nationality'] as String?,
      countryOfResidence: data['countryOfResidence'] as String?,
      profilePhotoUrl: data['profilePhotoUrl'] as String?,
      kycStatus: data['kycStatus'] as String? ?? 'pending',
      kycTier: (data['kycTier'] as num?)?.toInt() ?? 0,
      emailVerified: data['emailVerified'] as bool? ?? false,
      twoFaEnabled: data['twoFaEnabled'] as bool? ?? false,
      walletBalance: (wallet?['balance'] as num?)?.toDouble() ??
          (data['balance'] as num?)?.toDouble(),
      walletCurrency: wallet?['currency'] as String? ?? 'GHS',
      walletFrozen: wallet?['isFrozen'] as bool? ?? false,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'nationality': nationality,
        'countryOfResidence': countryOfResidence,
        'profilePhotoUrl': profilePhotoUrl,
        'kycStatus': kycStatus,
        'kycTier': kycTier,
        'emailVerified': emailVerified,
        'twoFaEnabled': twoFaEnabled,
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? nationality,
    String? countryOfResidence,
    String? kycStatus,
    int? kycTier,
    bool? emailVerified,
    double? walletBalance,
    bool? walletFrozen,
  }) {
    return UserModel(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      nationality: nationality ?? this.nationality,
      countryOfResidence: countryOfResidence ?? this.countryOfResidence,
      profilePhotoUrl: profilePhotoUrl,
      kycStatus: kycStatus ?? this.kycStatus,
      kycTier: kycTier ?? this.kycTier,
      emailVerified: emailVerified ?? this.emailVerified,
      twoFaEnabled: twoFaEnabled,
      walletBalance: walletBalance ?? this.walletBalance,
      walletCurrency: walletCurrency,
      walletFrozen: walletFrozen ?? this.walletFrozen,
      createdAt: createdAt,
    );
  }
}
