import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';

class RoomModel extends Room {
  const RoomModel({
    required super.id,
    required super.name,
    required super.emoji,
    super.imageURL,
    required super.inviteCode,
    required super.ownerId,
    super.isLocked,
    super.currentSpeakerId,
    super.currentSpeakerName,
    super.currentSpeakerPhotoURL,
    super.speakerStartedAt,
    super.participantCount,
    super.listenerCount,
    super.queueCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '📻',
      imageURL: data['imageURL'] as String?,
      inviteCode: data['inviteCode'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      isLocked: data['isLocked'] as bool? ?? false,
      currentSpeakerId: data['currentSpeakerId'] as String?,
      currentSpeakerName: data['currentSpeakerName'] as String?,
      currentSpeakerPhotoURL: data['currentSpeakerPhotoURL'] as String?,
      speakerStartedAt: (data['speakerStartedAt'] as Timestamp?)?.toDate(),
      participantCount: data['participantCount'] as int? ?? 0,
      listenerCount: data['listenerCount'] as int? ?? 0,
      queueCount: data['queueCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory RoomModel.fromEntity(Room room) => RoomModel(
        id: room.id,
        name: room.name,
        emoji: room.emoji,
        imageURL: room.imageURL,
        inviteCode: room.inviteCode,
        ownerId: room.ownerId,
        isLocked: room.isLocked,
        currentSpeakerId: room.currentSpeakerId,
        currentSpeakerName: room.currentSpeakerName,
        currentSpeakerPhotoURL: room.currentSpeakerPhotoURL,
        speakerStartedAt: room.speakerStartedAt,
        participantCount: room.participantCount,
        listenerCount: room.listenerCount,
        queueCount: room.queueCount,
        createdAt: room.createdAt,
        updatedAt: room.updatedAt,
      );

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'emoji': emoji,
        'imageURL': imageURL,
        'inviteCode': inviteCode,
        'ownerId': ownerId,
        'isLocked': isLocked,
        'currentSpeakerId': currentSpeakerId,
        'currentSpeakerName': currentSpeakerName,
        'currentSpeakerPhotoURL': currentSpeakerPhotoURL,
        'speakerStartedAt': speakerStartedAt != null
            ? Timestamp.fromDate(speakerStartedAt!)
            : null,
        'participantCount': participantCount,
        'listenerCount': listenerCount,
        'queueCount': queueCount,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
