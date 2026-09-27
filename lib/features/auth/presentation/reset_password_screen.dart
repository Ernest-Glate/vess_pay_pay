import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/form_input.dart';
import '../../../shared/widgets/glass_container.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleReset() async {
    // Simulate reset
    context.go('/login');
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
                    'New Password',
                    style: Theme.of(context).textTheme.displayLarge,
                  ).animate().fadeIn(duration: 600.ms),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Create a secure password to protect your account',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                  ).animate().fadeIn(delay: 200.ms),
                  
                  const SizedBox(height: 48),

                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        FormInput(
                          label: 'New Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                        const SizedBox(height: 24),
                        FormInput(
                          label: 'Confirm New Password',
                          hint: '••••••••',
                          controller: _confirmPasswordController,
                          obscureText: true,
                          prefixIcon: const Icon(Icons.lock_reset),
                        ),
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Update Password',
                          onPress: _handleReset,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).scale(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
