class ApiConfig {
  static const String host = 'https://medifinder.my.id/';
  static const String apiBase = '$host/api';

  static Uri apotek() => Uri.parse('$apiBase/apotek');
  static String storageUrl(String path) => "$host/storage/$path";
  
}