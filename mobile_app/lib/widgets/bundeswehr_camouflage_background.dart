import 'dart:math' as math;

import 'package:flutter/material.dart';

class BundeswehrCamouflageBackground extends StatelessWidget {
  final Widget child;
  final bool dark;

  const BundeswehrCamouflageBackground({
    super.key,
    required this.child,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _LowPolyCamoPainter(dark: dark),
            child: const SizedBox.expand(),
          ),
        ),
        if (dark) Container(color: Colors.black.withValues(alpha: 0.10)),
        child,
      ],
    );
  }
}

class _LowPolyCamoPainter extends CustomPainter {
  final bool dark;

  const _LowPolyCamoPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = (dark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2F3922), Color(0xFF50633C)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC2BE99), Color(0xFFA8A476)],
                ))
          .createShader(rect);

    canvas.drawRect(rect, background);

    final palette = dark
        ? const [
            Color(0xFF1A1C12),
            Color(0xFF36472A),
            Color(0xFF516A40),
            Color(0xFF6D7F55),
            Color(0xFF8A8558),
            Color(0xFF6C5234),
            Color(0xFF4C3D28),
          ]
        : const [
            Color(0xFF3E4B2F),
            Color(0xFF586E44),
            Color(0xFF71845A),
            Color(0xFF9E9A66),
            Color(0xFF7C6643),
            Color(0xFFA9A476),
            Color(0xFFC6C089),
          ];

    final rand = math.Random(1847);
    final step = math.max(60.0, size.shortestSide * 0.11);
    final columns = (size.width / step).ceil() + 2;
    final rows = (size.height / step).ceil() + 2;

    final points = List.generate(rows, (y) {
      return List.generate(columns, (x) {
        final jitterX = (rand.nextDouble() - 0.5) * step * 0.7;
        final jitterY = (rand.nextDouble() - 0.5) * step * 0.7;
        return Offset((x - 1) * step + jitterX, (y - 1) * step + jitterY);
      });
    });

    final fill = Paint()..style = PaintingStyle.fill;

    for (var y = 0; y < rows - 1; y++) {
      for (var x = 0; x < columns - 1; x++) {
        final p00 = points[y][x];
        final p10 = points[y][x + 1];
        final p01 = points[y + 1][x];
        final p11 = points[y + 1][x + 1];

        if (rand.nextBool()) {
          _drawTriangle(canvas, fill, p00, p10, p11, palette, rand);
          _drawTriangle(canvas, fill, p00, p11, p01, palette, rand);
        } else {
          _drawTriangle(canvas, fill, p00, p10, p01, palette, rand);
          _drawTriangle(canvas, fill, p10, p11, p01, palette, rand);
        }
      }
    }

    canvas.drawRect(
      rect,
      Paint()..color = Colors.black.withValues(alpha: dark ? 0.14 : 0.10),
    );
  }

  void _drawTriangle(
    Canvas canvas,
    Paint fill,
    Offset a,
    Offset b,
    Offset c,
    List<Color> palette,
    math.Random rand,
  ) {
    final color = palette[rand.nextInt(palette.length)];
    final variance = (rand.nextDouble() - 0.5) * 0.20;
    fill.color = _shiftLuminance(color, variance);

    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy)
      ..close();

    canvas.drawPath(path, fill);
  }

  Color _shiftLuminance(Color color, double delta) {
    final hsl = HSLColor.fromColor(color);
    final shifted = (hsl.lightness + delta).clamp(0.08, 0.86);
    return hsl.withLightness(shifted).toColor();
  }

  @override
  bool shouldRepaint(covariant _LowPolyCamoPainter oldDelegate) {
    return oldDelegate.dark != dark;
  }
}
