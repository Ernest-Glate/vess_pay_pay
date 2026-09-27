import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_service.dart';

enum AppButtonVariant { primary, secondary, outline, danger }

class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback onPress;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool disabled;
  final bool fullWidth;
  final double? width;
  final IconData? icon;

  const AppButton({
    super.key,
    required this.label,
    required this.onPress,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.disabled = false,
    this.fullWidth = true,
    this.width,
    this.icon,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor();
    final foregroundColor = _getForegroundColor();
    final borderColor = _getBorderColor();

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        HapticService.light();
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: (widget.disabled || widget.isLoading) ? null : widget.onPress,
      child: AnimatedContainer(
        duration: 100.ms,
        width: widget.fullWidth ? double.infinity : widget.width,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: _isPressed ? [] : [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: foregroundColor, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
                          ),
                    ),
                  ],
                ),
        ),
      ).animate(target: _isPressed ? 1 : 0).scale(
            begin: const Offset(1, 1),
            end: const Offset(0.97, 0.97),
            curve: Curves.easeOutCubic,
          ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.disabled) return AppColors.textSecondary.withValues(alpha: 0.1);
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.royalGold;
      case AppButtonVariant.secondary:
        return AppColors.forestDepths;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.danger;
    }
  }

  Color _getForegroundColor() {
    if (widget.disabled) return AppColors.textSecondary;
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.black;
      case AppButtonVariant.outline:
        return AppColors.royalGold;
      default:
        return AppColors.white;
    }
  }

  Color? _getBorderColor() {
    if (widget.variant == AppButtonVariant.outline) {
      return AppColors.royalGold.withValues(alpha: 0.5);
    }
    return null;
  }
}
