import 'package:flutter/material.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'services/socket_notification_service.dart';
import 'services/notification_service.dart';
import 'package:medifinder/services/notification_permission_service.dart';

import 'package:google_fonts/google_fonts.dart';

final SocketNotificationService socketNotificationService =
    SocketNotificationService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationPermissionService.requestWithoutContext();
  await NotificationService.init();
  socketNotificationService.connect();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString('username');
  String? password = prefs.getString('password');
  bool hasAllData = username != null && password != null;

  final bool sudahLoginGoogle = FirebaseAuth.instance.currentUser != null;

  runApp(
    ProviderScope(
      child: MyApp(langsungKeHasil: hasAllData || sudahLoginGoogle),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool langsungKeHasil;

  const MyApp({super.key, required this.langsungKeHasil});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,


      theme: ThemeData(
        useMaterial3: true,

        textTheme: GoogleFonts.poppinsTextTheme(),

        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(textStyle: GoogleFonts.poppins()),
        ),
      ),

      home: langsungKeHasil ? const Home() : const Login(),
    );
  }
}
