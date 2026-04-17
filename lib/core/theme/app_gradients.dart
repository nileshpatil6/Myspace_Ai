import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  AppGradients._();

  // ─── Orange brand gradients (same in both themes) ─────────────────────────
  static const LinearGradient orangeAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.orangeLight, AppColors.orangeDark],
  );

  static const LinearGradient orangeButton = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFF8C54), Color(0xFFFF5A1A)],
  );

  static const LinearGradient orangeHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.orangeLight, AppColors.orange],
  );

  static const RadialGradient voiceGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.85,
    colors: [Color(0x55FF6B2B), Color(0x00FF6B2B)],
  );

  static const RadialGradient orangeRadial = RadialGradient(
    center: Alignment.center,
    radius: 0.8,
    colors: [AppColors.orangeLight, AppColors.orangeDark],
  );

  // ─── Dark theme surface gradients ─────────────────────────────────────────
  static const LinearGradient darkCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF141414)],
  );

  static const LinearGradient darkBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F0F), Color(0xFF0A0A0A)],
  );

  static const LinearGradient darkAppBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF141414), Color(0x000A0A0A)],
  );

  // ─── Light theme surface gradients ────────────────────────────────────────
  static const LinearGradient lightCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F4EF)],
  );

  static const LinearGradient lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF6F1)],
  );

  static const LinearGradient lightAppBar = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
  );

  // ─── Chat bubble gradients ────────────────────────────────────────────────
  static const LinearGradient userBubble = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8C54), Color(0xFFFF5A1A)],
  );
}
