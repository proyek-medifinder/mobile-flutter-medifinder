import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/providers.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

class MedicineOffer {
  const MedicineOffer(this.pharmacy, this.medicine);
  final ApotekViewData pharmacy;
  final ObatViewData medicine;
}

class MedicineCatalog {
  const MedicineCatalog(this.offers, {this.failedPharmacies = 0});
  final List<MedicineOffer> offers;
  final int failedPharmacies;
}

final medicineCatalogProvider = FutureProvider<MedicineCatalog>((ref) async {
  final pharmacies = await ref.watch(apotekViewDataListProvider.future);
  final api = ref.watch(productApiProvider);
  final available = pharmacies.where((a) => a.id.isNotEmpty).toList();
  int failures = 0;
  final results = await Future.wait(
    available.map((a) async {
      try {
        final medicines = await api.getObatByApotek(apotekId: a.id);
        return medicines
            .whereType<Map>()
            .map(
              (m) => MedicineOffer(
                a,
                ObatViewData.fromMap(Map<String, dynamic>.from(m)),
              ),
            )
            .toList();
      } catch (_) {
        failures++;
        return <MedicineOffer>[];
      }
    }),
  );
  if (available.isNotEmpty && failures == available.length) {
    throw StateError('Katalog belum dapat dimuat');
  }
  return MedicineCatalog(
    results.expand((r) => r).toList(),
    failedPharmacies: failures,
  );
});
