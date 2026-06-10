import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/widgets/voice_animation.dart';

class SpeakerDisplay extends ConsumerWidget {
  final String roomId;

  const SpeakerDisplay({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));

    return roomAsync.when(
      data: (room) {
        if (!room.hasActiveSpeaker) {
          return _buildNoSpeaker(context);
        }
        return _buildActiveSpeaker(
          context,
          room.currentSpeakerName ?? '',
          room.currentSpeakerPhotoURL,
        );
      },
      loading: () => const SizedBox(height: 120),
      error: (_, __) => const SizedBox(height: 120),
    );
  }

  Widget _buildNoSpeaker(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 3,
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.mic_none,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.channelFree,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.statusOnline,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.holdToTalk,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 13,
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSpeaker(
    BuildContext context,
    String speakerName,
    String? photoURL,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            const VoiceAnimation(size: 120),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.statusSpeaking, width: 3),
                color: AppColors.primaryContainer,
              ),
              child: ClipOval(
                child: photoURL != null && photoURL.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoURL,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _buildInitialAvatar(speakerName),
                      )
                    : _buildInitialAvatar(speakerName),
              ),
            ),
            Positioned(
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusSpeaking,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.mic, size: 12, color: Colors.white),
                    SizedBox(width: 3),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.currentSpeaker,
          style: TextStyle(
            fontFamily: 'Rubik',
            fontSize: 12,
            color: AppColors.textHint,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          speakerName,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.statusSpeaking,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 2000.ms, color: AppColors.waveActive),
      ],
    );
  }

  Widget _buildInitialAvatar(String name) {
    return Container(
      color: AppColors.primaryContainer,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
