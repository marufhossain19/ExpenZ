import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/spending_limit.dart';
import '../models/budget_alert.dart';
import '../models/notification_item.dart';
import '../core/constants.dart';

/// Service layer for all Hive database operations.
/// Supports user-scoped boxes for multi-account data isolation.
class HiveService {
  static const String _pendingFamilyInviteEmailsKey = 'pending_family_invite_emails';

  // ── Shared boxes (not user-scoped) ─────────────────────────
  late Box<ExpenseCategory> _categoryBox;
  late Box _settingsBox;

  // ── User-scoped boxes ──────────────────────────────────────
  Box<Expense>? _expenseBox;
  Box<SpendingLimit>? _limitBox;
  Box<BudgetAlert>? _alertBox;
  Box<NotificationItem>? _notificationBox;

  /// The user ID whose boxes are currently open, or null.
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  /// Whether user-scoped boxes are open and ready.
  bool get hasUserBoxes => _expenseBox?.isOpen == true;

  /// Initialize Hive, register adapters, and open shared boxes.
  /// Call once in main() before runApp().
  Future<void> init() async {
    await Hive.initFlutter();

    // Register TypeAdapters
    if (!Hive.isAdapterRegistered(HiveTypeIds.expense)) {
      Hive.registerAdapter(ExpenseAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.category)) {
      Hive.registerAdapter(ExpenseCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.spendingLimit)) {
      Hive.registerAdapter(SpendingLimitAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.budgetAlert)) {
      Hive.registerAdapter(BudgetAlertAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveTypeIds.notificationItem)) {
      Hive.registerAdapter(NotificationItemAdapter());
    }

    // Open shared boxes (categories + settings are shared across accounts)
    _categoryBox = await Hive.openBox<ExpenseCategory>(HiveBoxes.categories);
    _settingsBox = await Hive.openBox(HiveBoxes.settings);

    debugPrint('[HiveService] init complete — shared boxes opened');

    // Seed default categories on first launch
    await _seedDefaultCategories();
  }

  // ══════════════════════════════════════════════════════════════
  // USER-SCOPED BOX MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Open user-scoped boxes for the given user ID.
  /// Must be called after login / session restore, before any data access.
  Future<void> openUserBoxes(String userId) async {
    // If already open for this user, skip
    if (_currentUserId == userId && hasUserBoxes) {
      debugPrint('[HiveService] User boxes already open for $userId');
      return;
    }

    // Close any previously open user boxes
    await closeUserBoxes();

    _currentUserId = userId;
    final shortId = userId.length > 8 ? userId.substring(0, 8) : userId;

    _expenseBox = await Hive.openBox<Expense>('expenses_$shortId');
    _limitBox = await Hive.openBox<SpendingLimit>('limits_$shortId');
    _alertBox = await Hive.openBox<BudgetAlert>('alerts_$shortId');
    _notificationBox = await Hive.openBox<NotificationItem>('notifs_$shortId');

    debugPrint('[HiveService] User boxes opened for $shortId — '
        'expenses: ${_expenseBox!.length}, '
        'limits: ${_limitBox!.length}, '
        'alerts: ${_alertBox!.length}, '
        'notifs: ${_notificationBox!.length}');
  }

  /// Close user-scoped boxes (call on logout / account switch).
  Future<void> closeUserBoxes() async {
    try {
      if (_expenseBox?.isOpen == true) await _expenseBox!.close();
      if (_limitBox?.isOpen == true) await _limitBox!.close();
      if (_alertBox?.isOpen == true) await _alertBox!.close();
      if (_notificationBox?.isOpen == true) await _notificationBox!.close();
    } catch (e) {
      debugPrint('[HiveService] Error closing user boxes: $e');
    }
    _expenseBox = null;
    _limitBox = null;
    _alertBox = null;
    _notificationBox = null;
    _currentUserId = null;
    debugPrint('[HiveService] User boxes closed');
  }

