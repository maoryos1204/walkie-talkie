import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shmuki_talk/core/theme/app_colors.dart';

class VoiceAnimation extends StatefulWidget {
  final double size;
  final Color? color;

  const VoiceAnimation({super.key, required this.size, this.color});

  @override
  State<VoiceAnimation> createState() => _VoiceAnimationState();
}

class _VoiceAnimationState extends State<VoiceAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  static const _waveCount = 4;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _waveCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + (i * 200)),
      )..repeat(reverse: true),
    );

    _animations = _controllers.asMap().entries.map((e) {
      return Tween<double>(
        begin: 0.3,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: e.value,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Stagger the animations
    for (var i = 0; i < _waveCount; i++) {
      Future.delayed(Duration(milliseconds: i * 120), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.waveActive;

    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _VoiceWavePainter(
            amplitudes: _animations.map((a) => a.value).toList(),
            color: color,
          ),
        );
      },
    );
  }
}

class _VoiceWavePainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _VoiceWavePainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3;

    for (var i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i];
      final ringRadius = baseRadius + (i + 1) * (size.width * 0.08);
      final opacity = (1.0 - (i * 0.2)) * amplitude * 0.6;

      final paint = Paint()
        ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 - (i * 0.3);

      canvas.drawCircle(center, ringRadius * amplitude, paint);
    }
  }

  @override
  bool shouldRepaint(_VoiceWavePainter oldDelegate) => true;
}

// Horizontal bar-style voice indicator
class VoiceBarsAnimation extends StatefulWidget {
  final double height;
  final Color? color;
  final int barCount;

  const VoiceBarsAnimation({
    super.key,
    this.height = 40,
    this.color,
    this.barCount = 5,
  });

  @override
  State<VoiceBarsAnimation> createState() => _VoiceBarsAnimationState();
}

class _VoiceBarsAnimationState extends State<VoiceBarsAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + _random.nextInt(400)),
      )..repeat(reverse: true),
    );

    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.15, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    for (var i = 0; i < widget.barCount; i++) {
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _controllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.waveActive;

    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                width: 4,
                height: widget.height * _animations[i].value,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
