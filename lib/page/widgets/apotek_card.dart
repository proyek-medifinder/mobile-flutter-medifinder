import 'package:flutter/material.dart';
import 'package:medifinder/page/detail_apotek1.dart';
import 'package:medifinder/page/widgets/clinical_widgets.dart';
import 'package:medifinder/theme/app_ui.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class ApotekCard extends StatelessWidget {
  const ApotekCard({
    super.key,
    required this.namaApotek,
    required this.alamat,
    required this.statusBuka,
    required this.jamOperasional,
    required this.gambarUrl,
    required this.idApotek,
    this.tags = const [],
    this.apotekData,
    this.distance,
  });
  final String namaApotek, alamat, statusBuka, jamOperasional, idApotek;
  final String? gambarUrl;
  final List<String> tags;
  final Map<String, dynamic>? apotekData;
  final double? distance;
  void _open(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) => DetailApotek1(
            idApotek: idApotek,
            initialData:
                apotekData == null ? null : ApotekViewData.fromMap(apotekData!),
          ),
    ),
  );
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ContentPanel(
      padding: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _open(context),
            borderRadius: BorderRadius.circular(18),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 170,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClinicalImage(
                      url: gambarUrl,
                      icon: Icons.local_pharmacy_outlined,
                    ),
                    if (statusBuka.isNotEmpty)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppUi.colors(context).surface,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: StatusPill(
                            statusBuka,
                            color: AppUi.statusColor(statusBuka),
                            icon: Icons.circle,
                          ),
                        ),
                      ),
                    if (distance != null)
                      Positioned(
                        bottom: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppUi.primaryDark.withValues(alpha: .85),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${distance!.toStringAsFixed(1)} km',
                            style: AppUi.text(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            namaApotek,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppUi.text(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppUi.colors(context).secondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  alamat,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppUi.text(
                    fontSize: 12,
                    color: AppUi.colors(context).secondary,
                  ),
                ),
              ),
            ],
          ),
          if (jamOperasional.isNotEmpty || tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (jamOperasional.isNotEmpty)
                  StatusPill(jamOperasional, icon: Icons.schedule_rounded),
                ...tags.take(3).map((t) => StatusPill(t)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _open(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppUi.accent,
                foregroundColor: AppUi.primaryDark,
                minimumSize: const Size(48, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              label: const Text('Kunjungi Apotek'),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              iconAlignment: IconAlignment.end,
            ),
          ),
        ],
      ),
    ),
  );
}

class ClinicalImage extends StatelessWidget {
  const ClinicalImage({
    super.key,
    this.url,
    this.icon = Icons.medication_outlined,
  });
  final String? url;
  final IconData icon;
  @override
  Widget build(BuildContext context) =>
      url?.isNotEmpty == true
          ? Image.network(
            url!,
            fit: BoxFit.cover,
            errorBuilder: (_, e, s) => _placeholder(context),
            loadingBuilder:
                (context, child, progress) =>
                    progress == null
                        ? child
                        : Container(
                          color: AppUi.colors(context).muted,
                          child: const Center(
                            child: SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
          )
          : _placeholder(context);
  Widget _placeholder(BuildContext context) => Container(
    color: AppUi.colors(context).softTeal,
    child: Center(
      child: Icon(
        icon,
        size: 44,
        color: AppUi.colors(context).primaryText.withValues(alpha: .5),
      ),
    ),
  );
}
