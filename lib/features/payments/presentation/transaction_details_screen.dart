import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class TransactionDetailsScreen extends StatelessWidget {
  const TransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'RECEIPT',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: AppColors.white),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Stack(
                    children: [
                      // Serrated Receipt Background
                      ClipPath(
                        clipper: ReceiptClipper(),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: BackdropFilter(
                            filter: ColorFilter.mode(Colors.black.withValues(alpha: 0.2), BlendMode.darken),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  // Status Icon
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.success.withValues(alpha: 0.1),
                                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                    ),
                                    child: const Icon(Icons.check_rounded, color: AppColors.success, size: 40),
                                  ).animate().scale(duration: 600.ms, curve: Curves.bounceOut),
                                  
                                  const SizedBox(height: 24),
                                  
                                  const Text(
                                    'TRANSFER SUCCESSFUL',
                                    style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  const Text(
                                    'GHS 1,250.00',
                                    style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  ),
                                  
                                  const SizedBox(height: 40),
                                  
                                  const Divider(color: Colors.white10),
                                  
                                  const SizedBox(height: 24),
                                  
                                  _buildDetailRow('Transaction ID', 'VP-78294021'),
                                  _buildDetailRow('Date', 'Feb 03, 2026 • 10:45 AM'),
                                  _buildDetailRow('Recipient', 'Ama Vesspay'),
                                  _buildDetailRow('MoMo Number', '024 123 4567'),
                                  _buildDetailRow('Fee', 'GHS 12.50'),
                                  _buildDetailRow('Status', 'COMPLETED'),
                                  
                                  const SizedBox(height: 40),
                                  
                                  // Share Button
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
                                      color: AppColors.royalGold.withValues(alpha: 0.05),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.share_rounded, color: AppColors.royalGold, size: 20),
                                        SizedBox(width: 12),
                                        Text(
                                          'SHARE RECEIPT',
                                          style: TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    
    // Bottom serrated edge
    double x = 0;
    double y = size.height;
    double increment = size.width / 20;
    
    while (x < size.width) {
      x += increment;
      y = (y == size.height) ? size.height - 10 : size.height;
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
