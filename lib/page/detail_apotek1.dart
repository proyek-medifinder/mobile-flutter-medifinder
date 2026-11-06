import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/page/chatbot.dart';
import 'package:medifinder/page/widgets/apotek_card.dart';
import 'package:medifinder/page/widgets/auth/auth_widgets.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class DetailApotek1 extends ConsumerStatefulWidget {
  const DetailApotek1({super.key, required this.idApotek, this.initialData});
  final String idApotek;
  final ApotekViewData? initialData;
  @override
  ConsumerState<DetailApotek1> createState() => _DetailApotek1State();
}

class _DetailApotek1State extends ConsumerState<DetailApotek1> {
  final _search = TextEditingController();
  String _keyword = '';
  int _filter = 0;
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Uri _map(ApotekViewData a) {
    final lat = a.raw['latitude'], lng = a.raw['longitude'];
    final query =
        lat != null && lng != null ? '$lat,$lng' : '${a.name} ${a.address}';
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': query,
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(apotekDetailProvider(widget.idApotek));
    final data = detail.asData?.value;
    final a = data != null ? ApotekViewData.fromMap(data) : widget.initialData;
    return Scaffold(
      backgroundColor: AppUi.colors(context).background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const MediFinderLogo(width: 95),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detail Apotek',
                style: AppUi.text(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body:
          a == null
              ? Padding(
                padding: const EdgeInsets.all(20),
                child: DataState(
                  title:
                      detail.isLoading
                          ? 'Memuat detail apotek...'
                          : 'Detail belum bisa dimuat',
                  loading: detail.isLoading,
                  onRetry:
                      detail.hasError
                          ? () => ref.invalidate(
                            apotekDetailProvider(widget.idApotek),
                          )
                          : null,
                ),
              )
              : _content(a, detail.isLoading, detail.hasError),
    );
  }

  Widget _content(ApotekViewData a, bool loading, bool error) {
    final medicines =
        a.medicines
            .where(
              (m) =>
                  '${m.name} ${m.description ?? ''}'.toLowerCase().contains(
                    _keyword.toLowerCase(),
                  ) &&
                  (_filter == 0 || (_filter == 1 ? m.stock > 0 : m.stock == 0)),
            )
            .toList();
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClinicalImage(
                  url: a.imageUrl,
                  icon: Icons.local_pharmacy_outlined,
                ),
                Positioned(
                  top: 14,
                  left: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppUi.colors(context).surface,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: StatusPill(
                      a.isBuka ? 'Buka Sekarang' : 'Sedang Tutup',
                      color:
                          a.isBuka
                              ? const Color(0xFF1B8A5A)
                              : const Color(0xFFC0392B),
                      icon: Icons.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (loading)
                      Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: AppUi.colors(context).primaryText,
                        ),
                      ),
                    if (error)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DataState(
                          title: 'Detail belum diperbarui',
                          subtitle: 'Menampilkan informasi sebelumnya.',
                          onRetry:
                              () => ref.invalidate(
                                apotekDetailProvider(widget.idApotek),
                              ),
                        ),
                      ),
                    ContentPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: AppUi.text(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (a.distance != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              '${a.distance!.toStringAsFixed(1)} km dari lokasi Anda',
                              style: AppUi.text(
                                fontSize: 12,
                                color: AppUi.colors(context).primaryText,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (a.phone?.isNotEmpty == true)
                                FilledButton.icon(
                                  onPressed:
                                      () => openExternal(
                                        context,
                                        Uri(scheme: 'tel', path: a.phone!),
                                      ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppUi.accent,
                                    foregroundColor: AppUi.primaryDark,
                                    minimumSize: const Size(48, 44),
                                  ),
                                  icon: const Icon(
                                    Icons.call_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Hubungi Apotek'),
                                ),
                              OutlinedButton.icon(
                                onPressed: () => openExternal(context, _map(a)),
                                icon: const Icon(
                                  Icons.directions_outlined,
                                  size: 18,
                                ),
                                label: const Text('Rute'),
                              ),
                              if (a.email?.isNotEmpty == true)
                                IconButton(
                                  tooltip: 'Email apotek',
                                  onPressed:
                                      () => openExternal(
                                        context,
                                        Uri(scheme: 'mailto', path: a.email!),
                                      ),
                                  icon: Icon(
                                    Icons.mail_outline_rounded,
                                    color: AppUi.colors(context).primaryText,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ContentPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeading('Informasi Operasional'),
                          _info(
                            Icons.schedule_rounded,
                            'Jam Operasional',
                            a.hours.isEmpty ? 'Jam belum diatur' : a.hours,
                          ),
                          const SizedBox(height: 16),
                          _info(
                            Icons.location_on_outlined,
                            'Alamat Lengkap',
                            a.address,
                          ),
                          if (a.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 16),
                            Text(
                              a.description!,
                              style: AppUi.text(
                                fontSize: 13,
                                color: AppUi.colors(context).secondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => openExternal(context, _map(a)),
                              icon: const Icon(Icons.map_outlined, size: 19),
                              label: const Text('Buka di Google Maps'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeading(
                      'Katalog Obat di Apotek Ini',
                      subtitle: '${a.medicines.length} obat',
                    ),
                    AppSearchField(
                      controller: _search,
                      hint: 'Cari obat di apotek ini...',
                      onChanged: (s) => setState(() => _keyword = s),
                    ),
                    const SizedBox(height: 12),
                    FilterPills(
                      labels: const ['Semua', 'Tersedia', 'Habis'],
                      selected: _filter,
                      onSelected: (i) => setState(() => _filter = i),
                    ),
                    const SizedBox(height: 16),
                    if (medicines.isEmpty)
                      const DataState(
                        title: 'Belum ada obat yang sesuai',
                        subtitle: 'Coba kata kunci atau filter lain.',
                      )
                    else
                      LayoutBuilder(
                        builder: (context, c) {
                          final count = c.maxWidth > 500 ? 3 : 2;
                          final width = (c.maxWidth - (count - 1) * 12) / count;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children:
                                medicines
                                    .map(
                                      (m) => SizedBox(
                                        width: width,
                                        child: _medicine(m),
                                      ),
                                    )
                                    .toList(),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    BotBanner(
                      compact: true,
                      onTap:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChatbotPage(),
                            ),
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String title, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: AppUi.colors(context).muted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: AppUi.colors(context).primaryText),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppUi.text(
                fontSize: 11,
                color: AppUi.colors(context).secondary,
              ),
            ),
            Text(value, style: AppUi.text(fontSize: 13)),
          ],
        ),
      ),
    ],
  );
  Widget _medicine(ObatViewData m) => Material(
    color: AppUi.colors(context).surface,
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () => _showMedicine(m),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 125,
                width: double.infinity,
                child: ClinicalImage(url: m.imageUrl),
              ),
            ),
            const SizedBox(height: 8),
            StatusPill(
              m.stock > 0 ? 'Tersedia (${m.stock})' : 'Habis',
              color:
                  m.stock > 0
                      ? const Color(0xFF1B8A5A)
                      : const Color(0xFFC0392B),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44 * MediaQuery.textScalerOf(context).scale(1),
              child: Text(
                m.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppUi.text(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    m.price == null ? 'Harga belum tersedia' : rupiah(m.price!),
                    style: AppUi.text(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppUi.colors(context).primaryText,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Detail ${m.name}',
                  onPressed: () => _showMedicine(m),
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: AppUi.colors(context).primaryText,
                    size: 21,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 44,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  void _showMedicine(ObatViewData m) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppUi.colors(context).surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder:
        (ctx) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.name,
                      style: AppUi.text(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: ClinicalImage(url: m.imageUrl),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                m.price == null ? 'Harga belum tersedia' : rupiah(m.price!),
                style: AppUi.text(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppUi.colors(context).primaryText,
                ),
              ),
              const SizedBox(height: 8),
              StatusPill(
                m.stock > 0 ? 'Stok tersedia: ${m.stock}' : 'Stok habis',
                color:
                    m.stock > 0
                        ? const Color(0xFF1B8A5A)
                        : const Color(0xFFC0392B),
              ),
              if (m.description?.isNotEmpty == true) ...[
                const SizedBox(height: 16),
                Text(m.description!, style: AppUi.text(fontSize: 14)),
              ],
              const SizedBox(height: 16),
              Text(
                'Konfirmasi stok dan penggunaan obat kepada apotek.',
                style: AppUi.text(
                  fontSize: 12,
                  color: AppUi.colors(context).secondary,
                ),
              ),
            ],
          ),
        ),
  );
}
