import 'package:intl/intl.dart';

/// Currency and date formatting utilities.
class Formatters {
  /// Format a number as currency (e.g., $1,234.56)
  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '৳',
      decimalDigits: 2,
      locale: 'en_US',
    );
    return formatter.format(amount);
  }

  /// Short currency without decimals for large numbers
  static String currencyShort(double amount) {
    if (amount >= 1000000) {
      return '৳${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '৳${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '৳${amount.toStringAsFixed(0)}';
  }

  /// Format date as "May 13, 2026"
  static String dateFullMonth(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date as "13 May"
  static String dateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  /// Format time as "11:30 AM"
  static String time(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Relative date: "Today", "Yesterday", or the formatted date
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    final difference = today.difference(dateOnly).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return DateFormat('EEEE').format(date); // "Monday"
    return dateFullMonth(date);
  }

  /// Relative date WITH time: "Today • 8:42 PM", "Yesterday • 10:15 AM", "12 July 2026 • 9:20 PM"
  static String relativeDateWithTime(DateTime date) {
    final rel = relativeDate(date);
    final t = time(date);
    return '$rel • $t';
  }

  /// Full date with time: "12 July 2026 • 8:32 PM"
  static String fullDateWithTime(DateTime date) {
    return '${DateFormat('dd MMMM yyyy').format(date)} • ${time(date)}';
  }

  /// Day of month: "12"
  static String dateDay(DateTime date) {
    return DateFormat('dd').format(date);
  }

  /// Full date: "12 July 2026"
  static String dateFull(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  /// Format month header: "May 2026"
  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Short month: "Jul"
  static String monthShort(DateTime date) {
    return DateFormat('MMM').format(date);
  }
}
