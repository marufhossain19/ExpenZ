import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

/// Manages authentication state with multi-step OTP flows.
/// Delegates all auth operations to [SupabaseService].
class AuthProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription<AuthState>? _authSubscription;

  // ── Core State ──────────────────────────────────────────
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userName;
  String? _userEmail;
  String? _errorMessage;
  String? _successMessage;

  // ── Registration Flow State ─────────────────────────────
  int _registrationStep = 0; // 0=form (name+email+password), 1=otp verify
  String? _pendingName;
  String? _pendingEmail;

  // ── Forgot Password Flow State ──────────────────────────
  int _forgotPasswordStep = 0; // 0=email, 1=otp, 2=password
  String? _resetEmail;

  // ── OTP Countdown ───────────────────────────────────────
  int _otpCountdown = 0;
  Timer? _countdownTimer;

  // ── Getters ─────────────────────────────────────────────
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int get registrationStep => _registrationStep;
  String? get pendingName => _pendingName;
  String? get pendingEmail => _pendingEmail;

  int get forgotPasswordStep => _forgotPasswordStep;
  String? get resetEmail => _resetEmail;

  int get otpCountdown => _otpCountdown;
  bool get canResendOtp => _otpCountdown <= 0;

  AuthProvider() {
    _listenToAuthChanges();
  }

  /// Listen to Supabase auth state changes for reactive updates.
  void _listenToAuthChanges() {
    _authSubscription = _supabaseService.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;
      debugPrint('[AuthProvider] onAuthStateChange: $event, '
          'user=${session?.user.id.substring(0, 8) ?? "null"}');

      if (event == AuthChangeEvent.signedIn && session != null) {
        _isAuthenticated = true;
        _userEmail = session.user.email;
        _userName = _supabaseService.getUserDisplayName();
        notifyListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _userName = null;
        _userEmail = null;
        notifyListeners();
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // Session refreshed — keep state as-is
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── OTP Countdown Timer ─────────────────────────────────

  void _startCountdown() {
    _otpCountdown = 60;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_otpCountdown <= 0) {
        timer.cancel();
      } else {
        _otpCountdown--;
        notifyListeners();
      }
    });
    notifyListeners();
  }

  // ── Session Check ────────────────────────────────────────

  /// The current user ID from Supabase, or null.
  String? get userId => _supabaseService.currentUserId;

  /// Check for an existing session on app start (auto-login).
  /// Uses refreshSession to validate the JWT is still valid.
  Future<bool> checkExistingSession() async {
    try {
      debugPrint('[AuthProvider] checkExistingSession: attempting restore...');
      final session = await _supabaseService.restoreSession();
      if (session != null) {
        _isAuthenticated = true;
        _userEmail = session.user.email;
        _userName = _supabaseService.getUserDisplayName();
        debugPrint('[AuthProvider] checkExistingSession: restored! '
            'user=${session.user.id.substring(0, 8)}, email=$_userEmail');
        notifyListeners();
        return true;
      }
      debugPrint('[AuthProvider] checkExistingSession: no valid session');
    } catch (e) {
      debugPrint('[AuthProvider] checkExistingSession error: $e');
    }
    return false;
  }

  // ── Sign In (Email + Password) ──────────────────────────

  /// Sign in with email and password via Supabase.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.session != null) {
        _isAuthenticated = true;
        _userEmail = email;
        _userName = _supabaseService.getUserDisplayName();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Sign in failed. Please check your credentials.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Sign Out ─────────────────────────────────────────────

  /// Sign out and clear all user state.
  Future<void> signOut() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    _errorMessage = null;
    _successMessage = null;
    _resetRegistrationState();
    _resetForgotPasswordState();
    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════
  // REGISTER FLOW (3 Steps)
  // ══════════════════════════════════════════════════════════

  /// Step 0: Signs up the user (sends "Confirm signup" email with OtpType.signup).
  Future<bool> sendRegistrationOtp({
    required String name,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use signUp so Supabase sends the "Confirm signup" email template
      // which correctly supports {{ .Token }} for OTP verification.
      await _supabaseService.signUp(
        email: email,
        password: DateTime.now().millisecondsSinceEpoch.toString(), // temp password, overwritten in step 2
        fullName: name,
      );
      _pendingName = name;
      _pendingEmail = email;
      _registrationStep = 1; // Move to OTP verify step
      _isLoading = false;
      _startCountdown();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send OTP. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 1: Verify OTP (signup type). Moves to Step 2 on success.
  Future<bool> verifyRegistrationOtp(String token) async {
    if (_pendingEmail == null) {
      _errorMessage = 'Email not found. Please start over.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Must use OtpType.signup to match the "Confirm signup" email template
      final response = await _supabaseService.verifySignupOtp(
        email: _pendingEmail!,
        token: token,
      );

      if (response.session != null) {
        // Successfully verified, move to Step 2 (Password)
        _registrationStep = 2;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Verification failed. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Connection error. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Set Password and finalize registration.
  Future<bool> setRegistrationPassword(String password) async {
    if (_pendingEmail == null || _pendingName == null) {
      _errorMessage = 'Session expired. Please start over.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Set the password
      await _supabaseService.setPassword(password);
      
      // Upsert profile data
      if (userId != null) {
        await _supabaseService.upsertProfile(
          userId: userId!,
          name: _pendingName!,
          email: _pendingEmail!,
        );
        // Also update auth metadata
        await _supabaseService.updateUserMetadata(fullName: _pendingName!);
      }

      _isAuthenticated = true;
      _userName = _pendingName;
      _userEmail = _pendingEmail;
      _isLoading = false;
      _successMessage = 'Account created successfully!';
      
      // Cleanup pending state but keep auth state
      _pendingName = null;
      _pendingEmail = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create account. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend OTP for registration flow (re-triggers "Confirm signup" email)
  Future<bool> resendRegistrationOtp() async {
    if (_pendingEmail == null || _pendingName == null || !canResendOtp) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Re-call signUp — Supabase resends the "Confirm signup" OTP email
      await _supabaseService.signUp(
        email: _pendingEmail!,
        password: DateTime.now().millisecondsSinceEpoch.toString(),
        fullName: _pendingName,
      );
      _isLoading = false;
      _successMessage = 'OTP resent to $_pendingEmail';
      _startCountdown();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to resend OTP. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Go back to previous registration step.
  void goBackRegistration() {
    if (_registrationStep > 0) {
      _registrationStep--;
      _errorMessage = null;
      _countdownTimer?.cancel();
      notifyListeners();
    }
  }

  void _resetRegistrationState() {
    _registrationStep = 0;
    _pendingName = null;
    _pendingEmail = null;
    _countdownTimer?.cancel();
    _otpCountdown = 0;
  }

  // ══════════════════════════════════════════════════════════
  // FORGOT PASSWORD FLOW (3 Steps)
  // ══════════════════════════════════════════════════════════

  /// Step 1: Send password reset email (uses "Reset password" template with OTP).
  Future<bool> sendResetOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.sendPasswordResetEmail(email);
      _resetEmail = email;
      _forgotPasswordStep = 1;
      _isLoading = false;
      _startCountdown();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to send reset email. Please check your internet.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 2: Verify the OTP code during password reset.
  Future<bool> verifyResetOtp(String token) async {
    if (_resetEmail == null) {
      _errorMessage = 'Email not found. Please start over.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _supabaseService.verifyResetOtp(
        email: _resetEmail!,
        token: token,
      );

      if (response.session != null) {
        _forgotPasswordStep = 2;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid OTP. Please try again.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Verification failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Step 3: Set the new password after OTP verified.
  Future<bool> resetPassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.setPassword(newPassword);
      _isLoading = false;
      _successMessage = 'Password reset successful!';
      _resetForgotPasswordState();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to reset password. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend password reset email.
  Future<bool> resendResetOtp() async {
    if (_resetEmail == null || !canResendOtp) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _supabaseService.sendPasswordResetEmail(_resetEmail!);
      _isLoading = false;
      _successMessage = 'Reset code resent to $_resetEmail';
      _startCountdown();
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = _mapAuthError(e.message);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to resend code.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Go back to previous forgot password step.
  void goBackForgotPassword() {
    if (_forgotPasswordStep > 0) {
      _forgotPasswordStep--;
      _errorMessage = null;
      _countdownTimer?.cancel();
      notifyListeners();
    }
  }

  void _resetForgotPasswordState() {
    _forgotPasswordStep = 0;
    _resetEmail = null;
    _countdownTimer?.cancel();
    _otpCountdown = 0;
  }

  // ── Offline Mode ─────────────────────────────────────────

  /// For offline / skip-auth mode (keeps backward compatibility).
  void skipAuth() {
    _isAuthenticated = true;
    _userName = 'User';
    notifyListeners();
  }

  // ── Utility ──────────────────────────────────────────────

  /// Clear error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear success message.
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// Reset registration state (e.g., when leaving screen).
  void resetRegister() {
    _resetRegistrationState();
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Reset forgot password state (e.g., when leaving screen).
  void resetForgotPassword() {
    _resetForgotPasswordState();
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Map Supabase error messages to user-friendly text.
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email first.';
    }
    if (lower.contains('user already registered')) {
      return 'An account with this email already exists.';
    }
    if (lower.contains('otp') && lower.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    }
    if (lower.contains('invalid otp') || lower.contains('token')) {
      return 'Invalid OTP code. Please check and try again.';
    }
    if (lower.contains('email rate limit')) {
      return 'Too many requests. Please wait a moment.';
    }
    if (lower.contains('signup is disabled')) {
      return 'Registration is currently disabled.';
    }
    if (lower.contains('password') && lower.contains('weak')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    // Fallback
    return message;
  }
}
