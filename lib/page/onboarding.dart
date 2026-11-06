import 'package:medifinder/page/widgets/appearance_picker.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:medifinder/page/login.dart';
import 'package:medifinder/page/register.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/services/onboarding_store.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _controller = PageController();
  int _page = 0;
  bool _leaving = false;
  static const _titles = [
    'Temukan Apotek Terdekat',
    'Cek Ketersediaan Obat',
    'Konsultasi Cerdas MediBot',
  ];
  static const _descriptions = [
    'Temukan apotek di sekitar Anda, lengkap dengan informasi jarak dan jam operasional.',
    'Cari obat yang Anda butuhkan dan lihat informasi stok dari apotek sebelum berkunjung.',
    'Jelajahi informasi obat dan temukan apotek dengan bantuan asisten AI MediBot.',
  ];
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({bool register = false}) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    await OnboardingStore.complete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => register ? const Register() : const Login(),
      ),
    );
  }

  void _go(int page) {
    if (_leaving) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(
        context,
      ).textTheme.apply(fontFamily: 'PlusJakartaSans'),
    ),
    child: Scaffold(
      backgroundColor: AppUi.colors(context).surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: MediFinderLogo(width: 190),
                        ),
                      ),
                      const AppearanceButton(),
                      if (_page < 2)
                        TextButton(
                          onPressed: _leaving ? null : () => _finish(),
                          child: Text(
                            'Lewati',
                            style: AuthDesign.text(
                              13,
                              color: AppUi.colors(context).secondary,
                            ),
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppUi.colors(context).muted,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '3 / 3',
                            style: AuthDesign.text(
                              12,
                              weight: FontWeight.w600,
                              color: AppUi.colors(context).primaryText,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: 3,
                    onPageChanged: (value) => setState(() => _page = value),
                    itemBuilder:
                        (context, index) => LayoutBuilder(
                          builder:
                              (context, constraints) => SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 20,
                                          ),
                                          child: OnboardingArtwork(
                                            index: index,
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              _titles[index],
                                              textAlign: TextAlign.center,
                                              style: AuthDesign.text(
                                                23,
                                                weight: FontWeight.w800,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              _descriptions[index],
                                              textAlign: TextAlign.center,
                                              style: AuthDesign.text(
                                                14,
                                                color:
                                                    AppUi.colors(
                                                      context,
                                                    ).secondary,
                                                height: 1.65,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Semantics(
                        label: 'Langkah ${index + 1} dari 3',
                        selected: _page == index,
                        child: InkWell(
                          onTap: () => _go(index),
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 44,
                            height: 32,
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: _page == index ? 32 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color:
                                      _page == index
                                          ? AuthDesign.primary
                                          : AppUi.colors(context).line,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  child:
                      _page == 2
                          ? Column(
                            children: [
                              AuthPrimaryButton(
                                label: 'Mulai Sekarang',
                                pill: true,
                                loading: _leaving,
                                onPressed: () => _finish(register: true),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Sudah punya akun?',
                                    style: AuthDesign.text(
                                      13,
                                      color: AppUi.colors(context).secondary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _leaving ? null : () => _finish(),
                                    child: Text(
                                      'Masuk',
                                      style: AuthDesign.text(
                                        13,
                                        weight: FontWeight.w700,
                                        color:
                                            AppUi.colors(context).primaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                          : Row(
                            children: [
                              TextButton(
                                onPressed:
                                    _leaving
                                        ? null
                                        : () =>
                                            _page == 0
                                                ? _finish()
                                                : _go(_page - 1),
                                child: Text(
                                  _page == 0 ? 'Lewati' : 'Kembali',
                                  style: AuthDesign.text(
                                    13,
                                    color: AppUi.colors(context).secondary,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 170,
                                child: AuthPrimaryButton(
                                  label: 'Lanjutkan',
                                  pill: true,
                                  onPressed: () => _go(_page + 1),
                                ),
                              ),
                            ],
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingArtwork extends StatelessWidget {
  const OnboardingArtwork({super.key, required this.index});
  final int index;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = math.min(constraints.maxWidth - 8, 280.0);
      final asset = ['pharmacy', 'medicine', 'medibot'][index];
      return Semantics(
        label:
            [
              'Ilustrasi apotek dengan penanda lokasi',
              'Ilustrasi botol obat dan pencarian',
              'Ilustrasi asisten MediBot',
            ][index],
        image: true,
        child: SizedBox(
          width: size,
          height: size + 12,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient:
                      index == 2
                          ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFE6F4F1), Color(0xFFD5EDE8)],
                          )
                          : null,
                  color: index == 2 ? null : const Color(0xFFE6F4F1),
                ),
              ),
              if (index != 1)
                Container(
                  width: size - 40,
                  height: size - 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        index == 2 ? Colors.white.withValues(alpha: .35) : null,
                    border: Border.all(
                      color:
                          index == 2
                              ? Colors.white.withValues(alpha: .7)
                              : AuthDesign.primary.withValues(alpha: .07),
                    ),
                  ),
                ),
              if (index == 2)
                Container(
                  width: size - 90,
                  height: size - 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0x66CCEAE3),
                  ),
                ),
              Padding(
                padding: EdgeInsets.only(top: index == 2 ? 25 : 0),
                child: SvgPicture.asset(
                  'assets/onboarding/$asset.svg',
                  width: index == 2 ? size * .53 : size * .80,
                  excludeFromSemantics: true,
                ),
              ),
              Positioned(
                top: index == 1 ? 12 : 28,
                right: index == 1 ? -2 : null,
                child: _artBadge(
                  context,
                  index == 0
                      ? 'Cari apotek terdekat'
                      : index == 1
                      ? 'Cek stok obat'
                      : 'Tanya MediBot',
                  index == 0
                      ? Icons.near_me_outlined
                      : index == 1
                      ? Icons.check_circle_rounded
                      : Icons.chat_bubble_outline_rounded,
                ),
              ),
              if (index < 2)
                Positioned(
                  bottom: 22,
                  left: index == 1 ? -4 : null,
                  child: _artBadge(
                    context,
                    index == 0 ? 'Jarak dari lokasi Anda' : 'Informasi obat',
                    index == 0
                        ? Icons.location_on_outlined
                        : Icons.medication_outlined,
                  ),
                ),
              if (index == 2)
                const Positioned(
                  right: 24,
                  top: 48,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Color(0xFF14B8A6),
                    size: 23,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
  Widget _artBadge(BuildContext context, String label, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: AppUi.colors(context).surface,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120A5A52),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF14B8A6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: AuthDesign.text(
                11,
                weight: FontWeight.w600,
                color: AppUi.colors(context).primaryText,
              ),
            ),
          ],
        ),
      );
}
