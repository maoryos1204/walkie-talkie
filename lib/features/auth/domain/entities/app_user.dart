import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String displayName;
  final String email;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastSeen;
  final List<String> rooms;
  final List<String> fcmTokens;
  final String status;
  final String? currentRoomId;
  final bool isListenerOnly;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoURL,
    required this.createdAt,
    required this.lastSeen,
    this.rooms = const [],
    this.fcmTokens = const [],
    this.status = 'online',
    this.currentRoomId,
    this.isListenerOnly = false,
  });

  AppUser copyWith({
    String? displayName,
    String? email,
    String? photoURL,
    DateTime? lastSeen,
    List<String>? rooms,
    List<String>? fcmTokens,
    String? status,
    String? currentRoomId,
    bool? isListenerOnly,
  }) {
    return AppUser(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      rooms: rooms ?? this.rooms,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      status: status ?? this.status,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      isListenerOnly: isListenerOnly ?? this.isListenerOnly,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        displayName,
        email,
        photoURL,
        createdAt,
        lastSeen,
        rooms,
        fcmTokens,
        status,
        currentRoomId,
        isListenerOnly,
      ];
}
