import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:medifinder/services/notification_service.dart';

class SocketNotificationService {
  late IO.Socket socket;

  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);

    await _localNotif.initialize(initSettings);
  }

  void connect() {
    socket = IO.io(
      'http://192.168.1.7:3000', // ganti
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.on('announcement:received', (data) {
      final title = data['senderName'] ?? 'Pengumuman';
      final body = data['message'] ?? '';

      NotificationService.show(title: title, body: body);
    });
  }

  Future<void> _showNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'medifinder_channel',
      'Medifinder Notification',
      importance: Importance.max,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotif.show(0, title, body, notificationDetails);
  }

  void dispose() {
    socket.disconnect();
    socket.dispose();
  }
}
