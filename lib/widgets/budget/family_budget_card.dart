import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Card showing family budget comparison with member progress bars.
class FamilyBudgetCard extends StatelessWidget {
  final String category;
  final double totalSpent;
  final double totalLimit;
  final List<Map<String, dynamic>> members; // {name, spent, color}

  const FamilyBudgetCard({
    super.key,
    required this.category,
    required this.totalSpent,
    required this.totalLimit,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = totalLimit > 0 ? totalSpent / totalLimit : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.family_restroom_rounded,
                  color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Family — $category', style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    )),
                    Text(
                      '${Formatters.currencyShort(totalSpent)} of ${Formatters.currencyShort(totalLimit)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text('${(percent * 100).toStringAsFixed(0)}%', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700,
                color: percent > 1 ? AppColors.expense : AppColors.primary,
              )),
            ],
          ),
          const SizedBox(height: 16),

          // Member avatars row
          Row(
            children: [
              ...members.take(5).map((m) => Container(
                margin: const EdgeInsets.only(right: 6),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: m['color'] as Color,
                  child: Text(
                    (m['name'] as String).substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white,
                    ),
                  ),
                ),
              )),
              if (members.length > 5)
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  child: Text('+${members.length - 5}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Member comparison bars
          ...members.map((m) {
            final memberPercent = totalLimit > 0
                ? (m['spent'] as double) / totalLimit
                : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(m['name'] as String, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: memberPercent.clamp(0.0, 1.0)),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) {
                        return Stack(
                          children: [
                            Container(
                              height: 8,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: val,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: m['color'] as Color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(Formatters.currencyShort(m['spent'] as double),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
