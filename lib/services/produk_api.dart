import 'package:dio/dio.dart';
import 'package:medifinder/config/api_config.dart';
import 'package:medifinder/services/api_client.dart';

class ProductApi {
  final ApiClient client;

  ProductApi(this.client);

  Future<List<dynamic>> getApotek() async {
    final Response res = await client.dio.get(
      '${ApiConfig.apiBase}/mobile/apotek?page=1&limit=10',
    );
    final data = res.data;

    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    } else if (data is List) {
      return List<dynamic>.from(data);
    }
    return [];
  }

  Future<List<dynamic>> getObatByApotek({
    required String apotekId,
    String name = '',
  }) async {
    final res = await client.dio.get(
      '${ApiConfig.apiBase}/apotek/$apotekId/obat',
      queryParameters: {'name': name},
    );
    final data = res.data;

    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    }
    if (data is List) {
      return List<dynamic>.from(data);
    }

    return [];
  }

  Future<Map<String, dynamic>> getApotekById(String id) async {
    final res = await client.dio.get('${ApiConfig.apiBase}/mobile/apotek/$id');
    final data = res.data;

    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data']);
    }
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Format data detail tidak dikenali');
  }
}
