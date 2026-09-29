import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/theme/app_ui.dart';

class PageIntroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? child;

  const PageIntroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppUi.glassDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 27),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (child != null) ...[
            const SizedBox(height: 18),
            child!,
          ],
        ],
      ),
    );
  }
}
