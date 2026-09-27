import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vibration/vibration.dart';
import '../../core/theme/app_colors.dart';
import './glass_container.dart';

class SuccessNotification extends StatelessWidget {
  final String message;
  final String? amount;
  final String timestamp;
  final VoidCallback onDismiss;

  const SuccessNotification({
    super.key,
    required this.message,
    this.amount,
    required this.timestamp,
    required this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String message,
    String? amount,
    required String timestamp,
  }) {
    // Trigger Haptic Feedback (skip on web)
    if (!kIsWeb) {
      try {
        Vibration.hasVibrator().then((hasVibrator) {
          if (hasVibrator == true) {
            Vibration.vibrate(duration: 100);
          }
        });
      } catch (_) {}
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: SuccessNotification(
          message: message,
          amount: amount,
          timestamp: timestamp,
          onDismiss: () {
            entry.remove();
          },
        ),
      ),
    );

    overlay.insert(entry);

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.3)),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.black, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (amount != null)
                    Text(
                      amount!,
                      style: const TextStyle(color: AppColors.royalGold, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  Text(
                    timestamp,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 20),
            ),
          ],
        ),
      ).animate().slideY(begin: -1, end: 0, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }
}
