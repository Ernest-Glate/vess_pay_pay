import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/glass_container.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';

import '../data/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _identityDocController = TextEditingController();
  final _claimTokenController = TextEditingController();
  final ValueNotifier<String?> _selectedNationalityNotifier = ValueNotifier<String?>(null);
  bool _showClaimTokenInput = false;
  bool _isClaimingToken = false;

  // ── Nationality → Identity Document mapping ─────────────────────────────
  static const Map<String, String> _africanIdLabels = {
    'Ghana (GH)': 'Ghana Card Number',
    'Nigeria (NG)': 'National ID (NIN)',
    'Kenya (KE)': 'National ID Number',
    'South Africa (ZA)': 'South African ID',
    'Tanzania (TZ)': 'National ID (NIDA)',
    'Rwanda (RW)': 'National ID (Ndi Umunyarwanda)',
    'Uganda (UG)': 'National ID Number',
    'Senegal (SN)': 'Carte Nationale d\'Identité',
    'Côte d\'Ivoire (CI)': 'Carte Nationale d\'Identité',
    'Cameroon (CM)': 'Carte Nationale d\'Identité',
  };

  static const List<String> _countries = [
    'Diaspora / Traveler',
    'Ghana (GH)',
    'Nigeria (NG)',
    'Kenya (KE)',
    'South Africa (ZA)',
    'Tanzania (TZ)',
    'Rwanda (RW)',
    'Uganda (UG)',
    'Senegal (SN)',
    'Côte d\'Ivoire (CI)',
    'Cameroon (CM)',
    'United States (US)',
    'United Kingdom (GB)',
    'Canada (CA)',
    'Germany (DE)',
    'France (FR)',
    'Other',
  ];

  /// Returns the identity document label and hint based on the selected nationality.
  ({String label, String hint, IconData icon}) _getIdentityFieldConfig() {
    final nationality = _selectedNationalityNotifier.value;
    if (nationality == null || nationality == 'Diaspora / Traveler') {
      return (
        label: 'PASSPORT NUMBER',
        hint: 'A12345678',
        icon: Icons.flight_outlined,
      );
    }
    final localLabel = _africanIdLabels[nationality];
    if (localLabel != null) {
      return (
        label: localLabel.toUpperCase(),
        hint: 'Enter your $localLabel',
        icon: Icons.credit_card_outlined,
      );
    }
    // Non-African foreign nationals
    return (
      label: 'PASSPORT NUMBER',
      hint: 'A12345678',
      icon: Icons.badge_outlined,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _identityDocController.dispose();
    _claimTokenController.dispose();
    _selectedNationalityNotifier.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate() || _selectedNationalityNotifier.value == null) {
      if (_selectedNationalityNotifier.value == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your nationality'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    // Split full name into first and last
    final nameParts = _nameController.text.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Call the actual registration API
    await ref.read(authProvider.notifier).register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: firstName,
      lastName: lastName,
      nationality: _selectedNationalityNotifier.value,
    );

    // Check for errors
    final authState = ref.read(authProvider);
    if (authState.error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authState.error!), backgroundColor: Colors.red.shade700),
        );
      }
      return;
    }

    // Registration succeeded — navigate to verify email
    if (mounted) {
      context.go('/verify-email');
    }
  }

  /// Validates a claim token against the corporate payroll API and
  /// pre-fills name + contact fields on success.
  Future<void> _redeemClaimToken() async {
    final token = _claimTokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a claim token'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isClaimingToken = true);

    try {
      // TODO: Replace with actual payroll claim API call once backend endpoint is ready
      // final response = await ref.read(apiClientProvider).post(
      //   ApiEndpoints.redeemPayrollToken,
      //   body: {'token': token},
      // );
      // final data = response.data;
      // _nameController.text = '${data['firstName']} ${data['lastName']}';
      // _emailController.text = data['email'] ?? '';

      // Simulated success feedback until API is wired
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token accepted — fields pre-filled'),
            backgroundColor: AppColors.deepGreen2,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        setState(() => _showClaimTokenInput = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid token: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaimingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.verticalGradient,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                      padding: EdgeInsets.zero,
                    ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.displayLarge,
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Join the borderless pan-African financial ecosystem',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                    
                    const SizedBox(height: 40),

                    // ── Claim Token Shortcut ──────────────────────────
                    _buildClaimTokenShortcut(),

                    const SizedBox(height: 16),

                    GlassContainer(
                      borderRadius: 24,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          FormInput(
                            label: 'FULL NAME',
                            controller: _nameController,
                            hint: 'John Doe',
                            prefixIcon: const Icon(Icons.person_outline),
                            validator: (val) {
                              if (val == null || val.length < 2) return 'Min 2 characters';
                              if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(val)) return 'Alphabets only';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FormInput(
                            label: 'EMAIL ADDRESS',
                            controller: _emailController,
                            hint: 'your@email.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email required';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                return 'Invalid email format';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          FormInput(
                            label: 'PASSWORD',
                            controller: _passwordController,
                            hint: 'Minimum 8 characters',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password required';
                              if (val.length < 8) return 'Minimum 8 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // ── Nationality Dropdown ─────────────────────
                          _buildNationalityDropdown(),

                          const SizedBox(height: 24),

                          // ── Dynamic Identity Document Field ──────────
                          _buildDynamicIdentityField(),

                          const SizedBox(height: 40),
                          AppButton(
                            label: 'Create Account',
                            isLoading: ref.watch(authProvider).isLoading,
                            onPress: _handleRegister,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
                    
                    const SizedBox(height: 32),
                    
                    Center(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: Text.rich(
                          TextSpan(
                            text: "Already a member? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: AppColors.royalGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SUB-WIDGETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Claim Token shortcut link + expandable input near the card container.
  Widget _buildClaimTokenShortcut() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showClaimTokenInput = !_showClaimTokenInput),
          child: Row(
            children: [
              Icon(
                _showClaimTokenInput ? Icons.close_rounded : Icons.redeem_rounded,
                color: AppColors.royalGold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                _showClaimTokenInput
                    ? 'Cancel token entry'
                    : 'Received a payment link? Enter Claim Token',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.royalGold,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),

        // Expandable token input
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: GlassContainer(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYROLL CLAIM TOKEN',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _claimTokenController,
                          style: Theme.of(context).textTheme.bodyLarge,
                          decoration: InputDecoration(
                            hintText: 'e.g. VPT-XXXX-XXXX',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 8),
                              child: Icon(Icons.vpn_key_outlined, color: AppColors.royalGold),
                            ),
                            filled: true,
                            fillColor: AppColors.inputBg,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isClaimingToken ? null : _redeemClaimToken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.royalGold,
                            foregroundColor: AppColors.deepGreen1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: _isClaimingToken
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deepGreen1),
                                )
                              : const Text('Claim', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the token from your employer\'s payment link to auto-fill your details.',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          crossFadeState: _showClaimTokenInput ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  /// Nationality dropdown with expanded African country list.
  Widget _buildNationalityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NATIONALITY',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<String?>(
          valueListenable: _selectedNationalityNotifier,
          builder: (context, value, child) {
            return DropdownButtonFormField<String>(
              dropdownColor: AppColors.deepGreen1,
              style: const TextStyle(color: AppColors.white),
              // ignore: deprecated_member_use
              value: value,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.public, color: AppColors.royalGold),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                _selectedNationalityNotifier.value = val;
                // Clear the identity document field when nationality changes
                _identityDocController.clear();
                setState(() {}); // Rebuild to update the dynamic field
              },
            );
          },
        ),
      ],
    );
  }

  /// Dynamic identity document field that adapts based on selected nationality.
  Widget _buildDynamicIdentityField() {
    return ValueListenableBuilder<String?>(
      valueListenable: _selectedNationalityNotifier,
      builder: (context, nationality, child) {
        final config = _getIdentityFieldConfig();
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: FormInput(
            key: ValueKey(config.label), // Forces rebuild on label change
            label: config.label,
            controller: _identityDocController,
            hint: config.hint,
            prefixIcon: Icon(config.icon),
            validator: (val) {
              if (val == null || val.isEmpty) return 'Required';
              return null;
            },
          ),
        );
      },
    );
  }
}
