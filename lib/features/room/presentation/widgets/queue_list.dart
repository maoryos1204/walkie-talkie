import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/providers/walkie_talkie_providers.dart';

class QueueList extends ConsumerWidget {
  final String roomId;

  const QueueList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(roomQueueProvider(roomId));
    final roomAsync = ref.watch(roomProvider(roomId));
    final user = ref.watch(currentUserProvider);

    return queueAsync.when(
      data: (queue) {
        if (queue.isEmpty) return const SizedBox.shrink();

        final isChannelBusy = roomAsync.valueOrNull?.hasActiveSpeaker ?? false;
        final isInQueue = queue.any((e) => e.userId == user?.uid);
        final wtState = ref.watch(walkieTalkieProvider(roomId));

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.queue, size: 16, color: AppColors.statusInQueue),
                      const SizedBox(width: 6),
                      Text(
                        '${AppStrings.speakingQueue} (${queue.length})',
                        style: const TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.statusInQueue,
                        ),
                      ),
                    ],
                  ),
                  if (!isInQueue && isChannelBusy && !wtState.isListenerOnly)
                    TextButton(
                      onPressed: () => ref
                          .read(walkieTalkieProvider(roomId).notifier)
                          .joinQueue(),
                      child: const Text(
                        AppStrings.joinQueue,
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  else if (isInQueue)
                    TextButton(
                      onPressed: () => ref
                          .read(walkieTalkieProvider(roomId).notifier)
                          .leaveQueue(),
                      child: const Text(
                        AppStrings.leaveQueue,
                        style: TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              ...queue.map((entry) {
                final isMe = entry.userId == user?.uid;
                return _QueueEntryTile(
                  entry: entry,
                  isMe: isMe,
                  position: entry.position,
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _QueueEntryTile extends StatelessWidget {
  final dynamic entry;
  final bool isMe;
  final int position;

  const _QueueEntryTile({
    required this.entry,
    required this.isMe,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.statusInQueue
                  : AppColors.statusInQueue.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isMe ? Colors.white : AppColors.statusInQueue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primaryContainer,
            backgroundImage: entry.photoURL != null
                ? CachedNetworkImageProvider(entry.photoURL!)
                : null,
            child: entry.photoURL == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isMe ? '${entry.displayName} (אתה)' : entry.displayName,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 13,
                fontWeight: isMe ? FontWeight.w600 : FontWeight.w400,
                color: isMe ? AppColors.statusInQueue : null,
              ),
            ),
          ),
          if (entry.isAdminPriority)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'עדיפות',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
