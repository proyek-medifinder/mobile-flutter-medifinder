import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/widgets/page_intro_card.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = true;
  bool _obscurePassword = true;
  bool _showSavedPassword = false;
  User? googleUser;
  bool isGoogleLogin = false;

  // Selected Section Tab (0: Info/Form, 1: Keamanan & Sesi)
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    googleUser = FirebaseAuth.instance.currentUser;
    isGoogleLogin = googleUser != null;

    if (!isGoogleLogin) {
      _usernameController.text =
          prefs.getString('full_name') ??
          prefs.getString('username') ??
          prefs.getString('email') ??
          '';
      _passwordController.text = prefs.getString('password') ?? '';
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    final String u = _usernameController.text.trim();
    final String p = _passwordController.text;

    if (u.isEmpty || p.isEmpty) {
      _showSnackBar('Username dan Password tidak boleh kosong', isError: true);
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', u);
    await prefs.setString('full_name', u);
    await prefs.setString('password', p);

    if (!mounted) return;
    _showSnackBar('Profil lokal berhasil disimpan!');
  }

  Future<void> _removeCredentials() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Hapus Data Lokal?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Tindakan ini akan menghapus username dan password lokal yang tersimpan di perangkat ini.',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Ya, Hapus',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('full_name');
    await prefs.remove('email');
    await prefs.remove('password');
    await prefs.remove('auth_token');
    await prefs.remove('auth_provider');

    _usernameController.clear();
    _passwordController.clear();

    if (!mounted) return;
    _showSnackBar('Username & Password lokal berhasil dihapus');
    setState(() {});
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Keluar dari Aplikasi',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            content: Text(
              'Apakah kamu yakin ingin keluar dari akun ini?',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Batal',
                  style: GoogleFonts.poppins(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Keluar',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Sign out Firebase
    if (isGoogleLogin) {
      await FirebaseAuth.instance.signOut();
    }

    // Clear saved local auth state
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_provider');

    if (!mounted) return;
    _showSnackBar('Berhasil keluar dari akun');

    // Arahkan ke halaman login jika rute tersedia (misal '/login')
    // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF0A5A52),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Hero Card dengan Tombol Logout
          _buildProfileHeroHeader(),
          const SizedBox(height: 20),

          // 2. Tab Segment Selector
          _buildTabSegmentSelector(),
          const SizedBox(height: 18),

          // 3. Dynamic Section Panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child:
                _activeTab == 0
                    ? _buildAccountDetailsPanel()
                    : _buildSecurityPanel(),
          ),
        ],
      ),
    );
  }

  // --- WIDGET COMPONENTS ---

  Widget _buildProfileHeroHeader() {
    final displayName =
        isGoogleLogin
            ? (googleUser?.displayName ?? 'Pengguna Google')
            : _usernameController.text.ifEmpty('Pengguna Medifinder');

    final emailOrStatus =
        isGoogleLogin
            ? (googleUser?.email ?? 'Akun Terverifikasi')
            : 'Akun Lokal Aktif';

    return PageIntroCard(
      title: 'Profil Pengguna',
      subtitle:
          isGoogleLogin
              ? 'Terhubung dengan Google. Data profil tersinkronisasi secara otomatis.'
              : 'Kelola data kredensial dan preferensi akun lokal Medifinder kamu.',
      icon: Icons.person_rounded,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppUi.glassDecoration(radius: 20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  backgroundImage:
                      isGoogleLogin && googleUser?.photoURL != null
                          ? NetworkImage(googleUser!.photoURL!)
                          : null,
                  child:
                      (!isGoogleLogin || googleUser?.photoURL == null)
                          ? const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 34,
                          )
                          : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color:
                          isGoogleLogin
                              ? const Color(0xFF4285F4)
                              : const Color(0xFF10B981),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(
                      isGoogleLogin
                          ? Icons.g_mobiledata_rounded
                          : Icons.lock_outline_rounded,
                      size: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emailOrStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tombol Logout Cepat di Header
            IconButton(
              onPressed: _handleLogout,
              tooltip: 'Keluar Akun',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSegmentSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segmentButton(
              title: 'Informasi Akun',
              icon: Icons.badge_outlined,
              isActive: _activeTab == 0,
              onTap: () => setState(() => _activeTab = 0),
            ),
          ),
          Expanded(
            child: _segmentButton(
              title: 'Keamanan & Sesi',
              icon: Icons.shield_outlined,
              isActive: _activeTab == 1,
              onTap: () => setState(() => _activeTab = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow:
              isActive
                  ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppUi.primary : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppUi.primary : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountDetailsPanel() {
    return Container(
      key: const ValueKey(0),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppUi.panelDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isGoogleLogin ? 'Detail Akun Google' : 'Ubah Data Akun',
            style: AppUi.sectionTitleStyle(),
          ),
          const SizedBox(height: 6),
          Text(
            isGoogleLogin
                ? 'Informasi ini tertaut langsung dengan profil Google Anda.'
                : 'Perbarui username dan password lokal secara berkala.',
            style: AppUi.sectionSubtitleStyle(),
          ),
          const SizedBox(height: 20),
          if (isGoogleLogin) ...[
            _infoTile(
              Icons.person_outline_rounded,
              'Nama Lengkap',
              googleUser?.displayName ?? 'Belum Diatur',
            ),
            const SizedBox(height: 12),
            _infoTile(
              Icons.email_outlined,
              'Alamat Email',
              googleUser?.email ?? '-',
            ),
            const SizedBox(height: 12),
            _infoTile(
              Icons.verified_user_outlined,
              'Tipe Pengautentikasi',
              'Google OAuth 2.0',
            ),
          ] else ...[
            _inputLabel('Username'),
            const SizedBox(height: 6),
            TextField(
              controller: _usernameController,
              decoration: _inputDecoration(
                'Masukkan username baru',
                icon: Icons.alternate_email_rounded,
              ),
            ),
            const SizedBox(height: 16),
            _inputLabel('Password'),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword, // PASSWORD TERSEMBUNYI BY DEFAULT
              decoration: _inputDecoration(
                'Masukkan password baru',
                icon: Icons.key_rounded,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.black54,
                  ),
                  onPressed:
                      () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  'Simpan Perubahan',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppUi.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSecurityPanel() {
    final String hiddenPassword =
        _passwordController.text.isEmpty
            ? 'Belum Diatur'
            : (_showSavedPassword ? _passwordController.text : '••••••••');

    return Container(
      key: const ValueKey(1),
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: AppUi.panelDecoration(radius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keamanan & Sesi', style: AppUi.sectionTitleStyle()),
          const SizedBox(height: 6),
          Text(
            'Kelola kredensial tersimpan dan status sesi akun Anda.',
            style: AppUi.sectionSubtitleStyle(),
          ),
          const SizedBox(height: 20),
          if (!isGoogleLogin) ...[
            _infoTileWithAction(
              icon: Icons.lock_outline_rounded,
              label: 'Password Tersimpan',
              value: hiddenPassword,
              actionIcon:
                  _showSavedPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
              onActionTap:
                  () =>
                      setState(() => _showSavedPassword = !_showSavedPassword),
            ),
            const SizedBox(height: 12),
          ],
          _actionCardTile(
            icon: Icons.cleaning_services_rounded,
            title: 'Hapus Kredensial Lokal',
            subtitle: 'Bersihkan username dan password tersimpan di memori.',
            color: Colors.orange.shade800,
            onTap: _removeCredentials,
          ),
          const SizedBox(height: 12),
          _actionCardTile(
            icon: Icons.logout_rounded,
            title: 'Keluar / Logout Akun',
            subtitle: 'Selesaikan sesi dan keluar dari aplikasi Medifinder.',
            color: Colors.redAccent,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _actionCardTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppUi.mutedSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black38,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint, {
    IconData? icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon:
          icon != null ? Icon(icon, size: 20, color: Colors.black45) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppUi.mutedSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppUi.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppUi.mutedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppUi.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTileWithAction({
    required IconData icon,
    required String label,
    required String value,
    required IconData actionIcon,
    required VoidCallback onActionTap,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppUi.mutedSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppUi.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onActionTap,
            icon: Icon(actionIcon, color: Colors.black54, size: 20),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
