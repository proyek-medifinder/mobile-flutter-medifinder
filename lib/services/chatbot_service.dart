import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:medifinder/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatPharmacy {
  final String apotekId;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double harga;
  final int stok;
  final String jamBuka;
  final String jamTutup;
  final bool isOpen;

  ChatPharmacy({
    required this.apotekId,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.harga,
    required this.stok,
    required this.jamBuka,
    required this.jamTutup,
    required this.isOpen,
  });

  factory ChatPharmacy.fromMap(Map<String, dynamic> map) {
    return ChatPharmacy(
      apotekId: map['apotek_id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? 'Apotek',
      alamat: map['alamat']?.toString() ?? '',
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      distanceKm: (map['distance_km'] is num) ? (map['distance_km'] as num).toDouble() : 0.0,
      harga: (map['harga'] is num) ? (map['harga'] as num).toDouble() : 0.0,
      stok: (map['stok'] is num) ? (map['stok'] as num).toInt() : 0,
      jamBuka: map['jam_buka']?.toString() ?? '',
      jamTutup: map['jam_tutup']?.toString() ?? '',
      isOpen: map['is_open'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apotek_id': apotekId,
      'nama': nama,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'distance_km': distanceKm,
      'harga': harga,
      'stok': stok,
      'jam_buka': jamBuka,
      'jam_tutup': jamTutup,
      'is_open': isOpen,
    };
  }
}

class ChatResponseData {
  final String reply;
  final String medicineName;
  final String availability; // NEARBY, OUTSIDE_RADIUS, EMPTY, NO_MEDICINE_NEEDED
  final bool isNearby;
  final List<ChatPharmacy> pharmacies;

  ChatResponseData({
    required this.reply,
    required this.medicineName,
    required this.availability,
    required this.isNearby,
    required this.pharmacies,
  });

  factory ChatResponseData.fromMap(Map<String, dynamic> map) {
    final rawPharmacies = map['pharmacies'];
    List<ChatPharmacy> pharms = [];
    if (rawPharmacies is List) {
      pharms = rawPharmacies
          .map((p) => ChatPharmacy.fromMap(p as Map<String, dynamic>))
          .toList();
    }

    return ChatResponseData(
      reply: map['reply']?.toString() ?? '',
      medicineName: map['medicine_name']?.toString() ?? '',
      availability: map['availability']?.toString() ?? 'NO_MEDICINE_NEEDED',
      isNearby: map['is_nearby'] == true,
      pharmacies: pharms,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reply': reply,
      'medicine_name': medicineName,
      'availability': availability,
      'is_nearby': isNearby,
      'pharmacies': pharmacies.map((p) => p.toMap()).toList(),
    };
  }
}

class ChatMessage {
  final String id;
  final String sender; // 'user' | 'bot'
  final String text;
  final DateTime timestamp;
  final ChatResponseData? data;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    this.data,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      sender: map['sender']?.toString() ?? 'bot',
      text: map['text']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: map['data'] != null && map['data'] is Map<String, dynamic>
          ? ChatResponseData.fromMap(map['data'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'data': data?.toMap(),
    };
  }
}

class ChatbotApiService {
  final ApiClient _client;

  ChatbotApiService(this._client);

  static const String _storageKeyMessages = 'medibot_mobile_history';
  static const String _storageKeyAgeGroup = 'medibot_mobile_age_group';
  static const String _storageKeyAge = 'medibot_mobile_age';

  Future<ChatResponseData> sendMessage({
    required String message,
    String? ageGroup,
    int? age,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client.dio.post(
        '/api/chat',
        data: {
          'message': message,
          'age_group': ageGroup ?? '',
          'age': age ?? 0,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 15),
        ),
      );

      if (response.data is Map<String, dynamic>) {
        return ChatResponseData.fromMap(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Format respon tidak sesuai');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorMsg = e.response?.data['error']?.toString();
        if (errorMsg != null && errorMsg.isNotEmpty) {
          throw Exception(errorMsg);
        }
      }
      throw Exception('Gagal menghubungi asisten MediBot. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  // Simpan riwayat chat ke SharedPreferences
  Future<void> saveHistory({
    required List<ChatMessage> messages,
    required String ageGroup,
    required int age,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = messages.map((m) => m.toMap()).toList();
      await prefs.setString(_storageKeyMessages, jsonEncode(list));
      await prefs.setString(_storageKeyAgeGroup, ageGroup);
      await prefs.setInt(_storageKeyAge, age);
    } catch (_) {}
  }

  // Ambil riwayat chat tersimpan
  Future<Map<String, dynamic>?> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStr = prefs.getString(_storageKeyMessages);
      final ageGroup = prefs.getString(_storageKeyAgeGroup) ?? '';
      final age = prefs.getInt(_storageKeyAge) ?? 0;

      if (savedStr != null && savedStr.isNotEmpty) {
        final rawList = jsonDecode(savedStr) as List<dynamic>;
        final messages = rawList
            .map((item) => ChatMessage.fromMap(item as Map<String, dynamic>))
            .toList();
        return {
          'messages': messages,
          'ageGroup': ageGroup,
          'age': age,
        };
      }
    } catch (_) {}
    return null;
  }

  // Bersihkan riwayat chat
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKeyMessages);
      await prefs.remove(_storageKeyAgeGroup);
      await prefs.remove(_storageKeyAge);
    } catch (_) {}
  }
}
