import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shmuki_talk/core/extensions/build_context_extension.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/router/app_router.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/auth/presentation/providers/auth_providers.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';
import 'package:shmuki_talk/features/room/presentation/widgets/participant_list.dart';
import 'package:shmuki_talk/features/room/presentation/widgets/queue_list.dart';
import 'package:shmuki_talk/features/room/presentation/widgets/speaker_display.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/providers/walkie_talkie_providers.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/widgets/ptt_button.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/widgets/channel_status.dart';

class RoomPage extends ConsumerStatefulWidget {
  final String roomId;

  const RoomPage({super.key, required this.roomId});

  @override
  ConsumerState<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends ConsumerState<RoomPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walkieTalkieProvider(widget.roomId).notifier).initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(walkieTalkieProvider(widget.roomId).notifier).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(walkieTalkieProvider(widget.roomId).notifier).onBackground();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(walkieTalkieProvider(widget.roomId).notifier).onForeground();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);

    return roomAsync.when(
      data: (room) => Scaffold(
        backgroundColor: context.colorScheme.surfaceContainerHighest,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, room.name, room.emoji, room.imageURL,
                  room.participantCount, room.listenerCount),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      ChannelStatusWidget(roomId: widget.roomId),
                      const SizedBox(height: 20),
                      SpeakerDisplay(roomId: widget.roomId),
                      const SizedBox(height: 28),
                      PttButton(roomId: widget.roomId),
                      const SizedBox(height: 20),
                      _buildListenerToggle(context),
                      const SizedBox(height: 24),
                      QueueList(roomId: widget.roomId),
                      const SizedBox(height: 16),
                      ParticipantList(roomId: widget.roomId),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(e.toString()),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text(AppStrings.close),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String emoji,
    String? imageURL,
    int participantCount,
    int listenerCount,
  ) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 4),
          _buildRoomAvatar(imageURL, emoji),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Rubik',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    const Icon(Icons.people, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount משתתפים',
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    if (listenerCount > 0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.headphones, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        '$listenerCount מאזינים',
                        style: const TextStyle(
                          fontFamily: 'Rubik',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70, size: 22),
            onPressed: () => context.push(
              AppRoutes.roomSettingsPath(widget.roomId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomAvatar(String? imageURL, String emoji) {
    if (imageURL != null && imageURL.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: imageURL,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _buildEmojiAvatar(emoji),
        ),
      );
    }
    return _buildEmojiAvatar(emoji);
  }

  Widget _buildEmojiAvatar(String emoji) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 22)),
      ),
    );
  }

  Widget _buildListenerToggle(BuildContext context) {
    final wtState = ref.watch(walkieTalkieProvider(widget.roomId));
    final isListenerOnly = wtState.isListenerOnly;

    return GestureDetector(
      onTap: () => ref
          .read(walkieTalkieProvider(widget.roomId).notifier)
          .toggleListenerMode(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isListenerOnly
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isListenerOnly
                ? AppColors.accent
                : AppColors.textHint.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isListenerOnly ? Icons.headphones : Icons.headphones_outlined,
              size: 18,
              color: isListenerOnly ? AppColors.accent : AppColors.textHint,
            ),
            const SizedBox(width: 8),
            Text(
              isListenerOnly ? AppStrings.exitListenerMode : AppStrings.listenerOnly,
              style: TextStyle(
                fontFamily: 'Rubik',
                fontSize: 13,
                color: isListenerOnly ? AppColors.accent : AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
