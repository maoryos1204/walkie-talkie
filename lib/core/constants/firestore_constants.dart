abstract class FirestoreConstants {
  // Collections
  static const usersCollection = 'users';
  static const roomsCollection = 'rooms';
  static const analyticsCollection = 'analytics';

  // Sub-collections
  static const membersSubcollection = 'members';
  static const queueSubcollection = 'queue';
  static const webrtcSessionsSubcollection = 'webrtc_sessions';
  static const candidatesSubcollection = 'candidates';

  // User fields
  static const fieldUid = 'uid';
  static const fieldDisplayName = 'displayName';
  static const fieldEmail = 'email';
  static const fieldPhotoURL = 'photoURL';
  static const fieldCreatedAt = 'createdAt';
  static const fieldLastSeen = 'lastSeen';
  static const fieldFcmTokens = 'fcmTokens';
  static const fieldStatus = 'status';
  static const fieldCurrentRoomId = 'currentRoomId';
  static const fieldIsListenerOnly = 'isListenerOnly';
  static const fieldRooms = 'rooms';

  // Room fields
  static const fieldId = 'id';
  static const fieldName = 'name';
  static const fieldEmoji = 'emoji';
  static const fieldImageURL = 'imageURL';
  static const fieldInviteCode = 'inviteCode';
  static const fieldOwnerId = 'ownerId';
  static const fieldIsLocked = 'isLocked';
  static const fieldCurrentSpeakerId = 'currentSpeakerId';
  static const fieldCurrentSpeakerName = 'currentSpeakerName';
  static const fieldCurrentSpeakerPhotoURL = 'currentSpeakerPhotoURL';
  static const fieldSpeakerStartedAt = 'speakerStartedAt';
  static const fieldParticipantCount = 'participantCount';
  static const fieldListenerCount = 'listenerCount';
  static const fieldQueueCount = 'queueCount';
  static const fieldUpdatedAt = 'updatedAt';

  // Member fields
  static const fieldUserId = 'userId';
  static const fieldRole = 'role';
  static const fieldIsMuted = 'isMuted';
  static const fieldJoinedAt = 'joinedAt';

  // Queue fields
  static const fieldPriority = 'priority';
  static const fieldPosition = 'position';

  // WebRTC fields
  static const fieldOffer = 'offer';
  static const fieldAnswer = 'answer';
  static const fieldSpeakerId = 'speakerId';
  static const fieldState = 'state';
  static const fieldIsLocal = 'isLocal';
  static const fieldCandidate = 'candidate';

  // Status values
  static const statusOnline = 'online';
  static const statusOffline = 'offline';
  static const statusBusy = 'busy';
  static const statusSpeaking = 'speaking';
  static const statusInQueue = 'in_queue';

  // Role values
  static const roleOwner = 'owner';
  static const roleAdmin = 'admin';
  static const roleMember = 'member';

  // WebRTC states
  static const webrtcStatePending = 'pending';
  static const webrtcStateActive = 'active';
  static const webrtcStateEnded = 'ended';
}
