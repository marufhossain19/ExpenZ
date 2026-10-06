import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Elegant legend for the heatmap color system.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      _LegendItem('No Expense', isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0F5)),
      _LegendItem('Safe', const Color(0xFF6BCB77)),
      _LegendItem('Near Limit', const Color(0xFFFFD93D)),
      _LegendItem('Exceeded', const Color(0xFFFF6B6B)),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 8,
      children: items.map((item) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: item.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 5),
          Text(item.label, style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          )),
        ],
      )).toList(),
    );
  }
}

class _LegendItem {
  final String label;
  final Color color;
  _LegendItem(this.label, this.color);
}
