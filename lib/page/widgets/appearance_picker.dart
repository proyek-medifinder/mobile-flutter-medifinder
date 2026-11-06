import 'package:flutter/material.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/theme/theme_controller.dart';

Future<void> showAppearancePicker(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder:
          (ctx) => ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance,
            builder:
                (context, current, _) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tampilan Aplikasi',
                        style: AppUi.text(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pilih tema yang nyaman untuk Anda.',
                        style: AppUi.text(
                          fontSize: 13,
                          color: AppUi.colors(context).secondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...ThemeMode.values.map(
                        (mode) => RadioListTile<ThemeMode>(
                          value: mode,
                          groupValue: current,
                          secondary: Icon(switch (mode) {
                            ThemeMode.system => Icons.brightness_auto_outlined,
                            ThemeMode.light => Icons.light_mode_outlined,
                            ThemeMode.dark => Icons.dark_mode_outlined,
                          }),
                          title: Text(switch (mode) {
                            ThemeMode.system => 'Ikuti Sistem',
                            ThemeMode.light => 'Terang',
                            ThemeMode.dark => 'Gelap',
                          }),
                          onChanged: (value) async {
                            if (value == null) return;
                            try {
                              await ThemeController.instance.setMode(value);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (_) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Pilihan tema belum dapat disimpan.',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );

class AppearanceButton extends StatelessWidget {
  const AppearanceButton({super.key});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Ubah tema',
    onPressed: () => showAppearancePicker(context),
    icon: Icon(
      Theme.of(context).brightness == Brightness.dark
          ? Icons.dark_mode_outlined
          : Icons.light_mode_outlined,
    ),
  );
}
