import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';
import '../../../shared/widgets/glass_container.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSent = false;

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
                    padding: EdgeInsets.zero,
                  ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(duration: 600.ms),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Enter your registered email to receive recovery instructions',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 48),

                  if (!_isSent)
                    GlassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          FormInput(
                            label: 'Email',
                            hint: 'your@email.com',
                            controller: _emailController,
                            prefixIcon: const Icon(Icons.email_outlined),
                          ),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Send Reset Link',
                            onPress: () => setState(() => _isSent = true),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).scale()
                  else
                    GlassContainer(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.royalGold, size: 64),
                          const SizedBox(height: 24),
                          const Text(
                            'Reset Link Sent',
                            style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Please check your inbox for instructions to reset your password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Back to Login',
                            onPress: () => context.pop(),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
