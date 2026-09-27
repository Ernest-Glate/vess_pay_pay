import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';
import '../data/auth_provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
//  LOGIN MODE
// ══════════════════════════════════════════════════════════════════════════════

enum LoginMode { email, phone }

// ══════════════════════════════════════════════════════════════════════════════
//  COUNTRY CODE MODEL
// ══════════════════════════════════════════════════════════════════════════════

class _CountryCode {
  final String code;
  final String country;
  final String flag;

  const _CountryCode(this.code, this.country, this.flag);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  LoginMode _loginMode = LoginMode.email;
  _CountryCode _selectedCountryCode = _countryCodes.first;

  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _biometricAttempted = false;

  // ── Pan-African telco country codes ──────────────────────────────────────
  static const List<_CountryCode> _countryCodes = [
    _CountryCode('+233', 'Ghana', '🇬🇭'),
    _CountryCode('+234', 'Nigeria', '🇳🇬'),
    _CountryCode('+254', 'Kenya', '🇰🇪'),
    _CountryCode('+27', 'South Africa', '🇿🇦'),
    _CountryCode('+255', 'Tanzania', '🇹🇿'),
    _CountryCode('+250', 'Rwanda', '🇷🇼'),
    _CountryCode('+256', 'Uganda', '🇺🇬'),
    _CountryCode('+221', 'Senegal', '🇸🇳'),
    _CountryCode('+225', 'Côte d\'Ivoire', '🇨🇮'),
    _CountryCode('+237', 'Cameroon', '🇨🇲'),
    _CountryCode('+1', 'United States', '🇺🇸'),
    _CountryCode('+44', 'United Kingdom', '🇬🇧'),
  ];