  // ── Settings ────────────────────────────────────────────

  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  List<String> getPendingFamilyInviteEmails() {
    final raw = _settingsBox.get(_pendingFamilyInviteEmailsKey);
    if (raw is List) {
      return raw.map((e) => e.toString().toLowerCase()).toList();
    }
    return [];
  }

  Future<void> addPendingFamilyInviteEmail(String email) async {
    final norm = email.trim().toLowerCase();
    if (norm.isEmpty) return;
    final set = getPendingFamilyInviteEmails().toSet()..add(norm);
    await _settingsBox.put(_pendingFamilyInviteEmailsKey, set.toList());
  }

  Future<void> removePendingFamilyInviteEmail(String email) async {
    final norm = email.trim().toLowerCase();
    final next = getPendingFamilyInviteEmails().where((e) => e != norm).toList();
    if (next.isEmpty) {
      await _settingsBox.delete(_pendingFamilyInviteEmailsKey);
    } else {
      await _settingsBox.put(_pendingFamilyInviteEmailsKey, next);
    }
  }

  Future<void> clearPendingFamilyInviteEmails() async {
    await _settingsBox.delete(_pendingFamilyInviteEmailsKey);
  }

  // ══════════════════════════════════════════════════════════════
  // EXPENSES — User-scoped CRUD + Cache
  // ══════════════════════════════════════════════════════════════

  List<Expense> getAllExpenses() {
    if (_expenseBox == null || !_expenseBox!.isOpen) {
      debugPrint('[HiveService] getAllExpenses: box not open, returning empty');
      return [];
    }
    final expenses = _expenseBox!.values.toList();
    expenses.sort((a, b) => b.date.compareTo(a.date));
    return expenses;
  }

  Future<void> addExpense(Expense expense) async {
    if (_expenseBox == null || !_expenseBox!.isOpen) return;
    await _expenseBox!.put(expense.id, expense);
  }

  Future<void> deleteExpense(String id) async {
    if (_expenseBox == null || !_expenseBox!.isOpen) return;
    await _expenseBox!.delete(id);
  }

  Future<void> updateExpense(Expense expense) async {
    if (_expenseBox == null || !_expenseBox!.isOpen) return;
    await _expenseBox!.put(expense.id, expense);
  }

  /// Replace entire expense cache with fresh data from Supabase.
  Future<void> cacheExpenses(List<Expense> expenses) async {
    if (_expenseBox == null || !_expenseBox!.isOpen) return;
    await _expenseBox!.clear();
    for (final e in expenses) {
      await _expenseBox!.put(e.id, e);
    }
    debugPrint('[HiveService] Cached ${expenses.length} expenses');
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return getAllExpenses()
        .where((e) => e.date.isAfter(start) && e.date.isBefore(end))
        .toList();
  }

  List<Expense> getExpensesByCategory(String category) {
    return getAllExpenses().where((e) => e.category == category).toList();
  }

  // ══════════════════════════════════════════════════════════════
  // CATEGORIES — Shared CRUD
  // ══════════════════════════════════════════════════════════════

  List<ExpenseCategory> getAllCategories() {
    return _categoryBox.values.toList();
  }

  Future<void> addCategory(ExpenseCategory category) async {
    await _categoryBox.put(category.name, category);
  }

  Future<void> deleteCategory(String name) async {
    await _categoryBox.delete(name);
  }

  bool categoryExists(String name) {
    return _categoryBox.containsKey(name);
  }

  // ══════════════════════════════════════════════════════════════
  // SPENDING LIMITS — User-scoped CRUD + Cache
  // ══════════════════════════════════════════════════════════════

  List<SpendingLimit> getAllLimits() {
    if (_limitBox == null || !_limitBox!.isOpen) return [];
    return _limitBox!.values.toList();
  }

  Future<void> addLimit(SpendingLimit limit) async {
    if (_limitBox == null || !_limitBox!.isOpen) return;
    await _limitBox!.put(limit.id, limit);
  }

  Future<void> updateLimit(SpendingLimit limit) async {
    if (_limitBox == null || !_limitBox!.isOpen) return;
    await _limitBox!.put(limit.id, limit);
  }

