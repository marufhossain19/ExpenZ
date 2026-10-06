import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/budget_provider.dart';
import '../../providers/notification_provider.dart';
import '../../services/hive_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/otp_input_widget.dart';
import '../../widgets/auth/auth_step_indicator.dart';

/// Multi-step registration screen:
/// Step 0: Name + Email → Step 1: OTP Verify → Step 2: Set Password → Done
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputWidgetState>();

  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    // Reset provider state when leaving
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      // Provider may no longer be accessible — that's fine
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Listen for error/success snackbars
    _showSnackbars(auth);

    return PopScope(
      canPop: auth.registrationStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          auth.goBackRegistration();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Header icon
                _buildHeaderIcon(auth.registrationStep),
                const SizedBox(height: 24),

                // Step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AuthStepIndicator(
                    currentStep: auth.registrationStep,
                    totalSteps: 3,
                    labels: const ['Details', 'Verify', 'Password'],
                  ),
                ),
                const SizedBox(height: 28),

                // Title & subtitle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTitle(context, auth.registrationStep, sub),
                ),
                const SizedBox(height: 28),

                // Step content
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.15, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildStepContent(auth, isDark, sub),
                ),

                const SizedBox(height: 20),

                // Error message
                if (auth.errorMessage != null)
                  _buildErrorBox(auth.errorMessage!),

                const SizedBox(height: 24),

                // Bottom links
                if (auth.registrationStep == 0) ...[
                  Center(
                    child: TextButton(
                      onPressed: () {
                        auth.resetRegister();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: sub),
                          children: const [
                            TextSpan(text: 'Already have an account? '),
                            TextSpan(
                              text: 'Sign In',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Step Content Builders ─────────────────────────────────

  Widget _buildStepContent(AuthProvider auth, bool isDark, Color sub) {
    switch (auth.registrationStep) {
      case 0:
        return _buildStepForm(auth, sub);
      case 1:
        return _buildStepOtp(auth, isDark, sub);
      case 2:
        return _buildStepPassword(auth, sub);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: Name + Email form
  Widget _buildStepForm(AuthProvider auth, Color sub) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step0'),
        children: [
          // Full Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outlined),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter your full name' : null,
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
                return 'Enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Send OTP button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendOtp,
              style: _primaryButtonStyle(),
              child: auth.isLoading
                  ? _loadingIndicator()
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.send_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Send OTP',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2: Set Password form
  Widget _buildStepPassword(AuthProvider auth, Color sub) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step2'),
        children: [
          // Email verified success banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.income, size: 20),
                SizedBox(width: 8),
                Text('Email verified successfully!',
                    style: TextStyle(color: AppColors.income, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure1,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure1
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure1 = !_obscure1),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure2,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                icon: Icon(_obscure2
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded),
                onPressed: () => setState(() => _obscure2 = !_obscure2),
              ),
            ),
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use 6+ characters with letters and numbers',
                  style: TextStyle(fontSize: 12, color: sub),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Create Account button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _createAccount,
              style: _primaryButtonStyle(),
              child: auth.isLoading
                  ? _loadingIndicator()
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Create Account',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: OTP verification
  Widget _buildStepOtp(AuthProvider auth, bool isDark, Color sub) {
    return Column(
      key: const ValueKey('step1'),
      children: [
        // Email display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.email_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  auth.pendingEmail ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => auth.goBackRegistration(),
                child: Text('Change',
                    style: TextStyle(
                      color: sub,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    )),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // OTP input
        OtpInputWidget(
          key: _otpKey,
          onCompleted: (otp) => _verifyOtp(otp),
          onChanged: () => auth.clearError(),
        ),
        const SizedBox(height: 28),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : () => _verifyOtp(null),
            style: _primaryButtonStyle(),
            child: auth.isLoading
                ? _loadingIndicator()
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_rounded, size: 20),
                      SizedBox(width: 10),
                      Text('Verify OTP',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),

        // Resend OTP
        Center(
          child: auth.canResendOtp
              ? TextButton.icon(
                  onPressed: auth.isLoading ? null : _resendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Resend OTP'),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 16, color: sub),
                    const SizedBox(width: 6),
                    Text(
                      'Resend in ${auth.otpCountdown}s',
                      style: TextStyle(
                        color: sub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  /// Step 1: OTP verification (removed Step 2 — password collected in Step 0)

  // ── Header & Titles ───────────────────────────────────────

  Widget _buildHeaderIcon(int step) {
    final icons = [
      Icons.person_add_rounded,
      Icons.dialpad_rounded,
      Icons.lock_rounded,
    ];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(step),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icons[step], size: 32, color: Colors.white),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, int step, Color sub) {
    final titles = ['Create Account', 'Verify Email', 'Set Password'];
    final subtitles = [
      'Start tracking your expenses today',
      'Enter the 6-digit code sent to your email',
      'Create a secure password for your account',
    ];

    return Column(
      key: ValueKey('title_$step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titles[step],
            style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: 8),
        Text(subtitles[step],
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: sub)),
      ],
    );
  }

  // ── Action Handlers ───────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();
    await auth.sendRegistrationOtp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
    );
  }

  Future<void> _verifyOtp(String? otp) async {
    final code = otp ?? _otpKey.currentState?.otp ?? '';
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter all 6 digits'),
          backgroundColor: AppColors.expense,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();
    final ok = await auth.verifyRegistrationOtp(code);
    if (!ok) {
      _otpKey.currentState?.shake();
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();
    final ok = await auth.setRegistrationPassword(_passwordController.text);
    
    if (ok && mounted) {
      // Open user-scoped Hive boxes FIRST
      final userId = auth.userId;
      if (userId != null) {
        final hiveService = Provider.of<HiveService>(context, listen: false);
        await hiveService.openUserBoxes(userId);
        debugPrint('[RegisterScreen] Opened user boxes for ${userId.substring(0, 8)}');
      }
      // Load user-specific data from Supabase
      final expenseP = Provider.of<ExpenseProvider>(context, listen: false);
      final budgetP = Provider.of<BudgetProvider>(context, listen: false);
      final notifP = Provider.of<NotificationProvider>(context, listen: false);
      await Future.wait([
        expenseP.loadUserData(),
        budgetP.loadUserData(),
        notifP.loadUserData(),
      ]);
      debugPrint('[RegisterScreen] User data loaded');
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    }
  }

  Future<void> _resendOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.resendRegistrationOtp();
    _otpKey.currentState?.clear();
  }

  // ── Snackbar Listener ─────────────────────────────────────

  void _showSnackbars(AuthProvider auth) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (auth.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(auth.successMessage!)),
              ],
            ),
            backgroundColor: AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        auth.clearSuccess();
      }
    });
  }

  // ── Shared UI Helpers ─────────────────────────────────────

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.expense.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.expense.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.expense, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.expense, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 4,
      shadowColor: AppColors.primary.withValues(alpha: 0.4),
    );
  }

  Widget _loadingIndicator() {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
    );
  }
}
