import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============ COLORES PRINCIPALES ============

  // Primarios - Gradiente de Ascenso
  static const Color primaryDark = Color(0xFF1A237E); // Azul profundo
  static const Color primary = Color(0xFF3F51B5); // Azul medio
  static const Color primaryLight = Color(0xFF7986CB); // Azul claro

  // Secundarios - Púrpura evolución
  static const Color secondary = Color(0xFF6A1B9A); // Púrpura oscuro
  static const Color secondaryLight = Color(0xFF9C27B0); // Púrpura medio

  // Acento - Progreso
  static const Color accent = Color(0xFF00E5FF); // Cyan eléctrico
  static const Color accentGreen = Color(0xFF00E676); // Verde éxito

  // ============ BACKGROUNDS ============

  // Dark Mode (Principal)
  static const Color backgroundDark = Color(0xFF0A0E27); // Casi negro azulado
  static const Color surfaceDark = Color(0xFF151B3D); // Surface cards
  static const Color surfaceVariantDark = Color(0xFF1E2749); // Elevated cards

  // Light Mode (Alternativo)
  static const Color backgroundLight = Color(0xFFF5F7FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE8EDF2);

  // ============ TEXTOS ============

  // Dark Mode
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B8D4);
  static const Color textTertiaryDark = Color(0xFF6B7399);

  // Light Mode
  static const Color textPrimaryLight = Color(0xFF1A1D2E);
  static const Color textSecondaryLight = Color(0xFF4A5167);
  static const Color textTertiaryLight = Color(0xFF8B92A8);

  // ============ ESTADOS ============

  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFAB00);
  static const Color error = Color(0xFFFF3D71);
  static const Color info = Color(0xFF00B8D4);

  // ============ BORDERS & DIVIDERS ============

  static const Color borderDark = Color(0xFF2A3154);
  static const Color borderLight = Color(0xFFD1D9E6);
  static const Color dividerDark = Color(0xFF1E2749);
  static const Color dividerLight = Color(0xFFE0E5ED);

  // ============ OVERLAYS ============

  static const Color overlayDark = Color(0x99000000);
  static const Color overlayLight = Color(0x66FFFFFF);

  // ============ GRADIENTES ============

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C9A7), accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============ SHADOWS ============

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: primaryDark.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.4),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
