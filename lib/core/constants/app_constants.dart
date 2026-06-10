abstract class AppConstants {
  // PTT
  static const pttMinPressDuration = Duration(milliseconds: 300);
  static const pttDebounceDelay = Duration(milliseconds: 50);

  // Presence
  static const presenceHeartbeatInterval = Duration(seconds: 30);
  static const presenceOfflineThreshold = Duration(seconds: 90);

  // Room
  static const maxRoomParticipants = 50;
  static const maxRoomNameLength = 20;
  static const minRoomNameLength = 2;
  static const inviteCodeMinLength = 6;
  static const inviteCodeMaxLength = 8;

  // Queue
  static const normalQueuePriority = 0;
  static const adminQueuePriority = 10;

  // Deep Links
  static const deepLinkScheme = 'shmukitalk';
  static const deepLinkHost = 'room';
  static const webDeepLinkBase = 'https://shmukitalk.app/room';

  // WhatsApp
  static const whatsappShareUrl = 'https://wa.me/?text=';

  // Storage paths
  static const roomImagesPath = 'room_images';
  static const userAvatarsPath = 'user_avatars';

  // Animation
  static const voiceWaveAnimDuration = Duration(milliseconds: 800);
  static const pttPulseAnimDuration = Duration(milliseconds: 1200);

  // Cache
  static const avatarCacheMaxAge = Duration(days: 7);
  static const roomImageCacheMaxAge = Duration(days: 1);

  // Analytics
  static const analyticsSessionMinDuration = Duration(seconds: 5);

  // Emojis for room creation
  static const defaultRoomEmojis = [
    '👨‍👩‍👧‍👦',
    '👥',
    '⚽',
    '🏝',
    '🎉',
    '🏠',
    '🎸',
    '🚗',
    '✈️',
    '🎮',
    '🍕',
    '🐶',
    '🌙',
    '🏔️',
    '🎯',
    '💪',
  ];
}
