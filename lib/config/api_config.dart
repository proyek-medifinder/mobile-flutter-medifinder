class ApiConfig {
  static const String host = String.fromEnvironment(
    'MEDIFINDER_API_BASE',
    defaultValue: 'https://medifinder-backend-production.up.railway.app',
  );
  static const String apiBase = host;
  static const String authHost = host;
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '539021546127-kj6icorqjdrouo9n31tla5r2tcl90e7r.apps.googleusercontent.com',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static Uri apotek() => Uri.parse('$apiBase/superadmin/apotek');

  static String storageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$host/storage/$normalized';
  }
}
