import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/optimized_image.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _features = [
    {
      'title': 'REFINE YOUR PAYMENTS',
      'headline': 'The Borderless Multi-Country Financial Wallet',
      'description': 'Hold secure foreign currency, receive international payouts, and spend seamlessly across 33 African nations via Mobile Money.',
      'image': 'assets/illustrations/payment.png',
    },
    {
      'title': 'SAFE & SECURE',
      'headline': 'Bank-grade protection across every border',
      'description': 'PCI-DSS compliant infrastructure, biometric authentication, and real-time fraud monitoring safeguard every cross-border transaction you make.',
      'image': 'assets/illustrations/confidence.png',
    },
    {
      'title': 'BEYOND BOUNDARIES',
      'headline': 'One wallet, 33 countries, zero friction',
      'description': 'Send payroll to Lagos, receive payments in Nairobi, and cash out via Mobile Money in Accra — all from a single unified account.',
      'image': 'assets/illustrations/kelewele.png',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.verticalGradient,
            ),
          ),
          
          // Static background glow (no repeating animation)
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.royalGold.withValues(alpha: 0.04),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Header
                Text(
                  'VESSPAY',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.royalGold,
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                
                const SizedBox(height: 24),
                
                // PageView Features — expanded to fill available space
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _features.length,
                    itemBuilder: (context, index) {
                      final feature = _features[index];
                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                                  ),
                                  child: OptimizedImage(
                                    imageUrl: feature['image']!,
                                    fit: BoxFit.cover,
                                    semanticLabel: feature['headline'],
                                    priority: index == 0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                feature['title']!,
                                style: const TextStyle(
                                  color: AppColors.royalGold,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                feature['headline']!,
                                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                feature['description']!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Page Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _features.length,
                    (index) => AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppColors.royalGold : AppColors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Actions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                  child: Column(
                    children: [
                      AppButton(
                        label: 'Get Started with VessPay',
                        onPress: () => context.push('/register'),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: Text(
                          'Already a member? Sign In',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () => context.push('/register', extra: {'source': 'payroll'}),
                        child: Text.rich(
                          const TextSpan(
                            text: 'Claim a corporate payroll transfer ',
                            children: [
                              TextSpan(
                                text: '→',
                                style: TextStyle(
                                  color: AppColors.royalGold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.royalGold.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

