import 'dart:math' as math;
import 'package:flutter/material.dart';

class BundeswehrLogo extends StatelessWidget {
  final double size;
  final Color color;

  const BundeswehrLogo({
    super.key,
    this.size = 180,
    this.color = const Color(0xFFF4F4F2),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _BundeswehrCrossPainter(color: color)),
    );
  }
}

class _BundeswehrCrossPainter extends CustomPainter {
  final Color color;

  const _BundeswehrCrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.translate(size.width / 2, size.height / 2);

    final armLength = size.width * 0.44;
    final armWidth = size.width * 0.18;
    final tipInset = size.width * 0.10;

    for (var i = 0; i < 4; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 2);

      final path = Path()
        ..moveTo(0, -armWidth / 2)
        ..lineTo(armLength, -armWidth * 0.66)
        ..lineTo(armLength - tipInset, 0)
        ..lineTo(armLength, armWidth * 0.66)
        ..lineTo(0, armWidth / 2)
        ..close();

      canvas.drawPath(path, paint);
      canvas.restore();
    }

    final centerRect = Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.24,
      height: size.height * 0.24,
    );
    canvas.drawRect(centerRect, paint);
  }

  @override
  bool shouldRepaint(covariant _BundeswehrCrossPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}
