# Referensi redesign mobile

Sumber: ZIP stitch_medifinder_mobile_re_design.zip yang diberikan pengguna.

Folder stitch menyimpan HTML, gambar layar, dan pedoman Clinical Clarity asli sebagai referensi. Implementasi aplikasi menggunakan widget Flutter, bukan mengeksekusi HTML/JavaScript referensi.

Ilustrasi SVG pada assets/onboarding diekstrak dari vektor pada HTML. Filter drop-shadow SVG dihilangkan untuk kompatibilitas flutter_svg; kedalaman tampilan diterapkan melalui dekorasi Flutter. Font Plus Jakarta Sans berasal dari repositori Google Fonts dan disertai lisensi OFL pada assets/fonts.

Teks contoh tentang SATUSEHAT, resep resmi, status ketersediaan username, data akun Sarah, dan jarak 1,2 km tidak dipakai sebagai data/fitur nyata aplikasi.

Referensi tahap halaman utama dari ZIP stitch_medifinder_mobile_re_design (1).zip disimpan di stitch_remaining. Logo tetap menggunakan aset navbar MediFinder yang sudah ada. Data, sertifikasi, rating, dan kontrol contoh tidak dianggap sebagai fitur backend tanpa dukungan implementasi. Rincian pemetaan dan batas integrasi dicatat pada design.md di root proyek.

Font Android memakai berkas statis Regular (400), Medium (500), SemiBold (600), Bold (700), dan ExtraBold (800), diturunkan dari sumber variable Plus Jakarta Sans yang sama melalui fontTools.varLib.instancer. Setiap bobot didaftarkan eksplisit pada pubspec.yaml. Sumber variable tetap disimpan sebagai referensi dan tidak dimuat sebagai font runtime.
