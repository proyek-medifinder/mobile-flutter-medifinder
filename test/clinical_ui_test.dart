import 'package:medifinder/services/auth_session_store.dart';
import 'package:medifinder/theme/theme_controller.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/register.dart';
import 'package:medifinder/page/onboarding.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medifinder/page/app_shell.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/page/edit_profile.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/services/api_client.dart';
import 'package:medifinder/services/chatbot_service.dart';
import 'package:medifinder/services/location_service.dart';
import 'package:medifinder/services/medicine_catalog.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

final pharmacy = ApotekViewData.fromMap({
  'id': 'pharmacy-test',
  'nama': 'Apotek Sehat Bersama',
  'alamat': 'Jl. Merdeka No. 12, Indramayu',
  'status_buka': 'buka',
  'jam_buka': '00:00',
  'jam_tutup': '23:59',
  'distance': .8,
  'phone_number': '0211234567',
  'latitude': -6.4,
  'longitude': 108.2,
  'obats': [
    {
      'nama': 'Vitamin C',
      'stok': 12,
      'harga': 8500,
      'deskripsi': 'Suplemen vitamin C.',
    },
    {
      'nama': 'Antiseptik',
      'stok': 0,
      'harga': 18000,
      'deskripsi': 'Informasi produk dari apotek.',
    },
  ],
});
final closed = ApotekViewData.fromMap({
  'id': 'closed-test',
  'nama': 'Apotek Sentosa',
  'alamat': 'Jl. Mawar, Indramayu',
  'status_buka': 'tutup',
  'jam_buka': '08:00',
  'jam_tutup': '20:00',
  'distance': 1.4,
});

class FakeChat extends ChatbotApiService {
  FakeChat() : super(ApiClient());
  String? group;
  String? sent;
  @override
  Future<Map<String, dynamic>?> loadHistory() async => null;
  @override
  Future<void> saveHistory({
    required List<ChatMessage> messages,
    required String ageGroup,
    required int age,
  }) async {}
  @override
  Future<void> clearHistory() async {}
  @override
  Future<ChatResponseData> sendMessage({
    required String message,
    String? ageGroup,
    int? age,
    double? latitude,
    double? longitude,
  }) async {
    sent = message;
    group = ageGroup;
    return ChatResponseData(
      reply:
          '**Informasi obat**\nHubungi apoteker untuk memastikan penggunaan obat.',
      medicineName: 'Vitamin C',
      availability: 'NEARBY',
      isNearby: true,
      pharmacies: [
        ChatPharmacy(
          apotekId: pharmacy.id,
          nama: pharmacy.name,
          alamat: pharmacy.address,
          latitude: -6.4,
          longitude: 108.2,
          distanceKm: .8,
          harga: 8500,
          stok: 12,
          jamBuka: '00:00',
          jamTutup: '23:59',
          isOpen: true,
        ),
      ],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FakeChat chat;
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
  setUp(() {
    chat = FakeChat();
    SharedPreferences.setMockInitialValues({
      'full_name': 'Nama Pengguna',
      'email': 'user@example.invalid',
      'auth_provider': 'google',
      'auth_token': 'session-kept',
    });
  });
  Future<void> show(
    WidgetTester tester, {
    int tab = 0,
    Widget? page,
    Size size = const Size(390, 844),
    double scale = 1,
    double keyboard = 0,
    ThemeMode? mode = ThemeMode.light,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apotekViewDataListProvider.overrideWith(
            (ref) async => [pharmacy, closed],
          ),
          apotekDetailProvider(
            'pharmacy-test',
          ).overrideWith((ref) async => pharmacy.raw),
          userLocationProvider.overrideWith(() => _FixedLocation()),
          medicineCatalogProvider.overrideWith(
            (ref) async => MedicineCatalog(
              pharmacy.medicines
                  .map((m) => MedicineOffer(pharmacy, m))
                  .toList(),
            ),
          ),
          chatbotServiceProvider.overrideWithValue(chat),
        ],
        child: ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance,
          builder:
              (context, selectedMode, _) => MaterialApp(
                theme: AppUi.theme,
                darkTheme: AppUi.darkTheme,
                themeMode: mode ?? selectedMode,
                debugShowCheckedModeBanner: false,
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQueryData(
                        size: size,
                        textScaler: TextScaler.linear(scale),
                        viewInsets: EdgeInsets.only(bottom: keyboard),
                      ),
                      child: RepaintBoundary(
                        key: const ValueKey('preview'),
                        child: child!,
                      ),
                    ),
                home:
                    page ??
                    AppShell(initialIndex: tab, requestPermissions: false),
              ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/Logo-remove.png'),
        tester.element(find.byType(MaterialApp)),
      );
    });
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

