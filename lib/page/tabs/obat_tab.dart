import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/page/chatbot.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/services/medicine_catalog.dart';
import 'package:medifinder/theme/app_ui.dart';

class ObatTab extends ConsumerStatefulWidget {
  const ObatTab({super.key, this.onNavigateTab});
  final ValueChanged<int>? onNavigateTab;
  @override
  ConsumerState<ObatTab> createState() => _ObatTabState();
}

class _ObatTabState extends ConsumerState<ObatTab> {
  final _search = TextEditingController();
  String _keyword = '';
  int _filter = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(medicineCatalogProvider);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppUi.primaryDark, AppUi.primary],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KATALOG & STOK OBAT',
                  style: AppUi.text(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA2F8EB),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cari & Temukan Obat',
                  style: AppUi.text(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cek stok dan harga obat dari apotek.',
                  style: AppUi.text(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 16),
                AppSearchField(
                  controller: _search,
                  hint: 'Ketik nama obat...',
                  onChanged: (s) => setState(() => _keyword = s.trim()),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        ['Paracetamol', 'Vitamin C', 'Antiseptik']
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  backgroundColor: const Color(0xFF2A8B81),
                                  side: BorderSide.none,
                                  label: Text(
                                    s,
                                    style: AppUi.text(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                  onPressed: () {
                                    _search.text = s;
                                    setState(() => _keyword = s);
                                  },
                                ),
                              ),
                            )
                            .toList(),
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
                FilterPills(
                  labels: const ['Semua', 'Stok Tersedia', 'Harga Terendah'],
                  selected: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
                const SizedBox(height: 14),
                BotBanner(
                  compact: true,
                  onTap: () {
                    if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(2);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatbotPage()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),
                SectionHeading(
                  _keyword.isEmpty ? 'Obat & Ketersediaan' : 'Hasil Pencarian',
                  subtitle: 'Konfirmasi stok sebelum mengunjungi apotek.',
                ),
                catalog.when(
                  loading:
                      () => const DataState(
                        title: 'Memuat katalog obat...',
                        loading: true,
                      ),
                  error:
                      (e, s) => DataState(
                        title: 'Katalog belum bisa dimuat',
                        onRetry: () => ref.invalidate(medicineCatalogProvider),
                      ),
                  data: (data) {
                    final filtered =
                        data.offers
                            .where(
                              (o) =>
                                  '${o.medicine.name} ${o.medicine.description ?? ''}'
                                      .toLowerCase()
                                      .contains(_keyword.toLowerCase()) &&
                                  (_filter != 1 || o.medicine.stock > 0),
                            )
                            .toList();
                    if (_filter == 2) {
                      filtered.sort(
                        (a, b) => (a.medicine.price ?? double.infinity)
                            .compareTo(b.medicine.price ?? double.infinity),
                      );
                    }
                    final groups = <String, List<MedicineOffer>>{};
                    for (final o in filtered) {
                      groups
                          .putIfAbsent(
                            o.medicine.name.trim().toLowerCase(),
                            () => [],
                          )
                          .add(o);
                    }
                    return Column(
                      children: [
                        if (data.failedPharmacies > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: DataState(
                              title: 'Sebagian stok belum termuat',
                              subtitle:
                                  '${data.failedPharmacies} apotek belum dapat dihubungi.',
                              onRetry:
                                  () => ref.invalidate(medicineCatalogProvider),
                            ),
                          ),
                        if (groups.isEmpty)
                          const DataState(
                            title: 'Obat tidak ditemukan',
                            subtitle: 'Coba nama obat atau filter lain.',
                          ),
                        ...groups.entries.map(
                          (e) => MedicineCatalogCard(
                            key: ValueKey('${e.key}-$_filter'),
                            offers: e.value,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineCatalogCard extends StatefulWidget {
  const MedicineCatalogCard({super.key, required this.offers});
  final List<MedicineOffer> offers;
  @override
  State<MedicineCatalogCard> createState() => _MedicineCatalogCardState();
}

class _MedicineCatalogCardState extends State<MedicineCatalogCard> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final offers = widget.offers;
    final medicine = offers.first.medicine;
    final prices =
        offers.map((o) => o.medicine.price).whereType<double>().toList()
          ..sort();
    final price =
        prices.isEmpty
            ? 'Harga belum tersedia'
            : prices.first == prices.last
            ? rupiah(prices.first)
            : '${rupiah(prices.first)} – ${rupiah(prices.last)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ContentPanel(
        padding: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox.square(
                    dimension: 76,
                    child: ClinicalImage(url: medicine.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusPill(
                        offers.any((o) => o.medicine.stock > 0)
                            ? 'Stok Tersedia'
                            : 'Stok Habis',
                        color:
                            offers.any((o) => o.medicine.stock > 0)
                                ? const Color(0xFF1B8A5A)
                                : const Color(0xFFC0392B),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        medicine.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppUi.text(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (medicine.description?.isNotEmpty == true)
                        Text(
                          medicine.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppUi.text(
                            fontSize: 12,
                            color: AppUi.colors(context).secondary,
                          ),
                        ),
                      const SizedBox(height: 7),
                      Text(
                        price,
                        style: AppUi.text(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppUi.colors(context).primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Apotek Penyedia (${offers.length})',
              style: AppUi.text(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppUi.colors(context).primaryText,
              ),
            ),
            const SizedBox(height: 8),
            ...(_expanded ? offers : offers.take(2)).map(
              (o) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppUi.colors(context).muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.pharmacy.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppUi.text(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${o.pharmacy.distance == null ? '' : '${o.pharmacy.distance!.toStringAsFixed(1)} km · '}Stok ${o.medicine.stock}${o.medicine.price == null ? '' : ' · ${rupiah(o.medicine.price!)}'}',
                            style: AppUi.text(
                              fontSize: 10,
                              color: AppUi.colors(context).secondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => DetailApotek1(
                                        idApotek: o.pharmacy.id,
                                        initialData: o.pharmacy,
                                      ),
                                ),
                              ),
                          style: TextButton.styleFrom(
                            backgroundColor: AppUi.accent,
                            foregroundColor: AppUi.primaryDark,
                            minimumSize: const Size(48, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          child: Text(
                            'Kunjungi',
                            style: AppUi.text(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppUi.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (offers.length > 2)
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    _expanded
                        ? 'Tampilkan Lebih Sedikit'
                        : 'Lihat ${offers.length - 2} Apotek Lainnya',
                    style: AppUi.text(
                      fontSize: 11,
                      color: AppUi.colors(context).primaryText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
