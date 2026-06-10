import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';

class ChannelStatusWidget extends ConsumerWidget {
  final String roomId;

  const ChannelStatusWidget({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));

    return roomAsync.when(
      data: (room) {
        final isBusy = room.hasActiveSpeaker;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isBusy
                ? AppColors.statusSpeaking.withOpacity(0.12)
                : AppColors.statusOnline.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isBusy
                  ? AppColors.statusSpeaking.withOpacity(0.4)
                  : AppColors.statusOnline.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isBusy ? AppColors.statusSpeaking : AppColors.statusOnline,
                  shape: BoxShape.circle,
                ),
              )
                  .animate(
                    onPlay: (c) => isBusy ? c.repeat() : null,
                  )
                  .scaleXY(
                    end: isBusy ? 1.5 : 1.0,
                    duration: 600.ms,
                  )
                  .then()
                  .scaleXY(end: 1.0, duration: 600.ms),
              const SizedBox(width: 8),
              Text(
                isBusy ? AppStrings.channelBusy : AppStrings.channelFree,
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isBusy ? AppColors.statusSpeaking : AppColors.statusOnline,
                  letterSpacing: 2.0,
                ),
              ),
              if (isBusy) ...[
                const SizedBox(width: 8),
                Text(
                  '· ${room.currentSpeakerName}',
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 12,
                    color: AppColors.statusSpeaking,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox(height: 36),
    );
  }
}
