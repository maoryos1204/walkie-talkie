import 'package:flutter/material.dart';

abstract class AppColors {
  // Primary palette - deep blue family-friendly
  static const primary = Color(0xFF1A237E);
  static const primaryLight = Color(0xFF3949AB);
  static const primaryDark = Color(0xFF0D1857);
  static const primaryContainer = Color(0xFFE8EAF6);
  static const onPrimary = Colors.white;

  // Accent - warm amber
  static const accent = Color(0xFFFFB300);
  static const accentLight = Color(0xFFFFD54F);
  static const accentDark = Color(0xFFFF8F00);
  static const onAccent = Color(0xFF1A1A1A);

  // Semantic
  static const success = Color(0xFF4CAF50);
  static const error = Color(0xFFE53935);
  static const warning = Color(0xFFFB8C00);
  static const info = Color(0xFF1E88E5);

  // Presence status colors
  static const statusOnline = Color(0xFF4CAF50);
  static const statusOffline = Color(0xFF9E9E9E);
  static const statusBusy = Color(0xFFFB8C00);
  static const statusSpeaking = Color(0xFF7C4DFF);
  static const statusInQueue = Color(0xFFFFB300);

  // PTT Button
  static const pttIdle = Color(0xFF1A237E);
  static const pttActive = Color(0xFF7C4DFF);
  static const pttBusy = Color(0xFFE53935);
  static const pttPulse = Color(0xFF7C4DFF);
  static const pttGlow = Color(0x557C4DFF);

  // Background
  static const backgroundLight = Color(0xFFF5F7FF);
  static const backgroundDark = Color(0xFF0A0E1F);
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF131829);
  static const cardLight = Colors.white;
  static const cardDark = Color(0xFF1C2340);

  // Text
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF5C6BC0);
  static const textPrimaryDark = Color(0xFFF0F4FF);
  static const textSecondaryDark = Color(0xFF8C9EFF);
  static const textHint = Color(0xFF9E9E9E);

  // Voice wave animation
  static const waveActive = Color(0xFF7C4DFF);
  static const waveInactive = Color(0x337C4DFF);

  // Divider
  static const divider = Color(0xFFE0E0E0);
  static const dividerDark = Color(0xFF2A3050);

  // Channel busy indicator
  static const channelBusy = Color(0xFFE53935);
  static const channelFree = Color(0xFF4CAF50);

  // Badge
  static const badge = Color(0xFFE53935);
  static const badgeText = Colors.white;

  // Gradient - hero background
  static const gradientStart = Color(0xFF1A237E);
  static const gradientEnd = Color(0xFF3949AB);
  static const gradientAccent = Color(0xFF7C4DFF);
}
