import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:medifinder/config/api_config.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/services/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GoogleIdentityProvider {
  Future<String?> getIdToken();
  Future<void> signOut();
}

class NativeGoogleIdentity implements GoogleIdentityProvider {
  static Future<void>? _initialization;
  final GoogleSignIn _google = GoogleSignIn.instance;

  Future<void> _initialize() =>
      _initialization ??= _google.initialize(
        serverClientId: ApiConfig.googleClientId,
        clientId:
            ApiConfig.googleIosClientId.isNotEmpty &&
                    (defaultTargetPlatform == TargetPlatform.iOS ||
                        defaultTargetPlatform == TargetPlatform.macOS)
                ? ApiConfig.googleIosClientId
                : null,
      );

  @override
  Future<String?> getIdToken() async {
    await _initialize();
    if (!_google.supportsAuthenticate()) {
      throw UnsupportedError(
        'Login Google native belum tersedia pada platform ini.',
      );
    }
    try {
      final account = await _google.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        throw const FormatException(
          'Google tidak memberikan ID token. Periksa konfigurasi OAuth aplikasi.',
        );
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _initialize();
    await _google.signOut();
  }
}

class AuthService {
  AuthService({
    GoogleIdentityProvider? google,
    AuthApiService? api,
    AuthSessionStore? store,
  }) : _google = google ?? NativeGoogleIdentity(),
       _api = api ?? AuthApiService(),
       _store = store ?? AuthSessionStore();

  final GoogleIdentityProvider _google;
  final AuthApiService _api;
  final AuthSessionStore _store;

  Future<AuthSession?> signInWithGoogle() async {
    final idToken = await _google.getIdToken();
    if (idToken == null) return null;
    try {
      // Same contract as the web: Google ID token -> /google-login -> backend JWT.
      final session = await _api.loginWithGoogleToken(idToken);
      final profile = await _api.getProfile(session.token);
      return session.withProfile(profile);
    } catch (_) {
      try {
        await _google.signOut();
      } catch (_) {
        /* Backend rejection still wins. */
      }
      rethrow;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (prefs.getString('auth_provider') == 'google') await _google.signOut();
    } catch (_) {
      // Local logout must succeed even if Google services are unavailable.
    } finally {
      await _store.clear();
    }
  }
}
