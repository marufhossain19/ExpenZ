import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../services/budget_service.dart';
import '../../utils/formatters.dart';

/// Glassmorphism-style overspending popup dialog.
/// Custom modal with blurred background, not default Flutter dialog.
class OverspendingPopup extends StatefulWidget {
  final String category;
  final double spent;
  final double limit;
  final bool isFamily;
  final VoidCallback onClose;
  final VoidCallback? onAdjustBudget;
  final VoidCallback? onIgnore;

  const OverspendingPopup({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    this.isFamily = false,
    required this.onClose,
    this.onAdjustBudget,
    this.onIgnore,
  });

  /// Show this popup as an overlay
  static Future<void> show(
    BuildContext context, {
    required String category,
    required double spent,
    required double limit,
    bool isFamily = false,
    VoidCallback? onAdjustBudget,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim1, anim2) {
        return OverspendingPopup(
          category: category,
          spent: spent,
          limit: limit,
          isFamily: isFamily,
          onClose: () => Navigator.of(ctx).pop(),
          onAdjustBudget: onAdjustBudget != null
              ? () { Navigator.of(ctx).pop(); onAdjustBudget(); }
              : null,
          onIgnore: () => Navigator.of(ctx).pop(),
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<OverspendingPopup> createState() => _OverspendingPopupState();
}

class _OverspendingPopupState extends State<OverspendingPopup> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final over = widget.spent - widget.limit;
    final aiWarning = BudgetService.getAIWarning(
      widget.category, widget.spent, widget.limit,
    );

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFE84393).withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE84393).withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button (X) at top-right
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: widget.onClose,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.close, size: 18,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary),
                        ),
                      ),
                    ),

                    // Warning icon with glow
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE84393).withValues(alpha: 0.12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE84393).withValues(alpha: 0.3),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        size: 40,
                        color: Color(0xFFE84393),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Budget Exceeded! 🚨',
                      style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category & amount
                    Text(
                      '${widget.isFamily ? "Family" : "Your"} ${widget.category} budget',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Over amount
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.expense.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Over by ${Formatters.currency(over)}',
                        style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700,
                          color: AppColors.expense,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI roast message
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkBackground
                            : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Text('🤖', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(aiWarning,
                              style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                height: 1.4,
                              )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onIgnore ?? widget.onClose,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Ignore'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onAdjustBudget ?? widget.onClose,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            child: const Text('Adjust Budget',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
