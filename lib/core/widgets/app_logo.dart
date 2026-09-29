import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final double fill;
  final double wavePhase;
  final bool showGlow;

  const AppLogo({
    super.key,
    this.size = 160,
    this.fill = 1,
    this.wavePhase = 0,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: AppLogoPainter(
          fill: fill.clamp(0.0, 1.0),
          wavePhase: wavePhase,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class AppLogoPainter extends CustomPainter {
  final double fill;
  final double wavePhase;
  final bool showGlow;

  AppLogoPainter({
    required this.fill,
    required this.wavePhase,
    required this.showGlow,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dropPath = _dropPath(size);

    if (showGlow) {
      canvas.drawPath(
        dropPath,
        Paint()
          ..color = const Color(0xFF83C5BE).withValues(alpha: 0.28)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    canvas.drawPath(
      dropPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width * 0.3, size.height * 0.1),
          Offset(size.width * 0.8, size.height * 0.95),
          const [Color(0xFF148C96), Color(0xFF00545C)],
        ),
    );

    canvas.save();
    canvas.clipPath(dropPath);

    final fillTop = size.height * (1 - fill * 0.82) + size.height * 0.08;
    final wavePath = Path()
      ..moveTo(0, fillTop);

    const segments = 16;
    for (var i = 0; i <= segments; i++) {
      final x = size.width * i / segments;
      final y = fillTop +
          math.sin((i / segments) * math.pi * 2 + wavePhase) * size.height * 0.028;
      wavePath.lineTo(x, y);
    }

    wavePath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      wavePath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, fillTop),
          Offset(size.width / 2, size.height),
          const [Color(0xFF7ED6D0), Color(0xFF2A9D8F), Color(0xFF006D77)],
          const [0, 0.45, 1],
        ),
    );

    final highlight = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(size.width * 0.38, size.height * 0.38),
          width: size.width * 0.22,
          height: size.height * 0.16,
        ),
      );
    canvas.drawPath(
      highlight,
      Paint()..color = Colors.white.withValues(alpha: 0.28),
    );

    canvas.restore();

    canvas.drawPath(
      dropPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.035
        ..color = Colors.white.withValues(alpha: 0.35),
    );

    final markPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final markY = size.height * 0.62;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, markY),
        width: size.width * 0.28,
        height: size.height * 0.16,
      ),
      math.pi * 1.1,
      math.pi * 0.8,
      false,
      markPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, markY + size.height * 0.07),
        width: size.width * 0.18,
        height: size.height * 0.1,
      ),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      markPaint,
    );
  }

  Path _dropPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, h * 0.08)
      ..cubicTo(w * 0.5, h * 0.08, w * 0.18, h * 0.42, w * 0.18, h * 0.62)
      ..cubicTo(w * 0.18, h * 0.84, w * 0.32, h * 0.94, w * 0.5, h * 0.94)
      ..cubicTo(w * 0.68, h * 0.94, w * 0.82, h * 0.84, w * 0.82, h * 0.62)
      ..cubicTo(w * 0.82, h * 0.42, w * 0.5, h * 0.08, w * 0.5, h * 0.08)
      ..close();
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) {
    return oldDelegate.fill != fill ||
        oldDelegate.wavePhase != wavePhase ||
        oldDelegate.showGlow != showGlow;
  }
}
