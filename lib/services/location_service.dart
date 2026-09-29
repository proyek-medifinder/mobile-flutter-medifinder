import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class UserLocation {
  final double lat;
  final double lng;
  final String addressName;

  UserLocation({
    required this.lat,
    required this.lng,
    required this.addressName,
  });
}

class LocationService {
  static final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'MediFinderMobile/1.0',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// Cek izin & ambil koordinat perangkat saat ini
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode dari lat, lng ke nama lokasi seperti web (Nominatim OpenStreetMap)
  static Future<String> getLocationName(double lat, double lng) async {
    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
        },
      );

      final data = response.data;
      if (data is Map && data['address'] is Map) {
        final address = data['address'] as Map;

        final kecamatan = (address['suburb'] ??
                address['village'] ??
                address['town'] ??
                address['city_district'] ??
                '')
            .toString()
            .trim();

        final kota = (address['city'] ??
                address['regency'] ??
                address['county'] ??
                '')
            .toString()
            .trim();

        final provinsi = (address['state'] ?? '').toString().trim();

        final parts = [kecamatan, kota, provinsi]
            .where((p) => p.isNotEmpty)
            .toList();

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {
      // Abaikan jika nominatim gagal / offline
    }

    return 'Lokasi Terdeteksi (${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)})';
  }

  /// Ambil lokasi lengkap (koordinat + nama)
  static Future<UserLocation?> fetchUserLocation() async {
    try {
      final pos = await getCurrentPosition();
      if (pos == null) return null;

      final name = await getLocationName(pos.latitude, pos.longitude);
      return UserLocation(
        lat: pos.latitude,
        lng: pos.longitude,
        addressName: name,
      );
    } catch (_) {
      return null;
    }
  }
}
