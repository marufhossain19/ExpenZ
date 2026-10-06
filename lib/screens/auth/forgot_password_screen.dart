import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/otp_input_widget.dart';
import '../../widgets/auth/auth_step_indicator.dart';

/// Multi-step forgot password screen:
/// Step 0: Email → Step 1: OTP Verify → Step 2: New Password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _otpKey = GlobalKey<OtpInputWidgetState>();

  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final sub = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    // Listen for snackbars
    _showSnackbars(auth);

    return PopScope(
      canPop: auth.forgotPasswordStep == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          auth.goBackForgotPassword();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (auth.forgotPasswordStep > 0) {
                auth.goBackForgotPassword();
              } else {
                auth.resetForgotPassword();
                Navigator.pop(context);
              }
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // Header icon
                _buildHeaderIcon(auth.forgotPasswordStep),
                const SizedBox(height: 24),

                // Step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AuthStepIndicator(
                    currentStep: auth.forgotPasswordStep,
                    totalSteps: 3,
                    labels: const ['Email', 'Verify', 'Reset'],
                  ),
                ),
                const SizedBox(height: 28),

                // Title & subtitle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildTitle(context, auth.forgotPasswordStep, sub),
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
                if (auth.errorMessage != null) _buildErrorBox(auth.errorMessage!),

                const SizedBox(height: 24),

                // Back to login (step 0 only)
                if (auth.forgotPasswordStep == 0)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        auth.resetForgotPassword();
                        Navigator.pop(context);
                      },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 14, color: sub),
                          children: const [
                            TextSpan(text: 'Remember your password? '),
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
    switch (auth.forgotPasswordStep) {
      case 0:
        return _buildStepEmail(auth, sub);
      case 1:
        return _buildStepOtp(auth, isDark, sub);
      case 2:
        return _buildStepPassword(auth, sub);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Step 0: Enter email
  Widget _buildStepEmail(AuthProvider auth, Color sub) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step0'),
        children: [
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

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _sendResetOtp,
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
                  auth.resetEmail ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => auth.goBackForgotPassword(),
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
          onCompleted: (otp) => _verifyResetOtp(otp),
          onChanged: () => auth.clearError(),
        ),
        const SizedBox(height: 28),

        // Verify button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: auth.isLoading ? null : () => _verifyResetOtp(null),
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

  /// Step 2: Set new password
  Widget _buildStepPassword(AuthProvider auth, Color sub) {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('step2'),
        children: [
          // Success badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.income, size: 18),
                SizedBox(width: 8),
                Text('Identity verified!',
                    style: TextStyle(
                      color: AppColors.income,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // New Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure1,
            decoration: InputDecoration(
              labelText: 'New Password',
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
              if (!v.contains(RegExp(r'[A-Za-z]'))) {
                return 'Password must contain at least one letter';
              }
              if (!v.contains(RegExp(r'[0-9]'))) {
                return 'Password must contain at least one number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Confirm Password
          TextFormField(
            controller: _confirmController,
            obscureText: _obscure2,
            decoration: InputDecoration(
              labelText: 'Confirm New Password',
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
          const SizedBox(height: 12),

          // Password hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: sub),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Use 6+ characters with letters and numbers',
                    style: TextStyle(fontSize: 12, color: sub),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reset Password button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: auth.isLoading ? null : _resetPassword,
              style: _primaryButtonStyle(),
              child: auth.isLoading
                  ? _loadingIndicator()
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key_rounded, size: 20),
                        SizedBox(width: 10),
                        Text('Reset Password',
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

  // ── Header & Titles ───────────────────────────────────────

  Widget _buildHeaderIcon(int step) {
    final icons = [
      Icons.lock_reset_rounded,
      Icons.dialpad_rounded,
      Icons.vpn_key_rounded,
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
    final titles = ['Forgot Password?', 'Verify Email', 'New Password'];
    final subtitles = [
      "Enter your email and we'll send you an OTP to reset your password.",
      'Enter the 6-digit code sent to your email',
      'Create a new password for your account',
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

  Future<void> _sendResetOtp() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();
    await auth.sendResetOtp(_emailController.text.trim());
  }

  Future<void> _verifyResetOtp(String? otp) async {
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
    final ok = await auth.verifyResetOtp(code);
    if (!ok) {
      _otpKey.currentState?.shake();
    }
  }

  Future<void> _resendOtp() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.resendResetOtp();
    _otpKey.currentState?.clear();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.clearError();
    final ok = await auth.resetPassword(_passwordController.text);
    if (ok && mounted) {
      // Sign out after password reset so user logs in with new password
      await auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
