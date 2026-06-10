import 'package:equatable/equatable.dart';

class Room extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final String? imageURL;
  final String inviteCode;
  final String ownerId;
  final bool isLocked;
  final String? currentSpeakerId;
  final String? currentSpeakerName;
  final String? currentSpeakerPhotoURL;
  final DateTime? speakerStartedAt;
  final int participantCount;
  final int listenerCount;
  final int queueCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Room({
    required this.id,
    required this.name,
    required this.emoji,
    this.imageURL,
    required this.inviteCode,
    required this.ownerId,
    this.isLocked = false,
    this.currentSpeakerId,
    this.currentSpeakerName,
    this.currentSpeakerPhotoURL,
    this.speakerStartedAt,
    this.participantCount = 0,
    this.listenerCount = 0,
    this.queueCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasActiveSpeaker => currentSpeakerId != null && currentSpeakerId!.isNotEmpty;

  Room copyWith({
    String? name,
    String? emoji,
    String? imageURL,
    bool? isLocked,
    String? currentSpeakerId,
    String? currentSpeakerName,
    String? currentSpeakerPhotoURL,
    DateTime? speakerStartedAt,
    int? participantCount,
    int? listenerCount,
    int? queueCount,
    DateTime? updatedAt,
  }) {
    return Room(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      imageURL: imageURL ?? this.imageURL,
      inviteCode: inviteCode,
      ownerId: ownerId,
      isLocked: isLocked ?? this.isLocked,
      currentSpeakerId: currentSpeakerId ?? this.currentSpeakerId,
      currentSpeakerName: currentSpeakerName ?? this.currentSpeakerName,
      currentSpeakerPhotoURL: currentSpeakerPhotoURL ?? this.currentSpeakerPhotoURL,
      speakerStartedAt: speakerStartedAt ?? this.speakerStartedAt,
      participantCount: participantCount ?? this.participantCount,
      listenerCount: listenerCount ?? this.listenerCount,
      queueCount: queueCount ?? this.queueCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        imageURL,
        inviteCode,
        ownerId,
        isLocked,
        currentSpeakerId,
        currentSpeakerName,
        participantCount,
        listenerCount,
        queueCount,
        updatedAt,
      ];
}
