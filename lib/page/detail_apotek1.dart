import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailApotek1 extends ConsumerWidget {
  const DetailApotek1({super.key, required this.idApotek, this.initialData});

  final String idApotek;
  final ApotekViewData? initialData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(apotekDetailProvider(idApotek));

    return Scaffold(
      backgroundColor: AppUi.primary,
      body: detailAsync.when(
        loading: () => _buildContent(context, initialData, isRefreshing: true),
        error:
            (err, st) => _buildContent(
              context,
              initialData,
              errorText:
                  'Gagal memperbarui detail. Menampilkan data yang tersimpan.',
            ),
        data: (data) => _buildContent(context, ApotekViewData.fromMap(data)),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ApotekViewData? data, {
    bool isRefreshing = false,
    String? errorText,
  }) {
    final viewData =
        data ??
        initialData ??
        ApotekViewData(
          id: idApotek,
          name: 'Detail Apotek',
          address: 'Alamat tidak tersedia',
          status: '',
          hours: '',
        );

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Hero Image / Sliver App Bar
            SliverAppBar(
              expandedHeight: isDesktop ? 320.0 : 250.0,
              pinned: true,
              backgroundColor: AppUi.primary,
              elevation: 0,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    viewData.imageUrl != null
                        ? Image.network(
                          viewData.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _heroPlaceholder(),
                        )
                        : _heroPlaceholder(),
                    // Overlay Gradient biar teks/tombol back tetap jelas
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.5),
                            Colors.transparent,
                            AppUi.primary.withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Main Content Body
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (errorText != null) ...[
                          _noticeBanner(errorText),
                          const SizedBox(height: 16),
                        ],

                        // Header Info Card (Nama, Status, Buka/Tutup)
                        _buildHeaderCard(viewData),
                        const SizedBox(height: 20),

                        // Quick Actions (Telepon / Email)
                        _buildQuickActionButtons(context, viewData),
                        const SizedBox(height: 20),

                        // Informasi Utama
                        _sectionCard(
                          title: 'Informasi Utama',
                          child: Column(
                            children: [
                              _infoTile(
                                Icons.location_on_rounded,
                                'Alamat',
                                viewData.address,
                              ),
                              if ((viewData.hours).isNotEmpty)
                                _infoTile(
                                  Icons.access_time_filled_rounded,
                                  'Jam Operasional',
                                  viewData.hours,
                                ),
                              if ((viewData.phone ?? '').isNotEmpty)
                                _infoTile(
                                  Icons.phone_rounded,
                                  'Nomor Telepon',
                                  viewData.phone!,
                                ),
                              if ((viewData.email ?? '').isNotEmpty)
                                _infoTile(
                                  Icons.email_rounded,
                                  'Email',
                                  viewData.email!,
                                ),
                            ],
                          ),
                        ),

                        // Deskripsi jika ada
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

                        // Daftar Obat / Produk
                        _sectionCard(
                          title: 'Daftar Obat Tersedia',
                          child:
                              viewData.medicines.isEmpty
                                  ? _buildEmptyMedicines()
                                  : _buildMedicineGrid(
                                    context,
                                    viewData.medicines,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        // Indicator Loading Transparan saat Refreshing Data
        if (isRefreshing)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- WIDGET HELPER ---

  Widget _buildHeaderCard(ApotekViewData data) {
    final statusColor = AppUi.statusColor(data.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppUi.panelDecoration(radius: 24),
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
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
              if (data.status.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.black54,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  data.address,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, ApotekViewData data) {
    final hasPhone = (data.phone ?? '').isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                hasPhone
                    ? () async {
                      final uri = Uri.parse('tel:${data.phone}');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                    : null,
            icon: const Icon(Icons.call_rounded, size: 18),
            label: Text(
              'Hubungi Apotek',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A5A52),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white24,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppUi.panelDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5F3),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: AppUi.primary),
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineGrid(
    BuildContext context,
    List<ObatViewData> medicines,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: medicines.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (context, index) {
            final obat = medicines[index];
            final inStock = obat.stock > 0;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppUi.mutedSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          obat.imageUrl != null
                              ? Image.network(
                                obat.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => _miniPlaceholder(),
                              )
                              : _miniPlaceholder(),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    inStock
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                inStock ? 'Stok: ${obat.stock}' : 'Habis',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    obat.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyMedicines() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            const Icon(
              Icons.medication_liquid_outlined,
              size: 40,
              color: Colors.black38,
            ),
            const SizedBox(height: 10),
            Text(
              'Belum ada daftar obat di apotek ini.',
              style: GoogleFonts.poppins(color: Colors.black54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Container(
      color: const Color(0xFF0E7067),
      child: const Center(
        child: Icon(
          Icons.local_pharmacy_rounded,
          size: 64,
          color: Colors.white30,
        ),
      ),
    );
  }

  Widget _miniPlaceholder() {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Center(
        child: Icon(Icons.medication_outlined, color: Colors.black38, size: 28),
      ),
    );
  }

  Widget _noticeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: AppUi.glassDecoration(radius: 18),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
