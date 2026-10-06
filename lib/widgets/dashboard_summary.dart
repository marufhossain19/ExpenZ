import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

/// Dashboard summary widget showing Income, Expense, and Balance cards.
class DashboardSummary extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const DashboardSummary({
    super.key,
    required this.income,
    required this.expense,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Balance section
          Text('Total Balance',
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            )),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                Formatters.currency(value),
                style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800,
                  color: Colors.white, letterSpacing: -0.5,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // Income and Expense row
          Row(
            children: [
              Expanded(child: _buildStatCard(
                icon: Icons.arrow_downward_rounded,
                label: 'Income',
                amount: income,
                color: AppColors.incomeLight,
              )),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard(
                icon: Icons.arrow_upward_rounded,
                label: 'Expense',
                amount: expense,
                color: AppColors.expenseLight,
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                )),
                const SizedBox(height: 2),
                Text(Formatters.currencyShort(amount),
                  style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
