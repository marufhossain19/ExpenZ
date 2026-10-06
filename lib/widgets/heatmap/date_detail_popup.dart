import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/expense.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

/// Glassmorphism date detail popup showing full analytics for a single day.
class DateDetailPopup extends StatelessWidget {
  final DateTime date;
  final List<Expense> expenses;
  final double dailyLimit;
  final bool isFamilyMode;

  const DateDetailPopup({
    super.key,
    required this.date,
    required this.expenses,
    required this.dailyLimit,
    this.isFamilyMode = false,
  });

  static Future<void> show(
    BuildContext context, {
    required DateTime date,
    required List<Expense> expenses,
    required double dailyLimit,
    bool isFamilyMode = false,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, _, __) => DateDetailPopup(
        date: date, expenses: expenses,
        dailyLimit: dailyLimit, isFamilyMode: isFamilyMode,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSpent = expenses.where((e) => !e.isIncome).fold(0.0, (s, e) => s + e.amount);
    final percent = dailyLimit > 0 ? (totalSpent / dailyLimit * 100) : 0.0;
    final statusColor = percent >= 100
        ? const Color(0xFFFF6B6B)
        : percent >= 80
            ? const Color(0xFFFFD93D)
            : const Color(0xFF6BCB77);

    // Category breakdown
    final catTotals = <String, double>{};
    for (final e in expenses.where((e) => !e.isIncome)) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCard.withValues(alpha: 0.88)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.25), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: statusColor.withValues(alpha: 0.15), blurRadius: 30),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context, isDark, totalSpent, percent, statusColor),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildBudgetUsage(isDark, totalSpent, percent, statusColor),
                            const SizedBox(height: 20),
                            if (catTotals.isNotEmpty) ...[
                              _buildCategoryBreakdown(isDark, catTotals, totalSpent),
                              const SizedBox(height: 20),
                            ],
                            _buildTransactionList(isDark),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext ctx, bool isDark, double total, double pct, Color statusColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [statusColor.withValues(alpha: 0.12), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Formatters.dateFull(date), style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      pct >= 100 ? 'Exceeded Limit' : pct >= 80 ? 'Near Limit' : 'Safe',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
                  ]),
                ],
              )),
              GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 18,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Total Spent: ', style: TextStyle(fontSize: 14,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              Text(Formatters.currency(total), style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetUsage(bool isDark, double total, double pct, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Budget Usage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            Text('${pct.toStringAsFixed(0)}%', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: pct.clamp(0, 100) / 100),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, val, __) => ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: val,
                minHeight: 10,
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Spent: ${Formatters.currencyShort(total)}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            Text('Limit: ${Formatters.currencyShort(dailyLimit)}',
              style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(bool isDark, Map<String, double> catTotals, double total) {
    final sorted = catTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 10),
        ...sorted.map((entry) {
          final pct = total > 0 ? (entry.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(flex: 3, child: Text(entry.key, style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary))),
              Expanded(flex: 4, child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct / 100),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (_, val, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: val, minHeight: 6,
                    backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 70, child: Text(Formatters.currencyShort(entry.value),
                textAlign: TextAlign.right, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
            ]),
          );
        }),
      ],
    );
  }

  Widget _buildTransactionList(bool isDark) {
    if (expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        child: Column(children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 2000),
            curve: Curves.easeInOut,
            builder: (_, val, child) => Transform.scale(scale: val, child: child),
            child: Icon(Icons.inbox_rounded, size: 48,
              color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 12),
          Text('No expenses recorded on this day', style: TextStyle(fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        const SizedBox(height: 10),
        ...expenses.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + i * 80),
            curve: Curves.easeOut,
            builder: (_, val, child) => Opacity(
              opacity: val,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - val)),
                child: child,
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (e.isIncome ? AppColors.income : AppColors.expense).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(
                    e.isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 18, color: e.isIncome ? AppColors.income : AppColors.expense),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    Text('${e.category} • ${Formatters.time(e.date)}',
                      style: TextStyle(fontSize: 11,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                )),
                Text(
                  '${e.isIncome ? "+" : "-"}${Formatters.currencyShort(e.amount)}',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: e.isIncome ? AppColors.income : AppColors.expense),
                ),
              ]),
            ),
          );
        }),
      ],
    );
  }
}
