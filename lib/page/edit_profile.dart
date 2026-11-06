import 'package:flutter/material.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _name = TextEditingController(), _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _photo;
  bool _loading = true, _saving = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name.text =
          p.getString('display_name') ?? p.getString('full_name') ?? '';
      _email.text = p.getString('email') ?? '';
      _photo = p.getString('profile_picture');
      _loading = false;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('display_name', _name.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama tampilan perangkat berhasil disimpan.'),
        ),
      );
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan belum dapat disimpan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Edit Profil',
        style: AppUi.text(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ),
    body:
        _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppUi.colors(context).primaryText,
                            width: 2,
                          ),
                        ),
                        child: AccountAvatar(photo: _photo, radius: 48),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Foto akun',
                        style: AppUi.text(
                          fontWeight: FontWeight.w700,
                          color: AppUi.colors(context).primaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Mengikuti foto dari akun yang terhubung.',
                        textAlign: TextAlign.center,
                        style: AppUi.text(
                          fontSize: 12,
                          color: AppUi.colors(context).secondary,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ContentPanel(
                        child: Form(
                          key: _form,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SectionHeading('Informasi Akun'),
                              AuthField(
                                label: 'Nama Tampilan',
                                controller: _name,
                                hint: 'Nama Anda',
                                icon: Icons.person_outline_rounded,
                                validator:
                                    (v) =>
                                        v == null || v.trim().length < 2
                                            ? 'Masukkan minimal 2 karakter.'
                                            : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Nama tampilan disimpan di perangkat ini.',
                                style: AppUi.text(
                                  fontSize: 11,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Alamat Email',
                                style: AppUi.text(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _email,
                                readOnly: true,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthPrimaryButton(
                        label: 'Simpan Perubahan',
                        onPressed: _save,
                        loading: _saving,
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed:
                            _saving ? null : () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
  );
}
