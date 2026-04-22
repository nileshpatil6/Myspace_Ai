import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Orange brand system (constant across both themes) ────────────────────
  static const Color orange = Color(0xFFFF6B2B);
  static const Color orangeLight = Color(0xFFFF8C54);
  static const Color orangeDark = Color(0xFFCC4E18);
  static const Color orangeGlow = Color(0x33FF6B2B);
  static const Color orangeSubtle = Color(0x1AFF6B2B);

  // ─── Dark theme ───────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF141414);
  static const Color darkSurfaceElevated = Color(0xFF1C1C1C);
  static const Color darkSurfaceBorder = Color(0xFF2A2A2A);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9A9A9A);
  static const Color darkTextDisabled = Color(0xFF4A4A4A);
  static const Color darkOverlay = Color(0xF00A0A0A);

  // ─── Light theme ──────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF5F0EB);
  static const Color lightSurfaceBorder = Color(0xFFE8E0D8);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextDisabled = Color(0xFFB0B0B0);
  static const Color lightOverlay = Color(0xF0FAFAFA);

  // ─── Status (same in both themes) ─────────────────────────────────────────
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ─── Category colors ──────────────────────────────────────────────────────
  static const Map<String, Color> categoryColors = {
    'Personal': Color(0xFF9B59B6),
    'Work': Color(0xFF3498DB),
    'Ideas': Color(0xFF1ABC9C),
    'Events': Color(0xFFFF6B2B),
    'Shopping': Color(0xFF2ECC71),
    'Health': Color(0xFFE74C3C),
    'Finance': Color(0xFFF39C12),
    'Passwords': Color(0xFF95A5A6),
    'Articles': Color(0xFF34495E),
    'Contacts': Color(0xFF16A085),
    'Code': Color(0xFF8E44AD),
    'Other': Color(0xFF7F8C8D),
  };
}
