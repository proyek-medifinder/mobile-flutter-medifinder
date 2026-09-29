import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logger/logger.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/register.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final email = TextEditingController();
  final password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Logger logger = Logger();
  final AuthApiService _authApiService = AuthApiService();
  final AuthService _authService = AuthService();

  SharedPreferences? prefs;
  bool _isPasswordHidden = true;
  bool _isSaving = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _initSharedPreferences();
  }

  Future<void> _initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();

    final savedEmail =
        prefs!.getString('email') ?? prefs!.getString('username') ?? '';
    final savedPassword = prefs!.getString('password') ?? '';

    if (!mounted) return;
    setState(() {
      email.text = savedEmail;
      password.text = savedPassword;
    });
  }

  Future<void> _saveSession(
    AuthSession session, {
    required String passwordValue,
    required String provider,
  }) async {
    await prefs!.setString('auth_token', session.token);
    await prefs!.setString('auth_provider', provider);
    await prefs!.setString('password', passwordValue);

    final emailValue = session.email?.trim() ?? email.text.trim();
    if (emailValue.isNotEmpty) {
      await prefs!.setString('email', emailValue);
    }

    final displayName = session.name?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      await prefs!.setString('full_name', displayName);
      await prefs!.setString('username', displayName);
    } else if (emailValue.isNotEmpty) {
      await prefs!.setString('username', emailValue);
    }
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      prefs ??= await SharedPreferences.getInstance();

      final session = await _authApiService.login(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      await _saveSession(
        session,
        passwordValue: password.text.trim(),
        provider: 'password',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } on DioException catch (e, st) {
      logger.e('Gagal login API', error: e, stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_dioErrorMessage(e))));
    } catch (e, st) {
      logger.e('Gagal login', error: e, stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login gagal, silakan coba lagi.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Home()),
        );
      }
    } catch (e, st) {
      logger.e('Gagal login Google', error: e, stackTrace: st);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login Google gagal: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  String _dioErrorMessage(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }

    return 'Login gagal. Periksa email, password, atau koneksi ke server.';
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0F756B), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) {
          return 'Email wajib diisi';
        }
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
          return 'Format email belum valid';
        }
        return null;
      },
      decoration: _fieldDecoration(
        hint: 'Email',
        icon: Icons.email_outlined,
      ),
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: password,
      obscureText: _isPasswordHidden,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Password wajib diisi';
        }
        if (value.trim().length < 4) {
          return 'Password minimal 4 karakter';
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: _fieldDecoration(
        hint: 'Password',
        icon: Icons.lock_outline,
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isBusy = _isSaving || _isGoogleLoading;

    return Scaffold(
      backgroundColor: AppUi.primary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: AbsorbPointer(
              absorbing: isBusy,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 20),
                    child: SizedBox(
                      height: bottomInset == 0 ? constraints.maxHeight : null,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: AutofillGroup(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 30,
                                    vertical: 18,
                                  ),
                                  decoration: AppUi.panelDecoration(radius: 999),
                                  child: Image.asset(
                                    'assets/images/Logo-remove.png',
                                    height: 55,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Selamat Datang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Masuk untuk melanjutkan pencarian obat dan apotek.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 28),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 32,
                                  ),
                                  decoration: AppUi.panelDecoration(radius: 32),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Login akun',
                                            style: GoogleFonts.poppins(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                              color: AppUi.primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Masuk dengan email dan password dari backend, atau lanjut dengan Google.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        _emailField(),
                                        const SizedBox(height: 18),
                                        _passwordField(),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'JWT login akan disimpan di perangkat ini.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.black45,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 56,
                                          child: ElevatedButton(
                                            onPressed: _isSaving ? null : _handleLogin,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppUi.accent,
                                              disabledBackgroundColor:
                                                  AppUi.accent.withValues(alpha: 0.6),
                                              shape: const StadiumBorder(),
                                              elevation: 0,
                                            ),
                                            child: _isSaving
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2.2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<Color>(
                                                        Colors.white,
                                                      ),
                                                    ),
                                                  )
                                                : Text(
                                                    'Login',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 28),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                thickness: 1,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                              ),
                                              child: Text(
                                                'atau',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                thickness: 1,
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 28),
                                        SizedBox(
                                          width: double.infinity,
                                          height: 54,
                                          child: OutlinedButton.icon(
                                            onPressed:
                                                _isGoogleLoading ? null : _handleGoogleLogin,
                                            icon: SvgPicture.asset(
                                              'assets/icons/google_logo.svg',
                                              width: 20,
                                              height: 20,
                                            ),
                                            label: Text(
                                              _isGoogleLoading
                                                  ? 'Menghubungkan Google...'
                                                  : 'Login dengan Google',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              shape: const StadiumBorder(),
                                              side: BorderSide(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Belum punya akun?',
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => const Register(),
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                'Daftar',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w600,
                                                  color: AppUi.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.18),
              child: Center(
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: AppUi.panelDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppUi.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _isGoogleLoading ? 'Masuk dengan Google...' : 'Sedang login...',
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
    );
  }
}
