import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final String? semanticLabel;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool priority;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.semanticLabel,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.priority = false,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: 300.ms,
          child: frame != null
              ? child
              : _buildSkeleton(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildErrorFallback();
      },
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
    ).animate(onPlay: (c) => c.repeat())
     .shimmer(duration: 1.5.seconds, color: Colors.white12);
  }

  Widget _buildErrorFallback() {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 200,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_rounded, color: AppColors.white.withValues(alpha: 0.3), size: 40),
          const SizedBox(height: 12),
          Text(
            'Asset not found',
            style: TextStyle(color: AppColors.white.withValues(alpha: 0.2), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
