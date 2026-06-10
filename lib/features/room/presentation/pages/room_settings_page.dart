import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shmuki_talk/core/constants/app_constants.dart';
import 'package:shmuki_talk/core/extensions/build_context_extension.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/room/domain/entities/room_member.dart';
import 'package:shmuki_talk/features/room/data/repositories/room_repository_impl.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomSettingsPage extends ConsumerWidget {
  final String roomId;

  const RoomSettingsPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomProvider(roomId));
    final membersAsync = ref.watch(roomMembersProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider(roomId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.roomSettings),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: roomAsync.when(
        data: (room) => ListView(
          children: [
            _buildInviteSection(context, room.inviteCode, room.id),
            const Divider(),
            if (isAdmin) _buildAdminControls(context, ref, room, isAdmin),
            if (isAdmin) const Divider(),
            membersAsync.when(
              data: (members) => _buildMembersList(
                context,
                ref,
                members,
                user?.uid ?? '',
                isAdmin,
                room.ownerId,
              ),
              loading: () => const ListTile(title: LinearProgressIndicator()),
              error: (e, _) => ListTile(title: Text(e.toString())),
            ),
            const Divider(),
            _buildLeaveButton(context, ref),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildInviteSection(
    BuildContext context,
    String inviteCode,
    String roomId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.inviteCode, style: context.textTheme.titleMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  inviteCode,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppColors.primary),
                      tooltip: AppStrings.copyCode,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.codeCopied),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: AppColors.primary),
                      tooltip: AppStrings.shareInvite,
                      onPressed: () => _shareInvite(context, inviteCode, roomId),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Text('📱', style: TextStyle(fontSize: 18)),
                  label: const Text(AppStrings.whatsappShare),
                  onPressed: () => _shareViaWhatsapp(inviteCode, roomId),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminControls(
    BuildContext context,
    WidgetRef ref,
    dynamic room,
    bool isAdmin,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ניהול חדר',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: room.isLocked,
            onChanged: (value) async {
              await ref.read(roomRepositoryProvider).lockRoom(roomId, value);
            },
            title: Text(room.isLocked ? AppStrings.roomIsLocked : AppStrings.roomIsUnlocked),
            secondary: Icon(
              room.isLocked ? Icons.lock : Icons.lock_open,
              color: room.isLocked ? AppColors.error : AppColors.statusOnline,
            ),
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList(
    BuildContext context,
    WidgetRef ref,
    List<RoomMember> members,
    String currentUserId,
    bool isAdmin,
    String ownerId,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.members} (${members.length})',
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...members.map((member) => _MemberTile(
                member: member,
                roomId: roomId,
                currentUserId: currentUserId,
                isCurrentUserAdmin: isAdmin,
                ownerId: ownerId,
              )),
        ],
      ),
    );
  }

  Widget _buildLeaveButton(BuildContext context, WidgetRef ref) {
    final user = ref.read(currentUserProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        icon: const Icon(Icons.exit_to_app, color: AppColors.error),
        label: const Text(
          AppStrings.leaveRoom,
          style: TextStyle(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
        ),
        onPressed: () => _showLeaveConfirmation(context, ref, user?.uid ?? ''),
      ),
    );
  }

  void _showLeaveConfirmation(BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.leaveRoom),
        content: const Text(AppStrings.leaveRoomConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(roomRepositoryProvider).leaveRoom(roomId, userId);
              if (context.mounted) context.go('/home');
            },
            child: const Text(AppStrings.leave),
          ),
        ],
      ),
    );
  }

  void _shareInvite(BuildContext context, String inviteCode, String roomId) {
    final message = AppStrings.shareRoomMessage
        .replaceAll('{code}', inviteCode)
        .replaceAll(
            '{link}', '${AppConstants.webDeepLinkBase}/$inviteCode');
    Share.share(message);
  }

  void _shareViaWhatsapp(String inviteCode, String roomId) {
    final message = Uri.encodeComponent(
      AppStrings.shareRoomMessage
          .replaceAll('{code}', inviteCode)
          .replaceAll('{link}', '${AppConstants.webDeepLinkBase}/$inviteCode'),
    );
    launchUrl(
      Uri.parse('${AppConstants.whatsappShareUrl}$message'),
      mode: LaunchMode.externalApplication,
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final RoomMember member;
  final String roomId;
  final String currentUserId;
  final bool isCurrentUserAdmin;
  final String ownerId;

  const _MemberTile({
    required this.member,
    required this.roomId,
    required this.currentUserId,
    required this.isCurrentUserAdmin,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = member.userId == currentUserId;
    final statusColor = switch (member.status) {
      MemberStatus.online => AppColors.statusOnline,
      MemberStatus.offline => AppColors.statusOffline,
      MemberStatus.busy => AppColors.statusBusy,
      MemberStatus.speaking => AppColors.statusSpeaking,
      MemberStatus.inQueue => AppColors.statusInQueue,
    };

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
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
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: const Border.fromBorderSide(
                  BorderSide(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isMe ? '${member.displayName} (אתה)' : member.displayName,
              style: context.textTheme.titleMedium,
            ),
          ),
          if (member.isOwner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'בעלים',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.accentDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (member.isAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'מנהל',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (member.isMuted)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.mic_off, size: 14, color: AppColors.error),
            ),
        ],
      ),
      subtitle: Text(
        member.statusLabel,
        style: TextStyle(
          fontSize: 12,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: !isMe && isCurrentUserAdmin
          ? PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (action) =>
                  _handleMemberAction(context, ref, action),
              itemBuilder: (context) => [
                if (!member.isMuted)
                  const PopupMenuItem(
                    value: 'mute',
                    child: Text(AppStrings.muteUser),
                  )
                else
                  const PopupMenuItem(
                    value: 'unmute',
                    child: Text(AppStrings.unmuteUser),
                  ),
                if (!member.isAdmin)
                  const PopupMenuItem(
                    value: 'make_admin',
                    child: Text(AppStrings.makeAdmin),
                  )
                else if (!member.isOwner)
                  const PopupMenuItem(
                    value: 'remove_admin',
                    child: Text(AppStrings.removeAdmin),
                  ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text(
                    AppStrings.removeMember,
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  void _handleMemberAction(BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(roomRepositoryProvider);

    switch (action) {
      case 'mute':
        await repo.muteMember(roomId, member.userId, true);
      case 'unmute':
        await repo.muteMember(roomId, member.userId, false);
      case 'make_admin':
        await repo.updateMemberRole(roomId, member.userId, MemberRole.admin);
      case 'remove_admin':
        await repo.updateMemberRole(roomId, member.userId, MemberRole.member);
      case 'remove':
        await repo.removeMember(roomId, member.userId);
    }
  }
}
