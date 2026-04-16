import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/config/api_config.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String username = '';
  bool isLoading = true;
  User? _firebaseUser;

  @override
  void initState() {
    super.initState();
    _loadUsername();
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
          prefs.getString('username') ??
          'User';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final apotekAsync = ref.watch(apotekListProvider);
    final googlePhoto = _firebaseUser?.photoURL;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageIntroCard(
            title: 'Halo, $username',
            subtitle:
                'Cek daftar apotek yang siap melayani dan temukan informasi penting dengan lebih nyaman.',
            icon: Icons.favorite_rounded,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.18),
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
          Text(
            'Daftar Apotek yang tersedia',
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih apotek yang paling sesuai dengan kebutuhanmu hari ini.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 18),
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
            data: (listApotek) {
              if (listApotek.isEmpty) {
                return _infoState(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Belum ada apotek tersedia',
                  subtitle: 'Nanti daftar apotek akan tampil di sini.',
                );
              }

              return Column(
                children:
                    listApotek.map((item) {
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
                        idApotek: apotek['id_apotek'].toString(),
                      );
                    }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
      ),
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
