import 'package:dio/dio.dart';
import 'package:medifinder/config/api_config.dart';

class ApiClient {
  final Dio dio;

  ApiClient()
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.apiBase,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    // logging interceptor biar enak debug
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
