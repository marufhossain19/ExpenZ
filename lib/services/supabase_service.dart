import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

/// Service layer for all Supabase authentication, profile, and data operations.
/// Uses signUp + verifyOTP for registration, resetPasswordForEmail + verifyOTP for resets.
/// Provides full CRUD for expenses, limits, alerts, notifications, and categories.
class SupabaseService {
  bool get isEnabled => AppConfig.isSupabaseEnabled;

  /// Returns the Supabase client singleton.
  SupabaseClient get _client => Supabase.instance.client;

  /// Initialize the Supabase SDK. Call once in main() before runApp().
  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  // ── Auth State ───────────────────────────────────────────

  /// Stream of auth state changes (sign in, sign out, token refresh, etc.)
  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Current authenticated user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Current session, or null.
  Session? get currentSession => _client.auth.currentSession;

  /// Whether a valid session exists.
  bool get hasSession => currentSession != null;

  /// Current user ID, or null.
  String? get currentUserId => currentUser?.id;

  /// Refreshes the JWT when a session exists so the next PostgREST calls succeed
  /// (helps right after sign-in before the client attaches the access token).
  Future<void> ensureSessionReady() async {
    if (!isEnabled) return;
    if (_client.auth.currentSession == null) return;
    try {
      await _client.auth.refreshSession();
    } catch (_) {}
  }

  /// Attempt to restore a persisted session on cold start.
  /// Returns the restored session, or null if none exists / refresh fails.
  Future<Session?> restoreSession() async {
    if (!isEnabled) return null;
    try {
      final session = _client.auth.currentSession;
      if (session == null) {
        debugPrint('[SupabaseService] restoreSession: no persisted session');
        return null;
      }
      // Refresh to ensure the JWT is still valid
      final res = await _client.auth.refreshSession();
      debugPrint('[SupabaseService] restoreSession: refreshed OK — '
          'user=${res.session?.user.id.substring(0, 8)}, '
          'expires=${res.session?.expiresAt}');
      return res.session;
    } catch (e) {
      debugPrint('[SupabaseService] restoreSession failed: $e');
      return null;
    }
  }

  // ── Sign In (Email + Password) ──────────────────────────

  /// Sign in with email + password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  // ── Sign Out ─────────────────────────────────────────────

  /// Sign out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Registration: signUp → sends "Confirm signup" email ─

