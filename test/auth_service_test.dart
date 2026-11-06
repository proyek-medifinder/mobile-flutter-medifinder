import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medifinder/services/auth_api_service.dart';
import 'package:medifinder/services/auth_service.dart';
import 'package:medifinder/services/auth_session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeGoogleIdentity implements GoogleIdentityProvider {
  String? token = 'google-id-token';
  int signOutCalls = 0;
  bool failSignOut = false;
  @override
  Future<String?> getIdToken() async => token;
  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (failSignOut) throw StateError('Google offline');
  }
}

class CallbackAdapter implements HttpClientAdapter {
  CallbackAdapter(this.respond);
  final ResponseBody Function(RequestOptions) respond;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody response(Map<String, dynamic> data, [int status = 200]) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
String jwt(DateTime expiry) =>
    '${base64Url.encode(utf8.encode('{"alg":"HS256"}')).replaceAll('=', '')}.${base64Url.encode(utf8.encode(jsonEncode({'exp': expiry.millisecondsSinceEpoch ~/ 1000, 'user_id': 'backend-user'}))).replaceAll('=', '')}.signature';
AuthApiService apiWith(ResponseBody Function(RequestOptions) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://backend.example.invalid'));
  dio.httpClientAdapter = CallbackAdapter(handler);
  return AuthApiService(dio: dio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Google token uses web endpoint, then profile and backend JWT become the mobile session',
    () async {
      final backendToken = jwt(DateTime.now().add(const Duration(hours: 1)));
      final calls = <String>[];
      final api = apiWith((request) {
        calls.add('${request.method} ${request.path}');
        if (request.path == '/google-login') {
          expect(request.data, {'token': 'google-id-token'});
          return response({
            'token': backendToken,
            'name': 'Old name',
            'email': 'user@example.invalid',
            'role': 'user',
          });
        }
        expect(request.path, '/me');
        expect(request.headers['Authorization'], 'Bearer $backendToken');
        return response({
          'data': {
            'id': 'backend-user',
            'name': 'Nama Backend',
            'email': 'user@example.invalid',
            'role': 'user',
            'profile_picture': 'https://images.example.invalid/avatar.jpg',
          },
        });
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('password', 'legacy-password');
      final session =
          await AuthService(
            google: FakeGoogleIdentity(),
            api: api,
          ).signInWithGoogle();
      expect(session, isNotNull);
      await AuthSessionStore(api: api).save(session!, provider: 'google');
      expect(calls, ['POST /google-login', 'GET /me']);
      expect(prefs.getString('auth_token'), backendToken);
      expect(prefs.getString('auth_provider'), 'google');
      expect(prefs.getString('full_name'), 'Nama Backend');
      expect(
        prefs.getString('profile_picture'),
        'https://images.example.invalid/avatar.jpg',
      );
      expect(prefs.getString('user_id'), 'backend-user');
      expect(prefs.containsKey('password'), isFalse);
    },
  );
  test(
    'canceling Google selection does not call the backend or create a session',
    () async {
      final google = FakeGoogleIdentity()..token = null;
      final api = apiWith(
        (_) => throw StateError('Backend should not be called'),
      );
      expect(
        await AuthService(google: google, api: api).signInWithGoogle(),
        isNull,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    },
  );
  test(
    'backend rejection signs out Google and does not create a local session',
    () async {
      final google = FakeGoogleIdentity();
      final api = apiWith(
        (_) => response({'error': 'akun dinonaktifkan'}, 403),
      );
      await expectLater(
        AuthService(google: google, api: api).signInWithGoogle(),
        throwsA(isA<DioException>()),
      );
      expect(google.signOutCalls, 1);
      expect(
        (await SharedPreferences.getInstance()).getString('auth_token'),
        isNull,
      );
    },
  );
  test('missing backend JWT cannot produce a successful login', () async {
    final api = apiWith((_) => response({'name': 'Google user'}));
    await expectLater(
      AuthService(google: FakeGoogleIdentity(), api: api).signInWithGoogle(),
      throwsA(isA<FormatException>()),
    );
  });
  test('unauthorized profile blocks login after token exchange', () async {
    final api = apiWith(
      (request) =>
          request.path == '/google-login'
              ? response({'token': 'backend-token', 'name': 'User'})
              : response({'error': 'unauthorized'}, 401),
    );
    final google = FakeGoogleIdentity();
    await expectLater(
      AuthService(google: google, api: api).signInWithGoogle(),
      throwsA(isA<DioException>()),
    );
    expect(google.signOutCalls, 1);
  });
  test(
    'Google account metadata without backend JWT does not restore a session',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_provider': 'google',
        'email': 'legacy@example.invalid',
      });
      final api = apiWith(
        (_) => throw StateError('Backend should not be called'),
      );
      expect(await AuthSessionStore(api: api).restore(), isFalse);
    },
  );
  test(
    'expired or malformed backend JWT is cleared without contacting backend',
    () async {
      for (final token in [
        'invalid',
        jwt(DateTime.now().subtract(const Duration(hours: 1))),
      ]) {
        SharedPreferences.setMockInitialValues({
          'auth_token': token,
          'auth_provider': 'google',
          'profile_picture': 'old',
        });
        final api = apiWith(
          (_) => throw StateError('Backend should not be called'),
        );
        expect(await AuthSessionStore(api: api).restore(), isFalse);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          isNull,
        );
      }
    },
  );
  test('restoration updates profile from the backend', () async {
    final token = jwt(DateTime.now().add(const Duration(hours: 1)));
    SharedPreferences.setMockInitialValues({
      'auth_token': token,
      'auth_provider': 'google',
      'full_name': 'Old',
    });
    final api = apiWith(
      (_) => response({
        'data': {
          'id': 'backend-user',
          'name': 'Updated',
          'email': 'new@example.invalid',
          'role': 'user',
        },
      }),
    );
    expect(await AuthSessionStore(api: api).restore(), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getString('full_name'),
      'Updated',
    );
  });
  test(
    'revoked backend session is cleared while temporary outages preserve the cache',
    () async {
      final token = jwt(DateTime.now().add(const Duration(hours: 1)));
      for (final status in [401, 403, 404, 503]) {
        SharedPreferences.setMockInitialValues({
          'auth_token': token,
          'auth_provider': 'google',
        });
        final api = apiWith((_) => response({'error': 'unavailable'}, status));
        expect(await AuthSessionStore(api: api).restore(), status == 503);
        expect(
          (await SharedPreferences.getInstance()).getString('auth_token'),
          status == 503 ? token : null,
        );
      }
    },
  );
  test(
    'logout clears all backend and Google metadata even when Google sign-out fails',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'old',
        'auth_provider': 'google',
        'email': 'old@example.invalid',
        'profile_picture': 'old',
        'user_id': 'old',
        'role': 'user',
      });
      final google = FakeGoogleIdentity()..failSignOut = true;
      await AuthService(google: google).signOut();
      final prefs = await SharedPreferences.getInstance();
      for (final key in [
        'auth_token',
        'auth_provider',
        'email',
        'profile_picture',
        'user_id',
        'role',
      ]) {
        expect(prefs.containsKey(key), isFalse);
      }
    },
  );
}
