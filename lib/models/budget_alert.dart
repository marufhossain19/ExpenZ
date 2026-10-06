import 'package:hive/hive.dart';

part 'budget_alert.g.dart';

/// Represents an alert triggered when a spending limit threshold is crossed.
@HiveType(typeId: 3)
class BudgetAlert extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String limitId;

  @HiveField(2)
  final String message;

  /// 0=safe, 1=warning, 2=danger, 3=exceeded
  @HiveField(3)
  final int level;

  @HiveField(4)
  final double amountSpent;

  @HiveField(5)
  final double amountLimit;

  @HiveField(6)
  final String? category;

  @HiveField(7)
  final bool isFamily;

  @HiveField(8)
  final DateTime timestamp;

  @HiveField(9)
  bool isDismissed;

  BudgetAlert({
    required this.id,
    required this.limitId,
    required this.message,
    required this.level,
    required this.amountSpent,
    required this.amountLimit,
    this.category,
    this.isFamily = false,
    required this.timestamp,
    this.isDismissed = false,
  });

  String get levelName {
    switch (level) {
      case 0: return 'Safe';
      case 1: return 'Warning';
      case 2: return 'Danger';
      case 3: return 'Exceeded';
      default: return 'Unknown';
    }
  }

  double get percentUsed =>
      amountLimit > 0 ? (amountSpent / amountLimit * 100) : 0;
}
