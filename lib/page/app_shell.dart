import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/tabs/chatbot_tab.dart';
import 'package:medifinder/page/tabs/home_tab.dart';
import 'package:medifinder/page/tabs/obat_tab.dart';
import 'package:medifinder/page/tabs/profile_tab.dart';
import 'package:medifinder/page/tabs/search_tab.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 0});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  bool _isLoggingOut = false;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      HomeTab(
        onNavigateTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      const SearchTab(),
      const ChatbotTab(),
      ObatTab(
        onNavigateTab: (index) {
          setState(() => _currentIndex = index);
        },
      ),
      const ProfileTab(),
    ];
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      if (FirebaseAuth.instance.currentUser != null) {
        await AuthService().signOut();
      }

      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('full_name');
      await prefs.remove('password');
      await prefs.remove('auth_token');
      await prefs.remove('auth_provider');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Konfirmasi Keluar',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: Colors.grey[700], fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text(
              'Ya, Keluar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        toolbarHeight: 68,
        centerTitle: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(Icons.notes_rounded, color: Color(0xFF0F756B), size: 20),
            ),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Image.asset(
          'assets/images/Logo-remove.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() => _currentIndex = 2); // Quick jump to MediBot
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE6F5F2), Color(0xFFD1FAE5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF0F756B),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),

      // ================= DRAWER / SIDEBAR (UPGRADED) =================
      drawer: Drawer(
        backgroundColor: const Color(0xFFF9FAFB),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        child: AbsorbPointer(
          absorbing: _isLoggingOut,
          child: Column(
            children: [
              // 1. HEADER DRAWER (MODERN GRADIENT + BADGE)
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  MediaQuery.of(context).padding.top + 20,
                  24,
                  24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F756B), Color(0xFF0A5A52)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x220F756B),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/Logo-remove.png',
                            height: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'AI Online',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MediFinder App',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Asisten Apotek & Konsultasi Obat Digital',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. DAFTAR MENU ITEM
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Text(
                        'NAVIGASI UTAMA',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF9CA3AF),
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),

                    _buildDrawerItem(
                      index: 0,
                      icon: Icons.home_rounded,
                      label: 'Beranda',
                      description: 'Halaman utama & fitur unggulan',
                    ),

                    _buildDrawerItem(
                      index: 1,
                      icon: Icons.search_rounded,
                      label: 'Cari Apotek',
                      description: 'Cari lokasi apotek terdekat',
                    ),

                    _buildDrawerItem(
                      index: 2,
                      icon: Icons.smart_toy_rounded,
                      label: 'MediBot AI',
                      description: 'Konsultasi keluhan kesehatan',
                      isAi: true,
                    ),

                    _buildDrawerItem(
                      index: 3,
                      icon: Icons.medication_rounded,
                      label: 'Cari Obat',
                      description: 'Cek ketersediaan stok & harga',
                    ),

                    _buildDrawerItem(
                      index: 4,
                      icon: Icons.person_rounded,
                      label: 'Profil Saya',
                      description: 'Pengaturan akun & riwayat',
                    ),
                  ],
                ),
              ),

              // 3. FOOTER LOGOUT & VERSION
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Column(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _isLoggingOut ? null : _showLogoutConfirmation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFEE2E2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Keluar Akun',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                  Text(
                                    'Akhiri sesi aplikasi',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isLoggingOut)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFDC2626),
                                ),
                              )
                            else
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 12,
                                color: Color(0xFFEF4444),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'MediFinder Mobile v1.2.0 • Proyek Kampus',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // ================= BODY =================
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: AbsorbPointer(
              absorbing: _isLoggingOut,
              child: Container(
                decoration: BoxDecoration(
                  gradient: _currentIndex == 2
                      ? null
                      : const LinearGradient(
                          colors: [AppUi.primary, AppUi.primaryDark],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                  color: _currentIndex == 2 ? Colors.grey[50] : null,
                ),
                child: IndexedStack(index: _currentIndex, children: _pages),
              ),
            ),
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: Center(
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF0F756B)),
                      const SizedBox(height: 14),
                      Text(
                        'Sedang logout...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),

      // ================= BOTTOM NAVIGATION (QRIS-STYLE MENONJOL) =================
      bottomNavigationBar: _buildQrisStyleBottomNav(),
    );
  }

  // WIDGET DRAWER MENU ITEM DENGAN WARNA EMERALD (BEBAS UNGU)
  Widget _buildDrawerItem({
    required int index,
    required IconData icon,
    required String label,
    required String description,
    bool isAi = false,
  }) {
    final isSelected = _currentIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE6F5F2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF0F756B).withValues(alpha: 0.22) : Colors.transparent,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pop(context);
            setState(() => _currentIndex = index);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F756B) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? const Color(0xFF0F756B) : const Color(0xFF374151),
                            ),
                          ),
                          if (isAi) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF0F756B)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'AI',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          color: isSelected
                              ? const Color(0xFF0F756B).withValues(alpha: 0.75)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F756B),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET BOTTOM NAV DENGAN TOMBOL CHATBOT PROTRUDING / MENONJOL KE ATAS SEPERTI QRIS M-BANKING
  Widget _buildQrisStyleBottomNav() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const double barHeight = 64.0;

    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // 1. DOCK / NAV BAR CONTAINER (EDGE-TO-EDGE FULL WIDTH SOLID WHITE)
          Container(
            height: barHeight + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                // SISI KIRI (Beranda & Cari)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(0, Icons.home_rounded, 'Beranda'),
                      _buildNavItem(1, Icons.search_rounded, 'Cari Apotek'),
                    ],
                  ),
                ),

                // RUANG KOSONG DI TENGAH KHUSUS TOMBOL QRIS-STYLE
                const SizedBox(width: 72),

                // SISI KANAN (Obat & Profil)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNavItem(3, Icons.medication_rounded, 'Cari Obat'),
                      _buildNavItem(4, Icons.person_rounded, 'Profil'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. CIRCULAR WHITE CRADLE (M-BANKING CREST) BEHIND THE FLOATING BUTTON
          Positioned(
            top: -16,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
            ),
          ),

          // 3. WHITE MASK TO FLUSH CRADLE INTO THE DOCK
          Positioned(
            top: 0,
            child: Container(
              width: 70,
              height: 24,
              color: Colors.white,
            ),
          ),

          // 4. TOMBOL CHATBOT MENONJOL KE ATAS (QRIS M-BANKING STYLE)
          Positioned(
            top: -12,
            child: GestureDetector(
              onTap: () {
                setState(() => _currentIndex = 2);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _currentIndex == 2
                            ? const [Color(0xFF10B981), Color(0xFF0F756B)]
                            : const [Color(0xFF14B8A6), Color(0xFF0F756B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F756B).withValues(
                            alpha: _currentIndex == 2 ? 0.40 : 0.25,
                          ),
                          blurRadius: _currentIndex == 2 ? 14 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(
                          Icons.smart_toy_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                        if (_currentIndex == 2)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'MediBot AI',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: _currentIndex == 2 ? FontWeight.w800 : FontWeight.w600,
                      color: _currentIndex == 2 ? const Color(0xFF0F756B) : const Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET ITEM NAVIGASI BIASA
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0F756B) : const Color(0xFF9CA3AF),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F756B) : const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F756B) : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
