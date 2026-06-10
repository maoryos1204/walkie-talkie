import 'package:flutter/material.dart';
import 'package:shmuki_talk/core/l10n/strings.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1A1A1A),
          disabledBackgroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          minimumSize: const Size(double.infinity, 56),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF1A237E),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 12),
                  const Text(
                    AppStrings.signInWithGoogle,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final whitePaint = Paint()..color = Colors.white;

    // Draw colored circle segments approximation using arcs
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Red (top-right arc)
    canvas.drawArc(rect, -1.1, 1.57, true, redPaint);
    // Blue (right side)
    canvas.drawArc(rect, 0.47, 1.57, true, bluePaint);
    // Yellow (bottom)
    canvas.drawArc(rect, 2.04, 0.79, true, yellowPaint);
    // Green (left)
    canvas.drawArc(rect, 2.83, 1.88, true, greenPaint);

    // White inner circle (donut hole)
    canvas.drawCircle(Offset(cx, cy), r * 0.6, whitePaint);

    // Blue right bar
    final barPaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(cx, cy - r * 0.2, r * 0.95, r * 0.4),
      barPaint,
    );

    // White circle again to make it look like G
    canvas.drawCircle(Offset(cx, cy), r * 0.55, whitePaint);
  }

  @override
  bool shouldRepaint(_GoogleLogoPainter oldDelegate) => false;
}
