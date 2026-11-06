import 'package:medifinder/theme/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/services/auth_session_store.dart';

class Register extends StatefulWidget {
  const Register({super.key, this.api, this.auth});
  final AuthApiService? api;
  final AuthService? auth;
  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _name = TextEditingController(),
      _email = TextEditingController(),
      _password = TextEditingController(),
      _confirm = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final AuthApiService _api = widget.api ?? AuthApiService();
  late final AuthService _auth = widget.auth ?? AuthService(api: _api);
  bool _hidden = true,
      _confirmHidden = true,
      _busy = false,
      _googleBusy = false;
  String? _error;
  bool get _working => _busy || _googleBusy;
  bool get _long => _password.text.length >= 8;
  bool get _upper => RegExp(r'[A-Z]').hasMatch(_password.text);
  bool get _number => RegExp(r'[0-9]').hasMatch(_password.text);
  int get _strength => [_long, _upper, _number].where((value) => value).length;

  @override
  void dispose() {
    for (final controller in [_name, _email, _password, _confirm]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toLogin([String? email]) {
    if (!mounted) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context, email);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (_) => Login(
                initialEmail: email,
                notice:
                    email == null
                        ? null
                        : 'Akun berhasil dibuat. Silakan masuk dengan akun baru Anda.',
              ),
        ),
      );
    }
  }

  Future<void> _register() async {
    if (_working) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _api.register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      _toLogin(_email.text.trim());
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _google() async {
    if (_working) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _googleBusy = true;
      _error = null;
    });
    try {
      final session = await _auth.signInWithGoogle();
      if (session == null) return;
      await AuthSessionStore(api: _api).save(session, provider: 'google');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton.filledTonal(
                tooltip: 'Kembali ke login',
                onPressed: _working ? null : () => _toLogin(),
                style: IconButton.styleFrom(
                  backgroundColor: AppUi.colors(context).softTeal,
                  foregroundColor: AppUi.colors(context).primaryText,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 21),
              ),
            ),
            const Expanded(child: Center(child: MediFinderLogo(width: 220))),
            const SizedBox(width: 44),
          ],
        ),
        const SizedBox(height: 20),
        AuthPanel(
          padding: 20,
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_add_alt_1_rounded,
                        color: AppUi.colors(context).primaryText,
                        size: 23,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Registrasi Pengguna',
                          style: AuthDesign.text(18, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Buat akun untuk mulai menggunakan MediFinder.',
                    style: AuthDesign.text(
                      12,
                      color: AppUi.colors(context).secondary,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (_error != null) AuthNotice(message: _error!, error: true),
                  AbsorbPointer(
                    absorbing: _working,
                    child: Column(
                      children: [
                        AuthField(
                          label: 'Nama Lengkap',
                          controller: _name,
                          hint: 'Contoh: Sarah Safira',
                          icon: Icons.badge_outlined,
                          autofillHints: const [AutofillHints.name],
                          validator:
                              (value) =>
                                  (value?.trim().length ?? 0) < 2
                                      ? 'Masukkan nama lengkap Anda.'
                                      : null,
                        ),
                        const SizedBox(height: 18),
                        AuthField(
                          label: 'Alamat Email',
                          controller: _email,
                          hint: 'nama@email.com',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: AuthDesign.emailValidator,
                        ),
                        const SizedBox(height: 18),
                        AuthField(
                          label: 'Kata Sandi Baru',
                          controller: _password,
                          hint: 'Buat kata sandi',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hidden,
                          autofillHints: const [AutofillHints.newPassword],
                          onChanged: (_) => setState(() {}),
                          validator:
                              (_) =>
                                  _long && _upper && _number
                                      ? null
                                      : 'Gunakan min. 8 karakter, huruf besar, dan angka.',
                          suffix: IconButton(
                            tooltip:
                                _hidden
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                            onPressed: () => setState(() => _hidden = !_hidden),
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 21,
                              color: AppUi.colors(context).secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(
                            3,
                            (index) => Expanded(
                              child: Container(
                                height: 3,
                                margin: EdgeInsets.only(
                                  right: index < 2 ? 5 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _password.text.isEmpty ||
                                              index >= _strength
                                          ? AppUi.colors(context).line
                                          : _strength == 3
                                          ? const Color(0xFF1B8A5A)
                                          : const Color(0xFFFABC2A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                'Min. 8 karakter, huruf besar & angka',
                                style: AuthDesign.text(
                                  10,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                            ),
                            if (_strength == 3)
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: Color(0xFF1B8A5A),
                                size: 16,
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AuthField(
                          label: 'Konfirmasi Kata Sandi',
                          controller: _confirm,
                          hint: 'Ulangi kata sandi',
                          icon: Icons.lock_reset_rounded,
                          obscure: _confirmHidden,
                          action: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => _register(),
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Ulangi kata sandi Anda.'
                                      : value != _password.text
                                      ? 'Konfirmasi kata sandi belum cocok.'
                                      : null,
                          suffix: IconButton(
                            tooltip:
                                _confirmHidden
                                    ? 'Tampilkan konfirmasi kata sandi'
                                    : 'Sembunyikan konfirmasi kata sandi',
                            onPressed:
                                () => setState(
                                  () => _confirmHidden = !_confirmHidden,
                                ),
                            icon: Icon(
                              _confirmHidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 21,
                              color: AppUi.colors(context).secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: 'Daftar Akun Baru',
                    onPressed: _working ? null : _register,
                    loading: _busy,
                  ),
                  const AuthDivider(register: true),
                  AuthGoogleButton(
                    register: true,
                    onPressed: _working ? null : _google,
                    loading: _googleBusy,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppUi.colors(context).softTeal,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Sudah memiliki akun? ',
                style: AuthDesign.text(
                  12,
                  color: AppUi.colors(context).secondary,
                ),
              ),
              TextButton(
                onPressed: _working ? null : () => _toLogin(),
                child: Text(
                  'Masuk ke Akun',
                  style: AuthDesign.text(
                    12,
                    weight: FontWeight.w700,
                    color: AppUi.colors(context).primaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
