import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shmuki_talk/features/auth/domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.displayName,
    required super.email,
    super.photoURL,
    required super.createdAt,
    required super.lastSeen,
    super.rooms,
    super.fcmTokens,
    super.status,
    super.currentRoomId,
    super.isListenerOnly,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoURL: data['photoURL'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      rooms: List<String>.from(data['rooms'] as List? ?? []),
      fcmTokens: List<String>.from(data['fcmTokens'] as List? ?? []),
      status: data['status'] as String? ?? 'offline',
      currentRoomId: data['currentRoomId'] as String?,
      isListenerOnly: data['isListenerOnly'] as bool? ?? false,
    );
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      photoURL: user.photoURL,
      createdAt: user.createdAt,
      lastSeen: user.lastSeen,
      rooms: user.rooms,
      fcmTokens: user.fcmTokens,
      status: user.status,
      currentRoomId: user.currentRoomId,
      isListenerOnly: user.isListenerOnly,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': FieldValue.serverTimestamp(),
      'rooms': rooms,
      'fcmTokens': fcmTokens,
      'status': status,
      'currentRoomId': currentRoomId,
      'isListenerOnly': isListenerOnly,
    };
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'lastSeen': FieldValue.serverTimestamp(),
      'rooms': [],
      'fcmTokens': [],
      'status': 'online',
      'currentRoomId': null,
      'isListenerOnly': false,
    };
  }
}
