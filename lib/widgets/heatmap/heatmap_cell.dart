import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Single day cell for the expense heatmap with tap, scale, and glow animations.
class HeatmapCell extends StatefulWidget {
  final int day;
  final double percent; // 0-100+ of daily limit used
  final bool hasData;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final int staggerIndex;
  final VoidCallback? onTap;

  const HeatmapCell({
    super.key,
    required this.day,
    required this.percent,
    required this.hasData,
    this.isSelected = false,
    this.isToday = false,
    this.isFuture = false,
    this.staggerIndex = 0,
    this.onTap,
  });

  @override
  State<HeatmapCell> createState() => _HeatmapCellState();
}

class _HeatmapCellState extends State<HeatmapCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  bool _hovering = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // Staggered entrance
    Future.delayed(Duration(milliseconds: 30 * widget.staggerIndex), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  /// Soft premium colors based on budget percentage
  Color get _cellColor {
    if (widget.isFuture) return Colors.transparent;
    if (!widget.hasData) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5);
    }
    if (widget.percent >= 100) return const Color(0xFFFF6B6B); // Red — exceeded
    if (widget.percent >= 80) return const Color(0xFFFFD93D); // Yellow — warning
    return const Color(0xFF6BCB77); // Green — safe
  }

  Color get _glowColor {
    if (!widget.hasData) return Colors.transparent;
    if (widget.percent >= 100) return const Color(0xFFFF6B6B);
    if (widget.percent >= 80) return const Color(0xFFFFD93D);
    return const Color(0xFF6BCB77);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FadeTransition(
      opacity: _entryController,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          child: GestureDetector(
            onTap: widget.isFuture ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              transform: Matrix4.diagonal3Values(
                widget.isSelected ? 1.15 : (_hovering ? 1.08 : 1.0),
                widget.isSelected ? 1.15 : (_hovering ? 1.08 : 1.0),
                1.0,
              ),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: _cellColor,
                borderRadius: BorderRadius.circular(6),
                border: widget.isToday
                    ? Border.all(color: AppColors.primary, width: 2)
                    : widget.isSelected
                        ? Border.all(color: AppColors.primary.withValues(alpha: 0.8), width: 2)
                        : null,
                boxShadow: (widget.isSelected || _hovering) && widget.hasData
                    ? [BoxShadow(
                        color: _glowColor.withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )]
                    : null,
              ),
              child: Center(
                child: widget.isFuture
                    ? null
                    : Text(
                        '${widget.day}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: widget.isToday ? FontWeight.w800 : FontWeight.w600,
                          color: widget.hasData
                              ? Colors.white.withValues(alpha: 0.9)
                              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                  .withValues(alpha: 0.6),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
