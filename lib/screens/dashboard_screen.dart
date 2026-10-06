import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/heatmap/expense_heatmap.dart';

/// Dashboard screen showing financial stats, charts, and heatmap.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, provider, _) {
            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text('Dashboard',
                      style: Theme.of(context).textTheme.headlineLarge),
                  ),
                ),

                // Summary cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 20),
                    child: DashboardSummary(
                      income: provider.monthlyIncome,
                      expense: provider.monthlyExpense,
                      balance: provider.monthlyBalance,
                    ),
                  ),
                ),

                // GitHub-style Expense Heatmap
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: ExpenseHeatmap(),
                  ),
                ),

                // Pie chart
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: PieChartWidget(
                      categoryTotals: provider.categoryTotals,
                      getCategoryColor: provider.getCategoryColor,
                    ),
                  ),
                ),

                // Weekly overview
                SliverToBoxAdapter(
                  child: _buildWeeklyOverview(context, isDark, provider),
                ),

                // Top expenses
                SliverToBoxAdapter(
                  child: _buildTopExpenses(context, isDark, provider),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWeeklyOverview(
      BuildContext context, bool isDark, ExpenseProvider provider) {
    final weeklyTotals = provider.weeklyTotals;
    final maxVal = weeklyTotals.values.fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          Text('This Week',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            )),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyTotals.entries.map((entry) {
              final ratio = maxVal > 0 ? entry.value / maxVal : 0.0;
              final isToday = entry.key == _todayName();
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: ratio),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, val, __) {
                          return Container(
                            height: 100 * val + 8,
                            decoration: BoxDecoration(
                              gradient: isToday
                                  ? AppColors.primaryGradient
                                  : null,
                              color: isToday
                                  ? null
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(entry.key,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? AppColors.primary
                              : isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                        )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _todayName() {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[DateTime.now().weekday - 1];
  }

  Widget _buildTopExpenses(
      BuildContext context, bool isDark, ExpenseProvider provider) {
    final topExpenses = provider.expenses
        .where((e) => !e.isIncome)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = topExpenses.take(5).toList();

    if (top5.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
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
          Text('Biggest Expenses',
            style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            )),
          const SizedBox(height: 14),
          ...top5.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Color(e.categoryColor).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    IconData(e.categoryIcon, fontFamily: 'MaterialIcons'),
                    color: Color(e.categoryColor), size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.title, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('${e.category} • ${Formatters.relativeDateWithTime(e.date)}',
                        style: TextStyle(fontSize: 11,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Text(Formatters.currency(e.amount),
                  style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.expense,
                  )),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
