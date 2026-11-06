import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppUi {
  static const background = Color(0xFFF7FBF9);
  static const ink = Color(0xFF191C1E);
  static const secondary = Color(0xFF596562);
  static TextStyle text({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
  }) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: fontSize ?? 14,
    fontWeight: fontWeight,
    color: color,
    height: height ?? 1.5,
    letterSpacing: letterSpacing,
    fontStyle: fontStyle,
  );
  static AppColors colors(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? AppColors.dark
          : AppColors.light;
  static ThemeData get theme => buildTheme(Brightness.light);
  static ThemeData get darkTheme => buildTheme(Brightness.dark);
  static ThemeData buildTheme(Brightness brightness) {
    final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    ).copyWith(
      primary: c.primaryText,
      onPrimary: c.isDark ? primaryDark : Colors.white,
      surface: c.surface,
      onSurface: c.ink,
      error: c.error,
      outline: c.line,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: 'PlusJakartaSans',
      colorScheme: scheme,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    );
    return base.copyWith(
      scaffoldBackgroundColor: c.background,
      textTheme: base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink),
      iconTheme: IconThemeData(color: c.primaryText),
      appBarTheme: AppBarTheme(
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              c.isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: c.isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: c.background,
          systemNavigationBarIconBrightness:
              c.isDark ? Brightness.light : Brightness.dark,
        ),
        backgroundColor: c.surface,
        foregroundColor: c.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      drawerTheme: DrawerThemeData(backgroundColor: c.surface),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.muted,
        hintStyle: text(fontSize: 13, color: c.secondary),
        labelStyle: text(color: c.secondary),
        prefixIconColor: c.secondary,
        suffixIconColor: c.secondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: c.primaryText, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: text(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primaryText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primaryText,
          side: BorderSide(color: c.line),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBackgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primaryText),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: c.surface,
        side: BorderSide(color: c.line),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.isDark ? c.raised : primaryDark,
        contentTextStyle: text(color: Colors.white),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.primaryText,
        selectionColor: c.primaryText.withValues(alpha: .25),
      ),
    );
  }

  static const Color primary = Color(0xFF0F756B);
  static const Color primaryDark = Color(0xFF0A5A52);
  static const Color accent = Color(0xFFFDBF2D);
  static const Color surface = Colors.white;
  static const Color mutedSurface = Color(0xFFF6F7F9);
  static const Color line = Color(0xFFE5E7EB);

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(color: Color(0x100A5A52), blurRadius: 16, offset: Offset(0, 6)),
  ];

  static BoxDecoration panelDecoration({
    double radius = 24,
    Color color = surface,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: cardShadow,
    );
  }

  static BoxDecoration glassDecoration({double radius = 28}) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.10),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    );
  }

  static Color statusColor(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approved') ||
        lower.contains('buka') ||
        lower.contains('open')) {
      return const Color(0xFF1B8A5A);
    }
    if (lower.contains('tutup') ||
        lower.contains('close') ||
        lower.contains('reject')) {
      return const Color(0xFFC0392B);
    }
    return primary;
  }

  static TextStyle sectionTitleStyle({Color color = Colors.black}) {
    return AppUi.text(fontSize: 21, fontWeight: FontWeight.w700, color: color);
  }

  static TextStyle sectionSubtitleStyle({Color color = Colors.black54}) {
    return AppUi.text(fontSize: 13, color: color, height: 1.55);
  }
}

/// Matches the web slate/emerald dark palette; no global mutable brightness.
class AppColors {
  const AppColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.muted,
    required this.raised,
    required this.ink,
    required this.secondary,
    required this.line,
    required this.primaryText,
    required this.softTeal,
    required this.error,
    required this.errorSurface,
    required this.success,
  });
  final bool isDark;
  final Color background,
      surface,
      muted,
      raised,
      ink,
      secondary,
      line,
      primaryText,
      softTeal,
      error,
      errorSurface,
      success;
  static const light = AppColors(
    isDark: false,
    background: Color(0xFFF7FBF9),
    surface: Colors.white,
    muted: Color(0xFFF6F7F9),
    raised: Color(0xFFEDEFF0),
    ink: Color(0xFF191C1E),
    secondary: Color(0xFF596562),
    line: Color(0xFFE5E7EB),
    primaryText: Color(0xFF0F756B),
    softTeal: Color(0xFFE3F0ED),
    error: Color(0xFFBA1A1A),
    errorSurface: Color(0xFFFFE5E5),
    success: Color(0xFF1B8A5A),
  );
  static const dark = AppColors(
    isDark: true,
    background: Color(0xFF020617),
    surface: Color(0xFF0F172A),
    muted: Color(0xFF1E293B),
    raised: Color(0xFF334155),
    ink: Color(0xFFF8FAFC),
    secondary: Color(0xFFCBD5E1),
    line: Color(0xFF334155),
    primaryText: Color(0xFF34D399),
    softTeal: Color(0xFF12332F),
    error: Color(0xFFFDA4AF),
    errorSurface: Color(0xFF451A28),
    success: Color(0xFF6EE7B7),
  );
  Color status(Color value) =>
      !isDark
          ? value
          : value == const Color(0xFF1B8A5A)
          ? success
          : (value == const Color(0xFFC0392B) ||
              value == const Color(0xFFDC2626) ||
              value == const Color(0xFFBA1A1A))
          ? error
          : (value == AppUi.primary || value == AppUi.primaryDark)
          ? primaryText
          : value;
}