  Future<void> deleteLimit(String id) async {
    if (_limitBox == null || !_limitBox!.isOpen) return;
    await _limitBox!.delete(id);
  }

  /// Replace entire limits cache with fresh data from Supabase.
  Future<void> cacheLimits(List<SpendingLimit> limits) async {
    if (_limitBox == null || !_limitBox!.isOpen) return;
    await _limitBox!.clear();
    for (final l in limits) {
      await _limitBox!.put(l.id, l);
    }
    debugPrint('[HiveService] Cached ${limits.length} limits');
  }

  // ══════════════════════════════════════════════════════════════
  // BUDGET ALERTS — User-scoped CRUD + Cache
  // ══════════════════════════════════════════════════════════════

  List<BudgetAlert> getAllAlerts() {
    if (_alertBox == null || !_alertBox!.isOpen) return [];
    final alerts = _alertBox!.values.toList();
    alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return alerts;
  }

  Future<void> addAlert(BudgetAlert alert) async {
    if (_alertBox == null || !_alertBox!.isOpen) return;
    await _alertBox!.put(alert.id, alert);
  }

  Future<void> updateAlert(BudgetAlert alert) async {
    if (_alertBox == null || !_alertBox!.isOpen) return;
    await _alertBox!.put(alert.id, alert);
  }

  Future<void> deleteAlert(String id) async {
    if (_alertBox == null || !_alertBox!.isOpen) return;
    await _alertBox!.delete(id);
  }

  Future<void> clearAlerts() async {
    if (_alertBox == null || !_alertBox!.isOpen) return;
    await _alertBox!.clear();
  }

  /// Replace entire alerts cache with fresh data from Supabase.
  Future<void> cacheAlerts(List<BudgetAlert> alerts) async {
    if (_alertBox == null || !_alertBox!.isOpen) return;
    await _alertBox!.clear();
    for (final a in alerts) {
      await _alertBox!.put(a.id, a);
    }
    debugPrint('[HiveService] Cached ${alerts.length} alerts');
  }

  // ══════════════════════════════════════════════════════════════
  // NOTIFICATIONS — User-scoped CRUD + Cache
  // ══════════════════════════════════════════════════════════════

  List<NotificationItem> getAllNotifications() {
    if (_notificationBox == null || !_notificationBox!.isOpen) return [];
    final items = _notificationBox!.values.toList();
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  Future<void> addNotification(NotificationItem item) async {
    if (_notificationBox == null || !_notificationBox!.isOpen) return;
    await _notificationBox!.put(item.id, item);
  }

  Future<void> updateNotification(NotificationItem item) async {
    if (_notificationBox == null || !_notificationBox!.isOpen) return;
    await _notificationBox!.put(item.id, item);
  }

  Future<void> deleteNotification(String id) async {
    if (_notificationBox == null || !_notificationBox!.isOpen) return;
    await _notificationBox!.delete(id);
  }

  Future<void> clearNotifications() async {
    if (_notificationBox == null || !_notificationBox!.isOpen) return;
    await _notificationBox!.clear();
  }

  /// Replace entire notifications cache with fresh data from Supabase.
  Future<void> cacheNotifications(List<NotificationItem> notifications) async {
    if (_notificationBox == null || !_notificationBox!.isOpen) return;
    await _notificationBox!.clear();
    for (final n in notifications) {
      await _notificationBox!.put(n.id, n);
    }
    debugPrint('[HiveService] Cached ${notifications.length} notifications');
  }

  // ── Seeding ─────────────────────────────────────────────

  Future<void> _seedDefaultCategories() async {
    if (_categoryBox.isEmpty) {
      for (final cat in DefaultCategories.all) {
        final category = ExpenseCategory(
          name: cat['name'] as String,
          iconCodePoint: cat['icon'] as int,
          colorValue: cat['color'] as int,
          isDefault: cat['isDefault'] as bool,
          supabaseId: null,
        );
        await _categoryBox.put(category.name, category);
      }
    }
  }

  /// Close all boxes
  Future<void> close() async {
    await closeUserBoxes();
    await _categoryBox.close();
    await _settingsBox.close();
  }
}
