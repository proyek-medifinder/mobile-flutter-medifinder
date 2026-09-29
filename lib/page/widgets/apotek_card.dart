import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class ApotekCard extends StatelessWidget {
  final String namaApotek;
  final String alamat;
  final String statusBuka;
  final String jamOperasional;
  final String? gambarUrl;
  final String idApotek;
  final List<String> tags;
  final Map<String, dynamic>? apotekData;
  final double? distance;

  const ApotekCard({
    super.key,
    required this.namaApotek,
    required this.alamat,
    required this.statusBuka,
    required this.jamOperasional,
    required this.gambarUrl,
    required this.idApotek,
    this.tags = const [],
    this.apotekData,
    this.distance,
  });

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailApotek1(
          idApotek: idApotek,
          initialData: apotekData != null
              ? ApotekViewData.fromMap(apotekData!)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: AppUi.panelDecoration(radius: 24).copyWith(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToDetail(context),
          splashColor: AppUi.primary.withValues(alpha: 0.08),
          highlightColor: AppUi.primary.withValues(alpha: 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- GAMBAR ---
              SizedBox(
                height: 185,
                width: double.infinity,
                child: gambarUrl != null && gambarUrl!.isNotEmpty
                    ? Image.network(
                        gambarUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: const Color(0xFFF3F4F6),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2.5,
                                color: AppUi.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => _placeholder(),
                      )
                    : _placeholder(),
              ),

              // --- DETAIL & STATUS ---
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TAGS
                    if (tags.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppUi.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // NAMA APOTEK & STATUS BUKA
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            namaApotek,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.3,
                            ),
                          ),
                        ),
                        if (statusBuka.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppUi.statusColor(statusBuka).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: AppUi.statusColor(statusBuka),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  statusBuka,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppUi.statusColor(statusBuka),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ALAMAT, JARAK & JAM OPERASIONAL
                    _infoRow(Icons.location_on_rounded, alamat),
                    if (distance != null) ...[
                      const SizedBox(height: 8),
                      _infoRow(
                        Icons.near_me_rounded,
                        '${distance!.toStringAsFixed(2)} km dari lokasi Anda',
                        iconColor: AppUi.primary,
                        textColor: AppUi.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                    if (jamOperasional.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _infoRow(Icons.access_time_filled_rounded, jamOperasional),
                    ],

                    const SizedBox(height: 18),

                    // TOMBOL AKSI
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToDetail(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppUi.accent,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Kunjungi Apotek',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text, {
    Color? iconColor,
    Color? textColor,
    FontWeight? fontWeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: (iconColor ?? AppUi.primary).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor ?? AppUi.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: textColor ?? Colors.black87,
              fontWeight: fontWeight ?? FontWeight.normal,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() {
    return Container(
      height: 185,
      width: double.infinity,
      color: const Color(0xFFE5E7EB),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_pharmacy_rounded,
            size: 42,
            color: Colors.black.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 6),
          Text(
            'Gambar Tidak Tersedia',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.black45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}