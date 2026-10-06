import 'package:hive/hive.dart';

part 'expense.g.dart';

/// Represents a single financial transaction (expense or income).
@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String category;

  @HiveField(4)
  final int categoryIcon;

  @HiveField(5)
  final int categoryColor;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final bool isIncome;

  @HiveField(8)
  final String? note;

  @HiveField(9)
  final String? userName;

  @HiveField(10)
  final bool isFamily;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.date,
    this.isIncome = false,
    this.note,
    this.userName,
    this.isFamily = false,
  });

  /// Create a copy with modified fields
  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    int? categoryIcon,
    int? categoryColor,
    DateTime? date,
    bool? isIncome,
    String? note,
    String? userName,
    bool? isFamily,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      date: date ?? this.date,
      isIncome: isIncome ?? this.isIncome,
      note: note ?? this.note,
      userName: userName ?? this.userName,
      isFamily: isFamily ?? this.isFamily,
    );
  }
}
