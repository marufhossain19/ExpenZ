import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../core/constants.dart';

/// Circular animated spending meter gauge with zone colors and pulse effect.
class SpendingMeter extends StatefulWidget {
  final double percent;
  final int level;
  final String centerLabel;
  final String? subtitle;
  final double size;

  const SpendingMeter({
    super.key,
    required this.percent,
    required this.level,
    this.centerLabel = '',
    this.subtitle,
    this.size = 180,
  });

  @override
  State<SpendingMeter> createState() => _SpendingMeterState();
}

class _SpendingMeterState extends State<SpendingMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.level >= AlertLevel.danger ? 800 : 1500),
    );
    if (widget.level >= AlertLevel.warning) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SpendingMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level >= AlertLevel.warning) {
      _pulseController.duration =
          Duration(milliseconds: widget.level >= AlertLevel.danger ? 800 : 1500);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color get _zoneColor {
    switch (widget.level) {
      case AlertLevel.warning: return const Color(0xFFFFA502);
      case AlertLevel.danger: return AppColors.budgetDanger;
      case AlertLevel.exceeded: return AppColors.budgetExceeded;
      default: return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulseVal = widget.level >= AlertLevel.warning
            ? 0.8 + _pulseController.value * 0.2
            : 1.0;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: widget.percent.clamp(0, 100) / 100),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, animVal, __) {
              return CustomPaint(
                painter: _MeterPainter(
                  progress: animVal,
                  color: _zoneColor,
                  trackColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  glowOpacity: pulseVal,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(animVal * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 32, fontWeight: FontWeight.w800,
                          color: _zoneColor,
                        ),
                      ),
                      if (widget.centerLabel.isNotEmpty)
                        Text(widget.centerLabel, style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        )),
                      if (widget.subtitle != null)
                        Text(widget.subtitle!, style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        )),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _MeterPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double glowOpacity;

  _MeterPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.glowOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 12.0;
    const startAngle = -pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle, false, trackPaint,
    );

    // Glow
    if (progress > 0.7) {
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15 * glowOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, sweepAngle * progress, false, glowPaint,
      );
    }

    // Fill
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle, sweepAngle * progress, false, fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MeterPainter old) =>
      old.progress != progress || old.color != color || old.glowOpacity != glowOpacity;
}
