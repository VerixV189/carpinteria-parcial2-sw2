import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PushNotificationService {
  static const MethodChannel _channel =
      MethodChannel('carpinteria/push_notifications');
  static bool _permissionRequested = false;

  /// Solicita permiso de notificaciones en Android 13+ (API 33+)
  static Future<void> requestPermissionIfNeeded() async {
    if (kIsWeb || _permissionRequested) return;
    _permissionRequested = true;
    try {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  /// Dispara una notificación push nativa en la barra de estado del dispositivo
  static Future<void> showSystemPush({
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    try {
      await requestPermissionIfNeeded();
      await _channel.invokeMethod('showPushNotification', {
        'title': title,
        'body': body,
      });
    } catch (_) {}
  }
}

