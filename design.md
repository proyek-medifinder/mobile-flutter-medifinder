# MediFinder Mobile — Panduan Desain

Implementasi Flutter, diperbarui 4 November 2026. Dokumen ini menjelaskan tampilan yang sudah diterapkan, sumber desain, dan batas fitur yang tersedia.

## 1. Referensi dan identitas

Pedoman utama adalah **Clinical Clarity** dari ZIP pengguna:

- [Pedoman desain lengkap](docs/design_reference/stitch_remaining/clinical_clarity/DESIGN.md).
- Referensi login, daftar, dan onboarding: `docs/design_reference/stitch/`.
- Referensi delapan tampilan berikutnya: `docs/design_reference/stitch_remaining/`.
- Logo mengikuti logo asli navbar beranda: `assets/images/Logo-remove.png`. Jangan menggantinya dengan ikon medis generik, logo HealthLoc, atau teks merek baru.
- HTML dan gambar dalam folder referensi hanya digunakan untuk panduan visual; aplikasi dirender menggunakan widget Flutter.

Tujuan desain: informasi kesehatan dan apotek yang mudah dipindai, ruang kosong cukup, kontrol jelas, serta status yang selalu memiliki teks.

## 2. Token visual

| Token | Nilai | Penggunaan |
|---|---|---|
| Font | Plus Jakarta Sans | Seluruh aplikasi, dibundel lokal dengan lisensi OFL; file statis 400/500/600/700/800 |
| Primary | `#0F756B` | Tombol utama, navigasi aktif, judul penting |
| Primary dark | `#0A5A52` | Hero dan gradasi struktural |
| Teal light | `#14B8A6` | MediBot dan aksen AI |
| Background | `#F7FBF9` | Latar halaman |
| Surface | `#FFFFFF` | Kartu, formulir, navigasi, dialog |
| Muted surface | `#F6F7F9` | Metadata dan baris penyedia |
| Ink | `#191C1E` | Teks utama |
| Secondary text | `#596562` | Keterangan dan metadata |
| Line | `#E5E7EB` | Pemisah |
| Accent | `#FDBF2D` | Kunjungi apotek dan kontak |
| Open | `#1B8A5A` | Buka dan stok tersedia |
| Closed | `#C0392B` | Tutup dan stok habis |
| Destructive | `#DC2626` | Keluar akun |

Ukuran memakai logical pixels Flutter:

- Judul halaman 21–23, judul bagian 18, nama kartu 15–17, isi 13–14, metadata 10–12.
- Margin utama 20, jarak kartu 16, jarak antarseksi 24.
- Radius kartu 24, hero 26, input 14, tombol 14–16, pill 99.
- Tombol utama autentikasi tinggi 56; tombol kunjungi 48; target ikon umumnya 44–48.
- Bayangan lembut bernuansa teal dengan offset 6 dan blur 16.
- Latar utama terang; teal difokuskan pada hero dan CTA. Tema tersedia dalam mode Terang, Gelap, dan Ikuti Sistem.

Pusat token berada di `lib/theme/app_ui.dart`; tema diterapkan melalui `AppUi.theme` pada `lib/main.dart`. Komponen autentikasi menggunakan `AuthDesign` dengan warna dan font yang sejalan.

## 3. Alur dan navigasi

```text
Startup → pulihkan sesi backend
  ├─ Sesi aktif → Beranda / AppShell
  └─ Tanpa sesi
       ├─ Onboarding belum selesai → 3 langkah → Login / Daftar
       └─ Onboarding selesai → Login
```

- Onboarding ditandai selesai setelah dilewati atau diakhiri. Logout tidak mengulang onboarding.
- Navbar atas: menu, logo asli, avatar menuju profil.
- Drawer dan navigasi bawah memiliki tujuan yang sama.
- Navigasi bawah tetap lima tab: Beranda, Cari Apotek, MediBot, Cari Obat, Profil.
- MediBot menggunakan node bulat bergradasi teal dengan cincin terang.
- Halaman tab dibuat saat pertama dibuka, kemudian state pencarian dan percakapan dipertahankan ketika berpindah tab.
- Detail apotek dan edit profil adalah halaman terpisah dengan tombol kembali.

## 4. Tampilan per halaman

### Login, daftar, dan onboarding

- Formulir terang, panel putih, lebar maksimal 420; onboarding maksimal 440.
- Login: email, kata sandi dengan visibilitas, Ingat Saya, lupa kata sandi, Google, dan tautan daftar.
- Daftar: nama lengkap, email, kata sandi, konfirmasi. Indikator menunjukkan syarat delapan karakter, huruf besar, dan angka.
- Onboarding: apotek terdekat, ketersediaan obat, dan MediBot; tiga ilustrasi SVG dari referensi.
- Login Google tetap menukar ID token melalui `/google-login`, lalu mengambil `/me` dan menyimpan sesi JWT backend. Tidak menggunakan Firebase.
- Ingat Saya memulihkan sesi pada startup berikutnya; jika tidak dipilih, sesi dibersihkan saat startup berikutnya. Kata sandi mentah tidak disimpan.
- Lupa kata sandi memanggil `/forgot-password` dan menampilkan respons backend yang generik.
- Izin notifikasi diminta setelah masuk, bukan saat onboarding.

