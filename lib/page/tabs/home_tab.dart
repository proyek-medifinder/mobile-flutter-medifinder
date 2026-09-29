import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum untuk mode filter buka/tutup
enum FilterMode { semua, buka, tutup }

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with SingleTickerProviderStateMixin {
  String username = '';
  bool isLoading = true;
  User? _firebaseUser;

  // State filter
  FilterMode _filterMode = FilterMode.semua;

  late AnimationController _filterAnimController;

  @override
  void initState() {
    super.initState();
    _filterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUsername();
  }

  @override
  void dispose() {
    _filterAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    setState(() {
      _firebaseUser = firebaseUser;
      username =
          firebaseUser?.displayName ??
          firebaseUser?.email ??
          prefs.getString('full_name') ??
          prefs.getString('email') ??
          prefs.getString('username') ??
          'User';
      isLoading = false;
    });
  }

  List<ApotekViewData> _applyFilter(List<ApotekViewData> list) {
    switch (_filterMode) {
      case FilterMode.buka:
        return list.where((a) => a.isBuka).toList();
      case FilterMode.tutup:
        return list.where((a) => !a.isBuka).toList();
      case FilterMode.semua:
        return list;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gunakan semua apotek, filter dilakukan di sisi client
    final apotekAsync = ref.watch(apotekViewDataListProvider);
    final googlePhoto = _firebaseUser?.photoURL;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HERO CARD ---
          PageIntroCard(
            title: 'Halo, $username',
            subtitle:
                'Cek daftar apotek yang siap melayani dan temukan informasi penting dengan lebih nyaman.',
            icon: Icons.favorite_rounded,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  backgroundImage:
                      googlePhoto != null ? NetworkImage(googlePhoto) : null,
                  child:
                      googlePhoto == null
                          ? const Icon(Icons.person, color: Colors.white)
                          : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _tagChip('Info apotek lengkap'),
                      _tagChip('Status buka real-time'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- SECTION TITLE ---
          Text(
            'Daftar Apotek',
            style: AppUi.sectionTitleStyle(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih apotek berdasarkan status operasionalnya.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70),
          ),

          const SizedBox(height: 16),

          // --- FILTER BAR ---
          _buildFilterBar(apotekAsync),

          const SizedBox(height: 18),

          // --- LIST APOTEK ---
          apotekAsync.when(
            loading:
                () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            error:
                (err, st) => _infoState(
                  icon: Icons.error_outline_rounded,
                  title: 'Data apotek belum bisa dimuat',
                  subtitle: 'Coba lagi beberapa saat. Detail error: $err',
                ),
            data: (List<ApotekViewData> allApotek) {
              final filtered = _applyFilter(allApotek);

              if (filtered.isEmpty) {
                final msg = switch (_filterMode) {
                  FilterMode.buka =>
                    'Saat ini belum ada apotek yang sedang buka.',
                  FilterMode.tutup =>
                    'Semua apotek sedang buka! Tidak ada yang tutup.',
                  FilterMode.semua => 'Belum ada data apotek tersedia.',
                };
                return _infoState(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Tidak ada apotek',
                  subtitle: msg,
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder:
                    (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                child: Column(
                  key: ValueKey(_filterMode),
                  children: filtered.map((viewData) {
                    return ApotekCard(
                      namaApotek: viewData.name,
                      alamat: viewData.address,
                      // Tampilkan "Buka" / "Tutup" berdasarkan getter isBuka
                      statusBuka: viewData.isBuka ? 'Buka' : 'Tutup',
                      jamOperasional: viewData.hours,
                      gambarUrl: viewData.imageUrl,
                      idApotek: viewData.id,
                      apotekData: viewData.raw,
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Filter Bar ─────────────────────────────────────────────────────────────

  Widget _buildFilterBar(AsyncValue<List<ApotekViewData>> apotekAsync) {
    int? total, bukaCount, tutupCount;
    apotekAsync.whenData((list) {
      total = list.length;
      bukaCount = list.where((a) => a.isBuka).length;
      tutupCount = list.where((a) => !a.isBuka).length;
    });

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          _filterChip(
            label: 'Semua',
            icon: Icons.apps_rounded,
            mode: FilterMode.semua,
            count: total,
            activeColor: Colors.white,
            activeTextColor: AppUi.primary,
          ),
          const SizedBox(width: 5),
          _filterChip(
            label: 'Buka',
            icon: Icons.store_rounded,
            mode: FilterMode.buka,
            count: bukaCount,
            activeColor: const Color(0xFF1B8A5A),
            activeTextColor: Colors.white,
          ),
          const SizedBox(width: 5),
          _filterChip(
            label: 'Tutup',
            icon: Icons.store_mall_directory_outlined,
            mode: FilterMode.tutup,
            count: tutupCount,
            activeColor: const Color(0xFFC0392B),
            activeTextColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required IconData icon,
    required FilterMode mode,
    int? count,
    required Color activeColor,
    required Color activeTextColor,
  }) {
    final isSelected = _filterMode == mode;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () => setState(() => _filterMode = mode),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? activeTextColor : Colors.white60,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeTextColor : Colors.white60,
                    ),
                  ),
                  if (count != null) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeTextColor.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? activeTextColor : Colors.white60,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _infoState({
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
          Icon(icon, color: Colors.white, size: 40),
          const SizedBox(height: 12),
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