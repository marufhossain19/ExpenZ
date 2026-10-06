import 'package:flutter/material.dart';

/// Premium fintech-inspired color palette for the Expense Tracker.
class AppColors {
  // ── Brand Colors ────────────────────────────────────────
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF8B7EF0);
  static const Color primaryDark = Color(0xFF5A4BD1);
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryLight = Color(0xFF55EFC4);
  static const Color accent = Color(0xFFFD79A8);

  // ── Semantic Colors ─────────────────────────────────────
  static const Color income = Color(0xFF00B894);
  static const Color incomeLight = Color(0xFF55EFC4);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color expenseLight = Color(0xFFFFAAAA);
  static const Color warning = Color(0xFFFFA502);

  /// Strong red for exceeded budgets / critical alerts (replaces pink-magenta).
  static const Color budgetExceeded = Color(0xFFC62828);
  static const Color budgetDanger = Color(0xFFD32F2F);

  // ── Light Theme Surfaces ────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightDivider = Color(0xFFF3F4F6);

  // ── Dark Theme Surfaces ─────────────────────────────────
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1E1E2E);
  static const Color darkCard = Color(0xFF252540);
  static const Color darkTextPrimary = Color(0xFFF1F1F8);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkBorder = Color(0xFF2D2D44);
  static const Color darkDivider = Color(0xFF1F1F35);

  // ── Gradients ───────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient incomeGradient = LinearGradient(
    colors: [income, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [expense, Color(0xFFFF8E8E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF252540), Color(0xFF1E1E2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Category Colors ─────────────────────────────────────
  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B), // Food
    Color(0xFF6C5CE7), // Shopping
    Color(0xFF00CEC9), // Transport
    Color(0xFFFFA502), // Bills
    Color(0xFFE84393), // Entertainment
    Color(0xFF00B894), // Health
    Color(0xFF55EFC4), // Salary
    Color(0xFF74B9FF), // Education
    Color(0xFFFD79A8), // Extra 1
    Color(0xFFA29BFE), // Extra 2
    Color(0xFFDFE6E9), // Extra 3
    Color(0xFFFAB1A0), // Extra 4
  ];
}
