import 'package:flutter/material.dart';
import '../models/expense.dart';

/// Manages search query and filter state for expense list.
class SearchProvider extends ChangeNotifier {
  String _query = '';
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showIncomeOnly = false;
  bool _showExpenseOnly = false;

  // ── Getters ─────────────────────────────────────────────
  String get query => _query;
  String? get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get showIncomeOnly => _showIncomeOnly;
  bool get showExpenseOnly => _showExpenseOnly;
  bool get hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedCategory != null ||
      _startDate != null ||
      _showIncomeOnly ||
      _showExpenseOnly;

  // ── Setters ─────────────────────────────────────────────

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    _startDate = start;
    _endDate = end;
    notifyListeners();
  }

  void setShowIncomeOnly(bool value) {
    _showIncomeOnly = value;
    if (value) _showExpenseOnly = false;
    notifyListeners();
  }

  void setShowExpenseOnly(bool value) {
    _showExpenseOnly = value;
    if (value) _showIncomeOnly = false;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _query = '';
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    _showIncomeOnly = false;
    _showExpenseOnly = false;
    notifyListeners();
  }

  /// Apply all filters to an expense list
  List<Expense> filterExpenses(List<Expense> expenses) {
    var filtered = expenses;

    // Text search
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.category.toLowerCase().contains(q) ||
              (e.note?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Category filter
    if (_selectedCategory != null) {
      filtered =
          filtered.where((e) => e.category == _selectedCategory).toList();
    }

    // Date range filter
    if (_startDate != null) {
      filtered = filtered.where((e) => e.date.isAfter(_startDate!)).toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((e) => e.date.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Type filters
    if (_showIncomeOnly) {
      filtered = filtered.where((e) => e.isIncome).toList();
    } else if (_showExpenseOnly) {
      filtered = filtered.where((e) => !e.isIncome).toList();
    }

    return filtered;
  }
}
