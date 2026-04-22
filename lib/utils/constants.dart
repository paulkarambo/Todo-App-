import 'package:flutter/material.dart';

// ── Colour Palette (matches React original) ──────────────────────────────────
class AppColors {
  static const background = Color(0xFF020617); // slate-950
  static const card = Color(0xFF0F172A); // slate-900
  static const surface = Color(0xFF1E293B); // slate-800
  static const border = Color(0xFF334155); // slate-700
  static const borderSubtle = Color(0xFF1E293B); // slate-800
  static const accent = Color(0xFF2563EB); // blue-600
  static const accentHover = Color(0xFF1D4ED8); // blue-700
  static const accentSoft = Color(0x262563EB); // blue-600 / 15 %
  static const textPrimary = Color(0xFFF1F5F9); // slate-100
  static const textSecondary = Color(0xFFCBD5E1); // slate-300
  static const textMuted = Color(0xFF94A3B8); // slate-400
  static const textDim = Color(0xFF475569); // slate-600
  static const priorityLow = Color(0xFF94A3B8); // slate-400
  static const priorityMedium = Color(0xFFF59E0B); // amber-500
  static const priorityHigh = Color(0xFFEF4444); // red-500
  static const danger = Color(0xFFEF4444);

  // Default project colours
  static const projectColors = [
    Color(0xFF2563EB), // blue-600
    Color(0xFF16A34A), // green-600
    Color(0xFFF97316), // orange-500
    Color(0xFFA855F7), // purple-500
    Color(0xFFEC4899), // pink-500
    Color(0xFF0EA5E9), // sky-500
    Color(0xFFEAB308), // yellow-500
    Color(0xFF14B8A6), // teal-500
  ];
}

// ── Sort / Group Enums ────────────────────────────────────────────────────────
enum SortMode { manual, priority, project }

enum SortDirection { asc, desc }

// ── Default Project IDs (stable — not random UUIDs) ──────────────────────────
class DefaultProjects {
  static const arbeitId = 'proj_arbeit';
  static const privatId = 'proj_privat';
}

// ── Priority helpers ──────────────────────────────────────────────────────────
class PriorityMeta {
  final String label;
  final Color color;
  final int order;
  const PriorityMeta({required this.label, required this.color, required this.order});
}

const priorityMeta = {
  'low': PriorityMeta(label: 'Niedrig', color: AppColors.priorityLow, order: 1),
  'medium': PriorityMeta(label: 'Mittel', color: AppColors.priorityMedium, order: 2),
  'high': PriorityMeta(label: 'Hoch', color: AppColors.priorityHigh, order: 3),
};

// ── Theme ─────────────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        surface: AppColors.card,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall: TextStyle(color: AppColors.textMuted),
        labelSmall: TextStyle(
          color: AppColors.textDim,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.textMuted),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.borderSubtle),
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.accent;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: AppColors.textDim, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      useMaterial3: true,
    );
  }
}
