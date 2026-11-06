import 'package:medifinder/page/widgets/appearance_picker.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Tokens from the supplied Clinical Clarity / Stitch authentication designs.
class AuthDesign {
  static const primary = Color(0xFF0F756B);
  static const dark = Color(0xFF0A5A52);
  static const background = Color(0xFFF7FBF9);
  static const muted = Color(0xFFF2F4F6);
  static const ink = Color(0xFF191C1E);
  static const secondary = Color(0xFF596562);
  static const line = Color(0xFFE5E7EB);
  static const error = Color(0xFFBA1A1A);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.5,
  }) => TextStyle(
    fontFamily: 'PlusJakartaSans',
    fontSize: size,
    fontWeight: weight,
    height: height,
    color: color,
  );

  static String? emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Alamat email wajib diisi.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Masukkan alamat email yang valid.';
    }
    return null;
  }

  static InputDecoration input(
    BuildContext context,
    String hint,
    IconData icon, {
    Widget? suffix,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: text(14, color: AppUi.colors(context).secondary),
    prefixIcon: Icon(icon, size: 21, color: AppUi.colors(context).secondary),
    suffixIcon: suffix,
    filled: true,
    fillColor: AppUi.colors(context).muted,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(
        color: AppUi.colors(context).primaryText,
        width: 1.6,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppUi.colors(context).error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppUi.colors(context).error, width: 1.6),
    ),
    errorStyle: text(11, color: AppUi.colors(context).error),
    errorMaxLines: 2,
  );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(
        context,
      ).textTheme.apply(fontFamily: 'PlusJakartaSans'),
      colorScheme: Theme.of(context).colorScheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppUi.colors(context).primaryText,
      ),
    ),
    child: Scaffold(
      backgroundColor: AppUi.colors(context).background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: child,
                ),
              ),
            ),
            const Positioned(top: 0, right: 4, child: AppearanceButton()),
          ],
        ),
      ),
    ),
  );
}

class AuthPanel extends StatelessWidget {
  const AuthPanel({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: AppUi.colors(context).surface,
      borderRadius: BorderRadius.circular(26),
      boxShadow: const [
        BoxShadow(
          color: Color(0x100A5A52),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

/// The original logo shared with the home navbar.
class MediFinderLogo extends StatelessWidget {
  const MediFinderLogo({super.key, this.width = 240});
  final double width;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/Logo-remove.png',
    width: width,
    fit: BoxFit.contain,
    semanticLabel: 'MediFinder',
  );
}

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const MediFinderLogo(width: 280),
      const SizedBox(height: 12),
      Text(
        'Temukan apotek dan informasi obat\ndi sekitar Anda.',
        textAlign: TextAlign.center,
        style: AuthDesign.text(12, color: AppUi.colors(context).secondary),
      ),
    ],
  );
}

class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.suffix,
    this.obscure = false,
    this.keyboardType,
    this.action = TextInputAction.next,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
  });
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final String? Function(String?)? validator;
  final Widget? suffix;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction action;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged, onSubmitted;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AuthDesign.text(
          12,
          weight: FontWeight.w600,
          color: AppUi.colors(context).secondary,
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        textInputAction: action,
        autofillHints: autofillHints,
        validator: validator,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        style: AuthDesign.text(14),
        autocorrect: false,
        enableSuggestions: !obscure,
        decoration: AuthDesign.input(context, hint, icon, suffix: suffix),
      ),
    ],
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.pill = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading, pill;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AuthDesign.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AuthDesign.primary.withValues(alpha: .6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(pill ? 99 : 16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        textStyle: AuthDesign.text(15, weight: FontWeight.w700),
      ),
      child:
          loading
              ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text(label)),
                  const SizedBox(width: 10),
                  const Icon(Icons.arrow_forward_rounded, size: 21),
                ],
              ),
    ),
  );
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.register = false,
  });
  final VoidCallback? onPressed;
  final bool loading, register;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: TextButton(
      onPressed: loading ? null : onPressed,
      style: TextButton.styleFrom(
        backgroundColor: AppUi.colors(context).muted,
        foregroundColor: AppUi.colors(context).ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child:
          loading
              ? const SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/icons/google_logo.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      register
                          ? 'Daftar cepat dengan Google'
                          : 'Lanjutkan dengan Google',
                      style: AuthDesign.text(13, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
    ),
  );
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.register = false});
  final bool register;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Row(
      children: [
        Expanded(child: Divider(color: AppUi.colors(context).line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            register ? 'ATAU DAFTAR DENGAN' : 'ATAU MASUK DENGAN',
            style: AuthDesign.text(
              9,
              weight: FontWeight.w600,
              color: AppUi.colors(context).secondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppUi.colors(context).line)),
      ],
    ),
  );
}

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    this.error = false,
    this.onClose,
  });
  final String message;
  final bool error;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color:
            error
                ? AppUi.colors(context).errorSurface
                : AppUi.colors(context).surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              error ? AppUi.colors(context).error : AppUi.colors(context).line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color:
                error
                    ? AppUi.colors(context).error
                    : AppUi.colors(context).primaryText,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AuthDesign.text(
                12,
                color:
                    error
                        ? AppUi.colors(context).error
                        : AppUi.colors(context).ink,
              ),
            ),
          ),
          if (onClose != null)
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Tutup pemberitahuan',
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppUi.colors(context).secondary,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

String friendlyAuthError(Object error) {
  // API errors are handled by the screens; never print credentials or raw tokens.
  if (error is FormatException) return error.message.toString();
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) return message;
    }
    if (error.response?.statusCode == 429) {
      return 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.';
    }
  }
  return 'Belum bisa terhubung. Periksa koneksi, lalu coba lagi.';
}
