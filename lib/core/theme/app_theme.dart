import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand colours (same in both themes) ───────────────────────────────────
  static const Color primaryColor   = Color(0xFF2563EB);
  static const Color primaryLight   = Color(0xFFEFF6FF);
  static const Color accentColor    = Color(0xFF10B981);
  static const Color errorColor     = Color(0xFFEF4444);
  static const Color warningColor   = Color(0xFFF59E0B);

  // ── Light palette ─────────────────────────────────────────────────────────
  static const Color surfaceColor    = Color(0xFFF8FAFC);
  static const Color cardColor       = Color(0xFFFFFFFF);
  static const Color borderColor     = Color(0xFFE2E8F0);
  static const Color textPrimary     = Color(0xFF1E293B);
  static const Color textSecondary   = Color(0xFF64748B);
  static const Color textHint        = Color(0xFF94A3B8);

  // ── Dark palette ──────────────────────────────────────────────────────────
  static const Color darkBg          = Color(0xFF0F172A);
  static const Color darkCard        = Color(0xFF1E293B);
  static const Color darkBorder      = Color(0xFF334155);
  static const Color darkText        = Color(0xFFF1F5F9);
  static const Color darkTextSub     = Color(0xFF94A3B8);

  // ── Helper: get correct card color for current theme ─────────────────────
  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkCard : cardColor;

  static Color scaffoldBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBg : surfaceColor;

  static Color divider(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBorder : borderColor;

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkText : textPrimary;

  static Color textSub(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSub : textSecondary;

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: surfaceColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ).copyWith(primary: primaryColor, surface: surfaceColor, error: errorColor),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardTheme(
        color: cardColor, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor),
        ),
      ),
      dividerColor: borderColor,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: textHint, fontSize: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : textHint),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primaryColor : borderColor),
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(primary: primaryColor, surface: darkBg, error: errorColor),
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: darkCard,
        foregroundColor: darkText,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: GoogleFonts.inter(color: darkText, fontSize: 18, fontWeight: FontWeight.w700),
        iconTheme: const IconThemeData(color: darkText),
      ),
      cardTheme: CardTheme(
        color: darkCard, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: darkBorder),
        ),
      ),
      dividerColor: darkBorder,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor, foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFF253047),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: darkBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: darkBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: primaryColor, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: darkTextSub, fontSize: 14),
        labelStyle: const TextStyle(color: darkTextSub),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : darkTextSub),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primaryColor : darkBorder),
      ),
      listTileTheme: const ListTileThemeData(textColor: darkText, iconColor: darkText),
      popupMenuTheme: const PopupMenuThemeData(color: darkCard),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: darkCard),
      dialogTheme: const DialogTheme(backgroundColor: darkCard),
    );
  }
}
