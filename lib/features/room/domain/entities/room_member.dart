import 'package:equatable/equatable.dart';

enum MemberRole { owner, admin, member }
enum MemberStatus { online, offline, busy, speaking, inQueue }

class RoomMember extends Equatable {
  final String userId;
  final String displayName;
  final String? photoURL;
  final MemberRole role;
  final bool isMuted;
  final bool isListenerOnly;
  final MemberStatus status;
  final DateTime joinedAt;
  final DateTime lastSeen;

  const RoomMember({
    required this.userId,
    required this.displayName,
    this.photoURL,
    this.role = MemberRole.member,
    this.isMuted = false,
    this.isListenerOnly = false,
    this.status = MemberStatus.online,
    required this.joinedAt,
    required this.lastSeen,
  });

  bool get isOwner => role == MemberRole.owner;
  bool get isAdmin => role == MemberRole.admin || role == MemberRole.owner;
  bool get isSpeaking => status == MemberStatus.speaking;
  bool get isInQueue => status == MemberStatus.inQueue;
  bool get isOnline => status != MemberStatus.offline;

  String get statusLabel {
    switch (status) {
      case MemberStatus.online:
        return 'מחובר';
      case MemberStatus.offline:
        return 'לא מחובר';
      case MemberStatus.busy:
        return 'עסוק';
      case MemberStatus.speaking:
        return 'מדבר';
      case MemberStatus.inQueue:
        return 'בתור';
    }
  }

  String get roleLabel {
    switch (role) {
      case MemberRole.owner:
        return 'בעלים';
      case MemberRole.admin:
        return 'מנהל';
      case MemberRole.member:
        return 'חבר';
    }
  }

  RoomMember copyWith({
    MemberRole? role,
    bool? isMuted,
    bool? isListenerOnly,
    MemberStatus? status,
    DateTime? lastSeen,
  }) {
    return RoomMember(
      userId: userId,
      displayName: displayName,
      photoURL: photoURL,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isListenerOnly: isListenerOnly ?? this.isListenerOnly,
      status: status ?? this.status,
      joinedAt: joinedAt,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, role, isMuted, isListenerOnly, status];
}
