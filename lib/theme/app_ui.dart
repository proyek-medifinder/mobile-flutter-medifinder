import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppUi {
  static const Color primary = Color(0xFF0F756B);
  static const Color primaryDark = Color(0xFF0A5A52);
  static const Color accent = Color(0xFFFDBF2D);
  static const Color surface = Colors.white;
  static const Color mutedSurface = Color(0xFFF6F7F9);
  static const Color line = Color(0xFFE5E7EB);

  static List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x18000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
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
    return GoogleFonts.poppins(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  static TextStyle sectionSubtitleStyle({Color color = Colors.black54}) {
    return GoogleFonts.poppins(
      fontSize: 13,
      color: color,
      height: 1.55,
    );
  }
}
