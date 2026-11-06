# Login Google Mobile melalui backend MediFinder

Mobile kini menggunakan kontrak login yang sama dengan web:

```text
Pilih akun melalui Google Sign-In native
  → Google ID token (audience: Web OAuth Client ID)
  → POST /google-login {"token":"GOOGLE_ID_TOKEN"}
  → JWT MediFinder dari backend
  → GET /me dengan Authorization: Bearer JWT
  → Simpan sesi backend dan buka aplikasi
```

Firebase Authentication, inisialisasi Firebase, dependensi Firebase, dan plugin Google Services Gradle telah dihapus. Google Sign-In tetap dipakai sebagai antarmuka pemilihan akun dan penyedia ID token OAuth/OpenID Connect. Tidak diperlukan browser callback atau deep link baru untuk alur native Android ini.

## Konfigurasi yang digunakan

| Pengaturan | Nilai |
| --- | --- |
| Backend default | `https://medifinder-backend-production.up.railway.app` |
| Endpoint login | `POST /google-login` |
| Endpoint profil | `GET /me` |
| Web OAuth Client ID / audience backend | `539021546127-kj6icorqjdrouo9n31tla5r2tcl90e7r.apps.googleusercontent.com` |
| Package Android | `com.example.medifinder` |
| SHA-1 debug pada komputer ini | `F4:56:A2:38:73:83:58:06:5E:FA:17:9A:55:16:0B:F1:8D:23:B4:16` |

Client ID adalah identitas publik aplikasi. Client secret OAuth tidak digunakan di aplikasi Flutter.

## Langkah Google Cloud untuk Android

1. Buka [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials) dan pilih proyek yang memiliki Web OAuth Client ID di atas. Kredensial Firebase lama berasal dari project number `969264091748`; client web yang digunakan aplikasi berasal dari project number `539021546127`.
2. Pastikan tersedia OAuth client bertipe **Android** pada proyek yang sama, dengan package `com.example.medifinder` dan SHA-1 debug di atas. Buat jika belum tersedia. Client ID Android tidak menggantikan Web Client ID pada `serverClientId`.
3. Periksa konfigurasi consent screen/audience. Jika aplikasi masih Testing dan akses akun dibatasi, tambahkan akun penguji yang diperlukan.
4. Pastikan konfigurasi `GOOGLE_CLIENT_ID` backend sesuai dengan Web Client ID yang dipakai mobile dan web.
5. Bangun ulang dan pasang aplikasi. Perubahan dependensi/plugin native memerlukan rebuild penuh; hot reload tidak cukup.

Registrasi Google Cloud harus diperiksa pada akun pemilik proyek; perubahan kode dan tes tiruan tidak membuktikan bahwa pasangan package/SHA sudah terdaftar di Google Cloud. Akun, pemilih Google native, dan akses end-to-end perlu diuji pada emulator/perangkat Android yang memiliki Google Play services.

Jika memakai signing key berbeda (mesin lain, CI, release, atau Play App Signing), daftarkan SHA-1 dari sertifikat penandatangan build tersebut. Fingerprint di atas diperiksa dari debug keystore komputer ini, bukan dari sertifikat produksi.

Untuk melihat ulang fingerprint debug:

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## Override konfigurasi build

Nilai default berada di `lib/config/api_config.dart`. Bila perlu, override dengan:

```powershell
flutter run --dart-define=MEDIFINDER_API_BASE=https://BACKEND-ANDA --dart-define=GOOGLE_WEB_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
```

Gunakan backend yang sudah menyediakan `/google-login` dan `/me`. Jika client ID diubah, samakan audience yang diizinkan backend. Jangan memakai Client ID atau token Firebase sebagai token yang dikirim ke `/google-login`.

## Sesi, profil, dan logout

- Login Google dianggap berhasil setelah backend menerbitkan JWT dan `/me` berhasil memuat profil.
- Nama, email, foto profil, user ID, dan role berasal dari backend. Pemilik akun di mobile mengikuti akun database yang sama dengan web.
- Google ID token hanya dipakai untuk pertukaran login; token tersebut tidak disimpan sebagai sesi aplikasi.
- Sesi menggunakan `auth_token` JWT MediFinder di penyimpanan lokal yang sudah dipakai proyek. Login Google menghapus password lokal lama.
- Saat mulai, aplikasi memeriksa expiry JWT dan memperbarui profil melalui `/me`. Token yang salah, kedaluwarsa, atau ditolak server dihapus.
- Saat gangguan jaringan/server sementara, sesi cache yang belum kedaluwarsa dipertahankan. Endpoint backend tetap memverifikasi JWT dan izin pada setiap permintaan.
- Akun Firebase lama tanpa JWT MediFinder harus masuk ulang. Keberadaan akun Google pada SDK tidak cukup untuk membuka aplikasi sebagai pengguna terautentikasi.
- Logout dan Hapus Kredensial Lokal menghapus JWT dan metadata akun, lalu kembali ke login. Kegagalan sign-out Google tidak menghalangi penghapusan sesi lokal.
- Perubahan ini tidak mengubah sesi browser web. Logout di satu perangkat tidak otomatis mencabut JWT perangkat lain.

Form profil untuk login password masih merupakan pengaturan lokal dari implementasi sebelumnya; ini bukan endpoint perubahan password server.

## iOS dan macOS

Kode layanan mendukung `GOOGLE_IOS_CLIENT_ID` untuk inisialisasi Google Sign-In pada platform Apple. Konfigurasi aplikasi Apple belum lengkap pada proyek ini dan tidak diuji dari Windows:

1. Daftarkan OAuth client iOS dengan bundle identifier aplikasi pada proyek Google yang sama.
2. Berikan client ID tersebut menggunakan `--dart-define=GOOGLE_IOS_CLIENT_ID=...` (atau konfigurasi `GIDClientID` pada Info.plist).
3. Tambahkan reversed iOS client ID ke `CFBundleURLTypes` / `CFBundleURLSchemes` di `ios/Runner/Info.plist`. Passing client ID dari Dart tidak menggantikan langkah URL scheme ini.
4. Gunakan Web Client ID yang sama sebagai serverClientId. Untuk macOS, lengkapi URL scheme dan keychain sharing sesuai dokumentasi plugin.
5. Jalankan instalasi Pods/build serta uji login di macOS/perangkat Apple.

Google Sign-In native bukan implementasi login browser Flutter Web atau login Windows/Linux. Website Nuxt tetap memakai Google Identity Services yang sudah ada.

## Pengujian

```powershell
flutter pub get
flutter test
flutter analyze
flutter build apk --debug --no-pub
```

Tes menggunakan identitas Google dan respons HTTP tiruan, tanpa login akun Google atau membuat akun database sungguhan. Cakupan: endpoint dan payload yang sama dengan web, JWT backend, profil `/me`, pembatalan login, penolakan akun, respons tanpa JWT, penolakan `/me`, pemulihan sesi, expiry, gangguan server, dan logout.

Jika login ditolak pada perangkat, periksa konfigurasi package/SHA, serverClientId, audience backend, serta akses akun penguji. Beberapa kesalahan konfigurasi Android dapat dilaporkan SDK sebagai canceled setelah pemilihan akun; tinjau konfigurasi meskipun tidak muncul pesan error terperinci.

Rujukan: [Google backend authentication](https://developers.google.com/identity/sign-in/android/backend-auth), [konfigurasi plugin Android](https://pub.dev/packages/google_sign_in_android), [sertifikat signing Android](https://developers.google.com/android/guides/client-auth), dan [konfigurasi plugin iOS](https://pub.dev/packages/google_sign_in_ios).
