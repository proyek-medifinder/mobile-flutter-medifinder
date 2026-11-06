import 'package:flutter/material.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/home.dart';
import 'package:medifinder/page/onboarding.dart';
import 'package:medifinder/services/onboarding_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:medifinder/services/auth_session_store.dart';

import 'services/socket_notification_service.dart';
import 'services/notification_service.dart';

import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/theme/theme_controller.dart';

final SocketNotificationService socketNotificationService =
    SocketNotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeController.instance.load();
  await NotificationService.init();
  socketNotificationService.connect();

  final hasBackendSession = await AuthSessionStore().restore();
  if (hasBackendSession) await OnboardingStore.complete();
  final showOnboarding =
      !hasBackendSession && !await OnboardingStore.hasCompleted();

  runApp(
    ProviderScope(
      child: MyApp(
        langsungKeHasil: hasBackendSession,
        showOnboarding: showOnboarding,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool langsungKeHasil;
  final bool showOnboarding;

  const MyApp({
    super.key,
    required this.langsungKeHasil,
    this.showOnboarding = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder:
          (context, mode, _) => MaterialApp(
            debugShowCheckedModeBanner: false,

            theme: AppUi.theme,
            darkTheme: AppUi.darkTheme,
            themeMode: mode,

            home:
                langsungKeHasil
                    ? const Home()
                    : showOnboarding
                    ? const Onboarding()
                    : const Login(),
          ),
    );
  }
}
