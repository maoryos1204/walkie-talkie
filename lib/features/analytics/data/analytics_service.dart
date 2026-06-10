import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/utils/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;
  final FirebaseFirestore _firestore;

  AnalyticsService({
    required FirebaseAnalytics analytics,
    required FirebaseFirestore firestore,
  })  : _analytics = analytics,
        _firestore = firestore;

  // Room events
  Future<void> logRoomJoined(String roomId) async {
    await _analytics.logEvent(name: 'room_joined');
    await _logAnonymous('room_session', roomId, 1);
  }

  Future<void> logRoomLeft(String roomId, Duration sessionDuration) async {
    await _analytics.logEvent(
      name: 'room_session_ended',
      parameters: {'duration_seconds': sessionDuration.inSeconds},
    );
    await _logAnonymous('room_session', roomId, sessionDuration.inSeconds);
  }

  Future<void> logPttPressed(String roomId) async {
    await _analytics.logEvent(name: 'ptt_pressed');
    await _logAnonymous('ptt_event', roomId, 1);
  }

  Future<void> logRoomCreated() async {
    await _analytics.logEvent(name: 'room_created');
  }

  Future<void> logParticipantCount(String roomId, int count) async {
    await _logAnonymous('participant_count', roomId, count);
  }

  // Log anonymous event to Firestore
  Future<void> _logAnonymous(
    String eventType,
    String roomId,
    int value,
  ) async {
    try {
      // Hash the roomId for privacy
      final hashedRoomId = roomId.hashCode.abs().toString();

      await _firestore.collection('analytics').add({
        'eventType': eventType,
        'roomId': hashedRoomId,
        'value': value,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      AppLogger.e('Analytics', 'Failed to log event', e);
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    analytics: FirebaseAnalytics.instance,
    firestore: FirebaseFirestore.instance,
  );
});
