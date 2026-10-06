import 'dart:math';
import '../models/expense.dart';
import '../models/spending_limit.dart';
import '../core/constants.dart';
import '../utils/extensions.dart';

/// Service for budget calculations, limit checking, and AI spending insights.
class BudgetService {
  static final _random = Random();

  /// Calculate total spending for a given limit period and optional category.
  static double getSpendingForLimit(
    SpendingLimit limit,
    List<Expense> expenses,
  ) {
    final now = DateTime.now();
    DateTime periodStart;

    switch (limit.type) {
      case LimitType.daily:
        periodStart = now.startOfDay;
        break;
      case LimitType.weekly:
        periodStart = now.subtract(Duration(days: now.weekday - 1)).startOfDay;
        break;
      case LimitType.monthly:
        periodStart = now.startOfMonth;
        break;
      default:
        periodStart = now.startOfMonth;
    }

    return expenses
        .where((e) =>
            !e.isIncome &&
            e.date.isAfter(periodStart) &&
            e.date.isBefore(now.add(const Duration(days: 1))) &&
            (limit.category == null || e.category == limit.category))
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Get percentage of limit used.
  static double getPercentUsed(double spent, double limit) {
    if (limit <= 0) return 0;
    return (spent / limit * 100);
  }

  /// Get alert level from percentage.
  static int getAlertLevel(double percent) {
    return AlertLevel.fromPercent(percent);
  }

  /// Generate a human-readable alert message for a limit breach.
  static String getAlertMessage(SpendingLimit limit, double spent) {
    final percent = getPercentUsed(spent, limit.amount);
    final over = spent - limit.amount;
    final cat = limit.category ?? 'Overall';
    final mode = limit.isFamily ? 'Family' : 'Your';
    final period = limit.typeName.toLowerCase();

    if (percent >= 100) {
      return '$mode $period $cat budget exceeded by ৳${over.toStringAsFixed(0)}!';
    } else if (percent >= 90) {
      return '⚠️ $mode $period $cat budget is at ${percent.toStringAsFixed(0)}%! Almost exceeded.';
    } else if (percent >= 70) {
      return '$mode $period $cat budget is ${percent.toStringAsFixed(0)}% used. Be careful!';
    }
    return '$mode $period $cat budget is on track.';
  }

  /// Generate AI spending insights based on expense patterns.
  static List<String> getAIInsights(List<Expense> expenses) {
    if (expenses.isEmpty) return ['Start tracking to get insights! 📊'];

    final insights = <String>[];
    final now = DateTime.now();
    final thisMonth = expenses.where((e) => e.date.isSameMonth(now) && !e.isIncome).toList();
    final lastMonth = expenses
        .where((e) =>
            e.date.month == (now.month == 1 ? 12 : now.month - 1) &&
            e.date.year == (now.month == 1 ? now.year - 1 : now.year) &&
            !e.isIncome)
        .toList();

    // Weekend spending pattern
    final weekendSpend = thisMonth
        .where((e) => e.date.weekday == 6 || e.date.weekday == 7)
        .fold(0.0, (s, e) => s + e.amount);
    final weekdaySpend = thisMonth
        .where((e) => e.date.weekday >= 1 && e.date.weekday <= 5)
        .fold(0.0, (s, e) => s + e.amount);
    if (weekendSpend > weekdaySpend * 0.6 && weekendSpend > 0) {
      insights.add('🎉 Weekend spending spikes detected — you spend ${(weekendSpend / (weekendSpend + weekdaySpend) * 100).toStringAsFixed(0)}% on weekends!');
    }

    // Month-over-month comparison
    if (lastMonth.isNotEmpty && thisMonth.isNotEmpty) {
      final thisTotal = thisMonth.fold(0.0, (s, e) => s + e.amount);
      final lastTotal = lastMonth.fold(0.0, (s, e) => s + e.amount);
      final change = ((thisTotal - lastTotal) / lastTotal * 100);
      if (change > 15) {
        insights.add('📈 Spending increased ${change.toStringAsFixed(0)}% compared to last month.');
      } else if (change < -15) {
        insights.add('📉 Great job! Spending decreased ${change.abs().toStringAsFixed(0)}% from last month.');
      }
    }

    // Category analysis — find top spending category
    final catTotals = <String, double>{};
    for (final e in thisMonth) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    if (catTotals.isNotEmpty) {
      final topCat = catTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add('💰 ${topCat.key} is your biggest spending category at ৳${topCat.value.toStringAsFixed(0)} this month.');
    }

    // Month-end pattern
    if (now.day > 20) {
      final lateSpend = thisMonth
          .where((e) => e.date.day > 20)
          .fold(0.0, (s, e) => s + e.amount);
      final earlySpend = thisMonth
          .where((e) => e.date.day <= 20)
          .fold(0.0, (s, e) => s + e.amount);
      if (lateSpend > earlySpend * 0.4 && lateSpend > 0) {
        insights.add('📅 You tend to spend more near month-end. Watch out!');
      }
    }

    // Daily average
    if (thisMonth.isNotEmpty) {
      final total = thisMonth.fold(0.0, (s, e) => s + e.amount);
      final avg = total / now.day;
      insights.add('📊 Your daily spending average is ৳${avg.toStringAsFixed(0)} this month.');
    }

    // Add a random motivational if we have few insights
    if (insights.length < 2) {
      final tips = [
        '💡 Set category-specific limits to control spending better!',
        '🎯 Try the 50/30/20 rule: Needs / Wants / Savings.',
        '🏦 Automate your savings before spending the rest.',
      ];
      insights.add(tips[_random.nextInt(tips.length)]);
    }

    return insights;
  }

  /// Generate AI warning for limit exceeded (used in popup).
  static String getAIWarning(String category, double spent, double limit) {
    final over = spent - limit;
    final messages = [
      'Your wallet is literally crying right now 😭 Over by ৳${over.toStringAsFixed(0)}!',
      'Budget? What budget? You just blew past it by ৳${over.toStringAsFixed(0)} 💸',
      'Financial discipline called — it wants a word with you 📞',
      'At this rate, you\'ll need a budget for your budget 🤯',
      'Plot twist: the $category budget was supposed to LIMIT spending 🎬',
    ];
    return messages[_random.nextInt(messages.length)];
  }
}