  Future<void> tap(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('all five tabs render reference layout with real state', (
    tester,
  ) async {
    for (var i = 0; i < 5; i++) {
      await show(tester, tab: i);
      await capture(
        tester,
        ['beranda', 'cari-apotek', 'medibot', 'cari-obat', 'profil'][i],
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ClinicalBottomNav), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });
  testWidgets(
    'dark mode covers all tabs, auth, onboarding, profile and detail',
    (tester) async {
      for (var i = 0; i < 5; i++) {
        await show(tester, tab: i, mode: ThemeMode.dark);
        expect(
          Theme.of(tester.element(find.byType(ClinicalBottomNav))).brightness,
          Brightness.dark,
        );
        await capture(
          tester,
          [
            'beranda-dark',
            'cari-apotek-dark',
            'medibot-dark',
            'cari-obat-dark',
            'profil-dark',
          ][i],
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
      final pages = <String, Widget>{
        'login-dark': const Login(),
        'register-dark': const Register(),
        'onboarding-dark': const Onboarding(),
        'edit-profil-dark': const EditProfilePage(),
        'detail-apotek-dark': DetailApotek1(idApotek: pharmacy.id),
      };
      for (final entry in pages.entries) {
        await show(tester, page: entry.value, mode: ThemeMode.dark);
        await capture(tester, entry.key);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    },
  );
  testWidgets(
    'theme picker changes appearance, persists and survives logout clearing',
    (tester) async {
      await ThemeController.instance.load();
      await show(tester, tab: 4, mode: null);
      await tap(tester, find.byTooltip('Ubah tema'));
      await tap(tester, find.text('Gelap'));
      expect(ThemeController.instance.value, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(ClinicalBottomNav))).brightness,
        Brightness.dark,
      );
      expect(
        (await SharedPreferences.getInstance()).getString(
          ThemeController.preferenceKey,
        ),
        'dark',
      );
      await AuthSessionStore().clear();
      ThemeController.instance.value = ThemeMode.system;
      await ThemeController.instance.load();
      expect(ThemeController.instance.value, ThemeMode.dark);
      await tap(tester, find.text('Tema Aplikasi'));
      await tap(tester, find.text('Terang'));
      expect(
        Theme.of(tester.element(find.byType(ClinicalBottomNav))).brightness,
        Brightness.light,
      );
      await tap(tester, find.byTooltip('Ubah tema'));
      await tap(tester, find.text('Ikuti Sistem'));
      expect(ThemeController.instance.value, ThemeMode.system);
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(ClinicalBottomNav))).brightness,
        Brightness.dark,
      );
      await capture(tester, 'tema-sistem-dark');
    },
  );
  testWidgets('dark mode supports messages, password reset and logout dialog', (
    tester,
  ) async {
    await show(tester, tab: 2, mode: ThemeMode.dark);
    await tap(tester, find.text('Dewasa'));
    await tester.enterText(find.byType(TextField), 'Informasi vitamin C');
    await tap(tester, find.byTooltip('Kirim pesan'));
    await capture(tester, 'medibot-jawaban-dark');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await show(tester, tab: 4, mode: ThemeMode.dark);
    await tap(tester, find.text('Keluar dari Akun'));
    await capture(tester, 'konfirmasi-keluar-dark');
    await tap(tester, find.text('Batal'));
    await tester.pumpWidget(const SizedBox());
    await show(tester, page: const Login(), mode: ThemeMode.dark);
    await tap(tester, find.text('Lupa Kata Sandi?'));
    await capture(tester, 'lupa-password-dark');
    expect(tester.takeException(), isNull);
  });
  testWidgets('pharmacy search filters names and operating status', (
    tester,
  ) async {
    await show(tester, tab: 1);
    expect(find.text(pharmacy.name), findsOneWidget);
    expect(find.text(closed.name), findsOneWidget);
    await tap(tester, find.text('Hanya Buka'));
    expect(find.text(closed.name), findsNothing);
    await tester.enterText(find.byType(TextField), 'tidak-ada');
    await tester.pumpAndSettle();
    expect(find.text('Apotek tidak ditemukan'), findsOneWidget);
    await tap(tester, find.byTooltip('Hapus pencarian'));
    expect(find.text(pharmacy.name), findsOneWidget);
  });
  testWidgets('medicine catalog filters stock and opens supplier detail', (
    tester,
  ) async {
    await show(tester, tab: 3);
    expect(find.text('Antiseptik'), findsNWidgets(2));
    await tap(tester, find.widgetWithText(ChoiceChip, 'Stok Tersedia'));
    expect(find.text('Antiseptik'), findsOneWidget);
    await tap(tester, find.text('Kunjungi').first);
    expect(find.byType(DetailApotek1), findsOneWidget);
    await capture(tester, 'detail-apotek');
    expect(tester.takeException(), isNull);
    await tap(tester, find.widgetWithText(ChoiceChip, 'Habis'));
    expect(find.text('Vitamin C'), findsNothing);
    expect(find.text('Antiseptik'), findsOneWidget);
    await tap(tester, find.byTooltip('Detail Antiseptik'));
    expect(find.text('Stok habis'), findsOneWidget);
  });
  testWidgets('profile edit saves only a device display name', (tester) async {
    await show(tester, tab: 4);
    await tap(tester, find.byTooltip('Edit profil'));
    expect(find.byType(EditProfilePage), findsOneWidget);
    await capture(tester, 'edit-profil');
    await tester.enterText(find.byType(TextFormField).first, 'Nama Baru');
    await tap(tester, find.text('Simpan Perubahan'));
    expect(find.text('Nama Baru'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('display_name'), 'Nama Baru');
    expect(prefs.getString('password'), isNull);
    expect(prefs.getString('auth_token'), 'session-kept');
  });
  testWidgets(
    'logout confirmation cancel preserves session and uses real account',
    (tester) async {
      await show(tester, tab: 4);
      await tap(tester, find.text('Keluar dari Akun'));
      await capture(tester, 'konfirmasi-keluar');
      expect(find.text('Keluar dari Akun?'), findsOneWidget);
      expect(find.text('user@example.invalid'), findsNWidgets(2));
      await tap(tester, find.text('Batal'));
      expect(find.text('Keluar dari Akun?'), findsNothing);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        'session-kept',
      );
    },
  );
  testWidgets(
    'MediBot requires age then sends backend context and formats response',
    (tester) async {
      await show(tester, tab: 2);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      await tap(tester, find.text('Dewasa'));
      await tester.enterText(find.byType(TextField), 'Informasi vitamin C');
      await tap(tester, find.byTooltip('Kirim pesan'));
      expect(chat.sent, 'Informasi vitamin C');
      expect(chat.group, 'Dewasa (12-59 tahun)');
      expect(find.textContaining('**Informasi obat**'), findsNothing);
      expect(find.text(pharmacy.name), findsOneWidget);
      await capture(tester, 'medibot-jawaban');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('small screens enlarged text and keyboard do not overflow', (
    tester,
  ) async {
    for (var i = 0; i < 5; i++) {
      await show(tester, tab: i, size: const Size(320, 568), scale: 1.5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
    await show(
      tester,
      page: DetailApotek1(idApotek: pharmacy.id),
      size: const Size(320, 568),
      scale: 1.5,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await show(
      tester,
      tab: 2,
      size: const Size(320, 568),
      scale: 1.5,
      keyboard: 250,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await show(
      tester,
      page: const EditProfilePage(),
      size: const Size(320, 568),
      scale: 1.5,
      keyboard: 250,
    );
    expect(tester.takeException(), isNull);
  });
}

class _FixedLocation extends UserLocationNotifier {
  @override
  UserLocation? build() =>
      UserLocation(lat: -6.4, lng: 108.2, addressName: 'Indramayu, Jawa Barat');
}
