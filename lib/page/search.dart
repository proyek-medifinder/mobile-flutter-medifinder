import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/profile.dart';
import 'package:medifinder/page/obat.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/config/api_config.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:medifinder/services/auth_service.dart';

class Search extends ConsumerStatefulWidget {
  const Search({super.key});

  @override
  ConsumerState<Search> createState() => _SearchState();
}

class _SearchState extends ConsumerState<Search> {
  int currentIndex = 1;
  String _keyword = ''; // kata kunci pencarian

  final TextEditingController _searchController = TextEditingController();

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    if (FirebaseAuth.instance.currentUser != null) {
      await AuthService().signOut();
    }

  
    await prefs.remove('username');
    await prefs.remove('password');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ambil semua apotek dari provider
    final apotekAsync = ref.watch(apotekListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F756B),
      appBar: AppBar(
        title: Text(
          'MEDIFINDER',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF0F756B)),
              child: Text(
                'Menu Navigasi',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('Keluar', style: GoogleFonts.poppins(fontSize: 16)),
              onTap: () async {
                Navigator.pop(context);
                await logout();
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: const Color(0xFF0F756B),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Home()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Obat()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Profile()),
            );
          }
        },
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Cari'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: 'Obat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),

      body: Column(
        children: [
          // ===== TextField Pencarian =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari apotek berdasarkan nama...',
                hintStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: const Color(0xFF0A5A52),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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

          // ===== Konten hasil pencarian =====
          Expanded(
            child: apotekAsync.when(
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
              error:
                  (err, st) => Center(
                    child: Text(
                      'Gagal memuat apotek: $err',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
              data: (listApotek) {
                // kalau belum mengetik apa-apa → kosong saja
                if (_keyword.isEmpty) {
                  return Center(
                    child: Text(
                      'Masukkan nama apotek untuk mencari',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                // filter berdasarkan nama_apotek
                final lower = _keyword.toLowerCase();
                final filtered =
                    listApotek.where((item) {
                      final map = item as Map<String, dynamic>;
                      final nama =
                          (map['nama_apotek'] ?? '').toString().toLowerCase();
                      return nama.contains(lower);
                    }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'Apotek dengan nama "$_keyword" tidak ditemukan',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final apotek = filtered[index] as Map<String, dynamic>;
                        final namaApotek =
                            apotek['nama_apotek']?.toString() ?? '-';
                        final alamat =
                            apotek['alamat']?.toString() ??
                            'Alamat tidak tersedia';
                        final statusBuka =
                            apotek['status_buka']?.toString() ?? '';
                        final jamOperasional =
                            apotek['jam_operasional']?.toString() ?? '';
                        final idApotek = apotek['id_apotek']?.toString() ?? '';

                        final String? fotoPath = apotek['foto_apotek'];
                        final String? gambarUrl =
                            (fotoPath != null && fotoPath.isNotEmpty)
                                ? ApiConfig.storageUrl(fotoPath)
                                : null;

                        return Container(
                          margin: const EdgeInsets.only(top: 20, bottom: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Gambar apotek (full card width)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child:
                                    gambarUrl != null
                                        ? SizedBox(
                                          height: 180,
                                          width: double.infinity,
                                          child: Image.network(
                                            gambarUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                        : Container(
                                          height: 180,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                            ),
                                          ),
                                        ),
                              ),

                              const SizedBox(height: 10),

                              // Nama + status buka
                              Row(
                                children: [
                                  Icon(
                                    Icons.medical_services,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      namaApotek,
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  if (statusBuka.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            statusBuka.toLowerCase() == 'buka'
                                                ? Colors.green[100]
                                                : Colors.red[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusBuka,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              statusBuka.toLowerCase() == 'buka'
                                                  ? Colors.green[800]
                                                  : Colors.red[800],
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              const SizedBox(height: 5),

                              // Alamat
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 18),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      alamat,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              if (jamOperasional.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      jamOperasional,
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 10),

                              // Tombol kunjungi
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (c) => DetailApotek1(
                                                idApotek: idApotek,
                                              ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.yellow[700],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Kunjungi',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
