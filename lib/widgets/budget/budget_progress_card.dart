import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../core/constants.dart';

/// Animated budget progress card with 4-zone color system and glow effects.
class BudgetProgressCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double spent;
  final double limit;
  final int level;
  final IconData? icon;
  final Color? iconColor;

  const BudgetProgressCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.spent,
    required this.limit,
    required this.level,
    this.icon,
    this.iconColor,
  });

  Color get _zoneColor {
    switch (level) {
      case AlertLevel.warning: return const Color(0xFFFFA502);
      case AlertLevel.danger: return AppColors.budgetDanger;
      case AlertLevel.exceeded: return AppColors.budgetExceeded;
      default: return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = limit > 0 ? (spent / limit).clamp(0.0, 1.5) : 0.0;
    final remaining = (limit - spent).clamp(0.0, double.infinity).toDouble();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: level >= AlertLevel.danger
              ? _zoneColor.withValues(alpha: 0.4)
              : isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: level >= AlertLevel.danger ? 1.5 : 1,
        ),
        boxShadow: level >= AlertLevel.exceeded
            ? [BoxShadow(color: _zoneColor.withValues(alpha: 0.2), blurRadius: 16)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              if (icon != null)
                Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? _zoneColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor ?? _zoneColor),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    )),
                    if (subtitle != null)
                      Text(subtitle!, style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      )),
                  ],
                ),
              ),
              // Percentage badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _zoneColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: _zoneColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Animated progress bar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) {
              return Stack(
                children: [
                  // Track
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: val,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_zoneColor.withValues(alpha: 0.7), _zoneColor],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: _zoneColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Spent / Limit / Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Spent: ${Formatters.currencyShort(spent)}', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: _zoneColor,
              )),
              Text('Limit: ${Formatters.currencyShort(limit)}', style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              )),
              Text('Left: ${Formatters.currencyShort(remaining)}', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: remaining > 0 ? AppColors.income : AppColors.expense,
              )),
            ],
          ),
        ],
      ),
    );
  }
}
