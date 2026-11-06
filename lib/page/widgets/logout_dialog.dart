import 'package:flutter/material.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool?> showLogoutConfirmation(
  BuildContext context, {
  String? name,
  String? email,
  String? photo,
}) => showDialog<bool>(
  context: context,
  builder:
      (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppUi.colors(context).errorSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppUi.colors(context).error,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Keluar dari Akun?',
                textAlign: TextAlign.center,
                style: AppUi.text(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Anda perlu masuk kembali untuk mengakses akun. Riwayat MediBot di perangkat ini tetap tersimpan.',
                textAlign: TextAlign.center,
                style: AppUi.text(
                  fontSize: 13,
                  color: AppUi.colors(context).secondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppUi.colors(context).muted,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    AccountAvatar(photo: photo),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name?.isNotEmpty == true
                                ? name!
                                : 'Akun MediFinder',
                            style: AppUi.text(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (email?.isNotEmpty == true)
                            Text(
                              email!,
                              style: AppUi.text(
                                fontSize: 12,
                                color: AppUi.colors(context).secondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 20),
                  label: const Text('Ya, Keluar Akun'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
              ),
            ],
          ),
        ),
      ),
);
Future<void> logoutAccount(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  if (!context.mounted) return;
  final confirmed = await showLogoutConfirmation(
    context,
    name: prefs.getString('full_name'),
    email: prefs.getString('email'),
    photo: prefs.getString('profile_picture'),
  );
  if (confirmed != true || !context.mounted) return;
  await AuthService().signOut();
  if (!context.mounted) return;
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder:
          (_) => const Login(
            notice:
                'Berhasil keluar. Sesi akun di perangkat ini telah dibersihkan.',
          ),
    ),
    (_) => false,
  );
}
