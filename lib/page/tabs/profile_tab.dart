import 'package:medifinder/page/widgets/appearance_picker.dart';
import 'package:flutter/material.dart';
import 'package:medifinder/page/edit_profile.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/page/widgets/logout_dialog.dart';
import 'package:medifinder/page/widgets/auth/forgot_password_sheet.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  String _name = '', _email = '';
  String? _photo;
  bool _google = false, _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name =
          p.getString('display_name') ?? p.getString('full_name') ?? 'Pengguna';
      _email = p.getString('email') ?? '';
      _photo = p.getString('profile_picture');
      _google = p.getString('auth_provider') == 'google';
      _loading = false;
    });
  }

  Future<void> _edit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
    await _load();
  }

  void _info(String title, String body) => showDialog(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(body, style: AppUi.text(fontSize: 13)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        ),
  );
  Widget _tile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool arrow = true,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppUi.colors(context).softTeal,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppUi.colors(context).primaryText, size: 22),
    ),
    title: Text(
      title,
      style: AppUi.text(fontSize: 14, fontWeight: FontWeight.w600),
    ),
    subtitle:
        subtitle.isEmpty
            ? null
            : Text(
              subtitle,
              style: AppUi.text(
                fontSize: 12,
                color: AppUi.colors(context).secondary,
              ),
            ),
    trailing:
        arrow
            ? Icon(
              Icons.chevron_right_rounded,
              size: 21,
              color: AppUi.colors(context).secondary,
            )
            : null,
    onTap: onTap,
  );
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppUi.primary, AppUi.primaryDark],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AKUN MEDIFINDER',
                        style: AppUi.text(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA2F8EB),
                        ),
                      ),
                      Text(
                        'Profil Saya',
                        style: AppUi.text(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Edit profil',
                  onPressed: _edit,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .16),
                  ),
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ContentPanel(
                  child: Row(
                    children: [
                      AccountAvatar(photo: _photo, radius: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _name,
                              style: AppUi.text(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _email,
                              style: AppUi.text(
                                fontSize: 13,
                                color: AppUi.colors(context).secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('Informasi Akun'),
                ContentPanel(
                  padding: 0,
                  child: _tile(
                    Icons.badge_outlined,
                    'Data Diri',
                    'Nama tampilan dan informasi akun',
                    _edit,
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('Tampilan'),
                ContentPanel(
                  padding: 0,
                  child: _tile(
                    Icons.brightness_6_outlined,
                    'Tema Aplikasi',
                    'Terang, gelap, atau ikuti sistem',
                    () => showAppearancePicker(context),
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('Keamanan & Sesi'),
                ContentPanel(
                  padding: 0,
                  child: Column(
                    children: [
                      _tile(
                        Icons.lock_outline_rounded,
                        'Kata Sandi & Akun Terhubung',
                        _google
                            ? 'Terhubung melalui Google'
                            : 'Masuk menggunakan email',
                        () {
                          if (_google) {
                            _info(
                              'Akun Google',
                              'Anda masuk melalui Google. Kelola kata sandi dan keamanan akun melalui pengaturan akun Google Anda.',
                            );
                          } else {
                            showForgotPasswordSheet(
                              context,
                              api: AuthApiService(),
                              email: _email,
                            );
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _tile(
                        Icons.cleaning_services_outlined,
                        'Bersihkan Cache Gambar',
                        'Memuat ulang gambar apotek dan obat',
                        () {
                          PaintingBinding.instance.imageCache.clear();
                          PaintingBinding.instance.imageCache.clearLiveImages();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache gambar telah dibersihkan.'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeading('Bantuan & Informasi'),
                ContentPanel(
                  padding: 0,
                  child: Column(
                    children: [
                      _tile(
                        Icons.help_outline_rounded,
                        'Panduan MediFinder',
                        'Apotek, stok obat, dan MediBot',
                        () => _info(
                          'Panduan MediFinder',
                          'Cari Apotek: telusuri nama atau alamat dan gunakan filter buka.\n\nCari Obat: cari nama obat untuk melihat stok dan harga dari apotek.\n\nMediBot: pilih usia pasien sebelum mengirim keluhan. Informasi AI bersifat edukatif; konsultasikan keputusan medis kepada tenaga kesehatan.\n\nHubungi apotek untuk memastikan ketersediaan sebelum berkunjung.',
                        ),
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _tile(
                        Icons.privacy_tip_outlined,
                        'Privasi Perangkat',
                        'Sesi, lokasi, dan riwayat percakapan',
                        () => _info(
                          'Privasi Perangkat',
                          'Lokasi perangkat digunakan dengan izin untuk mencari apotek terdekat. Pesan MediBot dikirim ke layanan AI melalui backend aplikasi.\n\nSesi login dan riwayat MediBot disimpan di perangkat. Keluar menghapus sesi akun; hapus percakapan melalui tombol mulai ulang di MediBot. Jangan memasukkan data pribadi yang tidak diperlukan.',
                        ),
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _tile(
                        Icons.info_outline_rounded,
                        'MediFinder Mobile',
                        'Versi 1.0.0',
                        () => _info(
                          'MediFinder Mobile',
                          'Temukan informasi obat dan apotek di sekitar Anda.',
                        ),
                        arrow: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => logoutAccount(context),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppUi.colors(context).surface,
                      foregroundColor: AppUi.colors(context).error,
                      side: BorderSide.none,
                      minimumSize: const Size(48, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Keluar dari Akun'),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
