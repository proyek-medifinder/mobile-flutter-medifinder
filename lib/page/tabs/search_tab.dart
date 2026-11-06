import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});
  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  final _search = TextEditingController();
  String _keyword = '';
  int _filter = 0;
  bool _nearest = false;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _set(String s) {
    _search.text = s;
    setState(() => _keyword = s.trim());
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(apotekViewDataListProvider);
    final location = ref.watch(userLocationProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppUi.primaryDark, AppUi.primary],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppUi.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cari Apotek',
                        style: AppUi.text(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Temukan apotek berdasarkan nama atau alamat.',
                        style: AppUi.text(fontSize: 12, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppSearchField(
            controller: _search,
            hint: 'Ketik nama apotek atau jalan...',
            onChanged: (s) => setState(() => _keyword = s.trim()),
          ),
          const SizedBox(height: 16),
          Text(
            'PENCARIAN CEPAT',
            style: AppUi.text(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppUi.colors(context).secondary,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  ['24 Jam', 'Kimia Farma', 'K-24', 'Century']
                      .map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ActionChip(
                            label: Text(
                              s,
                              style: AppUi.text(
                                fontSize: 11,
                                color: AppUi.colors(context).primaryText,
                              ),
                            ),
                            backgroundColor: AppUi.colors(context).surface,
                            side: BorderSide.none,
                            onPressed: () => _set(s),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 12),
          FilterPills(
            labels: const ['Semua Status', 'Hanya Buka', 'Tutup'],
            selected: _filter,
            onSelected: (i) => setState(() => _filter = i),
          ),
          const SizedBox(height: 16),
          list.when(
            loading:
                () =>
                    const DataState(title: 'Mencari apotek...', loading: true),
            error:
                (e, s) => DataState(
                  title: 'Data apotek belum bisa dimuat',
                  onRetry: () => ref.invalidate(apotekListProvider),
                ),
            data: (all) {
              final query = _keyword.toLowerCase();
              final result =
                  all.where((a) {
                    final matches =
                        query == '24 jam'
                            ? a.hours.toLowerCase().contains(query)
                            : '${a.name} ${a.address}'.toLowerCase().contains(
                              query,
                            );
                    return matches &&
                        (_filter == 0 || (_filter == 1 ? a.isBuka : !a.isBuka));
                  }).toList();
              if (_nearest) {
                result.sort(
                  (a, b) => (a.distance ?? double.infinity).compareTo(
                    b.distance ?? double.infinity,
                  ),
                );
              }
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ditemukan ${result.length} apotek',
                          style: AppUi.text(
                            fontSize: 12,
                            color: AppUi.colors(context).secondary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed:
                            all.any((a) => a.distance != null)
                                ? () => setState(() => _nearest = !_nearest)
                                : null,
                        icon: const Icon(Icons.sort_rounded, size: 17),
                        label: Text(
                          _nearest ? 'Terdekat' : 'Urutkan',
                          style: AppUi.text(
                            fontSize: 11,
                            color: AppUi.colors(context).primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (result.isEmpty)
                    const DataState(
                      title: 'Apotek tidak ditemukan',
                      subtitle: 'Coba nama, alamat, atau filter lain.',
                    ),
                  ...result.map(
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
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ContentPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeading('Jelajahi Peta Wilayah'),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppUi.colors(context).softTeal,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: AppUi.colors(context).primaryText,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        location?.addressName ?? 'Cari apotek di Google Maps',
                        textAlign: TextAlign.center,
                        style: AppUi.text(
                          fontSize: 12,
                          color: AppUi.colors(context).primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed:
                            () => openExternal(
                              context,
                              Uri.https('www.google.com', '/maps/search/', {
                                'api': '1',
                                'query':
                                    location == null
                                        ? 'apotek terdekat'
                                        : 'apotek near ${location.lat},${location.lng}',
                              }),
                            ),
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Buka Peta'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
