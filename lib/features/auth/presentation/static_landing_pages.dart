import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/optimized_image.dart';

class StaticLandingPage extends StatelessWidget {
  final String title;
  final String description;
  final String illustration;

  const StaticLandingPage({
    super.key,
    required this.title,
    required this.description,
    required this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.royalGold,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn().slideY(begin: -0.2, end: 0),
                const SizedBox(height: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: OptimizedImage(
                    imageUrl: illustration,
                    height: 250,
                    fit: BoxFit.cover,
                    semanticLabel: title,
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),
                const SizedBox(height: 40),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.6),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const StaticLandingPage(
    title: 'About VessPay',
    description: 'VessPay is Ghana\'s most refined fintech ecosystem, designed for those who demand excellence in their daily financial life.',
    illustration: 'assets/illustrations/payment.png',
  );
}

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});
  @override
  Widget build(BuildContext context) => const StaticLandingPage(
    title: 'Our Features',
    description: 'From instant MoMo transfers to offline functionality and multi-currency wallets, VessPay covers all your needs.',
    illustration: 'assets/illustrations/kelewele.png',
  );
}

class SecurityInfoScreen extends StatelessWidget {
  const SecurityInfoScreen({super.key});
  @override
  Widget build(BuildContext context) => const StaticLandingPage(
    title: 'Security First',
    description: 'PCI-DSS compliance, banking-grade encryption, and biometric protection ensure your funds are always safe.',
    illustration: 'assets/illustrations/confidence.png',
  );
}