  @override
  void initState() {
    super.initState();
    // Auto-fire biometric auth on screen load (mobile only)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptAutoBiometric();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BIOMETRIC AUTO-TRIGGER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _attemptAutoBiometric() async {
    if (kIsWeb || _biometricAttempted) return;
    _biometricAttempted = true;

    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) return;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) return;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to VessPay',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        // TODO: Replace with stored-credential login once secure storage is wired
        // For now, show success and let user proceed with credentials
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verified — enter credentials to continue'),
            backgroundColor: AppColors.deepGreen2,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      // Silently fail — biometric is optional, fall back to manual login
      debugPrint('Biometric auto-trigger failed: $e');
    }
  }

  Future<void> _handleBiometrics() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrics not available on this device')),
          );
        }
        return;
      }

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to VessPay',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (didAuthenticate && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Biometric verified — enter credentials to continue'),
            backgroundColor: AppColors.deepGreen2,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric error: ${e.toString()}')),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DEMO LOGIN HANDLER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handleDemoLogin() async {
    // Pre-fill demo credentials visually so user can see them
    setState(() {
      _loginMode = LoginMode.email;
      _emailController.text = 'demo@vesspay.com';
      _passwordController.text = 'Demo@1234';
    });

    // Brief pause so user sees the fields populate before login fires
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    await ref.read(authProvider.notifier).login(
      email: 'demo@vesspay.com',
      password: 'Demo@1234',
    );

    final authState = ref.read(authProvider);
    if (mounted && authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIN HANDLER
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _handleLogin() async {
    final credential = _loginMode == LoginMode.email
        ? _emailController.text.trim()
        : '${_selectedCountryCode.code}${_phoneController.text.trim()}';

    if (credential.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // The backend login endpoint accepts email — for phone login,
    // the phone number is passed as the email parameter until
    // a dedicated phone-auth endpoint is implemented.
    await ref.read(authProvider.notifier).login(
      email: credential,
      password: _passwordController.text,
    );

    // Router's refreshListenable will automatically redirect to /dashboard
    // if login succeeded. Show error if it failed.
    final authState = ref.read(authProvider);
    if (mounted && authState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authState.error!),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.verticalGradient,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Back Button
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                    padding: EdgeInsets.zero,
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 40),

                  // Title
                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'Sign in to your borderless financial wallet',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 200.ms, duration: 600.ms),

                  const SizedBox(height: 36),

                  // ── Login Mode Toggle ──────────────────────────
                  _buildLoginModeToggle(),

                  const SizedBox(height: 24),

                  // ── Login Form ─────────────────────────────────
                  GlassContainer(
                    borderRadius: 24,
                    child: Column(
                      children: [
                        // Dynamic credential input
                        if (_loginMode == LoginMode.email)
                          FormInput(
                            label: 'Email',
                            hint: 'your@email.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined),
                          )
                        else
                          _buildPhoneInput(),

                        const SizedBox(height: 24),

                        FormInput(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: Text(
                              'Forgot Password?',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.royalGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          label: 'Sign In',
                          isLoading: authState.isLoading,
                          onPress: _handleLogin,
                        ),

                        const SizedBox(height: 16),

                        // ── Demo Login Link ─────────────────────────────────
                        GestureDetector(
                          onTap: authState.isLoading ? null : _handleDemoLogin,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.royalGold.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.royalGold.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_outline_rounded,
                                  color: AppColors.royalGold.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Try Demo Account',
                                  style: TextStyle(
                                    color: AppColors.royalGold.withValues(alpha: 0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '— no account needed',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(alpha: 0.55),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.easeOutBack),

                  const SizedBox(height: 24),

                  // ── Claim Payroll Transfer Button ──────────────
                  _buildPayrollClaimButton(),

                  const SizedBox(height: 24),

                  // ── Biometric Shortcut ─────────────────────────
                  if (!kIsWeb) _buildBiometricSection(),

                  // Display error if any
                  if (authState.error != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Footer
                  Center(
                    child: TextButton(
                      onPressed: () => context.push('/register'),
                      child: Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                          children: const [
                            TextSpan(
                              text: 'Create Now',
                              style: TextStyle(
                                color: AppColors.royalGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  LOGIN MODE TOGGLE (Email | Phone)
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildLoginModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildModeTab(
            label: 'Email Login',
            icon: Icons.email_outlined,
            mode: LoginMode.email,
          ),
          _buildModeTab(
            label: 'Phone Number Login',
            icon: Icons.phone_android_rounded,
            mode: LoginMode.phone,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required LoginMode mode,
  }) {
    final isSelected = _loginMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _loginMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalGold.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.royalGold.withValues(alpha: 0.4) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.royalGold : AppColors.textSecondary.withValues(alpha: 0.5),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppColors.white : AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PHONE INPUT WITH COUNTRY CODE PICKER
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPhoneInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PHONE NUMBER',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Country code picker
            GestureDetector(
              onTap: _showCountryCodePicker,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedCountryCode.flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _selectedCountryCode.code,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Phone number field
            Expanded(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: '24 XXX XXXX',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Icon(Icons.phone_outlined, color: AppColors.royalGold.withValues(alpha: 0.8)),
                  ),
                  filled: true,
                  fillColor: AppColors.inputBg,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCountryCodePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepGreen1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select Country Code',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _countryCodes.length,
                  separatorBuilder: (_, __) => Divider(
                    color: AppColors.white.withValues(alpha: 0.05),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final cc = _countryCodes[index];
                    final isSelected = cc.code == _selectedCountryCode.code;
                    return ListTile(
                      leading: Text(cc.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(
                        cc.country,
                        style: TextStyle(
                          color: isSelected ? AppColors.royalGold : AppColors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        cc.code,
                        style: TextStyle(
                          color: isSelected ? AppColors.royalGold : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedCountryCode = cc);
                        Navigator.pop(context);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PAYROLL CLAIM BUTTON
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPayrollClaimButton() {
    return GestureDetector(
      onTap: () => context.push('/register', extra: {'source': 'payroll'}),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.royalGold.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.royalGold.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.royalGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_outlined, color: AppColors.royalGold, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Claim a Pending Payroll Transfer',
                    style: TextStyle(
                      color: AppColors.royalGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Freelancers & remote workers — verify with your phone number',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.royalGold.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  BIOMETRIC SECTION
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildBiometricSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'OR USE BIOMETRICS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _handleBiometrics,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                color: AppColors.royalGold.withValues(alpha: 0.05),
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                color: AppColors.royalGold,
                size: 40,
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .shimmer(duration: 2.seconds, color: Colors.white24),
          ),
          const SizedBox(height: 10),
          Text(
            'Face ID / Fingerprint',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}
