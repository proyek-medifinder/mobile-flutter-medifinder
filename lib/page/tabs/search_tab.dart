import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/config/api_config.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
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
            title: 'Cari Apotek',
            subtitle:
                'Temukan apotek berdasarkan nama, lalu buka detailnya untuk melihat informasi lengkap.',
            icon: Icons.search_rounded,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik nama apotek...',
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
                  title: 'Data belum bisa dimuat',
                  subtitle: 'Coba beberapa saat lagi. Detail error: $err',
                ),
            data: (listApotek) {
              if (_keyword.isEmpty) {
                return _emptyState(
                  icon: Icons.travel_explore_rounded,
                  title: 'Mulai pencarian apotek',
                  subtitle: 'Masukkan nama apotek untuk melihat hasil yang cocok.',
                );
              }

              final lower = _keyword.toLowerCase();
              final filtered =
                  listApotek.where((item) {
                    final map = item as Map<String, dynamic>;
                    final nama =
                        (map['nama_apotek'] ?? '').toString().toLowerCase();
                    return nama.contains(lower);
                  }).toList();

              if (filtered.isEmpty) {
                return _emptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Apotek tidak ditemukan',
                  subtitle: 'Coba kata kunci lain yang lebih spesifik.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultBadge('${filtered.length} apotek ditemukan'),
                  const SizedBox(height: 14),
                  ...filtered.map((item) {
                    final apotek = item as Map<String, dynamic>;
                    final String? fotoPath = apotek['foto_apotek'];

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
