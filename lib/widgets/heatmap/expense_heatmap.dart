import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../core/constants.dart';
import 'heatmap_cell.dart';
import 'heatmap_legend.dart';
import 'date_detail_popup.dart';

/// GitHub-style expense heatmap with monthly navigation, budget coloring, and date popups.
class ExpenseHeatmap extends StatefulWidget {
  final bool isFamilyMode;

  const ExpenseHeatmap({super.key, this.isFamilyMode = false});

  @override
  State<ExpenseHeatmap> createState() => _ExpenseHeatmapState();
}

class _ExpenseHeatmapState extends State<ExpenseHeatmap> {
  late DateTime _currentMonth;
  int? _selectedDay;
  int _animKey = 0; // Forces cell rebuild on month change

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedDay = null;
      _animKey++;
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (next.isAfter(DateTime(now.year, now.month + 1))) return;
    setState(() {
      _currentMonth = next;
      _selectedDay = null;
      _animKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer2<ExpenseProvider, BudgetProvider>(
      builder: (context, expenseP, budgetP, _) {
        final daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
        final now = DateTime.now();

        // Get daily limit (first enabled daily limit, or monthly/30)
        double dailyLimit = 0;
        final dailyLimits = budgetP.enabledLimits.where(
          (l) => l.type == LimitType.daily && l.category == null && l.isFamily == widget.isFamilyMode);
        if (dailyLimits.isNotEmpty) {
          dailyLimit = dailyLimits.first.amount;
        } else {
          final monthlyLimits = budgetP.enabledLimits.where(
            (l) => l.type == LimitType.monthly && l.category == null && l.isFamily == widget.isFamilyMode);
          if (monthlyLimits.isNotEmpty) {
            dailyLimit = monthlyLimits.first.amount / daysInMonth;
          }
        }

        // Precompute daily totals
        final dailyTotals = <int, double>{};
        final dailyExpenses = <int, List<Expense>>{};
        for (final e in expenseP.expenses) {
          if (e.isIncome) continue;
          if (e.date.year == _currentMonth.year && e.date.month == _currentMonth.month) {
            dailyTotals[e.date.day] = (dailyTotals[e.date.day] ?? 0) + e.amount;
            dailyExpenses.putIfAbsent(e.date.day, () => []).add(e);
          }
        }

        // Also include income for popup
        final allDailyExpenses = <int, List<Expense>>{};
        for (final e in expenseP.expenses) {
          if (e.date.year == _currentMonth.year && e.date.month == _currentMonth.month) {
            allDailyExpenses.putIfAbsent(e.date.day, () => []).add(e);
          }
        }

        final monthTotal = dailyTotals.values.fold(0.0, (s, v) => s + v);
        final monthPercent = dailyLimit > 0 ? (monthTotal / (dailyLimit * daysInMonth) * 100) : 0.0;

        // Grid: 7 columns
        final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
        final offsetDays = firstWeekday % 7; // Sunday = 0 start

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 20, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              // Header with month nav and summary
              _buildHeader(isDark, monthTotal, monthPercent),
              const SizedBox(height: 16),

              // Weekday labels
              _buildWeekdayLabels(isDark),
              const SizedBox(height: 6),

              // Heatmap grid with animated month transition
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.05, 0), end: Offset.zero)
                        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                    child: child,
                  ),
                ),
                child: _buildGrid(
                  key: ValueKey(_animKey),
                  daysInMonth: daysInMonth,
                  offsetDays: offsetDays,
                  dailyTotals: dailyTotals,
                  dailyLimit: dailyLimit,
                  now: now,
                ),
              ),
              const SizedBox(height: 16),

              // Legend
              const HeatmapLegend(),

              // Tooltip for selected day
              if (_selectedDay != null && dailyTotals.containsKey(_selectedDay))
                _buildTooltip(isDark, dailyTotals[_selectedDay!]!, dailyLimit),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, double total, double pct) {
    final now = DateTime.now();
    final isCurrentMonth = _currentMonth.year == now.year && _currentMonth.month == now.month;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left_rounded, size: 28),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground),
            ),
            Column(children: [
              Text(Formatters.monthYear(_currentMonth), style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              const SizedBox(height: 2),
              Text('Total: ${Formatters.currencyShort(total)}', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            ]),
            IconButton(
              onPressed: isCurrentMonth ? null : _nextMonth,
              icon: Icon(Icons.chevron_right_rounded, size: 28,
                color: isCurrentMonth ? Colors.grey.withValues(alpha: 0.3) : null),
              style: IconButton.styleFrom(
                backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground),
            ),
          ],
        ),
        if (pct > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct.clamp(0, 100) / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, val, __) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: val, minHeight: 6,
                  backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  valueColor: AlwaysStoppedAnimation(
                    pct >= 100 ? const Color(0xFFFF6B6B) : pct >= 80 ? const Color(0xFFFFD93D) : const Color(0xFF6BCB77)),
                ),
              ),
            )),
            const SizedBox(width: 10),
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: pct >= 100 ? const Color(0xFFFF6B6B) : pct >= 80 ? const Color(0xFFFFD93D) : const Color(0xFF6BCB77))),
          ]),
        ],
      ],
    );
  }

  Widget _buildWeekdayLabels(bool isDark) {
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return Row(
      children: days.map((d) => Expanded(
        child: Center(child: Text(d, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
      )).toList(),
    );
  }

  Widget _buildGrid({
    required Key key,
    required int daysInMonth,
    required int offsetDays,
    required Map<int, double> dailyTotals,
    required double dailyLimit,
    required DateTime now,
  }) {
    final totalCells = offsetDays + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      key: key,
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - offsetDays + 1;

              if (day < 1 || day > daysInMonth) {
                return Expanded(child: AspectRatio(aspectRatio: 1, child: Container()));
              }

              final cellDate = DateTime(_currentMonth.year, _currentMonth.month, day);
              final isFuture = cellDate.isAfter(now);
              final isToday = cellDate.year == now.year && cellDate.month == now.month && cellDate.day == now.day;
              final spent = dailyTotals[day] ?? 0;
              final hasData = spent > 0;
              final percent = dailyLimit > 0 ? (spent / dailyLimit * 100) : 0.0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: HeatmapCell(
                      day: day,
                      percent: percent,
                      hasData: hasData,
                      isSelected: _selectedDay == day,
                      isToday: isToday,
                      isFuture: isFuture,
                      staggerIndex: cellIndex,
                      onTap: () {
                        setState(() => _selectedDay = _selectedDay == day ? null : day);
                        // Open popup on tap
                        final expenses = <Expense>[];
                        final expenseP = Provider.of<ExpenseProvider>(context, listen: false);
                        for (final e in expenseP.expenses) {
                          if (e.date.year == _currentMonth.year &&
                              e.date.month == _currentMonth.month &&
                              e.date.day == day) {
                            expenses.add(e);
                          }
                        }
                        DateDetailPopup.show(
                          context,
                          date: cellDate,
                          expenses: expenses,
                          dailyLimit: dailyLimit,
                          isFamilyMode: widget.isFamilyMode,
                        );
                      },
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildTooltip(bool isDark, double spent, double limit) {
    final pct = limit > 0 ? (spent / limit * 100) : 0.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, val, child) => Opacity(opacity: val,
        child: Transform.translate(offset: Offset(0, 10 * (1 - val)), child: child)),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_selectedDay ${Formatters.monthShort(_currentMonth)}', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(width: 12),
            Text('Spent: ${Formatters.currencyShort(spent)}', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            const SizedBox(width: 12),
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w700,
              color: pct >= 100 ? const Color(0xFFFF6B6B)
                  : pct >= 80 ? const Color(0xFFFFD93D)
                  : const Color(0xFF6BCB77))),
          ],
        ),
      ),
    );
  }
}
