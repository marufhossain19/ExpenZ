import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/notification_item.dart';
import '../services/hive_service.dart';
import '../services/supabase_service.dart';

bool _dynBool(dynamic v, [bool d = false]) {
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

/// Manages in-app notifications. Dual-write to Supabase + Hive in cloud mode.
class NotificationProvider extends ChangeNotifier {
  final HiveService _hiveService;
  final SupabaseService _supabaseService;
  List<NotificationItem> _notifications = [];
  bool _isCloudMode = false;

  NotificationProvider(this._hiveService, this._supabaseService) {
    debugPrint('[NotificationProvider] Created (no auto-load)');
  }

  List<NotificationItem> get notifications => _notifications;
  List<NotificationItem> get unread => _notifications.where((n) => !n.isRead).toList();
  int get unreadCount => unread.length;
  bool get hasUnread => unreadCount > 0;

  void _loadLocalData() {
    _notifications = _hiveService.getAllNotifications();
    debugPrint('[NotificationProvider] _loadLocalData: ${_notifications.length} notifications');
    notifyListeners();
  }

  Future<void> loadUserData() async {
    if (!_supabaseService.isEnabled || _supabaseService.currentUserId == null) {
      _loadLocalData(); return;
    }
    _isCloudMode = true;
    final uid = _supabaseService.currentUserId!;
    debugPrint('[NotificationProvider] loadUserData: cloud mode for ${uid.substring(0, 8)}');

    _notifications = _hiveService.getAllNotifications();
    if (_notifications.isNotEmpty) notifyListeners();

    try {
      await _supabaseService.ensureSessionReady();
      final rows = await _supabaseService.fetchNotifications();
      _notifications = rows.map((row) => NotificationItem(
        id: row['id'] as String, title: row['title'] as String,
        body: row['body'] as String, type: row['type'] as int,
        isRead: _dynBool(row['is_read'], false),
        timestamp: DateTime.parse(row['created_at'] as String),
        relatedEmail: row['related_email'] as String?,
        inviteStatus: row['invite_status'] as String?,
      )).toList();
      await _hiveService.cacheNotifications(_notifications);
      debugPrint('[NotificationProvider] loadUserData: ${_notifications.length} from Supabase');
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationProvider] loadUserData error: $e');
      notifyListeners();
    }
  }

  void clearLocalData() {
    debugPrint('[NotificationProvider] clearLocalData');
    _notifications = []; _isCloudMode = false;
    unawaited(_hiveService.clearPendingFamilyInviteEmails());
    notifyListeners();
  }

  void loadOfflineData() { _isCloudMode = false; _loadLocalData(); }

  List<String> get pendingFamilyInviteEmails => _hiveService.getPendingFamilyInviteEmails();

  Future<void> removePendingFamilyInvite(String email) async {
    await _hiveService.removePendingFamilyInviteEmail(email); notifyListeners();
  }

  Future<void> addBudgetNotification(String title, String body) async {
    final id = const Uuid().v4();
    final item = NotificationItem(id: id, title: title, body: body, type: 0, timestamp: DateTime.now());
    _notifications.insert(0, item); notifyListeners();
    await _hiveService.addNotification(item);
    if (_isCloudMode) { try { await _supabaseService.addNotification({'id': id, 'title': title, 'body': body, 'type': 0, 'is_read': false}); } catch (e) { debugPrint('[NotificationProvider] addBudget cloud error: $e'); } }
  }

  Future<void> addFamilyNotification(String title, String body) async {
    final id = const Uuid().v4();
    final item = NotificationItem(id: id, title: title, body: body, type: 1, timestamp: DateTime.now());
    _notifications.insert(0, item); notifyListeners();
    await _hiveService.addNotification(item);
    if (_isCloudMode) { try { await _supabaseService.addNotification({'id': id, 'title': title, 'body': body, 'type': 1, 'is_read': false}); } catch (e) { debugPrint('[NotificationProvider] addFamily cloud error: $e'); } }
  }

  Future<void> addInsightNotification(String title, String body) async {
    final id = const Uuid().v4();
    final item = NotificationItem(id: id, title: title, body: body, type: 2, timestamp: DateTime.now());
    _notifications.insert(0, item); notifyListeners();
    await _hiveService.addNotification(item);
    if (_isCloudMode) { try { await _supabaseService.addNotification({'id': id, 'title': title, 'body': body, 'type': 2, 'is_read': false}); } catch (e) { debugPrint('[NotificationProvider] addInsight cloud error: $e'); } }
  }

  Future<String> sendFamilyInvite(String email) async {
    if (!_isCloudMode) return 'error';
    final normalized = email.trim().toLowerCase();
    try {
      final currentEmail = _supabaseService.currentUser?.email;
      if (currentEmail != null && currentEmail.toLowerCase() == normalized) return 'self_invite';
      if (_hiveService.getPendingFamilyInviteEmails().contains(normalized)) return 'already_sent';
      final recipientId = await _supabaseService.getUserIdByEmail(email);
      if (recipientId == null) return 'not_found';
      final senderName = _supabaseService.getUserDisplayName();
      final senderEmail = _supabaseService.currentUser?.email ?? 'Unknown';
      try {
        await _supabaseService.sendNotificationToUser(recipientUserId: recipientId, title: 'Family Invite', body: '$senderName ($senderEmail) wants to add you as a family member', type: 3, relatedEmail: senderEmail, inviteStatus: 'pending');
      } catch (e) { debugPrint('RPC failed: $e'); return 'error'; }
      await _hiveService.addPendingFamilyInviteEmail(email);
      return 'sent';
    } catch (e) { debugPrint('Error sending family invite: $e'); return 'error'; }
  }

  Future<bool> acceptInvite(String notificationId) async {
    if (!_isCloudMode) return false;
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1) return false;
    final notification = _notifications[idx];
    if (notification.type != 3 || notification.inviteStatus != 'pending') return false;
    final senderEmail = notification.relatedEmail;
    if (senderEmail == null) return false;
    try {
      final senderId = await _supabaseService.getUserIdByEmail(senderEmail);
      if (senderId == null) return false;
      final familyId = await _supabaseService.createFamily('Family Group');
      if (familyId == null) throw Exception('createFamily failed');
      await _supabaseService.addFamilyMember(familyId: familyId, userId: senderId, role: 'member', status: 'accepted');
      await _supabaseService.addFamilyMember(familyId: familyId, userId: _supabaseService.currentUserId!, role: 'owner', status: 'accepted');
      await _supabaseService.updateNotification(notificationId, {'invite_status': 'accepted', 'is_read': true});
      final recipientName = _supabaseService.getUserDisplayName();
      final recipientEmail = _supabaseService.currentUser?.email ?? '';
      try { await _supabaseService.sendNotificationToUser(recipientUserId: senderId, title: 'Family invite accepted', body: '$recipientName ($recipientEmail) accepted your family invite', type: 1); } catch (e) { debugPrint('Could not notify sender of accept: $e'); }
      _notifications[idx].inviteStatus = 'accepted'; _notifications[idx].isRead = true;
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error accepting invite: $e'); return false; }
  }

  Future<bool> rejectInvite(String notificationId) async {
    if (!_isCloudMode) return false;
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1) return false;
    final notification = _notifications[idx];
    if (notification.type != 3 || notification.inviteStatus != 'pending') return false;
    final senderEmail = notification.relatedEmail;
    try {
      await _supabaseService.updateNotification(notificationId, {'invite_status': 'rejected', 'is_read': true});
      if (senderEmail != null) {
        final senderId = await _supabaseService.getUserIdByEmail(senderEmail);
        if (senderId != null) {
          final name = _supabaseService.getUserDisplayName();
          final em = _supabaseService.currentUser?.email ?? '';
          try { await _supabaseService.sendNotificationToUser(recipientUserId: senderId, title: 'Family invite declined', body: '$name ($em) declined your family invite', type: 1); } catch (e) { debugPrint('Could not notify sender of decline: $e'); }
        }
      }
      _notifications[idx].inviteStatus = 'rejected'; _notifications[idx].isRead = true;
      notifyListeners(); return true;
    } catch (e) { debugPrint('Error rejecting invite: $e'); return false; }
  }

  Future<void> markRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;
    _notifications[idx].isRead = true; notifyListeners();
    await _hiveService.updateNotification(_notifications[idx]);
    if (_isCloudMode) { try { await _supabaseService.updateNotification(id, {'is_read': true}); } catch (e) { debugPrint('Error marking read: $e'); } }
  }

  Future<void> markAllRead() async {
    for (final n in _notifications) {
      if (!n.isRead) {
        n.isRead = true;
        await _hiveService.updateNotification(n);
        if (_isCloudMode) { _supabaseService.updateNotification(n.id, {'is_read': true}).catchError((e) => debugPrint('Error marking read: $e')); }
      }
    }
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id); notifyListeners();
    await _hiveService.deleteNotification(id);
    if (_isCloudMode) { try { await _supabaseService.deleteNotification(id); } catch (e) { debugPrint('Error deleting notification: $e'); } }
  }

  Future<void> clearAll() async {
    _notifications.clear(); notifyListeners();
    if (_isCloudMode) { try { await _supabaseService.clearNotifications(); } catch (e) { debugPrint('Error clearing notifications: $e'); } }
    await _hiveService.clearNotifications();
  }
}
