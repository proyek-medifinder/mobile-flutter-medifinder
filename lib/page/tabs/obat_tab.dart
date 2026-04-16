import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/config/api_config.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';

class ObatTab extends ConsumerStatefulWidget {
  const ObatTab({super.key});

  @override
  ConsumerState<ObatTab> createState() => _ObatTabState();
}

class _ObatTabState extends ConsumerState<ObatTab> {
  String _keyword = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apotekAsync = ref.watch(apotekListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageIntroCard(
            title: 'Cari Obat',
            subtitle:
                'Masukkan nama obat dan lihat apotek mana saja yang menyediakannya.',
            icon: Icons.medication_rounded,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik nama obat...',
                hintStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF0A5A52),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _keyword = value.trim();
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          apotekAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            error:
                (err, st) => _emptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Data obat belum bisa dimuat',
                  subtitle: 'Coba lagi nanti. Detail error: $err',
                ),
            data: (listApotek) {
              if (_keyword.isEmpty) {
                return _emptyState(
                  icon: Icons.vaccines_rounded,
                  title: 'Mulai pencarian obat',
                  subtitle: 'Masukkan nama obat untuk melihat apotek yang menyediakannya.',
                );
              }

              final lower = _keyword.toLowerCase();
              final filtered =
                  listApotek.where((item) {
                    final apotek = item as Map<String, dynamic>;
                    final obats = apotek['obats'] as List<dynamic>? ?? [];
                    return obats.any((o) {
                      final namaObat =
                          (o['nama_obat'] ?? '').toString().toLowerCase();
                      return namaObat.contains(lower);
                    });
                  }).toList();

              if (filtered.isEmpty) {
                return _emptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Obat belum ditemukan',
                  subtitle: 'Coba nama lain atau cek ejaan obat yang kamu cari.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultBadge('${filtered.length} apotek menyediakan obat ini'),
                  const SizedBox(height: 14),
                  ...filtered.map((item) {
                    final apotek = item as Map<String, dynamic>;
                    final String? fotoPath = apotek['foto_apotek'];
                    final obats = apotek['obats'] as List<dynamic>? ?? [];
                    final matchedTags =
                        obats
                            .where((o) {
                              final namaObat =
                                  (o['nama_obat'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              return namaObat.contains(lower);
                            })
                            .map((o) => (o['nama_obat'] ?? '').toString())
                            .where((nama) => nama.isNotEmpty)
                            .toSet()
                            .toList();

                    return ApotekCard(
                      namaApotek: apotek['nama_apotek']?.toString() ?? '-',
                      alamat:
                          apotek['alamat']?.toString() ??
                          'Alamat tidak tersedia',
                      statusBuka: apotek['status_buka']?.toString() ?? '',
                      jamOperasional:
                          apotek['jam_operasional']?.toString() ?? '',
                      gambarUrl:
                          (fotoPath != null && fotoPath.isNotEmpty)
                              ? ApiConfig.storageUrl(fotoPath)
                              : null,
                      idApotek: apotek['id_apotek']?.toString() ?? '',
                      tags: matchedTags,
                    );
                  }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _resultBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 42),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
