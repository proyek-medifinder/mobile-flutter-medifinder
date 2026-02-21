import 'package:dio/dio.dart';
import 'package:medifinder/services/api_client.dart';

class ProductApi {
  final ApiClient client;

  ProductApi(this.client);

  Future<List<dynamic>> getApotek() async {
    final Response res = await client.dio.get('/apotek');
    final data = res.data;

    if (data is Map && data['data'] is List) {
      return List<dynamic>.from(data['data']);
    } else if (data is List) {
      return List<dynamic>.from(data);
    }
    return [];
  }


  Future<Map<String, dynamic>> getApotekById(String id) async {
    final res = await client.dio.get('/apotek/show/$id');
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
