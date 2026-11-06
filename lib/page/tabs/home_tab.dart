import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/page/chatbot.dart';
import 'package:medifinder/page/search.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/services/location_service.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key, this.onNavigateTab});
  final ValueChanged<int>? onNavigateTab;
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  String _name = '';
  int _filter = 0;
  String? _locationError;
  @override
  void initState() {
    super.initState();
    _loadName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          ref.read(userLocationProvider) == null &&
          !ref.read(isLocationLoadingProvider)) {
        _locate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadName();
  }

  Future<void> _loadName() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () =>
            _name =
                p.getString('display_name') ??
                p.getString('full_name') ??
                'Pengguna',
      );
    }
  }

  Future<void> _locate() async {
    if (ref.read(isLocationLoadingProvider)) return;
    ref.read(isLocationLoadingProvider.notifier).setLoading(true);
    setState(() => _locationError = null);
    try {
      final loc = await LocationService.fetchUserLocation();
      if (!mounted) return;
      if (loc != null) {
        ref.read(userLocationProvider.notifier).setLocation(loc);
      } else {
        setState(
          () => _locationError = 'Aktifkan GPS dan izinkan akses lokasi.',
        );
      }
    } finally {
      if (mounted) {
        ref.read(isLocationLoadingProvider.notifier).setLoading(false);
      }
    }
  }

  void _navigate(int tab) {
    if (widget.onNavigateTab != null) {
      widget.onNavigateTab!(tab);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => tab == 2 ? const ChatbotPage() : const Search(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apotekViewDataListProvider),
        location = ref.watch(userLocationProvider);
    final locating = ref.watch(isLocationLoadingProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(apotekListProvider);
        try {
          await ref.read(apotekViewDataListProvider.future);
        } catch (_) {}
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppUi.primary, AppUi.primaryDark],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(26),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Halo, ${_name.isEmpty ? 'Pengguna' : _name.split(' ').first}',
                    style: AppUi.text(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Cari apotek terdekat & cek ketersediaan obat.',
                    style: AppUi.text(fontSize: 13, color: Colors.white),
                  ),
                  const SizedBox(height: 18),
                  Material(
                    color: AppUi.colors(context).surface,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => _navigate(3),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: AppUi.colors(context).primaryText,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cari obat atau apotek...',
                                style: AppUi.text(
                                  fontSize: 13,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.tune_rounded,
                              color: AppUi.colors(context).primaryText,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppUi.colors(context).surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: AppUi.colors(context).softTeal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              locating
                                  ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : Icon(
                                    Icons.location_on_outlined,
                                    color: AppUi.colors(context).primaryText,
                                    size: 21,
                                  ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOKASI ANDA',
                                style: AppUi.text(
                                  fontSize: 10,
                                  color: AppUi.colors(context).secondary,
                                ),
                              ),
                              Text(
                                locating
                                    ? 'Sedang mencari lokasi...'
                                    : _locationError ??
                                        location?.addressName ??
                                        'Lokasi belum diaktifkan',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppUi.text(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: locating ? null : _locate,
                          child: Text(
                            location == null ? 'Aktifkan' : 'Ubah',
                            style: AppUi.text(
                              fontSize: 11,
                              color: AppUi.colors(context).primaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BotBanner(onTap: () => _navigate(2)),
                  const SizedBox(height: 24),
                  SectionHeading(
                    location == null ? 'Daftar Apotek' : 'Apotek Terdekat',
                    subtitle:
                        location == null
                            ? 'Temukan apotek yang Anda butuhkan.'
                            : 'Apotek di sekitar lokasi Anda.',
                    action: TextButton(
                      onPressed: () => _navigate(1),
                      child: Text(
                        'Lihat Semua',
                        style: AppUi.text(
                          fontSize: 11,
                          color: AppUi.colors(context).primaryText,
                        ),
                      ),
                    ),
                  ),
                  FilterPills(
                    labels: const ['Semua', 'Buka Sekarang', '24 Jam'],
                    selected: _filter,
                    onSelected: (i) => setState(() => _filter = i),
                  ),
                  const SizedBox(height: 12),
                  list.when(
                    loading:
                        () => const DataState(
                          title: 'Memuat apotek...',
                          loading: true,
                        ),
                    error:
                        (e, s) => DataState(
                          title: 'Data apotek belum bisa dimuat',
                          onRetry: () => ref.invalidate(apotekListProvider),
                        ),
                    data: (all) {
                      final filtered =
                          all
                              .where(
                                (a) =>
                                    _filter == 0 ||
                                    (_filter == 1
                                        ? a.isBuka
                                        : a.hours.toLowerCase().contains(
                                          '24 jam',
                                        )),
                              )
                              .toList();
                      if (filtered.isEmpty) {
                        return const DataState(
                          title: 'Belum ada apotek yang sesuai',
                          subtitle:
                              'Coba filter lain atau perbarui lokasi Anda.',
                        );
                      }
                      return Column(
                        children:
                            filtered
                                .map(
                                  (a) => ApotekCard(
                                    namaApotek: a.name,
                                    alamat: a.address,
                                    statusBuka: a.isBuka ? 'Buka' : 'Tutup',
                                    jamOperasional: a.hours,
                                    gambarUrl: a.imageUrl,
                                    idApotek: a.id,
                                    apotekData: a.raw,
                                    distance: a.distance,
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
