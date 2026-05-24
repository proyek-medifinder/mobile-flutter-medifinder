import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

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

  Future<List<_ApotekSearchResult>> _searchObat(
    List<dynamic> listApotek,
    String keyword,
  ) async {
    final api = ref.read(productApiProvider);
    final results = await Future.wait(
      listApotek.map((item) async {
        final apotek = item as Map<String, dynamic>;
        final viewData = ApotekViewData.fromMap(apotek);

        if (viewData.id.isEmpty) {
          return null;
        }

        final obatList = await api.getObatByApotek(
          apotekId: viewData.id,
          name: keyword,
        );

        if (obatList.isEmpty) {
          return null;
        }

        final merged = Map<String, dynamic>.from(apotek);
        merged['obats'] = obatList;

        final detailData = ApotekViewData.fromMap(merged);
        final tags = detailData.medicines
            .map((obat) => obat.name)
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList();

        return _ApotekSearchResult(
          raw: merged,
          viewData: detailData,
          tags: tags,
        );
      }),
    );

    return results.whereType<_ApotekSearchResult>().toList();
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
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (err, st) => _emptyState(
              icon: Icons.error_outline_rounded,
              title: 'Data obat belum bisa dimuat',
              subtitle: 'Coba lagi nanti. Detail error: $err',
            ),
            data: (listApotek) {
              if (_keyword.isEmpty) {
                return _emptyState(
                  icon: Icons.vaccines_rounded,
                  title: 'Mulai pencarian obat',
                  subtitle:
                      'Masukkan nama obat untuk melihat apotek yang menyediakannya.',
                );
              }

              return FutureBuilder<List<_ApotekSearchResult>>(
                future: _searchObat(listApotek, _keyword),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return _emptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Pencarian obat gagal',
                      subtitle: 'Detail error: ${snapshot.error}',
                    );
                  }

                  final results = snapshot.data ?? const [];

                  if (results.isEmpty) {
                    return _emptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Obat belum ditemukan',
                      subtitle:
                          'Coba nama lain atau cek ejaan obat yang kamu cari.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _resultBadge(
                        '${results.length} apotek menyediakan obat ini',
                      ),
                      const SizedBox(height: 14),
                      ...results.map((result) {
                        return ApotekCard(
                          namaApotek: result.viewData.name,
                          alamat: result.viewData.address,
                          statusBuka: result.viewData.status,
                          jamOperasional: result.viewData.hours,
                          gambarUrl: result.viewData.imageUrl,
                          idApotek: result.viewData.id,
                          tags: result.tags,
                          apotekData: result.raw,
                        );
                      }),
                    ],
                  );
                },
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
      decoration: AppUi.glassDecoration(radius: 24),
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

class _ApotekSearchResult {
  const _ApotekSearchResult({
    required this.raw,
    required this.viewData,
    required this.tags,
  });

  final Map<String, dynamic> raw;
  final ApotekViewData viewData;
  final List<String> tags;
}
