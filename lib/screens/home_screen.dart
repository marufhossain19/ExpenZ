import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/search_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/add_expense_sheet.dart';
import '../widgets/dashboard_summary.dart';
import '../widgets/empty_state.dart';
import '../widgets/expense_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/notification_bell.dart';
import '../widgets/budget/warning_banner.dart';
import '../widgets/budget/overspending_popup.dart';

/// Main home screen showing the expense list with summary, search, and budget warnings.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _bannerDismissed = false;

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkSurface
              : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const AddExpenseSheet(),
      ),
    ).then((_) {
      // After adding expense, check budgets
      if (!mounted) return;
      final budgetP = Provider.of<BudgetProvider>(context, listen: false);
      final expenseP = Provider.of<ExpenseProvider>(context, listen: false);
      final newExceeded = budgetP.checkBudgets(expenseP.expenses);

      // Show popup if limit exceeded
      if (newExceeded && budgetP.pendingPopupAlert != null) {
        final alert = budgetP.pendingPopupAlert!;
        budgetP.clearPendingPopup();
        OverspendingPopup.show(
          context,
          category: alert.category ?? 'Overall',
          spent: alert.amountSpent,
          limit: alert.amountLimit,
          isFamily: alert.isFamily,
          onAdjustBudget: () => Navigator.pushNamed(context, '/limit_settings'),
        );
      }
      setState(() => _bannerDismissed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer3<ExpenseProvider, SearchProvider, BudgetProvider>(
          builder: (context, expenseP, searchP, budgetP, _) {
            // Recalculate budgets
            budgetP.checkBudgets(expenseP.expenses);
            final filtered = searchP.filterExpenses(expenseP.expenses);

            return CustomScrollView(
              slivers: [
                // App Bar with notification bell
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Expense Tracker',
                                style: Theme.of(context).textTheme.headlineLarge),
                              const SizedBox(height: 2),
                              Text('Track smart, spend smarter 🤖',
                                style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        // Dark/Light mode toggle
                        Consumer<ThemeProvider>(
                          builder: (context, themeP, _) {
                            final isDarkNow = Theme.of(context).brightness == Brightness.dark;
                            return GestureDetector(
                              onTap: () => themeP.toggleTheme(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDarkNow
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) =>
                                      RotationTransition(
                                        turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                                        child: FadeTransition(opacity: anim, child: child),
                                      ),
                                  child: Icon(
                                    isDarkNow ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                    key: ValueKey(isDarkNow),
                                    size: 20,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        const NotificationBell(),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('${expenseP.expenses.length} items',
                            style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ),
                ),

                // Warning banner (if any limits in warning+ state)
                if (budgetP.hasWarnings && !_bannerDismissed && budgetP.criticalAlertMessage != null)
                  SliverToBoxAdapter(
                    child: WarningBanner(
                      level: budgetP.highestAlertLevel,
                      message: budgetP.criticalAlertMessage!,
                      onTap: () => Navigator.pushNamed(context, '/limit_settings'),
                      onDismiss: () => setState(() => _bannerDismissed = true),
                    ),
                  ),

                // Dashboard Summary
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: DashboardSummary(
                      income: expenseP.monthlyIncome,
                      expense: expenseP.monthlyExpense,
                      balance: expenseP.monthlyBalance,
                    ),
                  ),
                ),

                // Search bar
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SearchBarWidget(),
                  ),
                ),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Transactions',
                          style: Theme.of(context).textTheme.titleMedium),
                        if (searchP.hasActiveFilters)
                          GestureDetector(
                            onTap: searchP.clearFilters,
                            child: const Text('Clear filters',
                              style: TextStyle(fontSize: 13, color: AppColors.primary,
                                fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),

                // Expense list or empty state
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      title: searchP.hasActiveFilters ? 'No results found' : 'No expenses yet',
                      subtitle: searchP.hasActiveFilters
                          ? 'Try different search terms or filters'
                          : 'Tap the + button to add your first transaction',
                      onAction: searchP.hasActiveFilters ? null : () => _showAddSheet(context),
                      actionLabel: searchP.hasActiveFilters ? null : 'Add Transaction',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final expense = filtered[index];
                        return ExpenseCard(
                          expense: expense,
                          index: index,
                          onDelete: () => expenseP.deleteExpense(expense.id),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}
