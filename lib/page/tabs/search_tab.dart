import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  String _keyword = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _quickSearches = [
    '24 Jam',
    'Kimia Farma',
    'K-24',
    'Apotek',
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

  @override
  Widget build(BuildContext context) {
    final apotekAsync = ref.watch(apotekViewDataListProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── INTRO & SEARCH BAR ─────────────────────────────────────────────
          PageIntroCard(
            title: 'Cari Apotek',
            subtitle:
                'Temukan apotek berdasarkan nama atau jalan dengan pencarian cepat.',
            icon: Icons.search_rounded,
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
                      hintText: 'Ketik nama apotek atau lokasi...',
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

                // Popular search tag chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Cari cepat:',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    ..._quickSearches.map((tag) {
                      final isSelected =
                          _keyword.toLowerCase() == tag.toLowerCase();
                      return InkWell(
                        onTap: () => _applyQuickSearch(tag),
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
                          child: Text(
                            tag,
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
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── LIST DATA ──────────────────────────────────────────────────────
          apotekAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (err, st) => _emptyState(
              icon: Icons.error_outline_rounded,
              title: 'Data belum bisa dimuat',
              subtitle: 'Coba beberapa saat lagi. Detail error: $err',
            ),
            data: (List<ApotekViewData> listApotek) {
              final lower = _keyword.toLowerCase();
              final filtered = _keyword.isEmpty
                  ? listApotek
                  : listApotek.where((apotek) {
                      final namaMatches =
                          apotek.name.toLowerCase().contains(lower);
                      final alamatMatches =
                          apotek.address.toLowerCase().contains(lower);
                      return namaMatches || alamatMatches;
                    }).toList();

              if (filtered.isEmpty) {
                return _emptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Apotek tidak ditemukan',
                  subtitle:
                      'Tidak ada apotek dengan kata kunci "$_keyword". Coba kata kunci lainnya.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _resultBadge(
                        _keyword.isEmpty
                            ? 'Semua Apotek (${filtered.length})'
                            : '${filtered.length} apotek ditemukan',
                      ),
                      if (_keyword.isNotEmpty)
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
                            'Reset Filter',
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
                  ...filtered.map((viewData) {
                    return ApotekCard(
                      namaApotek: viewData.name,
                      alamat: viewData.address,
                      statusBuka: viewData.isBuka ? 'Buka' : 'Tutup',
                      jamOperasional: viewData.hours,
                      gambarUrl: viewData.imageUrl,
                      idApotek: viewData.id,
                      apotekData: viewData.raw,
                      distance: viewData.distance,
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
            child: Icon(icon, color: Colors.white, size: 36),
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