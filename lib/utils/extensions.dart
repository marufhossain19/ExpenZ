/// Helpful extension methods used throughout the app.
library;

extension DateTimeExtensions on DateTime {
  /// Check if this date is the same day as [other]
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Check if this date is in the same month as [other]
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Get start of the day (midnight)
  DateTime get startOfDay => DateTime(year, month, day);

  /// Get end of the day (23:59:59)
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);

  /// Get start of the month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Get end of the month
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);
}

extension StringExtensions on String {
  /// Capitalize the first letter
  String get capitalized {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize each word
  String get titleCase {
    return split(' ').map((word) => word.capitalized).join(' ');
  }
}

extension DoubleExtensions on double {
  /// Check if this value is effectively zero
  bool get isEffectivelyZero => abs() < 0.01;
}
