import 'package:flutter/foundation.dart';

abstract class AppLogger {
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔵 [$tag] $message');
    }
  }

  static void i(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟢 [$tag] $message');
    }
  }

  static void w(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🟡 [$tag] $message');
    }
  }

  static void e(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔴 [$tag] $message');
      if (error != null) debugPrint('  Error: $error');
      if (stackTrace != null) debugPrint('  Stack: $stackTrace');
    }
  }

  static void webrtc(String message) => d('WebRTC', message);
  static void auth(String message) => d('Auth', message);
  static void room(String message) => d('Room', message);
  static void presence(String message) => d('Presence', message);
  static void queue(String message) => d('Queue', message);
  static void notif(String message) => d('Notification', message);
}
