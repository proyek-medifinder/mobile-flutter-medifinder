import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class DetailApotek1 extends ConsumerWidget {
  const DetailApotek1({
    super.key,
    required this.idApotek,
    this.initialData,
  });

  final String idApotek;
  final ApotekViewData? initialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(apotekDetailProvider(idApotek));

    return Scaffold(
      backgroundColor: AppUi.primary,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Detail Apotek',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: detailAsync.when(
        loading: () => _content(context, initialData, isRefreshing: true),
        error: (err, st) => _content(
          context,
          initialData,
          errorText: 'Detail terbaru belum bisa dimuat. Menampilkan data yang tersedia.',
        ),
        data: (data) => _content(
          context,
          ApotekViewData.fromMap(data),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    ApotekViewData? data, {
    bool isRefreshing = false,
    String? errorText,
  }) {
    final viewData =
        data ??
        ApotekViewData(
          id: idApotek,
          name: 'Detail apotek',
          address: 'Alamat tidak tersedia',
          status: '',
          hours: '',
        );

    return Stack(
      children: [
        SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorText != null) ...[
                _noticeBanner(errorText),
                const SizedBox(height: 16),
              ],
              _heroCard(viewData),
              const SizedBox(height: 20),
              _sectionCard(
                title: 'Informasi Utama',
                child: Column(
                  children: [
                    _infoTile(Icons.location_on_rounded, 'Alamat', viewData.address),
                    if ((viewData.phone ?? '').isNotEmpty)
                      _infoTile(Icons.call_rounded, 'Telepon', viewData.phone!),
                    if ((viewData.email ?? '').isNotEmpty)
                      _infoTile(Icons.email_rounded, 'Email', viewData.email!),
                    if (viewData.hours.isNotEmpty)
                      _infoTile(
                        Icons.access_time_rounded,
                        'Jam Operasional',
                        viewData.hours,
                      ),
                    _infoTile(
                      Icons.verified_rounded,
                      'Status',
                      viewData.status.isEmpty ? 'Belum tersedia' : viewData.status,
                    ),
                  ],
                ),
              ),
              if ((viewData.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionCard(
                  title: 'Deskripsi',
                  child: Text(
                    viewData.description!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _sectionCard(
                title: 'Daftar Obat',
                child: viewData.medicines.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Belum ada data obat untuk apotek ini.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: viewData.medicines
                            .map((obat) => _medicineTile(obat))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
        if (isRefreshing)
          const Positioned(
            top: 16,
            right: 20,
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _noticeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppUi.glassDecoration(radius: 18),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _heroCard(ApotekViewData data) {
    return Container(
      width: double.infinity,
      decoration: AppUi.panelDecoration(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: data.imageUrl != null
                ? Image.network(
                    data.imageUrl!,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imagePlaceholder(),
                  )
                : _imagePlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        data.name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    if (data.status.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppUi.statusColor(data.status).withOpacity(0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          data.status,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppUi.statusColor(data.status),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data.address,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppUi.panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppUi.sectionTitleStyle(),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppUi.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicineTile(ObatViewData obat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppUi.mutedSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: obat.imageUrl != null
                ? Image.network(
                    obat.imageUrl!,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _miniImagePlaceholder(),
                  )
                : _miniImagePlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  obat.name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stok tersedia: ${obat.stock}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 48, color: Colors.black45),
      ),
    );
  }

  Widget _miniImagePlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFE5E7EB),
      child: const Icon(Icons.medication_outlined, color: Colors.black45),
    );
  }

}
