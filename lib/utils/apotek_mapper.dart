import 'package:flutter/material.dart';
import 'package:medifinder/config/api_config.dart';

/// Memeriksa apakah toko/apotek sedang buka berdasarkan string jam operasional.
/// Jika [jamBukaNullDiDB] true (artinya jam tidak diset di DB),
/// maka dianggap buka 24 jam — sesuai perilaku web frontend.
bool cekApakahBuka(String? jamOperasional, {bool jamBukaNullDiDB = false}) {
  // Jika jam tidak diatur di DB → anggap buka 24 jam (sesuai web index.vue:446)
  if (jamBukaNullDiDB) return true;

  if (jamOperasional == null || jamOperasional.trim().isEmpty) {
    // Tidak ada jam sama sekali → anggap buka (konsisten dengan web)
    return true;
  }

  final str = jamOperasional.toLowerCase().trim();

  // 1. Jika Buka 24 Jam
  if (str.contains('24 jam') ||
      str.contains('24 hours') ||
      str.contains('24jam')) {
    return true;
  }

  // 2. Pisahkan rentang waktu
  List<String> parts = [];
  if (str.contains('-')) {
    parts = str.split('-');
  } else if (str.contains('s/d')) {
    parts = str.split('s/d');
  } else if (str.contains('sampai')) {
    parts = str.split('sampai');
  }

  if (parts.length != 2) return false;

  try {
    TimeOfDay? parseTime(String timeStr) {
      final cleaned = timeStr.trim().replaceAll('.', ':');
      // Cocokkan jam & menit (misal 08:00) atau hanya jam (misal 08)
      final match = RegExp(r'(\d{1,2})(?::(\d{2}))?').firstMatch(cleaned);
      if (match != null) {
        final hour = int.parse(match.group(1)!);
        final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
      return null;
    }

    final start = parseTime(parts[0]);
    final end = parseTime(parts[1]);

    if (start == null || end == null) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Melewati tengah malam (misal 17:00 - 02:00)
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  } catch (_) {
    return false;
  }
}

class ObatViewData {
  const ObatViewData({required this.name, required this.stock, this.imageUrl});

  final String name;
  final int stock;
  final String? imageUrl;

  factory ObatViewData.fromMap(Map<String, dynamic> map) {
    final imagePath = _firstString(map, const [
      'gambar_obat',
      'foto_obat',
      'photo_url',
      'PhotoURL',
      'Gambar',
      'Foto',
      'image',
      'image_url',
      'foto',
    ]);

    return ObatViewData(
      name:
          _firstString(map, const [
            'nama_obat',
            'nama',
            'name',
            'Nama',
            'Name',
          ]) ??
          'Obat tidak diketahui',
      stock:
          _firstInt(map, const [
            'stok',
            'stock',
            'qty',
            'Stok',
            'Stock',
            'Qty',
          ]) ??
          0,
      imageUrl: _resolveImage(imagePath),
    );
  }
}

class ApotekViewData {
  const ApotekViewData({
    required this.id,
    required this.name,
    required this.address,
    required this.status,
    required this.hours,
    this.imageUrl,
    this.phone,
    this.email,
    this.description,
    this.medicines = const [],
    this.raw = const {},
    // Nilai asli jam_buka & jam_tutup dari DB (null = belum diatur)
    this.jamBukaRaw,
    this.jamTutupRaw,
    this.distance,
  });

  final String id;
  final String name;
  final String address;
  final String status;
  final String hours;
  final String? imageUrl;
  final String? phone;
  final String? email;
  final String? description;
  final List<ObatViewData> medicines;
  final Map<String, dynamic> raw;

  /// Nilai asli dari DB (null = admin belum mengisi jam operasional)
  final String? jamBukaRaw;
  final String? jamTutupRaw;

  /// Jarak dalam kilometer (dari endpoint /apotek/nearby)
  final double? distance;

  /// Getter untuk memeriksa apakah apotek sedang buka.
  /// Mengikuti logika web frontend:
  /// - Jika jam_buka & jam_tutup NULL di DB → anggap buka 24 jam
  /// - Jika jam diatur → hitung berdasarkan waktu sekarang
  bool get isBuka {
    final statusLower = status.toLowerCase().trim();
    if (statusLower == 'buka' || statusLower == 'open') return true;
    if (statusLower == 'tutup' || statusLower == 'closed') return false;

    // Jika jam tidak diatur di DB → anggap buka 24 jam (sesuai web)
    final jamTidakDiatur = (jamBukaRaw == null || jamBukaRaw!.isEmpty) &&
        (jamTutupRaw == null || jamTutupRaw!.isEmpty);

    return cekApakahBuka(hours, jamBukaNullDiDB: jamTidakDiatur);
  }

  factory ApotekViewData.fromMap(Map<String, dynamic> map) {
    // Backend mengembalikan: photo_url, nama, alamat, jam_buka, jam_tutup
    final imagePath = _firstString(map, const [
      'photo_url',   // <- backend field utama
      'foto_apotek',
      'gambar',
      'image',
      'image_url',
      'foto',
      'thumbnail',
    ]);

    final medicinesRaw = _firstList(map, const [
      'obats',
      'obat',
      'medicines',
      'products',
    ]);

    // Backend mengembalikan jam_buka & jam_tutup terpisah (misal: "08:00", "21:00")
    final jamBuka = _firstString(map, const ['jam_buka', 'open_time']);
    final jamTutup = _firstString(map, const ['jam_tutup', 'close_time']);
    final computedHours =
        jamBuka != null && jamTutup != null
            ? '$jamBuka - $jamTutup'
            : jamBuka ?? jamTutup;

    // Backend tidak punya field status eksplisit — isBuka akan dihitung dari hours
    final statusRaw =
        _firstString(map, const ['status_buka', 'status', 'open_status']) ?? '';

    return ApotekViewData(
      // Backend mengembalikan UUID sebagai 'id'
      id:
          _firstString(map, const ['id', 'id_apotek', '_id', 'apotek_id']) ??
          '',
      // Backend mengembalikan nama apotek sebagai 'nama'
      name:
          _firstString(map, const ['nama', 'nama_apotek', 'name', 'title']) ??
          'Apotek tanpa nama',
      address:
          _firstString(map, const [
            'alamat',
            'address',
            'lokasi',
            'location',
          ]) ??
          'Alamat tidak tersedia',
      status: statusRaw,
      hours:
          _firstString(map, const [
            'jam_operasional',
            'hours',
            'operational_hours',
          ]) ??
          computedHours ??
          '',
      imageUrl: _resolveImage(imagePath),
      phone: _firstString(map, const [
        'phone_number', // <- backend field
        'telepon',
        'phone',
        'no_telp',
      ]),
      email: _firstString(map, const ['email']),
      description: _firstString(map, const [
        'deskripsi', // <- backend field
        'description',
        'keterangan',
      ]),
      medicines:
          medicinesRaw
              .map((item) => ObatViewData.fromMap(_ensureMap(item)))
              .toList(),
      raw: map,
      // Simpan nilai asli dari DB untuk logika isBuka
      // null = admin belum mengisi → anggap buka 24 jam (sesuai web)
      jamBukaRaw: jamBuka,
      jamTutupRaw: jamTutup,
      distance: () {
        final d = map['distance'] ?? map['Distance'] ?? map['jarak'];
        if (d is num) return d.toDouble();
        if (d is String) return double.tryParse(d);
        return null;
      }(),
    );
  }
}

// Helper Functions
Map<String, dynamic> _ensureMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value != null) {
      final str = value.toString().trim();
      if (str.isNotEmpty) return str;
    }
  }
  return null;
}

int? _firstInt(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
  }
  return null;
}

List<Map<String, dynamic>> _firstList(
  Map<String, dynamic> map,
  List<String> keys,
) {
  for (final key in keys) {
    final value = map[key];
    if (value is List) {
      return value.map(_ensureMap).toList();
    }
  }
  return const [];
}

String? _resolveImage(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  if (path.startsWith('/public/') || path.startsWith('public/')) {
    final normalized = path.startsWith('/') ? path : '/$path';
    return '${ApiConfig.host}$normalized';
  }
  return ApiConfig.storageUrl(path);
}
