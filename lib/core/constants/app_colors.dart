import 'package:flutter/material.dart';

/// Centralized color palette for LivePulse.
/// All theme-aware color decisions live in context_extensions.dart.
abstract class AppColors {
  // ─── Brand ───────────────────────────────────────────────────
  static const primary      = Color(0xFF5B3FE0);
  static const primaryLight = Color(0xFF7A5FE8);
  static const primaryDark  = Color(0xFF4A2ED0);

  static const secondary      = Color(0xFF00B894);
  static const secondaryLight = Color(0xFF1DD1A1);

  static const accent       = Color(0xFFFFB84D);
  static const accentOrange = Color(0xFFFF9F43);
  static const accentYellow = Color(0xFFFFA502);

  // ─── Dark Mode Backgrounds ───────────────────────────────────
  static const bgDark     = Color(0xFF15192A);
  static const bgCard     = Color(0xFF1C2138);
  static const bgSurface  = Color(0xFF232840);
  static const bgElevated = Color(0xFF2B3152);

  // ─── Dark Mode Text ──────────────────────────────────────────
  static const textPrimary   = Color(0xFFF4F3FF);
  static const textSecondary = Color(0xFFB8B8CC);
  static const textMuted     = Color(0xFF7E7E97);

  // ─── Light Mode Backgrounds ──────────────────────────────────
  static const bgLight         = Color(0xFFF5F4FF);
  static const bgCardLight     = Color(0xFFFFFFFF);
  static const bgSurfaceLight  = Color(0xFFEEECFB);
  static const bgElevatedLight = Color(0xFFE5E3F5);
  static const bgSubtleLight   = Color(0xFFFAF9FF);

  // ─── Light Mode Text ─────────────────────────────────────────
  static const textPrimaryLight   = Color(0xFF1A1830);
  static const textSecondaryLight = Color(0xFF525270);
  static const textMutedLight     = Color(0xFF9090B0);
  static const textDisabledLight  = Color(0xFFCCCCDE);

  // ─── Borders & Dividers ──────────────────────────────────────
  static const borderLight       = Color(0xFFDDDBF0);
  static const borderSubtleLight = Color(0xFFEAE8FA);
  static const dividerLight      = Color(0xFFEAE8FA);

  // ─── Overlays & Shadows ──────────────────────────────────────
  static const overlayLight      = Color(0x0F1A1830);
  static const shadowLight       = Color(0x0D1A1830);
  static const shadowMediumLight = Color(0x141A1830);

  // ─── Status Colors ───────────────────────────────────────────
  static const success = Color(0xFF00C896);
  static const error   = Color(0xFFFF5E5E);
  static const warning = Color(0xFFFFB84D);
  static const info    = Color(0xFF6C5CE7);

  // ─── Gradients – Dark ────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8172EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSecondary = LinearGradient(
    colors: [Color(0xFF00C896), Color(0xFF1DD1A1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientAccent = LinearGradient(
    colors: [Color(0xFFFFB84D), Color(0xFFFF9F43)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBg = LinearGradient(
    colors: [Color(0xFF15192A), Color(0xFF1C2138), Color(0xFF15192A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ─── Gradients – Light ───────────────────────────────────────
  static const gradientPrimaryLight = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF8172EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientBgLight = LinearGradient(
    colors: [Color(0xFFF5F4FF), Color(0xFFEEECFB), Color(0xFFF5F4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  // ─── MCQ Option Colors ───────────────────────────────────────
  static const mcqColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00C896),
    Color(0xFFFF5E5E),
    Color(0xFFFFB84D),
    Color(0xFF8172EB),
    Color(0xFF1DD1A1),
  ];

  // ─── Word Cloud Colors ───────────────────────────────────────
  static const wordCloudColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00C896),
    Color(0xFFFF5E5E),
    Color(0xFFFFB84D),
    Color(0xFF8172EB),
    Color(0xFF1DD1A1),
    Color(0xFFFF9F43),
    Color(0xFFFFA502),
  ];
}
