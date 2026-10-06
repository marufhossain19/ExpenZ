import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../core/constants.dart';

/// Editable limit row tile with toggle, period badge, inline editing, and delete.
class LimitTile extends StatefulWidget {
  final String title;
  final int type;
  final double amount;
  final bool isEnabled;
  final bool isFamily;
  final Color? color;
  final IconData? icon;
  final ValueChanged<double>? onAmountChanged;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  const LimitTile({
    super.key,
    required this.title,
    required this.type,
    required this.amount,
    required this.isEnabled,
    this.isFamily = false,
    this.color,
    this.icon,
    this.onAmountChanged,
    this.onToggle,
    this.onDelete,
  });

  @override
  State<LimitTile> createState() => _LimitTileState();
}

class _LimitTileState extends State<LimitTile> {
  bool _editing = false;
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.amount.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant LimitTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount && !_editing) {
      _ctrl.text = widget.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _periodLabel {
    switch (widget.type) {
      case LimitType.daily: return 'Daily';
      case LimitType.weekly: return 'Weekly';
      case LimitType.monthly: return 'Monthly';
      default: return '';
    }
  }

  Color get _periodColor {
    switch (widget.type) {
      case LimitType.daily: return AppColors.secondary;
      case LimitType.weekly: return AppColors.primary;
      default: return const Color(0xFFE84393);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Limit'),
        content: Text('Remove the ${_periodLabel.toLowerCase()} limit for "${widget.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.expense,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.color ?? _periodColor;

    return AnimatedOpacity(
      opacity: widget.isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon ?? Icons.account_balance_wallet_rounded, color: c, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _periodColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text(_periodLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _periodColor)),
                  ),
                  if (widget.isFamily) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Family', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.secondary)),
                    ),
                  ],
                ]),
              ],
            )),
            GestureDetector(
              onTap: () => setState(() => _editing = true),
              child: _editing
                ? SizedBox(width: 90, child: TextField(
                    controller: _ctrl, autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    decoration: const InputDecoration(prefix: Text('৳'), border: InputBorder.none, isDense: true),
                    onSubmitted: (v) {
                      final n = double.tryParse(v);
                      if (n != null && n > 0) widget.onAmountChanged?.call(n);
                      setState(() => _editing = false);
                    },
                  ))
                : Text('৳${widget.amount.toStringAsFixed(0)}', style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            ),
            const SizedBox(width: 4),
            // Delete button
            if (widget.onDelete != null)
              GestureDetector(
                onTap: _confirmDelete,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.expense.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: AppColors.expense, size: 16),
                ),
              ),
            const SizedBox(width: 4),
            SizedBox(height: 28, child: Switch(
              value: widget.isEnabled, onChanged: widget.onToggle,
              activeTrackColor: AppColors.primary,
            )),
          ],
        ),
      ),
    );
  }
}
