import 'package:medifinder/theme/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/register.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/page/widgets/auth/forgot_password_sheet.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/services/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key, this.initialEmail, this.notice, this.api, this.auth});
  final String? initialEmail, notice;
  final AuthApiService? api;
  final AuthService? auth;
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  late final AuthApiService _api = widget.api ?? AuthApiService();
  late final AuthService _auth = widget.auth ?? AuthService(api: _api);
  bool _hidden = true, _remember = true, _busy = false, _googleBusy = false;
  String? _error, _notice;
  bool get _working => _busy || _googleBusy;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail ?? '';
    _notice = widget.notice;
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_email.text.isEmpty) _email.text = prefs.getString('email') ?? '';
      _remember = prefs.getBool('remember_session') ?? true;
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _finish(AuthSession session, String provider) async {
    await AuthSessionStore(
      api: _api,
    ).save(session, provider: provider, rememberSession: _remember);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Home()),
      (_) => false,
    );
  }

  Future<void> _login() async {
    if (_working) return;
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _notice = null;
    });
    try {
      final session = await _api.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      final profile = await _api.getProfile(session.token);
      await _finish(session.withProfile(profile), 'password');
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
      _notice = null;
    });
    try {
      final session = await _auth.signInWithGoogle();
      if (session != null) await _finish(session, 'google');
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  Future<void> _register() async {
    if (_working) return;
    final registered = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => Register(api: _api, auth: _auth)),
    );
    if (!mounted || registered == null) return;
    setState(() {
      _email.text = registered;
      _password.clear();
      _error = null;
      _notice = 'Akun berhasil dibuat. Silakan masuk dengan akun baru Anda.';
    });
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    child: Column(
      children: [
        if (_notice != null)
          AuthNotice(
            message: _notice!,
            onClose: () => setState(() => _notice = null),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 26),
          child: AuthBrand(),
        ),
        AuthPanel(
          child: AutofillGroup(
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang Kembali',
                    style: AuthDesign.text(
                      21,
                      weight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk untuk menemukan apotek dan mengakses MediBot.',
                    style: AuthDesign.text(
                      13,
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
                          label: 'Kata Sandi',
                          controller: _password,
                          hint: 'Masukkan kata sandi',
                          icon: Icons.lock_outline_rounded,
                          obscure: _hidden,
                          action: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          validator:
                              (value) =>
                                  value == null || value.isEmpty
                                      ? 'Kata sandi wajib diisi.'
                                      : null,
                          onSubmitted: (_) => _login(),
                          suffix: IconButton(
                            tooltip:
                                _hidden
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                            icon: Icon(
                              _hidden
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 21,
                              color: AppUi.colors(context).secondary,
                            ),
                            onPressed: () => setState(() => _hidden = !_hidden),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 44,
                            child: Checkbox(
                              value: _remember,
                              activeColor: AuthDesign.primary,
                              checkColor: Colors.white,
                              onChanged:
                                  _working
                                      ? null
                                      : (value) => setState(
                                        () => _remember = value ?? true,
                                      ),
                            ),
                          ),
                          InkWell(
                            onTap:
                                _working
                                    ? null
                                    : () =>
                                        setState(() => _remember = !_remember),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 12,
                              ),
                              child: Text(
                                'Ingat Saya',
                                style: AuthDesign.text(
                                  12,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed:
                            _working
                                ? null
                                : () => showForgotPasswordSheet(
                                  context,
                                  api: _api,
                                  email: _email.text,
                                ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                        ),
                        child: Text(
                          'Lupa Kata Sandi?',
                          style: AuthDesign.text(
                            11,
                            weight: FontWeight.w600,
                            color: AppUi.colors(context).primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AuthPrimaryButton(
                    label: 'Masuk ke Akun',
                    onPressed: _working ? null : _login,
                    loading: _busy,
                  ),
                  const AuthDivider(),
                  AuthGoogleButton(
                    onPressed: _working ? null : _google,
                    loading: _googleBusy,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Belum punya akun? ',
              style: AuthDesign.text(
                13,
                color: AppUi.colors(context).secondary,
              ),
            ),
            TextButton(
              onPressed: _working ? null : _register,
              child: Text(
                'Daftar Sekarang',
                style: AuthDesign.text(
                  14,
                  weight: FontWeight.w700,
                  color: AppUi.colors(context).primaryText,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
