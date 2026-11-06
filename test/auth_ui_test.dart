import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/register.dart';
import 'package:medifinder/page/onboarding.dart';
import 'package:medifinder/services/onboarding_store.dart';
import 'package:medifinder/services/auth_session_store.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service_test.dart' show apiWith, response, jwt;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final fontLoader = FontLoader('PlusJakartaSans');
    for (final weight in [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      fontLoader.addFont(
        rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'),
      );
    }
    await fontLoader.load();
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  Future<void> show(
    WidgetTester tester,
    Widget screen, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        builder:
            (context, child) => MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(scale),
              ),
              child: RepaintBoundary(
                key: const ValueKey('preview'),
                child: child!,
              ),
            ),
        home: screen,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    const dir = String.fromEnvironment('UI_PREVIEW_DIR');
    if (dir.isEmpty) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      final picture = await boundary.toImage(pixelRatio: 2);
      final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
      await Directory(dir).create(recursive: true);
      await File('$dir/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      picture.dispose();
    });
  }

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'onboarding has three steps; completing opens registration and persists',
    (tester) async {
      await show(tester, const Onboarding());
      await capture(tester, 'onboarding-apotek');
      expect(find.text('Temukan Apotek Terdekat'), findsOneWidget);
      await tap(tester, 'Lanjutkan');
      expect(find.text('Cek Ketersediaan Obat'), findsOneWidget);
      await capture(tester, 'onboarding-obat');
      await tap(tester, 'Lanjutkan');
      expect(find.text('Konsultasi Cerdas MediBot'), findsOneWidget);
      await capture(tester, 'onboarding-medibot');
      await tap(tester, 'Mulai Sekarang');
      expect(find.byType(Register), findsOneWidget);
      expect(await OnboardingStore.hasCompleted(), isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('skip opens login and does not return to onboarding', (
    tester,
  ) async {
    await show(tester, const Onboarding());
    await tap(tester, 'Lewati');
    expect(find.byType(Login), findsOneWidget);
    expect(await OnboardingStore.hasCompleted(), isTrue);
    expect(Navigator.of(tester.element(find.byType(Login))).canPop(), isFalse);
  });
  testWidgets('login validates empty fields and toggles password visibility', (
    tester,
  ) async {
    await show(tester, const Login());
    await capture(tester, 'login');
    expect(find.textContaining('Berhasil keluar'), findsNothing);
    await tap(tester, 'Masuk ke Akun');
    expect(find.text('Alamat email wajib diisi.'), findsOneWidget);
    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();
    final password = tester.widget<TextFormField>(
      find.byType(TextFormField).last,
    );
    expect(password, isNotNull);
    expect(find.byTooltip('Sembunyikan kata sandi'), findsOneWidget);
  });
  testWidgets('register submits real fields and returns email to login', (
    tester,
  ) async {
    final calls = <String>[];
    final api = apiWith((request) {
      calls.add(request.path);
      expect(request.data, {
        'name': 'Nama Uji',
        'email': 'user@example.invalid',
        'password': 'Password123',
      });
      return response({'message': 'registered'}, 201);
    });
    await show(tester, Login(api: api));
    await tap(tester, 'Daftar Sekarang');
    await capture(tester, 'register');
    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Nama Uji');
    await tester.enterText(fields.at(1), 'user@example.invalid');
    await tester.enterText(fields.at(2), 'weak');
    await tester.enterText(fields.at(3), 'different');
    await tap(tester, 'Daftar Akun Baru');
    expect(calls, isEmpty);
    await tester.enterText(fields.at(2), 'Password123');
    await tester.enterText(fields.at(3), 'Password123');
    await tap(tester, 'Daftar Akun Baru');
    expect(calls, ['/register']);
    expect(find.byType(Login), findsOneWidget);
    expect(find.textContaining('Akun berhasil dibuat'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'user@example.invalid',
    );
  });
  testWidgets('forgot password sends email to backend without real mail', (
    tester,
  ) async {
    final api = apiWith((request) {
      expect(request.path, '/forgot-password');
      expect(request.data, {'email': 'user@example.invalid'});
      return response({
        'message': 'Jika email terdaftar, tautan akan dikirim.',
      });
    });
    await show(tester, Login(api: api, initialEmail: 'user@example.invalid'));
    await tap(tester, 'Lupa Kata Sandi?');
    await tap(tester, 'Kirim Tautan Reset');
    expect(
      find.text('Jika email terdaftar, tautan akan dikirim.'),
      findsOneWidget,
    );
    await tap(tester, 'Kembali ke Login');
    expect(find.text('Kirim Tautan Reset'), findsNothing);
  });
  testWidgets('small screens and enlarged text can scroll without overflow', (
    tester,
  ) async {
    for (final screen in [
      const Login(),
      const Register(),
      const Onboarding(),
    ]) {
      await show(tester, screen, size: const Size(320, 568), scale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
  test(
    'non remembered session is cleared on next startup, onboarding stays completed',
    () async {
      await OnboardingStore.complete();
      final store = AuthSessionStore(
        api: apiWith((_) => throw StateError('must not request profile')),
      );
      await store.save(
        AuthSession(token: jwt(DateTime.now().add(const Duration(hours: 1)))),
        provider: 'password',
        rememberSession: false,
      );
      expect(await store.restore(), isFalse);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
      expect(await OnboardingStore.hasCompleted(), isTrue);
    },
  );
}
