import 'package:flutter/material.dart';

/// TradingPro: I&T Brand Colors
class AppColors {
  AppColors._();

  // ─── Brand ───────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6C3FE0);
  static const Color primaryLight = Color(0xFF8F6BE8);
  static const Color primaryDark = Color(0xFF4E2DAB);
  static const Color primaryContainer = Color(0xFFEDE7FB);

  // ─── Background ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ─── Financial ───────────────────────────────────────────────────────────
  static const Color positive = Color(0xFF16A34A);
  static const Color positiveLight = Color(0xFFDCFCE7);
  static const Color negative = Color(0xFFDC2626);
  static const Color negativeLight = Color(0xFFFEE2E2);
  static const Color pending = Color(0xFFD97706);
  static const Color pendingLight = Color(0xFFFEF3C7);

  // ─── Neutral ─────────────────────────────────────────────────────────────
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ─── Helpers ─────────────────────────────────────────────────────────────
  static Color financialColor(bool isPositive) =>
      isPositive ? positive : negative;

  static Color financialBgColor(bool isPositive) =>
      isPositive ? positiveLight : negativeLight;
}