  /// Sign up with email + password.
  /// Supabase sends the "Confirm signup" email template which supports {{ .Token }}.
  /// User must verify the OTP code to confirm their account.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    return response;
  }

  /// Sign in with OTP (Magic Link flow).
  /// This triggers the Magic Link email template.
  Future<void> signInWithOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  // ── Registration: Verify signup OTP ─────────────────────

  /// Verify the OTP from the "Confirm signup" email.
  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
    return response;
  }

  /// Verify OTP for Magic Link flow.
  Future<AuthResponse> verifyMagicLinkOtp({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.magiclink,
    );
    return response;
  }

  // ── Password Reset: sends "Reset password" email ────────

  /// Send password reset email.
  /// Supabase sends the "Reset password" email template which supports {{ .Token }}.
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ── Password Reset: Verify reset OTP ────────────────────

  /// Verify the OTP from the "Reset password" email.
  Future<AuthResponse> verifyResetOtp({
    required String email,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
    return response;
  }

  // ── Password Management ─────────────────────────────────

  /// Update password for the currently authenticated user.
  Future<UserResponse> setPassword(String password) async {
    final response = await _client.auth.updateUser(
      UserAttributes(password: password),
    );
    return response;
  }

  // ── Profile Management ──────────────────────────────────

  /// Upsert user profile data in the profiles table.
  Future<void> upsertProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'full_name': name,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Update user metadata (full_name) in Supabase Auth.
  Future<UserResponse> updateUserMetadata({required String fullName}) async {
    final response = await _client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );
    return response;
  }

  /// Resolve a registered user's id by email (family invites). Uses SECURITY DEFINER RPC.
  Future<String?> getUserIdByEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return null;
    try {
      final result = await _client.rpc(
        'find_user_id_by_email',
        params: {'p_email': trimmed},
      );
      if (result == null) return null;
      if (result is String && result.isNotEmpty) return result;
      return result.toString();
    } catch (e) {
      // Older DBs without RPC: fall back (requires permissive profile SELECT policy).
      try {
        final response = await _client
            .from('profiles')
            .select('id')
            .eq('email', trimmed)
            .maybeSingle();
        if (response == null) return null;
        return response['id'] as String?;
      } catch (_) {
        return null;
      }
    }
  }

  // ── Expenses CRUD ───────────────────────────────────────

  /// Fetch all expenses for the current user (sorted by date desc).
  Future<List<Map<String, dynamic>>> fetchExpenses() async {
    final uid = currentUserId;
    if (uid == null) {
      debugPrint('[SupabaseService] fetchExpenses: no user — skipped');
      return [];
    }
    debugPrint('[SupabaseService] fetchExpenses: fetching for user=${uid.substring(0, 8)}');
    final response = await _client
        .from('expenses')
        .select()
        .eq('user_id', uid)
        .order('date', ascending: false);
    final result = List<Map<String, dynamic>>.from(response);
    debugPrint('[SupabaseService] fetchExpenses: got ${result.length} rows');
    return result;
  }

  /// Add an expense to the cloud.
  Future<void> addExpense(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    debugPrint('[SupabaseService] addExpense: id=${data['id']}, title=${data['title']}, user=${uid.substring(0, 8)}');
    await _client.from('expenses').insert({...data, 'user_id': uid});
  }

  /// Delete an expense from the cloud.
  Future<void> deleteExpense(String id) async {
    debugPrint('[SupabaseService] deleteExpense: id=$id');
    await _client.from('expenses').delete().eq('id', id);
  }

  /// Update an expense in the cloud.
  Future<void> updateExpense(String id, Map<String, dynamic> data) async {
    debugPrint('[SupabaseService] updateExpense: id=$id');
    await _client.from('expenses').update(data).eq('id', id);
  }

  // ── Categories CRUD ─────────────────────────────────────

  /// Fetch all categories for the current user (including defaults with user_id=null).
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final uid = currentUserId;
    if (uid == null) return [];
    // Fetch default categories (user_id is null) + user's custom categories
    final response = await _client
        .from('categories')
        .select()
        .or('user_id.is.null,user_id.eq.$uid');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a user category to the cloud. Returns new row id, or null on failure.
  Future<String?> addCategory(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return null;
    final row = await _client
        .from('categories')
        .insert({...data, 'user_id': uid})
        .select('id')
        .single();
    return row['id'] as String?;
  }

  /// Delete a user category from the cloud.
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }

  /// Emails / names of other users in the same accepted family group(s) as you.
  /// Requires RLS that allows reading peer profiles (see `supabase_family_peer_policy.sql`).
  Future<List<Map<String, String>>> fetchFamilyPeerProfiles() async {
    final uid = currentUserId;
    if (uid == null) return [];

    final myMemberships = await _client
        .from('family_members')
        .select('family_id')
        .eq('user_id', uid)
        .eq('status', 'accepted');
    if (myMemberships.isEmpty) return [];

    final familyIds = myMemberships
        .map((m) => m['family_id'] as String)
        .toSet()
        .toList();

    final members = await _client
        .from('family_members')
        .select('user_id')
        .inFilter('family_id', familyIds)
        .eq('status', 'accepted');

    final otherIds = <String>{};
    for (final m in members) {
      final id = m['user_id'] as String?;
      if (id != null && id != uid) otherIds.add(id);
    }
    if (otherIds.isEmpty) return [];

    final profiles = await _client
        .from('profiles')
        .select('email, full_name')
        .inFilter('id', otherIds.toList());

    return profiles
        .map<Map<String, String>>((p) => {
              'email': (p['email'] as String?) ?? '',
              'name': (p['full_name'] as String?) ?? '',
            })
        .where((m) => m['email']!.isNotEmpty)
        .toList();
  }

  // ── Spending Limits CRUD ────────────────────────────────

  /// Fetch all spending limits for the current user.
  Future<List<Map<String, dynamic>>> fetchLimits() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final response = await _client
        .from('spending_limits')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a spending limit to the cloud.
  Future<void> addLimit(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('spending_limits').insert({...data, 'user_id': uid});
  }

  /// Update a spending limit in the cloud.
  Future<void> updateLimit(String id, Map<String, dynamic> data) async {
    await _client.from('spending_limits').update(data).eq('id', id);
  }

  /// Delete a spending limit from the cloud.
  Future<void> deleteLimit(String id) async {
    await _client.from('spending_limits').delete().eq('id', id);
  }

  // ── Budget Alerts CRUD ──────────────────────────────────

  /// Fetch all budget alerts for the current user.
  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final response = await _client
        .from('budget_alerts')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a budget alert to the cloud.
  Future<void> addAlert(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('budget_alerts').insert({...data, 'user_id': uid});
  }

  /// Update a budget alert in the cloud.
  Future<void> updateAlert(String id, Map<String, dynamic> data) async {
    await _client.from('budget_alerts').update(data).eq('id', id);
  }

  /// Delete one budget alert (must belong to current user for RLS).
  Future<void> deleteAlert(String id) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('budget_alerts').delete().eq('id', id).eq('user_id', uid);
  }

  /// Clear all alerts for the current user.
  Future<void> clearAlerts() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('budget_alerts').delete().eq('user_id', uid);
  }

  // ── Notifications CRUD ──────────────────────────────────

  /// Fetch all notifications for the current user.
  Future<List<Map<String, dynamic>>> fetchNotifications() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final response = await _client
        .from('notifications')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Add a notification for the current user.
  Future<void> addNotification(Map<String, dynamic> data) async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('notifications').insert({...data, 'user_id': uid});
  }

  /// Send a notification to another user (for family invites).
  /// Uses a Supabase RPC function with SECURITY DEFINER.
  Future<void> sendNotificationToUser({
    required String recipientUserId,
    required String title,
    required String body,
    required int type,
    String? relatedEmail,
    String? inviteStatus,
  }) async {
    await _client.rpc('send_notification_to_user', params: {
      'p_recipient_id': recipientUserId,
      'p_title': title,
      'p_body': body,
      'p_type': type,
      'p_related_email': relatedEmail,
      'p_invite_status': inviteStatus,
    });
  }

  /// Update a notification.
  Future<void> updateNotification(String id, Map<String, dynamic> data) async {
    await _client.from('notifications').update(data).eq('id', id);
  }

  /// Delete a notification.
  Future<void> deleteNotification(String id) async {
    await _client.from('notifications').delete().eq('id', id);
  }

  /// Clear all notifications for the current user.
  Future<void> clearNotifications() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('notifications').delete().eq('user_id', uid);
  }

  // ── Family CRUD ─────────────────────────────────────────

  /// Create a new family group (current user is owner).
  Future<String?> createFamily(String name) async {
    final uid = currentUserId;
    if (uid == null) return null;
    final response = await _client.from('families').insert({
      'name': name,
      'owner_id': uid,
    }).select('id').single();
    return response['id'] as String;
  }

  /// Add a member to a family group.
  Future<void> addFamilyMember({
    required String familyId,
    required String userId,
    required String role,
    required String status,
  }) async {
    await _client.from('family_members').insert({
      'family_id': familyId,
      'user_id': userId,
      'role': role,
      'status': status,
    });
  }

  /// Update family member status (accept/reject).
  Future<void> updateFamilyMemberStatus({
    required String memberId,
    required String status,
  }) async {
    final data = <String, dynamic>{'status': status};
    if (status == 'accepted') {
      data['joined_at'] = DateTime.now().toIso8601String();
    }
    await _client.from('family_members').update(data).eq('id', memberId);
  }

  /// Get family memberships for current user.
  Future<List<Map<String, dynamic>>> fetchFamilyMemberships() async {
    final uid = currentUserId;
    if (uid == null) return [];
    final response = await _client
        .from('family_members')
        .select('*, families(*)')
        .eq('user_id', uid);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Unlink family (delete all memberships for current user).
  Future<void> unlinkFamily() async {
    final uid = currentUserId;
    if (uid == null) return;
    await _client.from('family_members').delete().eq('user_id', uid);
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Extract user's display name from metadata, or fallback to email prefix.
  String getUserDisplayName() {
    final user = currentUser;
    if (user == null) return 'User';
    final meta = user.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'] as String;
    }
    return user.email?.split('@').first ?? 'User';
  }
}
