import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  static Future<void> requestWithoutContext() async {
    final permission = await Permission.notification.status;
    if (!permission.isGranted) {
      await Permission.notification.request();
    }
  }
}

