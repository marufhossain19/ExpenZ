import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';
import '../providers/expense_provider.dart';
import '../models/spending_limit.dart';
import '../theme/app_colors.dart';
import '../core/constants.dart';

import '../widgets/budget/spending_meter.dart';
import '../widgets/budget/budget_progress_card.dart';

/// Budget dashboard: period selector (daily / weekly / monthly), progress, and AI insights.
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  /// Selected period tab: [LimitType.daily, weekly, monthly]
  int _periodTab = LimitType.daily;

  List<SpendingLimit> _limitsForPeriod(BudgetProvider budgetP) {
    return budgetP.enabledLimits.where((l) => l.type == _periodTab).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer2<BudgetProvider, ExpenseProvider>(
          builder: (context, budgetP, expenseP, _) {
            budgetP.checkBudgets(expenseP.expenses);
            final insights = budgetP.getInsights(expenseP.expenses);
            final periodLimits = _limitsForPeriod(budgetP);
            final hasAnyLimits = budgetP.limits.isNotEmpty;

            return CustomScrollView(
              slivers: [
                // ── Header ──────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget',
                            style: Theme.of(context).textTheme.headlineLarge),
                        IconButton(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Spending limits',
                          onPressed: () =>
                              Navigator.pushNamed(context, '/limit_settings'),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Period Selector — always visible ─────────────────
                SliverToBoxAdapter(child: _periodSelector(isDark)),

                // ── Spending Meter — only when overall limit exists ──
                SliverToBoxAdapter(
                    child: _buildOverallMeter(budgetP, periodLimits, isDark)),

                // ── Active Limits Section ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Active limits',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),

                if (periodLimits.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final limit = periodLimits[i];
                        final status = budgetP.getStatus(limit.id);
                        final spent = status?['spent'] as double? ?? 0;
                        final level = status?['level'] as int? ?? 0;
                        final catIcon = limit.category != null
                            ? IconData(
                                expenseP.getCategoryIcon(limit.category!),
                                fontFamily: 'MaterialIcons')
                            : Icons.account_balance_wallet_rounded;
                        final catColor = limit.category != null
                            ? Color(expenseP.getCategoryColor(limit.category!))
                            : null;
                        return BudgetProgressCard(
                          title: limit.category ?? 'Overall',
                          subtitle:
                              '${limit.typeName}${limit.isFamily ? " • Family" : ""}',
                          spent: spent,
                          limit: limit.amount,
                          level: level,
                          icon: catIcon,
                          iconColor: catColor,
                        );
                      },
                      childCount: periodLimits.length,
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: _buildNoLimitsInline(context, isDark, hasAnyLimits),
                  ),

                // ── AI Insights — always visible ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                    child: Text(
                      'AI Insights 🤖',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _buildInsights(insights, isDark)),

                // ── Alert History Link ────────────────────────────────
                if (budgetP.alerts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/alert_history'),
                        icon: const Icon(Icons.history_rounded, size: 20),
                        label: Text(
                          'View alert history (${budgetP.alerts.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _periodSelector(bool isDark) {
    const labels = ['Daily', 'Weekly', 'Monthly'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: List.generate(3, (i) {
            final active = _periodTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _periodTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: active
                            ? Colors.white
                            : (isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOverallMeter(
    BudgetProvider budgetP,
    List<SpendingLimit> periodLimits,
    bool isDark,
  ) {
    final overall = periodLimits.where((l) => l.category == null).toList();
    if (overall.isEmpty) return const SizedBox.shrink();

    final mainLimit = overall.first;
    final status = budgetP.getStatus(mainLimit.id);
    final percent = status?['percent'] as double? ?? 0;
    final level = status?['level'] as int? ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: SpendingMeter(
          percent: percent,
          level: level,
          centerLabel: mainLimit.typeName,
          subtitle: 'Budget used',
          size: 200,
        ),
      ),
    );
  }

  Widget _buildNoLimitsInline(BuildContext context, bool isDark, bool hasAnyLimits) {
    final message = hasAnyLimits
        ? 'No ${_periodLabel()} limits enabled. Switch period or add limits in settings.'
        : 'No spending limits set. Set limits to track and control your spending.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary.withValues(alpha: 0.6), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushNamed(context, '/limit_settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
              child: const Text('+ Set Limits'),
            ),
          ],
        ),
      ),
    );
  }

  String _periodLabel() {
    switch (_periodTab) {
      case LimitType.daily:
        return 'daily';
      case LimitType.weekly:
        return 'weekly';
      case LimitType.monthly:
        return 'monthly';
      default:
        return '';
    }
  }

  Widget _buildInsights(List<String> insights, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: insights
            .map((insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          insight,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

}
