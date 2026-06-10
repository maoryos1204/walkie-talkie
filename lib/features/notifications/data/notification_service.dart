import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/utils/logger.dart';
import 'package:shmuki_talk/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  AppLogger.notif('Background message: ${message.messageId}');
}

class NotificationService {
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static final _messaging = FirebaseMessaging.instance;

  static const _channelId = 'shmuki_talk_channel';
  static const _channelName = 'שמוקי טוק';
  static const _channelDesc = 'התראות מחדרי הקשר';

  static Future<void> initialize(WidgetRef ref) async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request permissions
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    AppLogger.notif('Notification permission: ${settings.authorizationStatus}');

    if (!kIsWeb) {
      await _initLocalNotifications();
    }

    // Get token and save
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveToken(ref, token);
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((token) => _saveToken(ref, token));

    // Foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Notification taps (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      AppLogger.notif('Notification opened: ${message.data}');
      // Navigate to room if roomId in data
    });
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDesc,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
          ),
        );
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;

    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: jsonEncode(message.data),
    );
  }

  static Future<void> _saveToken(WidgetRef ref, String token) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    await ref.read(authRepositoryProvider).updateFcmToken(user.uid, token);
    AppLogger.notif('FCM token saved for user: ${user.uid}');
  }

  static Future<void> clearBadge() async {
    await _localNotifications.cancelAll();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
