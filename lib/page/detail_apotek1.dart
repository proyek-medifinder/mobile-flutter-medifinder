import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/config/api_config.dart';

class DetailApotek1 extends ConsumerWidget {
  final String idApotek;

  const DetailApotek1({super.key, required this.idApotek});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apotekAsync = ref.watch(apotekDetailProvider(idApotek));

    return Scaffold(
      backgroundColor: const Color(0xFF0F756B),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Detail Apotek',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: apotekAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, st) => Center(
              child: Text(
                "Error: $err",
                style: const TextStyle(color: Colors.white),
              ),
            ),
        data: (apotek) {
          final nama = apotek['nama_apotek'] ?? '-';
          final alamat = apotek['alamat'] ?? '-';
          final telepon = apotek['telepon'] ?? '-';
          final email = apotek['email'] ?? '-';
          final jam = apotek['jam_operasional'] ?? '-';
          final deskripsi = apotek['deskripsi'] ?? '-';
          final statusBuka = apotek['status_buka'] ?? '-';

          final foto = apotek['foto_apotek'];
          final fotoUrl = foto != null ? ApiConfig.storageUrl(foto) : null;
          final List<dynamic> obats = (apotek['obats'] as List?) ?? <dynamic>[];

          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  // ===== Judul =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 20, left: 20),
                        child: Text(
                          nama,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ===== Foto Apotek =====
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: 420,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          fotoUrl != null
                              ? Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) =>
                                        const Icon(Icons.broken_image),
                              )
                              : Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
                                ),
                              ),
                    ),
                  ),

                  // ===== Informasi Dasar =====
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: 420,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        infoText("Alamat", alamat),
                        infoText("Telepon", telepon),
                        infoText("Email", email),
                        infoText("Jam Operasional", jam),
                        infoText("Status", statusBuka),
                      ],
                    ),
                  ),

                  // ===== Deskripsi =====
                  Container(
                    margin: const EdgeInsets.only(top: 20),
                    width: 420,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Deskripsi :",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          deskripsi,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ===== Daftar Obat =====
                  const SizedBox(height: 16),
                  Text(
                    "Daftar Obat di Apotek Ini",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  obats.isEmpty
                      ? Text(
                        "Belum ada obat",
                        style: GoogleFonts.poppins(color: Colors.white),
                      )
                      : SizedBox(
                        width: 420,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          itemCount: obats.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 160 / 150,
                              ),
                          itemBuilder: (context, index) {
                            final o = obats[index];
                            final obatNama = o['nama_obat'] ?? '-';
                            final stok = o['stok'] ?? 0;
                            final fotoObat = o['gambar_obat'];
                            final fotoObatUrl = 
                                fotoObat != null
                                    ? ApiConfig.storageUrl(fotoObat)
                                    : null;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child:
                                        fotoObatUrl != null
                                            ? Image.network(
                                              fotoObatUrl,
                                              height: 110,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                            : Container(
                                              height: 110,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              ),
                                            ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    obatNama,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Stok : $stok",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget infoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        "$label : $value",
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }
}
