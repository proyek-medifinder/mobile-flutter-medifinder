import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/login.dart';
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

  final List<Widget> _pages = const [
    HomeTab(),
    SearchTab(),
    ObatTab(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F756B),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        toolbarHeight: 78,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MEDIFINDER',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: Colors.black,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
            Text(
              'Temukan apotek dan obat lebih cepat',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFF7F8FA),
        child: AbsorbPointer(
          absorbing: _isLoggingOut,
          child: Column(
            children: [
              DrawerHeader(
                margin: EdgeInsets.zero,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppUi.primary, AppUi.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_hospital, color: Colors.white),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Menu Navigasi',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Akses cepat ke fitur utama Medifinder',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded),
                title: Text('Beranda', style: GoogleFonts.poppins()),
                selected: _currentIndex == 0,
                selectedTileColor: const Color(0xFFE8F5F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.search_rounded),
                title: Text('Cari Apotek', style: GoogleFonts.poppins()),
                selected: _currentIndex == 1,
                selectedTileColor: const Color(0xFFE8F5F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 1);
                },
              ),
              ListTile(
                leading: const Icon(Icons.medication_rounded),
                title: Text('Cari Obat', style: GoogleFonts.poppins()),
                selected: _currentIndex == 2,
                selectedTileColor: const Color(0xFFE8F5F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 2);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text('Profil', style: GoogleFonts.poppins()),
                selected: _currentIndex == 3,
                selectedTileColor: const Color(0xFFE8F5F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
              ),
              const Spacer(),
              const Divider(height: 1),
              SafeArea(
                top: false,
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text('Keluar', style: GoogleFonts.poppins(fontSize: 16)),
                  trailing: _isLoggingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  onTap: _isLoggingOut
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _logout();
                        },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: AbsorbPointer(
              absorbing: _isLoggingOut,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppUi.primary, AppUi.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: IndexedStack(index: _currentIndex, children: _pages),
              ),
            ),
          ),
          if (_isLoggingOut)
            Container(
              color: Colors.black.withOpacity(0.18),
              child: Center(
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                      const CircularProgressIndicator(
                        color: Color(0xFF0F756B),
                      ),
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: AppUi.primary,
        unselectedItemColor: Colors.grey,
        elevation: 18,
        selectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'Cari'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_rounded),
            label: 'Obat',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
