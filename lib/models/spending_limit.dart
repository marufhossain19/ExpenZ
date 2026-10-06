import 'package:hive/hive.dart';

part 'spending_limit.g.dart';

/// Represents a spending limit (daily/weekly/monthly) for a user or family.
@HiveType(typeId: 2)
class SpendingLimit extends HiveObject {
  @HiveField(0)
  final String id;

  /// 0 = daily, 1 = weekly, 2 = monthly
  @HiveField(1)
  final int type;

  @HiveField(2)
  double amount;

  /// null = overall limit, non-null = category-specific limit
  @HiveField(3)
  final String? category;

  @HiveField(4)
  final bool isFamily;

  @HiveField(5)
  bool isEnabled;

  @HiveField(6)
  final DateTime createdAt;

  SpendingLimit({
    required this.id,
    required this.type,
    required this.amount,
    this.category,
    this.isFamily = false,
    this.isEnabled = true,
    required this.createdAt,
  });

  String get typeName {
    switch (type) {
      case 0: return 'Daily';
      case 1: return 'Weekly';
      case 2: return 'Monthly';
      default: return 'Unknown';
    }
  }

  String get label {
    final cat = category ?? 'Overall';
    final mode = isFamily ? 'Family' : 'Personal';
    return '$mode $typeName — $cat';
  }
}
