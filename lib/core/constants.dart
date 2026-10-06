/// Application-wide constants for the Expense Tracker app.
library;

/// Hive box names
class HiveBoxes {
  static const String expenses = 'expenses_box';
  static const String categories = 'categories_box';
  static const String settings = 'settings_box';
  static const String spendingLimits = 'spending_limits_box';
  static const String budgetAlerts = 'budget_alerts_box';
  static const String notifications = 'notifications_box';
}

/// Hive Type IDs
class HiveTypeIds {
  static const int expense = 0;
  static const int category = 1;
  static const int spendingLimit = 2;
  static const int budgetAlert = 3;
  static const int notificationItem = 4;
}

/// Spending limit period types
class LimitType {
  static const int daily = 0;
  static const int weekly = 1;
  static const int monthly = 2;
}

/// Budget alert severity levels with thresholds
class AlertLevel {
  static const int safe = 0;      // 0% - 70%
  static const int warning = 1;   // 70% - 90%
  static const int danger = 2;    // 90% - 100%
  static const int exceeded = 3;  // 100%+

  static const double warningThreshold = 70.0;
  static const double dangerThreshold = 90.0;
  static const double exceededThreshold = 100.0;

  static int fromPercent(double percent) {
    if (percent >= exceededThreshold) return exceeded;
    if (percent >= dangerThreshold) return danger;
    if (percent >= warningThreshold) return warning;
    return safe;
  }
}

/// Animation durations used throughout the app
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);
}

/// Default category definitions with icon code points and colors
class DefaultCategories {
  static const List<Map<String, dynamic>> all = [
    {'name': 'Food', 'icon': 0xe57a, 'color': 0xFFFF6B6B, 'isDefault': true},
    {'name': 'Shopping', 'icon': 0xef17, 'color': 0xFF6C5CE7, 'isDefault': true},
    {'name': 'Transport', 'icon': 0xe1d7, 'color': 0xFF00CEC9, 'isDefault': true},
    {'name': 'Bills', 'icon': 0xef64, 'color': 0xFFFFA502, 'isDefault': true},
    {'name': 'Entertainment', 'icon': 0xe5dc, 'color': 0xFFE84393, 'isDefault': true},
    {'name': 'Health', 'icon': 0xf109, 'color': 0xFF00B894, 'isDefault': true},
    {'name': 'Salary', 'icon': 0xe0af, 'color': 0xFF55EFC4, 'isDefault': true},
    {'name': 'Education', 'icon': 0xe80c, 'color': 0xFF74B9FF, 'isDefault': true},
  ];
}
