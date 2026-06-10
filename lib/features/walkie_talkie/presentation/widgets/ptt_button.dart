import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';
import 'package:shmuki_talk/features/room/presentation/providers/room_providers.dart';
import 'package:shmuki_talk/features/walkie_talkie/presentation/providers/walkie_talkie_providers.dart';

class PttButton extends ConsumerStatefulWidget {
  final String roomId;

  const PttButton({super.key, required this.roomId});

  @override
  ConsumerState<PttButton> createState() => _PttButtonState();
}

class _PttButtonState extends ConsumerState<PttButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wtState = ref.watch(walkieTalkieProvider(widget.roomId));
    final roomAsync = ref.watch(roomProvider(widget.roomId));
    final room = roomAsync.valueOrNull;

    final isChannelBusy = (room?.hasActiveSpeaker ?? false) && !wtState.isSpeaking;
    final isListenerOnly = wtState.isListenerOnly;
    final isSpeaking = wtState.isSpeaking;
    final isInQueue = wtState.isInQueue;

    if (isSpeaking && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isSpeaking && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isChannelBusy)
          _buildChannelBusyIndicator(context),
        const SizedBox(height: 16),
        _buildButton(
          context,
          isSpeaking: isSpeaking,
          isChannelBusy: isChannelBusy,
          isListenerOnly: isListenerOnly,
          isInQueue: isInQueue,
        ),
        const SizedBox(height: 12),
        _buildButtonLabel(isSpeaking, isChannelBusy, isListenerOnly, isInQueue),
      ],
    );
  }

  Widget _buildChannelBusyIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.channelBusy.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.channelBusy.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.channelBusy,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(end: 1.5, duration: 600.ms)
              .then()
              .scaleXY(end: 1.0, duration: 600.ms),
          const SizedBox(width: 8),
          const Text(
            AppStrings.channelBusy,
            style: TextStyle(
              fontFamily: 'Rubik',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.channelBusy,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required bool isSpeaking,
    required bool isChannelBusy,
    required bool isListenerOnly,
    required bool isInQueue,
  }) {
    final buttonColor = isListenerOnly
        ? AppColors.statusOffline
        : isSpeaking
            ? AppColors.pttActive
            : isChannelBusy
                ? AppColors.pttBusy.withOpacity(0.6)
                : AppColors.pttIdle;

    final buttonSize = 140.0;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSpeaking ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isListenerOnly
            ? null
            : (_) => _onPressDown(),
        onTapUp: isListenerOnly
            ? null
            : (_) => _onPressUp(),
        onTapCancel: isListenerOnly
            ? null
            : () => _onPressUp(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow ring (when speaking)
            if (isSpeaking)
              Container(
                width: buttonSize + 30,
                height: buttonSize + 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pttGlow,
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scaleXY(end: 1.1, duration: 900.ms)
                  .then()
                  .scaleXY(end: 1.0, duration: 900.ms)
                  .fadeIn(duration: 200.ms),

            // Button shadow
            Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: buttonColor.withOpacity(isSpeaking ? 0.5 : 0.3),
                    blurRadius: isSpeaking ? 30 : 15,
                    spreadRadius: isSpeaking ? 6 : 2,
                  ),
                ],
              ),
            ),

            // Main button
            AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSpeaking
                      ? [AppColors.pttActive, const Color(0xFF9C27B0)]
                      : isChannelBusy
                          ? [AppColors.pttBusy.withOpacity(0.6), AppColors.pttBusy.withOpacity(0.4)]
                          : [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isListenerOnly
                          ? Icons.headphones
                          : isSpeaking
                              ? Icons.mic
                              : Icons.mic_none,
                      key: ValueKey(isSpeaking ? 'mic_on' : isListenerOnly ? 'headphones' : 'mic_off'),
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (!isListenerOnly)
                    Text(
                      isSpeaking ? 'שדר' : '...',
                      style: const TextStyle(
                        fontFamily: 'Rubik',
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPressDown() {
    setState(() => _isPressed = true);
    HapticFeedback.selectionClick();
    ref.read(walkieTalkieProvider(widget.roomId).notifier).onPttPressed();
  }

  Future<void> _onPressUp() async {
    if (!_isPressed) return;
    setState(() => _isPressed = false);
    await ref.read(walkieTalkieProvider(widget.roomId).notifier).onPttReleased();
  }

  Widget _buildButtonLabel(
    bool isSpeaking,
    bool isChannelBusy,
    bool isListenerOnly,
    bool isInQueue,
  ) {
    if (isListenerOnly) {
      return Text(
        AppStrings.listenerOnlyMode,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 14,
          color: AppColors.statusOffline,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (isSpeaking) {
      return Text(
        AppStrings.speaking,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 16,
          color: AppColors.pttActive,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      )
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1500.ms, color: Colors.white);
    }

    if (isInQueue) {
      return Text(
        AppStrings.speakingQueue,
        style: const TextStyle(
          fontFamily: 'Rubik',
          fontSize: 14,
          color: AppColors.statusInQueue,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text(
      AppStrings.holdToTalk,
      style: TextStyle(
        fontFamily: 'Rubik',
        fontSize: 14,
        color: AppColors.textHint,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