### Beranda

- Hero teal: sapaan dari akun, pintasan cari obat, lokasi pengguna, dan kontrol perbarui lokasi.
- Indikator pencarian lokasi serta pesan ketika GPS/izin belum tersedia.
- Banner MediBot yang dapat dibuka.
- Daftar apotek dengan filter Semua, Buka Sekarang, dan 24 Jam.
- Nama, alamat, gambar, jam, jarak jika tersedia, status, dan tombol detail berasal dari data API.
- Tarik untuk memperbarui daftar apotek.

### Cari Apotek

- Pengantar teal ringkas, input nama/alamat, dan kata kunci cepat.
- Filter semua/buka/tutup; jumlah hasil dihitung dari data yang ditampilkan.
- Urutan terdekat tersedia jika data memiliki jarak.
- Kartu apotek konsisten dengan beranda.
- Tombol peta membuka Google Maps sesuai lokasi pengguna; aplikasi belum menyematkan peta interaktif di dalam halaman.

### Cari Obat

- Hero katalog dengan pencarian nama obat, pintasan kata kunci, dan banner MediBot.
- Daftar diorganisasi per nama obat; satu obat dapat memiliki beberapa apotek penyedia.
- Setiap kartu menampilkan gambar jika ada, deskripsi, status stok, harga atau rentang harga, serta stok/harga per apotek.
- Filter Semua, Stok Tersedia, dan Harga Terendah menggunakan nilai dari API.
- Dua penyedia awal ditampilkan; pengguna dapat membuka penyedia lainnya.
- Kunjungi membuka detail apotek terkait.
- Provider katalog menyimpan hasil selama masih diamati; mengetik pencarian tidak mengirim permintaan baru untuk setiap karakter.
- Kegagalan sebagian apotek diberi keterangan; kegagalan seluruh katalog memiliki aksi coba lagi.

### Detail Apotek

- Navbar terang, foto hero, status operasional, panel nama dan tindakan.
- Kontak telepon/email hanya ditampilkan jika datanya tersedia. Rute membuka Google Maps berdasarkan koordinat atau alamat.
- Informasi operasional dan deskripsi berasal dari API.
- Pencarian katalog lokal dan filter Semua/Tersedia/Habis.
- Grid dua kolom, menjadi tiga kolom pada area di atas 500.
- Detail obat dibuka melalui kartu atau ikon informasi. Tidak menampilkan tombol keranjang yang belum terhubung ke transaksi mobile.
- Data awal ditampilkan saat detail diperbarui; kegagalan penyegaran memiliki keterangan dan aksi coba lagi.

### MediBot

- Latar terang, identitas AI, catatan edukasi singkat, dan pemilihan kelompok usia.
- Kelompok usia mengikuti kontrak backend yang sudah ada: balita <2, anak 2–12, dewasa 12–59, lansia 60+.
- Pengiriman pesan baru aktif setelah usia dipilih.
- Pesan pengguna teal; jawaban putih dengan pemformatan bold/italic/code, waktu, dan tombol salin.
- Rekomendasi apotek, stok, harga, jarak, detail, dan rute memakai respons backend.
- Ada indikator proses, topik cepat, dan konfirmasi mulai ulang percakapan.
- Riwayat percakapan lokal tetap menggunakan layanan sebelumnya.
- Tidak menampilkan kontrol mikrofon atau kamera yang belum memiliki implementasi.

### Profil dan edit profil

- Hero akun, identitas dari sesi, informasi akun, keamanan, bantuan, dan logout.
- Edit nama tampilan tersimpan pada perangkat melalui `display_name`; tidak mengubah nama akun server.
- Email ditampilkan sebagai informasi baca saja. Foto mengikuti akun yang terhubung.
- Kata sandi tidak ditampilkan atau disimpan pada formulir profil. Akun email dapat meminta tautan reset; akun Google diarahkan melalui penjelasan pengelolaan akun Google.
- Bersihkan cache hanya membersihkan cache gambar dalam memori, bukan menghapus token atau berpura-pura menghapus akun.
- Panduan, privasi perangkat, dan versi aplikasi disajikan sesuai kemampuan nyata.

### Konfirmasi keluar

- Dialog putih radius 26, ikon merah, nama/email akun aktual, tombol merah dan Batal.
- Profil dan drawer menggunakan dialog dan fungsi keluar yang sama.
- Konfirmasi membersihkan sesi termasuk nama tampilan perangkat; Batal mempertahankan sesi.
- Tidak mengklaim sertifikasi ISO/HIPAA atau status perlindungan data yang belum diverifikasi.

