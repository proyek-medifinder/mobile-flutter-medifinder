import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class ObatTab extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const ObatTab({super.key, this.onNavigateTab});

  @override
  ConsumerState<ObatTab> createState() => _ObatTabState();
}

class _ObatTabState extends ConsumerState<ObatTab> {
  String _keyword = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<Map<String, String>> _popularCategories = [
    {'label': 'Paracetamol', 'icon': '💊'},
    {'label': 'Flu & Batuk', 'icon': '🤧'},
    {'label': 'Maag', 'icon': '⚡'},
    {'label': 'Vitamin C', 'icon': '🍊'},
    {'label': 'Antiseptik', 'icon': '🩹'},
    {'label': 'Ibuprofen', 'icon': '🌡️'},
    {'label': 'Minyak Kayu Putih', 'icon': '🌿'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyQuickSearch(String text) {
    _searchController.text = text;
    setState(() {
      _keyword = text.trim();
    });
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
          // ── INTRO CARD & SEARCH INPUT ──────────────────────────────────────
          PageIntroCard(
            title: 'Katalog Obat',
            subtitle:
                'Cari ketersediaan obat dan temukan apotek mana saja yang menyediakannya.',
            icon: Icons.medication_rounded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean White Search Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ketik nama obat (cth: Paracetamol)...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.black38,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0F756B),
                      ),
                      suffixIcon: _keyword.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.cancel_rounded,
                                color: Colors.black45,
                                size: 19,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _keyword = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _keyword = value.trim();
                      });
                    },
                  ),
                ),

                const SizedBox(height: 14),

                // Popular Medicine Category Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Pilihan:',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ..._popularCategories.map((item) {
                      final label = item['label']!;
                      final icon = item['icon']!;
                      final isSelected =
                          _keyword.toLowerCase() == label.toLowerCase();
                      return InkWell(
                        onTap: () => _applyQuickSearch(label),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  color: isSelected
                                      ? const Color(0xFF0F756B)
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── HASIL PENCARIAN ATAU TIPS EDUKASI ──────────────────────────────
          if (_keyword.isEmpty)
            _buildEmptyGuidance()
          else
            apotekAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
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
                return FutureBuilder<List<_ApotekSearchResult>>(
                  future: _searchObat(listApotek, _keyword),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Mencari apotek penyedia "$_keyword"...',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
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
                            'Belum ada apotek terdaftar yang mencantumkan "$_keyword". Coba kata kunci atau nama generik lainnya.',
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _resultBadge(
                              '${results.length} apotek menyediakan "$_keyword"',
                            ),
                            TextButton.icon(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _keyword = '');
                              },
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              label: Text(
                                'Reset',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ...results.map((result) {
                          return ApotekCard(
                            namaApotek: result.viewData.name,
                            alamat: result.viewData.address,
                            statusBuka:
                                result.viewData.isBuka ? 'Buka' : 'Tutup',
                            jamOperasional: result.viewData.hours,
                            gambarUrl: result.viewData.imageUrl,
                            idApotek: result.viewData.id,
                            tags: result.tags,
                            apotekData: result.raw,
                            distance: result.viewData.distance,
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

  Widget _buildEmptyGuidance() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: AppUi.glassDecoration(radius: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_liquid_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Mulai Eksplorasi Obat',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ketik nama obat atau pilih salah satu kategori di atas untuk mengecek stok di seluruh apotek mitra.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Banner AI Advice
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Center(
                  child: Text('🤖', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bingung Memilih Obat?',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Konsultasikan gejala penyakit ke MediBot AI.',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F756B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.onNavigateTab?.call(2);
                },
                child: Text(
                  'Tanya AI',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
      padding: const EdgeInsets.all(28),
      decoration: AppUi.glassDecoration(radius: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 16),
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
