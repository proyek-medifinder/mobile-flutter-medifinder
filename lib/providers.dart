import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/services/api_client.dart';
import 'package:medifinder/services/location_service.dart';
import 'package:medifinder/services/produk_api.dart';
import 'package:medifinder/services/chatbot_service.dart';
import 'package:medifinder/utils/apotek_mapper.dart';

// State lokasi user saat ini
class UserLocationNotifier extends Notifier<UserLocation?> {
  @override
  UserLocation? build() => null;

  void setLocation(UserLocation? loc) => state = loc;
}

final userLocationProvider =
    NotifierProvider<UserLocationNotifier, UserLocation?>(
  UserLocationNotifier.new,
);

// State loading saat sedang mendeteksi lokasi GPS
class LocationLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool val) => state = val;
}

final isLocationLoadingProvider =
    NotifierProvider<LocationLoadingNotifier, bool>(
  LocationLoadingNotifier.new,
);

// 1. Client Dio
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// 2. Service untuk barang / apotek
final productApiProvider = Provider<ProductApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductApi(client);
});

// 3. Provider untuk list mentah dari API (memperhatikan lokasi jika ada)
final apotekListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(productApiProvider);
  final location = ref.watch(userLocationProvider);

  if (location != null) {
    try {
      final nearbyList = await api.getNearbyApotek(
        lat: location.lat,
        lng: location.lng,
      );
      if (nearbyList.isNotEmpty) {
        return nearbyList;
      }
    } catch (_) {
      // Fallback ke list reguler jika gagal
    }
  }

  return api.getApotek();
});

// 4. Provider untuk memetakan ke ApotekViewData
final apotekViewDataListProvider = FutureProvider<List<ApotekViewData>>((ref) async {
  final rawList = await ref.watch(apotekListProvider.future);
  return rawList
      .map((item) => ApotekViewData.fromMap(item as Map<String, dynamic>))
      .toList();
});

// 5. Provider KHUSUS untuk mengambil apotek yang SEDANG BUKA saja
final apotekBukaListProvider = FutureProvider<List<ApotekViewData>>((ref) async {
  final allApotek = await ref.watch(apotekViewDataListProvider.future);
  return allApotek.where((apotek) => apotek.isBuka).toList();
});

// 6. Provider detail apotek
final apotekDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(productApiProvider);
  return api.getApotekById(id);
});

// 7. Provider Chatbot Service
final chatbotServiceProvider = Provider<ChatbotApiService>((ref) {
  final client = ref.watch(apiClientProvider);
  return ChatbotApiService(client);
});