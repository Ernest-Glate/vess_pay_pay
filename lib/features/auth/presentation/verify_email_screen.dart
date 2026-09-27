import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_container.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = false;

  Future<void> _handleCheckStatus() async {
    setState(() => _isChecking = true);
    // Simulate check
    await Future.delayed(2.seconds);
    if (mounted) {
      setState(() => _isChecking = false);
      // Verification complete — go to dashboard
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.royalGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined, color: AppColors.royalGold, size: 64),
                ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 40),
                
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.displayLarge,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 16),
                
                const Text(
                  "We've sent a verification link to your email address. Please click the link to secure your account.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
                ).animate().fadeIn(delay: 400.ms),
                
                const Spacer(),
                
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'I\'ve Verified My Email',
                        isLoading: _isChecking,
                        onPress: _handleCheckStatus,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Resend Verification Email',
                          style: TextStyle(
                            color: AppColors.royalGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
