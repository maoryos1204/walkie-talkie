import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/domain/entities/room.dart';

class RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo(context)),
              _buildStatus(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (room.imageURL != null && room.imageURL!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: room.imageURL!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => _emojiAvatar(),
          errorWidget: (_, __, ___) => _emojiAvatar(),
        ),
      );
    }
    return _emojiAvatar();
  }

  Widget _emojiAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          room.emoji,
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (room.isLocked)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: const Icon(
                  Icons.lock,
                  size: 14,
                  color: AppColors.statusOffline,
                ),
              ),
            Expanded(
              child: Text(
                room.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.people_outline, size: 14, color: AppColors.textHint),
            const SizedBox(width: 4),
            Text(
              '${room.participantCount}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (room.hasActiveSpeaker) ...[
              const SizedBox(width: 10),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.statusSpeaking,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${room.currentSpeakerName} מדבר',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.statusSpeaking,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          room.inviteCode,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (room.hasActiveSpeaker)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusSpeaking.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.statusSpeaking.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.statusSpeaking,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.statusSpeaking,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusOnline.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'פנוי',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.statusOnline,
              ),
            ),
          ),
        const SizedBox(height: 8),
        const Icon(
          Icons.chevron_left,
          color: AppColors.textHint,
          size: 18,
        ),
      ],
    );
  }
}
