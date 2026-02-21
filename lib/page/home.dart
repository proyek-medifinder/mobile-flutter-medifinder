import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/page/profile.dart';
import 'package:medifinder/page/obat.dart' as obat_page;
import 'package:medifinder/page/search.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/config/api_config.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:medifinder/services/auth_service.dart';

// import 'package:medifinder/services/notification_permission_service.dart';

class Home extends ConsumerStatefulWidget {
  const Home({super.key});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  String username = "";
  bool isLoading = true;
  int currentIndex = 0;

  User? _firebaseUser;
  // final user = FirebaseAuth.instance.currentUser;
  // final googlePhoto = user?.photoURL;
  // final googleName = user?.displayName;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    // NotificationPermissionService.request(context);
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    setState(() {
      _firebaseUser = firebaseUser;

      if (firebaseUser != null) {
        username = firebaseUser.displayName ?? firebaseUser.email ?? "User";
      } else {
        username = prefs.getString("username") ?? "User";
      }

      isLoading = false;
    });
  }

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
    final apotekAsync = ref.watch(apotekListProvider);
    final googleUser = _firebaseUser;
    final String? googlePhoto = googleUser?.photoURL;
    final String? googleName = googleUser?.displayName;

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Profile()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const obat_page.Obat()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Search()),
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

      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // ===== Header Welcome =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    child:
                        googlePhoto != null
                            ? ClipOval(
                              child: Image.network(
                                googlePhoto,
                                width: 45,
                                height: 45,
                                fit: BoxFit.cover,
                              ),
                            )
                            : const Icon(
                              Icons.account_circle,
                              size: 45,
                              color: Colors.white,
                            ),
                  ),

                  // Teks Welcome
                  Container(
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      'Welcome, ${googleName ?? username}!',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              // ===== Kartu Lokasi =====
              Container(
                margin: const EdgeInsets.only(top: 50),
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Image(
                      image: NetworkImage(
                        'https://i.pinimg.com/1200x/2e/0a/78/2e0a789278de18b14b6716d8ac229677.jpg',
                      ),
                      width: 350,
                      height: 330,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.red[400]),
                        Text(
                          'Lokasi mu di Lohbener',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ===== Judul Apotek =====
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'Apotek di wilayah mu:',
                      style: GoogleFonts.poppins(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: apotekAsync.when(
                  loading:
                      () => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  error:
                      (err, st) => Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Gagal memuat apotek: $err',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                  data: (listApotek) {
                    if (listApotek.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Belum ada data apotek.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: listApotek.length,
                      itemBuilder: (context, index) {
                        final apotek =
                            listApotek[index] as Map<String, dynamic>;

                        final namaApotek =
                            apotek['nama_apotek']?.toString() ?? '-';
                        final alamat =
                            apotek['alamat']?.toString() ??
                            'Alamat tidak tersedia';
                        final statusBuka =
                            apotek['status_buka']?.toString() ?? '';
                        final jamOperasional =
                            apotek['jam_operasional']?.toString() ?? '';
                        // final idApotek = apotek['id_apotek']?.toString() ?? '';
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

                              // ===== Nama + Status buka =====
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

                              // ===== Alamat =====
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

                              // ===== Tombol Kunjungi =====
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
                                                idApotek:
                                                    apotek['id_apotek']
                                                        .toString(),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
