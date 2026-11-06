import 'package:dio/dio.dart';
import 'package:medifinder/config/api_config.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    this.name,
    this.email,
    this.userId,
    this.picture,
    this.role = 'user',
    this.raw = const {},
  });

  final String token;
  final String? name;
  final String? email;
  final String? userId;
  final String? picture;
  final String role;
  final Map<String, dynamic> raw;

  AuthSession withProfile(Map<String, dynamic> profile) {
    String? value(String key, String? fallback) {
      final result = profile[key];
      return result is String && result.trim().isNotEmpty
          ? result.trim()
          : fallback;
    }

    return AuthSession(
      token: token,
      name: value('name', name),
      email: value('email', email),
      userId: value('id', userId),
      picture: value('profile_picture', picture),
      role: value('role', role)!,
      raw: raw,
    );
  }
}

class AuthApiService {
  AuthApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.authHost,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true',
              },
            ),
          );

  final Dio _dio;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _dio.post(
      '/register',
      data: {'name': name, 'email': email, 'password': password},
    );
  }

  Future<String> requestPasswordReset(String email) async {
    final response = await _dio.post(
      '/forgot-password',
      data: {'email': email},
    );
    final body = _asMap(response.data);
    return _firstString(body, ['message']) ??
        'Jika email terdaftar, tautan reset akan dikirim ke kotak masuk atau spam.';
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    final response = await _dio.get(
      '/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final root = _asMap(response.data);
    final profile = _asMap(root['data'] ?? root);
    if (_firstString(profile, ['id']) == null) {
      throw const FormatException(
        'Profil akun dari server belum lengkap. Silakan masuk kembali.',
      );
    }
    return profile;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/login',
      data: {'email': email, 'password': password},
    );

    return _parseSession(response.data, fallbackEmail: email);
  }

  Future<AuthSession> loginWithGoogleToken(String token) async {
    final response = await _dio.post('/google-login', data: {'token': token});

    return _parseSession(response.data);
  }

  AuthSession _parseSession(dynamic data, {String? fallbackEmail}) {
    final root = _asMap(data);
    final payload = _firstMap(root, const ['data', 'result', 'user']) ?? root;
    final nestedUser = _firstMap(payload, const ['user', 'profile']);

    final token =
        _firstString(payload, const [
          'token',
          'access_token',
          'accessToken',
          'jwt',
          'jwt_token',
        ]) ??
        _firstString(root, const [
          'token',
          'access_token',
          'accessToken',
          'jwt',
          'jwt_token',
        ]);

    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Token login tidak ditemukan di response API',
      );
    }

    final name =
        _firstString(payload, const [
          'name',
          'full_name',
          'fullName',
          'username',
        ]) ??
        _firstString(nestedUser, const [
          'name',
          'full_name',
          'fullName',
          'username',
        ]);

    final email =
        _firstString(payload, const ['email']) ??
        _firstString(nestedUser, const ['email']) ??
        fallbackEmail;

    return AuthSession(
      token: token,
      name: name,
      email: email,
      role:
          _firstString(payload, const ['role']) ??
          _firstString(root, const ['role']) ??
          'user',
      raw: root,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    throw const FormatException('Format response API tidak valid');
  }

  Map<String, dynamic>? _firstMap(
    Map<String, dynamic>? source,
    List<String> keys,
  ) {
    if (source == null) return null;

    for (final key in keys) {
      final value = source[key];
      if (value is Map<String, dynamic>) return value;
      if (value is Map) {
        return value.map(
          (nestedKey, nestedValue) =>
              MapEntry(nestedKey.toString(), nestedValue),
        );
      }
    }

    return null;
  }

  String? _firstString(Map<String, dynamic>? source, List<String> keys) {
    if (source == null) return null;

    for (final key in keys) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}
