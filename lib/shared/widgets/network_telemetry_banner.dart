import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/network_telemetry_service.dart';

/// A slim, non-intrusive horizontal scrolling status strip that displays
/// live health of local mobile money operators. Placed at the top of the
/// wallet screen to manage user expectations and reduce support requests
/// when telco networks experience systemic downtimes.
class NetworkTelemetryBanner extends ConsumerWidget {
  const NetworkTelemetryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final operators = ref.watch(networkTelemetryProvider);

    if (operators.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _showFullOperatorList(context, operators),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _getBannerColor(operators).withValues(alpha: 0.06),
          border: Border(
            bottom: BorderSide(
              color: _getBannerColor(operators).withValues(alpha: 0.12),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Status icon
            Icon(
              _getBannerIcon(operators),
              color: _getBannerColor(operators),
              size: 14,
            ),
            const SizedBox(width: 8),

            // Scrolling operator statuses
            Expanded(
              child: SizedBox(
                height: 16,
                child: _buildScrollingStatus(operators),
              ),
            ),

            // Expand arrow
            Icon(
              Icons.expand_more_rounded,
              color: AppColors.textSecondary.withValues(alpha: 0.4),
              size: 16,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.5, end: 0);
  }

  Widget _buildScrollingStatus(List<MoMoOperatorStatus> operators) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: operators.length,
      itemBuilder: (context, index) {
        final op = operators[index];
        final isLast = index == operators.length - 1;

        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status dot
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _getStatusColor(op.status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                op.displayLabel,
                style: TextStyle(
                  color: _getStatusColor(op.status).withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: op.status != OperatorHealthStatus.operational
                      ? FontWeight.bold
                      : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '·',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBannerColor(List<MoMoOperatorStatus> operators) {
    final hasDown = operators.any((op) => op.status == OperatorHealthStatus.down);
    final hasDelayed = operators.any((op) =>
        op.status == OperatorHealthStatus.delayed ||
        op.status == OperatorHealthStatus.degraded);

    if (hasDown) return AppColors.error;
    if (hasDelayed) return AppColors.warning;
    return AppColors.success;
  }

  IconData _getBannerIcon(List<MoMoOperatorStatus> operators) {
    final hasDown = operators.any((op) => op.status == OperatorHealthStatus.down);
    final hasIssues = operators.any((op) => op.status != OperatorHealthStatus.operational);

    if (hasDown) return Icons.error_outline_rounded;
    if (hasIssues) return Icons.info_outline_rounded;
    return Icons.check_circle_outline_rounded;
  }

  Color _getStatusColor(OperatorHealthStatus status) {
    switch (status) {
      case OperatorHealthStatus.operational:
        return AppColors.success;
      case OperatorHealthStatus.degraded:
        return AppColors.warning;
      case OperatorHealthStatus.delayed:
        return AppColors.warning;
      case OperatorHealthStatus.down:
        return AppColors.error;
    }
  }

  void _showFullOperatorList(BuildContext context, List<MoMoOperatorStatus> operators) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          gradient: AppColors.verticalGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.cell_tower_rounded, color: AppColors.royalGold, size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Network Status',
                  style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  'Live',
                  style: TextStyle(color: AppColors.success.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6, height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...operators.map((op) => _buildOperatorRow(op)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Last checked: ${_formatTime(operators.first.lastChecked)}',
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.4), fontSize: 10),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorRow(MoMoOperatorStatus op) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(op.flag, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  op.name,
                  style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (op.statusMessage != null)
                  Text(
                    op.statusMessage!,
                    style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5), fontSize: 10),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(op.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(
                    color: _getStatusColor(op.status),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  op.statusText,
                  style: TextStyle(
                    color: _getStatusColor(op.status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
