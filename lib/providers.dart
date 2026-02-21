import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medifinder/services/api_client.dart';
import 'package:medifinder/services/produk_api.dart';

// 1. client Dio
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// 2. service untuk barang
final productApiProvider = Provider<ProductApi>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProductApi(client);
});

// 3. provider untuk list produk (async)
final apotekListProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(productApiProvider);
  return api.getApotek();
});

final apotekDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final api = ref.watch(productApiProvider);
  return api.getApotekById(id);
});
