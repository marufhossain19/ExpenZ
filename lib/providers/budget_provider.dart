import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/spending_limit.dart';
import '../models/budget_alert.dart';
import '../models/expense.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';
import '../services/budget_service.dart';
import '../core/constants.dart';

bool _dynBool(dynamic v, [bool d = true]) {
  if (v == null) return d;
  if (v is bool) return v;
  if (v is int) return v != 0;
  if (v is String) {
    final l = v.toLowerCase();
    if (l == 'true' || l == '1') return true;
    if (l == 'false' || l == '0') return false;
  }
  return d;
}

/// Manages spending limits, budget tracking, and alert generation.
/// In cloud mode, all writes go to BOTH Supabase and Hive (dual-write cache).
class BudgetProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SupabaseService _supabaseService;
  List<SpendingLimit> _limits = [];
  List<BudgetAlert> _alerts = [];
  bool _isCloudMode = false;
  Map<String, Map<String, dynamic>> _statusCache = {};
  BudgetAlert? pendingPopupAlert;

  BudgetProvider(this._hiveService, this._supabaseService) {
    debugPrint('[BudgetProvider] Created (no auto-load)');
  }

  List<SpendingLimit> get limits => _limits;
  List<SpendingLimit> get enabledLimits => _limits.where((l) => l.isEnabled).toList();
  List<SpendingLimit> get personalLimits => _limits.where((l) => !l.isFamily).toList();
  List<SpendingLimit> get familyLimits => _limits.where((l) => l.isFamily).toList();
  List<BudgetAlert> get alerts => _alerts;
  List<BudgetAlert> get activeAlerts => _alerts.where((a) => !a.isDismissed).toList();
  Map<String, dynamic>? getStatus(String limitId) => _statusCache[limitId];

  int get highestAlertLevel {
    if (_statusCache.isEmpty) return AlertLevel.safe;
    return _statusCache.values.map((s) => s['level'] as int).reduce((a, b) => a > b ? a : b);
  }

  String? get criticalAlertMessage {
    final critical = activeAlerts.where((a) => a.level >= AlertLevel.danger).toList();
    if (critical.isEmpty) return null;
    return critical.first.message;
  }

  bool get hasWarnings => highestAlertLevel >= AlertLevel.warning;

  void _loadLocalData() {
    _limits = _hiveService.getAllLimits();
    _alerts = _hiveService.getAllAlerts().where((a) => !a.isDismissed).toList();
    debugPrint('[BudgetProvider] _loadLocalData: ${_limits.length} limits, ${_alerts.length} alerts');
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (!_supabaseService.isEnabled || _supabaseService.currentUserId == null) {
      _loadLocalData();
      return;
    }
    _isCloudMode = true;
    final uid = _supabaseService.currentUserId!;
    debugPrint('[BudgetProvider] loadUserData: cloud mode for ${uid.substring(0, 8)}');

    // Load cached first
    _limits = _hiveService.getAllLimits();
    _alerts = _hiveService.getAllAlerts().where((a) => !a.isDismissed).toList();
    if (_limits.isNotEmpty || _alerts.isNotEmpty) notifyListeners();

    try {
      await _supabaseService.ensureSessionReady();
      final limitRows = await _supabaseService.fetchLimits();
      _limits = limitRows.map((row) => SpendingLimit(
        id: row['id'] as String, type: row['type'] as int,
        amount: (row['amount'] as num).toDouble(), category: row['category'] as String?,
        isFamily: _dynBool(row['is_family'], false), isEnabled: _dynBool(row['is_enabled'], true),
        createdAt: DateTime.parse(row['created_at'] as String),
      )).toList();
      await _hiveService.cacheLimits(_limits);

      final alertRows = await _supabaseService.fetchAlerts();
      _alerts = alertRows.where((row) => !_dynBool(row['is_dismissed'], false)).map((row) => BudgetAlert(
        id: row['id'] as String, limitId: row['limit_id'] as String,
        message: row['message'] as String, level: row['level'] as int,
        amountSpent: (row['amount_spent'] as num).toDouble(),
        amountLimit: (row['amount_limit'] as num).toDouble(),
        category: row['category'] as String?, isFamily: _dynBool(row['is_family'], false),
        isDismissed: _dynBool(row['is_dismissed'], false),
        timestamp: DateTime.parse(row['created_at'] as String),
      )).toList();
      await _hiveService.cacheAlerts(_alerts);
      debugPrint('[BudgetProvider] loadUserData: ${_limits.length} limits, ${_alerts.length} alerts from Supabase');
      notifyListeners();
    } catch (e) {
      debugPrint('[BudgetProvider] loadUserData error: $e');
      notifyListeners();
    }
  }

  void clearLocalData() {
    debugPrint('[BudgetProvider] clearLocalData');
    _limits = []; _alerts = []; _statusCache = {}; _isCloudMode = false;
    pendingPopupAlert = null; notifyListeners();
  }

  void loadOfflineData() { _isCloudMode = false; _loadLocalData(); }

  Future<void> addLimit({required int type, required double amount, String? category, bool isFamily = false}) async {
    final id = const Uuid().v4();
    final limit = SpendingLimit(id: id, type: type, amount: amount, category: category, isFamily: isFamily, createdAt: DateTime.now());
    _limits.add(limit); notifyListeners();
    await _hiveService.addLimit(limit);
    if (_isCloudMode) {
      try { await _supabaseService.addLimit({'id': id, 'type': type, 'amount': amount, 'category': category, 'is_family': isFamily, 'is_enabled': true}); } catch (e) { debugPrint('[BudgetProvider] addLimit cloud error: $e'); }
    }
  }

  Future<void> updateLimitAmount(String id, double newAmount) async {
    final idx = _limits.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    _limits[idx].amount = newAmount; notifyListeners();
    await _hiveService.updateLimit(_limits[idx]);
    if (_isCloudMode) { try { await _supabaseService.updateLimit(id, {'amount': newAmount}); } catch (e) { debugPrint('[BudgetProvider] updateLimit cloud error: $e'); } }
  }

  Future<void> setLimitEnabled(String id, bool enabled) async {
    final idx = _limits.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    if (_limits[idx].isEnabled == enabled) return;
    _limits[idx].isEnabled = enabled; notifyListeners();
    await _hiveService.updateLimit(_limits[idx]);
    if (_isCloudMode) { try { await _supabaseService.updateLimit(id, {'is_enabled': enabled}); } catch (e) { debugPrint('[BudgetProvider] setLimitEnabled cloud error: $e'); } }
  }

  Future<void> toggleLimit(String id) async {
    final idx = _limits.indexWhere((l) => l.id == id);
    if (idx == -1) return;
    await setLimitEnabled(id, !_limits[idx].isEnabled);
  }

  Future<void> deleteLimit(String id) async {
    _limits.removeWhere((l) => l.id == id); _statusCache.remove(id); notifyListeners();
    await _hiveService.deleteLimit(id);
    if (_isCloudMode) { try { await _supabaseService.deleteLimit(id); } catch (e) { debugPrint('[BudgetProvider] deleteLimit cloud error: $e'); } }
  }

  bool checkBudgets(List<Expense> expenses) {
    bool newExceeded = false;
    _statusCache = {};
    for (final limit in enabledLimits) {
      final spent = BudgetService.getSpendingForLimit(limit, expenses);
      final percent = BudgetService.getPercentUsed(spent, limit.amount);
      final level = BudgetService.getAlertLevel(percent);
      _statusCache[limit.id] = {
        'spent': spent,
        'percent': percent,
        'level': level,
        'remaining': (limit.amount - spent).clamp(0, double.infinity),
      };
      if (level >= AlertLevel.warning) {
        final existingAlert = _alerts.any((a) =>
            a.limitId == limit.id &&
            a.level == level &&
            a.timestamp.isAfter(
                DateTime.now().subtract(const Duration(hours: 1))));
        if (!existingAlert) {
          final alertId = const Uuid().v4();
          final alert = BudgetAlert(
            id: alertId,
            limitId: limit.id,
            message: BudgetService.getAlertMessage(limit, spent),
            level: level,
            amountSpent: spent,
            amountLimit: limit.amount,
            category: limit.category,
            isFamily: limit.isFamily,
            timestamp: DateTime.now(),
          );
          _alerts.insert(0, alert);
          _hiveService.addAlert(alert);

          // Sync to Supabase with visible error logging
          if (_isCloudMode) {
            _syncAlertToCloud(alertId, alert, level, spent);
          }

          if (level == AlertLevel.exceeded) {
            pendingPopupAlert = alert;
            newExceeded = true;
          }
        }
      }
    }
    // NOTE: Do NOT call notifyListeners() here — this method is called
    // directly from build() via Consumer. Listeners will be notified
    // by the next state change that triggers a real rebuild.
    return newExceeded;
  }

  /// Syncs a newly generated alert to Supabase in the background.
  Future<void> _syncAlertToCloud(
      String alertId, BudgetAlert alert, int level, double spent) async {
    try {
      await _supabaseService.addAlert({
        'id': alertId,
        'limit_id': alert.limitId,
        'message': alert.message,
        'level': level,
        'amount_spent': spent,
        'amount_limit': alert.amountLimit,
        'category': alert.category,
        'is_family': alert.isFamily,
        'is_dismissed': false,
      });
      debugPrint('[BudgetProvider] Alert synced to Supabase: $alertId');
    } catch (e, st) {
      debugPrint('[BudgetProvider] _syncAlertToCloud FAILED: $e\n$st');
    }
  }

  Future<void> removeAlert(String alertId) async {
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx == -1) return;
    _alerts.removeAt(idx);
    if (pendingPopupAlert?.id == alertId) pendingPopupAlert = null;
    notifyListeners();
    await _hiveService.deleteAlert(alertId);
    if (_isCloudMode) { try { await _supabaseService.deleteAlert(alertId); } catch (e) { debugPrint('[BudgetProvider] removeAlert cloud error: $e'); } }
  }

  void clearPendingPopup() { pendingPopupAlert = null; }

  Future<void> clearAlertHistory() async {
    // Always clear local state first, regardless of cloud result
    await _hiveService.clearAlerts();
    _alerts.clear();
    notifyListeners();
    // Best-effort cloud sync
    if (_isCloudMode) {
      try {
        await _supabaseService.clearAlerts();
        debugPrint('[BudgetProvider] clearAlertHistory: cloud alerts cleared');
      } catch (e) {
        debugPrint('[BudgetProvider] clearAlertHistory cloud error (local cleared): $e');
      }
    }
  }

  List<String> getInsights(List<Expense> expenses) => BudgetService.getAIInsights(expenses);
}
