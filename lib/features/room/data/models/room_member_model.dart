import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shmuki_talk/core/constants/firestore_constants.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';

class RoomMemberModel extends RoomMember {
  const RoomMemberModel({
    required super.userId,
    required super.displayName,
    super.photoURL,
    super.role,
    super.isMuted,
    super.isListenerOnly,
    super.status,
    required super.joinedAt,
    required super.lastSeen,
  });

  factory RoomMemberModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomMemberModel(
      userId: data['userId'] as String? ?? doc.id,
      displayName: data['displayName'] as String? ?? '',
      photoURL: data['photoURL'] as String?,
      role: _parseRole(data['role'] as String?),
      isMuted: data['isMuted'] as bool? ?? false,
      isListenerOnly: data['isListenerOnly'] as bool? ?? false,
      status: _parseStatus(data['status'] as String?),
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static MemberRole _parseRole(String? role) {
    switch (role) {
      case FirestoreConstants.roleOwner:
        return MemberRole.owner;
      case FirestoreConstants.roleAdmin:
        return MemberRole.admin;
      default:
        return MemberRole.member;
    }
  }

  static MemberStatus _parseStatus(String? status) {
    switch (status) {
      case FirestoreConstants.statusOffline:
        return MemberStatus.offline;
      case FirestoreConstants.statusBusy:
        return MemberStatus.busy;
      case FirestoreConstants.statusSpeaking:
        return MemberStatus.speaking;
      case FirestoreConstants.statusInQueue:
        return MemberStatus.inQueue;
      default:
        return MemberStatus.online;
    }
  }

  String get roleString {
    switch (role) {
      case MemberRole.owner:
        return FirestoreConstants.roleOwner;
      case MemberRole.admin:
        return FirestoreConstants.roleAdmin;
      case MemberRole.member:
        return FirestoreConstants.roleMember;
    }
  }

  String get statusString {
    switch (status) {
      case MemberStatus.offline:
        return FirestoreConstants.statusOffline;
      case MemberStatus.busy:
        return FirestoreConstants.statusBusy;
      case MemberStatus.speaking:
        return FirestoreConstants.statusSpeaking;
      case MemberStatus.inQueue:
        return FirestoreConstants.statusInQueue;
      case MemberStatus.online:
        return FirestoreConstants.statusOnline;
    }
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'role': roleString,
        'isMuted': isMuted,
        'isListenerOnly': isListenerOnly,
        'status': statusString,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      };
}
