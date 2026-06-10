import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';

class ParticipantList extends ConsumerWidget {
  final String roomId;

  const ParticipantList({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(roomMembersProvider(roomId));

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) return const SizedBox.shrink();

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
                children: [
                  const Icon(Icons.people, size: 16, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text(
                    '${AppStrings.participants} (${members.length})',
                    style: const TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members
                    .map((m) => _ParticipantChip(member: m))
                    .toList(),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ParticipantChip extends StatelessWidget {
  final RoomMember member;

  const _ParticipantChip({required this.member});

  Color get _statusColor => switch (member.status) {
        MemberStatus.online => AppColors.statusOnline,
        MemberStatus.offline => AppColors.statusOffline,
        MemberStatus.busy => AppColors.statusBusy,
        MemberStatus.speaking => AppColors.statusSpeaking,
        MemberStatus.inQueue => AppColors.statusInQueue,
      };

  String get _statusEmoji => switch (member.status) {
        MemberStatus.online => '🟢',
        MemberStatus.offline => '🔴',
        MemberStatus.busy => '🟠',
        MemberStatus.speaking => '🎤',
        MemberStatus.inQueue => '🟡',
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '${member.displayName} — ${member.statusLabel}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _statusColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: AppColors.primaryContainer,
                  backgroundImage: member.photoURL != null
                      ? CachedNetworkImageProvider(member.photoURL!)
                      : null,
                  child: member.photoURL == null
                      ? Text(
                          member.displayName.isNotEmpty
                              ? member.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.primary),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 5),
            Text(
              member.displayName.split(' ').first,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _statusColor,
              ),
              maxLines: 1,
            ),
            const SizedBox(width: 4),
            Text(_statusEmoji, style: const TextStyle(fontSize: 10)),
            if (member.isMuted)
              const Padding(
                padding: EdgeInsets.only(right: 2),
                child: Icon(Icons.mic_off, size: 10, color: AppColors.error),
              ),
          ],
        ),
      ),
    );
  }
}
