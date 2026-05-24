import 'package:medifinder/config/api_config.dart';

class ObatViewData {
  const ObatViewData({
    required this.name,
    required this.stock,
    this.imageUrl,
  });

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

  factory ApotekViewData.fromMap(Map<String, dynamic> map) {
    final imagePath = _firstString(map, const [
      'foto_apotek',
      'photo_url',
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

    final jamBuka = _firstString(map, const ['jam_buka', 'open_time']);
    final jamTutup = _firstString(map, const ['jam_tutup', 'close_time']);
    final computedHours =
        jamBuka != null && jamTutup != null
            ? '$jamBuka - $jamTutup'
            : jamBuka ?? jamTutup;

    return ApotekViewData(
      id:
          _firstString(map, const ['id_apotek', 'id', '_id', 'apotek_id']) ??
          '',
      name:
          _firstString(map, const [
            'nama_apotek',
            'nama',
            'name',
            'title',
          ]) ??
          'Apotek tanpa nama',
      address:
          _firstString(map, const [
            'alamat',
            'address',
            'lokasi',
            'location',
          ]) ??
          'Alamat tidak tersedia',
      status:
          _firstString(map, const [
            'status_buka',
            'status',
            'open_status',
          ]) ??
          '',
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
        'phone_number',
        'telepon',
        'phone',
        'no_telp',
      ]),
      email: _firstString(map, const ['email']),
      description: _firstString(map, const [
        'deskripsi',
        'description',
        'keterangan',
      ]),
      medicines: medicinesRaw
          .map((item) => ObatViewData.fromMap(_ensureMap(item)))
          .toList(),
      raw: map,
    );
  }
}

Map<String, dynamic> _ensureMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return <String, dynamic>{};
}

String? _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
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

List<Map<String, dynamic>> _firstList(Map<String, dynamic> map, List<String> keys) {
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
