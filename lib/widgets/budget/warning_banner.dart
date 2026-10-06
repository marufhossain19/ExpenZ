import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/constants.dart';

/// Animated warning banner that slides in when limits are near/exceeded.
/// Shows shake animation on exceeded state.
class WarningBanner extends StatefulWidget {
  final int level;
  final String message;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const WarningBanner({
    super.key,
    required this.level,
    required this.message,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<WarningBanner> createState() => _WarningBannerState();
}

class _WarningBannerState extends State<WarningBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    if (widget.level >= AlertLevel.exceeded) {
      _shakeController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Color get _bannerColor {
    switch (widget.level) {
      case AlertLevel.warning: return const Color(0xFFFFA502);
      case AlertLevel.danger: return AppColors.budgetDanger;
      case AlertLevel.exceeded: return AppColors.budgetExceeded;
      default: return AppColors.income;
    }
  }

  IconData get _icon {
    switch (widget.level) {
      case AlertLevel.exceeded: return Icons.error_rounded;
      case AlertLevel.danger: return Icons.warning_amber_rounded;
      case AlertLevel.warning: return Icons.info_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final shakeOffset = widget.level >= AlertLevel.exceeded
            ? ((_shakeController.value - 0.5) * 6)
            : 0.0;

        return Transform.translate(
          offset: Offset(shakeOffset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (_, val, child) {
            return Transform.translate(
              offset: Offset(0, -30 * (1 - val)),
              child: Opacity(opacity: val, child: child),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _bannerColor.withValues(alpha: 0.15),
                  _bannerColor.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _bannerColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(_icon, color: _bannerColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: _bannerColor,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.onDismiss != null)
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Icon(Icons.close, size: 18, color: _bannerColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
