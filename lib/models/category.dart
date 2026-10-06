import 'package:hive/hive.dart';

part 'category.g.dart';

/// Represents an expense/income category with visual properties.
@HiveType(typeId: 1)
class ExpenseCategory extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int iconCodePoint;

  @HiveField(2)
  final int colorValue;

  @HiveField(3)
  final bool isDefault;

  /// Supabase row id when loaded from cloud (null for offline-only rows).
  @HiveField(4)
  final String? supabaseId;

  ExpenseCategory({
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    this.isDefault = false,
    this.supabaseId,
  });
}
