import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mobile and web both use backend JWTs; Google SDK accounts alone are not sessions.
class AuthSessionStore {
  AuthSessionStore({AuthApiService? api}) : _api = api ?? AuthApiService();
  final AuthApiService _api;

  Future<void> save(
    AuthSession session, {
    required String provider,
    bool rememberSession = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.setString('auth_provider', provider);
    await prefs.setString('full_name', session.name ?? '');
    await prefs.setString('username', session.name ?? session.email ?? '');
    await prefs.setString('email', session.email ?? '');
    await prefs.setString('profile_picture', session.picture ?? '');
    await prefs.setString('user_id', session.userId ?? '');
    await prefs.setString('role', session.role);
    await prefs.remove('password');
    await prefs.setBool('remember_session', rememberSession);
    // Write the JWT last so a partial profile write cannot create a valid session.
    await prefs.setString('auth_token', session.token);
  }

  static bool isUnexpired(String token, {DateTime? now}) {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || parts.any((part) => part.isEmpty)) return false;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['exp'] is! num) return false;
      final expires = DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as num).toInt() * 1000,
        isUtc: true,
      );
      return expires.isAfter(now ?? DateTime.now());
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) return false;
    if (!(prefs.getBool('remember_session') ?? true)) {
      await clear();
      return false;
    }
    if (!isUnexpired(token)) {
      await clear();
      return false;
    }
    try {
      final profile = await _api.getProfile(token);
      await save(
        AuthSession(token: token).withProfile(profile),
        provider: prefs.getString('auth_provider') ?? 'password',
      );
      return true;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      // Keep an unexpired cached session during a temporary outage. Protected
      // backend APIs continue to validate its signature and account permissions.
      if (status == null || status >= 500 || status == 429) return true;
      await clear();
      return false;
    } on FormatException {
      await clear();
      return false;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'auth_token',
      'auth_provider',
      'remember_session',
      'user_id',
      'role',
      'profile_picture',
      'username',
      'full_name',
      'display_name',
      'email',
      'password',
    ]) {
      await prefs.remove(key);
    }
  }
}
