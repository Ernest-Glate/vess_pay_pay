import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Primary navigation is handled by app_router.dart redirect logic
    // which listens to auth state changes.
    // However, add a fallback timer to ensure we don't get stuck
    _startFallbackTimer();
  }

  void _startFallbackTimer() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      // If we're still on splash after 2 seconds, force navigation
      context.go('/landing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // VessPay Logo with Pulse Animation
            Image.asset(
              'assets/images/vesspay_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                // Log the error for debugging
                debugPrint('❌ Error loading VessPay logo: $error');
                // Return fallback widget that matches brand aesthetic
                return Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.royalGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.royalGold,
                    size: 80,
                  ),
                );
              },
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2000.ms, curve: Curves.easeInOut)
            .shimmer(delay: 1000.ms, duration: 1500.ms, color: AppColors.royalGoldLight.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
