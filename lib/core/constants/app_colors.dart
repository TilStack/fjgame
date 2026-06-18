// Palette de couleurs duale : mode clair (inspiration FGM) et mode sombre (gaming).

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ─── Mode Clair ───────────────────────────────────────────────────────────
  static const Color lightPrimary       = Color(0xFF8B0000);
  static const Color lightPrimaryLight  = Color(0xFFB71C1C);
  static const Color lightAccent        = Color(0xFFC62828);
  static const Color lightBackground    = Color(0xFFFFFFFF);
  static const Color lightSurface       = Color(0xFFF5F5F5);
  static const Color lightCardSurface   = Color(0xFFFFFFFF);
  static const Color lightTextPrimary   = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF616161);
  static const Color lightBorder        = Color(0xFFE0E0E0);

  // ─── Mode Sombre ──────────────────────────────────────────────────────────
  static const Color darkPrimary        = Color(0xFFFF1744);
  static const Color darkPrimaryLight   = Color(0xFFFF5252);
  static const Color darkAccent         = Color(0xFFFF6D00);
  static const Color darkBackground     = Color(0xFF0D0D14);
  static const Color darkSurface        = Color(0xFF1A1A2E);
  static const Color darkCardSurface    = Color(0xFF2A2A3E);
  static const Color darkTextPrimary    = Color(0xFFE0E0E0);
  static const Color darkTextSecondary  = Color(0xFF9E9E9E);
  static const Color darkBorder         = Color(0xFF3A3A5E);

  // ─── Sémantiques (communes aux deux modes) ────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color error   = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA000);
}
