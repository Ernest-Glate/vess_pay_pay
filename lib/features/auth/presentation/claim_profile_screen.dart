import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../data/auth_provider.dart';

/// Claim screen for workers who received a B2B payout SMS.
///
/// Deep-link format: vesspay://claim?phone=+233XXXXXXXXX&token=<64_char_hex>
///
/// Flow:
/// 1. Phone + token are pre-filled from the deep link.
/// 2. User enters email, password, first name, last name.
/// 3. POST /auth/claim → shadow profile converted to full account.
/// 4. JWT issued, user lands on dashboard with funds already visible.
class ClaimProfileScreen extends ConsumerStatefulWidget {
  final String phone;
  final String claimToken;

  const ClaimProfileScreen({
    super.key,
    required this.phone,
    required this.claimToken,
  });

  @override
  ConsumerState<ClaimProfileScreen> createState() => _ClaimProfileScreenState();
}

class _ClaimProfileScreenState extends ConsumerState<ClaimProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _currentStep = 0; // 0 = verify phone, 1 = register details
  String? _errorMessage;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                onPressed: () => setState(() => _currentStep = 0),
              )
            : null,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hero badge
                _buildHeroBadge(),

                const SizedBox(height: 32),

                // Step content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _currentStep == 0
                      ? _buildStep0VerifyPhone()
                      : _buildStep1RegisterDetails(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HERO BADGE — "You've received money!"
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroBadge() {
    return Column(
      children: [
        // Animated pulsing icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 1.0 + (_pulseController.value * 0.08);
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.royalGold,
                  AppColors.royalGold.withValues(alpha: 0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.royalGold.withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ).animate().scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),

        const SizedBox(height: 20),

        Text(
          'Money is waiting for you! 🎉',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 8),

        Text(
          'A payment was sent to your number.\nCreate your free account to access your funds.',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 600.ms),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 0: VERIFY PHONE
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStep0VerifyPhone() {
    return Column(
      key: const ValueKey('step0'),
      children: [
        GlassContainer(
          borderRadius: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'YOUR PHONE NUMBER',
                style: TextStyle(
                  color: Colors.white30,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Phone display (pre-filled from deep link)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalGold.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_rounded,
                        color: AppColors.royalGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recipient Number',
                            style: TextStyle(color: Colors.white30, fontSize: 11),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatPhone(widget.phone),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.verified_rounded,
                      color: AppColors.success,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Security note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: AppColors.success.withValues(alpha: 0.8),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your funds are secured and waiting. Complete registration to access them instantly.',
                        style: TextStyle(
                          color: AppColors.success.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 24),

        AppButton(
          label: 'Continue to Registration',
          icon: Icons.arrow_forward_rounded,
          onPress: () => setState(() => _currentStep = 1),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  STEP 1: REGISTER DETAILS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildStep1RegisterDetails() {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // Error message
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ).animate().shake(delay: 100.ms),

        GlassContainer(
          borderRadius: 24,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CREATE YOUR ACCOUNT',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Name row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.length < 2) ? 'Min 2 chars' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        icon: Icons.person_outline_rounded,
                        validator: (v) => (v == null || v.length < 2) ? 'Min 2 chars' : null,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || !v.contains('@')) return 'Valid email required';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => (v == null || v.length < 8) ? 'Min 8 characters' : null,
                ),

                const SizedBox(height: 16),

                // Confirm password
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v != _passwordController.text) return 'Passwords don\'t match';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0),

        const SizedBox(height: 24),

        AppButton(
          label: _isSubmitting ? 'Creating Account...' : 'Claim My Funds',
          icon: _isSubmitting ? null : Icons.rocket_launch_rounded,
          disabled: _isSubmitting,
          onPress: _submitClaim,
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 16),

        // Already have an account?
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'Already have an account? Sign in',
            style: TextStyle(
              color: AppColors.royalGold.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SUBMIT CLAIM
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      // TODO: Replace with real API call: POST /api/v1/auth/claim
      // final response = await dio.post('/auth/claim', data: { ... });
      await Future.delayed(const Duration(seconds: 2));

      // Simulate successful claim — in production, this would:
      // 1. Call POST /auth/claim with phone, claimToken, email, password, names
      // 2. Receive JWT + user data
      // 3. Store token in secure storage
      // 4. Set auth state

      // For now, simulate by logging in
      await ref.read(authProvider.notifier).login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        // Navigate to dashboard — skipping onboarding entirely!
        context.go('/dashboard');
      }
    } catch (e) {
      setState(() {
        _errorMessage = _mapClaimError(e.toString());
        _isSubmitting = false;
      });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  String _formatPhone(String phone) {
    // Format +233241234567 → +233 24 123 4567
    if (phone.length >= 12) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 6)} ${phone.substring(6, 9)} ${phone.substring(9)}';
    }
    return phone;
  }

  String _mapClaimError(String error) {
    if (error.contains('SHADOW_NOT_FOUND')) {
      return 'No pending funds found for this phone number.';
    }
    if (error.contains('INVALID_CLAIM_TOKEN')) {
      return 'Invalid claim link. Please use the link from your SMS.';
    }
    if (error.contains('CLAIM_TOKEN_EXPIRED')) {
      return 'This claim link has expired. Please contact support.';
    }
    if (error.contains('EMAIL_ALREADY_EXISTS')) {
      return 'An account with this email already exists. Try signing in instead.';
    }
    return 'Something went wrong. Please try again.';
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.white, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: AppColors.royalGold, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.white.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.royalGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
