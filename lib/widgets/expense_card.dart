import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/expense.dart';
import '../services/roast_service.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'roast_bubble.dart';

/// Reusable expense card with swipe-to-delete and tap-to-roast.
class ExpenseCard extends StatefulWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final int index;

  const ExpenseCard({
    super.key,
    required this.expense,
    this.onDelete,
    this.index = 0,
  });

  @override
  State<ExpenseCard> createState() => _ExpenseCardState();
}

class _ExpenseCardState extends State<ExpenseCard> {
  bool _showRoast = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final e = widget.expense;
    final color = Color(e.categoryColor);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          Slidable(
            key: ValueKey(e.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => widget.onDelete?.call(),
                  backgroundColor: AppColors.expense,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () => setState(() => _showRoast = !_showRoast),
              child: _buildCardContent(isDark, e, color),
            ),
          ),
          if (_showRoast)
            RoastBubble(
              message: RoastService.getRoast(e.category, e.amount, isIncome: e.isIncome),
              onDismiss: () => setState(() => _showRoast = false),
            ),
        ],
      ),
    );
  }

  Widget _buildCardContent(bool isDark, Expense e, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Icon ──────────────────────────────────────────
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              IconData(e.categoryIcon, fontFamily: 'MaterialIcons'),
              color: color, size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // ── Title + Category • Date ────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  // Category label — fixed width portion
                  Flexible(
                    flex: 0,
                    child: Text(e.category, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, color: color),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  Container(width: 3, height: 3, margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      shape: BoxShape.circle,
                    )),
                  // Date — takes all remaining space
                  Expanded(
                    child: Text(
                      Formatters.relativeDateWithTime(e.date),
                      style: TextStyle(fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // ── Amount — capped width so it never squeezes the date ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              '${e.isIncome ? '+' : '-'}${Formatters.currency(e.amount)}',
              style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700,
                color: e.isIncome ? AppColors.income : AppColors.expense,
              ),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