## 5. Komponen implementasi

| Lokasi | Tanggung jawab |
|---|---|
| `lib/theme/app_ui.dart` | Tema, tipografi, warna, permukaan |
| `lib/page/widgets/clinical_widgets.dart` | Panel, judul seksi, status pill, pencarian, filter, avatar, banner AI, state data |
| `lib/page/widgets/apotek_card.dart` | Kartu apotek dan placeholder gambar |
| `lib/page/widgets/logout_dialog.dart` | Konfirmasi dan alur logout bersama |
| `lib/page/widgets/auth/auth_widgets.dart` | Logo asli dan komponen formulir autentikasi |
| `lib/services/medicine_catalog.dart` | Penggabungan obat dan penyedia dari API |
| `lib/page/app_shell.dart` | Navbar, drawer, lima tab, navigasi bawah |
| `lib/page/edit_profile.dart` | Edit nama tampilan lokal |

## 6. Responsivitas dan state

- Konten halaman dapat digulir saat layar pendek, teks diperbesar, atau keyboard terbuka.
- Label panjang dibungkus atau dibatasi dua baris dengan ellipsis pada judul kartu.
- Filter dan pilihan usia dapat digulir horizontal.
- Status dibedakan dengan teks sekaligus warna.
- Gambar gagal/absen menampilkan placeholder medis, bukan foto contoh yang dianggap sebagai data nyata.
- Error data menampilkan pesan singkat dan aksi coba lagi; rincian teknis tidak ditampilkan pada alur pengguna.

## 7. Batas integrasi

Sumber ZIP memuat data contoh. Tidak semua kontrol atau klaimnya merupakan fitur backend. Tidak ditampilkan sebagai fitur nyata: rating/ulasan, BPJS, verifikasi Kemenkes, rekam medis, keanggotaan Gold, integrasi SATUSEHAT, sertifikasi keamanan, perubahan foto, dan pembelian/keranjang mobile.

Pencarian obat hanya mencakup apotek yang diberikan provider API saat ini. Daftar apotek reguler masih mengikuti pagination API yang sudah ada. Status stok dan operasional mengikuti data terakhir yang dimuat; konfirmasi langsung kepada apotek tetap disarankan.

Peta/rute saat ini dibuka di Google Maps. Edit nama bersifat lokal karena belum ada endpoint pembaruan profil umum. Fitur-fitur tersebut tidak diberi indikator sukses palsu.

## 8. Validasi

- Pengujian widget mencakup lima tab, pencarian/status apotek, stok obat, detail apotek dan obat, edit nama lokal, pembatalan logout, serta pengiriman MediBot dengan konteks usia.
- Render diperiksa pada 390×844, serta pengujian overflow pada 320×568 dengan skala teks 1,5 dan keyboard.
- Pengujian autentikasi dan onboarding tetap dijalankan bersama perubahan ini.
- Pratinjau lokal dihasilkan melalui pengujian dengan `--dart-define=UI_PREVIEW_DIR=build/design_previews` dan memakai data uji, bukan data produksi.
- Pengujian ini tidak menggantikan pemeriksaan GPS, aplikasi Google Maps, login Google, dan respons API produksi pada perangkat nyata.


## 9. Tema terang dan gelap

- Pengaturan berada pada ikon tema di navbar, halaman login/daftar/onboarding, dan Profil → Tema Aplikasi.
- Pilihan: Terang, Gelap, atau Ikuti Sistem. Nilai awal mengikuti sistem.
- Pilihan disimpan sebagai `appearance_theme_mode` melalui `ThemeController` dan dipulihkan sebelum aplikasi dirender. Pilihan tema tetap tersimpan ketika logout.
- Mode Ikuti Sistem merespons perubahan brightness Android tanpa mengubah ukuran font atau kepadatan layar perangkat.
- Palet gelap mengikuti web: background slate-950 `#020617`, panel slate-900 `#0F172A`, input/metadata slate-800 `#1E293B`, garis slate-700 `#334155`, teks `#F8FAFC` dan `#CBD5E1`, aksen emerald `#34D399`.
- `AppUi.colors(context)` menentukan warna berdasarkan tema pada subtree saat ini; tidak ada brightness global yang mengubah warna komponen lain secara tidak sengaja.
- Tombol kunjungan tetap amber dengan teks gelap; CTA teal tetap memakai teks putih. Status stok dan error memiliki warna yang lebih terang pada tema gelap.
- Tema meliputi autentikasi, onboarding, semua tab, detail apotek/obat, edit profil, dialog keluar, dan lembar lupa kata sandi.
- Foto dan ilustrasi tidak dibalik warnanya. Logo asli dan font Plus Jakarta Sans dipertahankan.
