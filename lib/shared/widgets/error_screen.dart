import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'app_button.dart';

/// Error screen displayed when navigation or routing fails
/// Provides user-friendly error message and recovery options
class ErrorScreen extends StatelessWidget {
  final String? error;
  final String? stackTrace;

  const ErrorScreen({
    super.key,
    this.error,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.error,
                    size: 64,
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 32),
                
                Text(
                  'Oops! Something went wrong',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                
                const SizedBox(height: 16),
                
                Text(
                  'We encountered an unexpected error. Don\'t worry, your data is safe.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                
                if (error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),
                ],
                
                const SizedBox(height: 40),
                
                AppButton(
                  label: 'Return to Dashboard',
                  onPress: () => context.go('/dashboard'),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                
                const SizedBox(height: 16),
                
                TextButton(
                  onPressed: () {
                    // Reload the app by navigating to splash
                    context.go('/splash');
                  },
                  child: const Text(
                    'Restart App',
                    style: TextStyle(
                      color: AppColors.royalGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
