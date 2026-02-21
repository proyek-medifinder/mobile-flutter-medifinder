import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/obat.dart';
import 'package:medifinder/page/search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medifinder/services/auth_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = true;
  bool _obscurePassword = true;
  int currentIndex = 3;

  User? googleUser; // <-- user Google
  bool isGoogleLogin = false;

  @override
  void initState() {
    super.initState();
    _loadProfileInfo();
  }

  Future<void> _loadProfileInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Cek apakah login via Google
    googleUser = FirebaseAuth.instance.currentUser;
    isGoogleLogin = googleUser != null;

    if (!isGoogleLogin) {
      // Login manual
      _usernameController.text = prefs.getString('username') ?? '';
      _passwordController.text = prefs.getString('password') ?? '';
    }

    setState(() => isLoading = false);
  }

  Future<void> _saveProfile() async {
    final String u = _usernameController.text.trim();
    final String p = _passwordController.text;

    if (u.isEmpty || p.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username dan Password tidak boleh kosong'),
        ),
      );
      return;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', u);
    await prefs.setString('password', p);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));
  }

  Future<void> _removeCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');

    _usernameController.clear();
    _passwordController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Username & Password dihapus')),
    );

    setState(() {});
  }

  Future<void> logoutAndGotoLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Jika login via Google → logout Firebase
    if (googleUser != null) {
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
                await logoutAndGotoLogin();
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
          setState(() => currentIndex = index);

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
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Search()),
            );
          }
        },
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

      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      'Profil Pengguna',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ---------------------------
                    //     PROFILE CARD
                    // ---------------------------
                    Container(
                      width: 400,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Foto profil
                          CircleAvatar(
                            radius: 45,
                            backgroundImage:
                                isGoogleLogin && googleUser?.photoURL != null
                                    ? NetworkImage(googleUser!.photoURL!)
                                    : null,
                            child:
                                (!isGoogleLogin || googleUser?.photoURL == null)
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFF0F756B),
                                    )
                                    : null,
                          ),

                          const SizedBox(height: 20),

                          // --- GOOGLE LOGIN MODE ---
                          if (isGoogleLogin) ...[
                            Text(
                              googleUser?.displayName ?? "No Name",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              googleUser?.email ?? "",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),

                            const SizedBox(height: 20),
                            const Text(
                              "Login menggunakan Google",
                              style: TextStyle(color: Colors.black54),
                            ),

                            const SizedBox(height: 10),
                          ],

                          // --- MANUAL LOGIN MODE ---
                          if (!isGoogleLogin) ...[
                            // Username
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Username',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Masukkan username',
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Password
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Password',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Masukkan password',
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Buttons (save + delete)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _saveProfile,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0F756B),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Simpan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _removeCredentials,
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                    child: Text(
                                      'Hapus',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
