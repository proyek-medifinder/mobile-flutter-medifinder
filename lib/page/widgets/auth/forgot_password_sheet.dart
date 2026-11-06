import 'package:medifinder/theme/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/services/auth_api_service.dart';

Future<void> showForgotPasswordSheet(
  BuildContext context, {
  required AuthApiService api,
  String email = '',
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: AppUi.colors(context).background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => _ForgotPasswordSheet(api: api, email: email),
);

class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.api, required this.email});
  final AuthApiService api;
  final String email;
  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final _email = TextEditingController(text: widget.email);
  final _form = GlobalKey<FormState>();
  bool _busy = false;
  String? _error, _success;
  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final message = await widget.api.requestPasswordReset(_email.text.trim());
      if (mounted) setState(() => _success = message);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_reset_rounded,
                        color: AppUi.colors(context).primaryText,
                        size: 28,
                      ),
                      const Spacer(),
                      IconButton(
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  Text(
                    'Lupa Kata Sandi?',
                    style: AuthDesign.text(23, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan email akun Anda. Kami akan mengirim tautan untuk membuat kata sandi baru.',
                    style: AuthDesign.text(
                      13,
                      color: AppUi.colors(context).secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) AuthNotice(message: _error!, error: true),
                  if (_success != null) ...[
                    AuthNotice(message: _success!),
                    AuthPrimaryButton(
                      label: 'Kembali ke Login',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ] else ...[
                    AbsorbPointer(
                      absorbing: _busy,
                      child: AuthField(
                        label: 'Alamat Email',
                        controller: _email,
                        hint: 'nama@email.com',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _send(),
                        validator: AuthDesign.emailValidator,
                      ),
                    ),
                    const SizedBox(height: 22),
                    AuthPrimaryButton(
                      label: 'Kirim Tautan Reset',
                      loading: _busy,
                      onPressed: _send,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
