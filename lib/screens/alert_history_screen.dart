import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../models/budget_alert.dart';
import '../providers/budget_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Screen showing chronological budget alert history.
class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          Consumer<BudgetProvider>(
            builder: (_, p, __) => p.alerts.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClear(context, p),
                    child: const Text(
                      'Clear All',
                      style: TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.w600),
                    ))
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: Consumer<BudgetProvider>(
        builder: (context, budgetP, _) {
          if (budgetP.alerts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 64,
                      color: AppColors.income.withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  Text('No alerts yet',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)),
                  const SizedBox(height: 8),
                  Text('Your spending is on track!',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            // Key on length forces full list rebuild after × or Clear All
            key: ValueKey(budgetP.alerts.length),
            itemCount: budgetP.alerts.length,
            itemBuilder: (_, i) {
              final alert = budgetP.alerts[i];
              return Slidable(
                key: ValueKey(alert.id),
                // Swipe left → delete
                endActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          Provider.of<BudgetProvider>(context, listen: false)
                              .removeAlert(alert.id),
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_rounded,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                // Swipe right → delete
                startActionPane: ActionPane(
                  motion: const DrawerMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (_) =>
                          Provider.of<BudgetProvider>(context, listen: false)
                              .removeAlert(alert.id),
                      backgroundColor: AppColors.expense,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_rounded,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ],
                ),
                child: _buildAlertCard(context, alert, isDark),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(
      BuildContext context, BudgetAlert alert, bool isDark) {
    // Level 3 (Exceeded): deep red instead of pink
    final levelColors = [
      AppColors.income,
      const Color(0xFFFFA502),
      AppColors.expense,
      AppColors.budgetExceeded,
    ];
    final levelIcons = [
      Icons.check_circle_rounded,
      Icons.info_rounded,
      Icons.warning_amber_rounded,
      Icons.error_rounded,
    ];
    final color = levelColors[alert.level.clamp(0, 3)];
    final icon = levelIcons[alert.level.clamp(0, 3)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Icon badge ────────────────────────────────────
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),

          // ── Content ───────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Level badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(alert.levelName,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
                  if (alert.isFamily) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color:
                              AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: const Text('Family',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.secondary)),
                    ),
                  ],
                  const Spacer(),
                  Text(Formatters.relativeDate(alert.timestamp),
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary)),
                ]),
                const SizedBox(height: 8),
                Text(alert.message,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary)),
                const SizedBox(height: 6),
                Text(
                  '${Formatters.currencyShort(alert.amountSpent)} of '
                  '${Formatters.currencyShort(alert.amountLimit)} '
                  '(${alert.percentUsed.toStringAsFixed(0)}%)',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
                ),
              ],
            ),
          ),

          // ── ✕ Close button ────────────────────────────────
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Provider.of<BudgetProvider>(context, listen: false)
                .removeAlert(alert.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Icon(
                Icons.close_rounded,
                size: 20,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, BudgetProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Alerts?'),
        content: const Text('This will remove all alert history.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearAlertHistory();
            },
            child: const Text('Clear All',
                style: TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
