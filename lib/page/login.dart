import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medifinder/page/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:medifinder/services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool _isPasswordHidden = true;

  SharedPreferences? prefs;
  Logger logger = Logger(printer: PrettyPrinter());

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    final saved1 = prefs!.getString('username') ?? '';
    final saved2 = prefs!.getString('password') ?? '';

    setState(() {
      username.text = saved1;
      password.text = saved2;
    });

    logger.i("Loaded username: $saved1, password: $saved2");
  }

  Future<void> _saveInfo() async {
    await prefs!.setString('username', username.text);
    await prefs!.setString('password', password.text);

    logger.i("Saved username: ${username.text}, password: ${password.text}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F756B),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Text(
                //   "Sign In",
                //   style: GoogleFonts.poppins(
                //     fontSize: 50,
                //     fontWeight: FontWeight.bold,r
                //     color: Colors.white,
                //   ),
                // ),
                
                      const SizedBox(height: 10),
                // CARD LOGIN
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =========== LOGO DI DALAM CARD ===========
                      // TITLE
                      Container(
                        width: 180,
                        height: 110,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/Logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // USERNAME FIELD
                      TextField(
                        controller: username,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE0E7EF),
                          hintText: "Username",
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PASSWORD FIELD
                      TextField(
                        controller: password,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFE0E7EF),
                          hintText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // LOGIN BUTTON
                      SizedBox(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: () {
                            // login manual
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.yellow[700],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Login",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // GOOGLE LOGIN BUTTON
                      SizedBox(
                        width: 400,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final user = await AuthService().signInWithGoogle();
                            if (user != null) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const Home()),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Colors.black26),
                            ),
                          ),
                          icon: const Icon(
                            Icons.g_mobiledata,
                            color: Colors.red,
                            size: 28,
                          ),
                          label: Text(
                            "Login dengan Google",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
